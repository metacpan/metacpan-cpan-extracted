#!perl -w

=head1 NAME

check_010.t -- Tests to ensure MARC::Errorchecks::check_010 subroutine works as expected.

=head1 TO DO

If check_010 would be better in MARC::Lint, modify this test appropriately.

=cut

use strict;
use Test::More tests=>46;

BEGIN { use_ok( 'MARC::Errorchecks' ); }
BEGIN { use_ok ( 'MARC::Record' ); }
print "MARC::Errorchecks version $MARC::Errorchecks::VERSION\n";

my @expected = (

    q{010: Subfield 'a' has improper spacing (00000001).}, #no spaces before or after 8-digit,

    q{010: Subfield 'a' has improper spacing (01000001).}, #spacing and post 2000 8-digit

    q{010: Subfield 'a' has improper spacing (2001000001).}, #no spaces before 10-digit,

########    q{   00000002  #good 8-digit},
#####    q{010: First digits of LCCN are 01.}, #spacing good on post 2000 8-digit},

########    q{  2001000002 #good 10-digit},

    q{010: Subfield 'a' has improper spacing (   00000003).}, #no space after 8-digit

    q{010: Subfield 'a' has improper spacing (  01000003 ).}, #2 spaces before and post 2000 8-digit


    q{010: Subfield 'a' has improper spacing ( 2001000003).}, #1 space before 10-digit
    q{010: Subfield 'a' has improper spacing (  00000004 ).}, #2 spaces before 8-digit
    q{010: Subfield 'a' has improper spacing (  2001000004 ).}, #1 space after 10-digit
    q{010: Subfield 'a' has improper spacing ( 00000005 ).}, #1 spaces before 8-digit
    q{010: Subfield 'a' has improper spacing ( 2001000005 ).}, #1 space before and after 10-digit
####    q{010: Subfield 'a' has non-digits (   00000006 //r96).}, #good 8-digit with extra data},
####    q{010: Subfield 'a' has non-digits (  2001000006//r02).}, #good 10-digit with extra data},
    q{010: First digits of LCCN are 2019.},

);

my @lccns = (
    q{00000001}, #no spaces before or after 8-digit
    q{01000001}, #spacing and post 2000 8-digit
    q{2001000001}, #no spaces before 10-digit
    q{   00000002 }, #good 8-digit
    q{   01000002 }, #spacing good on post 2000 8-digit
    q{  2001000002}, #good 10-digit
    q{   00000003}, #no space after 8-digit
    q{  01000003 }, #2 spaces before and post 2000 8-digit
    q{ 2001000003}, #1 space before 10-digit
    q{  00000004 }, #2 spaces before 8-digit
    q{  2001000004 }, #1 space after 10-digit
    q{ 00000005 }, #1 spaces before 8-digit
    q{ 2001000005 }, #1 space before and after 10-digit
    q{   00000006 //r96}, #good 8-digit with extra data
    q{  2001000006//r02}, #good 10-digit with extra data

    q{  2019000006}, #post-current year (until 2019) 10-digit


);

foreach my $lccn (@lccns) {
    my $marc = MARC::Record->new();
    isa_ok( $marc, 'MARC::Record', 'MARC record' );

    $marc->leader("00000nam  2200253 a 4500"); 
    my $nfields = $marc->add_fields(
        #control number so one is present
        ['001', "ttt04000001"
        ],
        #basic 008
        ['008', "050718s2005    ilu           000 0 eng d"
        ],
        #add current LCCN for testing
        ['010', "", "",
            a => $lccn,
        ],
        #basic 245
        [245, "0","0",
            a => "Test record from text /",
            c => "Bryan Baldus ... [et al.].",
        ],
    );
    is( $nfields, 4, "All the fields added OK" );


    my @errorstoreturn = ();
    push @errorstoreturn, (@{MARC::Errorchecks::check_010($marc)});
    if (@errorstoreturn) {
        print "Errors for LCCN(",  $lccn, ")\n";
    } #if errors
    else {
        print "No errors for LCCN(",  $lccn, ")\n";
    } #else no errors
    while ( @errorstoreturn ) {
        my $expected = shift @expected;
        my $actual = shift @errorstoreturn;
        #$expected .= $lccn;
        is( $actual, $expected, "Checking expected messages: $expected" );
    } #while errorstoreturn

} #foreach lccn

is( scalar @expected, 0, "All expected messages exhausted." );

