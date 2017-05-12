#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;

use Devel::Refcount qw( refcount );

ok( exception { refcount() },
    'refcount with no args fails' );

ok( exception { refcount(undef) },
    'refcount with undef arg fails' );

ok( exception { refcount("hello") },
    'refcount with non-ref arg fails' );
