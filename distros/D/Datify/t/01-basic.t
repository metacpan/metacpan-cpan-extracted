#! /usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
plan 5;

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
    keyify pairify hashify
    objectify
    codeify
    refify
    formatify
    globify
    self
);

isa_ok( my $datify = Datify->new, 'Datify' );

# NOTE: These are private functions, do not use!
ref_is_not( Datify->self, $datify,  'Class method self returns new self' );
ref_is(    $datify->self, $datify, 'Object method self returns same self' );

