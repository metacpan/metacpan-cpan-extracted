use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 49;
use File::Basename;
use File::Find;
use File::Spec;
use Footprintless::Util qw(
    slurp
    temp_dir
);

BEGIN { use_ok('Footprintless::Extract') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

my $logger         = Log::Any->get_logger();
my $test_dir       = dirname( File::Spec->rel2abs($0) );
my $bar_dir        = File::Spec->catdir( $test_dir, 'data', 'resources', 'bar' );
my $bar_dir_length = length($bar_dir);

sub dir_ok {
    my ( $extract_dir, $prefix, @dir ) = @_;
    my $path = File::Spec->catdir( $extract_dir, @dir );
    ok( -d $path, "dir_ok $prefix $path" );
}

sub file_ok {
    my ( $extract_dir, $prefix, @file ) = @_;
    my $path = File::Spec->catfile( $extract_dir, @file );
    ok( -f $path, "file_ok -f $prefix $path" );
    is( slurp($path),
        slurp( File::Spec->catfile( $bar_dir, @file ) ),
        "file_ok content $prefix $path"
    );
}

sub bar_extract_ok {
    my ( $extract_dir, $prefix ) = @_;
    find(
        sub {
            return if /^\.\.?$/;
            my $relative = substr( $File::Find::name, $bar_dir_length + 1 );

            # git doesnt keep empty folder, so we skip it...
            return if ( $relative =~ /WEB-INF\/classes$/ );

            if ( -d $File::Find::name ) {
                dir_ok( $extract_dir, $prefix, $relative );
            }
            else {
                file_ok( $extract_dir, $prefix, $relative );
            }
        },
        $bar_dir
    );
}

{
    $logger->info("test tar");
    my $temp_dir = temp_dir();
    ok( Footprintless::Extract->new(
            archive => File::Spec->catfile( $test_dir, 'data', 'resources', 'bar.tar' )
            )->extract( to => $temp_dir ),
        'tar extract'
    );
    bar_extract_ok( $temp_dir, 'tar' );
}

{
    $logger->info("test tgz");
    my $temp_dir = temp_dir();
    ok( Footprintless::Extract->new(
            archive => File::Spec->catfile( $test_dir, 'data', 'resources', 'bar.tgz' )
            )->extract( to => $temp_dir ),
        'tgz extract'
    );
    bar_extract_ok( $temp_dir, 'tgz' );
}

{
    $logger->info("test unzip");
    my $temp_dir = temp_dir();
    ok( Footprintless::Extract->new(
            archive => File::Spec->catfile( $test_dir, 'data', 'resources', 'bar.war' )
            )->extract( to => $temp_dir ),
        'zip extract'
    );
    bar_extract_ok( $temp_dir, 'zip' );
}
