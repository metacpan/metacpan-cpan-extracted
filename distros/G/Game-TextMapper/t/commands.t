# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

use Modern::Perl;
use Test::More;
use IPC::Open2;
use Mojo::DOM;
use Test::Mojo;
use Mojo::File;

my $script = Mojo::File->new('script', 'text-mapper');

# random

sub test_random_map {
  my $name = shift;
  my $pid;
  $pid = open2(my $out, my $in, $^X, $script, 'random', @_);
  # always slurp!
  undef $/;
  my $data = <$out>;
  like($data, qr/^0101/, $name);
  # reap zombie and retrieve exit status
  waitpid($pid, 0);
  my $child_exit_status = $? >> 8;
  is($child_exit_status, 0, "Exit status OK");
}

test_random_map('default');
test_random_map('Smale', 'Game::TextMapper::Smale');
test_random_map('Apocalypse', 'Game::TextMapper::Apocalypse');
test_random_map('Traveller', 'Game::TextMapper::Traveller');
test_random_map('Alpine (hex)', qw'Game::TextMapper::Schroeder::Alpine --role Game::TextMapper::Schroeder::Hex');
test_random_map('Alpine (square)', qw'Game::TextMapper::Schroeder::Alpine --role Game::TextMapper::Schroeder::Square');
test_random_map('Island (hex)', qw'Game::TextMapper::Schroeder::Island --role Game::TextMapper::Schroeder::Hex');
test_random_map('Island (square)', qw'Game::TextMapper::Schroeder::Island --role Game::TextMapper::Schroeder::Square');

# render

sub test_simple_render {
  my $map = shift;
  my $pid;
  $pid = open2(my $out, my $in, $^X, $script, 'render');
  print $in $map;
  close($in);
  # always slurp!
  undef $/;
  my $data = <$out>;
  my $dom = Mojo::DOM->new($data);
  for my $test (@_) {
    $test->($dom)
  }
  # reap zombie and retrieve exit status
  waitpid($pid, 0);
  my $child_exit_status = $? >> 8;
  is($child_exit_status, 0, "Exit status OK");
}

# testing

test_simple_render(
  "0101 forest\n",
  sub { ok(shift->at("g#things use"), "things") },
  sub { is(shift->at("g#coordinates text")->text, "01.01", "text") },
  sub { ok(shift->at("g#regions polygon#hex0101"), "text") });

done_testing;
