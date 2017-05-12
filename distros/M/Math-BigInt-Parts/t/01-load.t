#!perl
#
# Author:      Peter John Acklam
# Time-stamp:  2010-08-24 16:14:04 +02:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

########################

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
use utf8;               # enable UTF-8 in source code

########################

local $| = 1;                   # disable buffering

#BEGIN {
#    chdir 't' if -d 't';
#    unshift @INC, '../lib';     # for running manually
#}

#########################

use Test::More tests => 1;

BEGIN { use_ok('Math::BigInt::Parts'); }

diag("Testing Math::BigInt::Parts"
     . " $Math::BigInt::Parts::VERSION, Perl $], $^X");

# Emacs Local Variables:
# Emacs coding: utf-8-unix
# Emacs mode: perl
# Emacs End:
