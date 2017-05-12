
package Lingua::Alphabet::Phonetic::StarWars;

use strict;
use warnings;

=head1 NAME

Lingua::Alphabet::Phonetic::StarWars - map ASCII characters to names of Star Wars characters

=head1 SYNOPSIS

This is a specialization of L<Lingua::Alphabet::Phonetic>.
You should not use this module directly;
all interaction should be done with an object of type Lingua::Alphabet::Phonetic.

  my $oSpeaker = new Lingua::Alphabet::Phonetic('StarWars');

=head1 NOTES

=head1 SEE ALSO

http://www.wookieepedia.org

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=head1 LICENSE

This software is released under the same license as Perl itself.

=cut

#####################################################################

use base 'Lingua::Alphabet::Phonetic';
our
$VERSION = 1.201;

my @as = qw(
           Ackbar
           Bantha
           Chewbacca
           Dengar
           Evazan
           Fisto
           Greedo
           Hutt
           Isolder
           Jedi
           Kenobi
           Leia
           Mothma
           Needa
           Organa
           Palpatine
           Quadinaros
           Ree-Yees
           Skywalker
           Tyranus
           Ugnaught
           Vader
           Wampa
           X-wing
           Yoda
           Zuckuss
          );
my %hash = map { uc substr($_,0,1) => $_ } @as;

sub _name_of_letter
  {
  my $self = shift;
  my $s = shift;
  # print STDERR " + L::A::P::StarWars::_name_of_letter($s)\n";
  # If we get more than one character, ignore the rest:
  my $c = uc substr($s, 0, 1);
  # This module throws out punctuation:
  return if $c !~ m/[A-Z0-9]/;
  if (exists($hash{$c}))
    {
    return $hash{$c};
    } # if
  return $self->SUPER::_name_of_letter($s);
  } # _name_of_letter

1;

__END__
