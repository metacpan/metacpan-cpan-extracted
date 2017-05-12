use 5.16.0;
use warnings;
package Games::Nintendo::Mario::SMB2 0.208;

use base qw(Games::Nintendo::Mario::Hearts);

sub _names  { qw[Mario Luigi Peach Toad] }
sub _states { qw[normal] } # super isn't listed to prevent creation-as-super
sub _items  { qw[mushroom heart] }

sub _goto_hash {  {} }

sub _char_attr {
  {
  Mario => {
    power => 4,
    speed => 4,
    jump  => 4
  },
  Luigi => {
    power => 3,
    speed => 3,
    jump  => 5
  },
  Peach => {
    power => 2,
    speed => 2,
    jump  => 3
  },
  Toad => {
    power => 5,
    speed => 5,
    jump  => 2
  } }
}

sub state { ## no critic Homonym
  my $hero = shift;
  if ($hero->hearts < 1) { return "dead" }
  if ($hero->hearts > 1) { return "super" }
  else { return "normal" }
}

sub name { $_[0]->{name} }

sub powerup {
  my $hero = shift;
  my $item = shift;

  if (($item eq 'mushroom') and ($hero->max_hearts < 5)) {
    $hero->{max_hearts}++;
  }
  $hero->SUPER::powerup($item);
}

sub power { $_[0]->_char_attr->{$_[0]->name}->{power} }
sub speed { $_[0]->_char_attr->{$_[0]->name}->{speed} }
sub jump  { $_[0]->_char_attr->{$_[0]->name}->{jump} }

sub games {
  return ('Super Mario Bros. 2');
}

"It's-a me!  Mario!";

__END__

=head1 NAME

Games::Nintendo::Mario::SMB2 - a class for vegetable-throwing Italian plumbers (and friends)

=head1 VERSION

version 0.208

=head1 SYNOPSIS

  use Games::Nintendo::Mario::SMB2;

  my $liege = Games::Nintendo::Mario::SMB2->new(name => 'Peach');

  # below outputs "Peach: 1/3"
  print
    $liege->name . ": " . $liege->hearts . "/" . $liege->max_hearts . "\n";

  $liege->powerup('heart');    # 2/3
  $liege->damage;              # 1/3
  $liege->powerup('mushroom'); # 1/4
  $liege->powerup('heart');    # 2/4
  $liege->powerup('mushroom'); # 2/5
  $liege->powerup('heart');    # 3/5

  print "I'm feeling ", $liege->state, "!\n"; # She's feeling super.

  $liege->powerup('mushroom'); # Nothing happens.

  $liege->damage for (1 .. 3); # cue the Mario Death Music

=head1 DESCRIPTION

This class subclasses Games::Nintendo::Mario (and G::N::M::Hearts), providing a
model of the behavior of the Mario Brothers in Super Mario Brothers 2.  All of
the methods described in the Mario interface exist as documented.

=head2 NAMES

The plumber may be named Mario or Luigi, or a non-plumbing character named
Peach or Toad may be created.

=head2 STATES

C<< $hero->state >> will return 'dead' if he has no hearts, 'normal' if he has
one heart, and 'super' if he has more than one heart.  State may not be set
during construction; set hearts instead.

=head2 POWERUPS

Valid powerups are: C<mushroom> or C<heart>

=head1 METHODS

=head2 C<state>

=head2 C<name>

=head2 C<powerup>

These methods are implemented as per Games::Nintendo::Mario

=head2 C<power>

=head2 C<speed>

=head2 C<jump>

These methods return the requested attribute for the current character.

=head2 C<games>

The rules reflected in this module were only present in Super Mario Bros. 2
(and its re-releases).

=head1 AUTHOR

Ricardo SIGNES, <rjbs@cpan.org>

=head1 COPYRIGHT

Copyright 2003-2004 by Ricardo SIGNES <rjbs@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

