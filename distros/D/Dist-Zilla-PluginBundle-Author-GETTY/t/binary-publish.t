use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw( tempdir );
use File::Basename qw( dirname );
use File::Path ();
use Cwd qw( abs_path );
use Digest::SHA qw( sha256_hex );
use JSON::PP ();

# publish.pl (expected / sums / check) of the binary release workflow, run as
# `$^X publish.pl ...`; no network, no real release.

my $root   = abs_path(File::Spec->catdir(dirname(__FILE__), File::Spec->updir));
my $script = File::Spec->catfile($root, '.github', 'dzil-binary', 'publish.pl');

sub slurp { open my $fh, "<", $_[0] or die "$_[0]: $!"; binmode $fh; local $/; my $c = <$fh>; return defined $c ? $c : "" }
sub spew {
  my ($path, $data) = @_;
  File::Path::make_path(dirname($path));
  open my $fh, '>', $path or die "$path: $!"; binmode $fh; print $fh $data; close $fh;
}

# (exit_code, stdout, stderr); never through a shell
sub run_script {
  my (@args) = @_;
  my $tmp = tempdir(CLEANUP => 1);
  my ($o, $e) = ("$tmp/out", "$tmp/err");
  my $pid = fork // die "fork: $!";
  if (!$pid) {
    open STDOUT, '>', $o or die; open STDERR, '>', $e or die;
    exec $^X, $script, @args or die "exec: $!";
  }
  waitpid $pid, 0;
  return ($? >> 8, scalar(slurp($o)), scalar(slurp($e)));
}

my @PLAT = qw( linux-x86_64 windows-x86_64 );
my %XB = (
  platforms => [@PLAT],
  binaries  => {
    foo => { script => 'bin/foo', modules => [], require => [] },
    bar => { script => 'bin/bar', modules => [], require => [] },
  },
);
# binaries sorted by name, platforms in Global Constraints order within each
my @EXPECTED = (
  'bar-1.0-linux-x86_64', 'bar-1.0-windows-x86_64.exe',
  'foo-1.0-linux-x86_64', 'foo-1.0-windows-x86_64.exe',
);

sub write_meta {
  my ($d, $xb) = @_;
  my $meta = "$d/META.json";
  spew($meta, JSON::PP->new->canonical->encode({ name => 'Foo-Bar', version => '1.0', x_binaries => $xb || \%XB }));
  return $meta;
}

# a download dir holding every expected binary (+ the tarball), optionally minus some
sub dl_dir {
  my (%o) = @_;
  my $d = tempdir(CLEANUP => 1);
  spew("$d/$_", "content of $_\n") for grep { !$o{without} || $_ ne $o{without} } @EXPECTED;
  spew("$d/Foo-Bar-1.0.tar.gz", "tarball\n");
  return $d;
}

sub release_json {
  my ($prerelease, @assets) = @_;
  return release_full(prerelease => $prerelease, assets => [@assets]);
}

# release JSON with explicit id / created_at / tag_name (any may be omitted)
sub release_full {
  my (%o) = @_;
  my $d = tempdir(CLEANUP => 1);
  spew("$d/release.json", JSON::PP->new->encode({
    prerelease => $o{prerelease} ? JSON::PP::true : JSON::PP::false,
    assets     => [ map { { name => $_ } } @{ $o{assets} || ['Foo-Bar-1.0.tar.gz'] } ],
    (exists $o{id}         ? (id         => $o{id})         : ()),
    (exists $o{created_at} ? (created_at => $o{created_at}) : ()),
    (exists $o{tag_name}   ? (tag_name   => $o{tag_name})   : ()),
  }));
  return "$d/release.json";
}

# the releases/latest response: a hash is encoded, undef is the empty file
# (the workflow's "404, no latest release"), a plain string is written as is
sub latest_json {
  my ($v) = @_;
  my $d = tempdir(CLEANUP => 1);
  spew("$d/latest.json", !defined $v ? '' : ref $v ? JSON::PP->new->encode($v) : $v);
  return "$d/latest.json";
}

ok(-f $script, 'publish.pl exists') or do { diag "missing $script"; };

# --- pure function ----------------------------------------------------------

{
  my $ok = -f $script && eval { require $script; 1 };
  ok($ok, 'publish.pl loads via require without running main()') or diag $@;
  my @names = $ok ? DzilBinary::Publish::expected_names(\%XB, '1.0') : ();
  is_deeply(\@names, \@EXPECTED, 'expected_names(x_binaries, version) returns the expected names in order (binaries sorted, platforms in constraint order)');
}

# --- expected ---------------------------------------------------------------

