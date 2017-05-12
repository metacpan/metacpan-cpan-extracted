#!perl -Tw

use Test::More tests => 40;

use strict;
use File::Spec;

BEGIN {
    use_ok( 'MARC::Record' );
    use_ok( 'MARC::File::MicroLIF' );
    use_ok( 'MARC::File::USMARC' );
}

## decode can be called in a variety of ways
##
## $obj->decode()
## MARC::File::MicroLIF->decode()
## MARC::File::MicroLIF::decode()
##
## $obj->decode()
## MARC::File::USMARC->decode()
## MARC::File::USMARC::decode()
##
## these tests make sure we don't break any of them

## slurp up some microlif (one file of each type of line endings)
my @lifnames = ( 'lineendings-0a.lif', 'lineendings-0d.lif', 'lineendings-0d0a.lif' );

foreach my $lifname (@lifnames) {
    my $liffile = File::Spec->catfile( 't', $lifname );
    open(my $IN, '<', $liffile );
    my $str = join( '', <$IN> );
    close $IN;

    ## attempt to use decode() on it

DECODE_MICROLIF_METHOD: {
    my $rec = MARC::File::MicroLIF->decode( $str );
    isa_ok( $rec, 'MARC::Record' );
    like( $rec->title(), qr/all about whales/i, "retrieved title from file $lifname" );
}

DECODE_MICROLIF_FUNCTION: {
    my $rec = MARC::File::MicroLIF::decode( $str );
    isa_ok( $rec, 'MARC::Record' );
    like( $rec->title(), qr/all about whales/i, "retrieved title from file $lifname" );
}
} #foreach lif file

## slurp up some usmarc
my $marcname = File::Spec->catfile( 't', 'sample1.usmarc' );
open(my $IN, '<', $marcname );
my $str = join( '', <$IN> );
close $IN;

## attempt to use decode on it

DECODE_USMARC_METHOD: {
    my $rec = MARC::File::USMARC->decode( $str );
    isa_ok( $rec, 'MARC::Record' );
    like( $rec->title(), qr/all about whales/i, 'retrieved title' );
}

DECODE_USMARC_FUNCTION: {
    my $rec = MARC::File::USMARC::decode( $str );
    isa_ok( $rec, 'MARC::Record' );
    like( $rec->title(), qr/all about whales/i, 'retrieved title' );
}


#
# make sure that MARC decode() can handle gaps in the record
# body and data in the body not being in directory order
# 
my @fragments = (
    "00214nam  22000978a 4500",
    "001001500000",
    "010000900015",
    "100002000024",
    "245001100044",   # length is 11
    "260003300059", 
    "650002400092", 
    "\x1e",
    "control number\x1e",
    "  \x1f" . "aLCCN\x1e",
    "1 \x1f" . "aName, Inverted.\x1e",
    # '@@@@' here is dead space after then end of the field.
    # The directory is set up so that the 245 field consists just
    # of two indicators, \x1f, 'a', 'Title.', and \x1e.  The four
    # characters after the \x1e constitute an (allowed) unused gap in the
    # record body.
    "10\x1f" . "aTitle.\x1e@@@@",
    "3 \x1f" . "aPlace : \x1f" . "bPublisher, \x1f" . "cYear.\x1e",
    " 0\x1f" . "aLC subject heading.\x1e",
    "\x1d"
);

INITIAL_FRAGMENTS: {
    my $rec = MARC::File::USMARC->decode( join('', @fragments) );
    my @w = $rec->warnings();
    is( scalar @w, 0, 'should be no warnings' );
    is( $rec->field('245')->as_usmarc(), "10\x1f" . "aTitle.\x1e", 'gap after field data should not be returned' );
    my $the260 = $rec->field('260');
    isa_ok( $the260, "MARC::Field" );
    is( $the260->indicator(1), '3', 'indicators in tag after gap should be OK' );
    is( $the260->subfield('a'), "Place : ", 'subfield a in tag after gap should be OK' );
    is( $the260->subfield('b'), "Publisher, ", 'subfield b in tag after gap should be OK' );
    is( $the260->subfield('c'), "Year.", 'subfield c in tag after gap should be OK' );
}

# rearrange the directory for next test
@fragments[1,6] = @fragments[6,1];
@fragments[2,5] = @fragments[5,2];

SHUFFLED_FRAGMENTS: {
    my $rec = MARC::File::USMARC->decode( join('', @fragments) );
    isa_ok( $rec, "MARC::Record" );
    is( $rec->field('001')->as_string(), 'control number', '001 field correct' );
    is( $rec->field('010')->as_string(), 'LCCN', '010 field correct' );
    is( $rec->field('100')->as_string(), 'Name, Inverted.', '100 field correct' );
    is( $rec->field('245')->as_string(), 'Title.', '245 field correct' );
    is( $rec->field('260')->as_string(), 'Place :  Publisher,  Year.', '260 field correct' );
    is( $rec->field('650')->as_string(), 'LC subject heading.', '650 field correct' );
}


#
# make sure that MARC::File::MicroLIF::decode can handle
# fields with no subfields without causing MARC::Field
# to croak().
# 

MICROLIF_NOSUBFIELDS: {
    # both the 040 and 041 should be discarded
    my $str = <<EOT;
LDR00180nam  22     2  4500^
008891207s19xx    xxu           00010 eng d^
040  ^
041  _^
245 0_aAll about whales.^
260  _bHoliday,_c1987.^
300  _a[ ] p.^
900  _aALL^
952  _a20571_cR_dALL^`
EOT

    my $rec = MARC::File::MicroLIF::decode( $str );
    isa_ok( $rec, 'MARC::Record' );
    my @warnings = $rec->warnings();
    is( scalar @warnings, 2, 'check for appropriate warnings count' );
    ok( grep( /Tag 040.*discarded/, @warnings ), '040 warning present' );
    ok( grep( /Tag 041.*discarded/, @warnings ), '041 warning present' );
    ok( $rec->field('245'), '245 should not exist' );
    ok( !$rec->field('040'), '040 should not exist' );
    ok( !$rec->field('041'), '041 should not exist' );
}
