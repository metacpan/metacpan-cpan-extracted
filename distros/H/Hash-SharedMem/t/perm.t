use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use POSIX qw(
	S_IRUSR S_IWUSR S_IXUSR
	S_IRGRP S_IWGRP S_IXGRP
	S_IROTH S_IWOTH S_IXOTH
);
use Test::More tests => 91;

BEGIN { use_ok "Hash::SharedMem", qw(is_shash shash_open shash_set); }

my $tmpdir = tempdir(CLEANUP => 1);

sub perm_to_trad($) {
	my($p) = @_;
	my $t = 0;
	$t |= 0400 if $p & S_IRUSR;
	$t |= 0200 if $p & S_IWUSR;
	$t |= 0100 if $p & S_IXUSR;
	$t |= 0040 if $p & S_IRGRP;
	$t |= 0020 if $p & S_IWGRP;
	$t |= 0010 if $p & S_IXGRP;
	$t |= 0004 if $p & S_IROTH;
	$t |= 0002 if $p & S_IWOTH;
	$t |= 0001 if $p & S_IXOTH;
	return $t;
}

sub perm_from_trad($) {
	my($t) = @_;
	my $p = 0;
	$p |= S_IRUSR if $t & 0400;
	$p |= S_IWUSR if $t & 0200;
	$p |= S_IXUSR if $t & 0100;
	$p |= S_IRGRP if $t & 0040;
	$p |= S_IWGRP if $t & 0020;
	$p |= S_IXGRP if $t & 0010;
	$p |= S_IROTH if $t & 0004;
	$p |= S_IWOTH if $t & 0002;
	$p |= S_IXOTH if $t & 0001;
	return $p;
}

sub mkd($) {
	my($fn) = @_;
	mkdir $fn or die "can't create $fn: $!";
}

sub chm($$) {
	my($mode, $fn) = @_;
	chmod $mode, $fn or die "can't chmod $fn: $!";
}

sub file_perm_trad($) {
	my($fn) = @_;
	my @st = stat $fn;
	@st or die "can't stat $fn: $!";
	return perm_to_trad($st[2]);
}

umask(perm_from_trad(0000));
my $sh = shash_open("$tmpdir/t0", "rwc");
ok $sh;
ok is_shash($sh);
is file_perm_trad("$tmpdir/t0"), 0777;
is file_perm_trad("$tmpdir/t0/iNmv0,m\$%3"), 0666;
ok !-f "$tmpdir/t0/&\"JBLMEgGm0000000000000001";
shash_set($sh, "a", "b");
$sh = undef;
is file_perm_trad("$tmpdir/t0"), 0777;
is file_perm_trad("$tmpdir/t0/iNmv0,m\$%3"), 0666;
is file_perm_trad("$tmpdir/t0/&\"JBLMEgGm0000000000000001"), 0666;

umask(perm_from_trad(0000));
$sh = shash_open("$tmpdir/t1", "rwc");
ok $sh;
ok is_shash($sh);
$sh = undef;
is file_perm_trad("$tmpdir/t1"), 0777;
is file_perm_trad("$tmpdir/t1/iNmv0,m\$%3"), 0666;
ok !-f "$tmpdir/t1/&\"JBLMEgGm0000000000000001";
$sh = shash_open("$tmpdir/t1", "rw");
ok $sh;
ok is_shash($sh);
shash_set($sh, "a", "b");
$sh = undef;
is file_perm_trad("$tmpdir/t1"), 0777;
is file_perm_trad("$tmpdir/t1/iNmv0,m\$%3"), 0666;
is file_perm_trad("$tmpdir/t1/&\"JBLMEgGm0000000000000001"), 0666;

umask(perm_from_trad(0000));
$sh = shash_open("$tmpdir/t2", "rwc");
ok $sh;
ok is_shash($sh);
$sh = undef;
is file_perm_trad("$tmpdir/t2"), 0777;
is file_perm_trad("$tmpdir/t2/iNmv0,m\$%3"), 0666;
ok !-f "$tmpdir/t2/&\"JBLMEgGm0000000000000001";
umask(perm_from_trad(0077));
$sh = shash_open("$tmpdir/t2", "rw");
ok $sh;
ok is_shash($sh);
shash_set($sh, "a", "b");
$sh = undef;
is file_perm_trad("$tmpdir/t2"), 0777;
is file_perm_trad("$tmpdir/t2/iNmv0,m\$%3"), 0666;
is file_perm_trad("$tmpdir/t2/&\"JBLMEgGm0000000000000001"), 0666;

umask(perm_from_trad(0000));
$sh = shash_open("$tmpdir/t3", "rwc");
ok $sh;
ok is_shash($sh);
$sh = undef;
is file_perm_trad("$tmpdir/t3"), 0777;
is file_perm_trad("$tmpdir/t3/iNmv0,m\$%3"), 0666;
ok !-f "$tmpdir/t3/&\"JBLMEgGm0000000000000001";
umask(perm_from_trad(0777));
$sh = shash_open("$tmpdir/t3", "rw");
ok $sh;
ok is_shash($sh);
shash_set($sh, "a", "b");
$sh = undef;
is file_perm_trad("$tmpdir/t3"), 0777;
is file_perm_trad("$tmpdir/t3/iNmv0,m\$%3"), 0666;
is file_perm_trad("$tmpdir/t3/&\"JBLMEgGm0000000000000001"), 0666;

