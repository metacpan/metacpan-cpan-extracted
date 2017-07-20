package JSON::Schema::AsType::Draft4::Types;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: JSON-schema v4 keywords as types
$JSON::Schema::AsType::Draft4::Types::VERSION = '0.4.3';

use strict;
use warnings;

use Type::Utils -all;
use Types::Standard qw/ 
    Str StrictNum HashRef ArrayRef 
    Int
    Dict slurpy Optional Any
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
use List::Util qw/ pairs pairmap reduce uniq /;

use JSON qw/ to_json from_json /;

use JSON::Schema::AsType;

declare AdditionalProperties,
    constraint_generator => sub {
        my( $known_properties, $type_or_boolean ) = @_;

        sub {
            return 1 unless Object->check($_);
            my @add_keys = grep { 
                my $key = $_;
                none {
                    ref $_ ? $key =~ $_ : $key eq $_
                } @$known_properties
            } keys %$_;

            if ( eval { $type_or_boolean->can('check') } ) {
                my $obj = $_;
                return all { $type_or_boolean->check($obj->{$_}) } @add_keys;
            }
            else {
                return not( @add_keys and not $type_or_boolean );
            }
        }
    };

declare UniqueItems,
    where {
        return 1 unless Array->check($_);
        @$_ == uniq map { to_json $_ , { allow_nonref => 1 } } @$_
    };

my $json = JSON->new->allow_nonref->canonical;
use List::AllUtils qw/ zip none uniq /;

sub same_structs {
    my @s = @_;

    my @refs = grep { $_ } map { ref } @s;

    return if @refs == 1;

    no warnings 'uninitialized';

    return $s[0] eq $s[1] unless @refs;

    @refs = uniq @refs;
    return unless @refs == 1;

    if ( ref $s[0] eq 'ARRAY' ) {
        return all { same_structs($a,$b) } zip @{$s[0]}, @{$s[1]};
    }

    all { same_structs($s[0]{$_},$s[1]{$_}) } uniq map { keys %$_ } @s;
}

declare Enum,
    constraint_generator => sub {
        my @items = @_;

        sub {
            my $j = $_;
            any { same_structs($_,$j) } @items;
        }
    };

    # Dependencies[ foo => $type, bar => [ 'baz' ] ]
# TODO name of generated type should be better
declare Dependencies,
    constraint_generator => sub {
        my %deps = @_;

        return reduce { $a & $b } pairmap { Dependency[$a => $b] } %deps;
    };

    # Depencency[ foo => $type ]
declare Dependency,
    constraint_generator => sub {
        my( $property, $dep) = @_;

        sub {
            return 1 unless Object->check($_);
            return 1 unless exists $_->{$property};

            my $obj = $_;

            return all { exists $obj->{$_} } @$dep if ref $dep eq 'ARRAY';

            return $dep->check($_);
        }
    };

declare PatternProperties,
    constraint_generator => sub {
        my %props = @_;

        sub {
            return 1 unless Object->check($_);

            my $obj = $_;
            for my $key ( keys %props ) {
                return unless all { $props{$key}->check($obj->{$_}) } grep { /$key/ } keys %$_;
            }

            return 1;

        }
    };
declare Properties,
    constraint_generator => sub {
        my @types = @_;

        @types = pairmap { $a => Optional[$b] } @types;

        my $type = Dict[@types,slurpy Any];

        sub {
            return 1 unless Object->check($_);
            return $type->check($_);
        }
    };

declare Items,
    constraint_generator => sub {
        my $types = shift;

        if ( Boolean->check($types) ) {
            return $types ? Any : sub { !@$_ };
        }

        my $type =  ref $types eq 'ARRAY'
            ? Tuple[ ( map { Optional[$_] } @$types ), slurpy Any ]
            : Tuple[ slurpy ArrayRef[ $types ] ];

        return ~ArrayRef | $type;

    };

declare AdditionalItems,
    constraint_generator=> sub {
        if( @_ > 1 ) {
            my $to_skip = shift;
            my $schema = shift;
            return sub {
                all { $schema->check($_) } splice @$_, $to_skip; 
            }
        }
        else {
            my $size = shift;
            return sub { @$_ <= $size };
        }
    };

declare MaxLength,
    constraint_generator => sub {
        my $length = shift;
        sub {
            !String->check($_) or  $length >= length;
        }
    };

declare MinLength,
    constraint_generator => sub {
        my $length = shift;
        sub {
            !String->check($_) or  $length <= length;
        }
    };

declare AllOf,
    constraint_generator => sub {
        my @types = @_;
        sub {
            my $v = $_;
            all { $_->check($v) } @types;
        }
    };

declare AnyOf,
    constraint_generator => sub {
        my @types = @_;
        sub {
            my $v = $_;
            any { $_->check($v) } @types;
        }
    };

