#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use File::Find ();
use IPC::Open3 ();
use Symbol ();

my @failures;
my @warnings;

# Files/directories we care about for repo scanning.
my @scan_roots = grep { -e $_ } qw(
  lib
  t
  examples
  tools
  README.md
  Changes
  LICENSE
  Makefile.PL
  MANIFEST
  .github
);

# Files/directories that should not appear in a clean release work tree.
my @generated_cruft = qw(
  blib
  _build
  Makefile
  MYMETA.json
  MYMETA.yml
  MANIFEST.bak
  pm_to_blib
);

# Paths to ignore entirely when scanning.
my %skip_exact = map { $_ => 1 } (
  '.git',
  @generated_cruft,
);

my @skip_prefix = qw(
  .git/
  blib/
  _build/
  pm_to_blib/
);

# Repo metadata that we want to scan, but do NOT require in MANIFEST.
my %non_manifest_paths = map { $_ => 1 } qw(
  .github
);

main();
exit(@failures ? 1 : 0);

sub main {
  print "== Linux::Event release check ==\n";

  check_generated_cruft();
  check_manifest();
  check_non_ascii();
  check_versions();
  check_pod();
  check_syntax();
  check_git_status();
  run_build_checks();
  print_summary();
}

sub check_generated_cruft {
  print "\n-- generated cruft --\n";

  my @bad = grep { -e $_ } @generated_cruft;

  if (@bad) {
    push @failures, 'generated cruft present: ' . join(', ', @bad);
    print "FAIL: found generated cruft:\n";
    print "  $_\n" for @bad;
  }
  else {
    print "ok: no generated cruft found\n";
  }
}

sub check_manifest {
  print "\n-- MANIFEST --\n";

  unless (-f 'MANIFEST') {
    push @failures, 'MANIFEST is missing';
    print "FAIL: MANIFEST is missing\n";
    return;
  }

  my $manifest = read_manifest_files('MANIFEST');
  my $repo     = wanted_repo_files(manifest_only => 1);

  my @missing = sort grep { !exists $manifest->{$_} } keys %$repo;
  my @stale   = sort grep { !exists $repo->{$_} } keys %$manifest;

  if (@missing) {
    push @failures, 'files missing from MANIFEST: ' . join(', ', @missing);
    print "FAIL: files missing from MANIFEST:\n";
    print "  $_\n" for @missing;
  }
  else {
    print "ok: no files missing from MANIFEST\n";
  }

  if (@stale) {
    push @failures, 'stale MANIFEST entries: ' . join(', ', @stale);
    print "FAIL: stale MANIFEST entries:\n";
    print "  $_\n" for @stale;
  }
  else {
    print "ok: no stale MANIFEST entries\n";
  }
}

sub check_non_ascii {
  print "\n-- non-ASCII scan --\n";

  my @files = repo_files_for_scan();
  my @bad;

  for my $file (@files) {
    next unless -f $file;
    next if is_binary_file($file);

    open my $fh, '<:raw', $file or do {
      push @warnings, "could not read $file for non-ASCII scan: $!";
      next;
    };
    local $/;
    my $raw = <$fh>;
    close $fh;

    next unless defined $raw;
    if ($raw =~ /[^\x00-\x7F]/) {
      push @bad, $file;
    }
  }

  if (@bad) {
    push @failures, 'non-ASCII bytes found in: ' . join(', ', @bad);
    print "FAIL: non-ASCII bytes found in:\n";
    print "  $_\n" for @bad;
  }
  else {
    print "ok: no non-ASCII bytes found\n";
  }
}

sub check_versions {
  print "\n-- version consistency --\n";

  my @pm = sort grep { /\.pm\z/ } repo_files_for_scan();
  my %versions;

  for my $file (@pm) {
    open my $fh, '<:raw', $file or do {
      push @warnings, "could not read $file for version scan: $!";
      next;
    };

    my $found;
    while (my $line = <$fh>) {
      if ($line =~ /our\s+\$VERSION\s*=\s*'([^']+)'/) {
        $versions{$file} = $1;
        $found = 1;
        last;
      }
    }
    close $fh;

    push @warnings, "no \$VERSION found in $file" unless $found;
  }

  my %by_version;
  for my $file (sort keys %versions) {
    push @{ $by_version{ $versions{$file} } }, $file;
  }

  if (keys(%by_version) > 1) {
    my @parts;
    for my $ver (sort keys %by_version) {
      push @parts, "$ver => [" . join(', ', @{ $by_version{$ver} }) . "]";
    }
    push @failures, 'inconsistent module versions: ' . join('; ', @parts);
    print "FAIL: inconsistent module versions:\n";
    for my $ver (sort keys %by_version) {
      print "  $ver\n";
      print "    $_\n" for @{ $by_version{$ver} };
    }
  }
  elsif (keys %by_version == 1) {
    my ($ver) = keys %by_version;
    print "ok: module versions are consistent ($ver)\n";
  }
  else {
    push @warnings, 'no module versions found';
    print "WARN: no module versions found\n";
  }
}

sub check_pod {
  print "\n-- POD syntax --\n";

  my @pm = sort grep { /\.pm\z/ } repo_files_for_scan();
  my @bad;

  for my $file (@pm) {
    my ($ok, $out) = run_cmd(
      'perl', '-Ilib', '-MPod::Simple::Checker', '-e', <<'PERL', $file
my $file = $ARGV[0];
my $checker = Pod::Simple::Checker->new;
$checker->parse_file($file);
exit($checker->any_errata_seen ? 1 : 0);
PERL
    );

    push @bad, [$file, $out] unless $ok;
  }

  if (@bad) {
    push @failures, 'POD syntax errors found';
    print "FAIL: POD syntax errors found:\n";
    for my $item (@bad) {
      my ($file, $out) = @$item;
      print "  $file\n";
      print indent($out, 4) if length $out;
    }
  }
  else {
    print "ok: POD syntax checks passed\n";
  }
}

