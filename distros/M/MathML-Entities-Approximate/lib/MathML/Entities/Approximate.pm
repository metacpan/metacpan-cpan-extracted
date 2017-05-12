# MathML::Entitities::Approximate
#
# Copyright, Ian Stuart 2005.
# Extends MathML::Entitities (c) Jacques Distler
# All Rights Reserved.
# Licensed under the Perl Artistic License.
#
# Version: 0.20

package MathML::Entities::Approximate;

use strict;
use MathML::Entities qw(name2numbered name2utf8 );
require Exporter;

our @ISA = qw(Exporter MathML::Entities);
our @EXPORT = qw( name2approximated name2numbered name2utf8 );
our $VERSION = '0.20';

our %APPROXIMATES = (
	'AElig'		=>	'A',
	'Aacute'	=>	'A',
	'Abreve'	=>	'A',
	'Acirc'		=>	'A',
	'Agrave'	=>	'A',
	'Amacr'		=>	'A',
	'Aogon'		=>	'A',
	'Aring'		=>	'A',
	'Atilde'	=>	'A',
	'Auml'		=>	'A',
	'Cacute'	=>	'C',
	'Ccaron'	=>	'C',
	'Ccedil'	=>	'C',
	'Ccirc'		=>	'C',
	'Cdot'		=>	'C',
	'Dcaron'	=>	'D',
	'Dstrok'	=>	'D',
	'Dstroke'	=>	'D',
	'Eacute'	=>	'E',
	'Ecaron'	=>	'E',
	'Ecirc'		=>	'E',
	'Edot'		=>	'E',
	'Egrave'	=>	'E',
	'Emacr'		=>	'E',
	'Eogon'		=>	'E',
	'Euml'		=>	'E',
	'Gbreve'	=>	'G',
	'Gcedil'	=>	'G',
	'Gcirc'		=>	'G',
	'Gdot'		=>	'G',
	'Hcirc'		=>	'H',
	'Hstrok'	=>	'H',
	'IJlig'		=>	'IJ',
	'Iacute'	=>	'I',
	'Icirc'		=>	'I',
	'Idot'		=>	'I',
	'Igrave'	=>	'I',
	'Imacr'		=>	'I',
	'Iogon'		=>	'I',
	'Itilde'	=>	'I',
	'Iuml'		=>	'I',
	'Jcirc'		=>	'J',
	'Kcedil'	=>	'K',
	'Lacute'	=>	'L',
	'Lcaron'	=>	'L',
	'Lcedil'	=>	'L',
	'Lmidot'	=>	'L',
	'Lstrok'	=>	'L',
	'Lstroke'	=>	'L',
	'ENG'           =>      'N',
	'Nacute'	=>	'N',
	'Ncaron'	=>	'N',
	'Ncedil'	=>	'N',
	'Ntilde'	=>	'N',
	'OElig'		=>	'OE',
	'Oacute'	=>	'O',
	'Ocirc'		=>	'O',
	'Odblac'	=>	'O',
	'Ograve'	=>	'O',
	'Omacr'		=>	'O',
	'Oslash'	=>	'O',
	'Otilde'	=>	'O',
	'Ouml'		=>	'O',
	'Racute'	=>	'R',
	'Rcaron'	=>	'R',
	'Rcedil'	=>	'R',
	'Sacute'	=>	'S',
	'Scaron'	=>	'S',
	'Scedil'	=>	'S',
	'Scirc'		=>	'S',
	'Tcaron'	=>	'T',
	'Tcedil'	=>	'T',
	'Tstrok'	=>	'T',
	'Uacute'	=>	'U',
	'Ubreve'	=>	'U',
	'Ucirc'		=>	'U',
	'Udblac'	=>	'U',
	'Ugrave'	=>	'U',
	'Umacr'		=>	'U',
	'Uogon'		=>	'U',
	'Uring'		=>	'U',
	'Utilde'	=>	'U',
	'Uuml'		=>	'U',
	'Wcirc'		=>	'W',
	'Yacute'	=>	'Y',
	'Ycirc'		=>	'Y',
	'Yuml'		=>	'Y',
	'Zacute'	=>	'Z',
	'Zcaron'	=>	'Z',
	'Zdot'		=>	'Z',
	'aacute'	=>	'a',
	'abreve'	=>	'a',
	'acirc'		=>	'a',
	'aelig'		=>	'a',
	'agrave'	=>	'a',
	'amacr'		=>	'a',
	'Dstroke'	=>	'D',
	'Lstroke'	=>	'L',
	'cedilla'	=>	'c',
	'lstroke'	=>	'l',
	'aogon'		=>	'a',
	'aring'		=>	'a',
	'atilde'	=>	'a',
	'auml'		=>	'a',
	'cacute'	=>	'c',
	'ccaron'	=>	'c',
	'ccedil'	=>	'c',
	'ccirc'		=>	'c',
	'cdot'		=>	'c',
	'dcaron'	=>	'd',
	'dotlessi'	=>	'i',
	'dstrok'	=>	'd',
	'eacute'	=>	'e',
	'ecaron'	=>	'e',
	'ecirc'		=>	'e',
	'edot'		=>	'e',
	'egrave'	=>	'e',
	'emacr'		=>	'e',
	'eogon'		=>	'e',
	'euml'		=>	'e',
	'fnof'		=>	'f',
	'gacute'	=>	'g',
	'gbreve'	=>	'g',
	'gcirc'		=>	'g',
	'gdot'		=>	'g',
	'hcirc'		=>	'h',
	'hstrok'	=>	'h',
	'iacute'	=>	'i',
	'icirc'		=>	'i',
	'igrave'	=>	'i',
	'ijlig'		=>	'ij',
	'imacr'		=>	'i',
	'inodot'	=>	'i',
	'iogon'		=>	'i',
	'itilde'	=>	'i',
	'iuml'		=>	'i',
	'jcirc'		=>	'j',
	'kcedil'	=>	'k',
	'kgreen'	=>	'k',
	'lacute'	=>	'l',
	'lcaron'	=>	'l',
	'lcedil'	=>	'l',
	'lmidot'	=>	'l',
	'lstrok'	=>	'l',
	'lstroke'	=>	'l',
	'eng'           =>      'n',
	'nacute'	=>	'n',
	'napos'		=>	'n',
	'ncaron'	=>	'n',
	'ncedil'	=>	'n',
	'ntilde'	=>	'n',
	'oacute'	=>	'o',
	'ocirc'		=>	'o',
	'odblac'	=>	'o',
	'oelig'		=>	'oe',
	'ograve'	=>	'o',
	'omacr'		=>	'o',
	'oslash'	=>	'o',
	'otilde'	=>	'o',
	'ouml'		=>	'o',
	'racute'	=>	'r',
	'rcaron'	=>	'r',
	'rcedil'	=>	'r',
	'sacute'	=>	's',
	'scaron'	=>	's',
	'scedil'	=>	's',
	'scirc'		=>	's',
	'sup1'		=>	'1',
	'szlig'		=>	's',
	'tcaron'	=>	't',
	'tcedil'	=>	't',
	'tstrok'	=>	't',
	'uacute'	=>	'u',
	'ubreve'	=>	'u',
	'ucirc'		=>	'u',
	'udblac'	=>	'u',
	'ugrave'	=>	'u',
	'umacr'		=>	'u',
	'uogon'		=>	'u',
	'uring'		=>	'u',
	'utilde'	=>	'u',
	'uuml'		=>	'u',
	'wcirc'		=>	'w',
	'yacute'	=>	'y',
	'ycirc'		=>	'y',
	'yuml'		=>	'y',
	'zacute'	=>	'z',
	'zcaron'	=>	'z',
	'zdot'		=>	'z'
);

