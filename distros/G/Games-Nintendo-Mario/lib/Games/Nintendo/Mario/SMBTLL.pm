use 5.20.0;
use warnings;
package Games::Nintendo::Mario::SMBTLL 0.209;
# ABSTRACT: a class for long-lost Italian plumbers

use parent qw(Games::Nintendo::Mario::SMB);

#pod =head1 SYNOPSIS
#pod
#pod   use Games::Nintendo::Mario::SMBLL;
#pod
#pod   my $hero = Games::Nintendo::Mario::SMB->new(
#pod     name  => 'Luigi',
#pod     state => 'normal',
#pod   );
#pod
#pod   $hero->powerup('mushroom'); # doop doop doop!
#pod   $hero->powerup('flower');   # change clothes
#pod
#pod   $hero->powerup('poison_mushroom'); # uh oh!
#pod   $hero->damage;                     # cue the Mario Death Music
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class subclasses Games::Nintendo::Mario, providing a model of the behavior
#pod of the Mario Brothers in Super Mario Brothers: The Lost Levels.  All of the
#pod methods described in the Mario interface exist as documented.
#pod
#pod =head2 NAMES
#pod
#pod The plumber may be named Mario or Luigi.
#pod
#pod =head2 STATES
#pod
#pod The plumber's state may be any of: C<normal>, C<super>, or C<fire>
#pod
#pod =head2 POWERUPS
#pod
#pod Valid powerups are: C<mushroom>, C<poison_mushroom>, and C<flower>
#pod
#pod =method games
#pod
#pod This ruleset reflects Mario in Super Mario Bros.: The Lost Levels, the original
#pod Japanese sequel to SMB, later released as SMBTLL in the US (and now available
#pod on the Wii Virtual Console).
#pod
#pod =cut

sub _items  { qw[mushroom flower poison_mushroom] }

sub _goto_hash {
  my ($self) = @_;

  my $goto_hash = $self->SUPER::_goto_hash;

  return {
    %$goto_hash,
    poison_mushroom => $goto_hash->{damage}
  }
}

sub games {
  return (
    'Super Mario Bros.: The Lost Levels',
    # 'Super Mario Bros. 2: For Super Players',
  );
}

"It's-a me!  Mario!";

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Nintendo::Mario::SMBTLL - a class for long-lost Italian plumbers

=head1 VERSION

version 0.209

=head1 SYNOPSIS

  use Games::Nintendo::Mario::SMBLL;

  my $hero = Games::Nintendo::Mario::SMB->new(
    name  => 'Luigi',
    state => 'normal',
  );

  $hero->powerup('mushroom'); # doop doop doop!
  $hero->powerup('flower');   # change clothes

  $hero->powerup('poison_mushroom'); # uh oh!
  $hero->damage;                     # cue the Mario Death Music

=head1 DESCRIPTION

This class subclasses Games::Nintendo::Mario, providing a model of the behavior
of the Mario Brothers in Super Mario Brothers: The Lost Levels.  All of the
methods described in the Mario interface exist as documented.

=head2 NAMES

The plumber may be named Mario or Luigi.

=head2 STATES

The plumber's state may be any of: C<normal>, C<super>, or C<fire>

=head2 POWERUPS

Valid powerups are: C<mushroom>, C<poison_mushroom>, and C<flower>

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

This ruleset reflects Mario in Super Mario Bros.: The Lost Levels, the original
Japanese sequel to SMB, later released as SMBTLL in the US (and now available
on the Wii Virtual Console).

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
