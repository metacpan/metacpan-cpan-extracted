#!/usr/bin/env perl
# Provenance manifest (provenance.json) of the binary release workflow.
#   provenance.pl merge    <META.json> <version> <parts-dir> <assets-dir> <tarball-dir> <run-attempt>
#                          -> the manifest on STDOUT, once the parts agree with plan.pl, the
#                             artifact files and each other
#   provenance.pl verify   <provenance.json> <SHA256SUMS> <tag> <version>
#                          a release manifest whose assets are exactly the lines of SHA256SUMS
#   provenance.pl artifact <META.json> <version>   -> <name>-<version>.provenance
# The parts come from facts.sh (plan, smoke) and build-leg.sh provenance (build):
# one KEY=VALUE line per fact, printable ASCII, an empty value is null; only
# `binary` of a build part and `image_repo_digest` of a smoke part repeat.
# A failure prints one line per problem on STDERR, nothing on STDOUT, and exits 1.
package DzilBinary::Provenance;
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA ();
use File::Basename ();
use File::Spec ();

my $HERE = File::Spec->rel2abs(File::Basename::dirname(__FILE__));
require(File::Spec->catfile($HERE, 'publish.pl')) unless defined &DzilBinary::Publish::read_meta;
require(File::Spec->catfile($HERE, 'plan.pl'))    unless defined &DzilBinary::Plan::plan;

my @MACHINE = qw( os architecture abi kernel kernel_release );
my %KEYS = (
  plan => [qw( kind mode tag version_slot source_commit source_tag_object server_url repository run_id
    run_attempt event ref sha caller_workflow_ref caller_workflow_sha workflow_repository workflow_path
    workflow_ref workflow_commit bundle_ref_input bundle_source bundle_commit )],
  build => [qw( kind platform runner container runner_image_os runner_image_version runner_os runner_arch
    run_attempt bundle_commit ), (map { "build_$_" } @MACHINE),
    qw( perl_version perl_archname par_packer_version macosx_deployment_target binary )],
  smoke => [qw( kind platform binary asset sha256 smoked runner runner_image_os runner_image_version
    runner_os runner_arch run_attempt bundle_commit ), (map { "host_$_" } @MACHINE),
    qw( image image_id image_platform image_repo_digest ), (map { "target_$_" } @MACHINE)],
);
my %REPEAT = (build => { binary => 1 }, smoke => { image_repo_digest => 1 });
my $COMMIT = qr/\A[0-9a-f]{40}\z/;

sub fail { print STDERR "$_\n" for @_; return 1 }

sub nul { return defined $_[0] && length $_[0] ? $_[0] : undef }

sub sha256_file { return Digest::SHA->new(256)->addfile($_[0], 'b')->hexdigest }

sub machine_of { my ($kv, $prefix) = @_; return { map { $_ => nul($kv->{"$prefix$_"}) } @MACHINE } }

sub runner_image_of {
  my ($kv) = @_;
  my ($os, $version) = map { nul($kv->{$_}) } qw( runner_image_os runner_image_version );
  return defined $os || defined $version ? { os => $os, version => $version } : undef;
}

# D2: a job on the runner itself (not in a container) names the runner image.
sub need_runner_image {
  my ($kv, $file, $problems) = @_;
  for my $k (qw( runner_image_os runner_image_version )) {
    push @$problems, "$file: $k is empty on a job that runs on the runner itself" unless length $kv->{$k};
  }
}

