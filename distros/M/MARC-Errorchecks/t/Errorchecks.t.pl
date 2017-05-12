#!perl -w

=head1 NAME

Errorchecks.t -- Tests to ensure MARC::Errorchecks subroutines work as expected.
Currently, performs semi-random testing of some of the subroutines in MARC::Errorchecks.

=head1 TO DO

Devise checks for each subroutine individually.

=cut

use strict;
use Test::More tests=>45;

BEGIN { use_ok( 'MARC::File::USMARC' ); }
BEGIN { use_ok( 'MARC::Errorchecks' ); }

=head2 UNIMPLEMENTED

#may add this section later

FROM_FILE: {
	my @expected = ( (undef) x $countofundefs, [ q{$tag: $error} ] );

	my $filename = "t/errorchecks.usmarc";

	my $file = MARC::File::USMARC->in( $filename );
	while ( my $marc = $file->next() ) {
		isa_ok( $marc, 'MARC::Record' );
		my $title = $marc->title;

	my $expected = shift @expected;
	my @warnings = ();
	push @warnings, (@{MARC::Errorchecks::check_all_subs($record)});

	if ( $expected ) {
		ok( eq_array( \@warnings, $expected ), "Warnings match on $title" );
		} 
	else {
		is( scalar @warnings, 0, "No warnings on $title" );
		}
	} # while

	is( scalar @expected, 0, "All expected messages have been exhausted." );
}

=cut #from file

FROM_TEXT: {
	my $marc = MARC::Record->new();
	isa_ok( $marc, 'MARC::Record', 'MARC record' );

	$marc->leader("00000nam  2200253 a 4500"); 
	my $nfields = $marc->add_fields(
		#control number so one is present
		['001', "ttt04000001"
		],
		#bad 008 for check_008 and matchpubdates
		['008', "741452s20041   wisb          800 0 end p"
		],
		#lccn with extra space at end (and greater than current year) and an extra space at beginning
		['010', "", "",
			a => '   2050001001 ',
		],
		['020', "","",
			a => "154879474",
		],
		#Empty 040a will report space at start of field, trailing space
		['040', "","",
			a => " ",
		],
		#041 code not matching 008 lang code, invalid lang. code
		['041', "0","",
			a => "spa",
			a => "engs",
		],
		#Pub date non-match
		['050', "","",
			a => "TX714",
			b => "B23 2003",
		],
		#240 with no 1xx
		[240, "1","0",
			a => 'Tests',
		],
		#test elipses, trailing spaces, multiple internal spaces in 245, 1st ind. '1' with no 1xx
		[245, "1","0",
			a => "Test  record from text / ",
			b => "other title info :",
			c => "Bryan Baldus ... [et al.]. ",
		],
		#test ending punctuation in 246
		[246, "3", "",
			a => "Test 246 with ending period.",
		],
		#test exceptions to 246 ending punctuation
		[246, "3", "",
			a => "Test 246 with ending abbreviation, Ph.D.",
		], #no error
		[246, "3", "",
			a => "Test 246 with ending abbreviation, U.S.A.",
		], #no error
		[246, "3", "",
			a => "Test 246 with ending abbreviation, A.",
		], #no error
		#test multiple periods in 250
		[250, "", "",
			a => "3rd edition..",
		],
		[260, "", "",
			a => "Oregon, Illinois ; ",
			b => "B. Baldus, ",
			c => "2000",
		],
		#ending punctuation in 300
		[300, "","",
			a => "39 p",
			b => "ill. (some col), map. ;",
			c => "39 c",
		],
		#490 with 1st ind. '1' but no 830, 4xx vs. 300 punctuation
		[490, "1","",
			a => "Records series",
		],
		#Includes index in 504 instead of 500, ending punctuation
		[504, "","",
			a => "Includes index",
		],
		[504, "","",
			a => "Includes bibliographical references (44).",
		],
		[504, "","",
			a => "Includes bibliographical references(p. 44) and index.",
		],
		#floating hyphens, ending punctuation
		[505, "0","",
			a => "Test 1 --  Test 2 - Test 3 -- Test 4-- testing --  Test 5",
		],
		[500, "", "",
			a => "This has a floating period .",
		],
		[500, "", "",
			a => "This has a floating comma , that should not be there.",
		],
		[500, "", "",
			a => "Why does this field have a floating question mark ?",
		],
		[500, "", "",
			a => "This has an emdash (elipsis replacement) with floating period-- ."
		], #no error
		[500, "", "",
			a => "This has an emdash-- (elipsis replacement) with floating period ."
		],
		[500, "", "",
			a => "This has a regular emdash and floating period -- ."
		],
		[500, "", "",
			a => "This has an emdash-- . Then another sentence."
		], #no error
		[500, "", "",
			a => "This has an emdash-- . Then a floating period ."
		], 
		[500, "", "",
			a => "This lengthy sentence has . multiple floating . punctuation . strewn throughout its midst , to test the reporting abilities ? of the error checking module."
		], 
		#5xx with question mark-period
		[500, "", "",
			a => "This ends with question mark-period?."
		], 
		#505 with continuing emdash
		[505, "0", "",
			a => "This ends with emdash --"
		], 
		#505 with exclamation point-period
		[505, "8", "",
			a => "This ends with exclamation point period!."
		], 
		[650, "", "0",
			a => "MARC formats",
		],
	);
	is( $nfields, 34, "All the fields added OK" );

	my @expected = (
		q{040: Subfield starts with a space.},
		q{245: has multiple internal spaces (Test  record fro).},
		q{505: has multiple internal spaces (Test 1 --  Test 2 - T_testing --  Test 5).},
		q{040: has trailing spaces.},
		q{245: has trailing spaces.},
		q{250: has multiple consecutive periods that do not appear to be ellipses.},
		#008 byte checking returned errors will change in future version
		q{008: Bytes 0-5, Date entered has bad characters. Year entered (1974) is before 1980	Month entered is greater than 12 or is 00	Day entered is greater than 31 or is 00.},
		q{008: Bytes 11-14, Date2 (1   ) should be blank for this date type (s).},
		q{008: Bytes 15-17, Country of Publication (wis) is not valid.},
		q{008: Bytes 35-37, Language (end) not valid.},
		q{008: Byte 39, Cataloging source has bad characters (p).},
		q{008: Byte 29, Books-Conference publication has bad characters (8).},
		q{010: First digits of LCCN are 2050.},
		q{300: 4xx exists but 300 does not end with period.},
		q{300: Check subfield _a for p. or v.},
		q{300: Check subfield _c for cm., mm. or in.},
		#reporting in check_bk008_vs_300 may change in future version.
		q{300: Check subfield _b for missing period after col.},
		q{008: Bytes 18-21 do not have code 'a' but 300 subfield 'b' has 'ill.'	300: bytes 18-21 have code 'b' but 300 subfield b is ill. (some col), map. ;},
		q{490: Indicator is 1 but 8xx does not exist.},
		q{240: Is present but 1xx does not exist.},
		q{245: Indicator is 1 but 1xx does not exist.},
		q{Pub. Dates: 008 date1, 2004, 050 date, 2003, and 260_c date, 2000 do not match.},
		q{008: Index is coded 0 but 500 or 504 mentions index.},
		q{008: Not coded 'b' but 504 (or 500) mentions 'bibliographical references'.},
		q{504: Pagination may need 'p.' (Includes bibliographical references (44).).},
		q{504: Check spacing around parentheses (Includes bibliographical references(p. 44) and index.).},
#improve error message in check_041vs008lang
		q{041: First code (spa) does not match 008 bytes 35-37 (Language end).},
		q{500: Check ending punctuation (exclamation point or question mark should not be followed by period), This ends  ___ k-period?.},
		q{504: Check ending punctuation, Includes i ___ udes index},
		q{505: Check ending punctuation (exclamation point or question mark should not be followed by period), This ends  ___ t period!.},
		q{505: May have a floating hyphen, --  Test 2 - Test 3 -- },
		q{500: May have floating period (This has a floating period .).},
		q{500: May have floating comma (This has a floating comma , that should not be there.).},
		q{500: May have floating question mark (Why does this field have a floating question mark ?).},

		q{500: May have floating period (This has an emdash-- (elipsis replacement) with floating period .).},
		q{500: May have floating period (This has a regular emdash and floating period -- .).},
		q{500: May have floating period (This has an emdash-- . Then a floating period .).}, 
		q{500: May have floating punctuation marks (This lengthy se_ sentence has . multiple f_loating . punctuatio_out its midst , to test th_ing abilities ? of the err).},
		q{040: Subfield a contains only space(s) or period(s) ( ).},
		q{246: Check ending punctuation (not normally added for this field), Test 246 w ___ ng period.},

#add more expected messages here
#		q{},

	);
	my @errorstoreturn = ();
	push @errorstoreturn, (@{MARC::Errorchecks::check_all_subs($marc)});

	while ( @errorstoreturn ) {
		my $expected = shift @expected;
		my $actual = shift @errorstoreturn;

		is( $actual, $expected, "Checking expected messages: $expected" );
	}
	is( scalar @expected, 0, "All expected messages exhausted." );
}

