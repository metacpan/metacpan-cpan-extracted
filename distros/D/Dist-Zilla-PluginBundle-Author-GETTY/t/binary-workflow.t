use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Basename qw( dirname );
use Cwd qw( abs_path );
use File::Temp ();

# The dzil-binary.yml workflow unpacks the dist tarball in the checked-out
# workspace of a probe run, where the dist's own files live. The unpack
# directory has to be one no checked-in dist can own (a TypeScript "src/" at
# the root, say), so it lives under $RUNNER_TEMP.

my $root = abs_path(File::Spec->catdir(dirname(__FILE__), File::Spec->updir));
my $file = File::Spec->catfile($root, '.github', 'workflows', 'dzil-binary.yml');
open my $fh, '<', $file or die "$file: $!";
my $yml = do { local $/; <$fh> };
close $fh;

# the jobs that check the dist out (plan, provenance, publish); the platform
# legs have an empty workspace and unpack into dist/
my @unpack = grep { !/-C dist / } $yml =~ /^\s*tar xzf .*$/mg;
is(scalar @unpack, 3, 'the plan, provenance and publish jobs each unpack the tarball');
like($_, qr{-C "\$dist_src" }, "unpack into \$dist_src: $_") for @unpack;

my @dirs = $yml =~ /^\s*dist_src=(\S+)$/mg;
is_deeply(\@dirs, ['$RUNNER_TEMP/dist-src', '$RUNNER_TEMP/dist-src', '$RUNNER_TEMP/dist-src'],
  'dist_src is below $RUNNER_TEMP in all three jobs');

