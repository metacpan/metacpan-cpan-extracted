package Game::Senet::Notation;

use 5.010;
use strict;
use warnings;

use Exporter 'import';
use Scalar::Util ();

use Game::Senet::Sticks ();

our $VERSION = '0.01';

use constant {
    POS_OK     => 0,
    POS_NULL   => 1,
    POS_GROUPS => 2,
    POS_WIDTH  => 3,
    POS_LETTER => 4,
    POS_SIDE   => 5,
    POS_PIECES => 6,
    POS_EXCESS => 7,
    POS_FIELD  => 8,
    POS_LONG   => 9,
};

our (@EXPORT_OK, %EXPORT_TAGS);
my (@FIELDS, %FIELD_OK, %SIDE_OF, %LETTER_OF, %RESULT_OK, $MOVE_MAX);
BEGIN {
    @EXPORT_OK = qw(
        house_ok parse_move format_move format_display format_forfeit
        validate_position parse_record format_record
        POS_OK POS_NULL POS_GROUPS POS_WIDTH POS_LETTER POS_SIDE
        POS_PIECES POS_EXCESS POS_FIELD POS_LONG
    );
    %EXPORT_TAGS = (all => \@EXPORT_OK);

    @FIELDS = qw(pieces blockade protect backward reach26 throw_on_26);
    %FIELD_OK = (
        pieces      => qr/\A[1-7]\z/,
        blockade    => qr/\A[023]\z/,
        protect     => qr/\A(?:none|run|ends)\z/,
        backward    => qr/\A[01]\z/,
        reach26     => qr/\A(?:exact|any)\z/,
        throw_on_26 => qr/\A[01]\z/,
    );
    %SIDE_OF   = (l => 'light', d => 'dark');
    %LETTER_OF = (light => 'l', dark => 'd');
    %RESULT_OK = map { $_ => 1 }
        'light home', 'dark home', 'light resign', 'dark resign', 'draw ply_cap';
    $MOVE_MAX = length '30-off';
}

sub house_ok {
    my ($text) = @_;
    return 0 unless defined $text && $text =~ /\A[1-9][0-9]?\z/;
    return $text <= 30 ? 1 : 0;
}

my $place = sub {
    my ($text) = @_;
    return ('off', undef) if lc $text eq 'off';
    return (undef, 'shape') unless $text =~ /\A[0-9]+\z/;
    return (undef, 'house') unless house_ok($text);
    return ($text + 0, undef);
};

sub parse_move {
    my ($text) = @_;
    return (undef, 'empty') unless defined $text && length $text;
    return (undef, 'long') if length $text > $MOVE_MAX;
    my @parts = split /-/, $text, -1;
    return (undef, 'shape') unless @parts == 2 && length $parts[0] && length $parts[1];
    my ($from, $bad_from) = $place->($parts[0]);
    return (undef, $bad_from) if $bad_from;
    my ($to, $bad_to) = $place->($parts[1]);
    return (undef, $bad_to) if $bad_to;
    return (undef, 'from_off') if $from eq 'off';
    return (undef, 'same') if $from eq $to;
    return ({ from => $from, to => $to }, undef);
}

my $read = sub {
    my ($move, $name) = @_;
    return $move->$name if Scalar::Util::blessed($move) && $move->can($name);
    return ref $move eq 'HASH' ? $move->{$name} : undef;
};

sub format_move {
    my ($move) = @_;
    my $to = $read->($move, 'off') ? 'off' : $read->($move, 'to');
    return $read->($move, 'from') . '-' . lc $to;
}

sub format_display {
    my ($move, $again) = @_;
    return $read->($move, 'roll') . ': ' . format_move($move)
        . ($read->($move, 'back') ? '<' : '')
        . ($read->($move, 'swap') ? 'x' : '')
        . ($again ? '+' : '');
}

sub format_forfeit {
    my ($roll, $again) = @_;
    return $roll . ': -' . ($again ? '+' : '');
}

sub validate_position {
    my ($text) = @_;
    return POS_NULL unless defined $text && length $text;
    return POS_LONG if length $text >= 48;

    my @c = split //, $text;
    my ($group, $width, $i) = (0, 0, 0);
    my %count = (l => 0, d => 0);
    for (; $i < @c && $c[$i] ne ' '; $i++) {
        my $ch = $c[$i];
        if ($ch eq '/') {
            return POS_WIDTH  if $width != 10;
            return POS_GROUPS if $group == 2;
            $group++;
            $width = 0;
            next;
        }
        return POS_LETTER unless $ch eq 'l' || $ch eq 'd' || $ch eq '.';
        return POS_WIDTH if $width >= 10;
        $count{$ch}++ if $ch ne '.';
        $width++;
    }
    return POS_GROUPS if $group != 2;
    return POS_WIDTH  if $width != 10;

    return POS_FIELD unless $i < @c && $c[$i] eq ' ';
    $i++;
    return POS_FIELD if $i >= @c;
    return POS_SIDE unless $c[$i] eq 'l' || $c[$i] eq 'd';
    $i++;
    return POS_FIELD if $i >= @c;
    return POS_SIDE unless $c[$i] eq ' ';
    $i++;
    return POS_FIELD if $i >= @c;
    return POS_PIECES unless $c[$i] =~ /\A[1-7]\z/;
    my $pieces = $c[$i];
    $i++;
    return POS_PIECES if $i < @c && $c[$i] ne ' ';
    return POS_FIELD if $i < @c;
    return POS_EXCESS if $count{l} > $pieces || $count{d} > $pieces;
    return POS_OK;
}

