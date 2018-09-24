#!perl
#
# Tests for both interfaces - notably to see if anything naughty is
# being done with class variables in instance methods...
#
# Note that these tests could easily run afoul various perlport(1)
# related issues or other operating system idiosyncrasies. Some efforts
# have been made to avoid running certain operating specific tests on
# certain other operating systems.

use strict;
use warnings;

use Test::More tests => 6;

BEGIN { use_ok('File::AtomicWrite') }
BEGIN { use_ok('File::Spec') }
BEGIN { use_ok('File::Temp') }

my $work_dir = File::Temp::tempdir( CLEANUP => 1 );

eval {
    my $oo_filename  = File::Spec->catfile( $work_dir, 'test-oo' );
    my $oo_filename2 = File::Spec->catfile( $work_dir, 'test-oo2' );
    my $filename     = File::Spec->catfile( $work_dir, 'test' );

    my $oo_test_string  = "oo pid is $$\n";
    my $oo_test_string2 = "oo2 pid is $$\n";
    my $test_string     = "pid is $$\n";

    # Open object, then use write_file, then commit object. See if things
    # proper following that.
    my $aw = File::AtomicWrite->new( { file => $oo_filename } );
    my $fh = $aw->fh;
    print $fh $oo_test_string;

    my $aw2 = File::AtomicWrite->new( { file => $oo_filename2 } );
    my $fh2 = $aw2->fh;
    print $fh2 $oo_test_string2;

    File::AtomicWrite->write_file(
        {   file  => $filename,
            input => \$test_string
        }
    );

    $aw->commit;
    $aw2->commit;

    my $oo_result_fh;
    open( $oo_result_fh, '<', $oo_filename )
      or diag("Could not open $oo_filename: $!\n");
    my $oo_results = do { local $/ = undef; <$oo_result_fh> };

    is( $oo_results, $oo_test_string, 'check OO write results' );

    my $oo_result_fh2;
    open( $oo_result_fh2, '<', $oo_filename2 )
      or diag("Could not open $oo_filename2: $!\n");
    my $oo_results2 = do { local $/ = undef; <$oo_result_fh2> };

    is( $oo_results2, $oo_test_string2, 'check OO2 write results' );

    my $result_fh;
    open( $result_fh, '<', $filename )
      or diag("Could not open $filename: $!\n");
    my $results = do { local $/ = undef; <$result_fh> };

    is( $results, $test_string, 'check non-OO write results' );

};
if ($@) {
    die "Error unexpected execption: $@";
}
