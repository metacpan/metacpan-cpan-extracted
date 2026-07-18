#!perl
#
# Adversarial / robustness coverage: a distro-wide unpacker meets deliberately hostile archives
# (security-tool test suites). It must degrade gracefully - skip the bad item, keep going - never
# crash the whole run, and honour the opt-in resource caps. See File::Unpack2::_safe_unpack, the
# max_files/max_total_bytes/helper_timeout caps, and the lzma --memlimit-decompress hardening.

use strict;
use warnings;
use Test::More;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack2;
use File::Temp qw(tempdir);
use File::Find;
use JSON;

plan skip_all => 'needs Linux /proc' unless -d '/proc' && -r "/proc/$$/fd";
my $have_gzip = -x '/usr/bin/gzip' || -x '/bin/gzip';

sub guarded {
  my ($secs, $code) = @_;
  my $done = eval { local $SIG{ALRM} = sub { die "ALARM\n" }; alarm $secs; $code->(); alarm 0; 1 };
  alarm 0;
  return $done ? 1 : 0;
}

sub write_file { my ($p, $c) = @_; open my $f, '>', $p or die "$p: $!"; print $f $c; close $f }

subtest 'a die in one item is isolated: siblings still unpack, log stays valid JSON' => sub {
  my $src  = tempdir("FU_11s_XXXXXX", TMPDIR => 1, CLEANUP => 1);
  my $dest = tempdir("FU_11d_XXXXXX", TMPDIR => 1, CLEANUP => 1);
  write_file("$src/normal.txt",  "hello world\n");
  write_file("$src/explode.dat", "boom\n");

  my $log;
  my $u = File::Unpack2->new(destdir => $dest, verbose => 0, logfile => \$log);

  # Make one item's mime() die mid-recursion (stands in for a crafted archive that trips a
  # path-escape / rename / assert die). _safe_unpack must confine it to that item.
  no warnings 'redefine';
  my $orig = \&File::Unpack2::mime;
  local *File::Unpack2::mime = sub { my ($s, @a) = @_; die "boom in mime\n" if "@a" =~ /explode/; $orig->($s, @a) };

  my $done = guarded(30, sub { $u->unpack("$src") });
  ok($done, 'unpack() returned despite a dying item');
  is($u->{recursion_level} || 0, 0, 'recursion_level restored to 0 after the caught die');

  my $j = eval { JSON::from_json($log) };
  ok(ref $j eq 'HASH',   'log is still valid JSON (epilog ran)');
  ok(exists $j->{end},   'log has an end timestamp');
  ok((grep {m{normal\.txt$}} keys %{$j->{unpacked}}), 'the sibling normal.txt was still unpacked');
};

subtest 'opt-in max_files cap stops gracefully; unset = no effect' => sub {
  my $src = tempdir("FU_11f_XXXXXX", TMPDIR => 1, CLEANUP => 1);
  write_file("$src/file_$_.txt", "data $_\n") for 1 .. 6;

  my $u1 = File::Unpack2->new(destdir => tempdir(CLEANUP => 1), verbose => 0, logfile => '/dev/null', max_files => 2);
  ok(guarded(30, sub { $u1->unpack("$src") }), 'capped run returned');
  ok($u1->{_capped}, 'max_files cap tripped');

  my $u2 = File::Unpack2->new(destdir => tempdir(CLEANUP => 1), verbose => 0, logfile => '/dev/null');
  ok(guarded(30, sub { $u2->unpack("$src") }), 'uncapped run returned');
  ok(!$u2->{_capped}, 'no cap by default');
  cmp_ok($u2->{file_count}, '>=', 6, 'all files processed when uncapped');
};

