#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{RELEASE_TESTING} = 1;
}

use Test::Kwalitee;
