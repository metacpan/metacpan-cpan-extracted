package Lingua::Pangram;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use locale; # for correct lowercasing of 8-bit chars

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw( );
$VERSION = '0.02';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new {
    my $class = shift;
    my $alphabet = shift || [ 'a' .. 'z' ];
    my $self  = bless $alphabet, $class;
    return $self;
}#new


sub pangram {
    my $self = shift;
    my $string = lc shift;

    my $ret = 1;
    foreach my $letter (@$self) {
        $ret = 0 if index($string, $letter) == -1;
    }

    return $ret;
}#pangram

1;
__END__
=head1 NAME

Lingua::Pangram - Is this string a pangram

=head1 SYNOPSIS

  use Lingua::Pangram;
  my $pan = Lingua::Pangram->new;
  print "is a pangram" if $pan->pangram("a string");

  # alternative alphabet
  # add a" o" u" sz
  my $german = Lingua::Pangram->new(
                 [ 'a' .. 'z', "\xe4", "\xf6", "\xfc", "\xdf" ]
               );
  print "is a German pangram" if
    $german->pangram("eine Zeichenkette");

=head1 DESCRIPTION

This module exports no functions. It has an object-oriented interface
with one method: pangram. This method takes a string and returns 1 if
the string passed in contains all the letters of the alphabet, otherwise
it returns 0.

It is possible to change the notion of what comprises "all the letters
of the alphabet" by passing in an alternative set to the ->new method as
a reference to an array containing all possible (lowercase) letters. The
default set is 'a' .. 'z'.

The pangram method will lowercase the string prior to testing for the
letters. It uses locale for this, so you may get incorrect results if
your locale is not set up correctly.

=head1 AVAILABILITY

It should be available for download from
F<http://russell.matbouli.org/code/lingua-pangram/>
or from CPAN, in the directory authors/id/I/ID/IDORU.

=head1 AUTHOR

Russell Matbouli E<lt>lingua-pangram-spam@russell.matbouli.orgE<gt>

F<http://russell.matbouli.org/>

=head1 CONTRIBUTORS

Thanks to Philip Newton for a patch

=head1 TODO

Perhaps create minpangram which tests whether the string contains exactly 
one of each letter.

=head1 LICENSE

Distributed under GPL v2. See COPYING included with this distibution.

=head1 SEE ALSO

perl(1), L<locale>.

=cut
