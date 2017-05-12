# $File: //member/autrijus/Lingua-ZH-HanDetect/HanDetect.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 6772 $ $DateTime: 2003/06/27 04:42:27 $

package Lingua::ZH::HanDetect;
$Lingua::ZH::HanDetect::VERSION = '0.04';

use bytes;
use strict;
use vars qw($VERSION @ISA @EXPORT $columns $overflow);

use Exporter;

=head1 NAME

Lingua::ZH::HanDetect - Guess Chinese text's variant and encoding

=head1 VERSION

This document describes version 0.04 of Lingua::ZH::HanDetect, released
June 27, 2003.

=head1 SYNOPSIS

    use Lingua::ZH::HanDetect;

    # $encoding is 'big5-hkscs', 'big5', 'gbk', 'euc-cn', 'utf8' or ''
    # $variant  is 'traditional', 'simplified' or ''
    my ($encoding, $variant) = han_detect($some_chinese_text);

=head1 DESCRIPTION

B<Lingua::ZH::HanDetect> uses statistical measures to test a text
string to see if it's in Traditional or Simplified Chinese, as well
as which encoding it is in.

If the string does not contain Chinese characters, both the encoding
and variant values will be set to the empty string.

This module is needed because the various encodings for Chinese text
tend to occupy the similar byte ranges, rendering C<Encode::Guess>
ineffective.

=cut

@ISA      = qw(Exporter);
@EXPORT   = qw(han_detect);
my (%rev, %map);

sub han_detect {
    my $text = shift;
    my %count;

    while (my ($k, $v) = each %rev) {
	next unless index($text, $k) > -1;
	$count{$_}++ for keys %$v;
    }

    my $trad = delete($count{trad}) || 0;
    my $simp = delete($count{simp}) || 0;
    my $encoding = (sort { $count{$b} <=> $count{$a} } keys %count)[0] || '';

    return $encoding unless wantarray;
    return($encoding, ($encoding ? (($trad < $simp) ? 'simplified' : 'traditional') : ''));
}

1;

