#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use warnings;

use FindBin '$Bin';
use File::Spec;
use File::Temp qw(tempdir);
use lib "$Bin/../lib";

my $DATA_DIR = File::Spec->catdir( $Bin, 'data' );
my $RSS_FILE = File::Spec->catfile( $DATA_DIR, 'test.xml' );

BEGIN {
    use Test::More tests => 28;
}

use MP3::PodcastFetch;

my @tests = (
    {   config => {
            -rewrite_filename => 1,
            -upgrade_tag      => 0,
            -verbose          => 0,
            -mirror_mode      => 'exists',
        },
        files => [ 'Test_File_1.mp3', 'Test_File_2.mp3', 'Test_File_3.mp3', ],
    },
    {   config => {
            -rewrite_filename => 0,
            -upgrade_tag      => 0,
            -verbose          => 0,
            -mirror_mode      => 'exists',
        },
        files => [ 'test1.mp3', 'test2.mp3', 'test 3.mp3', ],
    },
);

chdir $Bin;

foreach my $test (@tests) {
    my $tempdir = tempdir( CLEANUP => 1 );
    my $base = File::Spec->catdir( $tempdir, 'podcasts' );
    my $rss = File::Spec->catfile( $tempdir, "test.xml" );

    my %config = %{ $test->{config} };
    $config{'-base'} = $base;
    $config{'-rss'}  = 'file://' . $rss;

    my @expect_files = sort @{ $test->{files} };
    my $file_count   = @expect_files;

    # we need to create a temporary XML file in which paths are correct
    open my $IN, $RSS_FILE or die $!;
    open my $OUT, ">", $rss or die $!;
    while (<$IN>) {
        s!\$PATH!file://$DATA_DIR!g;
        print $OUT $_;
    }
    close $IN;
    close $OUT;

    my $feed = MP3::PodcastFetch->new(%config);
    ok( $feed,             'created feed' );
    ok( $feed->fetch_pods, 'fetched pods' );
    is( $feed->fetched, $file_count, "fetched $file_count" );
    is( $feed->skipped, 0,           'skipped 0' );

    my @files;
    ok( @files = $feed->fetched_files, 'files we fetched' );
    @files = map { ( File::Spec->splitpath($_) )[-1] } @files;
    is_deeply( \@files, \@expect_files, 'got correct files' );

    ok( -d $base, 'basedir exists' );
    ok( -d File::Spec->catfile( $base, 'MP3PodcastFetch' ),
        'feed dir exists' );

    foreach my $f ( @{ $test->{files} } ) {
        my $file = File::Spec->catfile( $base, 'MP3PodcastFetch', $f );
        ok( -e $file, "$f exists" );
    }

    $feed = MP3::PodcastFetch->new(%config);
    ok( $feed->fetch_pods, 'refetch pods' );
    is( $feed->fetched, 0,           'fetched 0' );
    is( $feed->skipped, $file_count, "skipped $file_count" );
}

exit 0;
