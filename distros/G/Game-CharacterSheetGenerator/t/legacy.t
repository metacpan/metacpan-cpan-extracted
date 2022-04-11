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

# old edit links

$t->get_ok('/link/en?name=Aurora;str=9')
    ->status_is(302)
    ->header_is('Location' => '/edit/en?name=Aurora&str=9');

$t->get_ok('/edit/en?name=Aurora&str=9')
    ->status_is(200)
    ->text_like('textarea[name="input"]' => qr/name: Aurora\nstr: 9\n/);

# old image links

$t->get_ok('/en?name=Aurora;str=9')
    ->status_is(302)
    ->header_is('Location' => '/char/en?name=Aurora&str=9');

$t->get_ok('/char/en?name=Aurora&str=9')
    ->status_is(200)
    ->header_is('Content-Type' => 'image/svg+xml')
    ->text_is('text#name tspan' => 'Aurora')
    ->text_is('text#str tspan' => '9');

done_testing();
