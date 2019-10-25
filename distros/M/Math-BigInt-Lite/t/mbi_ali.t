#!perl

use strict;
use warnings;

# test that the new alias names work

use Test::More tests => 6;

use Math::BigInt::Lite;

our $CLASS;
$CLASS = 'Math::BigInt::Lite';

require './t/alias.inc';
