package Game::RoyalUr::Notation;

use 5.010;
use strict;
use warnings;

use Exporter 'import';
use Scalar::Util ();

use Game::RoyalUr::Dice ();

our $VERSION = '0.01';

use constant {
    POS_OK     => 0,
    POS_NULL   => 1,
    POS_ROWS   => 2,
    POS_WIDTH  => 3,
    POS_LETTER => 4,
    POS_GAP    => 5,
    POS_X      => 6,
    POS_SIDE   => 7,
    POS_COUNT  => 8,
    POS_FIELD  => 9,
    POS_LONG   => 10,
};

our (@EXPORT_OK, %EXPORT_TAGS);
my (%MISSING, %ROSETTE, %NAMED, @FIELDS, %SIDE_OF, %LETTER_OF, %RESULT_OK);
BEGIN {
    @EXPORT_OK = qw(
        square_ok parse_move format_move format_display format_forfeit
        validate_position parse_record format_record
        POS_OK POS_NULL POS_ROWS POS_WIDTH POS_LETTER POS_GAP POS_X
        POS_SIDE POS_COUNT POS_FIELD POS_LONG
    );
    %EXPORT_TAGS = (all => \@EXPORT_OK);

    %MISSING = map { $_ => 1 } qw(e1 f1 e3 f3);
    %ROSETTE = map { $_ => 1 } qw(a1 g1 a3 g3 d2);
    %NAMED = (
        finkel  => { route => 'short', dice => 4, zero_rolls => 0, safe_rosettes => 1, pieces => 7 },
        masters => { route => 'long',  dice => 3, zero_rolls => 4, safe_rosettes => 0, pieces => 7 },
    );
    @FIELDS    = qw(route dice zero_rolls safe_rosettes pieces);
    %SIDE_OF   = (l => 'light', d => 'dark');
    %LETTER_OF = (light => 'l', dark => 'd');
    %RESULT_OK = (
        'light home'   => 1, 'dark home'   => 1,
        'light resign' => 1, 'dark resign' => 1,
        'draw ply_cap' => 1,
    );
}

sub square_ok {
    my ($name) = @_;
    return 0 unless defined $name && $name =~ /\A[a-h][1-3]\z/;
    return $MISSING{$name} ? 0 : 1;
}

my $place = sub {
    my ($text) = @_;
    my $lower = lc $text;
    return $lower if $lower eq 'hand' || $lower eq 'home';
    return undef unless $text =~ /\A[A-Ha-h][1-3]\z/;
    return square_ok($lower) ? $lower : undef;
};

sub parse_move {
    my ($text) = @_;
    return (undef, 'empty') unless defined $text && length $text;
    my @parts = split /-/, $text, -1;
    return (undef, 'shape') unless @parts == 2;
    my ($from, $to) = map { $place->($_) } @parts;
    return (undef, 'place') unless defined $from && defined $to;
    return (undef, 'from_home') if $from eq 'home';
    return (undef, 'to_hand') if $to eq 'hand';
    return ({ from => $from, to => $to }, undef);
}

my $read = sub {
    my ($move, $name) = @_;
    return $move->$name if Scalar::Util::blessed($move) && $move->can($name);
    return ref $move eq 'HASH' ? $move->{$name} : undef;
};

sub format_move {
    my ($move) = @_;
    return $read->($move, 'from') . '-' . $read->($move, 'to');
}

sub format_display {
    my ($move, $roll) = @_;
    $roll = $read->($move, 'roll') unless defined $roll;
    return $roll . ': ' . format_move($move)
        . ($read->($move, 'captures') ? 'x' : '')
        . ($read->($move, 'rosette')  ? '*' : '');
}

sub format_forfeit {
    my ($roll) = @_;
    return $roll . ': -';
}

