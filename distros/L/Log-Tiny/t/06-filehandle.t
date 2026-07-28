#!perl

use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
	use_ok( 'Log::Tiny' );
}

# 1. Log to a caller-supplied (in-memory) filehandle.
my $buf = '';
open( my $memfh, '>>', \$buf ) or die "Could not open in-memory handle: $!";

my $log = Log::Tiny->new( $memfh, "%m\n" )
    or die 'Could not log! (' . Log::Tiny->errstr . ')';
isa_ok( $log, 'Log::Tiny' );
$log->LOG("hello");
$log->LOG("world");
undef $log;   # triggers DESTROY

is( $buf, "hello\nworld\n", "Logged to caller-supplied filehandle" );

# DESTROY must NOT close a handle we did not open.
ok( defined fileno($memfh), "Caller-supplied handle left open after DESTROY" );
close $memfh;

# 2. The string "-" logs to STDOUT.
my $out = '';
{
    open( my $capture, '>>', \$out ) or die "capture: $!";
    local *STDOUT = $capture;
    my $stdout_log = Log::Tiny->new( '-', "%m\n" )
        or die 'Could not log to STDOUT! (' . Log::Tiny->errstr . ')';
    $stdout_log->LOG("to stdout");
    undef $stdout_log;
}
is( $out, "to stdout\n", "'-' logs to STDOUT" );

# 3. A bad filename still fails the old way (errstr set, undef returned).
my $bad = Log::Tiny->new( "no/such/dir/nope.$$.log", "%m\n" );
ok( !defined $bad && Log::Tiny->errstr, "Unopenable path still returns error" );
