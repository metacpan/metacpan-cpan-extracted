#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 2;


package Foo;

use Test::More;

use Gapp::Moose;

use_ok 'GappX::Moose::Meta::Attribute::Trait::GappSSNEntry';

use GappX::SSNEntry;


widget 'entry' => (
    is => 'ro',
    traits => [qw( GappSSNEntry )],
    construct => 1,
);


package main;


my $o = Foo->new;
isa_ok $o->entry, 'GappX::SSNEntry';