# data section -- no user-servicable parts inside. {{{
%map = (
    big5_trad	=> [qw(
ª© ±q ¾Ç °ª ¬ì ªk ªí ³£ ´Á ¦h °ê ¹q ¶m ¦p ¤w ¤º ¥| Ãş »¡ ¦¹ ªL ¦Ü ¤å Åı ¯à 
°¢ ¶¡ ·~ ¿ı ¥D ³¯ À³ ¨Ã ¦a ¤¸ ¸ô ¥Î ´N ¦ı ¤G ¨ì ¨ä ³o «á ¥Ñ µ¥ ¨Ó ¥L ¤T ¥i 
¥» ¦W ­n ­¶ ¤p ªÌ ¯¸ ¤ë ©ó ¤é °Ï ½Ğ ·| ±N ³Ç ¤£ ®É ¤] ¸¹ ¶© §A ¹ï ¦Ó ¤j ·s 
©Ò ©M ±z ¤U ¦~ ²Ä ¤H «e ©Î ¤F ¥H ¬° ¤¤ ¦³ §Ú ¤W ¤@ ¬O ºô ¦^ »P ¦b ¤Î ¤§ ªº 
)],
    gbk_simp	=> [qw(
°æ ´Ó Ñ§ ¸ß ¿Æ ·¨ ±í ¶¼ ÆÚ ¶à ¹ú µç Ïç Èç ÒÑ ÄÚ ËÄ Àà Ëµ ´Ë ÁÖ ÖÁ ÎÄ ÈÃ ÄÜ 
ÉÂ ¼ä Òµ Â¼ Ö÷ ³Â Ó¦ ²¢ µØ Ôª Â· ÓÃ ¾Í µ« ¶ş µ½ Æä Õâ áá ÓÉ µÈ À´ Ëû Èı ¿É 
±¾ Ãû Òª Ò³ Ğ¡ Õß Õ¾ ÔÂ ì¶ ÈÕ Çø Çë »á ½« ½Ü ²» Ê± Ò² ºÅ Â¡ Äã ¶Ô ¶ø ´ó ĞÂ 
Ëù ºÍ Äú ÏÂ Äê µÚ ÈË Ç° »ò ÁË ÒÔ Îª ÖĞ ÓĞ ÎÒ ÉÏ Ò» ÊÇ Íø »Ø Óë ÔÚ ¼° Ö® µÄ 
)],
    gbk_trad	=> [qw(
°æ Ä ŒW ¸ß ¿Æ ·¨ ±í ¶¼ ÆÚ ¶à ‡ø ëŠ àl Èç ÒÑ ƒÈ ËÄ î Õf ´Ë ÁÖ ÖÁ ÎÄ ×Œ ÄÜ 
ê„ ég ˜I ä› Ö÷ ê ‘ª K µØ Ôª Â· ÓÃ ¾Í µ« ¶ş µ½ Æä ß@ áá ÓÉ µÈ í Ëû Èı ¿É 
±¾ Ãû Òª í“ Ğ¡ Õß Õ¾ ÔÂ ì¶ ÈÕ …^ Õˆ •ş Œ¢ ‚Ü ²» •r Ò² Ì– Â¡ Äã Œ¦ ¶ø ´ó ĞÂ 
Ëù ºÍ Äú ÏÂ Äê µÚ ÈË Ç° »ò ÁË ÒÔ é ÖĞ ÓĞ ÎÒ ÉÏ Ò» ÊÇ ¾W »Ø Åc ÔÚ ¼° Ö® µÄ 
)],
    utf8_trad	=> [qw(
ç‰ˆ å¾ å­¸ é«˜ ç§‘ æ³• è¡¨ éƒ½ æœŸ å¤š åœ‹ é›» é„‰ å¦‚ å·² å…§ å›› é¡ èªª æ­¤ æ— è‡³ æ–‡ è®“ èƒ½ 
é™ é–“ æ¥­ éŒ„ ä¸» é™³ æ‡‰ ä¸¦ åœ° å…ƒ è·¯ ç”¨ å°± ä½† äºŒ åˆ° å…¶ é€™ å¾Œ ç”± ç­‰ ä¾† ä»– ä¸‰ å¯ 
æœ¬ å è¦ é  å° è€… ç«™ æœˆ æ–¼ æ—¥ å€ è«‹ æœƒ å°‡ å‚‘ ä¸ æ™‚ ä¹Ÿ è™Ÿ éš† ä½  å° è€Œ å¤§ æ–° 
æ‰€ å’Œ æ‚¨ ä¸‹ å¹´ ç¬¬ äºº å‰ æˆ– äº† ä»¥ ç‚º ä¸­ æœ‰ æˆ‘ ä¸Š ä¸€ æ˜¯ ç¶² å› èˆ‡ åœ¨ åŠ ä¹‹ çš„ 
)],
    utf8_simp	=> [qw(
ç‰ˆ ä» å­¦ é«˜ ç§‘ æ³• è¡¨ éƒ½ æœŸ å¤š å›½ ç”µ ä¹¡ å¦‚ å·² å†… å›› ç±» è¯´ æ­¤ æ— è‡³ æ–‡ è®© èƒ½ 
é™• é—´ ä¸š å½• ä¸» é™ˆ åº” å¹¶ åœ° å…ƒ è·¯ ç”¨ å°± ä½† äºŒ åˆ° å…¶ è¿™ å¾Œ ç”± ç­‰ æ¥ ä»– ä¸‰ å¯ 
æœ¬ å è¦ é¡µ å° è€… ç«™ æœˆ æ–¼ æ—¥ åŒº è¯· ä¼š å°† æ° ä¸ æ—¶ ä¹Ÿ å· éš† ä½  å¯¹ è€Œ å¤§ æ–° 
æ‰€ å’Œ æ‚¨ ä¸‹ å¹´ ç¬¬ äºº å‰ æˆ– äº† ä»¥ ä¸º ä¸­ æœ‰ æˆ‘ ä¸Š ä¸€ æ˜¯ ç½‘ å› ä¸ åœ¨ åŠ ä¹‹ çš„ 
)],

);

while (my ($k, $v) = each %map) {
    my @k = split(/_/, $k);
    foreach my $c (@{$v}) {
	$rev{$c}{$_} = 1 for @k;
    }
}

# }}}

=head1 SEE ALSO

L<Encode::HanDetect>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