declare OneOf,
    constraint_generator => sub {
        my @types = @_;
        sub {
            my $v = $_;
            1 == grep { $_->check($v) } @types;
        }
    };

declare MaxProperties,
    constraint_generator => sub {
        my $nbr = shift;
        sub { !Object->check($_) or $nbr >= keys %$_; },
    };

declare MinProperties,
    constraint_generator => sub {
        my $nbr = shift;
        sub { 
            !Object->check($_) 
                or $nbr <= scalar keys %$_ 
        },
    };

declare Not,
    constraint_generator => sub {
        my $type = shift;
        sub { not $type->check($_) },
    };


# ~Str or ~String?
declare Pattern,
    constraint_generator => sub {
        my $regex = shift;
        sub { !String->check($_) or /$regex/ },
    };


declare Object => as HashRef ,where sub { ref eq 'HASH' };

declare Required,
    constraint_generator => sub {
        my @keys = @_;
        sub {
            return 1 unless Object->check($_);
            my $obj = $_;
            all { exists $obj->{$_} } @keys;
        }
    };

declare Array => as ArrayRef;

declare Boolean => where sub { ref =~ /JSON/ };

declare LaxNumber =>
    as StrictNum,
    where sub {
        return !(!defined || ref);
    };

declare Number =>
    where sub {
        return 0 if !defined || ref;

        my $b_obj = B::svref_2object(\$_);
        my $flags = $b_obj->FLAGS;
        return( $flags & ( B::SVp_IOK | B::SVp_NOK ) and not ($flags & B::SVp_POK) );
    };

declare LaxInteger => 
    as Int,
    where sub { return !(!defined || ref ) };

declare Integer =>
    where sub {
        return 0 if !defined || ref;

        my $b_obj = B::svref_2object(\$_);
        my $flags = $b_obj->FLAGS;
        return( $flags & B::SVp_IOK and not ($flags & B::SVp_POK) );
    };

declare LaxString => as Str,
    where sub { return defined && not ref; };

declare String => as Str,
    where sub {
        return 0 if !defined || ref;

        my $b_obj = B::svref_2object(\$_);
        my $flags = $b_obj->FLAGS;
        return ($flags & B::SVp_POK);
    };

declare Null => where sub { not defined };

declare 'MaxItems',
    constraint_generator => sub {
        my $max = shift;

        return sub {
            ref ne 'ARRAY' or @$_ <= $max;
        };
    };

declare 'MinItems',
    constraint_generator => sub {
        my $min = shift;

        return sub {
            ref ne 'ARRAY' or @$_ >= $min;
        };
    };

declare 'MultipleOf',
    constraint_generator => sub {
        my $num =shift;

        return sub {
            !Number->check($_)
                or ($_ / $num) !~ /\./;
        }
    };

declare Minimum,
    constraint_generator => sub {
        my $minimum = shift;
        return sub {
            ! Number->check($_)
                or $_ >= $minimum;
        };
    };

declare ExclusiveMinimum,
    constraint_generator => sub {
        my $minimum = shift;
        return sub { 
            ! StrictNum->check($_)
                or $_ > $minimum;
        }
    };

declare Maximum,
    constraint_generator => sub {
        my $max = shift;
        return sub {
            ! StrictNum->check($_)
                or $_ <= $max;
        };
    };

declare ExclusiveMaximum,
    constraint_generator => sub {
        my $max = shift;
        return sub { 
            ! StrictNum->check($_)
                or $_ < $max;
        }
    };

declare Schema, as InstanceOf['Type::Tiny'];

coerce Schema,
    from HashRef,
    via { 
        my $schema = JSON::Schema::AsType->new( draft_version => 4, schema => $_ );

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

version 0.4.3

=head1 SYNOPSIS

    use JSON::Schema::AsType::Draft4::Types '-all';

    my $type = Object & 
        Properties[
            foo => Minimum[3]
        ];

    $type->check({ foo => 5 });  # => 1
    $type->check({ foo => 1 });  # => 0

=head1 EXPORTED TYPES

        Null Boolean Array Object String Integer Pattern Number Enum

        OneOf AllOf AnyOf 

        Required Not

        Minimum ExclusiveMinimum Maximum ExclusiveMaximum MultipleOf

        MaxLength MinLength

        Items AdditionalItems MaxItems MinItems UniqueItems

        Properties PatternProperties AdditionalProperties MaxProperties MinProperties

        Dependencies Dependency

=head2 Schema

Only verifies that the variable is a L<Type::Tiny>. 

Can coerce the value from a hashref defining the schema.

    my $schema = Schema->coerce( \%schema );

    # equivalent to

    $schema = JSON::Schema::AsType::Draft4->new(
        draft_version => 4,
        schema => \%schema;
    )->type;

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
