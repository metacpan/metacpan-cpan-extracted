package Game::Backgammon::Board;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

use constant POINTS => 24;
use constant CHECKERS => 15;
use constant BAR_PIP => 25;

sub opening {
    my @p = (0) x POINTS;
    $p[23] =  2;  $p[12] =  5;  $p[7]  =  3;  $p[5]  =  5;
    $p[0]  = -2;  $p[11] = -5;  $p[16] = -3;  $p[18] = -5;
    return \@p;
}

has points => (
	is => 'ro',
	isa => ArrayRef,
	default => sub { opening() }
);

has bar_counts => (
	is => 'ro',
	isa => HashRef,
	default => sub { { white => 0, black => 0 } }
);

has off_counts => (
	is => 'ro',
	isa => HashRef,
	default => sub { { white => 0, black => 0 } }
);

sub clone {
	my ($self) = @_;
	return ref($self)->new(
		points     => [ @{ $self->points } ],
		bar_counts => { %{ $self->bar_counts } },
		off_counts => { %{ $self->off_counts } }
	);
}

sub other { return $_[0] eq 'white' ? 'black' : 'white' }

sub index_for {
    my ($self, $player, $n) = @_;
    die "Game::Backgammon::Board: point $n is not 1 to 24"
        unless defined $n && $n =~ /\A\d+\z/ && $n >= 1 && $n <= POINTS;
    return $player eq 'white' ? $n - 1 : POINTS - $n;
}

sub point_for {
    my ($self, $player, $n) = @_;
    my $v = $self->points->[ $self->index_for($player, $n) ];
    my $mine = $player eq 'white' ? $v : -$v;
    return $mine >= 0 ? ($mine, 0) : (0, -$mine);
}

sub mine_on   { my ($self, $p, $n) = @_; my ($m) = $self->point_for($p, $n); return $m }
sub theirs_on { my ($self, $p, $n) = @_; my (undef, $t) = $self->point_for($p, $n); return $t }

sub is_blot { my ($self, $player, $n) = @_; return $self->theirs_on($player, $n) == 1 ? 1 : 0 }

sub is_blocked { my ($self, $player, $n) = @_; return $self->theirs_on($player, $n) >= 2 ? 1 : 0 }

sub bar { my ($self, $player) = @_; return $self->bar_counts->{$player} }
sub off { my ($self, $player) = @_; return $self->off_counts->{$player} }

sub set_point {
	my ($self, $player, $n, $count) = @_;
	my $i = $self->index_for($player, $n);
	$self->points->[$i] = $player eq 'white' ? $count : -$count;
	return $self;
}

sub add {
	my ($self, $player, $n, $d) = @_;
	my $i = $self->index_for($player, $n);
	$self->points->[$i] += $player eq 'white' ? $d : -$d;
	return $self;
}

sub to_bar { my ($self, $player, $d) = @_; $self->bar_counts->{$player} += $d // 1; return $self }
sub to_off { my ($self, $player, $d) = @_; $self->off_counts->{$player} += $d // 1; return $self }

sub occupied {
    my ($self, $player) = @_;
    my @out;
    for my $n (reverse 1 .. POINTS) {
        my $m = $self->mine_on($player, $n);
        push @out, [ $n, $m ] if $m;
    }
    return \@out;
}

sub checkers_on_points {
    my ($self, $player) = @_;
    my $n = 0;
    $n += $_->[1] for @{ $self->occupied($player) };
    return $n;
}

sub pip_count {
    my ($self, $player) = @_;
    my $pips = $self->bar($player) * BAR_PIP;
    $pips += $_->[0] * $_->[1] for @{ $self->occupied($player) };
    return $pips;
}

sub all_home {
    my ($self, $player) = @_;
    return 0 if $self->bar($player);
    for my $n (7 .. POINTS) {
        return 0 if $self->mine_on($player, $n);
    }
    return 1;
}

sub highest_occupied {
    my ($self, $player) = @_;
    for my $n (reverse 1 .. POINTS) {
        return $n if $self->mine_on($player, $n);
    }
    return 0;
}

sub consistent {
    my ($self) = @_;
    my @wrong;
    for my $player (qw(white black)) {
        my $n = $self->checkers_on_points($player) + $self->bar($player) + $self->off($player);
        push @wrong, "$player has $n checkers, not " . CHECKERS unless $n == CHECKERS;
        push @wrong, "$player has a negative bar" if $self->bar($player) < 0;
        push @wrong, "$player has a negative tray" if $self->off($player) < 0;
    }
    return @wrong;
}

1;

__END__

=head1 NAME

Game::Backgammon::Board - the position, and the only thing that knows which way round it is

=head1 SYNOPSIS

    my $b = Game::Backgammon::Board->new;          # the opening position
    $b->mine_on('white', 6);                       # 5
    $b->is_blocked('white', 1);                    # 1: black has two there
    $b->pip_count('white');                        # 167
    $b->all_home('black');                         # 0

=head1 DESCRIPTION

Twenty-four points as one signed array: C<+n> is C<n> white checkers, C<-n>
is C<n> black. A point holds one colour or nothing, which the sign says
exactly, and which makes a point holding both colours unrepresentable rather
than merely untested.

=head2 Numbering, and why only this class knows it

Points are numbered 1 to 24 from each player's own side, so your 1 point is
your opponent's 24. The array is stored from white's, and C<index_for>
converts. Nothing outside this class indexes the array: the direction is
where the bugs in a backgammon engine live, so exactly one piece of code
knows about it and a test greps the tree to keep it that way.

=head2 Methods

C<point_for($player, $n)> returns C<($mine, $theirs)>, both positive, so a
rule reads the way it is spoken. C<mine_on>, C<theirs_on>, C<is_blot> and
C<is_blocked> are the shorthands the rules actually use.

C<pip_count> counts a checker on the bar as 25. C<all_home> is false while
anything is on the bar, which is what stops a player bearing off after being
hit.

C<consistent> returns a list of complaints, empty when the position is sound.

=head1 METHODS

=head2 opening

The starting position, as the signed array.

=head2 clone

An independent copy. The rules walk a tree of positions, so nothing shares.

=head2 other

The other player's name.

=head2 index_for($player, $n)

That player's point C<$n> as an index. The only place direction is known.

=head2 point_for($player, $n)

C<($mine, $theirs)>, both positive.

=head2 mine_on($player, $n), theirs_on($player, $n)

One half of C<point_for> each.

=head2 is_blot($player, $n)

Exactly one of theirs: the thing you can hit.

=head2 is_blocked($player, $n)

Two or more of theirs: you may not land there.

=head2 bar($player), off($player)

That side's count on the bar and in the tray.

=head2 bar_counts, off_counts, points

The raw attributes. Prefer the readers above.

=head2 set_point($player, $n, $count), add($player, $n, $delta)

=head2 to_bar($player, $delta), to_off($player, $delta)

=head2 occupied($player)

C<[ [ point, count ], ... ]>, highest point first.

=head2 checkers_on_points($player)

=head2 pip_count($player)

The sum of distances home; a checker on the bar counts 25.

=head2 all_home($player)

True when every checker is in the home board, which bearing off needs.
False while anything is on the bar.

=head2 highest_occupied($player)

The highest point still occupied, or 0.

=head2 consistent

A list of complaints, empty when the position is sound.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
