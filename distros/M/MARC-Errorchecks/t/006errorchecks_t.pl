#!perl -w

=head1 NAME

006errorchecks.t -- Tests to ensure MARC::Errorchecks::check_006 subroutine works as expected.

=head1 TO DO

Add tests for serials 006.

=cut

use strict;
use Test::More tests=>60;

BEGIN { use_ok( 'MARC::Record' ); }
BEGIN { use_ok( 'MARC::Errorchecks' ); }
print "MARC::Errorchecks version $MARC::Errorchecks::VERSION\n";

###################################################
	my @bad006s = (
		#too short
		q{a           000 0},
		#too long
		q{a           000 0  },
		###############
		# books 01-17 #
		###############
		#illustrations
		q{aq          000 0 },
		#audience
		q{a    h      000 0 },
		#form of item
		q{a     e     000 0 },
		#contents
		q{a      x    000 0 },
		#govt pub
		q{a          b000 0 },
		#conference
		q{a           a00 0 },
		#festschrift
		q{a           0a0 0 },
		#index
		q{a           00a 0 },
		#obsolete 32
		q{a           00000 },
		#literary form
		q{a           000 b },
		#bio
		q{a           000 0t},
		########################
		# Electronic resources #
		########################
		
		#undefined 18-21
		q{ma       i        },
		#audience
		q{m    h   i        },
		#form of item 23
		q{m     a  i        },
		#undefined 24-25
		q{m      a i        },
		#type of file
		q{m        k        },
		#undefined 27
		q{m        ia       },
		#govt pub
		q{m        i 0      },
		#undefined 29-34
		q{m        i  0     },

		######################
		# cartographic 18-34 #
		######################

		#relief
		q{eh      e     0   },
		#projection
		q{e    ee e     0   },
		#undefined 24
		q{e      ze     0   },
		#type of map
		q{e       h     0   },
		#undefined 26-27
		q{e       ef    0   },
		#govt pub
		q{e       e  r  0   },
		#form of item
		q{e       e   e 0   },
		#undefined 30
		q{e       e    a0   },
		#index
		q{e       e     z   },
		#undefined 32
		q{e       e     0z  },
		#special format
		q{e       e     0  d},
		
		#############################
		# music and sound rec 18-34 #
		#############################

		#form of comp
		q{cabz              },
		#format of music
		q{czzp              },
		#music parts
		q{czzza             },
		#audience
		q{czzz h            },
		#form of item
		q{czzz  e           },
		#accompanying material
		q{czzz   abcijr     },
		#lit text sound rec
		q{czzz         qs   },
		#undefined 32
		q{czzz           s  },
		#transposition
		q{czzz            d },
		#undefined 34
		q{czzz             a},

		####################
		# visual materials #
		####################

		#running time
		q{g0n0            vl},
		#undefined 21
		q{g010a           vl},
		#audience
		q{g010 h          vl},
		#undefined 23-27
		q{g010  abcdg     vl},
		#govt pub
		q{g010       b    vl},
		#form of item
		q{g010        e   vl},
		#undefined 30-32
		q{g010         abcvl},
		#type of material
		q{g010            el},
		#technique
		q{g010            vb},

		###################
		# mixed materials #
		###################

		#undefined 18-22
		q{pabcde            },
		#form of item
		q{p     e           },
		#undefined 24-34
		q{p      abcdefghijk},

	);
