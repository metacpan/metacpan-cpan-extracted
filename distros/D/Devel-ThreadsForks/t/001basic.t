BEGIN {				# Magic Perl CORE pragma
    chdir 't' if -d 't';
    unshift @INC,'../lib';
}

# get configuration information
require Config;
Config->import;
my $threads_ok= $Config{useithreads} || $Config{useithreads};

# be as strict and verbose as possible
use strict;
use warnings;

my $ok_tests_per_module;
my $no_tests_per_module;
BEGIN { $ok_tests_per_module= 21, $no_tests_per_module= 19 } #BEGIN

# initializations
use Test::More tests => 2 * ( $ok_tests_per_module + $no_tests_per_module );
my @modules=  qw( threads forks );
my $initial_ok=  <<"TEXT";
Installing 'threadsforks' checking logic for Makefile.PL
TEXT
my $initial_no=  <<"TEXT";

************************************************************************
* This distribution requires a version of Perl that has threads enabled
* or which has the forks.pm module installed.  Unfortunately, this does
* not appear to be the case for $^X.
* 
* Please install a threaded version of Perl, or the "forks" module
* before trying to install this distribution again.
************************************************************************

TEXT
my $manifest= <<"TEXT";
threadsforks                threads/forks test (added by Devel::ThreadsForks)
TEXT

# make sure we start clean
my @files=    qw(
 Makefile.PL
 MANIFEST
 STDERR.1
 STDERR.2
 STDOUT.1
 STDOUT.2
 threadsforks
);
unlink(@files); # handy during development / fix previous failures

# try both modules
diag "we can check for threads" if $threads_ok;
foreach my $module (@modules) {

    # tests with allowing Makefile.PL to run to completion
    SKIP: {

        # sorry, can't test
        if ( $module eq 'threads' and !$threads_ok ) {
            diag "Skipping $ok_tests_per_module tests on unthreaded perl";
            skip( "no threads on unthreaded perl", $ok_tests_per_module );
        }

        # set up MANIFEST
        ok( open( OUT, ">MANIFEST" ), "Failed to open MANIFEST: $!" );
        ok( close OUT, "Failed to close MANIFEST: $!" );
        ok( -e "MANIFEST", "Check if MANIFEST exists" );

        # set up code for success
        my $initial_code= <<"CODE";
# fake loading of $module.pm
BEGIN { \$INC{'$module.pm'}= 'loaded' } #BEGIN
BEGIN { eval "use Devel::ThreadsForks" } #BEGIN
open( OUT, '>size' );  # cannot use STDOUT first run
print OUT \$Devel::ThreadsForks::SIZE;
close OUT;
CODE
        ( my $final_code= $initial_code ) =~
          s#(ThreadsForks)"#$1; 1" or do 'threadsforks'#;

        # set up Makefile.PL
        ok( open( OUT, ">Makefile.PL" ), "Failed to open Makefile.PL: $!" );
        print OUT $initial_code;
        ok( close OUT, "Failed to close Makefile.PL: $!" );
        ok( -e "Makefile.PL", "Check if Makefile.PL exists" );

        # checks for first time
        my $result=
          system( "$^X -I../blib/lib Makefile.PL 2>STDERR.1 >STDOUT.1" ) >> 8;
        is( $result, 0, "call 1 ok" );
        my $size= -s 'threadsforks';
        is( slurp('size'), $size, 'contents of size first time' );
        ok( unlink('size'), 'unlink size' );
        is( slurp('STDOUT.1'), '', 'contents of STDOUT first time' );
        is( slurp('STDERR.1'), $initial_ok, 'contents of STDERR first time' );
        is( slurp('Makefile.PL'), $final_code, 'contents of Makefile.PL' );
        is( slurp('MANIFEST'), $manifest, 'contents of MANIFEST' );

        # checks for second time
        $result=
          system( "$^X -I../blib/lib Makefile.PL 2>STDERR.2 >STDOUT.2" ) >> 8;
        is( $result, 0, "call 2 ok" );
        is( slurp('size'), $size, 'contents of size first time' );
        ok( unlink('size'), 'unlink size' );
        is( slurp('STDOUT.2'), '', 'contents of STDOUT second time' );
        is( slurp('STDERR.2'), '', 'contents of STDERR second time' );
        is( slurp('Makefile.PL'), $final_code, 'contents of Makefile.PL' );
        is( slurp('MANIFEST'), $manifest, 'contents of MANIFEST' );

        # cleanup
        is( unlink(@files), scalar(@files), 'make sure we end up cleanly' );
    } #SKIP

    # tests not allowing Makefile.PL to run to completion
    SKIP: {

        # sorry, can't test with threaded perl
        if ($threads_ok) {
            diag "Skipping $no_tests_per_module tests on threaded perl";
            skip( "no failure on threaded perl", $no_tests_per_module );
        }

        # sorry, can't test is forks is installed
        elsif ( eval "use forks; 1" ) {
            diag "Skipping $no_tests_per_module tests on perl with forks installed";
            skip( "no failure if forks installed", $no_tests_per_module );
        }

        # set up MANIFEST
        ok( open( OUT, ">MANIFEST" ), "Failed to open MANIFEST: $!" );
        ok( close OUT, "Failed to close MANIFEST: $!" );
        ok( -e "MANIFEST", "Check if MANIFEST exists" );

        # set up code for success
        my $initial_code= <<"CODE";
BEGIN { eval "use Devel::ThreadsForks" } #BEGIN
open( OUT, '>size' );  # should never get executed
print OUT \$Devel::ThreadsForks::SIZE;
close OUT;
CODE
        ( my $final_code= $initial_code ) =~
          s#(ThreadsForks)"#$1; 1" or do 'threadsforks'#;

        # set up Makefile.PL
        ok( open( OUT, ">Makefile.PL" ), "Failed to open Makefile.PL: $!" );
        print OUT $initial_code;
        ok( close OUT, "Failed to close Makefile.PL: $!" );
        ok( -e "Makefile.PL", "Check if Makefile.PL exists" );

        # checks for first time
        my $result=
          system( "$^X -I../blib/lib Makefile.PL 2>STDERR.1 >STDOUT.1" ) >> 8;
        is( $result, 1, "call 1 no" );
        ok( !-e 'size', "should not have seen size" );
        unlink('size'); #just in case it *was* created
        is( slurp('STDOUT.1'), '', 'contents of STDOUT first time' );
        is( slurp('STDERR.1'), $initial_ok . $initial_no,
          'contents of STDERR first time' );
        is( slurp('Makefile.PL'), $final_code, 'contents of Makefile.PL' );
        is( slurp('MANIFEST'), $manifest, 'contents of MANIFEST' );

        # checks for second time
        $result=
          system( "$^X -I../blib/lib Makefile.PL 2>STDERR.2 >STDOUT.2" ) >> 8;
        is( $result, 1, "call 2 no" );
        ok( !-e 'size', "should not have seen size" );
        unlink('size'); #just in case it *was* created
        is( slurp('STDOUT.2'), '', 'contents of STDOUT second time' );
        is( slurp('STDERR.2'), $initial_no, 'contents of STDERR second time' );
        is( slurp('Makefile.PL'), $final_code, 'contents of Makefile.PL' );
        is( slurp('MANIFEST'), $manifest, 'contents of MANIFEST' );

        # cleanup
        is( unlink(@files), scalar(@files), 'make sure we end up cleanly' );
    } #SKIP
}

#-------------------------------------------------------------------------------
#  IN: 1 filename
# OUT: 1 contents

sub slurp { open IN, $_[0]; undef $/; <IN> } #slurp
#-------------------------------------------------------------------------------
