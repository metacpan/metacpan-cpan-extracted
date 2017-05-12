package Games::Zumbis;
BEGIN {
  $Games::Zumbis::VERSION = '0.05';
}
use strict;
use warnings;

use File::ShareDir ();
use Path::Class    ();
use FindBin        ();

my $sharedir;

sub sharedir {
    return $sharedir if $sharedir;

    my $root = Path::Class::Dir->new($FindBin::Bin,'..');

    # desenvolvimento
    if ( -f $root->file('dist.ini') ) {
        $sharedir = $root->subdir('share');
    }
    # instalado
    else {
        $sharedir = Path::Class::Dir->new( File::ShareDir::dist_dir('Games-Zumbis') );
    }

    return $sharedir;
}

'zombies!!';

__END__

=head1 NAME

Games::Zumbis - How long can you survive in a zombies attack

=head1 SYNOPSIS

  # install the game and its prereqs
  cpan Games::Zumbis

  # run the game
  zumbis

  # get addicted

=head1 DESCRIPTION

This game started as a self-imposed challenge by the authors to get a
game written from scratch during the 11th International Free Software
Forum - Forum Internacional de Software Livre FISL - from 21 to 24
july of 2010 in Porto Alegre, Brasil.

The game was playable and subject to a small gaming competition that
took place 24 of july 15h being projected in a big screen near the
"user groups" area.

The initial game art was taken from the free tile sets from
http://silveiraneto.net and heavily modified (specially the zombie
char) by Gustavo Barbosa during the event.

The gameplay is fast, simple and addictive: You have to shot the
zombies before they touch you moving only in four directions and with
only 4 bullets in the screen. You will, inexorably, die. The question
is: How much time you survive, and how many zombies can you kill.

=head1 GAME CONTROL

You move the character with the 4 arrow keys and fire with the space
key. You might also choose between the male and female character
before re-starting the game by using the keys 1 and 2.

=head1 LICENSE

The code is distributed in the same terms as Perl itself (Artistic
License 2 or GPL). For the game media, take a look in the CREDITS file
that lists each source and specific license.

=head1 AUTHORS

  $ git log | grep Author | sort | uniq
  Author: Breno G. de Oliveira <garu@cpan.org>
  Author: Daniel Ruoso <daniel@ruoso.com>
  Author: Gustavo Barbosa <gustavo.b.pires@gmail.com>
  Author: Kartik Thakore <thakore.kartik@gmail.com>
  Author: Tobias Leich <email@froggs.de>

=head1 CONTRIBUTIONS

You may take a look at http://github.com/ruoso/Zumbis, you can go to
L<irc://irc.perl.org/sdl> and talk to the developers, we are very permissive
in granting push rights.
