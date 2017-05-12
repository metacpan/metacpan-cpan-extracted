use strict;
use Test;
use File::Temp qw/ tempfile tempdir /;

my $dir = tempdir();

BEGIN { plan tests => 1 }

use Filesys::Virtual::Chroot;

my $cr;

ok(eval {
	$cr = Filesys::Virtual::Chroot->new(
		c => $dir,
		i => 0
	)
});


