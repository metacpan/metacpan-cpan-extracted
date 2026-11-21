use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw( tempdir );
use File::Basename qw( dirname );
use File::Path ();
use Cwd qw( abs_path );
use Config;
use Digest::SHA qw( sha256_hex );
use JSON::PP ();

# k33: the provenance manifest of the binary release workflow.
#   provenance.pl  merge / verify / artifact
#   facts.sh       machine / plan / smoke (docker and gh are faked)
#   build-leg.sh   provenance
# No network, no real docker/gh, no real release. A missing script fails its
# tests (it never skips them): every test runs the script and checks its exit
# code first.

my $root = abs_path(File::Spec->catdir(dirname(__FILE__), File::Spec->updir));
my $dir  = File::Spec->catdir($root, '.github', 'dzil-binary');
sub script { File::Spec->catfile($dir, shift) }

sub slurp { open my $fh, '<', $_[0] or die "$_[0]: $!"; binmode $fh; local $/; my $c = <$fh>; return defined $c ? $c : '' }
sub spew {
  my ($path, $data, $mode) = @_;
  File::Path::make_path(dirname($path));
  open my $fh, '>', $path or die "$path: $!"; binmode $fh; print $fh $data; close $fh;
  chmod $mode, $path if $mode;
}

# (exit_code, stdout, stderr) of a command; never through a shell.
#   env => { NAME => value | undef (delete) }, cwd => dir
sub run_cmd {
  my ($cmd, %o) = @_;
  my $tmp = tempdir(CLEANUP => 1);
  my ($out, $err) = ("$tmp/out", "$tmp/err");
  my $pid = fork // die "fork: $!";
  if (!$pid) {
    for my $k (keys %{ $o{env} || {} }) {
      if (defined $o{env}{$k}) { $ENV{$k} = $o{env}{$k} } else { delete $ENV{$k} }
    }
    chdir $o{cwd} or die "chdir $o{cwd}: $!" if $o{cwd};
    open STDOUT, '>', $out or die; open STDERR, '>', $err or die;
    exec @$cmd or do { print STDERR "exec @$cmd: $!\n"; exit 127 };
  }
  waitpid $pid, 0;
  return ($? >> 8, scalar slurp($out), scalar slurp($err));
}

sub provenance { run_cmd([$^X, script('provenance.pl'), @_]) }

# The part-file line format: KEY=VALUE, key [a-z][a-z0-9_]*. Returns
# ({ key => [values] }, [malformed lines]).
sub parse_part {
  my ($text) = @_;
  my (%kv, @bad);
  for my $line (split /\n/, $text) {
    if ($line =~ /\A([a-z][a-z0-9_]*)=([^\r\n]*)\z/) { push @{ $kv{$1} }, $2 } else { push @bad, $line }
  }
  return (\%kv, \@bad);
}
sub one { my ($kv, $k) = @_; return $kv->{$k} && @{ $kv->{$k} } == 1 ? $kv->{$k}[0] : undef }

ok(-f script('provenance.pl'), 'provenance.pl exists') or diag 'missing ' . script('provenance.pl');
ok(-f script('facts.sh'),      'facts.sh exists')      or diag 'missing ' . script('facts.sh');
{
  my $ok = -f script('provenance.pl') && eval { require(script('provenance.pl')); 1 };
  ok($ok, 'provenance.pl loads via require without running main()') or diag $@;
}

# --- the fixture: Foo-Bar 1.0, binaries foo and bar, linux-x86_64 + windows-x86_64 ---

my @PLAT = qw( linux-x86_64 windows-x86_64 );
my %XB = (
  platforms => [@PLAT],
  binaries  => {
    foo => { script => 'bin/foo', modules => [], require => [] },
    bar => { script => 'bin/bar', modules => [], require => [] },
  },
);
sub hex40 { substr sha256_hex($_[0]), 0, 40 }
my ($SRC, $TAGOBJ, $RUNSHA, $WF) = map { hex40($_) } qw( source tagobject runsha workflow );
my $WFREPO = 'Getty/p5-dist-zilla-pluginbundle-author-getty';

# legs and smoke cells straight from plan.pl, so the fixture follows the real matrix
my (%LEG, @CELLS);
{
  my $d = tempdir(CLEANUP => 1);
  spew("$d/META.json", JSON::PP->new->encode({ name => 'Foo-Bar', version => '1.0', x_binaries => \%XB }));
  require(script('plan.pl'));
  my %l = map { /\A(\w+)=(.*)\z/ ? ($1 => $2) : () } DzilBinary::Plan::plan("$d/META.json");
  $LEG{ $_->{platform} } = $_ for @{ JSON::PP->new->decode($l{legs}) };
  @CELLS = @{ JSON::PP->new->decode($l{smoke}) };
}
is(scalar @CELLS, 4, 'fixture: plan.pl gives 4 smoke cells (3 linux images + windows), so 8 smoke parts');

sub asset_name { my ($b, $v, $p) = @_; return "$b-$v-$p" . ($p eq 'windows-x86_64' ? '.exe' : '') }

sub machine { my ($p, $os) = @_; return ("${p}os" => $os, "${p}architecture" => 'x86_64', "${p}abi" => 'glibc 2.28',
                                         "${p}kernel" => 'Linux', "${p}kernel_release" => '6.8.0') }

