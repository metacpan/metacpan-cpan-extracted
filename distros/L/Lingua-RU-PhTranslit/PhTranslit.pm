package Lingua::RU::PhTranslit;

=head1 NAME

Lingua::RU::PhTranslit -  Phonetic correct translit (for Cyrillic)

=head1 SYNOPSIS

  use Lingua::RU::PhTranslit

=head1 DESCRIPTION

The folowing functions include in this package

  koi2phtr, phtr2koi
  koi2win, win2koi
  koi2alt, alt2koi

 koi - KOI8-R
 win - Windows-1251, CP1251
 alt - CP866

sample script ------------------------------------------

 use Lingua::RU::PhTranslit;

 my $koi_string=" üÔÁ ÓÔÒÏŞËÁ ÎÁĞÉÓÁÎÁ ÒÕÓÓËÉÍÉ ÂÕËÏ×ËÁÍÉ";
 print koi2phtr("$koi_string\n");

script output ------------------------------------------
 E'ta strochka napisana russkimi bukovkami

-------------------------------------------------------

    Main appointment of this package is converting information during
export/import from/to mobile devices. On desktop computers this
problem is not actul now. Transform in this pacage is bidirectional.

P.S. Sorry for my English. It is not a native language for me.

=head1 History

    0.1  ()		- initial release;
    0.2  (2001-10-12) 	- correct "£³" in koi2win;
    0.3  (2003-03-28)	- missing test added;
    0.4  (2003-04-10	- add some documentation,
			  correct mistake with change $_ (thank's Sean M. Burke)

=cut

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw( &koi2phtr &phtr2koi &koi2win &win2koi &koi2alt &alt2koi);
#@EXPORT_OK = qw();
$VERSION = '0.4';

sub koi2phtr
    { local ($_)=@_;

#
# koi8-r to Phonetic correct translit
#

s/óÈ/S\'h/; s/ÓÈ/s\'h/; s/óè/S\'H/;
s/û/Sh/g; s/Û/sh/g;

s/óÃÈ/Sc\'h/; s/ÓÃÈ/sc\'h/; s/óãè/SC\'H/;
s/ı/Sch/g; s/İ/sch/g;

s/ãÈ/C\'h/; s/ÃÈ/c\'h/; s/ãè/C\'H/;
s/ş/Ch/g; s/Ş/ch/g;

s/êÁ/J\'a/; s/ÊÁ/j\'a/; s/êá/J\'A/;
s/ñ/Ja/g; s/Ñ/ja/g;

s/êÏ/J\'o/; s/ÊÏ/j\'o/; s/êï/J\'O/;
s/³/Jo/g; s/£/jo/g;

s/êÕ/J\'u/; s/ÊÕ/j\'u/; s/êõ/J\'U/;
s/à/Ju/g; s/À/ju/g;

s/ü/E\'/g; s/Ü/e\'/g;
s/å/E/g; s/Å/e/g;

s/úÈ/Z\'h/g; s/ÚÈ/z\'h/g; s/úè/Z\'H/g;
s/ö/Zh/g; s/Ö/zh/g;

tr/
ÁÂ×ÇÄÚÉÊËÌÍÎÏĞÒÓÔÕÆÈÃßÙØáâ÷çäúéêëìíîïğòóôõæèãÿùø/
abvgdzijklmnoprstufhc\"y\'ABVGDZIJKLMNOPRSTUFHC\"Y\'/;

return $_;

}

sub phtr2koi
    { local($_)=@_;

#
# Phonetic correct translit to koi8-r
#

s/E\'/ü/g; s/e\'/Ü/g;
s/E/å/g; s/e/Å/g;

s/Jo/³/g; s/jo/£/g;
s/J\'o/êÏ/g; s/j\'o/ÊÏ/g; s/J\'O/êï/g;

s/Sch/ı/g; s/sch/İ/g;
s/Sc\'h/óÃÈ/g; s/sc\'h/ÓÃÈ/g; s/SC\'H/óãè/g;

s/Ch/ş/g; s/ch/Ş/g;
s/C\'h/ãÈ/g; s/c\'h/ÃÈ/g; s/C\'H/ãè/g;

s/Sh/û/g; s/sh/Û/g;
s/S\'h/óÈ/g; s/s\'h/ÓÈ/g; s/S\'H/óè/g;

s/Ja/ñ/g; s/ja/Ñ/g;
s/J\'a/êÁ/g; s/j\'a/ÊÁ/g; s/J\'A/êá/g;

s/Zh/ö/g; s/zh/Ö/g;
s/Z\'h/úÈ/g; s/z\'h/ÚÈ/g; s/Z\'H/úè/g;

s/Ju/à/g; s/ju/À/g;
s/J\'u/êÕ/g; s/j\'u/ÊÕ/g; s/J\'U/êõ/g;


tr/
abvgdzijklmnoprstufhc\"y\'ABVGDZIJKLMNOPRSTUFHC\"Y\'/
ÁÂ×ÇÄÚÉÊËÌÍÎÏĞÒÓÔÕÆÈÃßÙØáâ÷çäúéêëìíîïğòóôõæèãÿùø/;

return $_;

}

#
# Next functions added for Windows users
# Each function translate "\n" to "\n" - this in no bug.

sub koi2win
    { local($_)=@_;

tr/
áâ÷çäå³öúéêëìíîïğòóôõæèãşûıÿùøüàñÁÂ×ÇÄÅ£ÖÚÉÊËÌÍÎÏĞÒÓÔÕÆÈÃŞÛİßÙØÜÀÑ/
ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞßàáâãäå¸æçèéêëìíîïğñòóôõö÷øùúûüışÿ/;
return $_;
    }

sub win2koi
    { local($_)=@_;

tr/
ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞßàáâãäå¸æçèéêëìíîïğñòóôõö÷øùúûüışÿ/
áâ÷çäå³öúéêëìíîïğòóôõæèãşûıÿùøüàñÁÂ×ÇÄÅ£ÖÚÉÊËÌÍÎÏĞÒÓÔÕÆÈÃŞÛİßÙØÜÀÑ/;
return $_;

    }

sub alt2koi
    { local($_)=@_;

tr/
€‚ƒ„…†‡ˆ‰Š‹Œ‘’“”•–—˜™š›œŸ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞßàáâãäåæçèéêëìíîïğñòóôõö÷øùúûüışÿ/
áâ÷çäåöúéêëìíîïğòóôõæèãşûıÿùøüàñÁÂ×ÇÄÅÖÚÉÊËÌÍÎÏĞ€¬®¶†–™‰¦¾©£“ƒ¹±²¸´°µ„”¡§¢¨¤ ¥‚’ˆ˜‘‡—•…³·¿º»¼½ÒÓÔÕÆÈÃŞÛİßÙØÜÀÑŠ‹Œ¯ª­«š›œŸ/;
return $_;

    }

sub koi2alt
    { local($_)=@_;

tr/
áâ÷çäåöúéêëìíîïğòóôõæèãşûıÿùøüàñÁÂ×ÇÄÅÖÚÉÊËÌÍÎÏĞ€¬®¶†–™‰¦¾©£“ƒ¹±²¸´°µ„”¡§¢¨¤ ¥‚’ˆ˜‘‡—•…³·¿º»¼½ÒÓÔÕÆÈÃŞÛİßÙØÜÀÑŠ‹Œ¯ª­«š›œŸ/
€‚ƒ„…†‡ˆ‰Š‹Œ‘’“”•–—˜™š›œŸ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞßàáâãäåæçèéêëìíîïğñòóôõö÷øùúûüışÿ/;
return $_;

    }

1;

__END__

=head1 AUTHOR

CPAN -at- Basov -dot- net <Mikhail V. Basov>

=head1 SEE ALSO

perl(1).

=cut
