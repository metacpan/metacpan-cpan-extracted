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

# install.sh as rendered by `publish.pl render`, run with `sh` against a fake
# release served from a temp dir via <ENV>_BASE_URL=file://...
# No network, no real ~/.local/bin, no real release.

sub in_path { my $n = shift; return scalar grep { -x File::Spec->catfile($_, $n) } File::Spec->path }
plan skip_all => 'curl is needed' unless in_path('curl');
plan skip_all => 'sha256sum or shasum is needed' unless in_path('sha256sum') || in_path('shasum');
plan skip_all => 'sh is needed' unless in_path('sh');

my $root    = abs_path(File::Spec->catdir(dirname(__FILE__), File::Spec->updir));
my $publish = File::Spec->catfile($root, '.github', 'dzil-binary', 'publish.pl');

sub slurp { open my $fh, "<", $_[0] or die "$_[0]: $!"; binmode $fh; local $/; my $c = <$fh>; return defined $c ? $c : "" }
sub spew {
  my ($path, $data) = @_;
  File::Path::make_path(dirname($path));
  open my $fh, '>', $path or die "$path: $!"; binmode $fh; print $fh $data; close $fh;
}
sub listing { my $d = shift; return () unless -d $d; opendir my $dh, $d or die; return sort grep { $_ ne '.' && $_ ne '..' } readdir $dh }

# runs a command with extra env; returns (exit_code, stdout.stderr combined). Never via a shell.
sub run_cmd {
  my ($env, @cmd) = @_;
  my $tmp = tempdir(CLEANUP => 1);
  my $o = "$tmp/out";
  my $pid = fork // die "fork: $!";
  if (!$pid) {
    my %e = %$env;
    my $cwd = delete $e{_cwd}; my $stdin = delete $e{_stdin};
    delete $ENV{$_} for grep { /\AFOO_BAR_/ } keys %ENV;
    $ENV{$_} = $e{$_} for keys %e;
    if (defined $cwd) { chdir $cwd or die "chdir: $!" }
    if (defined $stdin) { spew("$tmp/in", $stdin); open STDIN, '<', "$tmp/in" or die }
    open STDOUT, '>', $o or die; open STDERR, '>&', \*STDOUT or die;
    exec @cmd or die "exec: $!";
  }
  waitpid $pid, 0;
  return ($? >> 8, scalar(slurp($o)));
}

my @ALL = qw( linux-x86_64 linux-arm64 macos-arm64 macos-x86_64 windows-x86_64 );
our @BINS = qw( foo bar );

sub asset { my ($n, $v, $p) = @_; return "$n-$v-$p" . ($p eq 'windows-x86_64' ? '.exe' : '') }

# a META.json for dist Foo-Bar (-> FOO_BAR)
sub write_meta {
  my ($d, $version, $platforms) = @_;
  my $meta = "$d/META.json";
  spew($meta, JSON::PP->new->canonical->encode({
    name => 'Foo-Bar', version => $version,
    x_binaries => {
      platforms => $platforms,
      binaries  => { map { $_ => { script => "bin/$_", modules => [], require => [] } } @BINS },
    },
  }));
  return $meta;
}

# publish.pl render META owner repo tag dir -> dir with install.sh / install.ps1
sub render {
  my ($version, $tag, $platforms) = @_;
  my $d = tempdir(CLEANUP => 1);
  my $meta = write_meta($d, $version, $platforms);
  File::Path::make_path("$d/out");
  my ($rc, $out) = run_cmd({}, $^X, $publish, 'render', $meta, 'acme', 'foo-bar', $tag, "$d/out");
  return ($rc, $out, "$d/out");
}

# a fake release below $rel/download/$tag/ ; binaries log "<platform> <argv>" to $logdir/<name>.log
sub serve {
  my (%o) = @_;
  my $rel = tempdir(CLEANUP => 1);
  my $logdir = tempdir(CLEANUP => 1);
  my $dl = "$rel/download/$o{tag}";
  File::Path::make_path($dl);
  my @sums;
  for my $p (@{ $o{platforms} }) {
    for my $n (@BINS) {
      my $name = asset($n, $o{version}, $p);
      my $body = $o{body} ? $o{body}->($n, $p, $logdir)
        : "#!/bin/sh\necho \"$p \$*\" >> '$logdir/$n.log'\n";
      spew("$dl/$name", $body);
      push @sums, sha256_hex($body) . "  $name\n";
    }
  }
  spew("$dl/SHA256SUMS", join '', @sums);
  return ($rel, $logdir, $dl);
}

