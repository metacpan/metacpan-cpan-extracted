package Game::Fanorona::Notation;

use 5.014;
use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.02';

use constant {
    PAIKA      => 0,
    APPROACH   => 1,
    WITHDRAWAL => 2,
};

use constant SETUP => 'bbbbbbbbb/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w';

use constant CHAIN_MAX => 44;

our @EXPORT_OK = qw(
    SETUP
    parse_point format_point square_of name_of
    parse_move format_move move_points mirror_move
    parse_position format_position mirror_position
    parse_game format_game
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my %BOARD = (
    sivy => [ 9, 5 ],
    dimy => [ 5, 5 ],
    telo => [ 3, 3 ],
);

my %DIR = (
    '0,1'   => 0,
    '1,1'   => 1,
    '1,0'   => 2,
    '1,-1'  => 3,
    '0,-1'  => 4,
    '-1,-1' => 5,
    '-1,0'  => 6,
    '-1,1'  => 7,
);

my %LETTER = (APPROACH, 'A', WITHDRAWAL, 'W');
my %KIND   = (A => APPROACH, W => WITHDRAWAL);

my %HEADER = map { $_ => 1 } qw(variant start quiet_limit repeat ply_cap white black result);
my @HEADER = qw(variant start quiet_limit repeat ply_cap white black result);

my $size_ok = sub {
    my ($cols, $rows) = @_;
    return 0 unless defined $cols && defined $rows;
    return 0 unless $cols =~ /\A[3579]\z/ && $rows =~ /\A[35]\z/;
    return 1;
};

my $size_of = sub {
    my (%arg) = @_;
    my ($cols, $rows) = ($arg{cols}, $arg{rows});
    ($cols, $rows) = (9, 5) unless defined $cols || defined $rows;
    return $size_ok->($cols, $rows) ? ($cols, $rows) : ();
};

my $fail = sub {
    my ($reason, @more) = @_;
    return wantarray ? (undef, $reason, @more) : undef;
};

sub parse_point {
    my ($name, %arg) = @_;
    my ($cols, $rows) = $size_of->(%arg) or return;
    return unless defined $name && $name =~ /\A([a-i])([1-5])\z/;
    my ($file, $rank) = (ord($1) - ord('a'), $2 - 1);
    return if $file >= $cols || $rank >= $rows;
    return ($file, $rank);
}

sub format_point {
    my ($file, $rank) = @_;
    return undef unless defined $file && defined $rank;
    return undef unless $file =~ /\A[0-8]\z/ && $rank =~ /\A[0-4]\z/;
    return chr(ord('a') + $file) . ($rank + 1);
}

sub square_of {
    my ($name) = @_;
    my ($file, $rank) = parse_point($name) or return -1;
    return ($rank + 1) * 11 + $file + 1;
}

sub name_of {
    my ($square) = @_;
    return undef unless defined $square && $square =~ /\A[0-9]+\z/;
    return format_point(($square % 11) - 1, int($square / 11) - 1);
}

sub parse_move {
    my ($string, %arg) = @_;
    my ($cols, $rows) = $size_of->(%arg) or return $fail->('bad_size');
    return $fail->('empty') unless defined $string && length $string;
    return $fail->('bad_shape')
        if $string =~ /[^A-Za-z0-9-]/ || $string =~ /\A-|-\z|--/ || $string !~ /-/;

    my ($first, @rest) = split /-/, $string;
    return $fail->('kind_on_start') if $first =~ /\A[a-z][0-9][A-Za-z]\z/;
    return $fail->('bad_point') unless $first =~ /\A[a-z][0-9]\z/;
    return $fail->('too_long') if @rest > CHAIN_MAX;

    my @tokens;
    for my $token (@rest) {
        return $fail->('bad_point') unless $token =~ /\A([a-z][0-9])(.*)\z/;
        my ($point, $letter) = ($1, $2);
        return $fail->('bad_kind') unless $letter eq '' || exists $KIND{$letter};
        push @tokens, [ $point, $letter ];
    }

    my @at = parse_point($first, cols => $cols, rows => $rows) or return $fail->('off_board');
    my @steps;
    my $from_name = $first;
    for my $token (@tokens) {
        my ($point, $letter) = @$token;
        my @to = parse_point($point, cols => $cols, rows => $rows) or return $fail->('off_board');
        my ($df, $dr) = ($to[0] - $at[0], $to[1] - $at[1]);
        return $fail->('same_point') if !$df && !$dr;
        return $fail->('not_adjacent') if abs($df) > 1 || abs($dr) > 1;
        return $fail->('no_line') if $df && $dr && ($at[0] + $at[1]) % 2;
        push @steps, {
            from => square_of($from_name),
            to   => square_of($point),
            dir  => $DIR{"$df,$dr"},
            kind => $letter eq '' ? PAIKA : $KIND{$letter},
        };
        @at = @to;
        $from_name = $point;
    }
    return $fail->('paika_in_chain') if @steps > 1 && grep { $_->{kind} == PAIKA } @steps;

    return {
        from   => $steps[0]{from},
        to     => $steps[-1]{to},
        steps  => \@steps,
        points => [ $first, map { $_->[0] } @tokens ],
    };
}

sub format_move {
    my ($move) = @_;
    return undef unless ref $move;
    my ($from, $steps) = ref $move eq 'HASH'
        ? ($move->{from}, $move->{steps})
        : ($move->from, $move->steps);
    return undef unless ref $steps eq 'ARRAY' && @$steps;
    my $text = name_of($from) // return undef;
    for my $s (@$steps) {
        my $to = name_of($s->{to}) // return undef;
        my $kind = $s->{kind} // return undef;
        return undef unless $kind == PAIKA || exists $LETTER{$kind};
        $text .= "-$to" . ($kind == PAIKA ? '' : $LETTER{$kind});
    }
    return $text;
}

sub move_points {
    my ($string, %arg) = @_;
    my $move = parse_move($string, %arg) or return;
    return @{ $move->{points} };
}

my $mirror = sub {
    my ($how, $cols, $rows, $file, $rank) = @_;
    return ($cols - 1 - $file, $rank)             if $how eq 'files';
    return ($file, $rows - 1 - $rank)             if $how eq 'ranks';
    return ($cols - 1 - $file, $rows - 1 - $rank) if $how eq 'turn';
    return;
};

sub mirror_move {
    my ($string, $how, %arg) = @_;
    my ($cols, $rows) = $size_of->(%arg) or return undef;
    my $move = parse_move($string, cols => $cols, rows => $rows) or return undef;
    my @names;
    for my $name (@{ $move->{points} }) {
        my @to = $mirror->($how // '', $cols, $rows, parse_point($name, cols => $cols, rows => $rows))
            or return undef;
        push @names, format_point(@to);
    }
    my $text = shift @names;
    for my $s (@{ $move->{steps} }) {
        $text .= '-' . shift(@names) . ($s->{kind} == PAIKA ? '' : $LETTER{ $s->{kind} });
    }
    return $text;
}

my $write_board = sub {
    my ($cols, $rows, $stones, $side) = @_;
    my @ranks;
    for my $rank (reverse 0 .. $rows - 1) {
        my ($out, $run) = ('', 0);
        for my $file (0 .. $cols - 1) {
            my $stone = $stones->{ format_point($file, $rank) };
            if (!defined $stone) { $run++; next }
            $out .= $run if $run;
            $run = 0;
            $out .= $stone;
        }
        $out .= $run if $run;
        push @ranks, $out;
    }
    return join('/', @ranks) . " $side";
};

sub parse_position {
    my ($string) = @_;
    return $fail->('empty') unless defined $string && length $string;
    return $fail->('too_long') if length $string > 80;
    my @field = split / /, $string, -1;
    return $fail->('bad_shape') unless @field == 2 || @field == 4;
    my ($board, $side, $quiet, $number) = @field;

    return $fail->('bad_letter') if $board =~ m{[^wb1-9/]};
    my @ranks = split m{/}, $board, -1;
    return $fail->('rows') unless @ranks == 3 || @ranks == 5;
    my @width = map { my $n = 0; $n += /[1-9]/ ? $_ : 1 for split //, $_; $n } @ranks;
    my $cols = $width[0];
    return $fail->('width') if grep { $_ != $cols } @width;
    return $fail->('width') unless $size_ok->($cols, scalar @ranks);
    return $fail->('side') unless $side eq 'w' || $side eq 'b';

    my $counted = @field == 4 ? 1 : 0;
    if ($counted) {
        return $fail->('bad_count') unless $quiet =~ /\A(?:0|[1-9][0-9]{0,5})\z/;
        return $fail->('bad_count') unless $number =~ /\A[1-9][0-9]{0,5}\z/;
    }

    my $rows = @ranks;
    my %stones;
    for my $i (0 .. $#ranks) {
        my $rank = $rows - 1 - $i;
        my $file = 0;
        for my $c (split //, $ranks[$i]) {
            if ($c =~ /[1-9]/) { $file += $c; next }
            $stones{ format_point($file, $rank) } = $c;
            $file++;
        }
    }
    return {
        cols    => $cols,
        rows    => $rows,
        side    => $side,
        stones  => \%stones,
        board   => $write_board->($cols, $rows, \%stones, $side),
        counted => $counted,
        quiet   => $counted ? $quiet + 0 : 0,
        move    => $counted ? $number + 0 : 1,
    };
}

sub format_position {
    my ($board, $quiet, $number) = @_;
    $quiet  = 0 unless defined $quiet;
    $number = 1 unless defined $number;
    my $position = parse_position($board) or return undef;
    return undef if $position->{counted};
    return undef unless $quiet =~ /\A(?:0|[1-9][0-9]{0,5})\z/ && $number =~ /\A[1-9][0-9]{0,5}\z/;
    return "$position->{board} $quiet $number";
}

sub mirror_position {
    my ($string, $how) = @_;
    my $position = parse_position($string) or return undef;
    my ($cols, $rows) = @{$position}{qw(cols rows)};
    my %stones;
    for my $name (keys %{ $position->{stones} }) {
        my @to = $mirror->($how // '', $cols, $rows, parse_point($name, cols => $cols, rows => $rows))
            or return undef;
        $stones{ format_point(@to) } = $position->{stones}{$name};
    }
    my $text = $write_board->($cols, $rows, \%stones, $position->{side});
    return $position->{counted} ? "$text $position->{quiet} $position->{move}" : $text;
}

my $variant_size = sub {
    my ($variant) = @_;
    return @{ $BOARD{$variant} } if exists $BOARD{$variant};
    return ($1, $2) if $variant =~ /\A([0-9])x([0-9])\z/ && $size_ok->($1, $2);
    return;
};

sub format_game {
    my ($game) = @_;
    return undef unless ref $game eq 'HASH';
    my %header = (variant => 'sivy', map { $_ => $game->{$_} } grep { defined $game->{$_} } @HEADER);
    return undef if grep { !$HEADER{$_} && $_ ne 'moves' } keys %$game;
    my $moves = $game->{moves} // [];
    return undef unless ref $moves eq 'ARRAY';
    my $text = "fanorona 1\n";
    for my $key (@HEADER) {
        next unless defined $header{$key};
        return undef if $header{$key} =~ /[^\x20-\x7e]/ || $header{$key} !~ /\S/;
        $text .= "$key $header{$key}\n";
    }
    $text .= "moves\n";
    $text .= "$_\n" for @$moves;
    return undef unless parse_game($text);
    return $text;
}

sub parse_game {
    my ($text) = @_;
    return $fail->('empty', 0) unless defined $text && length $text;
    my @lines = split /\n/, $text;
    return $fail->('not_a_game', 1) unless @lines && $lines[0] eq 'fanorona 1';

    my (%game, $n);
    for ($n = 1; $n < @lines; $n++) {
        my $line = $lines[$n];
        last if $line eq 'moves';
        return $fail->('bad_header', $n + 1) unless $line =~ /\A([a-z_]+) (\S.*)\z/;
        my ($key, $value) = ($1, $2);
        return $fail->('unknown_header', $n + 1) unless $HEADER{$key};
        return $fail->('repeated_header', $n + 1) if exists $game{$key};
        return $fail->('bad_header', $n + 1) if $value =~ /[^\x20-\x7e]/;
        return $fail->('bad_number', $n + 1)
            if $key =~ /\A(?:quiet_limit|repeat|ply_cap)\z/ && $value !~ /\A(?:0|[1-9][0-9]{0,5})\z/;
        $game{$key} = $value;
    }
    return $fail->('no_moves_line', scalar @lines) unless $n < @lines;
    my $moves_at = $n;

    $game{variant} = 'sivy' unless defined $game{variant};
    my ($cols, $rows) = $variant_size->($game{variant})
        or return $fail->('bad_variant', 2);
    if (defined $game{start}) {
        my $start = parse_position($game{start}) or return $fail->('bad_start', 2);
        return $fail->('bad_start', 2) unless $start->{cols} == $cols && $start->{rows} == $rows;
    }

    my @moves;
    for my $i ($moves_at + 1 .. $#lines) {
        my $move = $lines[$i];
        my ($parsed, $reason) = parse_move($move, cols => $cols, rows => $rows);
        return $fail->($reason, $i + 1) unless $parsed;
        push @moves, $move;
    }
    $game{moves} = \@moves;
    $game{moves_at} = $moves_at + 2;
    $game{cols} = $cols;
    $game{rows} = $rows;
    return \%game;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Fanorona::Notation - moves, positions and games of fanorona as text

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Game::Fanorona::Notation ':all';

    my ($move, $why) = parse_move('b2-c2A-c3A');
    print format_move($move), "\n";                  # b2-c2A-c3A
    print join(' ', move_points('b2-c2A-c3A')), "\n"; # b2 c2 c3

    my $position = parse_position(SETUP);
    print $position->{stones}{d3}, "\n";             # w

    print mirror_move('d3-e3A', 'files'), "\n";      # f3-e3A

=head1 DESCRIPTION

Functions that read and write fanorona as text. There is no object here and
B<no compiled code is loaded>: this module can tell a move from a typo, or
read a saved game, on a machine where the rest of the distribution was never
built.

B<It knows shape and not rules.> C<parse_move> will tell you that C<b2-c4> is
not a step and that a diagonal does not leave C<e2>. It will not tell you
whether there is a stone on C<b2>, whose turn it is, or whether the step
takes what its letter says: that is L<Game::Fanorona::Rules>.

Nothing is exported unless asked for; C<:all> asks for everything.

=head2 A point

A file letter C<a> to C<i> and a rank digit C<1> to C<5>: C<a1> is the corner
on White's left, C<e3> the centre of the nine by five. Always lower case.

=head2 A move

    b2-b1            a paika: one step that takes nothing
    b2-c2A           b2 to c2, taking by approach
    f4-e4W           f4 to e4, taking by withdrawal
    b2-c2A-c3A       a chain: two steps by the same stone

The stone's points in order, joined by dashes, with C<A> or C<W> after each
point it arrived on by a step that took. This is the notation of the 2008
paper that solved the game, Schadd et al., "Best Play in Fanorona Leads to
Draw".

B<A step that takes always carries its letter>, even where only one of the
two ways was possible, so a move can be read with no board beside it. Every
step of a chain takes, so a move of two steps or more has a letter on each.

=head2 A position

    bbbbbbbbb/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w
    bbbbbbbbb/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w 0 1

Ranks from the top down, C<w> and C<b> for stones, a digit for a run of empty
points, C</> between ranks; then the side to move. The size of the board is
read from the string.

The second form adds two counts for a game in progress: how many moves
running have taken nothing, and the number of the move about to be made,
starting from 1. The first form is what L<Game::Fanorona::Engine/of_string>
reads; C<parse_position> reads both and hands the first back as C<board>.

A position is always B<between> moves. There is no way to write a chain half
made.

=head2 A game

    fanorona 1
    variant sivy
    quiet_limit 60
    white Rakoto
    moves
    d3-e3A
    c3-d3W

A first line that says what this is, header lines of a word and a value, a
line C<moves>, and then one move a line. The headers are C<variant> (C<sivy>,
C<dimy>, C<telo>, or a size such as C<7x5>; C<sivy> when absent), C<start> (a
position, when the game does not begin from the set-up), C<quiet_limit>,
C<repeat>, C<ply_cap>, C<white>, C<black> and C<result>.

That is everything needed to play a game again, because nothing in fanorona
is left to chance.

=head1 FUNCTIONS

=head2 parse_point

    my ($file, $rank) = parse_point('e3');
    my ($file, $rank) = parse_point('c3', cols => 3, rows => 3);

The file and rank of a point, each counted from 0, or an empty list when the
name is not a point of a board that size. The size is the nine by five unless
given.

=head2 format_point

    format_point(4, 2)    # e3

The name of a file and rank, or C<undef>.

=head2 square_of

    my $sq = square_of('e3');

The number L<Game::Fanorona::Engine> uses for a point, or -1.

=head2 name_of

    name_of($sq)    # e3

The name of one of the engine's numbers, or C<undef>.

=head2 parse_move

    my $move = parse_move('b2-c2A-c3A');
    my ($move, $why) = parse_move($string, cols => 5, rows => 5);

A move as a hash, or C<undef>; in list context C<undef> and a word for why.

    {
        from   => $sq,                # the engine's number for the first point
        to     => $sq,                # and for the last
        points => [ 'b2', 'c2', 'c3' ],
        steps  => [
            { from => $sq, to => $sq, dir => 2, kind => 1 },
            { from => $sq, to => $sq, dir => 0, kind => 1 },
        ],
    }

Each step is what L<Game::Fanorona::Rules/step> and
L<Game::Fanorona::Engine/play> take, so a parsed move can be played a step at
a time as it stands. C<dir> is 0 to 7 clockwise from north; C<kind> is 0 for
a paika, 1 for an approach and 2 for a withdrawal.

The reasons, in the order they are looked for:

=over 4

=item C<bad_size>

The board asked for is not one.

=item C<empty>

No string.

=item C<bad_shape>

No dash, a dash at either end, two dashes together, or a character that is
not a letter, a digit or a dash.

=item C<kind_on_start>

A letter after the first point. A stone does not arrive where it starts.

=item C<bad_point>

Something that is not a lower-case letter and a digit where a point belongs.

=item C<too_long>

More than forty-four steps. No move is.

=item C<bad_kind>

Something after a point that is not C<A> or C<W>. A lower-case C<a> is this.

=item C<off_board>

A point that is not on a board of this size.

=item C<same_point>

A step from a point to itself.

=item C<not_adjacent>

A step between points that are not next to each other.

=item C<no_line>

A diagonal step from a point that has no diagonal.

=item C<paika_in_chain>

A move of two steps or more with a step that has no letter.

=back

=head2 format_move

    my $string = format_move($move);

The string for a move: either the hash C<parse_move> returns or a
L<Game::Fanorona::Move>. C<undef> for anything else.

=head2 move_points

    my @names = move_points('b2-c2A-c3A');    # b2 c2 c3

Every point a move touches, in order; an empty list for a string that is not
a move.

=head2 mirror_move

    mirror_move('d3-e3A', 'files')    # f3-e3A
    mirror_move('d3-e3A', 'ranks')    # d3-e3A
    mirror_move('d2-e3A', 'turn')     # f4-e3A

A move reflected: C<files> swaps left and right, C<ranks> swaps top and
bottom, C<turn> is half a turn of the board. The letters do not change: a
reflected approach is an approach. C<undef> for a string that is not a move.

=head2 parse_position

    my $position = parse_position($string);
    my ($position, $why) = parse_position($string);

A position as a hash, or C<undef> and a word for why.

    {
        cols    => 9,
        rows    => 5,
        side    => 'w',
        stones  => { a1 => 'w', ... },
        board   => 'bbbbbbbbb/.../wwwwwwwww w',   # the two-field form, canonical
        counted => 1,                              # the string had the counts
        quiet   => 0,
        move    => 1,
    }

C<board> is always written the one way the engine writes it: a string that
spells a run of five empty points as C<41> is read, and comes back as C<5>.

The reasons: C<empty>; C<too_long>; C<bad_shape> for a string that is not two
fields or four; C<bad_letter> for a character in the board that is not C<w>,
C<b>, C</> or a digit 1 to 9; C<rows> for a number of ranks that is not three
or five; C<width> for ranks of different widths or a width that is not 3, 5,
7 or 9; C<side>; and C<bad_count> for counts that are not whole numbers, or a
move number below 1.

=head2 format_position

    my $string = format_position($board, $quiet, $move);

The four-field form from the two-field one and the two counts, which are 0
and 1 when left out. C<undef> if the board is not a position or already has
counts, or a count is not a number.

=head2 mirror_position

    mirror_position($string, 'files')

A position reflected, in the three ways C<mirror_move> reflects a move. The
side to move and the counts are kept.

=head2 format_game

    my $text = format_game({ variant => 'sivy', white => 'Rakoto', moves => \@strings });

The text of a game, or C<undef> when a header is not one this module knows,
a value is empty or has a character outside plain ASCII, or a move is not a
move. What it writes is always something C<parse_game> reads.

=head2 parse_game

    my $game = parse_game($text);
    my ($game, $why, $line) = parse_game($text);

A game as a hash: each header that was present, C<variant> always, C<cols>
and C<rows> for its board, C<moves>, an array reference of move strings, and
C<moves_at>, the number of the line the first move is on or would be on.
Or C<undef>, a word for why, and the number of the line at fault.

The reasons: C<empty>, C<not_a_game> for a first line that is not
C<fanorona 1>, C<bad_header>, C<unknown_header>, C<repeated_header>,
C<bad_number>, C<no_moves_line>, C<bad_variant>, C<bad_start>, and any reason
C<parse_move> gives for a move. A move that parses is already written the one
way C<format_move> writes it, so nothing more is asked of it.

B<A game that parses is well formed, and may still not be a game.> Whether
each move was legal when it was made is found out by playing it.

=head1 CONSTANTS

=head2 SETUP

The position string of the set-up of the nine by five, in the two-field form.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
