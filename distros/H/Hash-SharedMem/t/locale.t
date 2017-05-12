use warnings;
use strict;

use Errno 1.00 qw(ENOENT);
use File::Temp 0.22 qw(tempdir);
use Test::More;

BEGIN {
	unless("$]" >= 5.021001) {
		plan skip_all => "locale doesn't affect messages on this Perl";
	}
}

my($enoent_nolocale, $enoent_uselocale);
BEGIN {
	$enoent_nolocale = do { local $! = ENOENT; "$!" };
	$enoent_uselocale = do { use locale; local $! = ENOENT; "$!" };
	if($enoent_uselocale eq $enoent_nolocale) {
		plan skip_all => "current locale doesn't affect messages";
	}
}

BEGIN { plan tests => 5; }

BEGIN { use_ok "Hash::SharedMem", qw(shash_open); }

my $tmpdir = tempdir(CLEANUP => 1);

is eval { shash_open("$tmpdir/t0", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: \Q$enoent_nolocale\E at #;

is eval { use locale; shash_open("$tmpdir/t0", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: \Q$enoent_uselocale\E at #;

1;
