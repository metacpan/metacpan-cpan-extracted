package Game::Floppy::Bot;

use 5.014;
use strict;
use warnings;

use Carp ();

our $VERSION = '0.09';

our @LADDER = (1, 2, 3);

our $NEAR = 120;

my %DESCRIBE = (
	1 => 'short-sighted: a tube counts only once it is near; until then it holds the middle',
	2 => 'far-sighted: it aims at the next gap from the moment the tube appears',
	3 => 'sits low: far-sighted, and it waits at the bottom of each gap, since rising is fast and falling slow',
);

sub levels { return @LADDER }

sub near { return $NEAR }

sub describe {
	my ($class, $level) = @_;
	return $DESCRIBE{ $class->_level($level) };
}

sub _level {
	my ($class, $level) = @_;
	$level = $LADDER[-1] unless defined $level;
	Carp::croak("Game::Floppy::Bot: a level is one of @LADDER, not '$level'")
		unless !ref $level && $DESCRIBE{$level};
	return $level;
}

sub target {
	my ($class, $game, $level) = @_;
	$level = $class->_level($level);

	my $middle = $game->height / 2;
	my $tube = $game->tubes->[0];
	return $middle unless $tube;
	return $middle if $level == 1 && $tube->{x} - $game->bird_x > $NEAR;
	my $target = $level == 3
		? $tube->{gap_bottom} - $game->bird_radius - 9
		: ($tube->{gap_top} + $tube->{gap_bottom}) / 2;
	my $floor = $game->height - $game->gravity - 1;
	return $target > $floor ? $floor : $target;
}

sub choose {
	my ($class, $game, %with) = @_;
	my $level = $class->_level($with{level});

	return undef if $game->status eq 'finished';

	return $game->bird->{y} > $class->target($game, $level) ? 1 : 0;
}

1;

__END__

=head1 NAME

Game::Floppy::Bot - a bird flown once a tick, at one of three levels

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    use Game::Floppy;
    use Game::Floppy::Bot;

    my $game = Game::Floppy->new(seed => $seed);

    while ($game->status ne 'finished') {
        $game->flap if Game::Floppy::Bot->choose($game, level => 3);
        $game->tick;
    }

=head1 DESCRIPTION

Asked once a tick, this says whether to flap: it flaps when the bird is below
a target and not otherwise. The three levels differ in what the target is.
Every target is at least 71 pixels down, a gap's centre at its highest, so
no level can flap into the sky.

In a gap nothing dies: a flap band of 27 pixels fits a 140 pixel gap with
room to spare. What kills is the drop between one gap and the next, 75 ticks
and 225 pixels of fall against gaps whose centres lie anywhere in 300. A bird
that starts down too late cannot get there.

=over 4

=item 1 short-sighted

A tube counts only once its left edge is within C<near> (120) pixels of the
bird; until then the target is the middle of the field.

=item 2 far-sighted

The target is the next gap's centre from the moment the tube appears.

=item 3 sits low

Far-sighted, but the target is the bottom of the gap, a radius and a flap's
margin above the lower pipe: falling is slow and rising fast, so a bird
waiting low loses nothing on a drop.

=back

Nothing here calls C<rand> and nothing is hashed: there are no ties to break.
The bot is a set of class methods and keeps nothing between ticks.

=head1 METHODS

=head2 choose

    my $flap = Game::Floppy::Bot->choose($game, level => 2);

1 to flap, 0 not to. The level is 1, 2 or 3 and defaults to 3. Undefined once
the game has finished. A level off the ladder is a programmer error and dies.

=head2 target

    my $y = Game::Floppy::Bot->target($game, 2);

The y the level is aiming the bird at this tick.

=head2 levels, describe, near

The ladder, C<(1, 2, 3)>; one line on what a level does; the distance at
which level 1 starts to count a tube.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
