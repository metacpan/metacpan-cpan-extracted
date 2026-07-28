#!perl

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
	use_ok( 'Log::Tiny' );
}

# Log %P (calling package) to an in-memory buffer.
my $buf = '';
open( my $memfh, '>>', \$buf ) or die "mem: $!";
my $log = Log::Tiny->new( $memfh, "%P\n" ) or die Log::Tiny->errstr;

# A wrapper living in another package. Without adjustment %P reports
# the wrapper's package; with caller_depth localised it reports ours.
{
    package My::Wrapper;
    our $log;
    sub emit { $log->LOG(@_) }
    sub emit_adjusted {
        local $Log::Tiny::caller_depth = 1;
        $log->LOG(@_);
    }
}
$My::Wrapper::log = $log;

$buf = '';
My::Wrapper::emit("x");
is( $buf, "My::Wrapper\n", "Without adjustment, %P is the wrapper package" );

$buf = '';
My::Wrapper::emit_adjusted("y");
is( $buf, "main\n", "With caller_depth=1, %P is the wrapper's caller" );

# Default depth for a direct call is unchanged.
$buf = '';
$log->LOG("z");
is( $buf, "main\n", "Direct call still reports the immediate caller" );

undef $log;
close $memfh;
