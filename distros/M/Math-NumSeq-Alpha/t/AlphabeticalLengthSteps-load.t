#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde

# This file is part of Math-NumSeq-Alpha.
#
# Math-NumSeq-Alpha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq-Alpha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq-Alpha.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;

my $test_count = (tests => 1)[1];
plan tests => 1;

# without nowarnings, due to warnings from a couple of Lingua modules

require Math::NumSeq::AlphabeticalLengthSteps;
my $seq = Math::NumSeq::AlphabeticalLengthSteps->new;
my ($i, $value) = $seq->next;
ok($i, 1);
exit 0;
