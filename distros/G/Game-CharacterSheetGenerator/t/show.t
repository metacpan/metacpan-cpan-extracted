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

$t->get_ok('/show')
    ->status_is(200)
    ->text_is('text#str' => 'str');

is($t->tx->res->dom->at('svg')->attr('sodipodi:docname'),
   "Charactersheet.svg",
   'the correct SVG file was loaded');

$t->get_ok('/show?charsheet=Charakterblatt.svg')
    ->status_is(200)
    ->text_is('text#str' => 'str');

is($t->tx->res->dom->at('svg')->attr('sodipodi:docname'),
   "Charakterblatt.svg",
   'the correct SVG file was loaded');

done_testing();