# the common case: tag v1.0 / version 1.0, rendered for all five platforms
sub fixture {
  my (%o) = @_;
  my $tag = $o{tag} || 'v1.0';
  my ($rc, $out, $rdir) = render('1.0', $tag, \@ALL);
  is($rc, 0, 'fixture: publish.pl render exits 0') or diag $out;
  my ($rel, $logdir, $dl) = serve(tag => $tag, version => '1.0', platforms => \@ALL, body => $o{body});
  my $home = tempdir(CLEANUP => 1);
  return { rdir => $rdir, rel => $rel, logdir => $logdir, dl => $dl, home => $home, ok => $rc == 0,
           inst => "$home/inst/bin" };
}

sub install {
  my ($f, $args, %env) = @_;
  my %e = (
    HOME => $f->{home},
    FOO_BAR_BASE_URL => "file://$f->{rel}",
    FOO_BAR_INSTALL_DIR => $f->{inst},
    FOO_BAR_PLATFORM => 'linux-x86_64',
    %env,
  );
  delete $e{$_} for grep { !defined $e{$_} } keys %e;
  return run_cmd(\%e, 'sh', "$f->{rdir}/install.sh", @{ $args || [] });
}

# --- render: every placeholder substituted, both scripts written ---------------

{
  my ($rc, $out, $rdir) = render('1.0', 'v1.0', [qw( linux-x86_64 windows-x86_64 )]);
  is($rc, 0, 'render_writes_both: exit 0') or diag $out;
  for my $f (qw( install.sh install.ps1 )) {
    ok(-f "$rdir/$f", "render_writes_both: $f written") or next;
    my $c = slurp("$rdir/$f");
    unlike($c, qr/\@(?:OWNER|REPO|TAG|VERSION|BINARIES|PLATFORMS|ENV|DIST)\@/, "render_no_placeholders_left: $f");
    like($c, qr/FOO_BAR_/, "render_env_prefix: $f uses the FOO_BAR_ environment prefix");
    like($c, qr/\bfoo\b/, "render_binaries: $f knows the binary foo");
    like($c, qr/\bbar\b/, "render_binaries: $f knows the binary bar");
  }
  if (-f "$rdir/install.ps1") {
    my $ps = slurp("$rdir/install.ps1");
    like($ps, qr/Programs\\Foo-Bar/, 'render_ps1_default_dir: install.ps1 defaults to Programs\Foo-Bar (META name)');
    unlike($ps, qr/Programs\\foo-bar/, 'render_ps1_default_dir: not the repo name (foo-bar) in that path');
  }
  if (-f "$rdir/install.sh") {
    like(slurp("$rdir/install.sh"), qr{github\.com/acme/foo-bar/releases}, 'render_default_base_url: install.sh defaults to the GitHub releases URL of owner/repo');
  }
}

# --- install.sh behaviour -------------------------------------------------------

subtest installs_all => sub {
  my $f = fixture(); $f->{ok} or return fail('fixture');
  my ($rc, $out) = install($f);
  is($rc, 0, 'exit 0') or diag $out;
  is_deeply([listing($f->{inst})], [qw( bar foo )], 'both binaries, and nothing else, in INSTALL_DIR');
  for my $n (@BINS) {
    my $p = "$f->{inst}/$n";
    is(-e $p ? (stat $p)[2] & 07777 : -1, 0755, "$n is mode 0755");
    is(slurp($p), "#!/bin/sh\necho \"linux-x86_64 \$*\" >> '$f->{logdir}/$n.log'\n", "$n is the linux-x86_64 asset") if -e $p;
  }
};