my $variant_text = sub {
    my ($variant) = @_;
    return join ' ', $variant->{name}, map { "$_=$variant->{$_}" } @FIELDS;
};

my $variant_of = sub {
    my ($text) = @_;
    my ($name, @pairs) = split / /, $text, -1;
    return undef unless defined $name && $name =~ /\A[a-z][a-z0-9_]*\z/;
    my (%variant, @names) = (name => $name);
    for my $pair (@pairs) {
        my ($field, $value) = $pair =~ /\A([a-z_0-9]+)=([a-z0-9]+)\z/ or return undef;
        push @names, $field;
        return undef unless $FIELD_OK{$field} && $value =~ $FIELD_OK{$field};
        $variant{$field} = $value =~ /\A\d+\z/ ? $value + 0 : $value;
    }
    return undef unless "@names" eq "@FIELDS";
    return \%variant;
};

sub format_record {
    my ($record) = @_;
    my @lines = (
        '[variant ' . $variant_text->($record->{variant}) . ']',
        '[first ' . $record->{first} . ']',
    );
    push @lines, '[position ' . $record->{position} . ']' if defined $record->{position};
    push @lines, '[seed ' . $record->{seed} . ']' if defined $record->{seed};
    my $n = 0;
    for my $ply (@{ $record->{plies} || [] }) {
        $n++;
        push @lines, $n . '. ' . $LETTER_OF{ $ply->{side} } . ' ' . $ply->{roll}
            . (defined $ply->{sticks} ? ' ' . $ply->{sticks} : '')
            . ': ' . (defined $ply->{move} ? $ply->{move} : '-');
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
    my %record = (plies => []);
    my ($at, $done) = (0, 0);

    my $header = sub {
        my ($name, $pattern) = @_;
        return undef unless $at < @lines && $lines[$at] =~ /\A\[\Q$name\E ($pattern)\]\z/;
        $at++;
        return $1;
    };

    my $variant = $header->('variant', '[a-z0-9_= ]+');
    return $fail->($at + 1, 'variant') unless defined $variant;
    $record{variant} = $variant_of->($variant);
    return $fail->($at, 'variant') unless $record{variant};

    $record{first} = $header->('first', 'light|dark');
    return $fail->($at + 1, 'first') unless defined $record{first};

    my $position = $header->('position', '[ld./ 1-7]+');
    if (defined $position) {
        return $fail->($at, 'position') if validate_position($position);
        my ($side, $pieces) = $position =~ / ([ld]) (\d)\z/;
        return $fail->($at, 'position')
            unless $pieces == $record{variant}{pieces} && $side eq substr($record{first}, 0, 1);
        $record{position} = $position;
    }

    my $seed = $header->('seed', '(?:[0-9a-f]{2})+');
    $record{seed} = $seed if defined $seed;
    my $bytes = defined $seed ? pack('H*', $seed) : undef;

    my $expect = $record{first};
    my $bind = $record{variant}{throw_on_26};
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

        my ($n, $letter, $roll, $sticks, $move) =
            $line =~ /\A([1-9][0-9]*)\. ([ld]) ([1-5])(?: ([01]{4}))?: (\S+)\z/
            or return $fail->($number, 'ply');
        my $throw = scalar @{ $record{plies} };
        return $fail->($number, 'number') unless $n == $throw + 1;

        my $side = $SIDE_OF{$letter};
        return $fail->($number, 'side') unless $side eq $expect;

        if (defined $sticks) {
            my $light = ($sticks =~ tr/1//);
            return $fail->($number, 'sticks') unless Game::Senet::Sticks::roll_of($light) == $roll;
        }
        if (defined $bytes) {
            my $thrown = Game::Senet::Sticks::throw_for($bytes, $throw);
            return $fail->($number, 'roll')
                unless Game::Senet::Sticks::roll_of(Game::Senet::Sticks::light_of($thrown)) == $roll;
            return $fail->($number, 'sticks') if defined $sticks && $sticks ne join('', @$thrown);
        }

        my %ply = (side => $side, roll => $roll + 0);
        $ply{sticks} = $sticks if defined $sticks;
        my $other = $side eq 'light' ? 'dark' : 'light';
        my $again = Game::Senet::Sticks::extra_throw($roll);
        if ($move eq '-') {
            $ply{move} = undef;
        }
        else {
            my ($parsed) = parse_move($move);
            return $fail->($number, 'move') unless $parsed && $move eq format_move($parsed);
            $ply{move} = $move;
            $again ||= $bind && $parsed->{to} ne 'off' && $parsed->{from} < 26 && $parsed->{to} == 26;
        }
        $expect = $again ? $side : $other;
        push @{ $record{plies} }, \%ply;
    }
    return (\%record, undef);
}

1;

__END__

=head1 NAME

Game::Senet::Notation - a Senet move, a position and a game record, as text

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Senet::Notation ':all';

    my ($move, $why) = parse_move('12-15');    # { from => 12, to => 15 }
    print format_move($move), "\n";             # 12-15

    print format_display({ from => 22, to => 20, roll => 2, back => 1, swap => 1 }), "\n";
                                                # 2: 22-20<x
    print format_forfeit(4, 1), "\n";           # 4: -+

    my ($record, $problem) = parse_record($text);
    print format_record($record);

=head1 DESCRIPTION

Functions, no objects and no compiled code, for reading and writing a game of
Senet as text: a move, a position string, and a whole game's record. Nothing
here has a board. A move is read and written without being asked whether it is
legal; that is the game's question.

=head1 A MOVE

The B<wire> form names two places: a house, a whole number from 1 to 30 with no
leading zero, and the word C<off>. C<12-15>, C<22-20>, C<26-off>, C<26-15>. It
carries no roll and no marks.

The B<display> form leads with the roll, then the move, then its marks in a
fixed order: C<< < >> a backward move, C<x> a swap, C<+> the same side throws
next. C<< 2: 22-20<x >> is a backward swap on a 2. A forfeit is the roll and a
dash: C<3: ->, or C<4: -+> when it keeps the turn.

C<< < >> cannot be worked out from the two houses. From 25 or below a lower
house is a backward move; from 26 or 27 it is the walk down from 15, which is
forward. The mark says which.

=head1 A RECORD

    [variant kendall pieces=5 blockade=3 protect=run backward=1 reach26=exact throw_on_26=0]
    [first light]
    1. l 1: 10-11
    2. l 2: 11-13
    3. d 3: 9-12
    4. l 5 0000: 6-11
    5. l 3: 2-5
    6. d 2: 7-9

A header, then one line a ply. The C<variant> line is the rule set's name and
every one of its fields in this order: C<pieces>, C<blockade>, C<protect>,
C<backward>, C<reach26>, C<throw_on_26>. C<first> says which side threw first.
C<position>, optional, is the position string the game began from, its side the
side of C<first>, when it did not begin at the start. C<seed>, in hexadecimal, is optional; with one, every roll is checked: line
I<k> is throw I<k> - 1 of the seed, since there is no opening throw.

A ply line is its number, the side, the roll, optionally the four sticks as
they fell (C<1> a light face), and the wire move or C<->. The side is on every
line because turns do not alternate: the next line is the same side after a
roll of 1, 4 or 5, and after a move from below house 26 onto it when the
variant's C<throw_on_26> is 1. A record may end C<[result light home]>, C<[result
dark resign]> or C<[result draw ply_cap]>, and ends with a newline.