sub validate_position {
    my ($text) = @_;
    return POS_NULL unless defined $text && length $text;
    return POS_LONG if length $text >= 48;

    my @c = split //, $text;
    my ($row, $file, $i) = (2, 0, 0);
    my $gap = sub { $row != 1 && ($file == 4 || $file == 5) };

    for (; $i < @c && $c[$i] ne ' '; $i++) {
        my $ch = $c[$i];
        if ($ch eq '/') {
            return POS_WIDTH if $file != 8;
            return POS_ROWS  if $row == 0;
            $row--;
            $file = 0;
            next;
        }
        if ($ch =~ /\A[1-8]\z/) {
            for (1 .. $ch) {
                return POS_WIDTH if $file >= 8;
                return POS_GAP   if $gap->();
                $file++;
            }
            next;
        }
        if ($ch eq 'x') {
            return POS_WIDTH if $file >= 8;
            return POS_X unless $gap->();
            $file++;
            next;
        }
        return POS_LETTER unless $ch eq 'l' || $ch eq 'd';
        return POS_WIDTH if $file >= 8;
        return POS_GAP   if $gap->();
        $file++;
    }
    return POS_ROWS  if $row != 0;
    return POS_WIDTH if $file != 8;

    return POS_FIELD unless $i < @c && $c[$i] eq ' ';
    $i++;
    return POS_SIDE unless $i < @c && ($c[$i] eq 'l' || $c[$i] eq 'd');
    $i++;
    for (1 .. 4) {
        return POS_FIELD unless $i < @c && $c[$i] eq ' ';
        $i++;
        return POS_FIELD if $i >= @c;
        return POS_COUNT unless $c[$i] =~ /\A[0-7]\z/;
        $i++;
        return POS_COUNT if $i < @c && $c[$i] ne ' ';
    }
    return POS_FIELD if $i < @c;
    return POS_OK;
}

my $rules_text = sub {
    my ($rules) = @_;
    return $rules unless ref $rules;
    return join ' ', map { "$_=$rules->{$_}" } @FIELDS;
};

my $rules_of = sub {
    my ($text) = @_;
    return $text if exists $NAMED{$text};
    my (%given, @names);
    for my $pair (split / /, $text, -1) {
        my ($name, $value) = $pair =~ /\A([a-z_]+)=([a-z0-9]+)\z/ or return undef;
        push @names, $name;
        $given{$name} = $value;
    }
    return undef unless "@names" eq "@FIELDS";
    return undef unless $given{route} =~ /\A(?:short|long)\z/
        && $given{dice} =~ /\A[34]\z/ && $given{zero_rolls} =~ /\A[04]\z/
        && $given{safe_rosettes} =~ /\A[01]\z/ && $given{pieces} =~ /\A[1-7]\z/;
    return \%given;
};

my $spelled = sub { ref $_[0] ? $_[0] : $NAMED{ $_[0] } };

sub format_record {
    my ($record) = @_;
    my @lines = (
        '[rules ' . $rules_text->($record->{rules}) . ']',
        '[first ' . $record->{first} . ']',
    );
    push @lines, '[seed ' . $record->{seed} . ']' if defined $record->{seed};
    push @lines, '[opening ' . $record->{opening} . ']' if $record->{opening};
    my $n = 0;
    for my $turn (@{ $record->{turns} || [] }) {
        $n++;
        push @lines, $n . '. ' . $LETTER_OF{ $turn->{side} } . ' ' . $turn->{roll}
            . (defined $turn->{faces} ? ' ' . $turn->{faces} : '')
            . ': ' . (defined $turn->{move} ? $turn->{move} : '-');
    }
    push @lines, '[result ' . $record->{result}{winner} . ' ' . $record->{result}{how} . ']'
        if $record->{result};
    return join("\n", @lines) . "\n";
}

