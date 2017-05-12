package Lingua::AR::Word;

use strict;
use utf8;


sub encode{

	my $word=shift;

	# let's take away the FIRST hamza ON/UNDER the alef from the word
	$word=~s/\x{0623}//; #HAMZA ON ALEF
	$word=~s/\x{0625}//; #HAMZA UNDER ALEF

	# let's take away the double-letters (=letter+shadda)
	$word=~s/\x{0628}\x{0651}/bb/g;
	$word=~s/\x{062A}\x{0651}/tt/g;
	$word=~s/\x{062B}\x{0651}/_t_t/g;
	$word=~s/\x{062C}\x{0651}/^g^g/g;
	$word=~s/\x{062D}\x{0651}/.h.h/g;
	$word=~s/\x{062E}\x{0651}/_h_h/g;
	$word=~s/\x{062F}\x{0651}/dd/g;
	$word=~s/\x{0630}\x{0651}/_d_d/g;
	$word=~s/\x{0632}\x{0651}/zz/g;
	$word=~s/\x{0633}\x{0651}/ss/g;
	$word=~s/\x{0634}\x{0651}/^s^s/g;
	$word=~s/\x{0635}\x{0651}/.s.s/g;
	$word=~s/\x{0636}\x{0651}/.d.d/g;
	$word=~s/\x{0637}\x{0651}/.t.t/g;
	$word=~s/\x{0638}\x{0651}/.z.z/g;
	$word=~s/\x{0639}\x{0651}/``/g;
	$word=~s/\x{063A}\x{0651}/.g.g/g;
	$word=~s/\x{0641}\x{0651}/ff/g;
	$word=~s/\x{0642}\x{0651}/qq/g;
	$word=~s/\x{0643}\x{0651}/kk/g;
	$word=~s/\x{0644}\x{0651}/ll/g;
	$word=~s/\x{0645}\x{0651}/mm/g;
	$word=~s/\x{0646}\x{0651}/nn/g;
	$word=~s/\x{0647}\x{0651}/hh/g;
	$word=~s/\x{0648}\x{0651}/ww/g;
	$word=~s/\x{064A}\x{0651}/yy/g;
	$word=~s/\x{0631}\x{0651}/rr/g;

    # now let's think of single letters
	$word=~s/\x{0627}/A/g; #ALEF;
	$word=~s/\x{062A}/t/g; #TEH;
	$word=~s/\x{0643}/k/g; #KAF
	$word=~s/\x{0628}/b/g; #BEH
	$word=~s/\x{0642}/q/g; #QAF
	$word=~s/\x{062E}/_h/g; #KHAH
	$word=~s/\x{0629}/T/g; #TEH MARBUTA
	$word=~s/\x{0631}/r/g; #REH
	$word=~s/\x{062C}/^g/g; #JEEM
	$word=~s/\x{0634}/^s/g; #SHEEN
	$word=~s/\x{0633}/s/g; #SEEN
	$word=~s/\x{0635}/.s/g; #SAD
	$word=~s/\x{062F}/d/g; #DAL
	$word=~s/\x{0630}/_d/g; #THAL
	$word=~s/\x{062B}/_t/g; #THEH
	$word=~s/\x{062D}/.h/g; #HAH
	$word=~s/\x{0636}/.d/g; #DAD
	$word=~s/\x{0641}/f/g; #FEH
	$word=~s/\x{0632}/z/g; #ZAIN
	$word=~s/\x{0637}/.t/g; #TAH
	$word=~s/\x{0638}/.z/g; #ZAH
	$word=~s/\x{063A}/.g/g; #GHAIN
	$word=~s/\x{0644}/l/g; #LAM
	$word=~s/\x{0645}/m/g; #MEEM
	$word=~s/\x{0646}/n/g; #NOON
	$word=~s/\x{0647}/h/g; #HEH
	$word=~s/\x{0648}/w/g; #WAW
	$word=~s/\x{0649}/_A/g; #ALEF MAKSURA
	$word=~s/\x{067E}/p/g; #PEH
	$word=~s/\x{06A4}/v/g; #VEH
	$word=~s/\x{06AF}/g/g; #GAF
	#$word=~s/\x{0681}/c/g; #HAMZA ON HAH
	$word=~s/\x{0686}/^c/g; #HAH WITH MIDDLE 3 DOTS DOWNWARD
	#$word=~s/\x{0695}/.r/g; #REH WITH SMALL V BELOW
	$word=~s/\x{064B}/aN/g; #FATHATAN
	$word=~s/\x{064C}/uN/g; #DAMMATAN
	$word=~s/\x{064D}/iN/g; #KASRATAN
	$word=~s/\x{064E}/a/g; #FATHA
	$word=~s/\x{064F}/u/g; #DAMMA
	$word=~s/\x{0650}/i/g; #KASRA
	$word=~s/\x{0670}/_a/g; #LETTER SUPERSCRIPT ALEF = DAGGER ALIF
	#$word=~s/\x{0657}/_u/g; #INVERTED DAMMA
	#$word=~s/\x{0656}/_i/g; #SUBSCRIPT ALEF
	$word=~s/\x{060C}/,/g; #COMMA
	$word=~s/\x{061B}/;/g; #SEMICOLON
	$word=~s/\x{061F}/?/g; #QUESTION MARK
	#$word=~s/\x{0695}/'A/g; #REH WITH SMALL V BELOW
	$word=~s/\x{0621}/'/g; #HAMZA
	$word=~s/\x{0622}/'A/g; #MADDA ON ALEF	
	$word=~s/\x{0623}/'/g; #HAMZA ON ALEF
	$word=~s/\x{0624}/'/g; #HAMZA ON WAW
	$word=~s/\x{0625}/'/g; #HAMZA UNDER ALEF
	$word=~s/\x{0626}/'/g; #HAMZA ON YEH
	$word=~s/\x{0639}/`/g; #AIN
	$word=~s/\x{0640}/--/g; #TATWEEL
	$word=~s/\x{064A}/y/g; #YEH
	$word=~s/\x{0652}//g; #SUKUN
	$word=~s/\x{0671}/A/g; #ALIF WASLA
	#$word=~s/\x{0685}/,c/g; #HAH WITH 3 DOTS ABOVE
	$word=~s/\x{0698}/^z/g; #REH WITH 3 DOTS ABOVE = JEH
	#$word=~s/\x{06AD}/^n/g; #KAF WITH 3 DOTS ABOVE = NG
	#$word=~s/\x{06B5}/^l/g; #LAM WITH SMALL V
return $word;
}

1;
__END__

=head1 NAME

Lingua::AR::Word::Encode - Perl extension to encode Arabic words into ArabTeX

=head1 SYNOPSIS

	use Lingua::AR::Word::Encode;

	$arabtex_form=Lingua::AR::Word::encode("ARABIC_WORD_IN_UTF8");

=head1 DESCRIPTION

This module will take care of encoding an Arabic word into ArabTeX, so that Arabic letters will be converted into English alphabet ones. This way we can interoperate with the ASCII-shell without requiring special Unicode-representation modules.


=head1 SEE ALSO

You may find more info about ArabTeX encoding at ftp://ftp.informatik.uni-stuttgart.de/pub/arabtex/arabtex.htm



=head1 AUTHOR

Andrea Benazzo, E<lt>andy@slacky.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Andrea Benazzo. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.


=cut
