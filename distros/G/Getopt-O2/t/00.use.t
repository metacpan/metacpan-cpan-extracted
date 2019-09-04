#!/usr/bin/perl -w
# $Id: 00.use.t 887 2016-08-29 12:57:34Z schieche $
package Test::V00::Use;

use 5.016;
use strict;
use warnings;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use Test::More;

use_ok('Getopt::O2');

BEGIN {plan tests => 1}
