use strict;
use warnings;
use ExtUtils::testlib;
use Test::More;
use Scalar::Util qw(looks_like_number);

use Filesys::DiskUsage::Fast;
local $Filesys::DiskUsage::Fast::ShowWarnings = 0;

for( 1 .. 10 ){
	my $total = Filesys::DiskUsage::Fast::du( $0 );
	ok( looks_like_number $total, "test 'file' looks like a number" );
	ok( $total > 0, "test 'file' result > 0" );
	ok( $total < 1_100_000_000, "test 'file' result < 1_100_000_000" );
}

done_testing;

__END__
