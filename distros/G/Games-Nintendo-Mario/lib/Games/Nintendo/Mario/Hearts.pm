use 5.20.0;
use warnings;
package Games::Nintendo::Mario::Hearts 0.208;
# ABSTRACT: a superclass for Italian plubmers who can take a beating

use parent qw(Games::Nintendo::Mario);
use Hash::Util::FieldHash qw(fieldhash);

#pod =head1 SYNOPSIS
#pod
#pod   use Games::Nintendo::Mario::Hearts;
#pod
#pod   my $noone = Games::Nintendo::Mario::Hearts->new;
#pod
#pod   print $hero->hearts . '/' . $hero->max_hearts; # at 1/3 health
#pod   $hero->powerup('heart');                       # up to 2/3!
#pod   $hero->powerup('heart');                       # full health!
#pod
#pod   print "It's-a me!  ", $hero->name, "!\n";      # 'Mario'
#pod
#pod   $hero->powerup('heart');                       # Nothing happens.
#pod
#pod   $hero->damage for (1 .. 3);                    # cue the Mario Death Music
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class subclasses Games::Nintendo::Mario, providing a class for further
#pod subclassing.  It adds the C<hearts> and C<max_hearts> methods, described below,
#pod and it causes Mario to die when his hearts count reaches zero.  This behavior
#pod is found in SMB2 and the Wario games.
#pod
#pod All of the methods described in the Mario interface exist as documented, but
#pod the only powerup in this class is 'heart' and the only state is 'normal'
#pod
#pod =method hearts
#pod
#pod This method returns the number of hearts the plumber currently has.  It
#pod defaults to 1 at creation.
#pod
#pod =method max_hearts
#pod
#pod This method returns the number of heart containers currently in the plumber's
#pod heart meter.  It defaults to 3 at creation.
#pod
#pod =method damage
#pod
#pod =method powerup
#pod
#pod These methods are defined in Games::Nintendo::Mario.
#pod
#pod =method games
#pod
#pod This is an abstract subclass for Mario classes, and does not represent any one
#pod game.
#pod
#pod =cut


sub _states { qw[normal] }
sub _items  { qw[heart] }
sub _other_defaults  { ( max_hearts => 3 ) }
sub __default_hearts { 1 };

sub _goto_hash { {} } # not used by base Hearts class

sub max_hearts {
  return $_[0]->{max_hearts}
}

fieldhash my %hearts;
sub hearts {
  my ($self) = @_;
  $hearts{ $self } //= $self->__default_hearts;
  return $hearts{ $self };
}

sub powerup {
  my $plumber  = shift;
  my $item     = shift;

  if (($item eq 'heart') and ($plumber->hearts) and ($plumber->hearts < $plumber->max_hearts)) {
    $hearts{ $plumber }++;
  }
  $plumber->SUPER::powerup($item);
}

sub damage {
  my $self = shift;
  my $item = shift;

  if ($self->hearts) {
    $self->{state} = 'dead' unless --$hearts{ $self };
  }

  $self->SUPER::damage;
}

sub games {
  return ();
}

"It's-a me!  Mario!";

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Nintendo::Mario::Hearts - a superclass for Italian plubmers who can take a beating

=head1 VERSION

version 0.209

=head1 SYNOPSIS

  use Games::Nintendo::Mario::Hearts;

  my $noone = Games::Nintendo::Mario::Hearts->new;

  print $hero->hearts . '/' . $hero->max_hearts; # at 1/3 health
  $hero->powerup('heart');                       # up to 2/3!
  $hero->powerup('heart');                       # full health!

  print "It's-a me!  ", $hero->name, "!\n";      # 'Mario'

  $hero->powerup('heart');                       # Nothing happens.

  $hero->damage for (1 .. 3);                    # cue the Mario Death Music

=head1 DESCRIPTION

This class subclasses Games::Nintendo::Mario, providing a class for further
subclassing.  It adds the C<hearts> and C<max_hearts> methods, described below,
and it causes Mario to die when his hearts count reaches zero.  This behavior
is found in SMB2 and the Wario games.

All of the methods described in the Mario interface exist as documented, but
the only powerup in this class is 'heart' and the only state is 'normal'

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

=head2 hearts

This method returns the number of hearts the plumber currently has.  It
defaults to 1 at creation.

=head2 max_hearts

This method returns the number of heart containers currently in the plumber's
heart meter.  It defaults to 3 at creation.

=head2 damage

=head2 powerup

These methods are defined in Games::Nintendo::Mario.

=head2 games

This is an abstract subclass for Mario classes, and does not represent any one
game.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