unlike($yml, qr{^\s*mkdir\s+src\b}m, 'no mkdir of a workspace-level src');
unlike($yml, qr{(?:\s|["'/])src/META\.json}, 'META.json is not read from src/');
unlike($yml, qr{-C\s+"?src\b}, 'tar does not extract into src');

# The plan and publish jobs' own scratch paths (dl/, tarball/, assets/,
# release.json, latest.json, latest.err) sit in the same workspace, so they
# live below $RUNNER_TEMP too (${{ runner.temp }} in `with: path:`, where shell
# variables do not expand). build and smoke have an empty workspace and keep
# their relative tarball/, bins/, dist/ and out/.
my ($jobs_text) = $yml =~ /^jobs:\n(.*)\z/ms;
my (undef, %job) = split /^  (\w+):\n/m, $jobs_text;
ok($job{$_}, "found the $_ job") for qw( plan build smoke provenance publish );
is_deeply([sort keys %job], [sort qw( plan build smoke provenance publish )], 'the workflow has exactly these jobs');

# Drop step names and comments: they mention "tarball" and "release.json" in prose.
sub code_of {
  join '', grep { !/^\s*(?:-\s+)?name:/ && !/^\s*#/ } split /^/m, $_[0];
}

# Uses of NAME that are workspace-relative: not preceded by a path separator,
# a variable sigil or a word/dash character (so $RUNNER_TEMP/NAME, $NAME,
# ${NAME}, dist-NAME do not count) and not an assignment (NAME=$RUNNER_TEMP/...).
sub relative_uses {
  my ($code, $name) = @_;
  my $re = qr/(?<![\w\/\$\{\}.\-])\Q$name\E(?![\w=])/;
  return grep { /$re/ } split /^/m, $code;
}

my $temp = qr{\$RUNNER_TEMP|\$\{\{\s*runner\.temp\s*\}\}};

my $plan = code_of($job{plan} // '');
my @dl = relative_uses($plan, 'dl');
is_deeply(\@dl, [], 'plan: no workspace-relative dl') or diag @dl;
like($plan, qr{^\s*mv\s+\./\*\.tar\.gz\s+"?\$}m, 'plan: the built tarball moves to a variable location');
like($plan, qr{gh release download\b[^\n]*-D\s+"?\$}, 'plan: the release tarball downloads to a variable location');
my ($plan_upload) = $plan =~ /upload-artifact.*?^\s*path:\s*([^\n]*\S)/ms;
like($plan_upload // '', qr{^$temp/}, 'plan: upload-artifact reads the tarball from below runner.temp');

my $publish = code_of($job{publish} // '');
for my $name (qw( tarball assets release.json latest.json latest.err provenance.json )) {
  my @rel = relative_uses($publish, $name);
  is_deeply(\@rel, [], "publish: no workspace-relative $name") or diag @rel;
}
my @paths = $publish =~ /^\s*path:\s*([^\n]*\S)/mg;
is(scalar @paths, 4, 'publish: four artifact/checkout paths') or diag "@paths";
my @art = grep { !/^\.dzil-binary$/ } @paths;
is(scalar @art, 3, 'publish: three download-artifact paths (tarball, assets, provenance)');
like($_, qr{^\$\{\{\s*runner\.temp\s*\}\}/}, "publish: download-artifact path $_ is below runner.temp") for @art;

# --- k33: the provenance job and the pinned bundle commit --------------------
# like/unlike without dumping a whole job into the failure diagnostics
sub qlike   { my ($t, $re, $n) = @_; return ok(defined $t && $t =~ $re, $n) }
sub qunlike { my ($t, $re, $n) = @_; return ok(!defined $t || $t !~ $re, $n) }


my $provenance = code_of($job{provenance} // '');
for my $name (qw( tarball assets parts provenance.json release.json )) {
  my @rel = relative_uses($provenance, $name);
  is_deeply(\@rel, [], "provenance: no workspace-relative $name") or diag @rel;
}
my @ppaths = $provenance =~ /^\s*path:\s*([^\n]*\S)/mg;
my @pdl = grep { !/^\.dzil-binary$/ } @ppaths;
cmp_ok(scalar @pdl, '>=', 4, 'provenance: the downloads and the upload have a path (tarball, assets, parts, manifest)') or diag "@ppaths";
qlike($_, qr{^\$\{\{\s*runner\.temp\s*\}\}/}, "provenance: path $_ is below runner.temp") for @pdl;
qunlike($job{provenance} // '', qr/^    if:/m, 'provenance: no job-level if: (probe and release runs both build the manifest)');
qlike($provenance, qr/\bprovenance\.pl\b.*\bmerge\b/s, 'provenance: runs provenance.pl merge');
qlike($job{provenance} // '', qr/^\s*(?:-\s+)?if-no-files-found:\s*error\s*$/m, 'provenance: the manifest upload fails when the file is missing');

sub needs_of { my ($j) = @_; my ($n) = $j =~ /^    needs:\s*(.*)$/m; return sort(($n // '') =~ /(\w+)/g) }
is_deeply([needs_of($job{provenance} // '')], [qw( build plan smoke )], 'provenance: needs plan, build and smoke');
is_deeply([needs_of($job{publish} // '')], [qw( build plan provenance smoke )], 'publish: needs provenance too (a failed provenance job blocks the release)');
qlike($job{publish}, qr/needs\.provenance\.outputs\.artifact/, 'publish: downloads the manifest artifact the provenance job names');
qlike($publish, qr/\bverify\b/, 'publish: verifies the manifest before uploading');
qlike($publish, qr/gh release upload(?:[^\n]*\\\n)*[^\n]*provenance\.json/, 'publish: provenance.json goes up in the gh release upload call');

# bundle_ref: empty means the commit of this workflow, resolved once in plan
my ($on) = $yml =~ /^on:\n(.*?)^permissions:/ms;
my ($ref_input) = ($on // '') =~ /^      bundle_ref:\n((?:        .*\n)+)/m;
qlike($ref_input // '', qr/^        default:\s*(?:''|"")\s*$/m, "bundle_ref defaults to ''");
qunlike(code_of($yml), qr/binary-v1/, 'no binary-v1 in the workflow code (comments may name the tag callers use)');

my @with_input = grep { ($job{$_} // '') =~ /inputs\.bundle_ref/ } sort keys %job;
is_deeply(\@with_input, ['plan'], 'inputs.bundle_ref is read in the plan job only');
my $repo = 'Getty/p5-dist-zilla-pluginbundle-author-getty';
my @repo_jobs = grep { ($job{$_} // '') =~ /repository:\s*\Q$repo\E/ } sort keys %job;
is_deeply(\@repo_jobs, [qw( build plan provenance publish smoke )], 'every job checks the bundle out');
is(scalar(() = $yml =~ /repository:\s*\Q$repo\E/g), 5, 'five bundle checkouts in all');
for my $j (qw( build smoke provenance publish )) {
  my @refs = ($job{$j} // '') =~ /repository:\s*\Q$repo\E\s*\n\s*ref:\s*([^\n]*\S)/g;
  is_deeply(\@refs, ['${{ needs.plan.outputs.bundle_commit }}'], "$j: the bundle checkout is at the pinned commit");
}
my ($plan_ref) = $job{plan} =~ /repository:\s*\Q$repo\E\s*\n\s*ref:\s*([^\n]*\S)/;
is($plan_ref, '${{ steps.resolve.outputs.ref }}', 'plan: the bundle checkout is at the resolved ref');
qlike($job{plan}, qr/^    outputs:\n(?:      .*\n)*?      bundle_commit:\s*\$\{\{\s*steps\.pin\.outputs\.bundle_commit\s*\}\}$/m, 'plan: outputs bundle_commit from the pin step');
qlike($plan, qr/job\.workflow_sha/, 'plan: reads job.workflow_sha (the called workflow\'s own commit)');
qlike($plan, qr/job\.workflow_repository/, 'plan: reads job.workflow_repository (the fork guard)');
my ($first_step) = $job{plan} =~ /^    steps:\n(?:\s*#[^\n]*\n)*\s+- name:\s*([^\n]*)/m;
is($first_step, 'Resolve the bundle commit', 'plan: the first step resolves the bundle commit');

# the permissions of the caller stay what they were
my ($perm) = $yml =~ /^permissions:\n((?:[ ]{2}.*\n)+)/m;
is_deeply([map { s/^\s+|\s+$//gr } split /\n/, $perm // ''], ['contents: read'], 'top-level permissions are contents: read only');

# smoke: the bundle checkout comes after both smoke steps (the macOS/Windows one
# may delete things; the Linux run needs bins/ and dist/ untouched)
{
  my $sm = $job{smoke} // '';
  my $at_smoke = index($sm, 'name: Smoke (macOS, Windows)');
  my $at_repo  = index($sm, "repository: $repo");
  cmp_ok($at_smoke, '>=', 0, 'smoke: has the macOS/Windows smoke step');
  cmp_ok($at_repo, '>', $at_smoke, 'smoke: the bundle is checked out after the smoke steps');
  qlike($sm, qr/id:\s*bundle\b/, 'smoke: the late bundle checkout has id: bundle');
  qlike(code_of($sm), qr/\bfacts\.sh\s+smoke\b/, 'smoke: writes its provenance part with facts.sh smoke');
  qlike($sm, qr/name:\s*provenance\.smoke\./, 'smoke: uploads provenance.smoke.<job-index>');
}
{
  my $b = $job{build} // '';
  my $at_verify = index(code_of($b), 'build-leg.sh verify');
  my $at_prov   = index(code_of($b), 'build-leg.sh provenance');
  cmp_ok($at_verify, '>=', 0, 'build: runs verify');
  cmp_ok($at_prov, '>', $at_verify, 'build: writes its provenance part after verify');
  qlike($b, qr/name:\s*provenance\.build\./, 'build: uploads provenance.build.<platform>');
  qlike($job{plan}, qr/name:\s*provenance\.plan\b/, 'plan: uploads provenance.plan');
  qlike(code_of($job{plan}), qr/\bfacts\.sh\s+plan\b/, 'plan: writes its provenance part with facts.sh plan');
}

# The artifact names must match no download pattern of the workflow (publish and
# provenance take '*-<version>-*', the smoke jobs '*-<version>-<platform>*') nor
# briefing's '*-<platform>*', or a manifest part would be swept in as an asset.
{
  my @plat = qw( linux-x86_64 linux-arm64 macos-arm64 macos-x86_64 windows-x86_64 );
  my @decl = $yml =~ /^\s+name:\s*(provenance\.\S[^\n]*)$/mg;
  is(scalar @decl, 3, 'three provenance part artifact names (plan, build, smoke)') or diag "@decl";
  my @names = ('Foo-Bar-1.0.provenance');
  for my $d (@decl) {
    if ($d =~ /matrix\.platform/) {
      for my $p (@plat) { (my $n = $d) =~ s/\$\{\{\s*matrix\.platform\s*\}\}/$p/; push @names, $n }
    }
    elsif ($d =~ /strategy\.job-index/) {
      for my $i (0 .. 7) { (my $n = $d) =~ s/\$\{\{\s*strategy\.job-index\s*\}\}/$i/; push @names, $n }
    }
    else { push @names, $d }
  }
  qunlike(join(' ', @names), qr/\$\{\{/, 'every provenance artifact name instantiates') or diag "@names";
  my @pat = $yml =~ /^\s*pattern:\s*'([^']*)'\s*$/mg;
  my @parts_pat = grep { $_ eq 'provenance.*' } @pat;
  is(scalar @parts_pat, 1, "exactly one download takes the parts pattern 'provenance.*'");
  my @asset_pat;
  for my $pt (grep { $_ ne 'provenance.*' } @pat) {
    (my $v = $pt) =~ s/\$\{\{\s*needs\.plan\.outputs\.version\s*\}\}/1.0/g;
    push @asset_pat, $v =~ /matrix\.cell\.platform/ ? (map { (my $x = $v) =~ s/\$\{\{\s*matrix\.cell\.platform\s*\}\}/$_/; $x } @plat) : $v;
  }
  push @asset_pat, map { "*-$_*" } @plat;   # briefing's
  my $re = sub { my $g = quotemeta shift; $g =~ s/\\\*/.*/g; qr/\A$g\z/ };
  for my $n (@names) {
    for my $pt (@asset_pat) { qunlike($n, $re->($pt), "artifact $n is not matched by the download pattern $pt") }
  }
  my $parts = $re->('provenance.*');
  qlike($_, $parts, "the parts pattern collects $_") for grep { /\Aprovenance\./ } @names;
  qunlike('Foo-Bar-1.0.provenance', $parts, 'the parts pattern does not collect the final manifest');
}

# The "Resolve the bundle commit" step, run for real under bash.
{
  my ($step) = $job{plan} =~ /(^      - name: Resolve the bundle commit\n.*?)(?=^      - name:|\z)/ms;
  ok(defined $step, 'found the Resolve the bundle commit step') or $step = '';
  my ($body) = $step =~ /^        run: \|\n((?:          .*\n|\n)+)/m;
  ok(defined $body && length $body, 'the step has a run: block') or $body = "exit 99\n";
  $body =~ s/^ {10}//mg;
  my $dir = File::Temp::tempdir(CLEANUP => 1);
  open my $o, '>', "$dir/resolve.sh" or die; print $o $body; close $o;
  my $sha = 'a' x 40;
  my $wf  = 'Getty/p5-dist-zilla-pluginbundle-author-getty';
  my $resolve = sub {
    my (%env) = @_;
    unlink "$dir/out";
    open my $t, '>', "$dir/out" or die; close $t;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
      $ENV{GITHUB_OUTPUT} = "$dir/out";
      $ENV{$_} = $env{$_} for keys %env;
      open STDOUT, '>', "$dir/stdout"; open STDERR, '>', "$dir/stderr";
      exec 'bash', "$dir/resolve.sh" or exit 127;
    }
    waitpid $pid, 0;
    my $rc = $? >> 8;
    open my $f, '<', "$dir/out" or die; my $out = do { local $/; <$f> };
    open my $e, '<', "$dir/stderr" or die; my $err = do { local $/; <$e> };
    open my $g, '<', "$dir/stdout" or die; my $so = do { local $/; <$g> };
    return ($rc, $out, "$so$err");
  };

  my ($rc, $out, $msg) = $resolve->(BUNDLE_REF => '', WORKFLOW_SHA => '', WORKFLOW_REPOSITORY => $wf);
  is($rc, 1, 'resolve: an empty job.workflow_sha fails the run') or diag $msg;
  qunlike($out, qr/^ref=/m, 'resolve: and writes no ref=');
  qlike($msg, qr/::error::/, 'resolve: and says why as an ::error::');

  ($rc, $out, $msg) = $resolve->(BUNDLE_REF => '', WORKFLOW_SHA => 'abc123', WORKFLOW_REPOSITORY => $wf);
  is($rc, 1, 'resolve: a workflow sha that is not 40 hex digits fails') or diag $msg;
  qunlike($out, qr/^ref=/m, 'resolve: and writes no ref=');

  ($rc, $out, $msg) = $resolve->(BUNDLE_REF => '', WORKFLOW_SHA => $sha, WORKFLOW_REPOSITORY => $wf);
  is($rc, 0, 'resolve: a 40-hex workflow sha resolves') or diag $msg;
  qlike($out, qr/^ref=$sha$/m, 'resolve: ref is the workflow sha');
  qlike($out, qr/^source=workflow$/m, 'resolve: source=workflow');

  ($rc, $out, $msg) = $resolve->(BUNDLE_REF => 'main', WORKFLOW_SHA => '', WORKFLOW_REPOSITORY => $wf);
  is($rc, 0, 'resolve: an explicit bundle_ref wins even without a workflow sha') or diag $msg;
  qlike($out, qr/^ref=main$/m, 'resolve: ref is the explicit ref');
  qlike($out, qr/^source=input$/m, 'resolve: source=input');

  ($rc, $out, $msg) = $resolve->(BUNDLE_REF => '', WORKFLOW_SHA => $sha, WORKFLOW_REPOSITORY => 'someone/fork-of-the-bundle');
  is($rc, 1, 'resolve: a fork\'s copy of the workflow does not default (its sha is not in Getty\'s repository)') or diag $msg;
  qunlike($out, qr/^ref=/m, 'resolve: and writes no ref=');
  qlike($msg, qr/someone\/fork-of-the-bundle/, 'resolve: and names the repository it runs from');

  ($rc, $out) = $resolve->(BUNDLE_REF => 'v9', WORKFLOW_SHA => '', WORKFLOW_REPOSITORY => 'someone/fork-of-the-bundle');
  is($rc, 0, 'resolve: an explicit bundle_ref is honoured in a fork too');
}

done_testing;