# A part file as { file, kind, kv => { key => value, repeating key => [values] } };
# nothing, with its problems pushed, when it is not a well-formed part.
sub read_part {
  my ($path, $problems) = @_;
  my $file = File::Basename::basename($path);
  my (@pairs, $bad);
  my $n = 0;
  for my $line (split /\n/, DzilBinary::Publish::slurp($path)) {
    $n++;
    if ($line =~ /\A([a-z][a-z0-9_]*)=([\x20-\x7e]*)\z/) { push @pairs, [ $1, $2 ]; next }
    my ($k) = $line =~ /\A([a-z][a-z0-9_]*)=/;
    push @$problems, "$file line $n: not a KEY=VALUE line of printable ASCII" . ($k ? " (key $k)" : '');
    $bad = 1;
  }
  return if $bad;
  my @kind = map { $_->[1] } grep { $_->[0] eq 'kind' } @pairs;
  if (@kind != 1 || !$KEYS{ $kind[0] }) {
    push @$problems, "$file: " . (!@kind ? 'no kind line' : @kind > 1 ? 'key kind repeated' : "kind '$kind[0]' is not plan, build or smoke");
    return;
  }
  my $kind = $kind[0];
  my %known = map { $_ => 1 } @{ $KEYS{$kind} };
  my $repeat = $REPEAT{$kind} || {};
  my %kv = map { $_ => [] } keys %$repeat;
  for (@pairs) {
    my ($k, $v) = @$_;
    if    (!$known{$k})     { push @$problems, "$file: unknown key $k in a $kind part"; $bad = 1 }
    elsif ($repeat->{$k})   { push @{ $kv{$k} }, $v }
    elsif (exists $kv{$k})  { push @$problems, "$file: key $k repeated"; $bad = 1 }
    else                    { $kv{$k} = $v }
  }
  for my $k (grep { !exists $kv{$_} } @{ $KEYS{$kind} }) { push @$problems, "$file: no $k line"; $bad = 1 }
  return if $bad;
  return { file => $file, kind => $kind, kv => \%kv };
}

