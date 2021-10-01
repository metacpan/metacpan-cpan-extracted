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

Game::FaceGenerator::Command::random - random subcommand for the command-line

=head1 SYNOPSIS

    face-generator random [artist] [type]
    face-generator random help

=head1 DESCRIPTION

This prints a random image to STDOUT.

    face-generator random alex man > man.png

=head1 OPTIONS

C<help> prints the man page.

=head1 EXAMPLES

    face-generator random alex man | display

=cut

package Game::FaceGenerator::Command::random;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Command';
use Pod::Simple::Text;
use Game::FaceGenerator::Core qw(random_components render_components);

has description => 'Print a random face to STDOUT';

has usage => sub { my $self = shift; $self->extract_usage };

sub run {
  my ($self, $artist, $type, @args) = @_;
  $artist ||= 'alex';
  $type ||= 'woman';
  if ($artist eq 'help') {
    seek(DATA, 0, 0); # read from this file
    my $parser = Pod::Simple::Text->new();
    $parser->output_fh(*STDOUT);
    $parser->parse_lines(<DATA>);
    return 1;
  }
  my @components = random_components($type, $artist);
  if (-t STDOUT) {
    say "@components";
    say "To generate an image, redirect stdout to a file."
  } else {
    print render_components($artist, @components);
  }
}

1;

__DATA__
