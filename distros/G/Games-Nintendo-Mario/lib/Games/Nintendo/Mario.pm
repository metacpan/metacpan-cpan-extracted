use 5.20.0;
use warnings;
package Games::Nintendo::Mario 0.209;
# ABSTRACT: a class for jumping Italian plumbers

#pod =head1 SYNOPSIS
#pod
#pod   use Games::Nintendo::Mario;
#pod
#pod   my $hero = Games::Nintendo::Mario->new(name => 'Luigi');
#pod
#pod   $hero->damage; # cue the Mario Death Music
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides a base class for representing the Mario Brothers from
#pod Nintendo's long-running Mario franchise of games.  Each Mario object keeps
#pod track of the plumber's current state and can be damaged or given powerups to
#pod change his state.
#pod
#pod =cut

use Carp qw(cluck);

sub _names  { qw[Mario Luigi] }
sub _states { qw[normal] }
sub _items  { () }
sub _other_defaults { () }

sub _goto_hash   {
  { damage => 'dead' }
}

sub _goto {
  my $self = shift;
  my ($state, $item) = @_;
  my $goto = $self->_goto_hash;

  return unless exists $goto->{$item};
  return $goto->{$item} unless ref $goto->{$item} eq 'HASH';
  return $goto->{$item}{_else} unless $goto->{$item}{$state};
  return $goto->{$item}{$state};
}

#pod =method new
#pod
#pod   my $hero = Games::Nintendo::Mario->new(name => 'Luigi');
#pod
#pod The constructor for Mario objects takes two named parameters, C<name> and
#pod C<state>.  C<name> must be either "Mario" or "Luigi" and C<state> must be
#pod "normal"
#pod
#pod If left undefined, C<name> and C<state> will default to "Mario" and "normal"
#pod respectively.
#pod
#pod =cut

sub new {
  my $class = shift;
  my %args  = (name => 'Mario', state => 'normal', @_);

  unless (grep { $_ eq $args{name} } $class->_names) {
    cluck "bad name for plumber";
    return;
  }
  unless (grep { $_ eq $args{state} } $class->_states) {
    cluck "bad starting state for plumber";
    return;
  }

  my $plumber = {
    state => $args{state},
    name  => $args{name},
    $class->_other_defaults
  };

  bless $plumber => $class;
}

#pod =method powerup
#pod
#pod   $hero->powerup('hammer'); # this won't work
#pod
#pod As the base Games::Nintendo::Mario class represents Mario from the original
#pod Mario Bros., there is no valid way to call this method.  Subclasses
#pod representing Mario in other games may allow various powerup names to be passed.
#pod
#pod =cut

sub powerup {
  my $plumber = shift;
  my $item    = shift;

  if ($plumber->state eq 'dead') {
    cluck "$plumber->{name} can't power up when dead";
    return $plumber;
  }

  unless (grep { $_ eq $item } $plumber->_items) {
    cluck "$plumber->{name} can't power up with that!";
    return $plumber;
  }

  my $goto = $plumber->_goto($plumber->state,$item);

  $plumber->{state} = $goto if $goto;

  return $plumber;
}

#pod =method damage
#pod
#pod   $hero->damage;
#pod
#pod This method causes the object to react as if Mario has been attacked or
#pod damaged.  In the base Games::Nintendo::Mario class, this will always result in
#pod his death.
#pod
#pod =cut

sub damage {
  my $plumber = shift;

  my $goto = $plumber->_goto($plumber->state,'damage');

  $plumber->{state} = $goto if $goto;

  return $plumber;
}

#pod =method state
#pod
#pod   print $hero->state;
#pod
#pod This method accesses the name of Mario's current state.
#pod
#pod =cut

sub state { ## no critic Homonym
  my $plumber = shift;

  return $plumber->{state};
}

#pod =method name
#pod
#pod   print $hero->name;
#pod
#pod This method returns the name of the plumber's current form.  (In the base
#pod class, this is always the same as the name passed to the constructor.)
#pod
#pod =cut

sub name {
  my $plumber = shift;

  return $plumber->{name} if $plumber->state eq 'normal';

  my $name = $plumber->state . q{ } . $plumber->{name};
  $name =~ s/(^.)/\u$1/;
  return $name;
}

#pod =method games
#pod
#pod   if (grep /World/, $hero->games) { ... }
#pod
#pod This returns a list of the games in which Mario behaved according to the model
#pod provided by this class.
#pod
#pod =cut

sub games {
  return ('Mario Bros.');
}

#pod =head1 TODO
#pod
#pod Wario, SMW.
#pod
#pod =cut

"It's-a me!  Mario!";

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Nintendo::Mario - a class for jumping Italian plumbers

=head1 VERSION

version 0.209

=head1 SYNOPSIS

  use Games::Nintendo::Mario;

  my $hero = Games::Nintendo::Mario->new(name => 'Luigi');

  $hero->damage; # cue the Mario Death Music

=head1 DESCRIPTION

This module provides a base class for representing the Mario Brothers from
Nintendo's long-running Mario franchise of games.  Each Mario object keeps
track of the plumber's current state and can be damaged or given powerups to
change his state.

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

=head2 new

  my $hero = Games::Nintendo::Mario->new(name => 'Luigi');

The constructor for Mario objects takes two named parameters, C<name> and
C<state>.  C<name> must be either "Mario" or "Luigi" and C<state> must be
"normal"

If left undefined, C<name> and C<state> will default to "Mario" and "normal"
respectively.

=head2 powerup

  $hero->powerup('hammer'); # this won't work

As the base Games::Nintendo::Mario class represents Mario from the original
Mario Bros., there is no valid way to call this method.  Subclasses
representing Mario in other games may allow various powerup names to be passed.

=head2 damage

  $hero->damage;

This method causes the object to react as if Mario has been attacked or
damaged.  In the base Games::Nintendo::Mario class, this will always result in
his death.

=head2 state

  print $hero->state;

This method accesses the name of Mario's current state.

=head2 name

  print $hero->name;

This method returns the name of the plumber's current form.  (In the base
class, this is always the same as the name passed to the constructor.)

=head2 games

  if (grep /World/, $hero->games) { ... }

This returns a list of the games in which Mario behaved according to the model
provided by this class.

=head1 TODO

Wario, SMW.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
