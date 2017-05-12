
=head1 NAME

Lingua::Alphabet::Phonetic - map ABC's to phonetic alphabets

=head1 SYNOPSIS

  use Lingua::Alphabet::Phonetic;
  my $oMilSpeaker = new Lingua::Alphabet::Phonetic('NATO');
  my @asMilSpeak = $oMilSpeaker->enunciate('ABC');

=head1 DESCRIPTION

At present, the only alphabet available for conversion is the
U.S. Military / NATO standard where "ABC...YZ" is pronounced "Alpha
Bravo Charlie ... Yankee Zulu".  It is called 'NATO' and it is
included with this distribution.

=head1 METHODS

=over

=cut

#####################################################################

package Lingua::Alphabet::Phonetic;

use strict;
use warnings;

our
$VERSION = 1.12;

=item new

Create an object of this class.  See SYNOPSIS above.

=cut

sub new
  {
  my $class = shift;
  my $sAlphabet = shift || '';
  my $sSubclass = "${class}::$sAlphabet";
  eval "use $sSubclass";
  Carp::croak("Unknown phonetic alphabet $sAlphabet: $@") if ($@);
  my $self = bless {
                   }, $sSubclass;
  return $self;
  } # new


=item enunciate

Given a string, returns a list of phonetic alphabet "words", one word
per character of the original string.  If there is no "word" in the
alphabet for a character, that character is returned in the list
position.

=cut

sub enunciate
  {
  my $self = shift;
  my $s = shift || '';
  my @ac = split('', $s);
  return map { $self->_name_of_letter($_) } @ac;
  } # enunciate


sub _name_of_letter
  {
  # This is the default fallback character --> word mapping.
  my $self = shift;
  my $s = shift;
  # Just return our argument unchanged:
  return $s;
  } # _name_of_letter

=back

=head1 OTHER ALPHABETS

To create a conversion scheme for another alphabet, simply subclass
this module and provide a method _name_of_letter() which takes a
character and returns its phonetic name.  See NATO.pm as an example.

=head1 SEE ALSO

http://en.wikipedia.org/wiki/Spelling_alphabet is a brief overview

http://www.bckelk.uklinux.net/phon.full.html contains a list of
phonetic alphabets from all over the world!

=head1 TO-DO

=over

=item Implement more alphabets.

=item Investigate how we might handle non-ASCII alphabets.  Unicode?

=back

=head1 BUGS

Please tell the author if you find any!

=head1 LICENSE

This software is released under the same license as Perl itself.

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

1;

__END__

