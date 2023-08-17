#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use MVC::Neaf;

throws_ok {
    MVC::Neaf->new( foobar => 1 );
} qr/MVC::Neaf.*[Nn]o.*supported.*\bfoobar\b/, 'options not supported. sorry.';

done_testing;
