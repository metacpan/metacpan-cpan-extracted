use 5.20.0;
use warnings;
package Games::Nintendo::Mario::NSMB 0.209;
# ABSTRACT: a class for stylus-enabled Italian plumbers

use parent qw(Games::Nintendo::Mario);

use Carp ();

#pod =head1 SYNOPSIS
#pod
#pod   use Games::Nintendo::Mario::NSMB;
#pod
#pod   my $hero = Games::Nintendo::Mario::SMB->new(
#pod    name  => 'Luigi',
#pod    state => 'normal',
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
#pod of the Mario Brothers in New Super Mario Brothers.  All of the methods
#pod described in the Mario interface exist as documented.
#pod
#pod =head2 NAMES
#pod
#pod The plumber may be named Mario or Luigi.
#pod
#pod =head2 STATES
#pod
#pod The plumber's state may be any of: normal super fire shell mini mega
#pod
#pod =head2 POWERUPS
#pod
#pod Valid powerups are: mushroom flower shell mega_mushroom mini_mushroom
#pod
#pod =method games
#pod
#pod This ruleset reflects Mario in New Super Mario Bros., the first SMB game for
#pod Nintendo DS.
#pod
#pod =cut

sub _names  { qw[Mario Luigi] }
sub _states { qw[normal super fire shell mini mega] }
sub _items  { qw[mushroom flower shell mega_mushroom mini_mushroom] }

my %__default_behavior = (
  damage   => 'dead',
  mushroom => 'super',
  flower   => 'fire',
  shell    => 'shell',
  mega_mushroom => 'mega',
  mini_mushroom => 'mini',
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
);

sub games {
  return ('New Super Mario Bros.');
}

sub _set_state {
  my ($self, $state, $item) = @_;

  if ($state eq 'save') {
    $self->{saved_item} = $item;
  } else {
    $self->{state} = $state;
  }
  return $self;
}

sub powerup {
  my ($self, $item) = @_;

  my $state = $self->state;
  Carp::confess "current state unknown"
    unless my $state_info = $state{ $state };

  Carp::confess "behavior for $item in $state unknown"
    unless my $new_state = $state_info->{$item};
  $self->_set_state($new_state, $item);
}

sub damage {
  my ($self) = @_;
  $self->powerup('damage');
}

"Go Wigi!";

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Nintendo::Mario::NSMB - a class for stylus-enabled Italian plumbers

=head1 VERSION

version 0.209

=head1 SYNOPSIS

  use Games::Nintendo::Mario::NSMB;

  my $hero = Games::Nintendo::Mario::SMB->new(
   name  => 'Luigi',
   state => 'normal',
  );

  $hero->powerup('mushroom'); # doop doop doop!
  $hero->powerup('flower');   # change clothes

  $hero->damage for (1 .. 2); # cue the Mario Death Music

=head1 DESCRIPTION

This class subclasses Games::Nintendo::Mario, providing a model of the behavior
of the Mario Brothers in New Super Mario Brothers.  All of the methods
described in the Mario interface exist as documented.

=head2 NAMES

The plumber may be named Mario or Luigi.

=head2 STATES

The plumber's state may be any of: normal super fire shell mini mega

=head2 POWERUPS

Valid powerups are: mushroom flower shell mega_mushroom mini_mushroom

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

This ruleset reflects Mario in New Super Mario Bros., the first SMB game for
Nintendo DS.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