###################################################

	
	#006 byte checking returned errors may change in future version
	my @expected = (

		#short
		q{006: Must be 18 bytes long but is 17 bytes long (a           000 0).},
		#long
		q{006: Must be 18 bytes long but is 19 bytes long (a           000 0  ).},

		#books 01-17
		q{006: Byte(s) 01-04, Books-Illustrations has bad characters (q   ).},
		q{006: Byte(s) 05, Books-Audience has bad characters (h).},
		q{006: Byte(s) 06, Books-Form of item has bad characters (e).},
		q{006: Byte(s) 07-10, Books-Contents has bad characters (x   ).},
		q{006: Byte(s) 11, Books-Govt publication has bad characters (b).},
		q{006: Byte(s) 12, Books-Conference publication has bad characters (a).},
		q{006: Byte(s) 13, Books-Festschrift has bad characters (a).},
		q{006: Byte(s) 14, Books-Index has bad characters (a).},
		q{006: Byte(s) 15, Books-Obsoletebyte32 has bad characters (0).},
		q{006: Byte(s) 16, Books-Literary form has bad characters (b).},
		q{006: Byte(s) 17, Books-Biography has bad characters (t).},

		#electronic resources 01-17
		q{006: Byte(s) 01-04, Electronic Resources-Undef18to21 has bad characters (a   ).},
		q{006: Byte(s) 05, Electronic Resources-Audience has bad characters (h).},
		q{006: Byte(s) 06, Electronic Resources-FormofItem has bad characters (a).},
		q{006: Byte(s) 07-08, Electronic Resources-Undef24to25 has bad characters (a ).},
		q{006: Byte(s) 09, Electronic Resources-Type of file has bad characters (k).},
		q{006: Byte(s) 10, Electronic Resources-Undef27 has bad characters (a).},
		q{006: Byte(s) 11, Electronic Resources-Govt publication has bad characters (0).},
		q{006: Byte(s) 12-17, Electronic Resources-Undef29to34 has bad characters (0     ).},

		
		#cartographic 18-34
		q{006: Byte(s) 01-04, Cartographic-Relief has bad characters (h   ).},
		q{006: Byte(s) 05-06, Cartographic-Projection has bad characters (ee).},
		q{006: Byte(s) 7, Cartographic-Undef24 has bad characters (z).},
		q{006: Byte(s) 08, Cartographic-Type of map has bad characters (h).},
		q{006: Byte(s) 09-10, Cartographic-Undef26to27 has bad characters (f ).},
		q{006: Byte(s) 11, Cartographic-Govt publication has bad characters (r).},
		q{006: Byte(s) 12, Cartographic-Form of item has bad characters (e).},
		q{006: Byte(s) 13, Cartographic-Undef30 has bad characters (a).},
		q{006: Byte(s) 14, Cartographic-Index has bad characters (z).},
		q{006: Byte(s) 15, Cartographic-Undef32 has bad characters (z).},
		q{006: Byte(s) 16-17, Cartographic-Special format characteristics has bad characters ( d).},
		
		#music and sound rec 18-34
		q{006: Byte(s) 01-02, Music-Form of composition has bad characters (ab).},
		q{006: Byte(s) 03, Music-Format of music has bad characters (p).},
		q{006: Byte(s) 04, Music-Parts has bad characters (a).},
		q{006: Byte(s) 05, Music-Audience has bad characters (h).},
		q{006: Byte(s) 06, Music-Form of item has bad characters (e).},
		q{006: Byte(s) 07-12, Music-Accompanying material has bad characters (abcijr).},
		q{006: Byte(s) 13-14, Music-Text for sound recordings has bad characters (qs).},
		q{006: Byte(s) 15, Music-Undef32 has bad characters (s).},
		q{006: Byte(s) 16, Music-Transposition and arrangement has bad characters (d).},
		q{006: Byte(s) 17, Music-Undef34 has bad characters (a).},


		#visual materials
		q{006: Byte(s) 01-03, Visual materials-Runningtime has bad characters (0n0).},
		q{006: Byte(s) 04, Visual materials-Undef21 has bad characters (a).},
		q{006: Byte(s) 05, Visual materials-Audience has bad characters (h).},
		q{006: Byte(s) 06-10, Visual materials-Undef23to27 has bad characters (abcdg).},
		q{006: Byte(s) 11, Visual materials-Govt publication has bad characters (b).},
		q{006: Byte(s) 12, Visual materials-Form of item has bad characters (e).},
		q{006: Byte(s) 13-15, Visual materials-Undef30to32 has bad characters (abc).},
		q{006: Byte(s) 16, Visual materials-Type of visual material has bad characters (e).},
		q{006: Byte(s) 17, Visual materials-Technique has bad characters (b).},

		#mixed materials
		q{006: Byte(s) 01-05, Mixed materials-Undef18to22 has bad characters (abcde).},
		q{006: Byte(s) 06, Mixed materials-Form of item has bad characters (e).},
		q{006: Byte(s) 07-17, Mixed materials-Undef24to34 has bad characters (abcdefghijk).},
		

#add more expected messages here
#		q{},

	);


	my $record = MARC::Record->new();
	isa_ok( $record, 'MARC::Record', 'MARC record' );

	$record->leader("00000nam  2200253 a 4500"); 
	my $nfields = $record->add_fields(
		#control number so one is present
		['001', "ttt06000001"
		],
		#008 so one is present
		['008', "060508s2006    ilu           000 0 eng d"
		],
	);
	is( $nfields, 2, "All the fields added OK" );

	foreach my $bad006 (@bad006s) {
		my $field = MARC::Field->new( '006', $bad006 );
		$record->append_fields($field);
		$nfields++;
	} #foreach 006
		

	is( $nfields, 56, "All the fields added OK" );

	my @errorstoreturn = ();
	push @errorstoreturn, (@{MARC::Errorchecks::check_006($record)});

	while ( @errorstoreturn ) {
		my $expected = shift @expected;
		my $actual = shift @errorstoreturn;

		is( $actual, $expected, "Checking expected messages: $expected" );
	} #while errors

	is( scalar @expected, 0, "All expected messages exhausted." );


#####