{ # expected_set_follows_platforms
  my $d = tempdir(CLEANUP => 1);
  my ($rc, $out, $err) = run_script('expected', write_meta($d), '1.0');
  is($rc, 0, 'expected_set_follows_platforms: exit 0') or diag $err;
  my @lines = split /\n/, $out;
  is_deeply(\@lines, \@EXPECTED,
    'expected_set_follows_platforms: bar then foo (sorted), each x [linux-x86_64, windows-x86_64], .exe only on windows, one name per line');

  my $d2 = tempdir(CLEANUP => 1);
  my $meta = write_meta($d2, { %XB, platforms => ['linux-x86_64'] });
  ($rc, $out) = run_script('expected', $meta, '2.5');
  is_deeply([split /\n/, $out], [qw( bar-2.5-linux-x86_64 foo-2.5-linux-x86_64 )],
    'expected_set_follows_platforms: a dist without windows expects no .exe; the version argument is used');
}

# --- check ------------------------------------------------------------------

{ # complete dl-dir, release with only the tarball
  my $d = tempdir(CLEANUP => 1);
  my ($rc, $out, $err) = run_script('check', write_meta($d), '1.0', dl_dir(), release_json(0, 'Foo-Bar-1.0.tar.gz'), latest_json(undef));
  is($rc, 0, 'check_ok: all binaries present, release has only the tarball -> exit 0') or diag "$out$err";
  like($out, qr/^latest=true$/m, 'check_ok: prints latest=true for a normal release');
}

{ # prerelease_is_never_marked_latest
  my $d = tempdir(CLEANUP => 1);
  my ($rc, $out, $err) = run_script('check', write_meta($d), '1.0', dl_dir(), release_json(1, 'Foo-Bar-1.0.tar.gz'), latest_json(undef));
  is($rc, 0, 'prerelease_is_never_marked_latest: exit 0') or diag "$out$err";
  like($out, qr/^latest=false$/m, 'prerelease_is_never_marked_latest: prerelease=true -> latest=false');
  unlike($out, qr/latest=true/, 'prerelease_is_never_marked_latest: no latest=true anywhere');
}

{ # missing_binary_fails
  my $d = tempdir(CLEANUP => 1);
  my $gone = 'bar-1.0-windows-x86_64.exe';
  my ($rc, $out, $err) = run_script('check', write_meta($d), '1.0', dl_dir(without => $gone), release_json(0, 'Foo-Bar-1.0.tar.gz'), latest_json(undef));
  is($rc, 1, 'missing_binary_fails: exit 1') or diag "$out$err";
  like("$out$err", qr/\Q$gone\E/, 'missing_binary_fails: output names the missing binary');
  unlike("$out$err", qr/\bfoo-1\.0-linux-x86_64\b/, 'missing_binary_fails: present binaries are not blamed');
}

{ # refuses_when_any_asset_exists
  my $d = tempdir(CLEANUP => 1);
  my ($rc, $out, $err) = run_script('check', write_meta($d), '1.0', dl_dir(),
    release_json(0, 'Foo-Bar-1.0.tar.gz', 'foo-1.0-linux-x86_64'), latest_json(undef));
  is($rc, 1, 'refuses_when_any_asset_exists: one expected asset already on the release -> exit 1') or diag "$out$err";
  like("$out$err", qr/foo-1\.0-linux-x86_64/, 'refuses_when_any_asset_exists: output names the existing asset');
  unlike($out, qr/latest=true/, 'refuses_when_any_asset_exists: never announces latest=true');
}

# --- check: the latest rule (never roll releases/latest back) ----------------
# 5th argument: the releases/latest response, or an empty file for "404, none".

sub check_latest {
  my ($rel, $latest) = @_;
  my $d = tempdir(CLEANUP => 1);
  return run_script('check', write_meta($d), '1.0', dl_dir(), release_full(%$rel), latest_json($latest));
}

{ # older_release_is_not_marked_latest
  my ($rc, $out, $err) = check_latest(
    { id => 100, created_at => '2026-01-01T00:00:00Z', tag_name => 'v1.0' },
    { id => 200, created_at => '2026-06-01T00:00:00Z', tag_name => 'v2.0' });
  is($rc, 0, 'older_release_is_not_marked_latest: exit 0') or diag "$out$err";
  like($out, qr/^latest=false$/m, 'older_release_is_not_marked_latest: latest is newer -> latest=false');
  unlike($out, qr/latest=true/, 'older_release_is_not_marked_latest: no latest=true anywhere');
  like($err, qr/v2\.0/, 'older_release_is_not_marked_latest: STDERR names the newer tag');
}

