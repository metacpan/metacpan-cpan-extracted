#!perl -w
use lib "./t";
use strict;
use ExtUtils::TBone;
use Lingua::DetectCyrillic qw ( &toLowerCyr &toUpperCyr &TranslateCyr %RusCharset );
my $T = typical ExtUtils::TBone;
$T->begin(9);
$T->msg(" CONVERSION TEST\n");
my ($String, $InCoding, $OutCoding, @OutCodings, $s);
$String="Это тест кириллицы";
$InCoding = "win";
@OutCodings = ( "win1251", "koi8r", "koi8u", "cp866", "utf", "iso", "mac" );

 $T->ok(toLowerCyr($String, $InCoding), "Translating to Lower case");
 $T->ok(toUpperCyr($String, $InCoding), "Translating to Upper case");

for ( @OutCodings ) {
#$s=TranslateCyr($InCoding,$_,$String);
#print "****** $InCoding  $_ $String $s\n";
  $T->ok(TranslateCyr($InCoding,$_,$String), "Converting to $_" );
}
$T->end;