sub check_syntax {
  print "\n-- perl syntax --\n";

  my @targets = sort grep { /\.(?:pm|pl|t)\z/ } repo_files_for_scan();
  my @bad;

  for my $file (@targets) {
    my ($ok, $out) = run_cmd('perl', '-Ilib', '-c', $file);
    push @bad, [$file, $out] unless $ok;
  }

  if (@bad) {
    push @failures, 'Perl syntax errors found';
    print "FAIL: Perl syntax errors found:\n";
    for my $item (@bad) {
      my ($file, $out) = @$item;
      print "  $file\n";
      print indent($out, 4) if length $out;
    }
  }
  else {
    print "ok: perl syntax checks passed\n";
  }
}

sub check_git_status {
  print "\n-- git status --\n";

  unless (-d '.git') {
    push @warnings, '.git directory not present; skipping git status check';
    print "WARN: .git directory not present; skipping\n";
    return;
  }

  my ($ok, $out) = run_cmd('git', 'status', '--porcelain');
  if (!$ok) {
    push @warnings, 'could not run git status';
    print "WARN: could not run git status\n";
    print indent($out, 2) if length $out;
    return;
  }

  if ($out =~ /\S/) {
    push @warnings, 'git working tree is dirty';
    print "WARN: git working tree is dirty\n";
    print indent($out, 2);
  }
  else {
    print "ok: git working tree is clean\n";
  }
}

sub run_build_checks {
  print "\n-- build/test commands --\n";

  my @commands = (
    [ 'perl', 'Makefile.PL' ],
    [ 'make' ],
    [ 'make', 'test' ],
    [ 'make', 'disttest' ],
  );

  for my $cmd (@commands) {
    my ($ok, $out) = run_cmd(@$cmd);
    my $label = join(' ', @$cmd);

    if ($ok) {
      print "ok: $label\n";
    }
    else {
      push @failures, "command failed: $label";
      print "FAIL: $label\n";
      print indent($out, 2) if length $out;
    }
  }
}

sub print_summary {
  print "\n== Summary ==\n";
  print "  failures : " . scalar(@failures) . "\n";
  print "  warnings : " . scalar(@warnings) . "\n";

  if (@failures) {
    print "\nFailed checks:\n";
    print "  - $_\n" for @failures;
  }

  if (@warnings) {
    print "\nWarnings:\n";
    print "  - $_\n" for @warnings;
  }

  if (!@failures) {
    print "\nRelease checks passed.\n";
  }
}

sub read_manifest_files ($manifest_path) {
  open my $fh, '<', $manifest_path
    or die "cannot open $manifest_path: $!";

  my %files;
  while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /^\s*#/;
    next if $line =~ /^\s*$/;

    my ($file) = split /\s+/, $line, 2;
    next unless defined $file && length $file;

    $files{$file} = 1;
  }

  close $fh;
  return \%files;
}

sub wanted_repo_files (%arg) {
  my $manifest_only = $arg{manifest_only} // 0;
  my %files;

  File::Find::find(
    {
      no_chdir => 1,
      wanted   => sub {
        my $path = normalize_path($File::Find::name);

        if (-d $path) {
          if (should_skip_dir($path)) {
            $File::Find::prune = 1;
          }
          return;
        }

        return if should_skip_file($path);

        if ($manifest_only) {
          return if is_non_manifest_path($path);
        }

        $files{$path} = 1;
      },
    },
    @scan_roots,
  );

  return \%files;
}

sub repo_files_for_scan {
  my $repo = wanted_repo_files();
  return sort keys %$repo;
}

sub is_non_manifest_path ($path) {
  return 1 if $path eq '.github';
  return 1 if index($path, '.github/') == 0;
  return 0;
}

sub should_skip_dir ($path) {
  return 1 if $skip_exact{$path};
  for my $prefix (@skip_prefix) {
    return 1 if index("$path/", $prefix) == 0;
  }
  return 0;
}

sub should_skip_file ($path) {
  return 1 if $skip_exact{$path};
  for my $prefix (@skip_prefix) {
    return 1 if index($path, $prefix) == 0;
  }
  return 0;
}

sub normalize_path ($path) {
  $path =~ s{\\}{/}g;
  $path =~ s{^\./}{};
  return $path;
}

sub is_binary_file ($file) {
  open my $fh, '<:raw', $file or return 0;
  read($fh, my $buf, 1024);
  close $fh;
  return defined($buf) && $buf =~ /\x00/ ? 1 : 0;
}

sub indent ($text, $spaces = 2) {
  my $pad = ' ' x $spaces;
  $text //= '';
  $text =~ s/\A\s+//;
  $text =~ s/\s+\z//;
  return '' unless length $text;
  $text =~ s/^/$pad/mg;
  return "$text\n";
}

sub run_cmd (@cmd) {
  my $err = Symbol::gensym();
  my $pid = IPC::Open3::open3(my $in, my $out, $err, @cmd);
  close $in;

  local $/;
  my $stdout = <$out> // '';
  my $stderr = <$err> // '';

  waitpid($pid, 0);
  my $exit = $? >> 8;

  my $combined = $stdout . $stderr;
  return ($exit == 0 ? 1 : 0, $combined);
}
