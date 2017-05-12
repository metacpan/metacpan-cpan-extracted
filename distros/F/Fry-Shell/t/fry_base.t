#!/usr/bin/perl

package main;
use strict;
use Test::More tests=>1;
use lib 'lib';
use lib 't/testlib';
use Fry::Base;

Fry::Base->_core(one=>'time');
is(Fry::Base->_core('one'),'time','&_core: retrieves and sets correctly');
