package JSON::Schema::AsType::Draft4::Types;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft4::Types::VERSION = '1.0.0';
# ABSTRACT: JSON-schema v4 keywords as types


use 5.42.0;
use warnings;

use Test::Deep::NoTest qw/ eq_deeply /;

use Math::BigFloat;
use Hash::Merge qw/ merge /;
use Type::Utils -all;
use Types::Standard qw/
  Str StrictNum HashRef ArrayRef
  Int
  Dict Slurpy Optional Any slurpy
  Tuple
  ConsumerOf
  InstanceOf
  /;

use Type::Library
  -base,
  -declare => qw(
  Minimum
  ExclusiveMinimum
  Maximum
  ExclusiveMaximum
  MultipleOf

  Null
  Boolean
  Array
  Object
  String
  Integer
  Pattern
  Number

  Required

  Not

  OneOf
  AllOf
  AnyOf

  MaxLength
  MinLength

  Items
  AdditionalItems
  MaxItems
  MinItems

  Properties
  PatternProperties
  AdditionalProperties
  MaxProperties
  MinProperties

  Dependencies
  Dependency

  Enum

  UniqueItems

  Schema

  );

use List::MoreUtils qw/ all any zip none /;
use List::Util      qw/ pairs pairmap reduce uniq /;
use List::AllUtils  qw/ none uniq /;

use JSON qw/ to_json from_json /;

use JSON::Schema::AsType;
use JSON::Schema::AsType::Annotations;

declare AdditionalProperties,
  constraint_generator => sub {
    my ( $known_properties, $type_or_boolean ) = @_;

    sub {
        return 1 unless Object->check($_);

        my @add_keys = grep {
            my $key = $_;
            none { ref $_ ? $key =~ $_ : $key eq $_ } @$known_properties
        } keys %$_;

        add_annotation( 'additionalProperties', @add_keys );

        if ( eval { $type_or_boolean->can('check') } ) {
            my $obj = $_;
            return all { $type_or_boolean->check( $obj->{$_} ) } @add_keys;
        }

        return not( @add_keys and not $type_or_boolean );
    }
  };

declare UniqueItems, where {
    return 1 unless Array->check($_);
    @$_ == uniq map { to_json $_, { allow_nonref => 1, canonical => 1 } } @$_
};

my $json = JSON->new->allow_nonref->canonical;

declare Enum, constraint_generator => sub {
    my @items = @_;

    sub {
        my $j = $_;

        # TODO horrible corner case for the test suite, worth it?
        any { eq_deeply( $_, $j ) } @items;
    }
};

# Dependencies[ foo => $type, bar => [ 'baz' ] ]
# TODO name of generated type should be better
declare Dependencies, constraint_generator => sub {
    my %deps = @_;

    return reduce { $a & $b } pairmap { Dependency [ $a => $b ] } %deps;
};

# Depencency[ foo => $type ]
declare Dependency, constraint_generator => sub {
    my ( $property, $dep ) = @_;

    sub {
        return 1 unless Object->check($_);
        return 1 unless exists $_->{$property};

        my $obj = $_;

        return all { exists $obj->{$_} } @$dep if ref $dep eq 'ARRAY';

        return $dep->check($_);
    }
};

declare PatternProperties, constraint_generator => sub {
    my %props = @_;

    sub {
        return 1 unless Object->check($_);

        my $obj = $_;

        my @keys;
        for my $key ( keys %props ) {
            push @keys, grep { /$key/ } keys %$obj;
        }

        add_annotation( 'patternProperties', @keys );

        for my $key ( keys %props ) {
            return
              unless all { $props{$key}->check( $obj->{$_} ) }
              grep { /$key/ } keys %$_;
        }

        return 1;

    }
};
declare Properties, constraint_generator => sub {
    my %types = @_;

    %types = pairmap { $a => Optional [$b] } %types;

    return ~HashRef    # not an object, don't care
      | (
        Dict [ %types, Slurpy [Any] ] & sub {
            my $value = $_;
            add_annotation( 'properties',
                grep { exists $value->{$_} } keys %types );
            return 1;
        }
      );
};

