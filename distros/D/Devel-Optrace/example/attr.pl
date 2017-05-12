#!perl -w
use strict;
use attributes;

use Devel::Optrace -all;

sub MODIFY_CODE_ATTRIBUTES{}

sub foo: Bar;
