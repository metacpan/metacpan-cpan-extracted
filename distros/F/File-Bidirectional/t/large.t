#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Config;
use Fcntl qw( :seek );
use Test::More;

use File::Bidirectional;

# NOTE: much of this code was taken from the core perl test script
# ops/lfs.t. it was modified to test File::ReadBackwards and large files

my %has_no_sparse_files = map { $_ => 1 }
	qw( MSWin32 NetWare VMS unicos ) ;

my $test_file = 'bw.data' ;

my @test_lines = (
	"3rd from last line\n",
	"2nd from last\n",
	"last line\n",
) ;

my $test_text = join '', @test_lines ;


sub skip_all_tests {

	my( $skip_text ) = @_ ;

#	unlink $test_file ;
	plan skip_all => $skip_text ;
}

if( $Config{lseeksize} < 8 ) {
	skip_all_tests( "no 64-bit file offsets\n" ) ;
}

unless( $Config{uselargefiles} ) {
	skip_all_tests( "no large file support\n" ) ;
}

if ( $has_no_sparse_files{ $^O } ) {
	skip_all_tests( "no sparse files in $^O\n" ) ;
}

# run the long seek code below in a subprocess in case it exits with a
# signal

my $rc = system $^X, '-e', <<"EOF";
open(BIG, ">$test_file");
seek(BIG, 5_000_000_000, 0);
print BIG "$test_text" ;
exit 0;
EOF

if( $rc ) {

	my $error = 'signal ' . ($rc & 0x7f) ;
	skip_all_tests( "seeking past 2GB failed: $error" ) ;
}

open(BIG, ">$test_file");

unless( seek(BIG, 5_000_000_000, 0) ) {
	skip_all_tests( "seeking past 2GB failed: $!" ) ;
}


# Either the print or (more likely, thanks to buffering) the close will
# fail if there are are filesize limitations (process or fs).

my $print = print BIG $test_text ;
my $close = close BIG;

unless ($print && $close) {

	print "# print failed: $!\n" unless $print;
	print "# close failed: $!\n" unless $close;

	if( $! =~/too large/i ) {
		skip_all_tests( 'writing past 2GB failed: process limits?' ) ;
	}

	if( $! =~ /quota/i ) {
		skip_all_tests( 'filesystem quota limits?' ) ;
	}

	skip_all_tests( "large file error: $!" ) ;
}

plan tests => 2 ;

my $bw = File::Bidirectional->new($test_file, {mode    => 'backward'})
    or die "can't open $test_file: $!" ;

my $line = $bw->readline() ;
is( $line, $test_lines[-1], 'last line' ) ;

$line = $bw->readline() ;
is( $line, $test_lines[-2], 'next to last line' ) ;

unlink $test_file ;

exit ;
