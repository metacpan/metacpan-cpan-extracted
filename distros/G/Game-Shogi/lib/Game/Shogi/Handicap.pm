package Game::Shogi::Handicap;

use 5.014;
use strict;
use warnings;
use utf8;

our $VERSION = '0.01';

my @ORDER = qw(lance bishop rook rook_lance two four six eight nine ten);

my %TABLE = (
    lance      => [ 'Lance',      '香落ち',   [qw(1a)] ],
    bishop     => [ 'Bishop',     '角落ち',   [qw(2b)] ],
    rook       => [ 'Rook',       '飛車落ち', [qw(8b)] ],
    rook_lance => [ 'Rook–Lance', '飛香落ち', [qw(8b 1a)] ],
    two        => [ '2-Piece',    '二枚落ち', [qw(8b 2b)] ],
    four       => [ '4-Piece',    '四枚落ち', [qw(8b 2b 9a 1a)] ],
    six        => [ '6-Piece',    '六枚落ち', [qw(8b 2b 9a 1a 8a 2a)] ],
    eight      => [ '8-Piece',    '八枚落ち', [qw(8b 2b 9a 1a 8a 2a 7a 3a)] ],
    nine       => [ '9-Piece',    '九枚落ち', [qw(8b 2b 9a 1a 8a 2a 7a 3a 4a)] ],
    ten        => [ '10-Piece',   '十枚落ち', [qw(8b 2b 9a 1a 8a 2a 7a 3a 4a 6a)] ],
);

my $START = 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL';

sub names    { @ORDER }
sub known    { defined $_[1] && exists $TABLE{ $_[1] } ? 1 : 0 }
sub english  { $_[0]->known($_[1]) ? $TABLE{ $_[1] }[0] : undef }
sub japanese { $_[0]->known($_[1]) ? $TABLE{ $_[1] }[1] : undef }
sub removed  { $_[0]->known($_[1]) ? @{ $TABLE{ $_[1] }[2] } : () }

sub sfen {
    my ($class, $name) = @_;
    return undef unless $class->known($name);
    require Game::Shogi::Engine;
    my $b = Game::Shogi::Engine->new(sfen => "$START w - 1");
    $b->lift(Game::Shogi::Engine->square($_)) for $class->removed($name);
    return $b->sfen;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Shogi::Handicap - the handicaps, as the stronger player gives them

=head1 SYNOPSIS

    use Game::Shogi::Handicap;
    my $H = 'Game::Shogi::Handicap';

    for my $name ($H->names) {
        printf "%-10s %s %s\n", $name, $H->japanese($name), $H->sfen($name);
    }

=head1 DESCRIPTION

In a handicap game the stronger player, the giver, plays White, starts without
some pieces, and moves first. The pieces removed are gone: they are never in
a hand and never come back. The ten here are the official handicaps and the
three larger ones taught to beginners.

"Left" means the giver's own left: the left lance is White's lance on 1a, and
the 9-Piece's left gold is White's gold on 4a.

=head1 METHODS

=head2 names

C<lance>, C<bishop>, C<rook>, C<rook_lance>, C<two>, C<four>, C<six>,
C<eight>, C<nine> and C<ten>, from the smallest handicap to the largest.

=head2 known

True for one of the names.

=head2 english

    Game::Shogi::Handicap->english('rook_lance')    # Rook–Lance

=head2 japanese

    Game::Shogi::Handicap->japanese('two')          # 二枚落ち

=head2 removed

The squares White's removed pieces stood on, as USI names them.

=head2 sfen

The start of that handicap game: the standard start less those pieces, White
to move, move 1. C<undef> for a name that is not one.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
