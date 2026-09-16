package Game::Backgammon::Notation;

use strict;
use warnings;

use Game::Backgammon::Move;
use Game::Backgammon::Turn;
use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(parse_turn print_turn);

sub _place {
    my ($text) = @_;
    return 'bar' if lc $text eq 'bar';
    return 'off' if lc $text eq 'off';
    return undef unless $text =~ /\A\d+\z/ && $text >= 1 && $text <= 24;
    return $text + 0;
}

sub parse_turn {
    my ($line, %o) = @_;
    $line = '' unless defined $line;
    $line =~ s/\A\s+|\s+\z//g;

    my @moves;
    return Game::Backgammon::Turn->new(player => $o{player}, dice => $o{dice} || [],
                                       moves => [])
        if $line eq '' || lc $line eq '(no play)';

    for my $group (split /\s+/, $line) {
        my $times = 1;
        if ($group =~ s/\(([^)]*)\)\z//) {
            $times = $1;
            return _bad("'$group($times)' repeats a move $times times, which is not 1 to 4")
                unless $times =~ /\A[1-4]\z/;
            $times += 0;
        }

        my @hops = split m{/}, $group, -1;
        return _bad("'$group' is not a move") if @hops < 2;

        my @pair;
        for my $i (0 .. $#hops - 1) {
            my ($from_text, $to_text) = ($hops[$i], $hops[$i + 1]);
            my $hit = ($to_text =~ s/\*\z//) ? 1 : 0;
            $from_text =~ s/\*\z//;
            my $from = _place($from_text);
            my $to   = _place($to_text);
            return _bad("'$group' names a place that is not a point, the bar or off")
                unless defined $from && defined $to;
            return _bad("'$group' moves from off the board") if $from eq 'off';
            return _bad("'$group' moves onto the bar")       if $to   eq 'bar';
            my $die = ($from ne 'bar' && $to ne 'off') ? $from - $to : undef;
            return _bad("'$group' moves backwards") if defined $die && $die <= 0;
            push @pair, Game::Backgammon::Move->new(
                player => $o{player}, from => $from, to => $to, die => $die, hit => $hit);
        }
        push @moves, (@pair) x $times;
    }
    return Game::Backgammon::Turn->new(player => $o{player},
                                       dice => $o{dice} || [], moves => \@moves);
}

sub _bad { $@ = "Game::Backgammon::Notation: $_[0]\n"; return undef }

sub print_turn { my ($turn) = @_; return $turn->notation }

1;

__END__

=head1 NAME

Game::Backgammon::Notation - standard notation, parsed and printed

=head1 SYNOPSIS

    use Game::Backgammon::Notation qw(parse_turn print_turn);

    my $turn = parse_turn('8/5 6/5', player => 'white') or die $@;
    print_turn($turn);                 # '8/5 6/5'
    parse_turn('bar/20 13/11*', player => 'black');
    parse_turn('13/7/5', player => 'white');    # one checker, two hops

=head1 DESCRIPTION

Both directions of the notation a backgammon player writes. C<8/5(2)> is
two checkers making the same move; C<13/7/5> is one checker making two,
and expands to C<13/7 7/5>.

=head2 It does not know the rules

The parser produces the moves the line says and nothing more: not whether
they are legal, not which dice they needed, not whether the hits are real.
That belongs to the rules, and a parser that half-knew them would be a
second place for them to be wrong. The C<die> on a parsed move is undef
where the position decides it, which is entering from the bar and bearing
off.

A line that is not notation returns undef with the reason in C<$@>. It came
from a player; refusing it is an ordinary answer, not an exception.

=head1 FUNCTIONS

=head2 parse_turn($line, player => $who, dice => \@dice)

A L<Game::Backgammon::Turn>, or undef with the reason in C<$@>.

=head2 print_turn($turn)

The turn as a line of notation.

=cut
