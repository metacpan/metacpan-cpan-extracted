package Encode::InCharset;

use 5.007003;
use strict;
use warnings;

our $VERSION = do { my @r = (q$Revision: 0.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
our $DEBUG = 1;

use Encode::InCharset::Config;
use Carp;

sub import{
    my $class = shift;
    my $callpkg = caller;
    my @sub = @_ ? @_ : sort keys %Encode::InCharset::Config::InPM;
    for my $sub (@sub){
	no strict 'refs';
	my $mod = $Encode::InCharset::Config::InPM{$sub} or
	    croak "Unknown property: $sub";
	my $modfile = $mod; $modfile =~ s,::,/,go;
	eval { require "$modfile.pm" };
	$@ and croak $@;
	*{"$callpkg\::$sub"} = \&{"$mod\::$sub"};
    }
}

1;
__END__


=head1 NAME

Encode::InCharset - defines \p{InCharset}

=head1 SYNOPSIS

  use Encode::InCharset qw(InJIS0208);
  "I am \x{5c0f}\x{98fc}\x{3000}\x{5f3e}" =~ /(\p{InJIS0208})+/o;
  # guess what is in $1

=head1 ABSTRACT

This module provides InI<Charset> Unicode property that matches
characters I<Charset>.  

As of this writing, Property-matching functions are auto-generated out
of ucm files in Encode, Encode::HanExtra, and Encode::JIS2K.

=head1 DESCRIPTION

As of this writing, this module supports character properties shown
below.  Since names are self-explanatory I am not going to discuss in
details.

  InASCII InAdobeStandardEncoding InAdobeSymbol InAdobeZdingbat
  InBIG5EXT InBIG5PLUS InBIG5_ETEN InBIG5_HKSCS InCCCII InCP1006
  InCP1026 InCP1047 InCP1250 InCP1251 InCP1252 InCP1253 InCP1254
  InCP1255 InCP1256 InCP1257 InCP1258 InCP37 InCP424 InCP437 InCP500
  InCP737 InCP775 InCP850 InCP852 InCP855 InCP856 InCP857 InCP860
  InCP861 InCP862 InCP863 InCP864 InCP865 InCP866 InCP869 InCP874
  InCP875 InCP932 InCP936 InCP949 InCP950 InDingbats InEUC_CN
  InEUC_JISX0213 InEUC_JP InEUC_KR InEUC_TW InGB12345 InGB18030 InGB2312
  InGSM0338 InHp_Roman8 InISO_8859_1 InISO_8859_10 InISO_8859_11
  InISO_8859_13 InISO_8859_14 InISO_8859_15 InISO_8859_16 InISO_8859_2
  InISO_8859_3 InISO_8859_4 InISO_8859_5 InISO_8859_6 InISO_8859_7
  InISO_8859_8 InISO_8859_9 InISO_IR_165 InJIS0201 InJIS0208 InJIS0212
  InJIS0213_1 InJIS0213_2 InJohab InKOI8_F InKOI8_R InKOI8_U InKSC5601
  InMacArabic InMacCentralEurRoman InMacChineseSimp InMacChineseTrad
  InMacCroatian InMacCyrillic InMacDingbats InMacFarsi InMacGreek
  InMacHebrew InMacIcelandic InMacJapanese InMacKorean InMacRoman
  InMacRomanian InMacRumanian InMacSami InMacSymbol InMacThai
  InMacTurkish InMacUkrainian InNextstep InPOSIX_BC InShift_JIS
  InShift_JISX0213 InSymbol InVISCII

=head2 EXPORT

  # will import all of them
  use Encode::InCharset;
  # will import only properties in qw()
  use Encode::InCharset qw(In<Charset>...) 

=head1 SEE ALSO

L<Encode>, L<perlunicode>

=head1 AUTHOR

Dan Kogai E<lt>dankogai@home.dan.intraE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
