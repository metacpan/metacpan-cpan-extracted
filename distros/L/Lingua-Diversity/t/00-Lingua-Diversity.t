#!/usr/bin/perl

# Dummy package for testing abstract method exception...
package DummyKO;
use Moose;
extends 'Lingua::Diversity';
no Moose;
__PACKAGE__->meta->make_immutable;

# Dummy package for testing measure() and measure_per_category()...
package DummyOK;
use Moose;
extends 'Lingua::Diversity';
sub _measure {
    my ( $self, $unit_array_ref, $category_array_ref ) = @_;
    if (
           $unit_array_ref->[0] eq 'Aa'
        && $unit_array_ref->[1] eq 'Bb'
        && @$unit_array_ref == 2
    ) {
        return Lingua::Diversity::Result->new( 'diversity' => 1 )
    }
    return Lingua::Diversity::Result->new( 'diversity' => 0 )
}
no Moose;
__PACKAGE__->meta->make_immutable;

# Main package...

package main;

use strict;
use warnings;

use Test::More tests => 13;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity' ) || print "Bail out!\n";
}

my $diversity = Lingua::Diversity->new();

# Created objects are of the right class...
cmp_ok(
    ref( $diversity ), 'eq', 'Lingua::Diversity',
    'is a Lingua::Diversity'
);

# Created object have all necessary methods defined...
can_ok( $diversity, qw(
    measure
    measure_per_category
    _measure
) );

# Method _measure() can't be called on abstract object...
eval { $diversity->_measure() };
is(
    ref $@,
    'Lingua::Diversity::X::AbstractObject',
    'Method _measure() correctly croaks when called on abstract object'
);

# Method _measure() must be implemented in derived classes...
my $diversity_ko = DummyKO->new();
eval { $diversity_ko->_measure(); };
is(
    ref $@,
    'Lingua::Diversity::X::AbstractMethod',
    'Method _measure() correctly croaks when not implemented in '
  . 'derived classes'
);

# Method measure() correctly requires array ref as 1st argument...
my $diversity_ok = DummyOK->new();
eval { $diversity_ok->measure(); };
is(
    ref $@,
    'Lingua::Diversity::X::ValidateSizeMissing1stArrayRef',
    'Method measure() correctly requires array ref as 1st argument'
);

# Method measure() correctly validates array size...
eval { $diversity_ok->measure( [] ); };
is(
    ref $@,
    'Lingua::Diversity::X::ValidateSizeArrayTooSmall',
    'Method measure() correctly validates array size'
);

# Method measure() correctly calls private and returns a L::D::Result...
my $result = $diversity_ok->measure( [ 'a' ] );
is(
    ref $result,
    'Lingua::Diversity::Result',
    'Method measure() correctly calls _measure() and returns a L::D::Result'
);

# Method measure_per_category() correctly requires array ref as 1st argument.
eval { $diversity_ok->measure_per_category(); };
is(
    ref $@,
    'Lingua::Diversity::X::ValidateSizeMissing1stArrayRef',
    'Method measure_per_category() correctly requires array ref as 1st '
  . 'argument'
);

# Method measure_per_category() correctly requires array ref as 2nd argument.
eval { $diversity_ok->measure_per_category( [ 'a' ] ); };
is(
    ref $@,
    'Lingua::Diversity::X::ValidateSizeMissing2ndArrayRef',
    'Method measure_per_category() correctly requires array ref as 2nd '
  . 'argument'
);

# Method measure_per_category() correctly validates array size...
eval { $diversity_ok->measure_per_category( [ qw( a b ) ], [ 'a' ] ); };
is(
    ref $@,
    'Lingua::Diversity::X::ValidateSizeArraysOfDifferentSize',
    'Method measure_per_category() correctly validates array size'
);

# Method measure_per_category() correctly calls private + returns L::D::Result
$result = $diversity_ok->measure_per_category( [ qw( a b ) ], [ qw( A B ) ] );
is(
    ref $result,
    'Lingua::Diversity::Result',
    'Method measure_per_category() correctly calls private and returns a '
  . 'L::D::Result'
);

# Method measure_per_category() correctly recodes units...
$result = $diversity_ok->measure_per_category( [ qw( a b ) ], [ qw( A B ) ] );
ok(
    $result->get_diversity(),
    'Method measure_per_category() correctly recodes units'
);