sub name2approximated {
    my $content = shift;

    # We have to call the subroutine so we can do the "exist" test.
    # If we don't do the exist test, then we get loads of 
    #   'Use of uninitialized value in substitution iterator' errors
    $content =~ s/(&([a-zA-Z0-9]+);)/$2 ? _convert2approximated($1) : ""/eg;
    
    return $content;

}

sub getSet {
  # get, or set-and-get, a key-value pair from the lookup table
  my ($key, $value) = @_;

  if ($key) {
    $APPROXIMATES{$key} = $value if $value;
    return $APPROXIMATES{$key};
  };
  return undef;
}

sub _convert2approximated {
   # this is the actual lookup routine
   my $reference = shift;
   $reference =~ /^&([a-zA-Z0-9]+);$/;
   my $name = $1;
   return (exists $MathML::Entities::ENTITIES{$name} &&
           exists $APPROXIMATES{$name} ) ?
	 $APPROXIMATES{$name} : "" ;

}
1;
__END__

=pod

=head1 NAME

  MathML::Entities::Approximate - Returns approximated ASCII characters for XHTML+MathML Named Entities

=head1 SYNOPSIS

A subclass of MathML::Entities that supplies ASCII-approximate characters for XHTML+MathML Named Entities.

  use lib (getpwnam('sdadmin'))[7] . '/perlib';
  use MathML::Entities::Approximate;

  $html    = '<strong>avanc&eacute;e</strong>';

  # convert to HTML character reference. Standard MathML::Entities
  $numeric = name2numbered($html)    # <strong>avanc&#x000E9;e</strong>

  # convert to standard ASCII
  $ascii   = name2approximated($html) # <strong>avancee</strong>

  # Muck around with the lookup table...
  MathML::Entities::Approximate::getSet(aacute);    # returns 'a'
  MathML::Entities::Approximate::getSet(aacute, z); # returns 'z'
  MathML::Entities::Approximate::getSet(aacute);    # now returns 'z'

=head1 DESCRIPTION

MathML::Entities::Approximate is a content conversion filter for named
XHTML+MathML entities. There are over two thousand named entities in the
XHTML+MathML DTD, however only a fraction of them are variants on standard 
ASCII characters.

A string is parsed and every Named Entity is converted to a reasonable ASCII (7-bit ASCII set), or removed from the string.

=head1 FUNCTIONS

There two functions, one of which is exported by default.

=over 4

=item * name2approximated

(Exported by default)

XHTML+MathML named entities in the argument of C<name2approximated()> are replaced by the corresponding 7-bit ASCII character. Any entitiy which cannot be approximated is removed.

=item * getSet

(Never Exported)

This method is provided to allow users to extend the internal C<%APPROXIMATES> lookup table: either alter an existing entry [for the life of the process] or add new entities.

Of course, for a large update to the lookup table, you have the option of:

  %MathML::Entities::Approximate:APPROXIMATES = (
    %MathML::Entities::Approximate:APPROXIMATES,
    'foobar' => 'fb',         # LOWERCASE WELL SCUNNERED
    'FooBar' => 'FB',         # UPPERCASE WELL SCUNNERED
    'landrover' => 'landie',  # LOWERCASE PROPER MOTOR
    'LandRover' => 'Landie'   # UPPERCASE PROPER MOTOR
  );


=back

=head1 AUTHOR

Ian Stuart E<lt>Ian.Stuart@ed.ac.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ian Stuart. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<MathML::Entities>,
L<HTML::Entities>,
L<HTML::Entities::Numbered>,
L<http://www.w3.org/TR/REC-html40/sgml/entities.html>,
L<http://www.w3.org/Math/characters/>

=cut
