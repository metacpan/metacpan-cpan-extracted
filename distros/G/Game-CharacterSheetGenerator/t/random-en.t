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

# start with an english root
$t->get_ok('/' => {'Accept-Language' => 'en'})
    ->status_is(302)
    ->header_is(Location => '/en');

$t->get_ok('/en')
    ->status_is(200)
    ->text_is('h1' => 'Character Sheet Generator')
    ->text_is('.footer a[href="/en"]:nth-child(1)' => 'Character Generator')
    ->text_is('.footer a[href="/help"]:nth-child(2)' => 'Help')
    ->text_is('.footer a[href="https://alexschroeder.ch/wiki/Contact"]:nth-child(3)' => 'Alex Schroeder')
    ->text_is('.footer a[href="https://alexschroeder.ch/cgit/character-sheet-generator/about/"]:nth-child(4)' => 'Source')
    ->text_is('.footer a[href="/de"]:nth-child(5)' => 'German');

$t->get_ok('/random?name=Alex')
    ->status_is(302)
    ->header_is(Location => '/random/en?name=Alex');

$t->get_ok('/random/en?name=Alex')
    ->status_is(200)
    ->header_is('Content-Type' => 'image/svg+xml')
    ->text_is('text#name tspan' => 'Alex')
    ->text_is('a#link text tspan' => 'Link');

my $url = $t->tx->res->dom->at('a#link')->attr('xlink:href');
my $str = $t->tx->res->dom->at('text#str tspan')->text;

like($url,
     qr!^/edit/en\?name=Alex&str=$str&!,
     "link with str $str");

$t->get_ok($url)
    ->status_is(200)
    ->text_is('h1' => 'A Link For Your Character')
    ->text_is('a:first-of-type' => 'Character Sheet')
    ->text_like('textarea[name="input"]' => qr/name: Alex\nstr: $str\n/);

like($t->tx->res->dom->at('a:first-of-type')->attr('href'),
     qr!^/char/en\?name=Alex&str=$str&!,
     'link back to character sheet');

my $action = $t->tx->res->dom->at('form')->attr('action');

is($action,
   '/redirect/en',
   'form points to redirect route');

my $input = $t->tx->res->dom->at('textarea[name="input"]')->text;

$t->get_ok($action => {Accept => '*/*'} => form => {input => $input})
    ->status_is(302)
    ->header_like(Location => qr!/char/en\?name=Alex&str=$str&!,
		  'redirection goes back to character sheet');

# following the redirect back to the character sheet
$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->header_is('Content-Type' => 'image/svg+xml')
    ->text_is('text#name tspan' => 'Alex')
    ->text_is('text#str tspan' => $str);

done_testing();
