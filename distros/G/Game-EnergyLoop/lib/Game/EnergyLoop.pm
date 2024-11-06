# -*- Perl -*-
#
# Game::EnergyLoop - a simple energy system

package Game::EnergyLoop;
our $VERSION = '0.01';
use strict;
use warnings;

sub update {
    my ($enlos, $initiative, $arg) = @_;
    my $min = ~0;
    for my $ent (@$enlos) {
        my $energy = $ent->enlo_energy;
        $min = $energy if $energy < $min;
    }
    die "negative minimum energy $min" if $min < 0;
    my @active;
    for my $ent (@$enlos) {
        my $energy = $ent->enlo_energy;
        $energy -= $min;
        push @active, $ent if $energy == 0;
        $ent->enlo_energy($energy);
    }
    $initiative->( \@active ) if defined $initiative and @active > 1;
    my @newbies;
    for my $ent (@active) {
        my ( $new_energy, $noobs ) = $ent->enlo_update( $min, $arg );
        die "negative entity new_energy $new_energy" if $new_energy < 0;
        $ent->enlo_energy($new_energy);
        push @newbies, @$noobs if defined $noobs;
    }
    push @$enlos, @newbies;
    return $min;
}

# TODO may need a return flag to indicate whether game is blocked? but
# if that's important the caller could set a flag in their world object
# and check for that...

1;
__END__
=head1 NAME

Game::EnergyLoop - a simple energy system

=head1 SYNOPSIS

  use Game::EnergyLoop;
  use Object::Pad;
  class Foo {
      field $name :param;
      field $energy :param;
      field $priority :param :reader;
      field $cur_energy = 0;
      method enlo_energy ( $new = undef ) {
          $cur_energy = $new if defined $new;
          return $cur_energy;
      }
      method enlo_update( $value, $epoch ) {
          print "$epoch RUN $name ($priority) $value\n";
          return $energy;
      }
  }
  sub pri { @{$_[0]} = sort {$b->priority <=> $a->priority} @{$_[0]} }
  my @obj = map {
      Foo->new(
          name     => "N$_",
          energy   => ( 1 + int rand 8 ),
          priority => int rand 2,
      )
  } 1 .. 3;
  my $epoch = 0;
  for ( 1 .. 10 ) {
      $epoch += Game::EnergyLoop::update( \@obj, \&pri, $epoch );
  }

See also the C<eg> directory of this module's distribution for
example scripts.

=head1 DESCRIPTION

This module provides an B<update> function that determines which agents
in a list should move, when, with an optional initiative callback for
when multiple agents run at the same time. An update function is called
for each agent that moves; this function must return a new energy cost
and optionally a list of new agents to append to the list of entities.

The energy cost is assumed to be a integer value; the minimum value is
subtracted from each agent each B<update> call and those entities that
have zero energy have their update function called. This means an agent
update function that returns zero will not advance the energy loop; this
can be used to provide "free moves" to an agent, or to prevent the other
agents from running until, say, some necessary input from a player
becomes available. How this energy loop interacts with, say, a user
interface loop may require some thought.

The caller is responsible for pruning dead agents out of the list after
B<update> is called, if relevant. Agents that move at the same time may,
in some cases, have to account for being killed before they have a
chance to move, or these agents may instead be considered to have moved
at the same time, and code that runs after the B<update> call may need
to resolve things, such as agents now being dead. These and other
details will depend on the particulars of the game or environment being
simulated.

=head1 FUNCTION

The function is not exported by default.

=over 4

=item B<update> I<animates> I<initiative-callback> I<arg>

I<animates> must be an array reference; the objects within must support
B<enlo_energy> and B<enlo_update> methods. B<enlo_energy> is a
getter/setter that contains the integer energy value of the entity, and
B<enlo_update> is a function called with the entity object and the
optional I<arg> passed in by the caller.

I<initiative-callback> is called if provided when two or more entities
move at the exact same time; an array reference of entity objects is
passed, and the function will need to reorder the entities, if
necessary, to run in some particular order, for example to roll
initiative and sort the array reference in place. If there is such an
initiative system, then entities may need to account for being killed
before it is their turn to move, e.g. Adam and Bob move at the same
time; Bob wins the initiative, kills Adam, so then Adam's update
function will need account for being already dead. The default order is
the order of the entities in the list. A common practice is to put the
player and any other special objects (e.g. a virtual entity that spawns
monsters) at the start of the list so that they move first.

The minimum cost for this update and I<arg> are passed along with the
entity object to the B<enlo_update> call. I<arg> could be a stash, or a
world object.

The B<enlo_update> function must return a new energy value for when the
entity moves next, and an optional array reference of new entities
created during the update call, such as when a player summons new
entities by casting a spell. New entities must not be directly added to
the entity list, as there is no "this entity is new" flag to distinguish
those new entities from the current ones being updated. That is, any new
entities do not run until the B<update> function finishes updating all
agents that move on the current "turn". If you do need agents that
update the instant they are created, you will have to figure out some
way to make that happen. The usual lore is to claim that the new summons
have summoning sickness, so cannot move right away.

B<update> returns the minimum energy cost value, or how much the energy
system advanced by, e.g. B<0> if something got a "free move" or maybe
C<100> if an agent moved left. This return value can almost be used as a
sort of an epoch counter, though beginnings can be difficult times.

=back

=head1 ENERGY VALUES

Energy values should be integers to avoid problematic small but not
quite zero floating point values, possible portability problems, etc.
Nothing in this module wastes time enforcing integerness, however.
Negative values cause errors to be thrown, so do not return those.

C<100> is typical for a default move cost, though one may want a larger
value if entities can move much faster than the default: C<50>, C<25>,
whoops C<12.5> isn't an integer value. If diagonal moves cost more (they
do not in many roguelikes) then consider using C<99> and C<70>, or
factors thereof, as 99 divided by 70 is a pretty good approximation of
the square root of two.

=head1 BUGS

These probably should be called errors, not bugs.

=head1 SEE ALSO

L<https://thrig.me/src/ministry-of-silly-vaults.git> contains various
energy system implementations in various languages, but none that are
complicated by also having to work with a user interface loop.

L<https://thrig.me/src/sbal.git> contains a similar but more complicated
energy system (in C<animate.c> and C<animate.h>) that does account for
objects being "new" or "dead" or "newly dead", and a perhaps too
complicated method to determine whether or not the game is blocked
waiting for player input, as a user interface loop does also exist.
B<sbal> is a 7DRL so was written in hurry, and as such may not have the
simplest of code. Consider this module a cleaned up and simplified
version of the B<sbal> animate system.

=head1 AUTHOR

Jeremy Mates

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Jeremy Mates

This program is distributed under the (Revised) BSD License.

=cut
