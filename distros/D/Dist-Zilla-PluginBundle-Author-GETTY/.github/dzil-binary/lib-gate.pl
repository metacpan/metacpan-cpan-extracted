#!/usr/bin/env perl
# No foreign shared library may be linked by the loader, any object inside the
# binary, or any object its first start extracts into the PAR cache (libperl, the
# inner executable); on Linux the highest GLIBC_x.y must stay within the floor.
#   lib-gate.pl <binary> <linux|macos|windows>
package DzilBinary::LibGate;
use strict;
use warnings;
use Archive::Zip qw( AZ_OK );
use File::Temp ();
use File::Find ();
use File::Spec ();
use File::Basename ();
use POSIX ();
use Time::HiRes ();

our $GLIBC_FLOOR = '2.28';
our $START_TIMEOUT = 60;   # seconds the start may take before it is killed

my @SYSTEM = (
  linux   => [ 'libc.so*', 'libm.so*', 'libpthread.so*', 'libdl.so*', 'librt.so*',
               'libutil.so*', 'libgcc_s.so*', 'ld-linux-*', 'linux-vdso*' ],
  macos   => [ '/usr/lib/*', '/System/*' ],
  windows => [ 'api-ms-*' ],
);
my %SYSTEM = @SYSTEM;

# the perl shared library the start must have extracted (matched on the basename)
my %PERL_LIB = ( linux => 'libperl.so*', macos => 'libperl.dylib', windows => 'perl5*.dll' );

sub glob_re {
  my ($g) = @_;
  my $re = join '.*', map { quotemeta } split /\*/, $g, -1;
  return qr/\A$re\z/i;
}

# A predicate: true for a library name the allowlist or a packed name covers.
sub covered {
  my ($allowed, $packed) = @_;
  my @re = map { glob_re($_) } @$allowed;
  my %packed = map { lc($_) => 1 } @$packed;
  return sub {
    my ($lib) = @_;
    my ($base) = $lib =~ m{([^/\\]+)\z};
    return $packed{lc $lib} || (defined $base && $packed{lc $base}) || scalar grep { $lib =~ $_ } @re;
  };
}

# %links: object => [library names]; returns sorted "lib (linked by object)" strings.
sub violations {
  my ($links, $allowed, $packed) = @_;
  my $covered = covered($allowed, $packed);
  my @v;
  for my $obj (keys %$links) {
    for my $lib (@{ $links->{$obj} }) {
      push @v, "$lib (linked by $obj)" unless $covered->($lib);
    }
  }
  return sort @v;
}

# The distinct library names violations() flags, sorted.
sub foreign {
  my ($links, $allowed, $packed) = @_;
  my $covered = covered($allowed, $packed);
  my %f = map { $_ => 1 } grep { !$covered->($_) } map { @$_ } values %$links;
  return sort keys %f;
}

