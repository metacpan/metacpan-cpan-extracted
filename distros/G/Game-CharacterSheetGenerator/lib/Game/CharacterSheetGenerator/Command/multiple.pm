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

Game::CharacterSheetGenerator::Command::multiple

=head1 SYNOPSIS

    character-sheet-generator multiple [language] [key=value ...]
    character-sheet-generator multiple help

=head1 DESCRIPTION

This prints multiple characters to STDOUT.

    character-sheet-generator multiple > npc.txt

=head1 OPTIONS

The supported languages are C<en> and C<de>. English is the default.

You can provide additional key-value pairs. These can be combined. Class names
are case sensitive.

```
character-sheet-generator multiple en class=elf
```

C<help> prints the man page.

=cut

package Game::CharacterSheetGenerator::Command::multiple;

use Modern::Perl '2018';
use Mojo::Base 'Mojolicious::Command';
use Game::CharacterSheetGenerator;
use Pod::Simple::Text;
use Role::Tiny;
use Encode::Locale;
use Encode;

binmode(STDOUT, ':utf8');

has description => 'Print a bunch of characters to STDOUT';

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

sub wrap {
  my $line = "";
  for (@_) {
    if (length($line) + length > 72) {
      print $line . ",\n";
      $line = "";
    }
    $line .= ", " if $line;
    $line .= $_;
  }
  print $line . "\n" if $line;
}

sub print_char {
  my ($char, $lang) = @_;
  say $char->{traits};
  if ($lang eq 'de') {
    say "Kraft Gesc. Gesu. Bild. Weis. Auft. TP RK Klasse";
    say join("  ", map { sprintf("%4d", $_) }
	     $char->{str}, $char->{dex}, $char->{con}, $char->{int},
	     $char->{wis}, $char->{cha})
	. "  " . join(" ", map { sprintf("%2d", $_) }
		     $char->{hp}, $char->{ac})
	. " " . $char->{class};
  } else {
    say "Str Dex Con Int Wis Cha HP AC Class";
    say join(" ", map { sprintf("%3d", $_) }
	     $char->{str}, $char->{dex}, $char->{con}, $char->{int},
	     $char->{wis}, $char->{cha})
	. " " . join(" ", map { sprintf("%2d", $_) }
		     $char->{hp}, $char->{ac})
	. " " . $char->{class};
  }
  wrap(split(/\\\\/, $char->{property}));
  say "";
}

sub run {
  my ($self, $lang, @args) = @_;
  $lang ||= 'en';
  if ($lang eq 'help') {
    seek(DATA, 0, 0); # read from this file
    my $parser = Pod::Simple::Text->new();
    $parser->output_fh(*STDOUT);
    $parser->parse_lines(<DATA>);
    return 1;
  }
  my $char = init(@args);
  my $characters = Game::CharacterSheetGenerator::characters($char, $lang);
  print_char($_, $lang) for @$characters;
  return 1;
}

1;

__DATA__
