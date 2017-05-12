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

my $log = Log::Tiny->new($filename, "%c ") or die 'Could not log! (' . Log::Tiny->errstr . ')'; 
isa_ok( $log, 'Log::Tiny' );
is( Log::Tiny->errstr, '', 'errstr callable and blank' );
$log->LOG("test");
$log->log_only(qw(WARN INFO));
$log->WARN('test');
$log->INFO('test');
$log->ERR('test');
undef $log;

open (my $fh, '<', $filename) or die "Could not open log for slurping: $!";
my $logtext = do { local( $/ ); <$fh> };
close $fh or die "Could not close log: $!";

is( $logtext, 'LOG WARN INFO ', "Inclusion/exclusion worked" );

is( unlink( $filename ), 1, "Remove $filename" );
ok( !-e $filename, "Actually gone" );
