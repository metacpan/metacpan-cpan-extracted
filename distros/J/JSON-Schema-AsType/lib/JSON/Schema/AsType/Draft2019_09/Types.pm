package JSON::Schema::AsType::Draft2019_09::Types;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft2019_09::Types::VERSION = '1.0.0';
# ABSTRACT: Type::Tiny types for draft 2019-09 schemas


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
  DependentRequired
  DependentSchemas
  UnevaluatedProperties
  UnevaluatedItems
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

declare DependentRequired => constraint_generator => sub($depends) {
    return sub {

        # only for objects
        return 1 unless ref eq 'HASH';

        for my ( $prop, $deps ) (%$depends) {
            next unless exists $_->{$prop};
            for my $d (@$deps) {
                return 0 unless exists $_->{$d};
            }
        }
        return 1;
    }
};

declare DependentSchemas => constraint_generator => sub($depends) {

    return sub {

        # only for objects
        return 1 unless ref eq 'HASH';

        for my ( $prop, $dep ) (%$depends) {
            next     unless exists $_->{$prop};
            return 0 unless $dep->check($_);
        }

        return 1;
    }
};

declare UnevaluatedProperties => constraint_generator => sub($type) {

    return sub {

        # only for objects
        return 1 unless ref eq 'HASH';

        my $target = $_;

        my %keys = map { $_ => 1 } annotation_properties();

        my @keys = grep { !$keys{$_} } keys %$target;

        add_annotation( 'unevaluatedProperties', @keys );

        return all { $type->check($_) } map { $target->{$_} } @keys;
    }
};

declare UnevaluatedItems => constraint_generator => sub($type) {

    return sub {

        # only for arrays
        return 1 unless ref eq 'ARRAY';

        my $target = $_;

        my %indexes;

        $indexes{$_}++ for annotation_items();

        for my $i ( grep { !$indexes{$_} } 0 .. $target->$#* ) {
            return 0 unless $type->check( $target->[$i] );
            add_annotation( 'unevaluatedItems', $i );
        }

        return 1;
    }
};

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft2019_09::Types - Type::Tiny types for draft 2019-09 schemas

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
