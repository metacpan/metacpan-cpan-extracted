#!perl
# Empty archives: a tarball with zero entries (just two trailing zero
# blocks) should iterate to zero entries cleanly.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/empty.tar";

# Create an archive with no entries by opening + immediately closing.
my $w = File::Raw::Archive->create($tar);
$w->close;

# tar's end-of-archive convention is two 512-byte zero blocks.
ok(-s $tar >= 1024, 'empty archive contains the trailing zero blocks');

# list() returns an empty arrayref.
my $rows = File::Raw::Archive->list($tar);
isa_ok($rows, 'ARRAY', 'list returns arrayref');
is(scalar @$rows, 0, 'empty archive: zero entries listed');

# each() never invokes the callback.
my $callbacks = 0;
File::Raw::Archive->each($tar, sub { $callbacks++ });
is($callbacks, 0, 'each: callback not invoked on empty archive');

# Reader::next returns undef immediately.
my $r = File::Raw::Archive->open($tar);
my $first = $r->next;
ok(!defined $first, 'next returns undef on empty archive');
$r->close;

# extract_all to an empty dir does nothing visible.
my $dest = "$dir/dest";
File::Raw::Archive->extract_all($tar, $dest);
ok(-d $dest, 'extract_all created the dest dir');
opendir my $dh, $dest or die "opendir: $!";
my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
closedir $dh;
is(scalar @entries, 0, 'extract_all of empty archive leaves dest empty');

# extract() of any name returns 0 (not found).
my $rc = File::Raw::Archive->extract($tar, 'no-such-name', "$dir/out.txt");
is($rc, 0, 'extract() returns 0 when target not in archive');
ok(!-e "$dir/out.txt", 'no output file created on extract miss');

# Round-trip through gzip auto-detection: empty .tar.gz also iterates clean.
my $gz = "$dir/empty.tar.gz";
my $gw = File::Raw::Archive->create($gz, compression => 'gzip');
$gw->close;
ok(-s $gz > 0, 'empty .tar.gz produced');

my $gz_rows = File::Raw::Archive->list($gz);
is(scalar @$gz_rows, 0, 'empty .tar.gz: zero entries listed (gzip auto-detect)');

done_testing;
