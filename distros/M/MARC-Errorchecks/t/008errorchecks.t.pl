#!perl -w

=head1 NAME

008errorchecks.t -- Tests to ensure MARC::Errorchecks::validate008 subroutine works as expected.

=head1 TO DO

=cut

use strict;
use Test::More tests=>74;#73;

BEGIN { use_ok( 'MARC::Errorchecks' ); }
print "MARC::Errorchecks version $MARC::Errorchecks::VERSION\n";

###################################################
	#one material type per field in @bad008s
	my @mattypes = (
		('a')x30,
		('m')x8,
		('e')x11,
		('c')x10,
		('g')x9,
		('p')x3,
	);
	my @bad008s = (
		#too short
		q{050517s2004    ilu           000 0 eng },
		#too long
		q{050517s2004    ilu           000 0 eng dd},
		#bad chars in create date
		q{a50517s2004    ilu           000 0 eng d},
		#bad year
		q{550517s2004    ilu           000 0 eng d},
		#bad month
		q{053517s2004    ilu           000 0 eng d},
		#bad day
		q{050537s2004    ilu           000 0 eng d},
		#invalid date type
		q{050517w2004    ilu           000 0 eng d},

		#date type vs. date1 and date2
		q{050517s20042001ilu           000 0 eng d},
		#date type vs. date1 and date2
		q{050517r2004    ilu           000 0 eng d},
		#date type vs. date1 and date2
		q{050517e200406  ilu           000 0 eng d},
		#date 1 blank
		q{050517s        ilu           000 0 eng d},
		#date 1 bad chars
		q{050517s209a    ilu           000 0 eng d},
		#date 2
		q{050517r2004205ailu           000 0 eng d},

		#date 2
		q{050517r20042058ilu           000 0 eng d},

		#country code
		q{050517s2004    ill           000 0 eng d},

		#language
		q{050517s2004    ilu           000 0 end d},

		#language (no linguistic content)
		q{050517s2004    ilu           000 0     d},

		#modified record
		q{050517s2004    ilu           000 0 engad},

		#cataloging source
		q{050517s2004    ilu           000 0 eng e},
		###############
		# books 18-34 #
		###############
		#illustrations
		q{050517s2004    iluq          000 0 eng d},
		#audience
		q{050517s2004    ilu    h      000 0 eng d},
		#form of item
		q{050517s2004    ilu     e     000 0 eng d},
		
		#contents
		q{050517s2004    ilu      x    000 0 eng d},
		#govt pub
		q{050517s2004    ilu          b000 0 eng d},
		#conference
		q{050517s2004    ilu           a00 0 eng d},
		#festschrift
		q{050517s2004    ilu           0a0 0 eng d},
		#index
		q{050517s2004    ilu           00a 0 eng d},
		#obsolete 32
		q{050517s2004    ilu           00000 eng d},
		#literary form
		q{050517s2004    ilu           000 b eng d},
		#bio
		q{050517s2004    ilu           000 0teng d},
		########################
		# Electronic resources #
		########################
		
		#undefined 18-21
		q{050517s2004    ilua       i        eng d},
		#audience
		q{050517s2004    ilu    h   i        eng d},
		#form of item
		q{050517s2004    ilu     a  i        eng d},
		#undefined 24-25
		q{050517s2004    ilu      a i        eng d},
		#type of file
		q{050517s2004    ilu        k        eng d},
		#undefined 27
		q{050517s2004    ilu        ia       eng d},
		#govt pub
		q{050517s2004    ilu        i 0      eng d},
		#undefined 29-34
		q{050517s2004    ilu        i  0     eng d},

		######################
		# cartographic 18-34 #
		######################

		#relief
		q{050517s2004    iluh      e     0   eng d},
		#projection
		q{050517s2004    ilu    ee e     0   eng d},
		#undefined 24
		q{050517s2004    ilu      ze     0   eng d},
		#type of map
		q{050517s2004    ilu       h     0   eng d},
		#undefined 26-27
		q{050517s2004    ilu       ef    0   eng d},
		#govt pub
		q{050517s2004    ilu       e  r  0   eng d},
		#form of item
		q{050517s2004    ilu       e   e 0   eng d},
		#undefined 30
		q{050517s2004    ilu       e    a0   eng d},
		#index
		q{050517s2004    ilu       e     z   eng d},
		#undefined 32
		q{050517s2004    ilu       e     0z  eng d},
		#special format
		q{050517s2004    ilu       e     0  deng d},
		
		#############################
		# music and sound rec 18-34 #
		#############################

		#form of comp
		q{050517s2004    iluabz              eng d},
		#format of music
		q{050517s2004    iluzzp              eng d},
		#music parts
		q{050517s2004    iluzzza             eng d},
		#audience
		q{050517s2004    iluzzz h            eng d},
		#form of item
		q{050517s2004    iluzzz  e           eng d},
		#accompanying material
		q{050517s2004    iluzzz   abcijr     eng d},
		#lit text sound rec
		q{050517s2004    iluzzz         qs   eng d},
		#undefined 32
		q{050517s2004    iluzzz           s  eng d},
		#transposition
		q{050517s2004    iluzzz            d eng d},
		#undefined 34
		q{050517s2004    iluzzz             aeng d},

		####################
		# visual materials #
		####################

		#running time
		q{050517s2004    ilu0n0            vleng d},
		#undefined 21
		q{050517s2004    ilu010a           vleng d},
		#audience
		q{050517s2004    ilu010 h          vleng d},
		#undefined 23-27
		q{050517s2004    ilu010  abcdg     vleng d},
		#govt pub
		q{050517s2004    ilu010       b    vleng d},
		#form of item
		q{050517s2004    ilu010        e   vleng d},
		#undefined 30-32
		q{050517s2004    ilu010         abcvleng d},
		#type of material
		q{050517s2004    ilu010            eleng d},
		#technique
		q{050517s2004    ilu010            vbeng d},

		###################
		# mixed materials #
		###################

		#undefined 18-22
		q{050517s2004    iluabcde            eng d},
		#form of item
		q{050517s2004    ilu     e           eng d},
		#undefined 24-34
		q{050517s2004    ilu      abcdefghijkeng d},

		

		#bad 008 for check_008 and matchpubdates
		#q{741452s20041   wisb          800 0 end p},
		#q{071452sa004    wisb          800 0 end p},
	);
