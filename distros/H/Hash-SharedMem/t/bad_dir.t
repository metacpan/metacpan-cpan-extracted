use warnings;
use strict;

use Errno 1.00 qw(ENOENT);
use File::Temp 0.22 qw(tempdir);
use Test::More tests => 7;

BEGIN { use_ok "Hash::SharedMem", qw(is_shash shash_open shash_set); }

my $enoent = do { local $! = ENOENT; "$!" };

my $tmpdir = tempdir(CLEANUP => 1);

sub touch($) {
	my($fn) = @_;
	open(my $fh, ">", $fn) or die "can't create $fn: $!";
}

is eval { shash_open("$tmpdir/t0", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: \Q$enoent\E at #;

touch("$tmpdir/t1");
is eval { shash_open("$tmpdir/t1", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t1: not a shared hash at #;
is eval { shash_open("$tmpdir/t1", "rwc") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t1: not a shared hash at #;

1;
