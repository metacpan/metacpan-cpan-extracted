use strict;
use warnings;
use ExtUtils::testlib;
use Test::More;

use Filesys::DiskUsage::Fast;
local $Filesys::DiskUsage::Fast::ShowWarnings = 0;

if( not -r "/bin" or not -r "/etc" ){
	plan skip_all => "seems not unix os";
}

local $Filesys::DiskUsage::Fast::SectorSize = 0;
my $normal = Filesys::DiskUsage::Fast::du("/bin", "/etc");

local $Filesys::DiskUsage::Fast::SectorSize = 512;
my $sector = Filesys::DiskUsage::Fast::du("/bin", "/etc");

ok( $normal > 0, "normal > 0: $normal" );
ok( $sector > 0, "sector > 0: $sector" );

ok( $normal != $sector, "normal != sector" );

my $diff = abs( $normal - $sector );
ok( $diff > 0, "diff > 0" );

ok( $diff < ( $normal > $sector ? $normal : $sector ) * 0.10, "diff size is reasonably small" );

done_testing;

__END__