subtest installs_selection => sub {
  my $f = fixture(); $f->{ok} or return fail('fixture');
  my ($rc, $out) = install($f, ['bar']);
  is($rc, 0, 'exit 0') or diag $out;
  is_deeply([listing($f->{inst})], ['bar'], 'sh install.sh bar installs only bar');
};

subtest unknown_name => sub {
  my $f = fixture(); $f->{ok} or return fail('fixture');
  my ($rc, $out) = install($f, ['nope']);
  isnt($rc, 0, 'exit != 0');
  like($out, qr/\bfoo\b/, 'output names foo');
  like($out, qr/\bbar\b/, 'output names bar');
  is_deeply([listing($f->{inst})], [], 'nothing installed');
};

for my $broken (qw( foo bar )) {
  subtest "checksum_mismatch ($broken tampered)" => sub {
    my $f = fixture(); $f->{ok} or return fail('fixture');
    my $file = "$f->{dl}/" . asset($broken, '1.0', 'linux-x86_64');
    spew($file, slurp($file) . "# tampered\n");
    my ($rc, $out) = install($f);
    isnt($rc, 0, 'exit != 0');
    like($out, qr/checksum|sha256|mismatch/i, 'output says why');
    is_deeply([listing($f->{inst})], [], 'INSTALL_DIR holds no files at all (no binary, no temp file), whatever the processing order');
    ok(!-e "$f->{logdir}/$_.log", "$_ never ran") for @BINS;
  };

  subtest "failed_download ($broken asset missing)" => sub {
    my $f = fixture(); $f->{ok} or return fail('fixture');
    unlink "$f->{dl}/" . asset($broken, '1.0', 'linux-x86_64') or die;
    my ($rc, $out) = install($f);
    isnt($rc, 0, 'a missing asset -> exit != 0');
    is_deeply([listing($f->{inst})], [], 'INSTALL_DIR holds no files at all (no binary, no temp file), whatever the processing order');
    ok(!-e "$f->{logdir}/$_.log", "$_ never ran") for @BINS;
  };
}

subtest unsupported_platform_names_built_ones => sub {
  my ($rc, $out, $rdir) = render('1.0', 'v1.0', ['linux-x86_64']);
  is($rc, 0, 'render exits 0') or return diag $out;
  my ($rel, $logdir) = serve(tag => 'v1.0', version => '1.0', platforms => ['linux-x86_64']);
  my $home = tempdir(CLEANUP => 1);
  my $f = { rdir => $rdir, rel => $rel, logdir => $logdir, home => $home, inst => "$home/bin" };
  ($rc, $out) = install($f, [], FOO_BAR_PLATFORM => 'windows-x86_64');
  isnt($rc, 0, 'exit != 0');
  like($out, qr/linux-x86_64/, 'output names the built platform linux-x86_64');
  like($out, qr/windows-x86_64/, 'output names the requested platform');
  is_deeply([listing($f->{inst})], [], 'nothing installed');
};

subtest warms_cache => sub {
  my $f = fixture(); $f->{ok} or return fail('fixture');
  my ($rc, $out) = install($f);
  is($rc, 0, 'exit 0') or diag $out;
  is(-e "$f->{logdir}/$_.log" ? slurp("$f->{logdir}/$_.log") : '<never ran>', "linux-x86_64 --help\n",
    "$_ ran exactly once, with --help") for @BINS;
};

subtest creates_install_dir => sub {
  my $f = fixture(); $f->{ok} or return fail('fixture');
  ok(!-e $f->{inst}, 'precondition: INSTALL_DIR absent');
  my ($rc, $out) = install($f);
  is($rc, 0, 'exit 0') or diag $out;
  ok(-d $f->{inst}, 'INSTALL_DIR (with parents) created');
  ok(-x "$f->{inst}/foo", 'and used');
};

subtest path_hint => sub {
  my $f = fixture(); $f->{ok} or return fail('fixture');
  my ($rc, $out) = install($f);
  is($rc, 0, 'exit 0') or diag $out;
  like($out, qr/\bPATH\b/, 'INSTALL_DIR not in PATH -> the output mentions PATH');
  like($out, qr/\Q$f->{inst}\E/, '... and names the directory');

  my $g = fixture(); $g->{ok} or return fail('fixture');
  ($rc, $out) = install($g, [], PATH => "$g->{inst}:$ENV{PATH}");
  is($rc, 0, 'exit 0 with INSTALL_DIR on PATH') or diag $out;
  unlike($out, qr/\bPATH\b/, 'INSTALL_DIR already on PATH -> no PATH hint');
};