#####

=head2 CURRENT SUBS

	push @errorstoreturn, (@{check_internal_spaces($marc)});

	push @errorstoreturn, (@{check_trailing_spaces($marc)});

	push @errorstoreturn, (@{check_double_periods($marc)});

	push @errorstoreturn, (@{check_008($marc)});

	push @errorstoreturn, (@{check_010($marc)});

	push @errorstoreturn, (@{check_end_punct_300($marc)});

	push @errorstoreturn, (@{check_bk008_vs_300($marc)});

	push @errorstoreturn, (@{check_490vs8xx($marc)});

	push @errorstoreturn, (@{check_240ind1vs1xx($marc)});

	push @errorstoreturn, (@{check_245ind1vs1xx($marc)});

	push @errorstoreturn, (@{matchpubdates($marc)});

	push @errorstoreturn, (@{check_bk008_vs_bibrefandindex($marc)});

	push @errorstoreturn, (@{check_041vs008lang($marc)});

	push @errorstoreturn, (@{check_5xxendingpunctuation($marc)});

	push @errorstoreturn, (@{findfloatinghyphens($marc)});

	push @errorstoreturn, (@{check_floating_punctuation($record)});

	push @errorstoreturn, (@{video007vs300vs538($marc)});

	push @errorstoreturn, (@{ldrvalidate($marc)});

	push @errorstoreturn, (@{geogsubjvs043($marc)});

	push @errorstoreturn, (@{findemptysubfields($marc)});

	push @errorstoreturn, (@{check_040present($marc)});

	push @errorstoreturn, (@{check_nonpunctendingfields($marc)});

	push @errorstoreturn, (@{check_fieldlength($marc)});


=cut