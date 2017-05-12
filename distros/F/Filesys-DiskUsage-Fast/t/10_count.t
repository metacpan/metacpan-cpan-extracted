use strict;
use warnings;
use ExtUtils::testlib;
use Test::More;

use Filesys::DiskUsage::Fast;
local $Filesys::DiskUsage::Fast::ShowWarnings = 0;

if( not -r "/bin" or not -r "/etc" ){
	plan skip_all => "seems not unix os";
}

my $one = Filesys::DiskUsage::Fast::du("/bin");
my $two = Filesys::DiskUsage::Fast::du("/etc");
my $added = Filesys::DiskUsage::Fast::du("/bin", "/etc");

ok( $one > 0, "one > 0: $one" );
ok( $two > 0, "two > 0: $two" );
ok( abs( $one + $two - $added ) < $added * 0.1, "one + two =~ added: $added" );

done_testing;

__END__