{ # newer_release_is_marked_latest
  my ($rc, $out, $err) = check_latest(
    { id => 300, created_at => '2026-09-01T00:00:00Z', tag_name => 'v3.0' },
    { id => 200, created_at => '2026-06-01T00:00:00Z', tag_name => 'v2.0' });
  is($rc, 0, 'newer_release_is_marked_latest: exit 0') or diag "$out$err";
  like($out, qr/^latest=true$/m, 'newer_release_is_marked_latest: latest is older -> latest=true');
  # equal created_at (<=) also counts as latest
  ($rc, $out, $err) = check_latest(
    { id => 301, created_at => '2026-06-01T00:00:00Z' },
    { id => 200, created_at => '2026-06-01T00:00:00Z' });
  like($out, qr/^latest=true$/m, 'newer_release_is_marked_latest: equal created_at -> latest=true') or diag "$out$err";
}

{ # no_latest_release_marks_latest: an empty file is a 404
  my ($rc, $out, $err) = check_latest({ id => 100, created_at => '2026-01-01T00:00:00Z' }, undef);
  is($rc, 0, 'no_latest_release_marks_latest: exit 0') or diag "$out$err";
  like($out, qr/^latest=true$/m, 'no_latest_release_marks_latest: empty latest file -> latest=true');
  # ... and it must not even need created_at on this release
  ($rc, $out) = check_latest({ id => 100 }, undef);
  like($out, qr/^latest=true$/m, 'no_latest_release_marks_latest: empty latest file needs no created_at');
}

{ # same_release_is_marked_latest: same id, even if the dates would say otherwise
  my ($rc, $out, $err) = check_latest(
    { id => 100, created_at => '2026-01-01T00:00:00Z' },
    { id => 100, created_at => '2026-06-01T00:00:00Z' });
  is($rc, 0, 'same_release_is_marked_latest: exit 0') or diag "$out$err";
  like($out, qr/^latest=true$/m, 'same_release_is_marked_latest: same id -> latest=true');
}

{ # prerelease stays false whatever latest says
  my ($rc, $out) = check_latest(
    { id => 300, prerelease => 1, created_at => '2026-09-01T00:00:00Z' },
    { id => 200, created_at => '2026-06-01T00:00:00Z' });
  like($out, qr/^latest=false$/m, 'latest_rule_prerelease: prerelease with an older latest -> latest=false');
}

{ # latest_json_without_created_at_fails
  my ($rc, $out, $err) = check_latest({ id => 100, created_at => '2026-01-01T00:00:00Z' }, { id => 200, tag_name => 'v2.0' });
  is($rc, 1, 'latest_json_without_created_at_fails: latest without created_at -> exit 1') or diag "$out$err";
  unlike($out, qr/latest=true/, 'latest_json_without_created_at_fails: no latest=true');

  ($rc, $out, $err) = check_latest({ id => 100 }, { id => 200, created_at => '2026-06-01T00:00:00Z' });
  is($rc, 1, 'latest_json_without_created_at_fails: this release without created_at (latest present) -> exit 1') or diag "$out$err";

  ($rc, $out, $err) = check_latest({ id => 100, created_at => '2026-01-01T00:00:00Z' }, "this is { not json");
  is($rc, 1, 'latest_json_without_created_at_fails: latest not valid JSON -> exit 1') or diag "$out$err";
  unlike($out, qr/latest=true/, 'latest_json_without_created_at_fails: invalid JSON never announces latest=true');
}

# --- sums -------------------------------------------------------------------

{ # sums_cover_expected_only
  my $dl = dl_dir();
  spew("$dl/stray.txt", "not an asset\n");
  my $d = tempdir(CLEANUP => 1);
  my ($rc, $out, $err) = run_script('sums', $dl);
  is($rc, 0, 'sums_cover_expected_only: exit 0') or diag "$out$err";
  my $file = "$dl/SHA256SUMS";
  ok(-f $file, 'sums_cover_expected_only: writes <dir>/SHA256SUMS') or last;
  my @lines = split /\n/, slurp($file);
  is(scalar @lines, scalar @EXPECTED, 'sums_cover_expected_only: one line per expected binary');
  my %got = map { /\A([0-9a-f]{64})  (\S+)\z/ ? ($2 => $1) : () } @lines;
  is(scalar keys %got, scalar @EXPECTED, 'sums_cover_expected_only: every line is "<sha256>  <name>" (sha256sum format)');
  is_deeply([map { /\A\S+  (\S+)\z/ ? $1 : () } @lines], \@EXPECTED, 'sums_cover_expected_only: exactly the expected names, in expected order');
  is($got{$_}, sha256_hex(slurp("$dl/$_")), "sums_cover_expected_only: correct digest for $_") for @EXPECTED;
  unlike(slurp($file), qr/tar\.gz|stray/, 'sums_cover_expected_only: no tarball or stray file line');
}

done_testing;
