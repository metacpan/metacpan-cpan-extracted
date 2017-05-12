# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::XS (by kulp)

use Test::More tests => 1;

use Mac::PropertyList::XS;
use Time::HiRes qw(tv_interval gettimeofday);

my $data = do {
	local @ARGV = qw(plists/com.apple.iTunes.plist);
	do { local $/; <> };
	};

my $time1 = [ gettimeofday ];
my $plist = Mac::PropertyList::XS::parse_plist( $data );
my $time2 = [ gettimeofday ];

my $elapsed = tv_interval( $time1, $time2 );
print STDERR "Elapsed time is $elapsed\n";

ok($elapsed < 3, "Parsing time test");
