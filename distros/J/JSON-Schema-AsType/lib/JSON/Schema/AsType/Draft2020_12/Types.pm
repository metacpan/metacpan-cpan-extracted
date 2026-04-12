package JSON::Schema::AsType::Draft2020_12::Types;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft2020_12::Types::VERSION = '1.0.0';
# ABSTRACT: Type::Tiny types for draft 2020-12 schemas


use 5.42.0;
use warnings;

use feature qw/ module_true /;

use Hash::Merge qw/ merge /;
use Type::Utils -all;
use Types::Standard qw/
  Str StrictNum HashRef ArrayRef
  Int
  Dict slurpy Optional Any
  Tuple
  InstanceOf
  /;

use Type::Library
  -base,
  -declare => qw(
  PrefixItems
  Contains
  MinContains MaxContains
  );

use List::MoreUtils qw/ zip none any all /;
use List::Util      qw/ pairs pairmap reduce uniq /;

use JSON::Schema::AsType;

use JSON::Schema::AsType::Annotations;
use JSON::Schema::AsType::Draft4::Types qw/
  Integer Boolean Number String Null Object Array Items
  ExclusiveMinimum ExclusiveMaximum Dependencies Dependency
  Not MultipleOf
  /;

#__PACKAGE__->meta->add_type( $_ ) for Integer, Boolean, Number, String, Null, Object, Array, Items, ExclusiveMaximum, ExclusiveMinimum;

declare PrefixItems,
  constraint_generator => sub {
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
                add_annotation( 'prefixItems' => 0 .. $types->$#* );
            }
            else {
                add_annotation( 'prefixItems' => 0 .. $_->$#* );
            }
            return 1;
        }
    );

  };

declare Contains, constraint_generator => sub($type) {
    return sub {
        return any { $type->check($_) } @$_;
    }
};

declare MinContains, constraint_generator => sub($min) {
    return sub {
        annotation_for('contains')->@* >= $min;
    }
};

declare MaxContains, constraint_generator => sub($max) {
    return sub {
        annotation_for('contains')->@* <= $max;
    }
};

declare Items, constraint_generator => sub {
    if ( @_ > 1 ) {
        my $to_skip = shift;
        my $schema  = shift;
        return sub {

            return unless ref eq 'ARRAY';

            my @v = @$_;

            my @additional = splice @v, $to_skip;

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

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft2020_12::Types - Type::Tiny types for draft 2020-12 schemas

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