subtest version_pin_keeps_tag_prefix => sub {
  for my $case ([ 'v1.0', 'v0.9' ], [ '1.0', '0.9' ]) {
    my ($tag, $pintag) = @$case;
    my ($rc, $out, $rdir) = render('1.0', $tag, ['linux-x86_64']);
    is($rc, 0, "tag $tag: render exits 0") or next;
    my ($rel, $logdir) = serve(tag => $pintag, version => '0.9', platforms => ['linux-x86_64']);
    ok(!-e "$rel/download/$tag", "tag $tag: the rendered release's own directory is not served");
    my $home = tempdir(CLEANUP => 1);
    my $f = { rdir => $rdir, rel => $rel, logdir => $logdir, home => $home, inst => "$home/bin" };
    ($rc, $out) = install($f, [], FOO_BAR_VERSION => '0.9');
    is($rc, 0, "tag $tag: FOO_BAR_VERSION=0.9 downloads from download/$pintag/") or diag $out;
    is_deeply([listing($f->{inst})], [qw( bar foo )], "tag $tag: both installed from the pinned release");
  }
};

subtest platform_detection_maps_uname => sub {
  my ($s, $m) = map { my ($rc, $o) = run_cmd({}, 'uname', $_); $o =~ s/\s+\z//; $o } '-s', '-m';
  my %os   = (Linux => 'linux', Darwin => 'macos');
  my %arch = (x86_64 => 'x86_64', amd64 => 'x86_64', aarch64 => 'arm64', arm64 => 'arm64');
  my $want = $os{$s} && $arch{$m} ? "$os{$s}-$arch{$m}" : '';
  $want = 'windows-x86_64' if $want eq '';   # keeps the assertion below honest
  plan skip_all => "host $s/$m is not a built platform" unless grep { $_ eq $want } @ALL[0 .. 3];
  my $f = fixture(); $f->{ok} or return fail('fixture');
  my ($rc, $out) = install($f, ['foo'], FOO_BAR_PLATFORM => undef);
  is($rc, 0, "detection on, exit 0 ($s $m)") or diag $out;
  is(-e "$f->{logdir}/foo.log" ? slurp("$f->{logdir}/foo.log") : '<never ran>', "$want --help\n",
    "detected platform is $want (uname mapping: Linux->linux, Darwin->macos, x86_64|amd64->x86_64, aarch64|arm64->arm64)");
};

# --- fix round 1 -----------------------------------------------------------------

subtest install_dir_with_space => sub {
  my $f = fixture(); $f->{ok} or return fail('fixture');
  $f->{inst} = "$f->{home}/inst dir";
  my ($rc, $out) = install($f);
  is($rc, 0, 'exit 0') or diag $out;
  is_deeply([listing($f->{inst})], [qw( bar foo )], 'both installed into a directory with a space');

  my $g = fixture(); $g->{ok} or return fail('fixture');
  $g->{inst} = "$g->{home}/inst dir";
  my $foo = "$g->{dl}/" . asset('foo', '1.0', 'linux-x86_64');
  spew($foo, slurp($foo) . "# tampered\n");
  ($rc, $out) = install($g);
  isnt($rc, 0, 'checksum mismatch: exit != 0');
  is_deeply([listing($g->{inst})], [], 'checksum mismatch: INSTALL_DIR holds no files at all, hidden ones included');
};

subtest duplicate_selection => sub {
  my $f = fixture(); $f->{ok} or return fail('fixture');
  my ($rc, $out) = install($f, [qw( foo foo )]);
  is($rc, 0, 'exit 0') or diag $out;
  is_deeply([listing($f->{inst})], ['foo'], 'foo installed, bar not, no leftover files');
  is(-e "$f->{logdir}/foo.log" ? slurp("$f->{logdir}/foo.log") : '<never ran>', "linux-x86_64 --help\n", 'foo handled once (one warm-up run)');
  ok(!-e "$f->{logdir}/bar.log", 'bar never ran');
};

subtest similar_binary_names => sub {
  local @BINS = qw( foo-bar foo_bar );
  my ($rc, $out, $rdir) = render('1.0', 'v1.0', ['linux-x86_64']);
  is($rc, 0, 'render exits 0') or return diag $out;
  my ($rel, $logdir) = serve(tag => 'v1.0', version => '1.0', platforms => ['linux-x86_64']);
  my $home = tempdir(CLEANUP => 1);
  my $f = { rdir => $rdir, rel => $rel, logdir => $logdir, home => $home, inst => "$home/bin" };
  ($rc, $out) = install($f);
  is($rc, 0, 'exit 0') or diag $out;
  is_deeply([listing($f->{inst})], [qw( foo-bar foo_bar )], 'both installed');
  for my $n (@BINS) {
    is(-e "$f->{inst}/$n" ? slurp("$f->{inst}/$n") : '<missing>', "#!/bin/sh\necho \"linux-x86_64 \$*\" >> '$logdir/$n.log'\n", "$n has its own content");
    is(-e "$logdir/$n.log" ? slurp("$logdir/$n.log") : '<never ran>', "linux-x86_64 --help\n", "$n ran once, logging to its own file");
  }
};

subtest glob_selection_not_expanded => sub {
  my $f = fixture(); $f->{ok} or return fail('fixture');
  my $cwd = tempdir(CLEANUP => 1);
  spew("$cwd/foo", "i am a file in cwd\n");
  my ($rc, $out) = install($f, ['f*'], _cwd => $cwd);
  isnt($rc, 0, "'f*' is an unknown name -> exit != 0");
  like($out, qr/\bfoo\b/, 'output names foo');
  like($out, qr/\bbar\b/, 'output names bar');
  is_deeply([listing($f->{inst})], [], 'nothing installed');
};

subtest warmup_stdin_is_empty => sub {
  my $body = sub { my ($n, $p, $logdir) = @_;
    return "#!/bin/sh\nif read -r x; then echo got-input; else echo stdin-empty; fi >> '$logdir/$n.log'\n" };
  my $f = fixture(body => $body); $f->{ok} or return fail('fixture');
  my ($rc, $out) = install($f, [], _stdin => "data\n");
  is($rc, 0, 'exit 0') or diag $out;
  is(-e "$f->{logdir}/$_.log" ? slurp("$f->{logdir}/$_.log") : '<never ran>', "stdin-empty\n", "$_: warm-up run sees an empty stdin") for @BINS;
};

subtest warmup_failure_is_ignored => sub {
  my $body = sub { my ($n, $p, $logdir) = @_; return "#!/bin/sh\necho ran >> '$logdir/$n.log'\nexit 1\n" };
  my $f = fixture(body => $body); $f->{ok} or return fail('fixture');
  my ($rc, $out) = install($f);
  is($rc, 0, 'a binary exiting 1 on --help does not fail the install') or diag $out;
  is_deeply([listing($f->{inst})], [qw( bar foo )], 'both installed');
};

subtest render_rejects_bad_tags => sub {
  for my $case ([ 'r2-1.0', 'prefix contains a digit' ], [ 'v1.1', 'tag does not end with the version' ]) {
    my ($tag, $why) = @$case;
    my ($rc, $out) = render('1.0', $tag, ['linux-x86_64']);
    isnt($rc, 0, "$tag / 1.0 ($why): render exits != 0");
    like($out, qr/\Q$tag\E/, "$tag: message names the tag");
    like($out, qr/1\.0/, "$tag: message names the version");
  }
};

{
  my ($rc, $out, $rdir) = render('1.0', 'v1.0', ['linux-x86_64']);
  if ($rc == 0 && -f "$rdir/install.ps1") {
    like(slurp("$rdir/install.ps1"), qr/\[scriptblock\]::Create/, 'ps1_header: install.ps1 documents the [scriptblock]::Create selection form');
  } else {
    fail('ps1_header: render did not produce install.ps1');
  }
}

done_testing;
