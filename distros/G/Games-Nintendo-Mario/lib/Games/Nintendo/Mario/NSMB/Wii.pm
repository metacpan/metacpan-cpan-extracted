use 5.20.0;
use warnings;
package Games::Nintendo::Mario::NSMB::Wii 0.209;
# ABSTRACT: a class for Italian plumbers who wave their hands around

use parent qw(Games::Nintendo::Mario::NSMB);

#pod =head1 WARNING!!
#pod
#pod Nobody has given RJBS a copy of NSMB Wii yet, so he hasn't played it, so this
#pod class may not be an accurate reflection of its behavior.
#pod
#pod =head1 SYNOPSIS
#pod
#pod   use Games::Nintendo::Mario::NSMB::Wii;
#pod
#pod   my $hero = Games::Nintendo::Mario::SMB->new(
#pod     name  => 'Blue Toad',
#pod     state => 'normal',
#pod   );
#pod
#pod   $hero->powerup('mushroom'); # doop doop doop!
#pod   $hero->powerup('flower');   # change clothes
#pod
#pod   $hero->damage for (1 .. 2); # cue the Mario Death Music
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class subclasses Games::Nintendo::Mario, providing a model of the behavior
#pod of the Mario Brothers in New Super Mario Bros. for Wii.  All of the methods
#pod described in the Mario interface exist as documented.
#pod
#pod =head2 NAMES
#pod
#pod The plumber may be named Mario or Luigi, or can be "Blue Toad" or "Yellow
#pod Toad."
#pod
#pod =head2 STATES
#pod
#pod The plumber's state may be any of: normal super fire shell mini mega ice
#pod penguin propeller
#pod
#pod =head2 POWERUPS
#pod
#pod Valid powerups are: mushroom flower shell mega_mushroom mini_mushroom
#pod ice_flower penguinsuit propeller_mushroom
#pod
#pod =method games
#pod
#pod This ruleset reflects Mario in New Super Mario Bros. Wii, the first SMB game
#pod for Nintendo Wii.
#pod
#pod =cut

use Carp ();

sub _names  { ('Mario', 'Luigi', 'Blue Toad', 'Yellow Toad') }
sub _states { qw[normal super fire shell mini mega propeller ice penguin] }
sub _items  { qw[mushroom flower shell mega_mushroom mini_mushroom propeller_mushroom ice_flower penguinsuit] }

my %__default_behavior = (
  damage   => 'dead',
  mushroom => 'super',
  flower   => 'fire',
  shell    => 'shell',
  mega_mushroom => 'mega',
  mini_mushroom => 'mini',
  propeller_mushroom => 'propeller',
  ice_flower         => 'ice',
  penguinsuit        => 'penguin',
);

my %state = (
  normal => { %__default_behavior },
  super  => {
    %__default_behavior,
    damage   => 'normal',
    mushroom => 'save',
  },
  fire   => {
    %__default_behavior,
    damage   => 'normal',
    flower   => 'save',
    mushroom => 'save',
  },
  shell  => {
    %__default_behavior,
    damage   => 'super',
    mushroom => 'save',
    flower   => 'save',
  },
  mega   => { map { $_ => 'ignore' } keys %__default_behavior },
  mini   => { %__default_behavior, mini => 'save' },

  propeller  => {
    %__default_behavior,
    damage   => 'normal',
    mushroom => 'save',
  },
  ice  => {
    %__default_behavior,
    damage   => 'normal',
    mushroom => 'save',
  },
  penguin  => {
    %__default_behavior,
    damage   => 'normal',
    mushroom => 'save',
  },
);

sub games {
  return ('New Super Mario Bros. Wii');
}

"Go Wigi!";

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Nintendo::Mario::NSMB::Wii - a class for Italian plumbers who wave their hands around

=head1 VERSION

version 0.209

=head1 SYNOPSIS

  use Games::Nintendo::Mario::NSMB::Wii;

  my $hero = Games::Nintendo::Mario::SMB->new(
    name  => 'Blue Toad',
    state => 'normal',
  );

  $hero->powerup('mushroom'); # doop doop doop!
  $hero->powerup('flower');   # change clothes

  $hero->damage for (1 .. 2); # cue the Mario Death Music

=head1 DESCRIPTION

This class subclasses Games::Nintendo::Mario, providing a model of the behavior
of the Mario Brothers in New Super Mario Bros. for Wii.  All of the methods
described in the Mario interface exist as documented.

=head2 NAMES

The plumber may be named Mario or Luigi, or can be "Blue Toad" or "Yellow
Toad."

=head2 STATES

The plumber's state may be any of: normal super fire shell mini mega ice
penguin propeller

=head2 POWERUPS

Valid powerups are: mushroom flower shell mega_mushroom mini_mushroom
ice_flower penguinsuit propeller_mushroom

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

=head2 games

This ruleset reflects Mario in New Super Mario Bros. Wii, the first SMB game
for Nintendo Wii.

=head1 WARNING!!

Nobody has given RJBS a copy of NSMB Wii yet, so he hasn't played it, so this
class may not be an accurate reflection of its behavior.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
