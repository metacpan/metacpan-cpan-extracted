##############################################################################
# The Faq-O-Matic is Copyright 1997 by Jon Howell, all rights reserved.      #
#                                                                            #
# This program is free software; you can redistribute it and/or              #
# modify it under the terms of the GNU General Public License                #
# as published by the Free Software Foundation; either version 2             #
# of the License, or (at your option) any later version.                     #
#                                                                            #
# This program is distributed in the hope that it will be useful,            #
# but WITHOUT ANY WARRANTY; without even the implied warranty of             #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
# GNU General Public License for more details.                               #
#                                                                            #
# You should have received a copy of the GNU General Public License          #
# along with this program; if not, write to the Free Software                #
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.#
#                                                                            #
# Jon Howell can be contacted at:                                            #
# 6211 Sudikoff Lab, Dartmouth College                                       #
# Hanover, NH  03755-3510                                                    #
# jonh@cs.dartmouth.edu                                                      #
#                                                                            #
# An electronic copy of the GPL is available at:                             #
# http://www.gnu.org/copyleft/gpl.html                                       #
#                                                                            #
##############################################################################

use strict;
use locale;

### Words.pm
###
### Support for extracting "words" from strings
###
### To change these routines to support other character sets,
### copy this file to a location outside of the FAQ::OMatic tree and
### add the following lines to the start of your cgi-bin/fom file:
###	use lib '/Whatever/your/directory/path/is';
###	require Words;
###	#existing use lib line
###	use FAQ::OMatic::Words
### This will override the definitions in this file.


package FAQ::OMatic::Words;

BEGIN {
#   This code use Japanese environment only.
#   see http://chasen.aist-nara.ac.jp/index.html.en
#
    if (FAQ::OMatic::I18N::language() eq 'ja_JP.EUC') {
        require Text::ChaSen;  import Text::ChaSen;
        &Text::ChaSen::getopt_argv('faq-omatic', '-j', '-F', '%m ');
    }
}

sub cannonical {
    my $string = shift;

    # convert the input string into cannonical form.
    #
    # The default is to strip parenthesis and apostrophies, and
    # convert to ASCII lower case.
    #
    # If you use another character set (e.g. ISO-8859-?), you'll want
    # to override to do correct lower case handling.
    #
    # This routine is called both when the indicies are created and
    # when the search pattern is formed, so things will be done
    # consistantly.

    # convert
    #	timer(s) to timers
    #   timer's to timers
    #   e-mail  to email
    $string =~ s/[()'-]//g;
    $string  = lc($string);		# convert to lower case

    if (FAQ::OMatic::I18N::language() eq 'hu') {
        # Accentuated lc(),
        $string =~ tr/\301\311\315\323\326\325\332\334\333/\341\351\355\363\366\365\372\374\373/;
    }

    $string;
}

sub getWords {
    my $string = shift;
    my $encode_lang = FAQ::OMatic::I18N::language();
#EUC-JP case
    return getWordsEUCJP($string) if($encode_lang eq "ja_JP.EUC");
# Hungarian case
    return getWordshu($string) if($encode_lang eq 'hu');
#normal case
    return getWordsSB($string);
}

sub getWordsSB {
	my $string = shift;

	# given a user-input string, we break it into "legal" words
	# and return an array of them

	$string = cannonical( $string );

	my $wordPattern = '[\w-]';	# alphanumeric + '_' + '-'

	#my @words = ($string =~ m/($wordPattern+)/gso);
	# /gso seems to break in some circumstances. :v(
	my @wordspl = split(/($wordPattern+)/, $string);
	my @words=();
	my $i;
	for ($i=1; $i<@wordspl; $i+=2) {
		push (@words, $wordspl[$i]);
	}
	return @words;

}

sub getWordsEUCJP {
    require Text::ChaSen; import Text::ChaSen;
    require NKF; import NKF;

	my $string = shift;

	# given a user-input string, we break it into "legal" words
	# and return an array of them

	$string = nkf('-e', $string);
	$string = cannonical( $string );

	my $wordPattern = '[\w-]';	# alphanumeric + '_' + '-'

	my $s = &Text::ChaSen::sparse_tostr($string);
	chomp $s;
	my @words = split / /, $s;
	return @words;

}

sub getWordshu {
	my $string = shift;

	# given a user-input string, we break it into "legal" words
	# and return an array of them

	$string = cannonical( $string );

	# pattern for hungarian language:
	my $wordPattern = '[\w\341\351\355\363\366\365\372\374\373-]';	

	#my @words = ($string =~ m/($wordPattern+)/gso);
	# /gso seems to break in some circumstances. :v(
	my @wordspl = split(/($wordPattern+)/, $string);
	my @words=();
	my $i;
	for ($i=1; $i<@wordspl; $i+=2) {
		push (@words, $wordspl[$i]);
	}
	return @words;
}

sub getPrefixes {
    my $word = shift;
    my $encode_lang = FAQ::OMatic::I18N::language();
#EUC-JP case
    return getPrefixesEUCJP($word) if($encode_lang eq "ja_JP.EUC");
#normal case
    return getPrefixesSB($word);
}

sub getPrefixesSB {
    my $word = shift;

    # given a word, return an array of prefixes which should be
    # indexed.
    #
    # default routine returns all substrings
    my @prefix=();
    my $i = length( $word );
    while( $i ) {
        push @prefix, substr( $word, 0, $i-- );
    }

    @prefix;
}

## Japanese EUC-JP multibyte extended getPrefixes by oota ##
sub getPrefixesEUCJP {
    my $word = shift;

    # given a word, return an array of prefixes which should be
    # indexed.
    #
    # default routine returns all substrings
    my @prefix=();
    my $i = 1;
    while( $i <= length( $word )) {	
       if(ord(substr($word,$i-1,1)) >= 128) {
           push @prefix, substr( $word, 0, $i+1 );
           $i += 2;
       } else {
           push @prefix, substr( $word, 0, $i );
           $i += 1;
       }
    }

    reverse @prefix;
}

'true';

