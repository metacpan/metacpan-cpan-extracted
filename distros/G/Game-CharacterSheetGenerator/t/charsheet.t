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
$t->app->config("face_generator_url", undef);
$t->app->log->level('warn');

$t->get_ok('/char/en?name=Markus&charsheet=Charakterblatt.svg')
    ->status_is(200)
    ->header_is('Content-Type' => 'image/svg+xml');

is($t->tx->res->dom->at('svg')->attr('sodipodi:docname'),
   "Charakterblatt.svg",
   'the correct SVG file was loaded');

$t->get_ok('/char/en?str=10&str-bonus=0')
    ->status_is(200)
    ->text_is('#str tspan' => '10')
    ->text_is('#str-bonus tspan' => '0');

$t->get_ok('/random/en?class=fighter')
    ->status_is(200)
    ->text_is('#class tspan' => 'fighter')
    ->text_is('#abilities tspan:first-child' => '1/6 for normal tasks');

$t->get_ok('/random/en?class=thief')
    ->status_is(200)
    ->text_is('#class tspan' => 'thief')
    ->text_is('#abilities tspan:first-child' => '2/6 for all activities');

$t->get_ok('/random/en?class=thief&level=3')
    ->status_is(200)
    ->text_is('#level tspan' => '3')
    ->text_is('#abilities tspan:first-child' => '3/6 for all activities');

done_testing();
