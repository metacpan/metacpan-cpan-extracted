#!perl -Tw

=head2 NAME

DOS EOF test -- tests modification to MARC::File::USMARC to remove/ignore \x1a
from MARC files.

=head2 DESCRIPTION

Checks t/sample1eof.usmarc and cameleof.usmarc, which are just sample1.usmarc
with \x1a added as a final character, and cameleof.usmarc with \x1a added
between some records.


Prior to the change, MARC::File::USMARC should report
1..12
ok 1 - use MARC::File::USMARC;
ok 2 - Test record 1 in file sample1eof.usmarc
not ok 3 - Test record 2 in file sample1eof.usmarc
#     Failed test ([path_to_test_file] at line 58)
#          got: 'Record length "\x1a" is not numeric in record 2'
#     expected: undef
ok 4 - Test record 1 in file cameleof.usmarc
not ok 5 - Test record 2 in file cameleof.usmarc
#     Failed test ([path_to_test_file] at line 58)
#          got: 'Record length "\x1a0064" is not numeric in record 2'
#     expected: undef
ok 6 - Test record 3 in file cameleof.usmarc
ok 7 - Test record 4 in file cameleof.usmarc
not ok 8 - Test record 5 in file cameleof.usmarc
#     Failed test ([path_to_test_file] at line 58)
#          got: 'Record length "\x1a0080" is not numeric in record 5'
#     expected: undef
ok 9 - Test record 6 in file cameleof.usmarc
ok 10 - Test record 7 in file cameleof.usmarc
not ok 11 - Test record 8 in file cameleof.usmarc
#     Failed test ([path_to_test_file] at line 58)
#          got: 'Record length "\x1a0066" is not numeric in record 8'
#     expected: undef
ok 12 - Test record 9 in file cameleof.usmarc
ok 13 - Test record 10 in file cameleof.usmarc
# Looks like you planned 12 tests but ran 1 extra.

In the output above, I changed the EOF character to \x1a to prevent possible
problems a real EOF may have caused. [path_to_test_file] will be dosEOF.t plus
the path to the test file.

The revised version should report:
1..12
ok 1 - use MARC::File::USMARC;
ok 2 - Test record 1 in file sample1eof.usmarc
ok 3 - Test record 1 in file cameleof.usmarc
ok 4 - Test record 2 in file cameleof.usmarc
ok 5 - Test record 3 in file cameleof.usmarc
ok 6 - Test record 4 in file cameleof.usmarc
ok 7 - Test record 5 in file cameleof.usmarc
ok 8 - Test record 6 in file cameleof.usmarc
ok 9 - Test record 7 in file cameleof.usmarc
ok 10 - Test record 8 in file cameleof.usmarc
ok 11 - Test record 9 in file cameleof.usmarc
ok 12 - Test record 10 in file cameleof.usmarc

=cut

use strict;

use File::Spec;

use Test::More tests=>12;

BEGIN {use_ok( 'MARC::File::USMARC' );}

my @expected = (undef)x11;

foreach my $file ( 'sample1eof.usmarc', 'cameleof.usmarc' ) {

    my $filename = File::Spec->catfile( 't', $file );

    my $marcfile = MARC::File::USMARC->in( $filename ) or die "Can not open file $filename, $!";

    my $reccount = 0;

    while ( my $marc = $marcfile->next() ) {
        $reccount++;
        my @warnings = $marc->warnings();
        my $expected = shift @expected;
        my $warns = shift @warnings;
        is($warns, $expected, "Test record $reccount in file $file");

    } #while

} #foreach file
