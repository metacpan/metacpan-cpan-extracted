#!perl
#
# Tests for the OO interface
#
# Note that these tests could easily run afoul various perlport(1)
# related issues or other operating system idiosyncrasies. Some efforts
# have been made to avoid running certain operating specific tests on
# certain other operating systems.

use warnings;
use strict;

use Test::More tests => 17;

BEGIN { use_ok('File::AtomicWrite') }
can_ok(
    'File::AtomicWrite', qw/new safe_level set_template
      fh filename checksum commit/
);

BEGIN { use_ok('File::Spec') }
BEGIN { use_ok('File::Temp') }

# FAILURE TO READ THE DOCS
eval {
    File::AtomicWrite->new();    # should fail
};
like( $@, qr/missing \S+ option/, 'empty invocation' );

my $work_dir = File::Temp::tempdir( CLEANUP => 1 );
my $test_string = "oo test\n";

eval {
    my $test_file = File::Spec->catfile( $work_dir, 'ootest1' );
    my $aw = File::AtomicWrite->new( { file => $test_file } );
    isa_ok( $aw, 'File::AtomicWrite' );

    my $fh = $aw->fh;
    ok( defined $fh, 'test filehandle' );

    my $filename = $aw->filename;
    ok( -f $filename, 'tmp filename should exist' );

    print $fh $test_string;

    ok( !-f $test_file, 'real filename should not exist' );
    $aw->commit();

    ok( -f $test_file, 'real filename exists' );
    ok( !-f $filename, 'tmp filename should not exist' );

    my $result_fh;
    open( $result_fh, '<', $test_file )
      or diag("Cannot open output file: $!\n");
    my $result_string = do { local $/; <$result_fh> };
    is( $result_string, $test_string, 'data written to disk matches source data' );
};
diag($@) if $@;

# check that DESTROY cleans things up
eval {
    my $test_file = File::Spec->catfile( $work_dir, 'ootest2' );
    my $aw = File::AtomicWrite->new( { file => $test_file } );

    my $filename = $aw->filename;
    ok( -f $filename, 'tmp filename should exist' );

    undef $aw;
    # http://www.cpantesters.org/cpan/report/07445084-b19f-3f77-b713-d32bba55d77f
    # false alarm or check too soon?
    sleep 1;
    ok( !-f $filename, 'tmp filename should not exist' );
};
diag($@) if $@;

# checksum instance method test
SKIP: {
    eval { require Digest::SHA1; };
    skip( "lack Digest::SHA1 so sorry", 1 ) if $@;

    my $really_important = "Can't corrupt this\n http://xkcd.com/108/ \n";
    my $test_file = File::Spec->catfile( $work_dir, 'ootest3' );

    eval {
        my $aw = File::AtomicWrite->new( { file => $test_file } );

        my $fh = $aw->fh;
        print $fh $really_important;

        my $digest   = Digest::SHA1->new;
        my $checksum = $digest->add($really_important)->hexdigest;

        $aw->checksum($checksum)->commit;
    };
    diag($@) if $@;

    my $result_fh;
    open( $result_fh, '<', $test_file )
      or diag("Cannot open output file: $!\n");
    my $result_string = do { local $/; <$result_fh> };
    is( $result_string, $really_important,
        'data written to disk matches source data' );
}

{
    File::AtomicWrite->set_template("NTDFOSIH_XXXXXXXXX");
    my $test_file = File::Spec->catfile( $work_dir, 'set_template_test' );
    my $aw = File::AtomicWrite->new( { file => $test_file } );
    like( $aw->filename, qr/NTDFOSIH_.{9}/, 'check custom file template name' );

    my $aw2 = File::AtomicWrite->new(
        { file => $test_file, template => 'SNTDBDTB_XXXXXXXXXX' } );
    like( $aw2->filename, qr/SNTDBDTB_.{10}/,
        'check custom file template by option' );
}