###################################################

	#get current date in form of yyyymmdd
	my $current_date = MARC::Errorchecks::_get_current_date();
	my $current_year = substr($current_date, 0, 4);
	
	#008 byte checking returned errors will change in future version
	my @expected = (
	
		#begin with basic checks and checks for bytes 0-17
		q{008: Not 40 characters long. Bytes not validated (050517s2004    ilu           000 0 eng ).},
		q{008: Not 40 characters long. Bytes not validated (050517s2004    ilu           000 0 eng dd).},
		q{008: Bytes 0-5, Date entered has bad characters. Record creation date (a50517) has non-numeric characters.},
		qq{008: Bytes 0-5, Date entered has bad characters. Year entered (2055) is after current year ($current_year)	Date entered (550517) may be later than current date ($current_date).},
		qq{008: Bytes 0-5, Date entered has bad characters. Month entered is greater than 12 or is 00.},
		q{008: Bytes 0-5, Date entered has bad characters. Day entered is greater than 31 or is 00.},
		q{008: Byte 6, Date type (w) has bad characters.},
		q{008: Bytes 11-14, Date2 (    ) has bad characters or is blank which is not consistent with this date type (w).},
		q{008: Bytes 11-14, Date2 (2001) should be blank for this date type (s).},
		q{008: Bytes 11-14, Date2 (    ) has bad characters or is blank which is not consistent with this date type (r).},
		###verify MARC docs for 'e' date type
		q{008: Bytes 11-14, Date2 (06  ) has bad characters or is blank which is not consistent with this date type (e).}, ###no error should exist?
		###
		q{008: Bytes 7-10, Date1 has bad characters (    ).},
		q{008: Bytes 7-10, Date1 has bad characters (209a).},
		q{008: Bytes 11-14, Date2 (205a) has bad characters or is blank which is not consistent with this date type (r).},
		q{008: Bytes 15-17, Country of Publication (ill) is not valid.},

		#skip to bytes 35-39

		q{008: Bytes 35-37, Language (end) not valid.},
		q{008: Bytes 35-37, Language (   ) must now be coded 'zxx' for No linguistic content.},
		q{008: Byte 38, Modified record has bad characters (a).},
		q{008: Byte 39, Cataloging source has bad characters (e).},

		#proceed with individual material type checks for bytes 18-34

		#books 18-34
		q{008: Bytes 18-21, Books-Illustrations has bad characters (q   ).},
		q{008: Byte 22, Books-Audience has bad characters (h).},
		q{008: Byte 23, Books-Form of item has bad characters (e).},
		q{008: Bytes 24-27, Books-Contents has bad characters (x   ).},
		q{008: Byte 28, Books-Govt publication has bad characters (b).},
		q{008: Byte 29, Books-Conference publication has bad characters (a).},
		q{008: Byte 30, Books-Festschrift has bad characters (a).},
		q{008: Byte 31, Books-Index has bad characters (a).},
		q{008: Byte 32, Books-Obsoletebyte32 has bad characters (0).},
		q{008: Byte 33, Books-Literary form has bad characters (b).},
		q{008: Byte 34, Books-Biography has bad characters (t).},

		#electronic resources 18-34
		q{008: Bytes 18-21, Electronic Resources-Undef18to21 has bad characters (a   ).},
		q{008: Byte 22, Electronic Resources-Audience has bad characters (h).},
		q{008: Byte 23, Electronic Resources-FormofItem has bad characters (a).},
		q{008: Bytes 24-25, Electronic Resources-Undef24to25 has bad characters (a ).},
		q{008: Byte 26, Electronic Resources-Type of file has bad characters (k).},
		q{008: Byte 27, Electronic Resources-Undef27 has bad characters (a).},
		q{008: Byte 28, Electronic Resources-Govt publication has bad characters (0).},
		q{008: Bytes 29-34, Electronic Resources-Undef29to34 has bad characters (0     ).},

		
		#cartographic 18-34
		q{008: Bytes 18-21, Cartographic-Relief has bad characters (h   ).},
		q{008: Bytes 22-23, Cartographic-Projection has bad characters (ee).},
		q{008: Byte 24, Cartographic-Undef24 has bad characters (z).},
		q{008: Byte 25, Cartographic-Type of map has bad characters (h).},
		q{008: Bytes 26-27, Cartographic-Undef26to27 has bad characters (f ).},
		q{008: Byte 28, Cartographic-Govt publication has bad characters (r).},
		q{008: Byte 29, Cartographic-Form of item has bad characters (e).},
		q{008: Byte 30, Cartographic-Undef30 has bad characters (a).},
		q{008: Byte 31, Cartographic-Index has bad characters (z).},
		q{008: Byte 32, Cartographic-Undef32 has bad characters (z).},
		q{008: Bytes 33-34, Cartographic-Special format characteristics has bad characters ( d).},
		
		#music and sound rec 18-34
		q{008: Bytes 18-19, Music-Form of composition has bad characters (ab).},
		q{008: Byte 20, Music-Format of music has bad characters (p).},
		q{008: Byte 21, Music-Parts has bad characters (a).},
		q{008: Byte 22, Music-Audience has bad characters (h).},
		q{008: Byte 23, Music-Form of item has bad characters (e).},
		q{008: Bytes 24-29, Music-Accompanying material has bad characters (abcijr).},
		q{008: Byte 30-31, Music-Text for sound recordings has bad characters (qs).},
		q{008: Byte 32, Music-Undef32 has bad characters (s).},
		q{008: Byte 33, Music-Transposition and arrangement has bad characters (d).},
		q{008: Byte 34, Music-Undef34 has bad characters (a).},


		#visual materials
		q{008: Bytes 18-20, Visual materials-Runningtime has bad characters (0n0).},
		q{008: Byte 21, Visual materials-Undef21 has bad characters (a).},
		q{008: Byte 22, Visual materials-Audience has bad characters (h).},
		q{008: Bytes 23-27, Visual materials-Undef23to27 has bad characters (abcdg).},
		q{008: Byte 28, Visual materials-Govt publication has bad characters (b).},
		q{008: Byte 29, Visual materials-Form of item has bad characters (e).},
		q{008: Bytes 30-32, Visual materials-Undef30to32 has bad characters (abc).},
		q{008: Byte 33, Visual materials-Type of visual material has bad characters (e).},
		q{008: Byte 34, Visual materials-Technique has bad characters (b).},

		#mixed materials
		q{008: Bytes 18-22, Mixed materials-Undef18to22 has bad characters (abcde).},
		q{008: Byte 23, Mixed materials-Form of item has bad characters (e).},
		q{008: Bytes 24-34, Mixed materials-Undef24to34 has bad characters (abcdefghijk).},
		

#add more expected messages here
#		q{},

	);

	#for current purposes, treat all 008s as from monographs
	my $biblvl = 'm';

###make sure mattype count matches number of bad008s to check
is (scalar @mattypes, scalar @bad008s, 'Correct number of material types and 008s.');
###
	foreach my $field008 (@bad008s) {
		my $mattype = shift @mattypes;
		my @errorstoreturn = ();
		push @errorstoreturn, (@{MARC::Errorchecks::validate008($field008, $mattype, $biblvl)});

		while ( @errorstoreturn ) {
			my $expected = shift @expected;
			my $actual = shift @errorstoreturn;

			is( $actual, $expected, "Checking expected messages: $expected" );
		}
	} #foreach bad 008
	is( scalar @expected, 0, "All expected messages exhausted." );


#####


