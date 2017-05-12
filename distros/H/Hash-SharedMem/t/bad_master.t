use warnings;
use strict;

use Errno 1.00 qw(EISDIR);
use File::Temp 0.22 qw(tempdir);
use Test::More tests => 28;

my $eisdir = do { local $! = EISDIR; "$!" };

BEGIN { use_ok "Hash::SharedMem", qw(is_shash shash_open); }

my $tmpdir = tempdir(CLEANUP => 1);

my $sh = shash_open("$tmpdir/t0", "rwc");
ok $sh;
ok is_shash($sh);
$sh = undef;
my $master_file = "$tmpdir/t0/iNmv0,m\$%3";
my $size = -s $master_file;
$size or die;

ok is_shash(eval { shash_open("$tmpdir/t0", "rw") });

open(my $fh, ">>", $master_file) or die "can't enlarge $master_file: $!";
print {$fh} ("\0" x $size) or die "can't enlarge $master_file: $!";
close $fh or die "can't enlarge $master_file: $!";
is eval { shash_open("$tmpdir/t0", "r") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: not a shared hash at #;
is eval { shash_open("$tmpdir/t0", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: not a shared hash at #;
is eval { shash_open("$tmpdir/t0", "rwc") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: not a shared hash at #;

truncate $master_file, $size>>1 or die "can't reduce $master_file: $!";
is eval { shash_open("$tmpdir/t0", "r") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: not a shared hash at #;
is eval { shash_open("$tmpdir/t0", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: not a shared hash at #;
is eval { shash_open("$tmpdir/t0", "rwc") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: not a shared hash at #;

open($fh, ">", $master_file) or die "can't rewrite $master_file: $!";
print {$fh} ("\0" x $size) or die "can't rewrite $master_file: $!";
close $fh or die "can't rewrite $master_file: $!";
is eval { shash_open("$tmpdir/t0", "r") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: not a shared hash at #;
is eval { shash_open("$tmpdir/t0", "rw") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: not a shared hash at #;
is eval { shash_open("$tmpdir/t0", "rwc") }, undef;
like $@, qr#\Acan't open shared hash \Q$tmpdir\E/t0: not a shared hash at #;

unlink $master_file or die "can't remove $master_file: $!";
mkdir $master_file or die "can't create $master_file: $!";
is eval { shash_open("$tmpdir/t0", "r") }, undef;
like $@, qr#\Acan't\ open\ shared\ hash\ \Q$tmpdir\E/t0:
		\ (?:\Q$eisdir\E|not\ a\ shared\ hash)\ at\ #x;
is eval { shash_open("$tmpdir/t0", "rw") }, undef;
like $@, qr#\Acan't\ open\ shared\ hash\ \Q$tmpdir\E/t0:
		\ (?:\Q$eisdir\E|not\ a\ shared\ hash)\ at\ #x;
is eval { shash_open("$tmpdir/t0", "rwc") }, undef;
like $@, qr#\Acan't\ open\ shared\ hash\ \Q$tmpdir\E/t0:
		\ (?:\Q$eisdir\E|not\ a\ shared\ hash)\ at\ #x;

1;