=head1 FUNCTIONS

None is exported unless asked for. C<:all> exports them all, and the C<POS_>
constants, which are L<Game::Senet::Engine>'s.

=head2 house_ok

    house_ok('15');    # 1

True for a house number as the wire form writes one: 1 to 30, no leading zero.

=head2 parse_move

    my ($move, $why) = parse_move($text);

The move a wire form names, as C<< { from, to } >> with C<to> a number or
C<off>, and C<undef>; or C<undef> and why not: C<empty>, C<long>, C<shape>,
C<house>, C<from_off> or C<same>. C<off> is read in any case; nothing else is
forgiven.

=head2 format_move

    my $text = format_move($move);

The wire form of a move: a L<Game::Senet::Move> or a hash with C<from> and
C<to>.

=head2 format_display

    my $text = format_display($move, $again);

The display form. C<$again> is whether the same side throws next, which only
the game can say, and puts the C<+> on.

=head2 format_forfeit

    my $text = format_forfeit($roll, $again);

A throw that allowed nothing, in the display form.

=head2 validate_position

    my $code = validate_position($text);

C<POS_OK>, or the code L<Game::Senet::Engine> would refuse the string with,
worked out without building a board.

=head2 parse_record

    my ($record, $problem) = parse_record($text);

A record as a hash: C<variant> (the name and the fields), C<first>, C<seed>
when given, C<plies> (each with C<side>, C<roll>, C<sticks> when given, and
C<move>, C<undef> for a forfeit) and C<result> when given. Or C<undef> and
C<< { line, error } >>. It checks the record's own consistency: the numbering,
the sides, the sticks against the roll, and the rolls against the seed. It does
not play the game, so it cannot say whether a move was legal.

=head2 format_record

    my $text = format_record($record);

A record as text, the inverse of C<parse_record>, byte for byte.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
