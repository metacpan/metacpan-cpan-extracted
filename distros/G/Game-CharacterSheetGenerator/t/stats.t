#!/usr/bin/env perl

# Copyright (C) 2015-2022 Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

use Modern::Perl;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Game::CharacterSheetGenerator');
$t->app->log->level('warn');

$t->get_ok('/stats/en/100')
    ->status_is(200)
    ->content_like(qr/backpack  100\n/);

$t->get_ok('/stats/de/100')
    ->status_is(200)
    ->content_like(qr/Rucksack  100\n/);

# and some redirections

$t->get_ok('/stats')
    ->status_is(302)
    ->header_is(Location => '/stats/en/100');

$t->get_ok('/stats/100')
    ->status_is(302)
    ->header_is(Location => '/stats/en/100');

$t->get_ok('/stats/de')
    ->status_is(302)
    ->header_is(Location => '/stats/de/100');

done_testing();
