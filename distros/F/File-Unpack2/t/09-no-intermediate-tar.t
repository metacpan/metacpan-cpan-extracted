#!perl

use Test::More;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack2;
use File::Temp;
use File::Find;

# Regression test: after unpacking a foo.tar.gz, the intermediate foo.tar
# must not be left behind in the unpacked directory (it wastes space and
# should be removed once its contents have been recursively extracted).

my $have_tar  = -f '/usr/bin/tar'  || -f '/bin/tar';
my $have_gzip = -f '/usr/bin/gzip' || -f '/bin/gzip';
my $have_xz   = -f '/usr/bin/xz'   || -f '/bin/xz';

plan skip_all => 'tar and/or gzip not found' unless $have_tar && $have_gzip;

subtest 'Simple .tar.gz archive' => sub {
  my $testdir = File::Temp::tempdir("FU_09_XXXXX", TMPDIR => 1, CLEANUP => 1);
  my $fixture  = "$FindBin::Bin/data/intermediate-removal-test.tar.gz";

  my $u = File::Unpack2->new(destdir => $testdir, verbose => 0, logfile => '/dev/null');

  ok(-f $fixture, 'test fixture intermediate-removal-test.tar.gz exists');

  $u->unpack($fixture);

  # The source .tar.gz must not be copied/left in destdir.
  ok(!-f "$testdir/intermediate-removal-test.tar.gz",
    '.tar.gz archive is not left in destination after unpacking');

  # The inner tar archive must NOT remain as a plain file after unpacking.
  ok(!-f "$testdir/intermediate-removal-test.tar",
    'intermediate .tar file is removed after unpacking .tar.gz');

  # The actual content must be present somewhere under testdir.
  ok(-f "$testdir/intermediate-removal-test.tar_/hello.txt" ||
    -f "$testdir/intermediate-removal-test/hello.txt"      ||
    -f "$testdir/hello.txt",
    'hello.txt from inside the archive is present after unpacking');
};

subtest 'Recursive 3-level .tar.gz archive with subdirectories' => sub {
  my $destdir = File::Temp::tempdir("FU_09R_XXXXX", TMPDIR => 1, CLEANUP => 1);
  my $fixture = "$FindBin::Bin/data/recursive-3level-removal-test.tar.gz";

  my $u = File::Unpack2->new(destdir => $destdir, verbose => 0, logfile => '/dev/null');

  ok(-f $fixture, 'test fixture recursive-3level-removal-test.tar.gz exists');

  $u->unpack($fixture);

  my @payloads;
  my @leftover_archives;
  find(
    sub {
      return unless -f $_;
      push @payloads, $File::Find::name if $_ eq 'hello-3.txt';
      push @leftover_archives, $File::Find::name if $_ =~ m{\.tar(?:\.gz)?\z};
    },
    $destdir,
  );

  ok(@payloads > 0,
    'deep payload from nested archives is present after recursive unpacking');
  is(scalar @leftover_archives, 0,
    'no .tar or .tar.gz files are left behind in destination tree');
};

subtest 'Simple .tar.xz archive' => sub {
  plan skip_all => 'xz not found' unless $have_xz;

  my $testdir = File::Temp::tempdir("FU_09XZ_XXXXX", TMPDIR => 1, CLEANUP => 1);
  my $fixture  = "$FindBin::Bin/data/intermediate-removal-test.tar.xz";

  my $u = File::Unpack2->new(destdir => $testdir, verbose => 0, logfile => '/dev/null');

  ok(-f $fixture, 'test fixture intermediate-removal-test.tar.xz exists');

  $u->unpack($fixture);

  # The source .tar.xz must not be copied/left in destdir.
  ok(!-f "$testdir/intermediate-removal-test.tar.xz",
    '.tar.xz archive is not left in destination after unpacking');

  # The inner tar archive must NOT remain as a plain file after unpacking.
  ok(!-f "$testdir/intermediate-removal-test.tar",
    'intermediate .tar file is removed after unpacking .tar.xz');

  # The actual content must be present somewhere under testdir.
  my @found;
  find(sub { push @found, $File::Find::name if $_ eq 'hello.txt' }, $testdir);
  ok(@found > 0, 'hello.txt from inside the archive is present after unpacking');
};

subtest 'Recursive 3-level .tar.xz archive with subdirectories' => sub {
  plan skip_all => 'xz not found' unless $have_xz;

  my $destdir = File::Temp::tempdir("FU_09RXZ_XXXXX", TMPDIR => 1, CLEANUP => 1);
  my $fixture = "$FindBin::Bin/data/recursive-3level-removal-test.tar.xz";

  my $u = File::Unpack2->new(destdir => $destdir, verbose => 0, logfile => '/dev/null');

  ok(-f $fixture, 'test fixture recursive-3level-removal-test.tar.xz exists');

  $u->unpack($fixture);

  my @payloads;
  my @leftover_archives;
  find(
    sub {
      return unless -f $_;
      push @payloads, $File::Find::name if $_ eq 'hello-3.txt';
      push @leftover_archives, $File::Find::name if $_ =~ m{\.tar(?:\.xz)?\z};
    },
    $destdir,
  );

  ok(@payloads > 0,
    'deep payload from nested archives is present after recursive unpacking');
  is(scalar @leftover_archives, 0,
    'no .tar or .tar.xz files are left behind in destination tree');
};

done_testing;
