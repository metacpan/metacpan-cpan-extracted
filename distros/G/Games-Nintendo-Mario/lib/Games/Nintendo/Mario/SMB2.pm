use 5.20.0;
use warnings;
package Games::Nintendo::Mario::SMB2 0.209;
# ABSTRACT: a class for vegetable-throwing Italian plumbers (and friends)

use parent qw(Games::Nintendo::Mario::Hearts);

#pod =head1 SYNOPSIS
#pod
#pod   use Games::Nintendo::Mario::SMB2;
#pod
#pod   my $liege = Games::Nintendo::Mario::SMB2->new(name => 'Peach');
#pod
#pod   # below outputs "Peach: 1/3"
#pod   say $liege->name . ": " . $liege->hearts . "/" . $liege->max_hearts;
#pod
#pod   $liege->powerup('heart');    # 2/3
#pod   $liege->damage;              # 1/3
#pod   $liege->powerup('mushroom'); # 1/4
#pod   $liege->powerup('heart');    # 2/4
#pod   $liege->powerup('mushroom'); # 2/5
#pod   $liege->powerup('heart');    # 3/5
#pod
#pod   say "I'm feeling ", $liege->state, "!"; # She's feeling super.
#pod
#pod   $liege->powerup('mushroom'); # Nothing happens.
#pod
#pod   $liege->damage for (1 .. 3); # cue the Mario Death Music
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class subclasses Games::Nintendo::Mario (and G::N::M::Hearts), providing a
#pod model of the behavior of the Mario Brothers in Super Mario Brothers 2.  All of
#pod the methods described in the Mario interface exist as documented.
#pod
#pod =head2 NAMES
#pod
#pod The plumber may be named Mario or Luigi, or a non-plumbing character named
#pod Peach or Toad may be created.
#pod
#pod =head2 STATES
#pod
#pod C<< $hero->state >> will return 'dead' if he has no hearts, 'normal' if he has
#pod one heart, and 'super' if he has more than one heart.  State may not be set
#pod during construction; set hearts instead.
#pod
#pod =head2 POWERUPS
#pod
#pod Valid powerups are: C<mushroom> or C<heart>
#pod
#pod =method state
#pod
#pod =method name
#pod
#pod =method powerup
#pod
#pod These methods are implemented as per Games::Nintendo::Mario
#pod
#pod =method power
#pod
#pod =method speed
#pod
#pod =method jump
#pod
#pod These methods return the requested attribute for the current character.
#pod
#pod =method games
#pod
#pod The rules reflected in this module were only present in Super Mario Bros. 2
#pod (and its re-releases).
#pod
#pod =cut

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

=pod

=encoding UTF-8

=head1 NAME

Games::Nintendo::Mario::SMB2 - a class for vegetable-throwing Italian plumbers (and friends)

=head1 VERSION

version 0.209

=head1 SYNOPSIS

  use Games::Nintendo::Mario::SMB2;

  my $liege = Games::Nintendo::Mario::SMB2->new(name => 'Peach');

  # below outputs "Peach: 1/3"
  say $liege->name . ": " . $liege->hearts . "/" . $liege->max_hearts;

  $liege->powerup('heart');    # 2/3
  $liege->damage;              # 1/3
  $liege->powerup('mushroom'); # 1/4
  $liege->powerup('heart');    # 2/4
  $liege->powerup('mushroom'); # 2/5
  $liege->powerup('heart');    # 3/5

  say "I'm feeling ", $liege->state, "!"; # She's feeling super.

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

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 state

=head2 name

=head2 powerup

These methods are implemented as per Games::Nintendo::Mario

=head2 power

=head2 speed

=head2 jump

These methods return the requested attribute for the current character.

=head2 games

The rules reflected in this module were only present in Super Mario Bros. 2
(and its re-releases).

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
