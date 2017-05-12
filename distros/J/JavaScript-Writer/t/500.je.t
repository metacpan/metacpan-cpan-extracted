#!perl
use strict;
use warnings;
use Test::Class;

use lib 't/lib';

use Test::WithJE;

Test::Class->runtests;
