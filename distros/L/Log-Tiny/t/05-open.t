#!perl -T

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
	use_ok( 'Log::Tiny' );
}

# With 2-arg open(), mode and filename are one string and Perl strips the
# leading whitespace, so a name like "  spacey.log" would be written to
# "spacey.log".  With 3-arg open() the path is honoured literally.
my $filename = "  example.$$.log";
if ( -e $filename ) {
    die "Error, '$filename' exists";
}

my $log = Log::Tiny->new($filename, "%m\n")
    or die 'Could not log! (' . Log::Tiny->errstr . ')';
isa_ok( $log, 'Log::Tiny' );
$log->LOG("test");
undef $log;

ok( -e $filename, "Log file created at the literal (untrimmed) path" );

is( unlink( $filename ), 1, "Remove '$filename'" );
