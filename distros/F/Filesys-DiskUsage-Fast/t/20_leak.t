use strict;
use warnings;
use ExtUtils::testlib;
use Test::More;
use Test::LeakTrace;

use Filesys::DiskUsage::Fast;
local $Filesys::DiskUsage::Fast::ShowWarnings = 0;

no_leaks_ok {
	for( 1 .. 10 ){
		my $total = Filesys::DiskUsage::Fast::du("/bin");
	}
} 'no memory leaks';

done_testing;

__END__
