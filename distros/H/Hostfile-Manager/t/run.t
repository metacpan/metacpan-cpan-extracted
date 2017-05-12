#! /usr/bin/perl -T

use strict;
use warnings;

use lib 't/tests';
use Test::Class::Load qw<t/tests>;

INIT { Test::Class->runtests( Test::Class->_test_classes, +1 ) }
