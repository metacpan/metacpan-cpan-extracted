#!/usr/bin/perl
#
# Author:      Peter J. Acklam
# Time-stamp:  2010-02-19 15:50:40 +01:00
# E-mail:      pjacklam@cpan.org
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

########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

use Math::BigInt::Random::OO;

########################

#can_ok('Math::BigInt::Random::OO', 'new');
#my $generator = Math::BigInt::Random::OO -> new(min => 0,
#                                                max => 1,
#                                               );
#isa_ok($generator, 'Math::BigInt::Random::OO');

# Create constructor objects with various arguments.

new_ok('Math::BigInt::Random::OO', [min => 0, max => 1]);
new_ok('Math::BigInt::Random::OO', [length => 3, base => 8]);
new_ok('Math::BigInt::Random::OO', [length_bin => 4]);
new_ok('Math::BigInt::Random::OO', [length_hex => 5]);

# Emacs Local Variables:
# Emacs coding: utf-8-unix
# Emacs mode: perl
# Emacs End:
