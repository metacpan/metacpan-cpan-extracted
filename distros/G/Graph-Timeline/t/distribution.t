#!/usr/bin/perl

# $Id: distribution.t,v 1.1 2005/09/14 19:53:01 peterhickman Exp $

use strict;
use warnings;

use Test::More;

eval 'require Test::Distribution';
plan( 'skip_all' => 'Test::Distribution not installed' ) if $@;

Test::Distribution->import();

# vim: syntax=perl :
