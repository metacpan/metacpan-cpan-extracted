#!perl -w

=head1 NAME

ldrerrorchecks.t -- Tests to ensure MARC::Errorchecks::ldrvalidate subroutine works as expected. Checks bytes 5, 6, 7, 17, and 18.

=cut

use strict;
use Test::More tests=>131;

BEGIN { use_ok( 'MARC::Errorchecks' ); }
BEGIN { use_ok ( 'MARC::Record' ); }
print "MARC::Errorchecks version $MARC::Errorchecks::VERSION\n";

my @expected = (

    q{LDR: Byte 05, Status b is invalid.}, # doesn't exist

    q{LDR: Byte 06, Material type b is invalid.}, # obsolete
    q{LDR: Byte 06, Material type h is invalid.}, # obsolete
    q{LDR: Byte 06, Material type l is invalid.}, # doesn't exist
    q{LDR: Byte 06, Material type n is invalid.}, # obsolete
    q{LDR: Byte 06, Material type q is invalid.}, # doesn't exist
    q{LDR: Byte 06, Material type s is invalid.}, # doesn't exist
    q{LDR: Byte 06, Material type u is invalid.}, # doesn't exist
    q{LDR: Byte 06, Material type v is invalid.}, # doesn't exist
    q{LDR: Byte 06, Material type 8 is invalid.}, # doesn't exist
    q{LDR: Byte 06, Material type   is invalid.}, # doesn't exist

    q{LDR: Byte 07, Bib. Level, e is invalid.}, # doesn't exist
    q{LDR: Byte 17, Encoding Level, 6 is invalid.}, # doesn't exist
    q{LDR: Byte 18, Cataloging rules, b is invalid.}, # doesn't exist
    q{LDR: Byte 18, Cataloging rules, p is invalid.}, # obsolete
    q{LDR: Byte 18, Cataloging rules, r is invalid.}, # obsolete

);

my @leaders = (

    #byte 05:
    q{00000aam  2200253 a 4500}, # good
    q{00000bam  2200253 a 4500}, # bad
    q{00000cam  2200253 a 4500}, # good
    q{00000dam  2200253 a 4500}, # good
    q{00000nam  2200253 a 4500}, # good
    q{00000pam  2200253 a 4500}, # good

    #byte 06:
    q{00000nam  2200253 a 4500}, # good
    q{00000nbm  2200253 a 4500}, # obsolete
    q{00000ncm  2200253 a 4500}, # good
    q{00000ndm  2200253 a 4500}, # good
    q{00000nem  2200253 a 4500}, # good
    q{00000nfm  2200253 a 4500}, # good
    q{00000ngm  2200253 a 4500}, # good
    q{00000nhm  2200253 a 4500}, # obsolete
    q{00000nim  2200253 a 4500}, # good
    q{00000njm  2200253 a 4500}, # good
    q{00000nkm  2200253 a 4500}, # good
    q{00000nlm  2200253 a 4500}, # bad
    q{00000nmm  2200253 a 4500}, # good
    q{00000nnm  2200253 a 4500}, # good
    q{00000nom  2200253 a 4500}, # good
    q{00000nqm  2200253 a 4500}, # bad
    q{00000npm  2200253 a 4500}, # good
    q{00000nrm  2200253 a 4500}, # good
    q{00000nsm  2200253 a 4500}, # bad
    q{00000ntm  2200253 a 4500}, # good
    q{00000num  2200253 a 4500}, # bad
    q{00000nvm  2200253 a 4500}, # bad
    q{00000n8m  2200253 a 4500}, # bad
    q{00000n m  2200253 a 4500}, # bad

    #byte 07:
    q{00000naa  2200253 a 4500}, # good
    q{00000nab  2200253 a 4500}, # good
    q{00000nac  2200253 a 4500}, # good
    q{00000nad  2200253 a 4500}, # good
    q{00000nae  2200253 a 4500}, # bad
    q{00000nai  2200253 a 4500}, # good
    q{00000nam  2200253 a 4500}, # good
    q{00000nas  2200253 a 4500}, # good

    #byte 17:
    q{00000nam  2200253 a 4500}, # good
    q{00000nam  22002531a 4500}, # good
    q{00000nam  22002532a 4500}, # good
    q{00000nam  22002533a 4500}, # good
    q{00000nam  22002534a 4500}, # good
    q{00000nam  22002535a 4500}, # good
    q{00000nam  22002536a 4500}, # bad
    q{00000nam  22002537a 4500}, # good
    q{00000nam  22002538a 4500}, # good
    q{00000nam  2200253ua 4500}, # good
    q{00000nam  2200253za 4500}, # good

    #byte 18:
    q{00000nam  2200253   4500}, # good
    q{00000nam  2200253 a 4500}, # good
    q{00000nam  2200253 b 4500}, # bad
    q{00000nam  2200253 i 4500}, # good
    q{00000nam  2200253 p 4500}, # obsolete
    q{00000nam  2200253 r 4500}, # obsolete
    q{00000nam  2200253 u 4500}, # good

);

foreach my $leader (@leaders) {
    my $marc = MARC::Record->new();
    isa_ok( $marc, 'MARC::Record', 'MARC record' );

    $marc->leader($leader); 
    my $nfields = $marc->add_fields(
        #control number so one is present
        ['001', "ttt07000001"
        ],
        #basic 008
        ['008', "050718s2005    ilu           000 0 eng d"
        ],
        #basic 245
        [245, "0","0",
            a => "Test record from text /",
            c => "Bryan Baldus ... [et al.].",
        ],
    );
    is( $nfields, 3, "All the fields added OK" );


    my @errorstoreturn = ();
    push @errorstoreturn, (@{MARC::Errorchecks::ldrvalidate($marc)});
    if (@errorstoreturn) {
        print "Errors for leader (",  $leader, ")\n";
    } #if errors
    else {
        print "No errors for leader (",  $leader, ")\n";
    } #else no errors
    while ( @errorstoreturn ) {
        my $expected = shift @expected;
        my $actual = shift @errorstoreturn;
        #$expected .= $leader;
        is( $actual, $expected, "Checking expected messages: $expected" );
    } #while errorstoreturn

} #foreach leader

is( scalar @expected, 0, "All expected messages exhausted." );

