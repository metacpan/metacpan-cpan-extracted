package t::lib::TestUtils;

use strict;

use ExtUtils::Manifest qw(manicopy maniread);
use File::Path qw(rmtree);
use File::Spec::Functions qw(rel2abs);
use Cwd qw(cwd);
use Fatal qw(chdir);
use Config qw();
use Capture::Tiny 'capture_merged';

require Exporter; *import = \&Exporter::import;

our @EXPORT = qw(prepare_test build_makemaker build_module_build);

sub _run_capture {
    my @cmd = @_;
    my $captured = capture_merged {
        system(@cmd);
    };
    my $status = $?;
    return($captured, $status);
}

sub prepare_test {
    my( $source, $destination ) = @_;
    my $cwd = cwd();

    $destination = rel2abs( $destination );
    rmtree( $destination );
    chdir( $source );
    manicopy( maniread(), $destination );
    chdir( $cwd );
}

sub build_module_build {
    my( $path ) = @_;
    my $cwd = cwd();
    chdir $path;

    my ($build_pl, $build_pl_ok) = _run_capture($^X, "Build.PL");

    if( $build_pl_ok != 0 ) {
        chdir( $cwd );
        return ( 0, $build_pl, undef, undef );
    }

    my ($build, $build_ok) = _run_capture($^X, "Build");

    if( $build_ok != 0 ) {
        chdir( $cwd );
        return ( 0, $build_pl, $build, undef );
    }

    my ($build_test, $build_test_ok) = _run_capture($^X, "Build", "test");

    if( $build_test_ok != 0 ) {
        chdir( $cwd );
        return ( 0, $build_pl, $build, $build_test );
    } else {
        chdir( $cwd );
        return ( 1, $build_pl, $build, $build_test );
    }
}

sub build_makemaker {
    my( $path ) = @_;
    my $cwd = cwd();
    chdir $path;

    my ($makefile_pl, $makefile_pl_ok) = _run_capture($^X, "Makefile.PL");

    if( $makefile_pl_ok != 0 ) {
        chdir( $cwd );
        return ( 0, $makefile_pl, undef, undef );
    }

    my ($make, $make_ok) = _run_capture($Config::Config{make});

    if( $make_ok != 0 ) {
        chdir( $cwd );
        return ( 0, $makefile_pl, $make, undef );
    }

    my ($make_test, $make_test_ok) = _run_capture($Config::Config{make}, "test");

    if( $make_test_ok != 0 ) {
        chdir( $cwd );
        return ( 0, $makefile_pl, $make, $make_test );
    } else {
        chdir( $cwd );
        return ( 1, $makefile_pl, $make, $make_test );
    }
}

1;
