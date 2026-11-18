#!/usr/bin/env perl
# The full pp argv of one binary, NUL-terminated entries.
#   pp-args.pl <META.json> <name> <out> <dist_root>
package DzilBinary::PPArgs;
use strict;
use warnings;
use Cwd ();
use JSON::PP ();
use POSIX ();

# Same line rule as the bundle's local check: split on "\n" only, strip one
# trailing "\r", drop empty lines; one line is one argument.
sub pp_args_lines {
  my ($output) = @_;
  return grep { length } map { s/\r\z//r } split /\n/, $output;
}

# Same -M rule as the bundle's local check: each module as -M, a trailing ::*
# as ::**, every module below at any depth (pp takes one level for ::*), the
# namespace require-gate.pl checks for Glob::*.
sub pp_module_args {
  my (@modules) = @_;
  return map { ('-M', s/::\*\z/::**/r) } @modules;
}

# Runs `sh -c <cmd>` in $dir without an argument; dies if it fails.
sub run_in {
  my ($dir, $cmd) = @_;
  return run_in_win32($dir, $cmd) if $^O eq 'MSWin32';
  pipe(my $r, my $w) or die "pipe: $!\n";
  my $pid = fork // die "fork: $!\n";
  if (!$pid) {
    close $r;
    open STDOUT, '>&', $w or do { print STDERR "cannot redirect stdout: $!\n"; POSIX::_exit(127) };
    chdir $dir or do { print STDERR "cannot chdir to $dir: $!\n"; POSIX::_exit(127) };
    { exec 'sh', '-c', $cmd }
    print STDERR "cannot exec sh: $!\n"; POSIX::_exit(127);
  }
  close $w;
  my $out = do { local $/; <$r> };
  close $r;
  waitpid $pid, 0;
  die "binary_pp_args failed (exit " . ($? >> 8) . "): $cmd\n" if $?;
  return $out // '';
}

# Win32: fork is emulated there and pipe handles are not duplicated reliably
# into the pseudo-process (perlfork, BUGS), so the pipe + fork + exec above never
# sees EOF (the same fix as run_tool_win32 in lib-gate.pl). sh is started with a
# list-form pipe open from $dir; the parent's cwd is restored right after.
# $cmd does not travel on the command line: Perl joins the list into one
# CreateProcess command line without escaping an embedded " (win32.c,
# create_command_line), and the MSYS2 sh splits it again by rules of its own
# (' quotes too, \\ becomes \, words are globbed). It goes in the environment;
# the fixed script holds neither " nor \, and with IFS empty and globbing off
# the variable expands to exactly one word: a fresh sh -c <cmd>, as on Unix.
sub run_in_win32 {
  my ($dir, $cmd) = @_;
  return '' unless length $cmd;   # sh -c '' prints nothing; exec sh -c without a word fails
  my $back = Cwd::getcwd() // die "cannot read the current directory: $!\n";
  chdir $dir or die "cannot chdir to $dir: $!\nbinary_pp_args failed: $cmd\n";
  my ($fh, $why);
  my $started = do {
    local $ENV{DZIL_BINARY_PP_ARGS} = $cmd;
    my $ok = open $fh, '-|', 'sh', '-c', 'IFS=; set -f; exec sh -c $DZIL_BINARY_PP_ARGS';
    $why = "$!";   # before the local is undone: restoring %ENV may clobber errno
    $ok;
  };
  chdir $back or die "cannot chdir back to $back: $!\n";
  die "cannot run sh: $why\nbinary_pp_args failed: $cmd\n" unless $started;
  my $out = do { local $/; <$fh> };
  close $fh;   # false on a non-zero exit; $? holds the status either way
  die "binary_pp_args failed (exit " . ($? >> 8) . "): $cmd\n" if $?;
  return $out // '';
}

sub argv {
  my ($meta_file, $name, $out, $dist_root) = @_;
  open my $fh, '<:raw', $meta_file or die "cannot read $meta_file: $!\n";
  my $meta = eval { JSON::PP->new->decode(do { local $/; <$fh> }) };
  die "$meta_file is not valid JSON: $@" unless $meta;
  my $bins = ref $meta->{x_binaries} eq 'HASH' ? $meta->{x_binaries}{binaries} : undef;
  my $b = ref $bins eq 'HASH' ? $bins->{$name} : undef;
  die "no binary '$name' in x_binaries of $meta_file\n" unless ref $b eq 'HASH';
  die "binary '$name' has no script\n" unless defined $b->{script} && length $b->{script};

  my @extra = defined $b->{pp_args} ? pp_args_lines(run_in($dist_root, $b->{pp_args})) : ();
  return ('-o', $out, '-I', 'lib', pp_module_args(@{ $b->{modules} || [] }), @extra, $b->{script});
}

sub main {
  my (@args) = @_;
  die "usage: pp-args.pl <META.json> <name> <out> <dist_root>\n" unless @args == 4;
  my @argv = eval { argv(@args) };
  if ($@) { print STDERR $@; return 1 }
  binmode STDOUT;
  print "$_\0" for @argv;
  return 0;
}

exit main(@ARGV) unless caller;
1;
