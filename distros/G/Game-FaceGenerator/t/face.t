#!/usr/bin/env perl

# Copyright (C) 2015 Alex Schroeder <alex@gnu.org>

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
use FindBin;
use GD;
use strict;
use warnings;
use File::Temp qw(tempdir);
use File::Slurper qw(write_binary);

my $t = Test::Mojo->new('Game::FaceGenerator');
$t->app->config->{contrib} = 'share';

sub png_images_ok {
  my $images = shift;
  ok($images, "images provided by " . $t->tx->req->url);
  for my $image (@$images) {
    my $url = $image->attr('src');
    $t->get_ok($url)
	->status_is(200)
	->header_is('Content-Type' => 'image/png');
  }
}

$t->get_ok('/')
    ->status_is(200)
    ->text_is('h1' => 'Faces for your RPG Characters')
    # alex
    ->element_exists('li a[href="/view/alex/woman"]')
    # but not debugging alex
    ->element_exists_not('li a[href="/debug/alex"]');

# set up an account in the config file
$t->app->config('users')->{alex} = '*secret*';

# failed login to access debug mode
$t->post_ok('/login' => form =>  {
  username => 'alex',
  password => 'fnork' })
    ->status_is(200)
    ->content_like(qr/login failed/i)
    ->element_exists_not('li a[href="/debug/alex"]');

# successful login redirects to the main page
$t->post_ok('/login' => form =>  {
  username => 'alex',
  password => '*secret*' })
    ->status_is(302)
    ->header_is(Location => '/');

# debugging alex works, now
$t->get_ok('/')
    ->element_exists('li a[href="/debug/alex"]');

$t->get_ok('/view')
    ->status_is(302)
    ->header_is(Location => '/view/alex/woman');

$t->get_ok('/gallery')
    ->status_is(302)
    ->header_is(Location => '/gallery/alex/man');

$t->get_ok('/gallery/man')
    ->status_is(302)
    ->header_is(Location => '/gallery/alex/man');

$t->get_ok('/random')
    ->status_is(302)
    ->header_is(Location => '/random/alex/woman');

$t->get_ok('/random/woman')
    ->status_is(302)
    ->header_is(Location => '/random/alex/woman');

$t->get_ok('/random/alex/woman')
    ->status_is(200)
    ->header_is('Content-Type' => 'image/png');

 ARTIST:
    for my $artist (qw(alex)) {
      for my $type (qw(all man woman elf)) {

	$t->get_ok("/view/$artist/$type")
	    ->status_is(200)
	    ->text_is('h1' => "Random Face")
	    # Gallery
	    ->element_exists("a[href='/gallery/$artist/$type']")
	    # For demonstration purposes...
	    ->element_exists("a[href='/random/$artist/$type']")
	    # The image link itself
	    ->element_exists("a img[src^='/render/$artist/']");

	my $url = $t->tx->res->dom->at('img')->attr('src');

	$t->get_ok($url)
	    ->status_is(200)
	    ->header_is('Content-Type' => 'image/png');

	$t->get_ok("/gallery/$artist/$type")
	    ->status_is(200)
	    ->text_is('h1' => "Face Gallery");

	png_images_ok($t->tx->res->dom->find('img'));
      }
}

$t->get_ok('/debug/alex')
    ->status_is(200);

for my $element (Game::FaceGenerator::all_elements()) {
  $t->element_exists("li a[href='/debug/alex/$element']");
}

if ($ENV{AUTHOR_TEST}) {
  for my $element (Game::FaceGenerator::all_elements()) {

    $t->get_ok("/debug/alex/$element")
	->status_is(200);

    png_images_ok($t->tx->res->dom->find('img'));
  }
} else {
  diag "Skipping some tests because AUTHOR_TEST is not set";
}

my $dir = tempdir(CLEANUP => 1);
use Game::FaceGenerator::Core qw(dir);
dir($dir);

my $image = GD::Image->new(1, 30);
my $white = $image->colorAllocate(255,255,255);
my $black = $image->colorAllocate(  0,  0,  0);
$image->rectangle(0, 0, $image->getBounds(), $white);

write_binary("$dir/empty.png", $image->png);
write_binary("$dir/edit.png", $image->png);

$image->setPixel(0, 20, $black);

mkdir "$dir/alex";
my $file = "$dir/alex/test_all.png";
write_binary($file, $image->png);

$t->get_ok("/debug/alex/test");
my $url = $t->tx->res->dom->at('a.edit')->attr('href');
$t->get_ok($url)
    ->status_is(200)
    ->element_exists("area[alt='Move up']")
    ->element_exists("area[alt='Move down']");

my $up = $t->tx->res->dom->at("area[alt='Move up']")->attr('href');
my $down = $t->tx->res->dom->at("area[alt='Move down']")->attr('href');

png_images_ok($t->tx->res->dom->find('img'));

$t->get_ok($up)
    ->status_is(200);

my $y;

$image = GD::Image->new($file);

for ($y = 0;
     $image->getPixel(0, $y) eq $white
     && $y < $image->height - 1;
     $y++) {};

is($y, 10, "Black at y=10");

$t->get_ok($down)
    ->status_is(200);

$image = GD::Image->new($file);

for ($y = 0;
     $image->getPixel(0, $y) eq $white
     && $y < $image->height - 1;
     $y++) {};

is($y, 20, "Black at y=20");

unlink($file);

done_testing();
