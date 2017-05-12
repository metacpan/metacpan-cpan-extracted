#!/usr/bin/perl

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 3;

use_ok( 'JSAN::Transport' );
use_ok( 'JSAN::Index' );
use_ok( 'JSAN::Client' );