declare Items, constraint_generator => sub {
    my $types = shift;

    if ( Boolean->check($types) ) {
        return $types ? Any : sub { !@$_ };
    }

    my $type =
      ref $types eq 'ARRAY'
      ? Tuple [ ( map { Optional [$_] } @$types ), slurpy Any ]
      : Tuple [ slurpy ArrayRef [$types] ];

    return ~ArrayRef | (
        $type & sub {
            if ( ref $types eq 'ARRAY' ) {
                add_annotation( 'items', 0 .. $types->$#* );
            }
            else {
                add_annotation( 'items', 0 .. $_->$#* );
            }
            return 1;
        }
    );

};

declare AdditionalItems, constraint_generator => sub {
    if ( @_ > 1 ) {
        my $to_skip = shift;
        my $schema  = shift;
        return sub {

            return unless ref eq 'ARRAY';
            my @additional = splice @$_, $to_skip;

            if ( ref $schema eq 'JSON::PP::Boolean' ) {
                my $verdict = @additional;
                $verdict = !$verdict unless $schema;
                return $verdict;
            }

            return all { $schema->check($_) } @additional;
        }
    }
    else {
        my $size = shift;
        if ( ref $size eq 'JSON::PP::Boolean' ) {
            return sub {
                my $s = ref($_) eq 'ARRAY' ? @_ : 0;
                $DB::single = 1;
                return !!$size ? $s : !$s;
            }
        }
        return sub {
            my $s = ref($_) eq 'ARRAY' ? @_ : 0;
            $s <= $size;
        };
    }
};

declare MaxLength, constraint_generator => sub {
    my $length = shift;
    sub {
        !String->check($_) or $length >= length;
    }
};

declare MinLength, constraint_generator => sub {
    my $length = shift;
    sub {
        !String->check($_) or $length <= length;
    }
};

declare AllOf, constraint_generator => sub {
    my @types = @_;
    sub {
        my $value = $_;

        my $matched = 1;
        my $scope   = {};

        for my $type (@types) {
            my %scope;
            return 0 unless annotation_scope(
                sub {
                    return 0 unless $type->check($value);

                    $scope = annotation_merge($scope);

                    return 1;
                }
            );
        }

        annotation_merge($scope);

        return 1;
    }
};

declare AnyOf, constraint_generator => sub {
    my @types = @_;
    sub {
        my $value = $_;

        my $matched = 0;
        my $scope   = {};

        for my $type (@types) {
            annotation_scope(
                sub {
                    return unless $type->check($value);

                    $scope   = annotation_merge($scope);
                    $matched = 1;
                }
            );
        }

        if ($matched) {
            annotation_merge($scope);
        }

        return $matched;
    }
};

declare OneOf, constraint_generator => sub {
    my @types = @_;
    sub {
        my $value = $_;

        my $matched = 0;
        my $scope   = {};

        for my $type (@types) {
            return 0 unless annotation_scope(
                sub {
                    return 1 unless $type->check($value);

                    return 0 if $matched;

                    $scope   = annotation_merge($scope);
                    $matched = 1;

                    return 1;

                }
            );
        }

        if ($matched) {
            annotation_merge($scope);
        }

        return $matched;
    }
};

declare MaxProperties, constraint_generator => sub {
    my $nbr = shift;
    sub { !Object->check($_) or $nbr >= keys %$_; },;
};

declare MinProperties, constraint_generator => sub {
    my $nbr = shift;
    sub {
        !Object->check($_)
          or $nbr <= scalar keys %$_;
    },;
};

declare Not, constraint_generator => sub {
    my $type = shift;
    sub { not $type->check($_) },;
};

# ~Str or ~String?
declare Pattern, constraint_generator => sub {
    my $regex = shift;
    sub { !String->check($_) or /$regex/ },;
};

declare Object => as HashRef, where sub { ref eq 'HASH' };

declare Required, constraint_generator => sub {
    my @keys = @_;
    sub {
        return 1 unless Object->check($_);
        my $obj = $_;
        all { exists $obj->{$_} } @keys;
    }
};

declare Array => as ArrayRef;

declare Boolean => where sub { ref =~ /JSON/ };

declare
  LaxNumber => as StrictNum,
  where sub {
    return !( !defined || ref );
  };

declare Number => where sub {
    return 0 if !defined || ref;

    my $b_obj = B::svref_2object( \$_ );
    my $flags = $b_obj->FLAGS;
    return ( $flags & ( B::SVp_IOK | B::SVp_NOK )
          and not( $flags & B::SVp_POK ) );
};

declare
  LaxInteger => as Int,
  where sub { return !( !defined || ref ) };

declare Integer => where sub {
    return 0 unless Int->check($_);

    # weeeird stuff stolen from JSON
    my $b_obj = B::svref_2object( \$_ );

    my $flags = $b_obj->FLAGS;
    my $verdict =
      $flags & ( B::SVp_IOK | B::SVp_NOK ) && !( $flags & B::SVp_POK() );
    return !!$verdict;
};

declare
  LaxString => as Str,
  where sub { return defined && not ref; };

declare
  String => as Str,
  where sub {
    return 0 if !defined || ref;

    my $b_obj = B::svref_2object( \$_ );
    my $flags = $b_obj->FLAGS;
    return ( $flags & B::SVp_POK );
  };

declare Null => where sub { not defined };

declare 'MaxItems', constraint_generator => sub {
    my $max = shift;

    return sub {
        ref ne 'ARRAY' or @$_ <= $max;
    };
};

declare 'MinItems', constraint_generator => sub {
    my $min = shift;

    return sub {
        ref ne 'ARRAY' or @$_ >= $min;
    };
};

declare 'MultipleOf', constraint_generator => sub {
    my $num = shift;

    return sub {
        return 1 unless Number->check($_);
        my ( $q, $r ) = Math::BigFloat->new($_)->bdiv($num);
        return !$r;
    }
};

declare Minimum, constraint_generator => sub {
    my $minimum = shift;
    return sub {
        !Number->check($_)
          or $_ >= $minimum;
    };
};

declare ExclusiveMinimum, constraint_generator => sub {
    my $minimum = shift;
    return sub {
        !StrictNum->check($_)
          or $_ > $minimum;
    }
};

declare Maximum, constraint_generator => sub {
    my $max = shift;
    return sub {
        !StrictNum->check($_)
          or $_ <= $max;
    };
};

declare ExclusiveMaximum, constraint_generator => sub {
    my $max = shift;
    return sub {
        !StrictNum->check($_)
          or $_ < $max;
    }
};

declare Schema, as InstanceOf ['Type::Tiny'];

coerce Schema, from HashRef, via {
    my $schema = JSON::Schema::AsType->new( draft => 4, schema => $_ );

    if ( $schema->validate_schema ) {
        die "not a valid draft4 json schema\n";
    }

    $schema->type
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft4::Types - JSON-schema v4 keywords as types

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION 

Internal module for L<JSON::Schema:::AsType>. 

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
