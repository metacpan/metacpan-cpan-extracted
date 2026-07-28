#!perl

use strict;
use warnings;
use Test::More tests => 5;

use Log::Tiny ':easy';

ok( defined &INFO,  "INFO exported by :easy" );
ok( defined &LOGDIE, "LOGDIE exported by :easy" );

# Default easy logger writes to STDERR.
{
    my $buf = '';
    local *STDERR;
    open( *STDERR, '>>', \$buf ) or die $!;
    INFO("to-stderr");
    like( $buf, qr/\[INFO\] to-stderr/,
        "Uninitialised :easy logger defaults to STDERR" );
}

# easy_init: positional destination + format.
$Log::Tiny::easy = undef;
my $b2 = '';
open( my $fh2, '>>', \$b2 ) or die $!;
Log::Tiny->easy_init( $fh2, '%c:%m%n' );
WARN("w");
is( $b2, "WARN:w\n", "easy_init(\$fh, \$format) redirects the easy logger" );

# easy_init: hashref form with a level threshold.
$Log::Tiny::easy = undef;
my $b3 = '';
open( my $fh3, '>>', \$b3 ) or die $!;
Log::Tiny->easy_init( { fh => $fh3, format => '%c %m%n', level => 'WARN' } );
DEBUG("d");   # below threshold -> dropped
ERROR("e");   # above threshold -> logged
is( $b3, "ERROR e\n", "easy_init level threshold filters easy calls" );
