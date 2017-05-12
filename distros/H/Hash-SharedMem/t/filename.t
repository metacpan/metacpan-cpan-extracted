use warnings;
use strict;

use Errno 1.00 qw(ENOENT);
use File::Temp 0.22 qw(tempdir);
use Test::More tests => 42;

BEGIN { use_ok "Hash::SharedMem", qw(is_shash shash_open shash_set); }

my $enoent = do { local $! = ENOENT; "$!" };

my $tmpdir = tempdir(CLEANUP => 1);

sub mkd($) {
	my($fn) = @_;
	mkdir $fn or die "can't create $fn: $!";
}

sub touch($) {
	my($fn) = @_;
	open(my $fh, ">", $fn) or die "can't create $fn: $!";
}

sub rm_existing($) {
	my($fn) = @_;
	if(-f $fn) {
		ok 1;
		unlink($fn) or die "can't remove $fn: $!";
	} else {
		ok 0;
	}
}

sub rm_nonexisting($) {
	my($fn) = @_;
	if(-f $fn) {
		ok 0;
		unlink($fn) or die "can't remove $fn: $!";
	} else {
		ok 1;
	}
}

my $sh = shash_open("$tmpdir/t12", "rwc");
ok $sh;
ok is_shash($sh);
shash_set($sh, "a", "b");
$sh = undef;

ok is_shash(eval { shash_open("$tmpdir/t12", "rw") });

mkd("$tmpdir/t0");
is eval { shash_open("$tmpdir/t0", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: \Q$enoent\E at #;

mkd("$tmpdir/t1");
ok is_shash(eval { shash_open("$tmpdir/t1", "rwc") });

touch "$tmpdir/t12/.wibble";
ok is_shash(eval { shash_open("$tmpdir/t12", "rw") });
rm_existing "$tmpdir/t12/.wibble";

mkd("$tmpdir/t2");
touch "$tmpdir/t2/.wibble";
is eval { shash_open("$tmpdir/t2", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t2: \Q$enoent\E at #;

mkd("$tmpdir/t3");
touch "$tmpdir/t3/.wibble";
ok is_shash(eval { shash_open("$tmpdir/t3", "rwc") });

touch "$tmpdir/t12/&\"JBLMEgGm0000000000000010";
ok is_shash(eval { shash_open("$tmpdir/t12", "rw") });
rm_existing "$tmpdir/t12/&\"JBLMEgGm0000000000000010";

touch "$tmpdir/t12/&\"JBLMEgGmfffffffffffffff0";
ok is_shash(eval { shash_open("$tmpdir/t12", "rw") });
rm_nonexisting "$tmpdir/t12/&\"JBLMEgGmfffffffffffffff0";

touch "$tmpdir/t12/DNaM6okQi;wibble";
ok is_shash(eval { shash_open("$tmpdir/t12", "rw") });
rm_nonexisting "$tmpdir/t12/DNaM6okQi;wibble";

mkd("$tmpdir/t4");
touch "$tmpdir/t4/DNaM6okQi;wibble";
is eval { shash_open("$tmpdir/t4", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t4: \Q$enoent\E at #;

mkd("$tmpdir/t5");
touch "$tmpdir/t5/DNaM6okQi;wibble";
ok is_shash(eval { shash_open("$tmpdir/t5", "rwc") });

touch "$tmpdir/t12/&\"JBLMEgGm0000000000000000";
is eval { shash_open("$tmpdir/t12", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t12: not a shared hash at #;
rm_existing "$tmpdir/t12/&\"JBLMEgGm0000000000000000";

mkd("$tmpdir/t6");
touch "$tmpdir/t6/&\"JBLMEgGm0000000000000000";
is eval { shash_open("$tmpdir/t6", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t6: not a shared hash at #;

mkd("$tmpdir/t7");
touch "$tmpdir/t7/&\"JBLMEgGm0000000000000000";
is eval { shash_open("$tmpdir/t7", "rwc") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t7: not a shared hash at #;

touch "$tmpdir/t12/&\"JBLMEgGmwibble";
is eval { shash_open("$tmpdir/t12", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t12: not a shared hash at #;
rm_existing "$tmpdir/t12/&\"JBLMEgGmwibble";

mkd("$tmpdir/t8");
touch "$tmpdir/t8/&\"JBLMEgGmwibble";
is eval { shash_open("$tmpdir/t8", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t8: not a shared hash at #;

mkd("$tmpdir/t9");
touch "$tmpdir/t9/&\"JBLMEgGmwibble";
is eval { shash_open("$tmpdir/t9", "rwc") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t9: not a shared hash at #;

touch "$tmpdir/t12/wibble";
is eval { shash_open("$tmpdir/t12", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t12: not a shared hash at #;
rm_existing "$tmpdir/t12/wibble";

mkd("$tmpdir/t10");
touch "$tmpdir/t10/wibble";
is eval { shash_open("$tmpdir/t10", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t10: not a shared hash at #;

mkd("$tmpdir/t11");
touch "$tmpdir/t11/wibble";
is eval { shash_open("$tmpdir/t11", "rwc") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t11: not a shared hash at #;

1;
