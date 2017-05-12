use warnings;
use strict;

use Errno 1.00 qw(EIO);
use File::Temp 0.22 qw(tempdir);
use Test::More tests => 44;

BEGIN { use_ok "Hash::SharedMem", qw(
	shash_referential_handle is_shash shash_open shash_set shash_get
); }

my $eio = do { local $! = EIO; "$!" };

is shash_referential_handle(), !!shash_referential_handle;
is &shash_referential_handle(), !!shash_referential_handle;
is_deeply [shash_referential_handle()], [!!shash_referential_handle];
is_deeply [&shash_referential_handle()], [!!shash_referential_handle];

require_ok "Hash::SharedMem::Handle";
is "Hash::SharedMem::Handle"->referential_handle, shash_referential_handle;
is_deeply ["Hash::SharedMem::Handle"->referential_handle],
	[shash_referential_handle];

my $tmpdir = tempdir(CLEANUP => 1);

sub mkd($) {
	my($fn) = @_;
	mkdir $fn or die "can't create $fn: $!";
}

sub rmd($) {
	my($fn) = @_;
	rmdir $fn or die "can't delete $fn: $!";
}

sub touch($) {
	my($fn) = @_;
	open(my $fh, ">", $fn) or die "can't create $fn: $!";
}

my $i = 0;
sub test_rename($) {
	my($extra) = @_;
	mkd "$tmpdir/a$i";
	my $sh = shash_open("$tmpdir/a$i/b$i", "rwce");
	ok $sh;
	ok is_shash($sh);
	rename "$tmpdir/a$i/b$i", "$tmpdir/c$i" or die "can't rename: $!";
	$extra->();
	eval { shash_set($sh, "a", "bcd") };
	if(shash_referential_handle) {
		is $@, "";
	} else {
		like $@, qr#\Acan't write shared hash \Q$tmpdir/a$i/b$i\E: \Q$eio\E at #;
	}
	$sh = undef;
	$sh = shash_open("$tmpdir/c$i", "rw");
	ok $sh;
	ok is_shash($sh);
	is shash_get($sh, "a"), shash_referential_handle ? "bcd" : undef;
	$i++;
}

test_rename(sub {});
test_rename(sub {
	touch "$tmpdir/a$i/b$i";
});
test_rename(sub {
	mkd "$tmpdir/a$i/b$i";
});
test_rename(sub {
	rmd "$tmpdir/a$i";
});
test_rename(sub {
	rmd "$tmpdir/a$i";
	touch "$tmpdir/a$i";
});
test_rename(sub {
	rmd "$tmpdir/a$i";
	mkd "$tmpdir/a$i";
});

1;
