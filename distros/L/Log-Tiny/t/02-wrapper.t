#!perl -T

use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
	use_ok( 'Log::Tiny' );
}

my $filename = "example.$$.log";
if ( -e $filename ) { 
    die "Error, '$filename' exists";
}

my $log = Log::Tiny2->new($filename, "%P %S %m\n") or die 'Could not log! (' . Log::Tiny->errstr . ')'; 
isa_ok( $log, 'Log::Tiny2' );
is( Log::Tiny2->errstr, '', 'errstr callable and blank' );
$log->LOG("test");
undef $log;

open (my $fh, '<', $filename) or die "Could not open log for slurping: $!";
my $logtext = do { local( $/ ); <$fh> };
close $fh or die "Could not close log: $!";

is( $logtext, "main main test\n", 'Log worked' );

is( unlink( $filename ), 1, "Remove $filename" );
ok( !-e $filename, "Actually gone" );

package Log::Tiny2;
use Log::Tiny;
use base 'Log::Tiny';

package main;
