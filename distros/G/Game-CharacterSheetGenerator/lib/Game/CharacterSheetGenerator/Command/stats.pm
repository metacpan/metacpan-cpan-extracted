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

Game::CharacterSheetGenerator::Command::stats

=head1 SYNOPSIS

    character-sheet-generator stats [language] [n]
    character-sheet-generator stats help

=head1 DESCRIPTION

This counts the classes picked and the equipment bought.

    character-sheet-generator stats

=head1 OPTIONS

The supported languages are C<en> and C<de>. English is the default.

The number of characters generated is C<n>. The default is 100.

You can provide additional key-value pairs. These can be combined. Class names
are case sensitive.

```
character-sheet-generator stats en 50 class=elf
```

C<help> prints the man page.

=cut

package Game::CharacterSheetGenerator::Command::stats;

use Modern::Perl '2018';
use Mojo::Base 'Mojolicious::Command';
use Game::CharacterSheetGenerator;
use Pod::Simple::Text;
use Role::Tiny;
use Encode::Locale;
use Encode;

binmode(STDOUT, ':utf8');

has description => 'Print stats for random characters to STDOUT';

has usage => sub { my $self = shift; $self->extract_usage };

sub init {
  my %char = ();
  my @provided;
  for my $arg (@_) {
    my ($key, $value) = split(/=/, $arg, 2);
    push(@provided, $key);
    $char{$key} = decode(locale => $value);
  }
  $char{provided} = \@provided;
  return \%char;
}

sub run {
  my ($self, $lang, $n, @args) = @_;
  $lang ||= 'en';
  $n ||= 100;
  if ($lang eq 'help') {
    seek(DATA, 0, 0); # read from this file
    my $parser = Pod::Simple::Text->new();
    $parser->output_fh(*STDOUT);
    $parser->parse_lines(<DATA>);
    return 1;
  }
  my $char = init(@args);
  say Game::CharacterSheetGenerator::stats($char, $lang, $n);
  return 1;
}

1;

__DATA__
