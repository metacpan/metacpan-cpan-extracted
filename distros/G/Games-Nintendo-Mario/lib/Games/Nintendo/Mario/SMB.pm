use 5.16.0;
use warnings;
package Games::Nintendo::Mario::SMB 0.208;

use base qw(Games::Nintendo::Mario);

sub _names  { qw[Mario Luigi] }
sub _states { qw[normal super fire] }
sub _items  { qw[mushroom flower] }

sub _goto_hash {
  {
    damage => {
      normal => 'dead',
      _else  => 'normal'
    },
    mushroom => {
      fire  => 'fire',
      _else => 'super',
    },
    flower => {
      normal => 'super',
      _else  => 'fire'
    }
  }
}

sub games {
  return ('Super Mario Bros.');
}

"It's-a me!  Mario!";

__END__

=head1 NAME

Games::Nintendo::Mario::SMB - a class for mushroom-eating Italian plumbers

=head1 VERSION

version 0.208

=head1 SYNOPSIS

  use Games::Nintendo::Mario::SMB;

  my $hero = Games::Nintendo::Mario::SMB->new(
    name  => 'Luigi',
    state => 'normal',
  );
  
  $hero->powerup('mushroom'); # doop doop doop!
  $hero->powerup('flower');   # change clothes

  $hero->damage for (1 .. 2); # cue the Mario Death Music

=head1 DESCRIPTION

This class subclasses Games::Nintendo::Mario, providing a model of the behavior
of the Mario Brothers in Super Mario Brothers.  All of the methods described in
the Mario interface exist as documented.

=head2 NAMES

The plumber may be named Mario or Luigi.

=head2 STATES

The plumber's state may be any of: C<normal>, C<super>, or C<fire>

=head2 POWERUPS

Valid powerups are: C<mushroom> and C<flower>

=head1 METHODS

=over 4

=item C<games>

This ruleset reflects Mario in Super Mario Bros., the original SMB game.

=back

=head1 AUTHOR

Ricardo SIGNES E<lt>rjbs@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Ricardo SIGNES E<lt>rjbs@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

