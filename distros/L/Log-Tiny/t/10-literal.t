#!perl

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
	use_ok( 'Log::Tiny' );
}

# The POD promises that an unrecognised %-code is emitted literally, e.g.
# "%d" (which is NOT a Log::Tiny format code) must appear as the two
# characters "%d" and must NOT be consumed by the internal sprintf.

my $buf = '';
open( my $fh, '>>', \$buf ) or die $!;
my $log = Log::Tiny->new( $fh, '%m says %d%n' ) or die Log::Tiny->errstr;
$log->LOG("hi");
undef $log;
close $fh;

is( $buf, "hi says %d\n",
	"Unknown code %d printed literally, not consumed by sprintf" );

# A width/precision on an unknown code is preserved literally too.
my $buf2 = '';
open( my $fh2, '>>', \$buf2 ) or die $!;
my $log2 = Log::Tiny->new( $fh2, '%3d|%m%n' ) or die Log::Tiny->errstr;
$log2->LOG("x");
undef $log2;
close $fh2;

is( $buf2, "%3d|x\n", "Unknown code keeps its width digits literally" );

# A literal percent (%%) still collapses to a single percent.
my $buf3 = '';
open( my $fh3, '>>', \$buf3 ) or die $!;
my $log3 = Log::Tiny->new( $fh3, '100%% %m%n' ) or die Log::Tiny->errstr;
$log3->LOG("done");
undef $log3;
close $fh3;

is( $buf3, "100% done\n", "%% still collapses to a single literal percent" );
