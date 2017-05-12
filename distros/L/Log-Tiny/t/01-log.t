#!perl -T

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
	use_ok( 'Log::Tiny' );
}

my $filename = "example.$$.log";
if ( -e $filename ) { 
    die "Error, '$filename' exists";
}

my $log = Log::Tiny->new($filename, "(%-5c) %m\n") or die 'Could not log! (' . Log::Tiny->errstr . ')'; 
# ^ don't use system newlines because log in DATA fh may not match (generated with \n)
isa_ok( $log, 'Log::Tiny' );
my ($warn, $error, $trace, $debug) = (0, 0, 0, 0);
$log->DEBUG("Starting...");
$debug++;
foreach ( 1 .. 5 ) {
    $log->WARN( ++$warn );
    $log->TRACE( ++$trace );
}
$log->DEBUG("Finishing...");
$debug++;
undef $log;

open (my $fh, '<', $filename) or die "Could not open log for slurping: $!";
my $logtext = do { local( $/ ); <$fh> };
close $fh or die "Could not close log: $!";

my $exptext = do { local( $/ ); <DATA> };

is($logtext, $exptext, "Does log match expected results, incl. %-5c");

is( unlink( $filename ), 1, "Remove $filename" );
ok( !-e $filename, "Actually gone" );

__DATA__
(DEBUG) Starting...
(WARN ) 1
(TRACE) 1
(WARN ) 2
(TRACE) 2
(WARN ) 3
(TRACE) 3
(WARN ) 4
(TRACE) 4
(WARN ) 5
(TRACE) 5
(DEBUG) Finishing...
