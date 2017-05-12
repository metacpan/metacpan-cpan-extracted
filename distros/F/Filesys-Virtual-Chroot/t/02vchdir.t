use strict;
use Test;
use File::Temp qw/ tempfile tempdir /;

my $dir = tempdir();

BEGIN { plan tests => 7 }

use Filesys::Virtual::Chroot;

my $cr;

ok(eval {
	$cr = Filesys::Virtual::Chroot->new(
		c => $dir,
		i => 0
	)
});

my $time = time;

ok($cr->rroot eq $dir);
ok($cr->vpwd eq '/');
ok(mkdir "$dir/vchroot.$time", 0755);
ok($cr->vchdir("/vchroot.$time"));
ok($cr->rpwd eq "$dir/vchroot.$time");
ok(rmdir "$dir/vchroot.$time");