subtest 'opt-in max_total_bytes cap stops gracefully' => sub {
  my $src = tempdir("FU_11b_XXXXXX", TMPDIR => 1, CLEANUP => 1);
  write_file("$src/big_$_.txt", "x" x 4096) for 1 .. 6;
  my $u = File::Unpack2->new(destdir => tempdir(CLEANUP => 1), verbose => 0, logfile => '/dev/null', max_total_bytes => 8192);
  ok(guarded(30, sub { $u->unpack("$src") }), 'run returned');
  ok($u->{_capped}, 'max_total_bytes cap tripped');
};

subtest 'opt-in helper_timeout kills even a steadily-progressing helper' => sub {
  plan skip_all => 'need gzip to build a non-text fixture' unless $have_gzip;

  # A helper that writes a growing file for ~5s: it always makes progress, so the no-progress stall
  # watchdog can never stop it - only the absolute helper_timeout can.
  my $argv = [$^X, '-e',
    'open my $f,">","slow.out" or die $!; for (1..20) { syswrite $f, "x"x4096; select undef,undef,undef,0.25 } '
      . 'open my $m,">","slow.done" or die $!; close $m'];

  my $setup = sub {
    my (%opt) = @_;
    my $dest   = tempdir("FU_11hd_XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $srcdir = tempdir("FU_11hs_XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $src    = "$srcdir/payload.gz";
    system('/bin/sh', '-c', "echo hi | gzip -c > '$src'") == 0 or return;
    my $u    = File::Unpack2->new(destdir => $dest, verbose => 0, logfile => '/dev/null', stall_timeout => 0, %opt);
    my $mime = $u->mime($src)->[0];
    return if !defined $mime || $mime eq 'text/plain' || $mime eq '';
    $u->mime_helper($mime, undef, $argv);
    return ($u, $src, $dest);
  };

  my ($u1, $s1, $d1) = $setup->(helper_timeout => 2);
  plan skip_all => 'could not build fixture' unless $u1;
  ok(guarded(30, sub { $u1->unpack($s1) }), 'capped run returned');
  my $done1 = 0; find(sub { $done1 = 1 if $_ eq 'slow.done' }, $d1);
  ok(!$done1, 'helper_timeout killed the progressing helper before it finished');

  my ($u2, $s2, $d2) = $setup->(helper_timeout => 0);
  ok(guarded(30, sub { $u2->unpack($s2) }), 'uncapped run returned');
  my $done2 = 0; find(sub { $done2 = 1 if $_ eq 'slow.done' }, $d2);
  ok($done2, 'without a cap the progressing helper runs to completion');
};

subtest 'a corrupt/truncated archive is survived, not fatal' => sub {
  plan skip_all => 'need gzip' unless $have_gzip;
  my $src = tempdir("FU_11c_XXXXXX", TMPDIR => 1, CLEANUP => 1);
  system('/bin/sh', '-c', "echo hello | gzip -c > '$src/good.gz'") == 0 or plan skip_all => 'gzip failed';
  # truncate to a header-only, undecompressable gz
  open my $g, '+<', "$src/good.gz" or die; truncate $g, 3; close $g;
  write_file("$src/sibling.txt", "still here\n");

  my $log;
  my $u = File::Unpack2->new(destdir => tempdir(CLEANUP => 1), verbose => 0, logfile => \$log);
  ok(guarded(30, sub { $u->unpack("$src") }), 'unpack() survived a corrupt archive');
  my $j = eval { JSON::from_json($log) };
  ok(ref $j eq 'HASH', 'log still valid JSON after a corrupt archive');
  ok((grep {m{sibling\.txt$}} keys %{$j->{unpacked}}), 'sibling file still unpacked');
};

subtest 'lzma-family helpers carry --memlimit-decompress' => sub {
  my $u = File::Unpack2->new(destdir => tempdir(CLEANUP => 1), verbose => 0, logfile => '/dev/null');
  my $h = $u->find_mime_helper('application/xz');
  ok($h, 'an xz helper is registered');
  like($h->{fmt_p} || "@{[ map { @$_ } grep { ref } @{$h->{argvv} || []} ]}",
    qr/--memlimit-decompress/, 'xz helper limits decompress memory');
};

done_testing;
