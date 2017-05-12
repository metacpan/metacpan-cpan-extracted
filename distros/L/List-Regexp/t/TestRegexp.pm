# -*- perl -*-
# Copyright (C) 2015-2016 Sergey Poznyakoff <gray@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package TestRegexp;

use strict;
use List::Regexp;
use Test;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(TestRegexp);

sub TestRegexp {
    local %_ = @_;
    croak "no input supplied" unless defined $_{input};
    my @input = @{$_{input}};

    my $tests = $#input + 1;

    $tests++ if defined $_{re};
    $tests += $#{$_{xok}} + 1 if defined($_{xok});
    $tests += $#{$_{xfail}} + 1 if defined($_{xfail});

    plan(tests => $tests);
    
    my $re = regexp_opt(\%_, @input);

    ok($re, $_{re}) if defined($_{re});
    
    foreach my $s (@input) {
	ok($s, qr/$re/);
    }

    foreach my $s (@{$_{xok}}) {
	ok($s, qr/$re/);
    }

    foreach my $s (@{$_{xfail}}) {
	ok($s !~ m/$re/);
    }
}

1;
