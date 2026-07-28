#!perl

use strict;
use warnings;
use Test::More tests => 3;

use Log::Tiny;

my $buf = '';
open( my $fh, '>>', \$buf ) or die $!;
my $log = Log::Tiny->new( $fh, "%m%n" ) or die Log::Tiny->errstr;
$log->levels( [qw(DEBUG INFO WARN ERROR FATAL)] );
$log->min_level('WARN');

my $called = 0;

# Below threshold: the code ref must NOT be invoked.
$log->DEBUG( sub { $called++; "expensive" } );
is( $called, 0, "Code-ref message not evaluated when below threshold" );

# At/above threshold: the code ref is invoked and its return value logged.
$log->ERROR( sub { $called++; "cheap" } );
is( $called, 1, "Code-ref message evaluated when it will be logged" );
is( $buf, "cheap\n", "Code-ref return value is what gets logged" );
