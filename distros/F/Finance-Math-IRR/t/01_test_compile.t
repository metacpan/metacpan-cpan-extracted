#!/usr/local/bin/perl
#################################################################
#
#   $Id: 01_test_compile.t,v 1.1 2007/04/11 12:22:52 erwan_lemonnier Exp $
#
#   @author       erwan lemonnier
#   @description  test that Finance::Math::IRR compiles
#   @system       pluto
#   @function     base
#   @function     vf
#

use strict;
use warnings;
use Test::More tests => 1;
use lib "../lib/";

use_ok('Finance::Math::IRR');
