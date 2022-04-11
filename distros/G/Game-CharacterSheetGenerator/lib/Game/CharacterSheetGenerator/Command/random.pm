# Copyright (C) 2022  Alex Schroeder <alex@gnu.org>
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

Game::CharacterSheetGenerator::Command::random

=head1 SYNOPSIS

    character-sheet-generator random [language] [format] [key=value ...]
    character-sheet-generator random help

=head1 DESCRIPTION

This prints a random character SVG document to STDOUT.

    character-sheet-generator random > test.svg

=head1 OPTIONS

The supported languages are C<en> and C<de>. English is the default.

The supported formats are C<SVG> and C<text>. SVG is the default.

You can provide additional key-value pairs:

```
script/character-sheet-generator random de text name=Alex
```

C<help> prints the man page.

=cut

package Game::CharacterSheetGenerator::Command::random;

use Modern::Perl '2018';
use Mojo::Base 'Mojolicious::Command';
use Game::CharacterSheetGenerator;
use Pod::Simple::Text;
use Role::Tiny;

binmode(STDOUT, ':utf8');

has description => 'Print a random character sheet to STDOUT';

has usage => sub { my $self = shift; $self->extract_usage };

sub init {
  my %char = ();
  my @provided;
  for my $arg (@_) {
    my ($key, $value) = split(/=/, $arg, 2);
    push(@provided, $key);
    $char{$key} = $value;
  }
  $char{provided} = \@provided;
  return \%char;
}

sub run {
  my ($self, $lang, $format, @args) = @_;
  $lang ||= 'en';
  $format ||= 'SVG';
  if ($lang eq 'help') {
    seek(DATA, 0, 0); # read from this file
    my $parser = Pod::Simple::Text->new();
    $parser->output_fh(*STDOUT);
    $parser->parse_lines(<DATA>);
    return 1;
  }
  my $char = init(@args);
  Game::CharacterSheetGenerator::random_parameters($char, $lang, "portrait");
  Game::CharacterSheetGenerator::compute_data($char, $lang);
  if ($format eq 'SVG') {
    my $svg = Game::CharacterSheetGenerator::svg_transform(undef, Game::CharacterSheetGenerator::svg_read($char));
    print $svg->toString();
  } elsif ($format eq 'text') {
    for my $key (@{$char->{provided}}) {
      next unless defined $char->{$key};
      for my $value (split(/\\\\/, $char->{$key})) {
	say "$key: $value";
      }
    }
  } else {
    warn "Unknown format '$format'\n";
  }
  return 1;
}

1;

__DATA__