sub glibc_cmp {
  my @a = split /\./, $_[0];
  my @b = split /\./, $_[1];
  while (@a || @b) {
    my ($x, $y) = (shift(@a) // 0, shift(@b) // 0);
    return $x <=> $y if $x != $y;
  }
  return 0;
}

sub glibc_max {
  my $max;
  for my $v (@_) { $max = $v if !defined $max || glibc_cmp($v, $max) > 0 }
  return $max;
}

# --- CLI side (needs ldd / otool / objdump and real objects) ---------------

sub unpack_archive {
  my ($archive, $dest) = @_;
  my $zip = Archive::Zip->new;
  die "cannot read $archive as an archive\n" unless $zip->read($archive) == AZ_OK;
  for my $m ($zip->members) {
    next if $m->isDirectory;
    my $n = $m->fileName;
    next if $n =~ m{(?:\A|/)\.\.(?:/|\z)} || $n =~ m{\A/};
    my $to = File::Spec->catfile($dest, split m{/}, $n);
    File::Path::make_path(File::Basename::dirname($to));
    $m->extractToFileNamed($to) == AZ_OK or die "cannot extract $n\n";
  }
}

sub is_native {
  my ($file) = @_;
  open my $fh, '<:raw', $file or return 0;
  read($fh, my $magic, 4);
  return 0 unless defined $magic && length $magic >= 2;
  return $magic =~ /\A(?:\x7fELF|MZ|\xfe\xed\xfa[\xce\xcf]|[\xce\xcf]\xfa\xed\xfe|\xca\xfe\xba\xbe)/s ? 1 : 0;
}

# Runs a tool; dies when it cannot be spawned (naming it). Returns (output, exit code).
sub run_tool {
  my ($merge_stderr, @cmd) = @_;
  return run_tool_win32($merge_stderr, @cmd) if $^O eq 'MSWin32';
  pipe(my $r, my $w) or die "pipe: $!\n";
  pipe(my $er, my $ew) or die "pipe: $!\n";   # exec-failure channel, closed on exec
  my $pid = fork // die "fork: $!\n";
  if (!$pid) {
    close $r; close $er;
    open STDOUT, '>&', $w or POSIX::_exit(127);
    open STDERR, '>&', $w or POSIX::_exit(127) if $merge_stderr;
    { exec @cmd }
    { my $o = select $ew; $| = 1; select $o }
    print $ew "$!";
    POSIX::_exit(127);
  }
  close $w; close $ew;
  my $out = do { local $/; <$r> };
  my $failed = do { local $/; <$er> };
  close $r; close $er;
  waitpid $pid, 0;
  die "cannot run $cmd[0]: $failed\n" if defined $failed && length $failed;
  die "$cmd[0] was killed by signal " . ($? & 127) . "\n" if $? & 127;
  return ($out // '', $? >> 8);
}

# Win32: fork is emulated there and pipe handles are not duplicated reliably
# into the pseudo-process (perlfork, BUGS), so the pipe + fork + exec above never
# sees EOF. A list-form pipe open spawns the tool directly. STDOUT only: the
# tool's STDERR stays the gate's, and merge_stderr (only ldd, Linux) dies.
# Win32 keeps only the low byte of an exit code and has no signals: a killed or
# crashed tool shows as that byte, the signal check never fires there.
sub run_tool_win32 {
  my ($merge_stderr, @cmd) = @_;
  die "cannot run $cmd[0]: merging its STDERR is not supported on MSWin32\n" if $merge_stderr;
  open my $fh, '-|', @cmd or die "cannot run $cmd[0]: $!\n";
  my $out = do { local $/; <$fh> };
  close $fh;   # false on a non-zero exit; $? holds the status either way
  die "cannot wait for $cmd[0]: $!\n" if $? == -1;
  die "$cmd[0] was killed by signal " . ($? & 127) . "\n" if $? & 127;
  return ($out // '', $? >> 8);
}

# Unix: the child leads its own process group, so a timeout takes the loader's
# children with it. Dies when the binary cannot be executed (naming it).
sub spawn_unix {
  my ($binary, $null) = @_;
  pipe(my $er, my $ew) or die "pipe: $!\n";   # exec-failure channel, closed on exec
  my $pid = fork // die "fork: $!\n";
  if (!$pid) {
    close $er;
    my $fail = sub { syswrite $ew, $_[0]; POSIX::_exit(127) };
    setpgrp(0, 0) or $fail->("setpgrp: $!");
    open(STDIN, '<', $null) && open(STDOUT, '>', $null) && open(STDERR, '>', $null)
      or $fail->("cannot open $null: $!");
    { exec { $binary } $binary, '--help' }
    $fail->("$!");
  }
  close $ew;
  my $failed = do { local $/; <$er> };
  close $er;
  if (defined $failed && length $failed) { waitpid $pid, 0; die "cannot start $binary: $failed\n" }
  return $pid;
}

# Win32 (fork is emulated there): spawn with system 1, STDOUT/STDERR pointed at
# the null device for the call and restored after it. The gate never reads
# stdin, so it stays on the null device.
sub spawn_win32 {
  my ($binary, $null) = @_;
  open STDIN, '<', $null or die "cannot open $null: $!\n";
  open my $out, '>&', \*STDOUT or die "cannot dup STDOUT: $!\n";
  open my $err, '>&', \*STDERR or die "cannot dup STDERR: $!\n";
  my ($pid, $why);
  if (open(STDOUT, '>', $null) && open(STDERR, '>', $null)) {
    $pid = system 1, File::Spec->canonpath($binary), '--help';   # C:/x -> C:\x for CreateProcess
    $why = "$!";
  }
  else { $why = "cannot open $null: $!" }
  open STDOUT, '>&', $out or die "cannot restore STDOUT: $!\n";
  open STDERR, '>&', $err or die "cannot restore STDERR: $!\n";
  die "cannot start $binary: $why\n" unless defined $pid && $pid > 0;
  return $pid;
}

# Starts the binary once as the install scripts' warm-up does: <binary> --help,
# stdin at EOF, output discarded, exit status ignored, the PAR cache in $cache
# (PAR_GLOBAL_TEMP is the exact cache directory). A start still running after
# $START_TIMEOUT seconds is killed with its process group (Unix) or process tree
# (Win32); a timeout alone is not a failure. Dies when it cannot be started.
sub start_binary {
  my ($binary, $cache) = @_;
  local $ENV{PAR_GLOBAL_TEMP} = $cache;
  my $null = File::Spec->devnull;
  my $pid = $^O eq 'MSWin32' ? spawn_win32($binary, $null) : spawn_unix($binary, $null);
  my $deadline = Time::HiRes::time() + $START_TIMEOUT;
  while (waitpid($pid, POSIX::WNOHANG()) == 0) {
    if (Time::HiRes::time() >= $deadline) {
      kill -9, $pid;   # negative signal: Unix the process group $pid leads, Win32 the process tree
      waitpid $pid, 0;
      print STDERR "$binary --help timed out after ${START_TIMEOUT}s: killed it with its ",
        ($^O eq 'MSWin32' ? 'process tree' : 'process group'), "; checking what the cache holds\n";
      return;
    }
    Time::HiRes::sleep(0.1);
  }
  return;
}

# native files anywhere under $dir, whatever their name: [ path, label ], sorted
sub cache_objects {
  my ($dir) = @_;
  my @found;
  File::Find::find({ no_chdir => 1, wanted => sub {
    push @found, $File::Find::name if -f $_ && is_native($_);
  } }, $dir);
  return map { [ $_, join '/', 'cache', File::Spec->splitdir(File::Spec->abs2rel($_, $dir)) ] } sort @found;
}

sub capture {
  my (@cmd) = @_;
  my ($out, $rc) = run_tool(0, @cmd);
  die "$cmd[0] failed (exit $rc) on $cmd[-1]\n" if $rc;
  return $out;
}

# ldd: only "not a dynamic executable" / "statically linked" may fail.
sub capture_ldd {
  my ($obj) = @_;
  my ($out, $rc) = run_tool(1, 'ldd', $obj);
  return $out if !$rc;
  return '' if $out =~ /not a dynamic|statically linked/;
  die "ldd failed (exit $rc) on $obj\n";
}

sub linked {
  my ($platform, $obj) = @_;
  my %seen;
  if ($platform eq 'linux') {
    for (split /\n/, capture_ldd($obj)) {
      if    (/^\s*(\S+)\s+=>/) { $seen{ File::Basename::basename($1) } = 1 }
      elsif (m{^\s*(/\S+|\S+)\s+\(0x}) { $seen{ File::Basename::basename($1) } = 1 }
    }
  }
  elsif ($platform eq 'macos') {
    my @l = split /\n/, capture('otool', '-L', $obj);
    shift @l;
    for (@l) {
      next unless /^\s+(\S+)\s+\(/;
      my $n = $1;
      $n = File::Basename::basename($n) if $n =~ /\A\@/;
      $seen{$n} = 1;
    }
  }
  else {
    for (split /\n/, capture('objdump', '-p', $obj)) { $seen{ lc $1 } = 1 if /DLL Name:\s*(\S+)/ }
  }
  return [ sort keys %seen ];
}

sub glibc_versions {
  my ($obj) = @_;
  my %v;
  my $out = capture('objdump', '-T', $obj);
  $v{$1} = 1 while $out =~ /GLIBC_(\d+(?:\.\d+)*)/g;
  return keys %v;
}

# What the gate judges, without the verdict: the links of the loader, of every
# object inside $archive and of every native file its first start extracts into
# the PAR cache, and the names of all of those (packed). $report gets the cache
# listing before the perl library check. Returns
# { links => { label => [names] }, packed => [names], glibc => { version => 1 }, checked => count }.
sub inspect_binary {
  my ($archive, $platform, $report) = @_;
  die "unknown platform '$platform' (linux, macos, windows)\n" unless $SYSTEM{$platform};
  my $tmp = File::Temp->newdir;
  unpack_archive($archive, "$tmp");

  my @objects;
  File::Find::find({ no_chdir => 1, wanted => sub {
    push @objects, $File::Find::name
      if -f $_ && /\.(?:so(?:\.[\d.]+)?|dylib|bundle|dll|pyd)\z/i;
  } }, "$tmp");
  my $packed_name = sub { $platform eq 'windows' ? lc File::Basename::basename($_[0]) : File::Basename::basename($_[0]) };
  my @packed = map { $packed_name->($_) } @objects;
  unshift @objects, $archive if is_native($archive);
  die "no shared objects to check in $archive: the gate proved nothing\n" unless @objects;

  my (%links, %glibc);
  my $inspect = sub {
    my ($o, $label) = @_;
    $links{$label} = linked($platform, $o);
    $glibc{$_} = 1 for $platform eq 'linux' ? glibc_versions($o) : ();
  };
  $inspect->($_, $_ eq $archive ? "$archive (loader)" : File::Spec->abs2rel($_, "$tmp")) for @objects;

  # libperl, the inner executable and PAR's own XS live in the loader, not in the
  # zip: only a start shows them
  my $cache = File::Temp->newdir;
  start_binary($archive, "$cache");
  my @cached = cache_objects("$cache");
  $report->("PAR cache after the start: " . scalar(@cached) . " object(s)\n", map({ "  $_->[1]\n" } @cached));
  my $perl_re = glob_re($PERL_LIB{$platform});
  die "the start extracted no perl library into PAR_GLOBAL_TEMP: the gate proved nothing about libperl\n"
    unless grep { File::Basename::basename($_->[0]) =~ $perl_re } @cached;
  for my $c (@cached) {
    $inspect->(@$c);
    push @packed, $packed_name->($c->[0]);
  }
  return { links => \%links, packed => \@packed, glibc => \%glibc, checked => @objects + @cached };
}

# The system libraries $platform's objects may link; on Windows also every name
# in %$links that System32 holds.
sub allowlist {
  my ($platform, $links) = @_;
  my @allowed = @{ $SYSTEM{$platform} };
  if ($platform eq 'windows') {
    my $sys = File::Spec->catdir($ENV{SystemRoot} // 'C:\\Windows', 'System32');
    my %names = map { $_ => 1 } map { @$_ } values %$links;
    push @allowed, map { quotemeta } grep { -e File::Spec->catfile($sys, $_) } sort keys %names;
    @allowed = map { s/\\//gr } @allowed;   # names have no '*', plain strings
  }
  return @allowed;
}

sub run {
  my ($archive, $platform) = @_;
  local $| = 1;   # nothing buffered on STDOUT when run_tool / the start fork
  my $seen = inspect_binary($archive, $platform, sub { print @_ });
  my %links = %{ $seen->{links} };
  my %glibc = %{ $seen->{glibc} };

  my @v = violations(\%links, [allowlist($platform, \%links)], $seen->{packed});
  my $fail = 0;
  if (@v) { print STDERR "foreign shared libraries:\n", map({ "  $_\n" } @v); $fail = 1 }
  if ($platform eq 'linux' && !%glibc) {
    print STDERR "glibc check did not run: no GLIBC_ version found in any object\n"; $fail = 1;
  }
  elsif ($platform eq 'linux') {
    my $max = glibc_max(keys %glibc);
    if (glibc_cmp($max, $GLIBC_FLOOR) > 0) {
      print STDERR "glibc $max needed, floor is $GLIBC_FLOOR\n"; $fail = 1;
    }
    else { print "highest glibc symbol version: $max (floor $GLIBC_FLOOR)\n" }
  }
  print "lib-gate $platform: $seen->{checked} object(s) checked, " . ($fail ? 'FAILED' : 'ok') . "\n";
  return $fail;
}

sub main {
  my ($archive, $platform) = @_;
  die "usage: lib-gate.pl <binary> <linux|macos|windows>\n" unless defined $platform;
  my $rc = eval { run($archive, $platform) };
  if ($@) { print STDERR $@; return 2 }
  return $rc;
}

require File::Path;
exit main(@ARGV) unless caller;
1;
