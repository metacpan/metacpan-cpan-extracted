#!perl

use strict;
use warnings;
use Test::More tests => 6;

use Log::Tiny;

my $buf = '';
open( my $fh, '>>', \$buf ) or die $!;
my $log = Log::Tiny->new( $fh, "%m%n" ) or die Log::Tiny->errstr;

ok( $log->would_log('ANYTHING'), "No filter configured -> everything logs" );

$log->levels( [qw(DEBUG INFO WARN ERROR FATAL)] );
$log->min_level('WARN');
ok( !$log->would_log('DEBUG'), "Below threshold -> would_log false" );
ok(  $log->would_log('ERROR'), "Above threshold -> would_log true" );
ok(  $log->would_log('AUDIT'), "Unranked category -> would_log true" );

my $buf2 = '';
open( my $fh2, '>>', \$buf2 ) or die $!;
my $log2 = Log::Tiny->new( $fh2, "%m%n" ) or die Log::Tiny->errstr;
$log2->log_only(qw(WARN));
ok(  $log2->would_log('WARN'), "Whitelisted category -> would_log true" );
ok( !$log2->would_log('INFO'), "Non-whitelisted category -> would_log false" );
