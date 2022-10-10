# Copyright (C) 2009-2021  Alex Schroeder <alex@gnu.org>
#
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
# with this program. If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

Game::TextMapper::Command::render

=head1 SYNOPSIS

    text-mapper random [--hex|--square|help]

=head1 DESCRIPTION

This takes a map description on STDIN and prints the SVG on STDOUT.

    text-mapper random | text-mapper render > map.svg

=head1 OPTIONS

C<help> prints the man page.

C<--hex> is the default: this uses L<Game::TextMapper::Mapper::Hex> to render a
hex map.

C<--square> uses L<Game::TextMapper::Mapper::Square> to render a square map.

This is important if the algorithm can produce both kinds of map, like
L<Game::TextMapper::Schroeder::Alpine>.

=head1 EXAMPLES

Hex map:

    text-mapper random Game::TextMapper::Schroeder::Alpine \
        --role Game::TextMapper::Schroeder::Hex \
    | text-mapper render > map.svg

Square map:

    text-mapper random Game::TextMapper::Schroeder::Alpine \
        --role Game::TextMapper::Schroeder::Square \
    | text-mapper render --square > map.svg

=cut

package Game::TextMapper::Command::render;
use Modern::Perl '2018';
use Mojo::Base 'Mojolicious::Command';
use File::ShareDir 'dist_dir';
use Pod::Simple::Text;
use Getopt::Long qw(GetOptionsFromArray);
use Encode;

has description => 'Render map from STDIN to STDOUT, as SVG (all UTF-8)';

has usage => sub { my $self = shift; $self->extract_usage };

sub run {
  my ($self, @args) = @_;
  my $dist_dir = $self->app->config('contrib') // dist_dir('Game-TextMapper');
  my $hex;
  my $square;
  if (@args and $args[0] eq 'help') {
    seek(DATA, 0, 0); # read from this file
    my $parser = Pod::Simple::Text->new();
    $parser->output_fh(*STDOUT);
    $parser->parse_lines(<DATA>);
    return 1;
  }
  GetOptionsFromArray (\@args, "hex" => \$hex, "square" => \$square);
  warn "Unhandled arguments: @args\n" if @args;
  my $mapper;
  if ($square) {
    $mapper = Game::TextMapper::Mapper::Square->new(dist_dir => $dist_dir, local_files => 1);
  } else {
    $mapper = Game::TextMapper::Mapper::Hex->new(dist_dir => $dist_dir, local_files => 1);
  }
  local $/ = undef;
  $mapper->initialize(decode_utf8 <STDIN>);
  print encode_utf8 $mapper->svg;
}

1;

__DATA__
