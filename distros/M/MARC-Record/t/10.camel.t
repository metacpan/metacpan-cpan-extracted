#!perl -Tw

use strict;

use Test::More tests => 32;

use File::Spec;

BEGIN {
    use_ok( 'MARC::Record' );
    use_ok( 'MARC::File::USMARC' );
}

# Test 1: Testing as_usmarc()
my $marc = MARC::Record->new();
isa_ok( $marc, 'MARC::Record', 'MARC record' );

$marc->leader("00000nam  22?????8a 4500"); # The ????? represents meaningless digits at this point
my $nfields = $marc->add_fields(
	["001","fol05865967"],
	["003","IMchF"],
	["010", "","", 
		a => "   00055799",
		],
	[100, "1","",
		a => "Wall, Larry."
		],
	[245, "1","0",
		a => "Programming Perl / ",
		c => "Larry Wall, Tom Christiansen & Jon Orwant.",
		],
	[250, "", "",
		a => "3rd ed.",
		],
	[260, "", "",
		a => "Cambridge, Mass. : ",
		b => "O'Reilly, ",
		c => "2000.",
		],
	[650, " ","0",
		a => "Perl (Computer program language)",
		],
	[700, "1"," ",
		a => "Christiansen, Tom.",
		],
	[700, "1"," ",
		a => "Orwant, Jon.",
		],
	);

is( $nfields, 10,	'Expected 10 fields' );

my $expected = "00397nam  22001458a 4500001001200000003000600012010001600018100001700034245006800051250001200119260004300131650003700174700002300211700001700234\x1Efol05865967\x1EIMchF\x1E  \x1Fa   00055799\x1E1 \x1FaWall, Larry.\x1E10\x1FaProgramming Perl / \x1FcLarry Wall, Tom Christiansen & Jon Orwant.\x1E  \x1Fa3rd ed.\x1E  \x1FaCambridge, Mass. : \x1FbO'Reilly, \x1Fc2000.\x1E 0\x1FaPerl (Computer program language)\x1E1 \x1FaChristiansen, Tom.\x1E1 \x1FaOrwant, Jon.\x1E\x1D";

is( MARC::File::USMARC->encode( $marc ), $expected,  'encode()' );

is( $marc->as_usmarc(), $expected,  'as_usmarc()' );

my $marc_from_blob = MARC::Record->new_from_usmarc( $expected );
isa_ok( $marc_from_blob, 'MARC::Record', 'MARC record imported from a blob' );
is( $marc->as_usmarc(), $expected,  'MARC from blob encodes correctly' ); 

# Test 2: as_string()
$expected = join( "", <DATA> );
my $generated = $marc->as_formatted;
chomp $expected;
chomp $generated;
ok( $generated eq $expected,	'as_formatted()' );


# Test 3: multiple fields by number
TEST3: {
    my @fields = $marc->field("700");
    is( scalar @fields, 2, 'Multiple 700 tags' );

    my $field = $fields[0];
    isa_ok( $field, "MARC::Field" );
    is( $field->subfield("a"), 'Christiansen, Tom.', '  Tom Christiansen' );

    $field = $fields[1];
    isa_ok( $field, "MARC::Field" );
    is( $field->subfield("a"), 'Orwant, Jon.', '  Jon Orwant' );
}


# Test 4: multiple fields by the ".." notation
TEST4: {
    my @fields = $marc->field("7..");
    is( scalar @fields, 2, 'Multiple 7.. tags' );

    my $field = $fields[0];
    isa_ok( $field, "MARC::Field" );
    is( $field->subfield("a"), 'Christiansen, Tom.', '  Tom Christiansen' );

    $field = $fields[1];
    isa_ok( $field, "MARC::Field" );
    is( $field->subfield("a"), 'Orwant, Jon.', '  Jon Orwant' );
}

# Test 5: field/subfield
is( $marc->subfield( 100, "a" ), "Wall, Larry.", 'Field/subfield lookup' );

# Test 6: Reading from disk
my $filename = File::Spec->catfile( 't', 'camel.usmarc' );
my $file = MARC::File::USMARC->in( $filename );
isa_ok( $file, 'MARC::File', "Opened input file" );

my $diskmarc;
for my $n ( 1..8 ) {
	$diskmarc = $file->next();
	isa_ok( $diskmarc, 'MARC::Record', "  Record #$n" );
}
	
if ( $diskmarc ) {
	is( $diskmarc->subfield(245,"c"), $marc->subfield(245,"c"), "Disk MARC matches built MARC" );
}
$file->close;


# Test 7: return from field() when nothing matches
TEST7: {
    my @fields = $marc->field( '999' );  # doesn't exist in the record
    is( scalar @fields, 0, "nothing returned for tag 999--array context" );
    my $field = $marc->field( '999' );   # doesn't exist in the record
    ok( !defined $field, "nothing returned for tag 999-scalar context" );
}


__END__
LDR 00397nam  22001458a 4500
001     fol05865967
003     IMchF
010    _a   00055799
100 1  _aWall, Larry.
245 10 _aProgramming Perl / 
       _cLarry Wall, Tom Christiansen & Jon Orwant.
250    _a3rd ed.
260    _aCambridge, Mass. : 
       _bO'Reilly, 
       _c2000.
650  0 _aPerl (Computer program language)
700 1  _aChristiansen, Tom.
700 1  _aOrwant, Jon.
