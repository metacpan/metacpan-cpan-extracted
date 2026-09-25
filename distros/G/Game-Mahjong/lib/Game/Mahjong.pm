package Game::Mahjong;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;

sub dl_load_flags { 0x01 }

XSLoader::load('Game::Mahjong', $VERSION);

use Game::Mahjong::Tiles;
use Game::Mahjong::Notation;
use Game::Mahjong::Error;
use Game::Mahjong::Wall;
use Game::Mahjong::Meld;
use Game::Mahjong::Hand;
use Game::Mahjong::Decompose;
use Game::Mahjong::Fan;
use Game::Mahjong::Fans;
use Game::Mahjong::Tally;
use Game::Mahjong::Score;
use Game::Mahjong::Result;
use Game::Mahjong::Rules;
use Game::Mahjong::Shanten;
use Game::Mahjong::Search;
use Game::Mahjong::Bot;

1;

__END__

=head1 NAME

Game::Mahjong - Mahjong, the four-player tile game, under the Chinese Official competition rules

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Mahjong;

    my @set = Game::Mahjong::Tiles::set();          # 144 kind ids
    Game::Mahjong::Tiles::code_of(5);               # "m5"
    Game::Mahjong::Tiles::is_terminal(9);           # 1, the nine of characters

    my @hand = Game::Mahjong::Notation::parse('123m 55p EEE');

=head1 DESCRIPTION

The engine for Mahjong under the World Mahjong Organization's competition
rules (2006), the ruleset the European federations play: 144 tiles including
the eight flowers, chow, pung and kong claims, robbing the kong, the
eighty-one scoring elements in twelve grades, and a minimum of eight points to
win.

It is the engine behind the Mahjong at L<https://peer2peergames.com>.

=head1 METHODS

=head2 dl_load_flags

Returns C<0x01> so the shared object is loaded with its symbols global, which
is what lets another XS module link against the table. Not for calling.

=head1 SEE ALSO

L<Game::Mahjong::Tiles>, L<Game::Mahjong::Notation>, L<Game::Mahjong::Error>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