# The fixture as data; tests mutate it, then write_fixture() puts it on disk.
#   plan => [[k,v]...], builds => { platform => [[k,v]...] }, smokes => [ [[k,v]...] ... ]
sub fixture {
  my (%o) = @_;
  my $mode = $o{mode} || 'release';
  my $slot = $mode eq 'release' ? '1.0' : 'probe-' . substr($SRC, 0, 7);
  my %f = (version => $slot, mode => $mode, assets => {}, tarballs => ['Foo-Bar-1.0.tar.gz'], meta_version => '1.0');
  $f{plan} = [
    [kind => 'plan'], [mode => $mode], [tag => $mode eq 'release' ? 'v1.0' : ''], [version_slot => $slot],
    [source_commit => $SRC], [source_tag_object => $mode eq 'release' ? $TAGOBJ : ''],
    [server_url => 'https://github.com'], [repository => 'Getty/Foo-Bar'], [run_id => '4242'], [run_attempt => '1'],
    [event => 'push'], [ref => 'refs/tags/v1.0'], [sha => $RUNSHA],
    [caller_workflow_ref => 'Getty/Foo-Bar/.github/workflows/binaries.yml@refs/tags/v1.0'], [caller_workflow_sha => $RUNSHA],
    [workflow_repository => $WFREPO], [workflow_path => '.github/workflows/dzil-binary.yml'],
    [workflow_ref => "$WFREPO/.github/workflows/dzil-binary.yml\@refs/tags/binary-v1"], [workflow_commit => $WF],
    [bundle_ref_input => ''], [bundle_source => 'workflow'], [bundle_commit => $WF],
  ];
  my %sha;
  for my $b (sort keys %{ $XB{binaries} }) {
    for my $p (@PLAT) {
      my $a = asset_name($b, $slot, $p);
      $f{assets}{$a} = "binary $a\n";
      $sha{$a} = sha256_hex($f{assets}{$a});
    }
  }
  for my $p (@PLAT) {
    my $leg = $LEG{$p};
    my $host = !$leg->{container};
    $f{builds}{$p} = pairs(
      kind => 'build', platform => $p, runner => $leg->{runner}, container => $leg->{container} // '',
      runner_image_os => $host ? 'win25' : '', runner_image_version => $host ? '20261101.1' : '',
      runner_os => $host ? 'Windows' : 'Linux', runner_arch => 'X64', run_attempt => '1', bundle_commit => $WF,
      machine('build_', $host ? 'windows 10.0' : 'almalinux 8.10'),
      perl_version => '5.40.0', perl_archname => 'x86_64-linux', par_packer_version => '1.075',
      macosx_deployment_target => '',
      (map { my $a = asset_name($_, $slot, $p); (binary => "$a $sha{$a}") } sort keys %{ $XB{binaries} }),
    );
  }
  my $i = 0;
  for my $b (sort keys %{ $XB{binaries} }) {
    for my $c (@CELLS) {
      my $a = asset_name($b, $slot, $c->{platform});
      my $linux = $c->{platform} =~ /\Alinux-/;
      my $id = 'sha256:' . sha256_hex("image " . ($c->{image} // ''));
      $f{smokes}[$i++] = pairs(
        kind => 'smoke', platform => $c->{platform}, binary => $b, asset => $a, sha256 => $sha{$a}, smoked => 'true',
        runner => $c->{runner}, runner_image_os => 'ubuntu24', runner_image_version => '20261110.1',
        runner_os => $linux ? 'Linux' : 'Windows', runner_arch => 'X64', run_attempt => '1', bundle_commit => $WF,
        machine('host_', 'ubuntu 24.04'),
        image => $linux ? $c->{image} : '', image_id => $linux ? $id : '', image_platform => $linux ? 'linux/amd64' : '',
        ($linux ? (image_repo_digest => "docker.io/lib\@sha256:" . ('b' x 64), image_repo_digest => "docker.io/lib\@sha256:" . ('a' x 64)) : ()),
        machine('target_', $linux ? 'almalinux 8.10' : 'windows 10.0'),
      );
    }
  }
  return \%f;
}

sub pairs { my @l = @_; my @p; push @p, [splice @l, 0, 2] while @l; return \@p }

sub setp {   # first pair named KEY := VALUE
  my ($pairs, $k, $v) = @_;
  for (@$pairs) { if ($_->[0] eq $k) { $_->[1] = $v; return } }
  die "no key $k";
}
sub find_smoke {
  my ($f, $plat, $bin, $image) = @_;
  for my $s (@{ $f->{smokes} }) {
    my %h = map { $_->[0] => $_->[1] } @$s;
    return $s if $h{platform} eq $plat && $h{binary} eq $bin && (!defined $image || $h{image} eq $image);
  }
  die "no smoke part $plat/$bin";
}
sub all_parts {   # every part of the fixture as ($file => pairs)
  my ($f) = @_;
  my %h = ('plan.txt' => $f->{plan});
  $h{"build-$_.txt"} = $f->{builds}{$_} for keys %{ $f->{builds} };
  my $i = 0;
  $h{ 'smoke-' . $i++ . '.txt' } = $_ for @{ $f->{smokes} };
  return %h;
}

# Writes the fixture; returns the merge argument list.
sub write_fixture {
  my ($f) = @_;
  my $d = tempdir(CLEANUP => 1);
  spew("$d/META.json", JSON::PP->new->canonical->encode({ name => 'Foo-Bar', version => $f->{meta_version}, x_binaries => \%XB }));
  my %parts = all_parts($f);
  spew("$d/parts/$_", join '', map { "$_->[0]=$_->[1]\n" } @{ $parts{$_} }) for keys %parts;
  File::Path::make_path("$d/parts", "$d/assets", "$d/tarball");
  spew("$d/assets/$_", $f->{assets}{$_}) for keys %{ $f->{assets} };
  my $n = 0;
  for my $t (@{ $f->{tarballs} }) {
    my $stage = "$d/stage" . $n++ . '/Foo-Bar-1.0';
    spew("$stage/META.json", JSON::PP->new->canonical->encode({ name => 'Foo-Bar', version => '1.0', x_binaries => \%XB }));
    spew("$stage/lib/Foo/Bar.pm", "package Foo::Bar; 1;\n");
    my ($rc, undef, $err) = run_cmd(['tar', 'czf', "$d/tarball/$t", '-C', dirname($stage), 'Foo-Bar-1.0']);
    die "tar: $err" if $rc;
  }
  return { dir => $d, args => ["$d/META.json", $f->{version}, "$d/parts", "$d/assets", "$d/tarball", '1'] };
}

sub merge { my ($f) = @_; my $w = write_fixture($f); my @r = provenance('merge', @{ $w->{args} }); return (@r, $w) }

# --- merge: the good run ------------------------------------------------------

{
  my $f = fixture();
  my ($rc, $out, $err, $w) = merge($f);
  is($rc, 0, 'merge_ok: exit 0') or diag $err;
  my $m = eval { JSON::PP->new->decode($out) } || {};
  my $canon = $m && %$m ? JSON::PP->new->canonical->pretty->ascii->encode($m) : '';
  is($out, $canon, 'merge_ok: STDOUT is the canonical pretty ascii JSON, with its trailing newline') if length $out;
  ok(length $out, 'merge_ok: STDOUT carries the manifest');
  is($m->{schema_version}, 1, 'merge_ok: schema_version 1');
  is($m->{mode}, 'release', 'merge_ok: mode release');
  is_deeply(
    [ map { [$_->{name}, $_->{sha256}] } @{ $m->{assets} || [] } ],
    [ map { [$_, sha256_hex($f->{assets}{$_})] } 'bar-1.0-linux-x86_64', 'bar-1.0-windows-x86_64.exe', 'foo-1.0-linux-x86_64', 'foo-1.0-windows-x86_64.exe' ],
    'merge_ok: assets in expected_names order with the sha256 of the artifact files');
  is_deeply([ map { $_->{platform} } @{ $m->{builds} || [] } ], [@PLAT], 'merge_ok: two builds in platform order');
  is(scalar @{ $m->{smokes} || [] }, 8, 'merge_ok: eight smokes');
  is_deeply(
    [ map { join '|', $_->{binary}, $_->{platform}, $_->{image} ? $_->{image}{ref} : '-' } @{ $m->{smokes} || [] } ],
    [ map { my $b = $_; map { join '|', $b, $_->{platform}, $_->{image} // '-' } @CELLS } qw( bar foo ) ],
    'merge_ok: smokes by binary, then platform, then image');
  is($m->{run}{run_id}, '4242', 'merge_ok: run.run_id passes through');
  is($m->{run}{attempt}, '1', 'merge_ok: run.attempt is the ATTEMPT argument');
  is($m->{caller}{workflow_sha}, $RUNSHA, 'merge_ok: caller.workflow_sha passes through');
  is($m->{workflow}{commit}, $WF, 'merge_ok: workflow.commit passes through');
  is($m->{workflow}{repository}, $WFREPO, 'merge_ok: workflow.repository passes through');
  is($m->{bundle}{source}, 'workflow', 'merge_ok: bundle.source');
  is($m->{bundle}{commit}, $WF, 'merge_ok: bundle.commit');
  is($m->{source}{commit}, $SRC, 'merge_ok: source.commit');
  is($m->{source}{tag_object}, $TAGOBJ, 'merge_ok: source.tag_object');
  is($m->{source}{tag}, 'v1.0', 'merge_ok: source.tag');
  is($m->{dist}{name}, 'Foo-Bar', 'merge_ok: dist.name from META.json');
  is($m->{dist}{version_slot}, '1.0', 'merge_ok: dist.version_slot');
  is($m->{dist}{tarball}{name}, 'Foo-Bar-1.0.tar.gz', 'merge_ok: dist.tarball.name');
  is($m->{dist}{tarball}{sha256}, sha256_hex(slurp("$w->{dir}/tarball/Foo-Bar-1.0.tar.gz")), 'merge_ok: dist.tarball.sha256 is the tarball\'s own hash');
  my ($lin, $win) = @{ $m->{builds} || [{}, {}] };
  is($lin->{container}, $LEG{'linux-x86_64'}{container}, 'merge_ok: linux build container');
  ok(!defined $win->{container}, 'merge_ok: windows build container is null');
  is($lin->{machine}{abi}, 'glibc 2.28', 'merge_ok: builds[].machine.abi');
  is($lin->{perl}{version}, '5.40.0', 'merge_ok: builds[].perl.version');
  is($win->{runner_image}{version}, '20261101.1', 'merge_ok: host build runner_image.version');
  ok(!defined $lin->{runner_image} || !defined $lin->{runner_image}{os}, 'merge_ok: container build leg has no runner image');
  my ($s) = grep { $_->{platform} eq 'linux-x86_64' && ($_->{image} || {})->{ref} eq 'almalinux:8' && $_->{binary} eq 'foo' } @{ $m->{smokes} || [] };
  $s ||= {};
  ok($s->{smoked}, 'merge_ok: smoked is true');
  is($s->{image}{id}, 'sha256:' . sha256_hex('image almalinux:8'), 'merge_ok: smokes[].image.id');
  is_deeply($s->{image}{repo_digests}, [ map { "docker.io/lib\@sha256:" . ($_ x 64) } qw( a b ) ], 'merge_ok: repo_digests sorted');
  is($s->{target}{os}, 'almalinux 8.10', 'merge_ok: linux smoke target comes from the in-image run');
  is($s->{host}{os}, 'ubuntu 24.04', 'merge_ok: smoke host');
  my ($ws) = grep { $_->{platform} eq 'windows-x86_64' } @{ $m->{smokes} || [] };
  ok(!defined(($ws || {})->{image}), 'merge_ok: windows smoke has no image');
}

# --- merge: the other good runs -----------------------------------------------

{
  my ($rc, $out, $err) = merge(fixture(mode => 'probe'));
  is($rc, 0, 'merge_probe: a probe fixture (slot probe-<7 hex of the source commit>) merges') or diag $err;
  my $m = eval { JSON::PP->new->decode($out) } || {};
  is($m->{mode}, 'probe', 'merge_probe: mode probe');
  is($m->{dist}{version_slot}, 'probe-' . substr($SRC, 0, 7), 'merge_probe: version_slot');
}
{ # an explicit bundle_ref wins: its commit need not be the workflow's
  my $f = fixture();
  my $other = hex40('explicit');
  setp($f->{plan}, bundle_source => 'input'); setp($f->{plan}, bundle_ref_input => 'main'); setp($f->{plan}, bundle_commit => $other);
  setp($_, bundle_commit => $other) for values %{ $f->{builds} }, @{ $f->{smokes} };
  my ($rc, $out, $err) = merge($f);
  is($rc, 0, 'merge_input_source: bundle_source=input may differ from the workflow commit') or diag $err;
}
{ # D2: a container leg has no runner image
  my $f = fixture();
  is_deeply([ grep { $_->[0] =~ /\Arunner_image/ } @{ $f->{builds}{'linux-x86_64'} } ], [[runner_image_os => ''], [runner_image_version => '']],
    'merge_container_null_image: (fixture) the container leg carries empty runner_image_*');
  my ($rc, $out, $err) = merge($f);
  is($rc, 0, 'merge_container_null_image: empty runner_image on a container leg passes') or diag $err;
}

# --- merge: one failure per check ------------------------------------------------

sub fails {
  my ($label, $mut, @culprit) = @_;
  my $f = fixture();
  $mut->($f);
  my ($rc, $out, $err) = merge($f);
  is($rc, 1, "merge_fails($label): exit 1") or diag "stdout: $out\nstderr: $err";
  is($out, '', "merge_fails($label): nothing on STDOUT");
  like($err, $_, "merge_fails($label): STDERR names the culprit $_") for @culprit;
}

fails('tampered artifact', sub { $_[0]{assets}{'foo-1.0-linux-x86_64'} .= 'tampered' }, qr/foo-1\.0-linux-x86_64/);
fails('build hash differs from the artifact', sub {
  my @b = grep { $_->[0] eq 'binary' && $_->[1] =~ /^foo-1\.0-windows/ } @{ $_[0]{builds}{'windows-x86_64'} };
  $b[0][1] = 'foo-1.0-windows-x86_64.exe ' . ('0' x 64);
}, qr/foo-1\.0-windows-x86_64\.exe/);
fails('smoke hash differs from the build hash', sub {
  setp(find_smoke($_[0], 'windows-x86_64', 'foo'), sha256 => '1' x 64);
}, qr/foo-1\.0-windows-x86_64\.exe/);
fails('missing smoke cell', sub {
  my $s = find_smoke($_[0], 'windows-x86_64', 'foo');
  @{ $_[0]{smokes} } = grep { $_ != $s } @{ $_[0]{smokes} };
}, qr/windows/, qr/foo/);
fails('duplicate smoke cell', sub {
  my $s = find_smoke($_[0], 'windows-x86_64', 'foo');
  push @{ $_[0]{smokes} }, [ map { [@$_] } @$s ];
}, qr/windows/, qr/foo/);
fails('extra smoke cell', sub {
  my $s = find_smoke($_[0], 'linux-x86_64', 'foo', 'almalinux:8');
  my @c = map { [@$_] } @$s;
  setp(\@c, image => 'alpine:3');
  push @{ $_[0]{smokes} }, \@c;
}, qr/alpine/);
fails('missing build part', sub { delete $_[0]{builds}{'windows-x86_64'} }, qr/windows-x86_64/);
fails('build part lacks a binary', sub {
  $_[0]{builds}{'windows-x86_64'} = [ grep { !($_->[0] eq 'binary' && $_->[1] =~ /^bar-/) } @{ $_[0]{builds}{'windows-x86_64'} } ];
}, qr/bar|windows-x86_64/);
fails('wrong container', sub { setp($_[0]{builds}{'linux-x86_64'}, container => 'almalinux:9') }, qr/linux-x86_64|container/);
fails('wrong runner', sub { setp($_[0]{builds}{'windows-x86_64'}, runner => 'windows-2019') }, qr/windows-x86_64|runner/);
{
  my $foreign = hex40('foreign');
  fails('foreign bundle_commit', sub { setp(find_smoke($_[0], 'windows-x86_64', 'bar'), bundle_commit => $foreign) }, qr/bundle_commit|\Q$foreign\E/);
  fails('foreign bundle_commit in a build part', sub { setp($_[0]{builds}{'linux-x86_64'}, bundle_commit => $foreign) }, qr/bundle_commit|\Q$foreign\E/);
  fails('workflow source, different commit', sub {
    my $f = shift;
    setp($f->{plan}, bundle_commit => $foreign);
    setp($_, bundle_commit => $foreign) for values %{ $f->{builds} }, @{ $f->{smokes} };
  }, qr/bundle|workflow/);
}
fails('non-hex workflow_commit', sub {
  setp($_[0]{plan}, workflow_commit => 'binary-v1'); setp($_[0]{plan}, bundle_commit => 'binary-v1');
  setp($_, bundle_commit => 'binary-v1') for values %{ $_[0]{builds} }, @{ $_[0]{smokes} };
}, qr/commit/);
fails('non-hex source_commit', sub { setp($_[0]{plan}, source_commit => 'HEAD') }, qr/source_commit|commit/);
fails('unknown key', sub { push @{ $_[0]{builds}{'linux-x86_64'} }, [bogus_key => 'x'] }, qr/bogus_key/);
fails('CR in a value', sub { setp($_[0]{builds}{'linux-x86_64'}, build_os => "almalinux\r") }, qr/build-linux-x86_64\.txt|build_os/);
fails('repeated scalar', sub { push @{ $_[0]{plan} }, [tag => 'v1.0'] }, qr/\btag\b|plan\.txt/);
fails('two plan parts', sub { $_[0]{builds}{'extra'} = [ map { [@$_] } @{ $_[0]{plan} } ] }, qr/plan/i);
fails('slot mismatch', sub { setp($_[0]{plan}, version_slot => '1.1') }, qr/version_slot|1\.1/);
fails('tag does not end with the version', sub { setp($_[0]{plan}, tag => 'v1.1') }, qr/\btag\b|v1\.1/);
fails('no tarball', sub { $_[0]{tarballs} = [] }, qr/tarball/i);
fails('two tarballs', sub { $_[0]{tarballs} = ['Foo-Bar-1.0.tar.gz', 'Foo-Bar-1.0-b.tar.gz'] }, qr/tarball/i);
fails('host smoke without runner_image_version', sub { setp(find_smoke($_[0], 'windows-x86_64', 'foo'), runner_image_version => '') }, qr/runner_image_version/);
fails('host build without runner_image_os', sub { setp($_[0]{builds}{'windows-x86_64'}, runner_image_os => '') }, qr/runner_image_os/);

# --- verify ------------------------------------------------------------------

{
  my $f = fixture();
  my $w = write_fixture($f);
  my ($rc, undef, $err) = run_cmd([$^X, script('publish.pl'), 'sums', "$w->{dir}/assets"]);
  is($rc, 0, 'verify setup: publish.pl sums over the fixture assets') or diag $err;
  my $sums = "$w->{dir}/assets/SHA256SUMS";
  my @names = ('bar-1.0-linux-x86_64', 'bar-1.0-windows-x86_64.exe', 'foo-1.0-linux-x86_64', 'foo-1.0-windows-x86_64.exe');

  my $manifest = sub {
    my (%over) = @_;
    my $m = { schema_version => 1, mode => 'release', source => { tag => 'v1.0' }, dist => { version_slot => '1.0' },
      assets => [ map { { name => $_, sha256 => sha256_hex($f->{assets}{$_}) } } @names ] };
    $m->{$_} = $over{$_} for keys %over;
    my $p = tempdir(CLEANUP => 1) . '/provenance.json';
    spew($p, JSON::PP->new->canonical->pretty->encode($m));
    return $p;
  };
  my $sums_with = sub {
    my ($edit) = @_;
    my $t = slurp($sums); local $_ = $t; $edit->(); my $p = tempdir(CLEANUP => 1) . '/SHA256SUMS'; spew($p, $_); return $p;
  };

  ($rc, my $out, $err) = provenance('verify', $manifest->(), $sums, 'v1.0', '1.0');
  is($rc, 0, 'verify_ok: a manifest matching publish.pl sums passes') or diag $err;
  is($out, '', 'verify_ok: nothing on STDOUT');

  my $bad = sub {
    my ($label, $rcx, $outx, $errx, $culprit) = @_;
    is($rcx, 1, "verify_fails($label): exit 1");
    is($outx, '', "verify_fails($label): nothing on STDOUT");
    like($errx, $culprit, "verify_fails($label): STDERR names the culprit");
  };
  my $m2 = $manifest->();
  { # changed hash
    my $m = JSON::PP->new->decode(slurp($m2)); $m->{assets}[2]{sha256} = '0' x 64;
    my $p = tempdir(CLEANUP => 1) . '/p.json'; spew($p, JSON::PP->new->canonical->encode($m));
    $bad->('changed hash', provenance('verify', $p, $sums, 'v1.0', '1.0'), qr/foo-1\.0-linux-x86_64/);
  }
  { # extra line in SHA256SUMS
    my $s = $sums_with->(sub { $_ .= ('c' x 64) . "  zed-1.0-linux-x86_64\n" });
    $bad->('extra line', provenance('verify', $manifest->(), $s, 'v1.0', '1.0'), qr/zed-1\.0-linux-x86_64/);
  }
  { # missing line in SHA256SUMS
    my $s = $sums_with->(sub { $_ = join '', grep { !/bar-1\.0-windows/ } split /^/m });
    $bad->('missing line', provenance('verify', $manifest->(), $s, 'v1.0', '1.0'), qr/bar-1\.0-windows-x86_64\.exe/);
  }
  $bad->('wrong tag', provenance('verify', $manifest->(), $sums, 'v2.0', '1.0'), qr/tag|v2\.0/);
  $bad->('wrong version', provenance('verify', $manifest->(), $sums, 'v1.0', '2.0'), qr/version|2\.0/);
  $bad->('probe-mode manifest', provenance('verify', $manifest->(mode => 'probe'), $sums, 'v1.0', '1.0'), qr/mode|probe/);
  $bad->('schema 2', provenance('verify', $manifest->(schema_version => 2), $sums, 'v1.0', '1.0'), qr/schema/);
}

# --- artifact ----------------------------------------------------------------

{
  my $d = tempdir(CLEANUP => 1);
  spew("$d/META.json", JSON::PP->new->encode({ name => 'Foo-Bar', x_binaries => \%XB }));
  my ($rc, $out, $err) = provenance('artifact', "$d/META.json", '1.0');
  is($rc, 0, 'artifact_name: exit 0') or diag $err;
  is($out, "Foo-Bar-1.0.provenance\n", 'artifact_name: <name>-<version>.provenance');
  unlike($out, qr/-provenance/, 'artifact_name: never <dist>-<version>-provenance (that one matches the assets download pattern)');
  for my $bad (['bad name', 'Foo Bar', '1.0'], ['slash in name', 'Foo/Bar', '1.0'], ['bad version', 'Foo-Bar', '1.0 beta'], ['shell char', 'Foo$Bar', '1.0']) {
    my ($l, $n, $v) = @$bad;
    spew("$d/m2.json", JSON::PP->new->encode({ name => $n, x_binaries => \%XB }));
    ($rc, $out, $err) = provenance('artifact', "$d/m2.json", $v);
    is($rc, 1, "artifact_refuses($l): exit 1");
    is($out, '', "artifact_refuses($l): nothing on STDOUT");
  }
  ($rc) = provenance('bogus');
  is($rc, 1, 'usage: an unknown command exits 1');
}

# --- facts.sh ----------------------------------------------------------------

sub facts { my ($env, @args) = @_; return run_cmd(['sh', script('facts.sh'), @args], env => $env) }

{ # machine
  my ($rc, $out, $err) = facts({}, 'machine', 'x_');
  is($rc, 0, 'facts_machine: exit 0') or diag $err;
  my ($kv, $bad) = parse_part($out);
  is_deeply([sort keys %$kv], [sort map { "x_$_" } qw( os architecture abi kernel kernel_release )], 'facts_machine: exactly the five x_ keys');
  is_deeply($bad, [], 'facts_machine: every line is KEY=VALUE');
  chomp(my $uname_m = `uname -m`); chomp(my $uname_s = `uname -s`);
  is(one($kv, 'x_architecture'), $uname_m, 'facts_machine: architecture is uname -m');
  is(one($kv, 'x_kernel'), $uname_s, 'facts_machine: kernel is uname -s');
  ok(length(one($kv, 'x_os') // ''), 'facts_machine: os is not empty here');
}
{ # no getconf on PATH: abi may be empty, the run never fails
  my $bin = tempdir(CLEANUP => 1);
  my %seen;
  for my $p (grep { length && -d } File::Spec->path) {
    opendir my $dh, $p or next;
    for my $n (readdir $dh) {
      next if $n eq 'getconf' || $seen{$n}++ || -e "$bin/$n";
      symlink "$p/$n", "$bin/$n" if -x "$p/$n" && !-d "$p/$n";
    }
  }
  ok(!-e "$bin/getconf", 'facts_machine_nogetconf: the restricted PATH has no getconf');
  my ($rc, $out, $err) = run_cmd(['sh', script('facts.sh'), 'machine', 'x_'], env => { PATH => $bin });
  is($rc, 0, 'facts_machine_nogetconf: exit 0 without getconf') or diag $err;
  my ($kv) = parse_part($out);
  is_deeply([sort keys %$kv], [sort map { "x_$_" } qw( os architecture abi kernel kernel_release )], 'facts_machine_nogetconf: still the five keys');
}

# fake docker and gh, as perl scripts on a PATH directory
my $fakes = tempdir(CLEANUP => 1);
spew("$fakes/docker", <<"PERL", 0755);
#!$^X
use strict; use warnings; use JSON::PP;
if (defined \$ENV{FAKE_LOG}) { open my \$l, '>>', \$ENV{FAKE_LOG} or die; print \$l join(' ', \@ARGV), "\\n"; close \$l }
my \@a = \@ARGV;
shift \@a if \@a && \$a[0] eq 'image';
if (\@a && \$a[0] eq 'inspect') {
  exit 1 if \$ENV{FAKE_INSPECT_FAIL};
  my \@dig = split /,/, (\$ENV{FAKE_DIGESTS} // '');
  my %img = (Id => \$ENV{FAKE_IMAGE_ID}, Os => 'linux', Architecture => 'amd64', Variant => '', RepoDigests => \\\@dig);
  my \$fmt;
  for my \$i (0 .. \$#a) { \$fmt = \$a[\$i + 1] if \$a[\$i] =~ /\\A(?:-f|--format)\\z/; \$fmt = \$1 if \$a[\$i] =~ /\\A--format=(.*)\\z/s }
  unless (defined \$fmt) { print JSON::PP->new->pretty->canonical->encode([\\%img]); exit 0 }
  \$fmt =~ s/\\{\\{range \\.RepoDigests\\}\\}(.*?)\\{\\{end\\}\\}/join '', map { my \$d = \$_; (my \$b = \$1) =~ s{\\{\\{println \\.\\}\\}}{\$d\\n}g; \$b =~ s{\\{\\{\\.\\}\\}}{\$d}g; \$b =~ s{\\{\\{"\\\\n"\\}\\}}{\\n}g; \$b } \@dig/gse;
  \$fmt =~ s/\\{\\{json \\.\\}\\}/JSON::PP->new->canonical->encode(\\%img)/ge;
  \$fmt =~ s/\\{\\{json \\.(\\w+)\\}\\}/JSON::PP->new->allow_nonref->canonical->encode(\$img{\$1})/ge;
  \$fmt =~ s/\\{\\{join \\.RepoDigests "(.*?)"\\}\\}/join \$1, \@dig/ge;
  \$fmt =~ s/\\{\\{index \\.RepoDigests (\\d+)\\}\\}/\$dig[\$1] \\/\\/ ''/ge;
  \$fmt =~ s/\\{\\{\\.(\\w+)\\}\\}/\$img{\$1} \\/\\/ ''/ge;
  \$fmt =~ s/\\{\\{"\\\\n"\\}\\}/\\n/g;
  if (\$fmt =~ /\\{\\{/) { print STDERR "fake docker: unsupported --format template: \$fmt\\n"; exit 2 }
  print \$fmt, (\$fmt =~ /\\n\\z/ ? '' : "\\n");
  exit 0;
}
if (\@a && \$a[0] eq 'run') {
  my \@t = ('target_os=almalinux 8.10', 'target_architecture=x86_64', 'target_abi=glibc 2.28', 'target_kernel=Linux', 'target_kernel_release=6.8.0');
  print "\$_\\n" for \@t;
  exit 0;
}
exit 1;
PERL
spew("$fakes/gh", <<"PERL", 0755);
#!$^X
use strict; use warnings; use JSON::PP;
if (defined \$ENV{FAKE_LOG}) { open my \$l, '>>', \$ENV{FAKE_LOG} or die; print \$l join(' ', \@ARGV), "\\n"; close \$l }
my \@a = \@ARGV;
shift \@a if \@a && \$a[0] eq 'api';
my (\$ep, \$jq);
while (\@a) {
  my \$x = shift \@a;
  if (\$x =~ /\\A(?:-H|--header|-X|--method|-f|-F|--hostname|--cache)\\z/) { shift \@a }
  elsif (\$x =~ /\\A(?:-q|--jq)\\z/) { \$jq = shift \@a }
  elsif (\$x =~ /\\A--jq=(.*)\\z/s) { \$jq = \$1 }
  elsif (\$x =~ /\\A-/) { }
  else { \$ep //= \$x }
}
die "fake gh: no endpoint\\n" unless defined \$ep;
\$ep =~ s{\\A/}{};
(my \$file = "\$ENV{FAKE_GH}/\$ep.json") =~ s{(?<=\\A\$ENV{FAKE_GH}/)(.*)\\.json\\z}{ (my \$n = \$1) =~ s{/}{_}g; "\$n.json" }e;
unless (-f \$file) { print STDERR "gh: Not Found (HTTP 404)\\n"; exit 1 }
open my \$fh, '<', \$file or die; my \$json = do { local \$/; <\$fh> };
my \$data = JSON::PP->new->decode(\$json);
unless (defined \$jq) { print JSON::PP->new->canonical->encode(\$data), "\\n"; exit 0 }
sub path { my (\$p) = \@_; my \$v = \$data; for my \$k (grep { length } split /\\./, \$p) { \$v = ref \$v eq 'HASH' ? \$v->{\$k} : undef } return defined \$v ? \$v : '' }
my \$out;
if (\$jq =~ /\\A"(.*)"\\z/s)   { (\$out = \$1) =~ s/\\\\\\(([.\\w]+)\\)/path(\$1)/ge }
elsif (\$jq =~ /\\A[.\\w]+\\z/) { \$out = path(\$jq) }
elsif (\$jq =~ /\\A(?:\\S+|"[^"]*")(?:\\s+\\+\\s+(?:\\S+|"[^"]*"))+\\z/) {
  \$out = join '', map { /\\A"(.*)"\\z/s ? \$1 : path(\$_) } split /\\s+\\+\\s+/, \$jq;
}
else { print STDERR "fake gh: unsupported --jq expression: \$jq\\n"; exit 2 }
print "\$out\\n";
PERL

sub fake_env {
  my (%e) = @_;
  my $log = tempdir(CLEANUP => 1) . '/calls.log';
  return ({ PATH => "$fakes:$ENV{PATH}", FAKE_LOG => $log, %e }, $log);
}

{ # smoke, linux, with SMOKE set
  my $d = tempdir(CLEANUP => 1);
  spew("$d/bins/foo-1.0-linux-x86_64", "the binary\n");
  my $id = 'sha256:' . ('d' x 64);
  my @dig = ('docker.io/lib@sha256:' . ('b' x 64), 'docker.io/lib@sha256:' . ('a' x 64));
  my ($env, $log) = fake_env(FAKE_IMAGE_ID => $id, FAKE_DIGESTS => join(',', @dig),
    PLATFORM => 'linux-x86_64', BIN_NAME => 'foo', ASSET => 'foo-1.0-linux-x86_64', SMOKE => 'foo --version',
    IMAGE => 'almalinux:8', RUNNER_LABEL => 'ubuntu-24.04', BUNDLE_COMMIT => $WF, GITHUB_RUN_ATTEMPT => '1',
    ImageOS => 'ubuntu24', ImageVersion => '20261110.1', RUNNER_OS => 'Linux', RUNNER_ARCH => 'X64');
  my ($rc, $out, $err) = facts($env, 'smoke', "$d/smoke-0.txt", "$d/bins/foo-1.0-linux-x86_64");
  is($rc, 0, 'facts_smoke: exit 0') or diag $err;
  my ($kv, $bad) = parse_part(-f "$d/smoke-0.txt" ? slurp("$d/smoke-0.txt") : '');
  is_deeply($bad, [], 'facts_smoke: every line of the part is KEY=VALUE');
  is(one($kv, 'kind'), 'smoke', 'facts_smoke: kind=smoke');
  is(one($kv, $_->[0]), $_->[1], "facts_smoke: $_->[0]") for
    [platform => 'linux-x86_64'], [binary => 'foo'], [asset => 'foo-1.0-linux-x86_64'], [smoked => 'true'],
    [sha256 => sha256_hex("the binary\n")], [runner => 'ubuntu-24.04'], [bundle_commit => $WF], [run_attempt => '1'],
    [runner_image_os => 'ubuntu24'], [runner_image_version => '20261110.1'], [runner_os => 'Linux'], [runner_arch => 'X64'],
    [image => 'almalinux:8'], [image_id => $id], [image_platform => 'linux/amd64'],
    [target_os => 'almalinux 8.10'], [target_architecture => 'x86_64'], [target_abi => 'glibc 2.28'], [target_kernel => 'Linux'];
  is_deeply([sort @{ $kv->{image_repo_digest} || [] }], [sort @dig], 'facts_smoke: image_repo_digest repeats once per digest');
  ok(exists $kv->{$_}, "facts_smoke: $_ is written") for map { "host_$_" } qw( os architecture abi kernel kernel_release );
  my $calls = -f $log ? slurp($log) : '';
  like($calls, qr/inspect/, 'facts_smoke: docker image inspect was asked');
  like($calls, qr/\brun\b.*\Q$id\E/, 'facts_smoke: the in-image facts run uses the image id, not the tag');
  like($calls, qr/machine/, 'facts_smoke: the in-image run is `facts.sh machine ...`');
  like($calls, qr/target_/, 'facts_smoke: ... with the target_ prefix');
}
{ # smoke without a smoke command: no docker call at all
  my $d = tempdir(CLEANUP => 1);
  spew("$d/bins/foo-1.0-linux-x86_64", "the binary\n");
  my ($env, $log) = fake_env(PLATFORM => 'linux-x86_64', BIN_NAME => 'foo', ASSET => 'foo-1.0-linux-x86_64', SMOKE => '',
    IMAGE => 'almalinux:8', RUNNER_LABEL => 'ubuntu-24.04', BUNDLE_COMMIT => $WF, GITHUB_RUN_ATTEMPT => '1',
    ImageOS => 'ubuntu24', ImageVersion => '20261110.1', RUNNER_OS => 'Linux', RUNNER_ARCH => 'X64');
  my ($rc, $out, $err) = facts($env, 'smoke', "$d/smoke-0.txt", "$d/bins/foo-1.0-linux-x86_64");
  is($rc, 0, 'facts_smoke_false: exit 0') or diag $err;
  my ($kv) = parse_part(-f "$d/smoke-0.txt" ? slurp("$d/smoke-0.txt") : '');
  is(one($kv, 'smoked'), 'false', 'facts_smoke_false: smoked=false');
  is(one($kv, 'sha256'), sha256_hex("the binary\n"), 'facts_smoke_false: the binary is hashed all the same');
  is($kv->{$_} ? $kv->{$_}[0] : '', '', "facts_smoke_false: $_ is null") for qw( image image_id target_os );
  ok(!-e $log, 'facts_smoke_false: docker was not called');
}
{ # smoke: inspect failing is a failure
  my $d = tempdir(CLEANUP => 1);
  spew("$d/bins/foo-1.0-linux-x86_64", "the binary\n");
  my ($env) = fake_env(FAKE_INSPECT_FAIL => 1, PLATFORM => 'linux-x86_64', BIN_NAME => 'foo', ASSET => 'foo-1.0-linux-x86_64',
    SMOKE => 'foo --version', IMAGE => 'almalinux:8', RUNNER_LABEL => 'ubuntu-24.04', BUNDLE_COMMIT => $WF, GITHUB_RUN_ATTEMPT => '1',
    ImageOS => 'ubuntu24', ImageVersion => '1', RUNNER_OS => 'Linux', RUNNER_ARCH => 'X64');
  my ($rc) = facts($env, 'smoke', "$d/smoke-0.txt", "$d/bins/foo-1.0-linux-x86_64");
  is($rc, 1, 'facts_smoke_inspect_fails: docker image inspect failing makes facts.sh exit 1');
}
{ my ($rc) = facts({}, 'bogus'); is($rc, 1, 'facts_usage: an unknown subcommand exits 1') }

# plan: gh is faked, the tag chain comes from canned API answers
sub gh_dir {
  my (%ep) = @_;   # endpoint => data
  my $d = tempdir(CLEANUP => 1);
  for my $e (keys %ep) { (my $n = $e) =~ s{/}{_}g; spew("$d/$n.json", JSON::PP->new->encode($ep{$e})) }
  return $d;
}
sub plan_env {
  my (%e) = @_;
  # the superset of names the design leaves open for BUNDLE_*/WORKFLOW_*/CALLER_*
  return (
    TAG => 'v1.0', VERSION_SLOT => '1.0', GH_TOKEN => 'x',
    GITHUB_SERVER_URL => 'https://github.com', GITHUB_REPOSITORY => 'Getty/Foo-Bar', GITHUB_RUN_ID => '4242',
    GITHUB_RUN_ATTEMPT => '1', GITHUB_EVENT_NAME => 'push', GITHUB_REF => 'refs/tags/v1.0', GITHUB_SHA => $RUNSHA,
    CALLER_WORKFLOW_REF => 'Getty/Foo-Bar/.github/workflows/binaries.yml@refs/tags/v1.0', CALLER_WORKFLOW_SHA => $RUNSHA,
    WORKFLOW_REPOSITORY => $WFREPO, WORKFLOW_PATH => '.github/workflows/dzil-binary.yml', WORKFLOW_FILE_PATH => '.github/workflows/dzil-binary.yml',
    WORKFLOW_REF => 'x@refs/tags/binary-v1', WORKFLOW_SHA => $WF, WORKFLOW_COMMIT => $WF,
    BUNDLE_REF_INPUT => '', BUNDLE_REF => '', BUNDLE_SOURCE => 'workflow', BUNDLE_COMMIT => $WF,
    %e);
}
sub plan_run {
  my ($gh, %e) = @_;
  my $d = tempdir(CLEANUP => 1);
  my ($env, $log) = fake_env(FAKE_GH => $gh, plan_env(%e));
  my ($rc, $out, $err) = facts($env, 'plan', "$d/plan.txt");
  my ($kv, $bad) = parse_part(-f "$d/plan.txt" ? slurp("$d/plan.txt") : '');
  return ($rc, $kv, $bad, $err, $log);
}
my $TAGGED = hex40('tagged');

{ # annotated tag: ref -> tag object -> commit
  my $gh = gh_dir(
    'repos/Getty/Foo-Bar/git/ref/tags/v1.0' => { object => { type => 'tag', sha => $TAGOBJ } },
    "repos/Getty/Foo-Bar/git/tags/$TAGOBJ"  => { object => { type => 'commit', sha => $TAGGED } },
  );
  my ($rc, $kv, $bad, $err) = plan_run($gh);
  is($rc, 0, 'facts_plan_annotated: exit 0') or diag $err;
  is_deeply($bad, [], 'facts_plan_annotated: every line is KEY=VALUE');
  is(one($kv, 'kind'), 'plan', 'facts_plan_annotated: kind=plan');
  is(one($kv, 'mode'), 'release', 'facts_plan_annotated: mode=release');
  is(one($kv, 'source_commit'), $TAGGED, 'facts_plan_annotated: source_commit is the commit the tag object points at');
  is(one($kv, 'source_tag_object'), $TAGOBJ, 'facts_plan_annotated: source_tag_object is the tag object');
  is(one($kv, 'tag'), 'v1.0', 'facts_plan_annotated: tag');
  is(one($kv, 'version_slot'), '1.0', 'facts_plan_annotated: version_slot');
  is(one($kv, 'run_id'), '4242', 'facts_plan_annotated: run_id');
}
{ # lightweight tag
  my $gh = gh_dir('repos/Getty/Foo-Bar/git/ref/tags/v1.0' => { object => { type => 'commit', sha => $TAGGED } });
  my ($rc, $kv, undef, $err) = plan_run($gh);
  is($rc, 0, 'facts_plan_lightweight: exit 0') or diag $err;
  is(one($kv, 'source_commit'), $TAGGED, 'facts_plan_lightweight: source_commit');
  is($kv->{source_tag_object} ? $kv->{source_tag_object}[0] : '', '', 'facts_plan_lightweight: no tag object');
}
{ # tag of a tag
  my $t2 = hex40('second');
  my $gh = gh_dir(
    'repos/Getty/Foo-Bar/git/ref/tags/v1.0' => { object => { type => 'tag', sha => $TAGOBJ } },
    "repos/Getty/Foo-Bar/git/tags/$TAGOBJ"  => { object => { type => 'tag', sha => $t2 } },
    "repos/Getty/Foo-Bar/git/tags/$t2"      => { object => { type => 'commit', sha => $TAGGED } },
  );
  my ($rc, $kv, undef, $err) = plan_run($gh);
  is($rc, 0, 'facts_plan_chain: a tag of a tag is followed') or diag $err;
  is(one($kv, 'source_commit'), $TAGGED, 'facts_plan_chain: it ends at the commit');
}
{ # tree object
  my $gh = gh_dir('repos/Getty/Foo-Bar/git/ref/tags/v1.0' => { object => { type => 'tree', sha => $TAGGED } });
  my ($rc, undef, undef, $err) = plan_run($gh);
  is($rc, 1, 'facts_plan_tree: a tag that ends at a tree makes facts.sh plan exit 1');
}
{ # unknown tag: gh fails
  my ($rc) = plan_run(gh_dir());
  is($rc, 1, 'facts_plan_gh_fails: gh failing makes facts.sh plan exit 1');
}
{ # probe: no gh, SOURCE_COMMIT as given
  my ($rc, $kv, undef, $err, $log) = plan_run(gh_dir(), TAG => '', VERSION_SLOT => 'probe-' . substr($SRC, 0, 7), SOURCE_COMMIT => $SRC);
  is($rc, 0, 'facts_plan_probe: exit 0') or diag $err;
  is(one($kv, 'mode'), 'probe', 'facts_plan_probe: mode=probe');
  is(one($kv, 'source_commit'), $SRC, 'facts_plan_probe: source_commit from the checkout');
  ok(!-e $log, 'facts_plan_probe: gh is not called');
}

# --- build-leg.sh provenance ---------------------------------------------------

SKIP: {
  my ($bash) = grep { -x $_ } map { File::Spec->catfile($_, 'bash') } grep { length } File::Spec->path;
  fail('bash is on PATH (build-leg.sh provenance cannot be driven without it)') unless $bash;
  skip 'no bash on PATH - named failure above', 1 unless $bash;

  my $leg = sub {
    my (%o) = @_;
    my $tmp = tempdir(CLEANUP => 1);
    my ($home, $ws) = ("$tmp/home", "$tmp/ws");
    File::Path::make_path("$home/dzil-binary/perl/bin");
    symlink $^X, "$home/dzil-binary/perl/bin/perl" or die "symlink: $!";
    spew("$home/dzil-binary/local/lib/perl5/PAR/Packer.pm", "package PAR::Packer; our \$VERSION = '1.099'; 1;\n");
    spew("$ws/dist/META.json", JSON::PP->new->encode({ name => 'Foo-Bar', version => '1.0', x_binaries => \%XB }));
    my $p = $o{platform};
    my $exe = $p =~ /windows/ ? '.exe' : '';
    spew("$ws/out/$_-1.0-$p$exe", "binary of $_ on $p\n") for qw( foo bar );
    my ($rc, $out, $err) = run_cmd([$bash, script('build-leg.sh'), 'provenance'], cwd => $ws, env => {
      HOME => $home, PLATFORM => $p, VERSION => '1.0', RUNNER_LABEL => $o{runner}, LEG_CONTAINER => $o{container},
      BUNDLE_COMMIT => $WF, GITHUB_RUN_ATTEMPT => '1', RUNNER_OS => $o{runner_os}, RUNNER_ARCH => 'X64',
      ImageOS => $o{image_os}, ImageVersion => $o{image_version}, MACOSX_DEPLOYMENT_TARGET => $o{target},
      GITHUB_OUTPUT => undef, PERL5LIB => undef, PERL_LOCAL_LIB_ROOT => undef,
    });
    my $file = "$ws/provenance/build-$p.txt";
    my ($kv, $bad) = parse_part(-f $file ? slurp($file) : '');
    return ($rc, $out, $err, $kv, $bad, -f $file ? 1 : 0, $ws);
  };

  { # a container (Linux) leg: no runner image
    my ($rc, $out, $err, $kv, $bad, $have) = $leg->(platform => 'linux-x86_64', runner => 'ubuntu-24.04',
      container => $LEG{'linux-x86_64'}{container}, runner_os => 'Linux');
    is($rc, 0, 'leg_provenance_linux: exit 0') or diag "stdout: $out\nstderr: $err";
    ok($have, 'leg_provenance_linux: writes provenance/build-linux-x86_64.txt');
    is_deeply($bad, [], 'leg_provenance_linux: every line is KEY=VALUE');
    is(one($kv, 'kind'), 'build', 'leg_provenance_linux: kind=build');
    is(one($kv, 'platform'), 'linux-x86_64', 'leg_provenance_linux: platform');
    is(one($kv, 'runner'), 'ubuntu-24.04', 'leg_provenance_linux: runner');
    is(one($kv, 'container'), $LEG{'linux-x86_64'}{container}, 'leg_provenance_linux: container');
    is(one($kv, 'bundle_commit'), $WF, 'leg_provenance_linux: bundle_commit');
    is(one($kv, 'run_attempt'), '1', 'leg_provenance_linux: run_attempt');
    is(one($kv, 'perl_version'), $Config{version}, 'leg_provenance_linux: perl_version is the packing perl\'s $Config{version}');
    is(one($kv, 'perl_archname'), $Config{archname}, 'leg_provenance_linux: perl_archname');
    is(one($kv, 'par_packer_version'), '1.099', 'leg_provenance_linux: par_packer_version from the local lib');
    is(($kv->{runner_image_os} || [''])->[0], '', 'leg_provenance_linux: no ImageOS in a container, so runner_image_os is empty');
    is_deeply([sort @{ $kv->{binary} || [] }],
      [ map { "$_-1.0-linux-x86_64 " . sha256_hex("binary of $_ on linux-x86_64\n") } qw( bar foo ) ],
      'leg_provenance_linux: one binary=<asset> <sha256> line per binary, with the hash of the file');
    ok(exists $kv->{$_}, "leg_provenance_linux: $_ is written") for map { "build_$_" } qw( os architecture abi kernel kernel_release );
    chomp(my $uname_m = `uname -m`);
    is(one($kv, 'build_architecture'), $uname_m, 'leg_provenance_linux: build_architecture is uname -m');
  }
  { # a host leg: runner image facts and the deployment target pass through
    my ($rc, $out, $err, $kv, undef, $have) = $leg->(platform => 'macos-arm64', runner => 'macos-15', container => undef,
      runner_os => 'macOS', image_os => 'macos15', image_version => '20261101.1', target => '12.0');
    is($rc, 0, 'leg_provenance_macos: exit 0') or diag "stdout: $out\nstderr: $err";
    is(one($kv, 'runner_image_os'), 'macos15', 'leg_provenance_macos: runner_image_os from ImageOS');
    is(one($kv, 'runner_image_version'), '20261101.1', 'leg_provenance_macos: runner_image_version from ImageVersion');
    is(one($kv, 'macosx_deployment_target'), '12.0', 'leg_provenance_macos: macosx_deployment_target');
    is(($kv->{container} || [''])->[0], '', 'leg_provenance_macos: no container');
    is(scalar @{ $kv->{binary} || [] }, 2, 'leg_provenance_macos: two binary lines');
  }
}

done_testing;