umask(perm_from_trad(0077));
$sh = shash_open("$tmpdir/t4", "rwc");
ok $sh;
ok is_shash($sh);
$sh = undef;
is file_perm_trad("$tmpdir/t4"), 0700;
is file_perm_trad("$tmpdir/t4/iNmv0,m\$%3"), 0600;
ok !-f "$tmpdir/t4/&\"JBLMEgGm0000000000000001";
umask(perm_from_trad(0000));
$sh = shash_open("$tmpdir/t4", "rw");
ok $sh;
ok is_shash($sh);
shash_set($sh, "a", "b");
$sh = undef;
is file_perm_trad("$tmpdir/t4"), 0700;
is file_perm_trad("$tmpdir/t4/iNmv0,m\$%3"), 0600;
is file_perm_trad("$tmpdir/t4/&\"JBLMEgGm0000000000000001"), 0600;

umask(perm_from_trad(0022));
$sh = shash_open("$tmpdir/t5", "rwc");
ok $sh;
ok is_shash($sh);
$sh = undef;
is file_perm_trad("$tmpdir/t5"), 0755;
is file_perm_trad("$tmpdir/t5/iNmv0,m\$%3"), 0644;
ok !-f "$tmpdir/t5/&\"JBLMEgGm0000000000000001";
umask(perm_from_trad(0000));
$sh = shash_open("$tmpdir/t5", "rw");
ok $sh;
ok is_shash($sh);
shash_set($sh, "a", "b");
$sh = undef;
is file_perm_trad("$tmpdir/t5"), 0755;
is file_perm_trad("$tmpdir/t5/iNmv0,m\$%3"), 0644;
is file_perm_trad("$tmpdir/t5/&\"JBLMEgGm0000000000000001"), 0644;

umask(perm_from_trad(0027));
$sh = shash_open("$tmpdir/t6", "rwc");
ok $sh;
ok is_shash($sh);
$sh = undef;
is file_perm_trad("$tmpdir/t6"), 0750;
is file_perm_trad("$tmpdir/t6/iNmv0,m\$%3"), 0640;
ok !-f "$tmpdir/t6/&\"JBLMEgGm0000000000000001";
umask(perm_from_trad(0750));
$sh = shash_open("$tmpdir/t6", "rw");
ok $sh;
ok is_shash($sh);
shash_set($sh, "a", "b");
$sh = undef;
is file_perm_trad("$tmpdir/t6"), 0750;
is file_perm_trad("$tmpdir/t6/iNmv0,m\$%3"), 0640;
is file_perm_trad("$tmpdir/t6/&\"JBLMEgGm0000000000000001"), 0640;

umask(perm_from_trad(0077));
mkd "$tmpdir/t7";
is file_perm_trad("$tmpdir/t7"), 0700;
umask(perm_from_trad(0000));
$sh = shash_open("$tmpdir/t7", "rwc");
ok $sh;
ok is_shash($sh);
$sh = undef;
is file_perm_trad("$tmpdir/t7"), 0700;
is file_perm_trad("$tmpdir/t7/iNmv0,m\$%3"), 0666;
ok !-f "$tmpdir/t7/&\"JBLMEgGm0000000000000001";
umask(perm_from_trad(0007));
$sh = shash_open("$tmpdir/t7", "rw");
ok $sh;
ok is_shash($sh);
shash_set($sh, "a", "b");
$sh = undef;
is file_perm_trad("$tmpdir/t7"), 0700;
is file_perm_trad("$tmpdir/t7/iNmv0,m\$%3"), 0666;
is file_perm_trad("$tmpdir/t7/&\"JBLMEgGm0000000000000001"), 0666;

umask(perm_from_trad(0000));
$sh = shash_open("$tmpdir/t8", "rwc");
ok $sh;
ok is_shash($sh);
$sh = undef;
is file_perm_trad("$tmpdir/t8"), 0777;
is file_perm_trad("$tmpdir/t8/iNmv0,m\$%3"), 0666;
ok !-f "$tmpdir/t8/&\"JBLMEgGm0000000000000001";
chm perm_from_trad(0770), "$tmpdir/t8/iNmv0,m\$%3";
is file_perm_trad("$tmpdir/t8/iNmv0,m\$%3"), 0770;
umask(perm_from_trad(0077));
$sh = shash_open("$tmpdir/t8", "rw");
ok $sh;
ok is_shash($sh);
shash_set($sh, "a", "b");
$sh = undef;
is file_perm_trad("$tmpdir/t8"), 0777;
is file_perm_trad("$tmpdir/t8/iNmv0,m\$%3"), 0770;
is file_perm_trad("$tmpdir/t8/&\"JBLMEgGm0000000000000001"), 0660;

1;
