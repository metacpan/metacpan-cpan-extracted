use 5.20.0;
use warnings;
package Games::Nintendo::Mario::SMB3 0.209;
# ABSTRACT: a class for fuzzy-tailed Italian plumbers

use parent qw(Games::Nintendo::Mario);

#pod =head1 SYNOPSIS
#pod
#pod   use Games::Nintendo::Mario::SMB3;
#pod
#pod   my $hero = Games::Nintendo::Mario::SMB->new(
#pod     name  => 'Mario',
#pod     state => 'hammer',
#pod   );
#pod   
#pod   $hero->powerup('mushroom'); # Nothing happens.
#pod   $hero->damage;              # back to super
#pod
#pod   print "It's-a me!  ", $hero->name, "!\n"; # 'Super Mario'
#pod
#pod   $hero->powerup('frogsuit'); # Nothing happens.
#pod
#pod   $hero->damage for (1 .. 2); # cue the Mario Death Music
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class subclasses Games::Nintendo::Mario, providing a model of the behavior
#pod of the Mario Brothers in Super Mario Brothers 3.  All of the methods described
#pod in the Mario interface exist as documented.
#pod
#pod =head2 NAMES
#pod
#pod The plumber may be named Mario or Luigi.
#pod
#pod =head2 STATES
#pod
#pod The plumber's state may be any of: C<normal>, C<super>, C<fire>, C<raccoon>,
#pod C<tanooki>, C<hammer>, C<frog>, or C<pwing>
#pod
#pod =head2 POWERUPS
#pod
#pod Valid powerups are: C<mushroom>, C<flower>, C<leaf>, C<tanookisuit>,
#pod C<hammersuit>, C<frogsuit>, or C<pwing>
#pod
#pod =method games
#pod
#pod This ruleset reflects Mario in Super Mario Bros. 3.
#pod
#pod =cut

sub _names  { qw[Mario Luigi] }
sub _states { qw[normal super fire raccoon tanooki frog hammer pwing] }
sub _items  { qw[mushroom flower leaf tanookisuit frogsuit hammersuit pwing] }

sub _goto_hash {
  {
    damage    => {
      normal  => 'dead',
      super  => 'normal',
      _else  => 'super'
    },
    mushroom   => {
      normal  => 'super'
    },
    flower    => 'fire',
    leaf    => 'raccoon',
    tanookisuit  => 'tanooki',
    hammersuit  => 'hammer',
    frogsuit  => 'frog',
    pwing    => 'pwing'
  }
}

sub games {
  return ('Super Mario Bros. 3');
}

"It's-a me!  Mario!";

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Nintendo::Mario::SMB3 - a class for fuzzy-tailed Italian plumbers

=head1 VERSION

version 0.209

=head1 SYNOPSIS

  use Games::Nintendo::Mario::SMB3;

  my $hero = Games::Nintendo::Mario::SMB->new(
    name  => 'Mario',
    state => 'hammer',
  );
  
  $hero->powerup('mushroom'); # Nothing happens.
  $hero->damage;              # back to super

  print "It's-a me!  ", $hero->name, "!\n"; # 'Super Mario'

  $hero->powerup('frogsuit'); # Nothing happens.

  $hero->damage for (1 .. 2); # cue the Mario Death Music

=head1 DESCRIPTION

This class subclasses Games::Nintendo::Mario, providing a model of the behavior
of the Mario Brothers in Super Mario Brothers 3.  All of the methods described
in the Mario interface exist as documented.

=head2 NAMES

The plumber may be named Mario or Luigi.

=head2 STATES

The plumber's state may be any of: C<normal>, C<super>, C<fire>, C<raccoon>,
C<tanooki>, C<hammer>, C<frog>, or C<pwing>

=head2 POWERUPS

Valid powerups are: C<mushroom>, C<flower>, C<leaf>, C<tanookisuit>,
C<hammersuit>, C<frogsuit>, or C<pwing>

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

This ruleset reflects Mario in Super Mario Bros. 3.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
