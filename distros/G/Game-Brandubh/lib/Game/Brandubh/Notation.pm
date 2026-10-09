package Game::Brandubh::Notation;

use 5.010;
use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT_OK = qw(
    SETUP
    square_name square_parse
    move_wire move_split move_parse move_display
    position_ok position_cells
    game_string game_parse
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use constant SETUP => '3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a';

my $SQUARE = qr/[a-g][1-7]/;

sub _plain {
    my ($text) = @_;
    return undef if !defined $text || ref $text;
    return "$text";
}

sub square_name {
    my ($file, $rank) = @_;
    return undef unless defined $file && defined $rank;
    return undef unless $file =~ /\A[0-6]\z/ && $rank =~ /\A[0-6]\z/;
    return chr(ord('a') + $file) . ($rank + 1);
}

sub square_parse {
    my $text = _plain($_[0]);
    return unless defined $text;
    my ($f, $r) = lc($text) =~ /\A([a-g])([1-7])\z/ or return;
    return (ord($f) - ord('a'), $r - 1);
}

sub move_wire {
    my $from = _plain($_[0]);
    my $to   = _plain($_[1]);
    return undef unless defined $from && defined $to;
    ($from, $to) = (lc $from, lc $to);
    return undef unless $from =~ /\A$SQUARE\z/ && $to =~ /\A$SQUARE\z/;
    return $from . $to;
}

sub move_split {
    my $text = _plain($_[0]);
    return unless defined $text;
    my ($from, $to) = $text =~ /\A($SQUARE)($SQUARE)\z/ or return;
    return ($from, $to);
}

sub move_parse {
    my $text = _plain($_[0]);
    return undef unless defined $text;
    $text = lc $text;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    my ($from, $to) = $text =~ /\A
        k?
        ($SQUARE) -? ($SQUARE)
        (?: x $SQUARE (?: , $SQUARE )* )?
        (?: \# | \+\+ )?
    \z/x or return undef;
    return $from . $to;
}

sub move_display {
    my ($wire, $about) = @_;
    my ($from, $to) = move_split($wire) or return undef;
    $about = {} unless ref $about eq 'HASH';

    my @captures = sort grep { /\A$SQUARE\z/ } map { lc } grep { defined && !ref }
        @{ ref $about->{captures} eq 'ARRAY' ? $about->{captures} : [] };

    my $text = ($about->{king} ? 'K' : '') . $from . '-' . $to;
    $text .= 'x' . join(',', @captures) if @captures;
    if    ($about->{king_home})  { $text .= '++' }
    elsif ($about->{king_taken}) { $text .= '#' }
    return $text;
}

sub position_ok {
    my $text = _plain($_[0]);
    return 0 unless defined $text;
    return 0 unless $text =~ m{\A ([adk1-7]+ (?: / [adk1-7]+ ){6}) [ ] [ad] \z}x;
    for my $row (split m{/}, $1) {
        my $width = 0;
        $width += /[1-7]/ ? $_ : 1 for split //, $row;
        return 0 unless $width == 7;
    }
    return 1;
}

sub position_cells {
    my $text = _plain($_[0]);
    return unless position_ok($text);
    my ($rows, $side) = split / /, $text;
    my @board;
    for my $row (split m{/}, $rows) {
        my @cells;
        for my $ch (split //, $row) {
            if ($ch =~ /[1-7]/) { push @cells, ('') x $ch }
            else                { push @cells, $ch }
        }
        push @board, \@cells;
    }
    return (\@board, $side);
}

sub game_string {
    my ($game) = @_;
    return undef unless ref $game eq 'HASH';

    my $variant = _plain($game->{variant});
    $variant = 'brandubh' unless defined $variant && length $variant;
    return undef if $variant =~ /[\r\n]/ || $variant !~ /\S/;

    my @moves;
    for my $move (@{ $game->{moves} || [] }) {
        my ($from, $to) = move_split($move) or return undef;
        push @moves, $from . $to;
    }

    my @lines = ("variant $variant");
    my $start = _plain($game->{start});
    if (defined $start && $start ne SETUP) {
        return undef unless position_ok($start);
        push @lines, "start $start";
    }
    push @lines, join(' ', 'moves', @moves);

    my $result = $game->{result};
    if (defined $result) {
        my $line = _result_line($result);
        return undef unless defined $line;
        push @lines, "result $line";
    }
    return join("\n", @lines) . "\n";
}

sub _result_line {
    my ($result) = @_;
    return undef unless ref $result eq 'HASH';
    my $how = $result->{how} // '';
    return 'agreed' if $how eq 'agreed';
    if ($how eq 'resign') {
        my $by = $result->{by} // '';
        return "resign $by" if $by eq 'attackers' || $by eq 'defenders';
    }
    return undef;
}

sub game_parse {
    my $text = _plain($_[0]);
    return undef unless defined $text;

    my @lines = grep { /\S/ } split /\r?\n/, $text;
    my %game = (start => SETUP, moves => [], result => undef);
    my %seen;

    for my $line (@lines) {
        my ($word, $rest) = $line =~ /\A(\w+)(?:[ ](.*))?\z/ or return undef;
        $rest = '' unless defined $rest;
        return undef if $seen{$word}++;

        if ($word eq 'variant') {
            return undef unless $rest =~ /\S/;
            $game{variant} = $rest;
        }
        elsif ($word eq 'start') {
            return undef unless position_ok($rest);
            $game{start} = $rest;
        }
        elsif ($word eq 'moves') {
            for my $move (split ' ', $rest) {
                my ($from, $to) = move_split($move) or return undef;
                push @{ $game{moves} }, $from . $to;
            }
        }
        elsif ($word eq 'result') {
            if    ($rest eq 'agreed')                     { $game{result} = { how => 'agreed' } }
            elsif ($rest =~ /\Aresign (attackers|defenders)\z/) { $game{result} = { how => 'resign', by => $1 } }
            else                                          { return undef }
        }
        else {
            return undef;
        }
    }
    return undef unless $seen{variant} && $seen{moves};
    return \%game;
}

1;

__END__

=head1 NAME

Game::Brandubh::Notation - squares, moves, positions and whole games as strings

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Brandubh::Notation ':all';

    my ($file, $rank) = square_parse('d4');          # (3, 3)
    my $name          = square_name(3, 3);           # 'd4'

    my $move = move_parse('Kd4-d1');                 # 'd4d1'
    my $text = move_display('d1d3', { captures => ['c3'] });    # 'd1-d3xc3'

    print "a position\n" if position_ok(SETUP);

    my $record = game_string({ variant => 'brandubh', moves => [qw(d1c1 d3c3)] });
    my $game   = game_parse($record);

=head1 DESCRIPTION

The strings a person and a log use. Functions only: nothing here holds a
board, and nothing here knows a rule. A move that this module accepts is a
move that is B<written> correctly, which is a different thing from one that
may be played.

It loads on its own, without the rest of the distribution.

=head2 A square

A file letter from C<a> to C<g> and a rank digit from C<1> to C<7>: C<a1> is
the bottom left corner as the diagram is drawn, C<d4> the throne, C<g7> the
top right corner. Written in lower case and read in either.

=head2 A move

B<As it is stored>, four characters: the square left and the square reached,
C<d1d3>. This is the form a log keeps and C<move_parse> returns.

B<As it is shown>, with what happened:

    d1-d3           a move
    d1-d3xc3        a move that captured the piece on c3
    d1-d3xc3,e3     one that captured two
    Ke4-e1          the king's move
    Kg2-g1++        the king reaching a corner
    c5-c4xd4#       the move that captured the king

The C<K> marks the king; the other pieces have no letter. Captured squares are
listed in order.

The game has no settled notation, and nothing in the rules this distribution
follows gives one. B<The two endings are this distribution's own>: C<++> for
the king reaching a corner and C<#> for his capture, so that the last line of
a finished game does not look like any other line.

What a shown move says was captured is B<commentary>. C<move_parse> reads past
it: the position decides what a move captures, and a string cannot.

=head2 A position

Seven rows from rank 7 down to rank 1 with a C</> between them, a digit for a
run of empty squares, then one space and the side to move.

    3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a

C<a> is an attacker, C<d> a defender, C<k> the king; the side is C<a> or C<d>.
That string is the set-up, and is the constant C<SETUP>.

=head2 A game

Three things, and everything else about a game can be worked out again by
playing them: the rule set, the position it started from, and the moves.

    variant brandubh
    start 7/7/7/3k3/7/7/a6 d
    moves d4d1 a1a2 d1g1

The C<start> line is left out when the game began from the set-up. A fourth
line records an ending the board cannot show, because it is something the
players did:

    result resign attackers
    result agreed

A resignation and an agreed draw are B<not moves> and are never written among
them.

=head1 CONSTANTS

=head2 SETUP

The position every game starts from unless it is told otherwise.

=head1 FUNCTIONS

Nothing is exported unless asked for. C<:all> exports everything.

=head2 square_name

    my $name = square_name($file, $rank);

The name of a square from its file and rank, both counted from 0. C<undef>
when either is off the board.

=head2 square_parse

    my ($file, $rank) = square_parse('d4');

The file and rank of a named square, both counted from 0. The empty list for
anything that is not the name of a square, without a warning.

=head2 move_wire

    my $move = move_wire('d1', 'd3');       # 'd1d3'

A stored move from two square names. C<undef> unless both are squares.

=head2 move_split

    my ($from, $to) = move_split('d1d3');

The two square names of a stored move. The empty list for anything else. It
is strict: lower case, four characters, nothing more.

=head2 move_parse

    my $move = move_parse('Kd4-d1');        # 'd4d1'

A stored move from a string a person might type or a log might show: either
form above, in either case, with or without the C<K>, the hyphen, the captures
and the ending. C<undef> for anything else.

B<It checks the writing and nothing more.> Whether a piece stands on the first
square, whether it may reach the second, and what it captures on the way are
questions for a position.

=head2 move_display

    my $text = move_display($move, \%about);

A stored move as it is shown. C<%about> says what happened, and every key is
optional:

=over 4

=item C<king>

True when the piece that moved is the king.

=item C<captures>

An array reference of the names of the squares captured.

=item C<king_home>

True when the king's move ended where he wins.

=item C<king_taken>

True when the move captured the king.

=back

C<undef> when the move is not a stored move.

=head2 position_ok

    if (position_ok($string)) { ... }

True when the string is written as a position: seven rows, each seven squares
wide, the three piece letters and the digits 1 to 7, one space, a side. It
agrees with L<Game::Brandubh::Engine/of_string> on what is and is not a
position, and like it judges the writing and never the sense: two kings pass.

=head2 position_cells

    my ($rows, $side) = position_cells($string);

The position as seven array references of seven cells, rank 7 first and file
a first, each cell C<''>, C<'a'>, C<'d'> or C<'k'>; and the side to move,
C<'a'> or C<'d'>. The empty list when the string is not a position.

=head2 game_string

    my $text = game_string(\%game);

A game as text. The keys of C<%game>:

=over 4

=item C<variant>

A word or a line naming the rule set. C<brandubh> when left out.

=item C<start>

A position. Left out, or the set-up, when the game began from the set-up.

=item C<moves>

An array reference of stored moves, in order.

=item C<result>

Left out unless the game ended by something the players did: C<< { how =>
'resign', by => 'attackers' } >>, the same with C<defenders>, or C<< { how =>
'agreed' } >>.

=back

C<undef> when any part of it is not written correctly.

=head2 game_parse

    my $game = game_parse($text);

The reverse: a hash reference with C<variant>, C<start> (the set-up when the
text had no C<start> line), C<moves> and C<result> (C<undef> when the text had
none). C<undef> when the text is not a game: a line it does not know, a line
given twice, a move or a position that is not one, or no C<variant> or
C<moves> line.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
