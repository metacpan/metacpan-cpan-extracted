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

Game::TextMapper::Command::random

=head1 SYNOPSIS

    text-mapper random [algorithm] [options]
    text-mapper random help

=head1 DESCRIPTION

This prints a random map description to STDOUT.

    text-mapper random | text-mapper render > map.svg

=head1 OPTIONS

C<help> prints the man page.

The algorithm can be any module that Perl can load using C<require>. By default,
these are the ones:

=over

=item * L<Game::TextMapper::Apocalypse>

=item * L<Game::TextMapper::Gridmapper>

=item * L<Game::TextMapper::Schroeder::Alpine> (needs role)

=item * L<Game::TextMapper::Schroeder::Island> (needs role)

=item * L<Game::TextMapper::Smale>

=item * L<Game::TextMapper::Traveller>

=back

The default algorithm is L<Game::TextMapper::Smale>.

Valid options depend on the algorithm. If an algorithm needs a role, you can
provide it using the C<--role> option.

    text-mapper random Game::TextMapper::Schroeder::Alpine \
        --role Game::TextMapper::Schroeder::Hex

If you don't do this, you'll get errors such as:

    Can't locate object method "random_neighbor" via package ...

That's because C<random_neighbor> must differ depending on whether we are
looking at a hex map (6) or a square map (4).

The two roles currently used:

=over

=item * L<Game::TextMapper::Schroeder::Hex>

=item * L<Game::TextMapper::Schroeder::Square>

=back

=head1 DEVELOPING YOUR OWN

The algorithm modules must be classes one instantiates using C<new> and they
must provide a method called C<generate_map> that returns a string.

Assume you write your own, and put it in the F<./lib> directory, called
F<Arrakis.pm>. Here is a sample implementation. It uses L<Mojo::Base> to make it
a class.

    package Arrakis;
    use Modern::Perl;
    use Mojo::Base -base;
    sub generate_map {
      for my $x (0 .. 10) {
	for my $y (0 .. 10) {
	  printf("%02d%02d dust desert\n", $x, $y);
	}
      }
      say "include gnomeyland.txt";
    }
    1;

Since the lib directory is in @INC when called via F<text-mapper>, you run it
like this:

    text-mapper random Arrakis | text-mapper render > map.svg

Any extra arguments are passed along to the call to C<generate_map>.

=cut

package Game::TextMapper::Command::random;

use Modern::Perl '2018';
use Mojo::Base 'Mojolicious::Command';
use Pod::Simple::Text;
use Getopt::Long qw(GetOptionsFromArray);
use Role::Tiny;
binmode(STDOUT, ':utf8');

has description => 'Print a random map to STDOUT';

has usage => sub { my $self = shift; $self->extract_usage };

sub run {
  my ($self, $module, @args) = @_;
  $module ||= 'Game::TextMapper::Smale';
  if ($module eq 'help') {
    seek(DATA, 0, 0); # read from this file
    my $parser = Pod::Simple::Text->new();
    $parser->output_fh(*STDOUT);
    $parser->parse_lines(<DATA>);
    return 1;
  }
  my $res = eval "require $module"; # require needs bareword!
  die "random: compilation of module '$module' failed: $!\n" unless defined $res;
  die "$module did not return a true value\n" unless $res;
  my $obj = eval "${module}->new";
  die "random: module '$module->new' failed: $@" unless defined $obj;
  die "random: module '$module->new' did not return a value\n" unless $obj;
  my @roles;
  GetOptionsFromArray (\@args, "role=s" => \@roles);
  Role::Tiny->apply_roles_to_object($obj, @roles) if @roles;
  print $obj->generate_map(@args);
}

1;

__DATA__
