#!perl
# Copyright 2022 Axel Zuber
# This file is part of MarpaX::G4.  MarpaX::G4 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# MarpaX::G4 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with MarpaX::G4.  If not, see
# http://www.gnu.org/licenses/.

use warnings;
use strict;

use Test::More tests => 1;

my $EVAL_ERROR;

if (not eval { require MarpaX::G4; 1; })
{
    Test::More::diag($EVAL_ERROR);
    Test::More::BAIL_OUT('Could not load MarpaX::G4');
}

my $marpa_version_ok = defined $MarpaX::G4::VERSION;
my $marpa_version_desc =
    $marpa_version_ok
        ? 'MarpaX::G4 version is ' . $MarpaX::G4::VERSION
        : 'No MarpaX::G4::VERSION';
Test::More::ok( $marpa_version_ok, $marpa_version_desc );

# vim: expandtab shiftwidth=4:
