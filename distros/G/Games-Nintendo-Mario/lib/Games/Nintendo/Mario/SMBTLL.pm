use 5.16.0;
use warnings;
package Games::Nintendo::Mario::SMBTLL 0.208;

use parent qw(Games::Nintendo::Mario::SMB);

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

=head1 NAME

Games::Nintendo::Mario::SMBTLL - a class for long-lost Italian plumbers

=head1 VERSION

version 0.208

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

=head1 METHODS

=head2 C<games>

This ruleset reflects Mario in Super Mario Bros.: The Lost Levels, the original
Japanese sequel to SMB, later released as SMBTLL in the US (and now available
on the Wii Virtual Console).

=head1 AUTHOR

Ricardo SIGNES E<lt>rjbs@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 by Ricardo SIGNES E<lt>rjbs@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

