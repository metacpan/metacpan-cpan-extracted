package Encode::Buckwalter;
our $VERSION = "1.1";
 
use Encode;
use XSLoader;
XSLoader::load(__PACKAGE__,$VERSION);

1;
__END__

=head1 NAME
 
Encode::Buckwalter - ASCII-based Transliteration for Arabic
 
=head1 SYNOPSIS

 use Encode;
 use Encode::Buckwalter;

 $ref_utf = "\x{0641}\x{0648}\x{0628}\x{0x631}";
 $ref_bwt = "fwbr";

 $bwt_out = encode( "Buckwalter", $ref_utf );  # eq ref_bwt
 $utf_out = decode( "Buckwalter", $ref_bwt );  # eq ref_utf

=head1 DESCRIPTION

(Most of the following is adapted from comments in the Buckwalter.ucm
file, which is included in the Encode directory in this distribution.)

In the Buckwalter transliteration for Arabic, standard ASCII
alphabetics, brackets and punctuation are used to represent Arabic
characters.  This entails that any text string "encoded" in Buckwalter
cannot contain, e.g. English words or abbreviations.

As a result, when Arabic Unicode text is encoded into Buckwalter, any
Latin alphabetic characters mixed in with the Arabic cannot be
preserved -- they will be converted to a default "replacement
character" (the ASCII question mark), causing a loss of information.
ASCII digits, and punctuation and brackets that are not used to
represent Arabic characters in Buckwalter, will be passed through
without change.

For digits and shared punctuation, conversion is uni-directional: in
Unicode->Buckwalter, the Arabic comma, semicolon, question mark and
Arabic-Indic digits (U+060C, U+061B, U+061F, U+0660 - U+0669) will
always be converted to their ASCII equivalents (U+002C, U+003B,
U+003F, U+0030 - U+0039,), but in Buckwalter->Unicode, these ASCII
characters are never converted to the Arabic-table versions.

Note that the ASCII characters used for one-to-one mapping to Arabic
characters include the following "volatile" code points, which will
generally need to be quoted or escaped (if used in shell commands) or
re-transliterated as "character entity references" (if used in html,
xml, sgml or a url):

  & (&amp;)
  < (&lt;)
  > (&gt;)
  ' (&#39 or &x#27)
  $ (&#36 or &x#24)
  * (&#42 or &x#2a)
  ` (&#96 or &x#60)
  { (&#123 or &x#7b)
  | (&#124 or &x#7c)
  } (&#125 or &x#7d)

=head1 NOTE: Comparison to another "Buckwalter" module on CPAN

The approach taken here (in Encode::Buckwalter) is different from the
one found in Encode::Arabic::Buckwalter, created by Otakar Smrz.
Briefly, the main differences are:

 - Encode::Buckwalter was built from the "ucm" (Unicode Character Map)
   table file mentioned above.  The "enc2xs" utility, also a standard
   part of 5.8.0 and later versions of Perl, was used to create this
   distribution package, which in turn creates a C-compiled library
   extension from the ucm file.  Otakar's module is "pure perl", and
   uses tr/// internally.

 - Encode::Buckwalter relies on the "encode" and "decode" functions as
   defined/exported by the standard "Encode" module, whereas Otakar
   supplies his own "encode" and "decode" functions that extend the
   standard ones.

 - Encode::Buckwalter's ucm file defines one-way transforms for
   certain characters in the Unicode Arabic table, as described above.
   Otakar's module converts ASCII digits, comma, question-mark and
   semi-colon to their Unicode Arabic forms.  Note that if input
   Unicode text contains both ASCII and Arabic versions of these
   characters, a simple round-trip conversion (unicode -> buckwalter
   -> unicode) would be "lossy" no matter which module you use.

 - Encode::Buckwalter does not provide any "filtering" modes as part
   of the conversion process, whereas Otakar's module supports modes
   for doing things like removing certain or all diacritic marks.

=head1 SEE ALSO

L<Encode>

L<Encode::Arabic::Buckwalter>

=head1 AUTHOR

David Graff  <graff@ldc.upenn.edu>

=head1 COPYRIGHT

(c) 2009 University of Pennsylvania

This is free software.  It may be used and redistributed under the
same terms as Perl.

=cut