sub parse_record {
    my ($text) = @_;
    my $fail = sub { return (undef, { line => $_[0], error => $_[1] }) };
    return $fail->(0, 'empty') unless defined $text && length $text;
    return $fail->(0, 'no_newline') unless $text =~ /\n\z/;

    my @lines = split /\n/, $text, -1;
    pop @lines;
    my %record = (turns => []);
    my ($at, $expect, $done) = (0, undef, 0);

    my $header = sub {
        my ($name, $pattern) = @_;
        return undef unless $at < @lines && $lines[$at] =~ /\A\[\Q$name\E ($pattern)\]\z/;
        $at++;
        return $1;
    };

    my $rules = $header->('rules', '[a-z0-9_= ]+');
    return $fail->($at + 1, 'rules') unless defined $rules;
    $record{rules} = $rules_of->($rules);
    return $fail->($at, 'rules') unless defined $record{rules};
    my $set = $spelled->($record{rules});

    $record{first} = $header->('first', 'light|dark');
    return $fail->($at + 1, 'first') unless defined $record{first};

    my $seed = $header->('seed', '(?:[0-9a-f]{2})+');
    $record{seed} = $seed if defined $seed;
    my $opening = $header->('opening', '[1-9][0-9]*');
    $record{opening} = $opening + 0 if defined $opening;
    return $fail->($at, 'opening') if defined $opening && ($opening % 2 || !defined $seed);

    my $bytes = defined $seed ? pack('H*', $seed) : undef;
    my $throw = $record{opening} || 0;
    $expect = $record{first};

    for (; $at < @lines; $at++) {
        my $line = $lines[$at];
        my $number = $at + 1;
        return $fail->($number, 'after_result') if $done;

        if ($line =~ /\A\[result ([a-z_]+ [a-z_]+)\]\z/) {
            return $fail->($number, 'result') unless $RESULT_OK{$1};
            my ($winner, $how) = split / /, $1;
            $record{result} = { winner => $winner, how => $how };
            $done = 1;
            next;
        }

        my ($n, $letter, $roll, $faces, $move) =
            $line =~ /\A([1-9][0-9]*)\. ([ld]) ([0-4])(?: ([01]{3,4}))?: (\S+)\z/
            or return $fail->($number, 'turn');
        return $fail->($number, 'number') unless $n == @{ $record{turns} } + 1;

        my $side = $SIDE_OF{$letter};
        return $fail->($number, 'side') unless $side eq $expect;

        if (defined $faces) {
            return $fail->($number, 'faces') unless length $faces == $set->{dice};
            my $marked = ($faces =~ tr/1//);
            return $fail->($number, 'faces')
                unless Game::RoyalUr::Dice::roll_of($marked, $set) == $roll;
        }
        if (defined $bytes) {
            my $thrown = Game::RoyalUr::Dice::throw_for($bytes, $throw, $set->{dice});
            return $fail->($number, 'roll')
                unless Game::RoyalUr::Dice::roll_of(Game::RoyalUr::Dice::marked($thrown), $set) == $roll;
            return $fail->($number, 'faces') if defined $faces && $faces ne join('', @$thrown);
        }
        $throw++;

        my %turn = (side => $side, roll => $roll + 0);
        $turn{faces} = $faces if defined $faces;
        my $other = $side eq 'light' ? 'dark' : 'light';
        if ($move eq '-') {
            $turn{move} = undef;
            $expect = $other;
        }
        else {
            my ($parsed, $error) = parse_move($move);
            return $fail->($number, 'move') unless $parsed;
            return $fail->($number, 'move') unless $move eq format_move($parsed);
            $turn{move} = $move;
            $expect = $ROSETTE{ $parsed->{to} } ? $side : $other;
        }
        push @{ $record{turns} }, \%turn;
    }
    return (\%record, undef);
}

1;

__END__

=head1 NAME

Game::RoyalUr::Notation - moves, positions and game records of the Royal Game of Ur, as text

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::RoyalUr::Notation qw(parse_move format_display parse_record format_record);

    my ($move, $error) = parse_move('hand-b1');      # { from => 'hand', to => 'b1' }

    print format_display($move_object), "\n";        # 3: a2-d2x*

    my ($record, $problem) = parse_record($text);
    die "line $problem->{line}: $problem->{error}\n" unless $record;
    print format_record($record);

=head1 DESCRIPTION

Functions that read and write a move, a turn and a whole game as text. There
is no object here and nothing is kept between calls.

This module needs no compiled code. It loads, and does everything below, on a
machine where the rest of the distribution could not be built.

=head2 A move, three ways

    hand-b1          the wire form
    3: a2-d2x*       the display form
    0: -             a turn lost to the roll

The B<wire> form names two places and nothing else. A place is a square, a
file letter C<a> to C<h> and a row digit C<1> to C<3>, or the word C<hand> for
a piece entering the board, or the word C<home> for a piece leaving it. It
carries no roll: a move cannot tell a game what was rolled.

The B<display> form leads with the roll, then the wire form, then C<x> if the
move captures and C<*> if it lands on a rosette, in that order.

A B<forfeit> is the roll and a dash.

Everything is written in lower case. The two words and the file letters are
read in either case, and nothing else is forgiven: no spaces, no other
separator, and no C<x> or C<*> on a wire move.

B<A wire move is not checked against a board.> C<b1-h3> is read without
complaint. Whether it is a move in some position is a question for a game.

=head2 A game record

    [rules finkel]
    [first light]
    [seed 5f1c9a]
    1. l 3: hand-b1
    2. d 0: -
    3. l 4 1111: b1-c2
    [result light resign]

A header and then one turn a line.

=over 4

=item C<[rules ...]>

C<finkel> or C<masters>, or the five fields of a rule set spelled out in
order: C<route=long dice=3 zero_rolls=4 safe_rosettes=1 pieces=7>.

=item C<[first ...]>

C<light> or C<dark>: the side that moves first.

=item C<[seed ...]>

Optional. The seed's bytes, in hexadecimal. B<With a seed, every roll in the
record is checked against the dice of that seed>, and a record that disagrees
is refused. Without one the rolls are taken as written, which is how a game
played with real dice is recorded.

=item C<[opening N]>

Optional, and only with a seed: how many throws were spent deciding who moves
first, so that the game's own throws are numbered from there.

=item a turn

Its number, counted from 1; the side, C<l> or C<d>; the roll; optionally the
dice as they fell, a C<1> for a marked die and a C<0> for an unmarked one; a
colon; and the move in wire form, or a dash for a turn lost.

The side is on every line because turns do not alternate, and it is checked
and not trusted: after a move onto a rosette the same side moves again, and
after anything else the other side does.

=item C<[result ...]>

Optional, and last. C<light home> or C<dark home> for a game won by bringing
the last piece home, C<light resign> or C<dark resign> naming the winner of a
game that was resigned, and C<draw ply_cap>.

=back

A record ends with a newline, and a record that has been read and written
again is the same text, byte for byte.

A record is checked for its own consistency: its numbering, its sides, its
dice. B<It is not played.> Whether each move was legal is a question for a
game, which is asked by replaying it.

=head1 FUNCTIONS

None is exported unless asked for. C<:all> exports everything.

=head2 square_ok

    square_ok('d2')     # true
    square_ok('e1')     # false: there is no such square

True for the name of one of the twenty squares, in lower case.

=head2 parse_move

    my ($move, $error) = parse_move($text);

A reference to C<< { from => ..., to => ... } >> in lower case and C<undef>,
or C<undef> and one of:

=over 4

=item C<empty>

No text.

=item C<shape>

Not two places with one dash between them.

=item C<place>

One of the two is not a square, C<hand> or C<home>.

=item C<from_home>

A piece that has come home does not move again.

=item C<to_hand>

Nothing moves to the hand.

=back

=head2 format_move

    my $wire = format_move($move);

The wire form of a move: a L<Game::RoyalUr::Move>, or a hash reference with
C<from> and C<to>.

=head2 format_display

    my $shown = format_display($move);
    my $shown = format_display($move, $roll);

The display form. The roll, and whether the move captures or lands on a
rosette, are read from the move; a roll given as the second argument is used
instead of the move's own.

=head2 format_forfeit

    my $shown = format_forfeit($roll);     # '0: -'

A turn lost to that roll, in the display form.

=head2 validate_position

    my $code = validate_position($string);

C<POS_OK> for a position string in the form
L<Game::RoyalUr::Engine/to_string> writes, or the reason it is not one. It
agrees with L<Game::RoyalUr::Engine/of_string> on every string, and needs no
board to say so.

=head2 parse_record

    my ($record, $problem) = parse_record($text);

A record and C<undef>, or C<undef> and a reference to
C<< { line => ..., error => ... } >> naming the first line that is wrong,
counted from 1, and why.

A record is a hash reference:

    {
        rules   => 'finkel',                # or a hash of the five fields
        first   => 'light',
        seed    => '5f1c9a',                # when the record has one
        opening => 2,                       # when the record has one
        turns   => [
            { side => 'light', roll => 3, move => 'hand-b1' },
            { side => 'dark',  roll => 0, move => undef },
            { side => 'light', roll => 4, faces => '1111', move => 'b1-c2' },
        ],
        result  => { winner => 'light', how => 'resign' },    # when it has one
    }

=head2 format_record

    my $text = format_record($record);

The text of a record in that shape.

=head1 CONSTANTS

=over 4

=item C<POS_OK>, C<POS_NULL>, C<POS_ROWS>, C<POS_WIDTH>, C<POS_LETTER>, C<POS_GAP>, C<POS_X>, C<POS_SIDE>, C<POS_COUNT>, C<POS_FIELD>, C<POS_LONG>

What C<validate_position> answers, with the meanings and the values
L<Game::RoyalUr::Engine> gives the same names.

=back

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