sub merge {
  my ($meta_file, $version, $parts_dir, $assets_dir, $tarball_dir, $attempt) = @_;
  my @p;
  my $meta = DzilBinary::Publish::read_meta($meta_file);
  my $x = $meta->{x_binaries};
  my @bins  = DzilBinary::Publish::binaries_of($x);
  my @plats = DzilBinary::Publish::platforms_of($x);
  my @names = DzilBinary::Publish::expected_names($x, $version);
  my %asset;   # binary => platform => asset name, in expected_names' order
  my $i = 0;
  for my $bin (@bins) { $asset{$bin}{$_} = $names[ $i++ ] for @plats }
  my %plan = map { /\A(\w+)=(.*)\z/s ? ($1 => $2) : () } DzilBinary::Plan::plan($meta_file);
  my @legs  = @{ JSON::PP->new->decode($plan{legs}) };
  my @cells = @{ JSON::PP->new->decode($plan{smoke}) };

  opendir my $dh, $parts_dir or die "cannot read $parts_dir: $!\n";
  my @files = sort grep { !/\A\./ && -f File::Spec->catfile($parts_dir, $_) } readdir $dh;
  closedir $dh;
  my @parts = map { read_part(File::Spec->catfile($parts_dir, $_), \@p) } @files;
  return fail(@p) if @p;

  # --- the plan part ---
  my @plans = grep { $_->{kind} eq 'plan' } @parts;
  return fail(@plans ? 'want exactly one plan part, found ' . join(', ', map { $_->{file} } @plans) : "no plan part in $parts_dir")
    unless @plans == 1;
  my ($pl, $pf) = @{ $plans[0] }{qw( kv file )};
  for my $k (qw( workflow_commit bundle_commit source_commit )) {
    push @p, "$pf: $k '$pl->{$k}' is not a 40-hex commit" unless $pl->{$k} =~ $COMMIT;
  }
  push @p, "$pf: source_tag_object '$pl->{source_tag_object}' is not a 40-hex object"
    if length $pl->{source_tag_object} && $pl->{source_tag_object} !~ $COMMIT;
  if ($pl->{bundle_source} eq 'workflow') {
    push @p, "$pf: bundle_commit $pl->{bundle_commit} is not the workflow's commit $pl->{workflow_commit} (bundle_source workflow)"
      unless $pl->{bundle_commit} eq $pl->{workflow_commit};
  }
  elsif ($pl->{bundle_source} ne 'input') { push @p, "$pf: bundle_source '$pl->{bundle_source}' is not workflow or input" }
  push @p, "$pf: version_slot $pl->{version_slot} is not the version $version of this run" unless $pl->{version_slot} eq $version;
  if ($pl->{mode} eq 'release') {
    my $v = $meta->{version} // '';
    push @p, "$meta_file: version '$v' is not the version $version of this run" unless $v eq $version;
    push @p, "$pf: tag '$pl->{tag}' does not end with the dist version '$v'"
      unless length $v && length $pl->{tag} >= length $v && substr($pl->{tag}, -length $v) eq $v;
  }
  elsif ($pl->{mode} eq 'probe') {
    push @p, "$pf: a probe has no tag, this one has tag '$pl->{tag}'" if length $pl->{tag};
    my $want = 'probe-' . substr($pl->{source_commit}, 0, 7);
    push @p, "the version $version of this run is not $want, the probe slot of $pl->{source_commit}" unless $version eq $want;
  }
  else { push @p, "$pf: mode '$pl->{mode}' is not release or probe" }
  for my $part (grep { $_->{kind} ne 'plan' } @parts) {
    push @p, "$part->{file}: bundle_commit $part->{kv}{bundle_commit} is not the plan's $pl->{bundle_commit}"
      unless $part->{kv}{bundle_commit} eq $pl->{bundle_commit};
  }

  # --- the tarball and the artifact files ---
  opendir my $th, $tarball_dir or die "cannot read $tarball_dir: $!\n";
  my @tars = sort grep { /\.tar\.gz\z/ && -f File::Spec->catfile($tarball_dir, $_) } readdir $th;
  closedir $th;
  my $tarball;
  if (@tars == 1) { $tarball = { name => $tars[0], sha256 => sha256_file(File::Spec->catfile($tarball_dir, $tars[0])) } }
  else { push @p, "want exactly one tarball (*.tar.gz) in $tarball_dir, found " . (@tars ? join(', ', @tars) : 'none') }
  my %hash;   # asset name => sha256 of its artifact file
  for my $n (@names) {
    my $f = File::Spec->catfile($assets_dir, $n);
    if (-f $f) { $hash{$n} = sha256_file($f) } else { push @p, "no artifact file $n in $assets_dir" }
  }

  # --- one build part per leg of plan.pl ---
  my %build;
  for my $part (grep { $_->{kind} eq 'build' } @parts) {
    my $plat = $part->{kv}{platform};
    if (!grep { $_->{platform} eq $plat } @legs) { push @p, "$part->{file}: platform '$plat' has no build leg" }
    elsif ($build{$plat}) { push @p, "two build parts for $plat: $build{$plat}{file}, $part->{file}" }
    else { $build{$plat} = $part }
  }
  my @builds;
  for my $leg (@legs) {
    my $plat = $leg->{platform};
    my $part = $build{$plat} or do { push @p, "no build part for $plat"; next };
    my ($kv, $f) = @$part{qw( kv file )};
    my $container = $leg->{container} // '';
    push @p, "$f: runner '$kv->{runner}', the $plat leg runs on $leg->{runner}" unless $kv->{runner} eq $leg->{runner};
    push @p, "$f: container '$kv->{container}', the $plat leg runs in '$container'" unless $kv->{container} eq $container;
    need_runner_image($kv, $f, \@p) unless length $container;
    my %want = map { $asset{$_}{$plat} => 1 } @bins;
    my %line;
    for my $l (@{ $kv->{binary} }) {
      my ($n, $s) = $l =~ /\A(\S+) ([0-9a-f]{64})\z/;
      if    (!defined $n)     { push @p, "$f: binary '$l' is not '<asset> <sha256>'" }
      elsif (!$want{$n})      { push @p, "$f: binary $n is not an asset of $plat" }
      elsif (exists $line{$n}) { push @p, "$f: binary $n repeated" }
      else                    { $line{$n} = $s }
    }
    my @binaries;
    for my $n (map { $asset{$_}{$plat} } @bins) {
      if (!exists $line{$n}) { push @p, "$f: no binary line for $n"; next }
      push @p, "$f: $n has sha256 $line{$n}, its artifact file $hash{$n}" if defined $hash{$n} && $line{$n} ne $hash{$n};
      push @binaries, { name => $n, sha256 => $line{$n} };
    }
    push @builds, {
      platform => $plat, runner => $kv->{runner}, container => nul($kv->{container}),
      runner_image => runner_image_of($kv), runner_os => nul($kv->{runner_os}), runner_arch => nul($kv->{runner_arch}),
      machine => machine_of($kv, 'build_'),
      perl => { version => nul($kv->{perl_version}), archname => nul($kv->{perl_archname}) },
      par_packer => nul($kv->{par_packer_version}), macosx_deployment_target => nul($kv->{macosx_deployment_target}),
      bundle_commit => $kv->{bundle_commit}, run_attempt => nul($kv->{run_attempt}), binaries => \@binaries,
    };
  }

  # --- one smoke part per plan.pl cell and binary ---
  # A smoked part names its image; one that was not smoked has none, so it takes
  # any free cell of its binary, platform and runner: the smoked ones go first.
  my @slots = map { my $bin = $_; map { { binary => $bin, cell => $_ } } @cells } @bins;
  my @smoke = grep { $_->{kind} eq 'smoke' } @parts;
  for my $part ((grep { $_->{kv}{smoked} eq 'true' } @smoke), (grep { $_->{kv}{smoked} ne 'true' } @smoke)) {
    my ($kv, $f) = @$part{qw( kv file )};
    my $what = "$kv->{binary} on $kv->{platform} ($kv->{runner}" . (length $kv->{image} ? ", $kv->{image}" : '') . ')';
    if ($kv->{smoked} !~ /\A(?:true|false)\z/) { push @p, "$f: smoked '$kv->{smoked}' is not true or false"; next }
    my $smoked = $kv->{smoked} eq 'true';
    if (!$smoked && length $kv->{image}) { push @p, "$f: the smoke of $what did not run, yet it names an image"; next }
    my @match = grep {
      $_->{binary} eq $kv->{binary} && $_->{cell}{platform} eq $kv->{platform} && $_->{cell}{runner} eq $kv->{runner}
        && (!$smoked || ($_->{cell}{image} // '') eq $kv->{image})
    } @slots;
    my ($free) = grep { !$_->{part} } @match;
    if ($free) { $free->{part} = $part; next }
    push @p, @match ? "$f: duplicate smoke part for $what (also $match[0]{part}{file})" : "$f: the smoke part for $what is no cell of plan.pl";
  }
  my @smokes;
  for my $s (@slots) {
    my $c = $s->{cell};
    if (!$s->{part}) {
      push @p, "no smoke part for $s->{binary} on $c->{platform} ($c->{runner}" . (defined $c->{image} ? ", $c->{image}" : '') . ')';
      next;
    }
    my ($kv, $f) = @{ $s->{part} }{qw( kv file )};
    my $n = $asset{ $s->{binary} }{ $c->{platform} };
    push @p, "$f: asset '$kv->{asset}', the cell's is $n" unless $kv->{asset} eq $n;
    push @p, "$f: $n has sha256 $kv->{sha256}, its artifact file $hash{$n}" if defined $hash{$n} && $kv->{sha256} ne $hash{$n};
    need_runner_image($kv, $f, \@p);
    my $smoked = $kv->{smoked} eq 'true';
    push @smokes, {
      binary => $s->{binary}, platform => $c->{platform}, asset => $kv->{asset}, sha256 => $kv->{sha256},
      smoked => $smoked ? JSON::PP::true() : JSON::PP::false(),
      runner => $kv->{runner}, runner_image => runner_image_of($kv),
      runner_os => nul($kv->{runner_os}), runner_arch => nul($kv->{runner_arch}),
      host => machine_of($kv, 'host_'),
      image => length $kv->{image}
        ? { ref => $kv->{image}, id => nul($kv->{image_id}), platform => nul($kv->{image_platform}),
            repo_digests => [ sort @{ $kv->{image_repo_digest} } ] }
        : undef,
      target => $smoked ? machine_of($kv, 'target_') : undef,
      bundle_commit => $kv->{bundle_commit}, run_attempt => nul($kv->{run_attempt}),
    };
  }
  return fail(@p) if @p;

  print JSON::PP->new->canonical->pretty->ascii->encode({
    schema_version => 1,
    mode => $pl->{mode},
    run => {
      server_url => nul($pl->{server_url}), repository => nul($pl->{repository}), run_id => nul($pl->{run_id}),
      attempt => nul($attempt), event => nul($pl->{event}), ref => nul($pl->{ref}), sha => nul($pl->{sha}),
    },
    caller => { workflow_ref => nul($pl->{caller_workflow_ref}), workflow_sha => nul($pl->{caller_workflow_sha}) },
    workflow => {
      repository => nul($pl->{workflow_repository}), path => nul($pl->{workflow_path}),
      ref => nul($pl->{workflow_ref}), commit => $pl->{workflow_commit},
    },
    bundle => { ref_input => nul($pl->{bundle_ref_input}), source => $pl->{bundle_source}, commit => $pl->{bundle_commit} },
    source => { commit => $pl->{source_commit}, tag => nul($pl->{tag}), tag_object => nul($pl->{source_tag_object}) },
    dist => { name => nul($meta->{name}), version => nul($meta->{version}), version_slot => $pl->{version_slot}, tarball => $tarball },
    assets => [ map { { name => $_, sha256 => $hash{$_} } } @names ],
    builds => \@builds,
    smokes => \@smokes,
  });
  return 0;
}

sub verify {
  my ($file, $sums, $tag, $version) = @_;
  my $m = eval { JSON::PP->new->decode(DzilBinary::Publish::slurp($file)) };
  die "$file is not a JSON object" . ($@ ? ": $@" : "\n") unless ref $m eq 'HASH';
  my $str = sub { my ($v) = @_; return defined $v && !ref $v ? $v : undef };
  my $sub = sub { my ($k, $f) = @_; return ref $m->{$k} eq 'HASH' ? $str->($m->{$k}{$f}) : undef };
  my @p;
  my %got = (
    schema_version => [ $str->($m->{schema_version}), 1 ],
    mode           => [ $str->($m->{mode}), 'release' ],
    'source.tag'   => [ $sub->(source => 'tag'), $tag ],
    'dist.version_slot' => [ $sub->(dist => 'version_slot'), $version ],
  );
  for my $k (sort keys %got) {
    my ($have, $want) = @{ $got{$k} };
    push @p, "$file: $k is " . ($have // 'null') . ", want $want" unless defined $have && $have eq $want;
  }
  my %want;
  for my $e (ref $m->{assets} eq 'ARRAY' ? @{ $m->{assets} } : ()) {
    my ($n, $s) = ref $e eq 'HASH' ? map { $str->($e->{$_}) } qw( name sha256 ) : ();
    if (!defined $n || !defined $s) { push @p, "$file: an asset without name or sha256" }
    elsif (exists $want{$n})        { push @p, "$file: asset $n listed twice" }
    else                            { $want{$n} = $s }
  }
  push @p, "$file: no assets" unless %want;
  my %have;
  my $n = 0;
  for my $line (split /\n/, DzilBinary::Publish::slurp($sums)) {
    $n++;
    my ($s, $name) = $line =~ /\A([0-9a-f]{64})  (\S+)\z/;
    if    (!defined $s)         { push @p, "$sums line $n: not '<sha256>  <name>'" }
    elsif (exists $have{$name}) { push @p, "$sums: $name listed twice" }
    else                        { $have{$name} = $s }
  }
  for my $name (sort keys %want) {
    if    (!exists $have{$name})           { push @p, "SHA256SUMS has no line for $name of the manifest" }
    elsif ($have{$name} ne $want{$name})   { push @p, "$name: SHA256SUMS has $have{$name}, the manifest $want{$name}" }
  }
  push @p, "SHA256SUMS lists $_, the manifest does not" for grep { !exists $want{$_} } sort keys %have;
  return @p ? fail(@p) : 0;
}

sub artifact {
  my ($meta_file, $version) = @_;
  my $name = DzilBinary::Publish::read_meta($meta_file)->{name};
  for my $v ($name, $version) {
    die "refusing '" . ($v // '') . "': only letters, digits, '.', '_', '-', '+' are allowed\n"
      unless defined $v && !ref $v && $v =~ /\A[A-Za-z0-9._+-]+\z/;
  }
  return "$name-$version.provenance";
}

sub main {
  my ($cmd, @a) = @_;
  $cmd //= '';
  my $rc = eval {
    if    ($cmd eq 'merge'    && @a == 6) { merge(@a) }
    elsif ($cmd eq 'verify'   && @a == 4) { verify(@a) }
    elsif ($cmd eq 'artifact' && @a == 2) { my $n = artifact(@a); print "$n\n"; 0 }
    else { die "usage: provenance.pl merge|verify|artifact ...\n" }
  };
  if (!defined $rc) { print STDERR $@; return 1 }
  return $rc;
}

exit main(@ARGV) unless caller;
1;
