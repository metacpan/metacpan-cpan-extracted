#! /usr/bin/env perl

use strict;
use warnings;

# Proper testing requires a . at the end of the error message
use Carp 1.25;

use Test2::V0;
plan 10;

ok require Datify, 'Required Datify';

can_ok 'Datify', qw(
    new get set
    varify
    undefify
    booleanify
    stringify stringify1 stringify2
    numify
    scalarify
    vstringify
    regexpify
    listify arrayify
    keysort keyify pairify hashify
    objectify
    codeify
    refify
    formatify
    globify
    self
    class
);

isa_ok( my $datify = Datify->new, 'Datify' );

is(
    warning { Datify->set( apple => 123 ) },
    sprintf( "Unknown key apple at %s line %d.\n",  __FILE__, __LINE__ - 1 ),
    'Class method warned about unknown parameter'
);
is(
    warning { $datify->set( banana => 321 ) },
    sprintf( "Unknown key banana at %s line %d.\n", __FILE__, __LINE__ - 1 ),
    'Object method warned about unknown parameter'
);

# NOTE: The following are private, do not use!
ref_is_not( Datify->self, $datify,  'Class method "self" returns new self' );
ref_is(    $datify->self, $datify, 'Object method "self" returns same self' );

is(
    dies { $datify->_settings },
    sprintf(
        "Illegal use of private method at %s line %d.\n",
        __FILE__, __LINE__ - 3
    ),
    'Cannot call private method'
);

# 9e9999 should be infinity.
my @list = (
    9e9999 / 9e9999,
    "NaN",
    9e9999,
    "Infinity",
    "INF",
    123_456_789,
    -23_456_789.01,
      3_456_789.01_2,
       -456_789.01_23,
         56_789.01_234,
         -6_789.01_234_5,
            789.01_234_56,
            -89.01_234_567,
              9.01_234_567_8,
    "0",
    "000",
    "0.00",
    "apple",
    "Banana",
    "CHERRY",
);
my @sorted = sort Datify::keysort @list;
my @expected = (
    -23_456_789.01,
       -456_789.01_23,
         -6_789.01_234_5,
            -89.01_234_567,
    "0",
    "0.00",
    "000",
              9.01_234_567_8,
            789.01_234_56,
         56_789.01_234,
      3_456_789.01_2,
    123_456_789,
    sort( { lc($a) cmp lc($b) || $a cmp $b }
        "apple",
        "Banana",
        "CHERRY",
        9e9999,             # Can be inf, 1.#INF, or some other values
        "INF",
        "Infinity",
        "NaN",
        9e9999 / 9e9999,    # Can be nan, -nan, 1.#IND, or some other values
    ),
);
is( \@sorted, \@expected, 'List sorts sensibly' )
    or do {
        diag( 'List sorted oddly:' );
        diag( '@list   = ', join( ', ', @list ) );
        diag( '@sorted = ', join( ', ', @sorted ) );
    };

subtest get_class => \&get_class;

sub get_class {
    package Datify::Test;

    use Test2::V0;
    use parent 'Datify';

    sub as_method {
        my $size  = @_;
        my $str   = "$size: @_";
        my $class = &Datify::class;
        is( $class, __PACKAGE__,   'Method "class" returns class name' );
        is( scalar(@_), $size - 1, "\@_ was properly altered ($str)" );
    }

    sub as_function {
        my $size  = @_;
        my $str   = "$size: @_";
        my $class = &Datify::class;
        is( $class, __PACKAGE__, 'Function "class" returns class name' );
        is( scalar(@_), $size,     "\@_ was properly altered ($str)" );
    }

    __PACKAGE__->as_method;
    my $object = __PACKAGE__->new;
    $object->as_method($object);

    Datify::Test::as_function();

    foreach my $param (qw( cherry Datify )) {
        __PACKAGE__->as_method($param);
        my $object = __PACKAGE__->new;
        $object->as_method($object);
        $object->as_method($param);

        Datify::Test::as_function($param);
    }
}


