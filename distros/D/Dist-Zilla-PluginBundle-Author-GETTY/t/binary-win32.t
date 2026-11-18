#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Path::Tiny;

use Dist::Zilla::Plugin::Author::GETTY::Binary;

# The local binary check of dzil build (Binary::after_build) on native Windows,
# exercised on any platform by setting $^O to MSWin32 around the calls. The
# Win32 branches only ever run real processes that exist here too: sh (the
# tests need one) and a stub that stands in for $^X and records its argv. On
# Linux that argv is what Perl hands to execve, i.e. the very strings
# create_command_line would join into the CreateProcess command line, so the
# command line is rebuilt from them and parsed by a reference parser of the
# MSVCRT rules.
# No network, no pp, no Perl::Packer.

my ($SH) = grep { -x $_ } map { File::Spec->catfile($_, 'sh') } grep { length } File::Spec->path;
plan skip_all => 'no sh on PATH' unless $SH;

my $CLASS = 'Dist::Zilla::Plugin::Author::GETTY::Binary';
my $tmp   = path(tempdir(CLEANUP => 1));

# A plugin without a zilla: the real accessors, a log_fatal that dies.
{
  package T::Binary;
  our @ISA = ($CLASS);
  sub log       { }
  sub log_fatal { die "FATAL: $_[1]\n" }
}

sub plugin {
  my (%a) = @_;
  return bless { binary_name => 'foo', script => 'bin/foo', modules => [], %a }, 'T::Binary';
}

# Reference parser of the C runtime's rules for the arguments after the program
# name: 2n backslashes + " -> n backslashes and a quote toggle; 2n+1 backslashes
# + " -> n backslashes and a literal "; backslashes elsewhere are literal;
# blanks outside quotes end an argument.
sub msvcrt_split {
  my ($line) = @_;
  my @args;
  my ($cur, $started, $inq, $bs) = ('', 0, 0, 0);
  for my $c (split //, $line) {
    if ($c eq '\\') { $bs++; next }
    if ($c eq '"') {
      $cur .= '\\' x int($bs / 2);
      if ($bs % 2) { $cur .= '"' } else { $inq = !$inq }
      ($started, $bs) = (1, 0);
      next;
    }
    $cur .= '\\' x $bs;
    $started = 1 if $bs;
    $bs = 0;
    if ($c =~ /[ \t]/ && !$inq) {
      if ($started) { push @args, $cur; ($cur, $started) = ('', 0) }
      next;
    }
    $cur .= $c;
    $started = 1;
  }
  $cur .= '\\' x $bs;
  $started = 1 if $bs;
  push @args, $cur if $started;
  return @args;
}

# What Perl does with the argument list on Win32: join with blanks (an
# argument that starts and ends in " is passed as it is), then the child parses.
sub child_view { return msvcrt_split(join ' ', @_) }

# --- the reference parser itself -------------------------------------------

is_deeply [ msvcrt_split('a "b c" "" d\\"e "f\\\\" g') ], [ 'a', 'b c', '', 'd"e', 'f\\', 'g' ],
  'reference parser: quoted words, empty argument, \\" literal, \\\\" closes';

# A section that dies (a missing function) fails instead of ending the file.
sub block {
  my ($name, $code) = @_;
  eval { $code->(); 1 } or fail("$name died: $@");
}

# --- _win32_arg --------------------------------------------------------------

my @ARGS = (
  '',
  '"',
  'ends\\',
  'C:\\a b\\',
  '%PATH%',
  '^&|<>()',
  'say "hi"',
  'tr\\"ail',
  'two\\\\"quotes\\\\',
  'plain',
  "tab\there",
  '-a',
  'x y;lib/z',
);

block '_win32_arg' => sub {
for my $arg (@ARGS) {
  my $q = $CLASS->can('_win32_arg')->($arg);
  (my $label = $arg) =~ s/\t/<TAB>/g;
  ok $q =~ /\A".*"\z/s, "_win32_arg: [$label] is wrapped in quotes (create_command_line passes it unchanged)";
  is_deeply [ child_view($q) ], [ $arg ], "_win32_arg: [$label] survives the round trip through the MSVCRT parser";
}
is_deeply [ child_view(map { $CLASS->can('_win32_arg')->($_) } @ARGS) ], \@ARGS,
  '_win32_arg: all of them on one command line come back as the same list';
is $CLASS->can('_win32_arg')->(''), '""', '_win32_arg: the empty argument is ""';
is $CLASS->can('_win32_arg')->('a\\'), '"a\\\\"', '_win32_arg: a trailing backslash is doubled, or it would escape the closing quote';
is $CLASS->can('_win32_arg')->('a"b'), '"a\\"b"', '_win32_arg: an embedded quote is escaped';
};

# --- the stub that records its argv ------------------------------------------

my $log  = $tmp->child('log');
$log->mkpath;
my $stub = $tmp->child('stub');
$stub->spew(<<'SH');
#!/bin/sh
# one raw argument per line; creates the file after -o (quotes stripped)
: > "$STUB_LOG/argv"
prev=
out=
for a in "$@"; do
  printf '%s\n' "$a" >> "$STUB_LOG/argv"
  b=${a#\"}
  b=${b%\"}
  [ "$prev" = -o ] && out=$b
  prev=$b
done
[ -n "$out" ] && printf x > "$out"
exit ${STUB_EXIT:-0}
SH
chmod 0755, "$stub";
$ENV{STUB_LOG} = "$log";

sub argv { return [ split /\n/, $log->child('argv')->slurp ] }

# --- _find_pp -----------------------------------------------------------------

block '_find_pp' => sub {
  my $dir = $tmp->child('findpp');
  $dir->mkpath;
  $dir->child('pp')->spew("#!/usr/bin/perl\n");
  chmod 0644, $dir->child('pp');
  local $ENV{PATH} = "$dir";
  my $find = $CLASS->can('_find_pp');

  is $find->(), undef, '_find_pp: a pp that is not executable is not found on Unix';
  {
    local $^O = 'MSWin32';
    is $find->(), File::Spec->catfile("$dir", 'pp'), '_find_pp: on MSWin32 the non-executable pp (a script next to pp.bat) is found';
  }
  chmod 0755, $dir->child('pp');
  is $find->(), File::Spec->catfile("$dir", 'pp'), '_find_pp: an executable pp is found on Unix';
  $dir->child('pp')->remove;
  {
    local $^O = 'MSWin32';
    is $find->(), undef, '_find_pp: no pp, not found on MSWin32 either';
  }
  $dir->child('pp')->mkpath;   # a directory called pp
  {
    local $^O = 'MSWin32';
    is $find->(), undef, '_find_pp: a directory called pp is no pp';
  }
};

# --- _run_pp ------------------------------------------------------------------

block '_run_pp' => sub {
  my @cmd = ("$stub", '-o', $tmp->child('o1')->stringify, 'a b', 'say "hi"', 'C:\\a b\\', '', 'last');

  my $rc = $CLASS->can('_run_pp')->(@cmd);
  is $rc, 0, '_run_pp (Unix): runs the command';
  is_deeply argv(), [ @cmd[ 1 .. $#cmd ] ], '_run_pp (Unix): the argv is unchanged';

  {
    local $^O = 'MSWin32';
    local $^X = "$stub";
    my @win = ('/some/dir/pp', '-o', $tmp->child('o2')->stringify, 'a b', 'say "hi"', 'C:\\a b\\', '', '%PATH%');
    $rc = $CLASS->can('_run_pp')->(@win);
    is $rc, 0, '_run_pp (MSWin32): runs $^X';
    my @seen = @{ argv() };
    is_deeply \@seen, [ map { $CLASS->can('_win32_arg')->($_) } @win ],
      '_run_pp (MSWin32): $^X gets pp as its script and every argument quoted by _win32_arg';
    is_deeply [ child_view(@seen) ], \@win,
      '_run_pp (MSWin32): the child process parses the command line back to the original arguments (pp path first)';
    ok $tmp->child('o2')->exists, '_run_pp (MSWin32): the stub ran and found its -o';

    local $ENV{STUB_EXIT} = 3;
    $rc = $CLASS->can('_run_pp')->(@win);
    is $rc >> 8, 3, '_run_pp (MSWin32): the exit status of the command is returned';
  }
};

# --- _pp_args_output ----------------------------------------------------------

block '_pp_args_output' => sub {
  my $specials = q{printf '%s|' "a  b" '{a,b}' '\\\\' '*' 'say "hi"'; printf '%s' "$DZIL_BINARY_PP_ARGS"};
  my $fixed    = q{a  b|{a,b}|\\\\|*|say "hi"|};
  my $self     = plugin();

  {
    local $^O = 'MSWin32';
    local $ENV{DZIL_BINARY_PP_ARGS} = 'previous value';
    my $out = $self->_pp_args_output($specials);
    is $out, $fixed . $specials,
      '_pp_args_output (MSWin32): the command (", double blank, {a,b}, \\\\, *) reaches sh unchanged, handed over in DZIL_BINARY_PP_ARGS';
    is $ENV{DZIL_BINARY_PP_ARGS}, 'previous value', '_pp_args_output (MSWin32): %ENV is restored';
  }
  {
    local $^O = 'MSWin32';
    delete local $ENV{DZIL_BINARY_PP_ARGS};
    $self->_pp_args_output($specials);
    ok !exists $ENV{DZIL_BINARY_PP_ARGS}, '_pp_args_output (MSWin32): an unset variable is unset again';
  }
  {
    my $out = $self->_pp_args_output($specials);
    is $out, $fixed, '_pp_args_output (Unix): the same command, no environment hand-over';
  }

  # an empty pp_args starts no sh
  my $nosh = $tmp->child('nosh');
  $nosh->mkpath;
  {
    local $^O = 'MSWin32';
    local $ENV{PATH} = "$nosh";
    my $out = eval { $self->_pp_args_output('') };
    is $out, '', '_pp_args_output (MSWin32): empty pp_args yields no output, and needs no sh (PATH without sh)';
    is $@, '', '... and does not die';
    local $SIG{__WARN__} = sub { };   # perl's "Can't exec sh"
    $out = eval { $self->_pp_args_output('echo x') };
    like $@, qr/\AFATAL: cannot run binary_pp_args of foo: /,
      '_pp_args_output (MSWin32): a non-empty command does need sh (the previous test is not vacuous)';
  }

  for my $os ('linux', 'MSWin32') {
    local $^O = $os;
    eval { $self->_pp_args_output('echo partial; exit 3') };
    is $@, "FATAL: binary_pp_args of foo failed: echo partial; exit 3\n",
      "_pp_args_output ($os): a failing command fails the build with its text";
  }
};

# --- _run_hook ----------------------------------------------------------------

block '_run_hook' => sub {
  my $dblog = $tmp->child('hook.log');
  local $ENV{DBLOG} = "$dblog";
  my $cmd = q{printf '%s\n' "$0" "$#" "$1" "$DZIL_BINARY_HOOK" "$DZIL_BINARY_OUT" 'q "x"  {a,b} \\\\ *' > "$DBLOG"; :};
  my $out = '/with space/NAME.exe';
  my $script = "$cmd \"\$@\"";

  {
    local $^O = 'MSWin32';
    local $ENV{DZIL_BINARY_HOOK} = 'old hook';
    delete local $ENV{DZIL_BINARY_OUT};
    my $rc = $CLASS->can('_run_hook')->($cmd, $out);
    is $rc, 0, '_run_hook (MSWin32): runs';
    is_deeply [ split /\n/, $dblog->slurp ], [ 'sh', 1, $out, $script, $out, q{q "x"  {a,b} \\\\ *} ],
      '_run_hook (MSWin32): $0 is sh, $# is 1, $1 the binary; the script and the path travel in the environment; the command is unchanged';
    is $ENV{DZIL_BINARY_HOOK}, 'old hook', '_run_hook (MSWin32): DZIL_BINARY_HOOK is restored';
    ok !exists $ENV{DZIL_BINARY_OUT}, '_run_hook (MSWin32): DZIL_BINARY_OUT is unset again';
  }
  $dblog->remove;
  {
    my $rc = $CLASS->can('_run_hook')->($cmd, $out);
    is $rc, 0, '_run_hook (Unix): runs';
    is_deeply [ split /\n/, $dblog->slurp ], [ 'sh', 1, $out, '', '', q{q "x"  {a,b} \\\\ *} ],
      '_run_hook (Unix): the same $0, $#, $1, and no environment hand-over';
  }
  for my $os ('linux', 'MSWin32') {
    local $^O = $os;
    my $rc = $CLASS->can('_run_hook')->('exit 4', $out);
    is $rc >> 8, 4, "_run_hook ($os): the exit status is returned";
  }
};

# --- after_build ----------------------------------------------------------------

sub build_root {
  my ($name) = @_;
  my $root = $tmp->child($name);
  $root->child('lib')->mkpath;
  $root->child('bin')->mkpath;
  $root->child('bin', 'foo')->spew("#!/usr/bin/env perl\n1;\n");
  return $root;
}

my $PPARGS = q{printf '%s\n' -a "x y;lib/z"};

# Unix: pp is found and run directly, the binary is NAME.
block 'after_build Unix' => sub {
  my $root = build_root('unix-build');
  my $bindir = $tmp->child('unix-bin');
  $bindir->mkpath;
  $bindir->child('pp')->spew($stub->slurp);
  chmod 0755, $bindir->child('pp');
  my $hooklog = $tmp->child('unix-hooks');
  local $ENV{PATH} = "$bindir:$ENV{PATH}";
  local $ENV{DBLOG} = "$hooklog";
  delete local $ENV{DZIL_BINARY_SKIP};
  my $self = plugin(
    modules => ['A'], pp_args => $PPARGS,
    verify => q{printf '%s\n' verify >> "$DBLOG"; :}, smoke => q{printf '%s\n' smoke "$0" >> "$DBLOG"; :},
  );
  $self->after_build({ build_root => "$root" });
  my $sib = "$root-binaries";
  is_deeply argv(), [ '-o', "$sib/foo", '-I', "$root/lib", '-M', 'A', '-a', 'x y;lib/z', "$root/bin/foo" ],
    'after_build (Unix): the pp argv is unchanged';
  ok -f "$sib/foo", 'after_build (Unix): the binary is NAME';
  ok !-e "$sib/foo.exe", 'after_build (Unix): ... not NAME.exe';
  is_deeply [ split /\n/, $hooklog->slurp ], [ 'verify', 'smoke', 'sh' ], 'after_build (Unix): verify, then smoke';
};

# MSWin32: pp is found without the executable bit, run with $^X, the binary is NAME.exe.
block 'after_build MSWin32' => sub {
  my $root = build_root('win-build');
  my $bindir = $tmp->child('win-bin');
  $bindir->mkpath;
  $bindir->child('pp')->spew("not executable, a script next to pp.bat\n");
  chmod 0644, $bindir->child('pp');
  my $hooklog = $tmp->child('win-hooks');
  local $ENV{PATH} = "$bindir:$ENV{PATH}";
  local $ENV{DBLOG} = "$hooklog";
  delete local $ENV{DZIL_BINARY_SKIP};
  local $^O = 'MSWin32';
  local $^X = "$stub";
  my $self = plugin(
    modules => ['A'], pp_args => $PPARGS,
    verify => q{printf '%s\n' "verify $1 $DZIL_BINARY_OUT" >> "$DBLOG"; :}, smoke => q{printf '%s\n' smoke "$0" >> "$DBLOG"; :},
  );
  $self->after_build({ build_root => "$root" });
  my $sib = "$root-binaries";
  my $pp  = File::Spec->catfile("$bindir", 'pp');
  my @seen = @{ argv() };
  is_deeply [ child_view(@seen) ],
    [ $pp, '-o', "$sib/foo.exe", '-I', "$root/lib", '-M', 'A', '-a', 'x y;lib/z', "$root/bin/foo" ],
    'after_build (MSWin32): the child of $^X parses pp, then the same pp arguments, the binary NAME.exe';
  ok -f "$sib/foo.exe", 'after_build (MSWin32): the binary is NAME.exe';
  ok !-e "$sib/foo", 'after_build (MSWin32): ... not NAME';
  is_deeply [ split /\n/, $hooklog->slurp ], [ "verify $sib/foo.exe $sib/foo.exe", 'smoke', 'sh' ],
    'after_build (MSWin32): verify and smoke get NAME.exe as $1 and in DZIL_BINARY_OUT';

  # the failure messages
  my $fail = plugin(pp_args => 'exit 3');
  eval { $fail->after_build({ build_root => "$root" }) };
  is $@, "FATAL: binary_pp_args of foo failed: exit 3\n", 'after_build (MSWin32): a failing binary_pp_args names binary and command';

  $fail = plugin(verify => 'exit 1');
  eval { $fail->after_build({ build_root => "$root" }) };
  is $@, "FATAL: binary_verify failed for foo: exit 1\n", 'after_build (MSWin32): a failing binary_verify names binary and command';

  $fail = plugin(smoke => 'exit 1');
  eval { $fail->after_build({ build_root => "$root" }) };
  is $@, "FATAL: binary_smoke failed for foo: exit 1\n", 'after_build (MSWin32): a failing binary_smoke names binary and command';

  # pp found, but $^X cannot be started (system returns -1)
  {
    my $enoent = do { local $! = 2; "$!" };
    local $^X = "$tmp/no/such/perl";
    local $SIG{__WARN__} = sub { };   # perl's "Can't exec ..."
    eval { plugin()->after_build({ build_root => "$root" }) };
    is $@, "FATAL: cannot run pp for binary foo: $enoent\n",
      'after_build (MSWin32): an unstartable $^X dies with the reason from $!, no exit code';
  }

  # pp runs and fails
  {
    local $ENV{STUB_EXIT} = 4;
    eval { plugin()->after_build({ build_root => "$root" }) };
    is $@, "FATAL: pp failed for binary foo (exit 4)\n", 'after_build (MSWin32): a failing pp names binary and exit code';
  }

  # nothing found
  local $ENV{PATH} = "$tmp/nowhere";
  eval { plugin()->after_build({ build_root => "$root" }) };
  like $@, qr/pp not found in PATH/, 'after_build (MSWin32): no pp at all still dies with the hint';
};

# --- the hook environment: PERL5LIB out, DZIL_BINARY_PERL5LIB for verify only (k32) ---

# What the hook sees: "PERL5LIB:<set|unset> DZIL_BINARY_PERL5LIB:<set|unset>=<value>".
my $SEEN = q{printf '%s\n' "PERL5LIB:$(if [ "${PERL5LIB+y}" ]; then echo set; else echo unset; fi) DZIL_BINARY_PERL5LIB:$(if [ "${DZIL_BINARY_PERL5LIB+y}" ]; then echo set; else echo unset; fi)=${DZIL_BINARY_PERL5LIB-}" >> "$DBLOG"; :};

block '_run_hook environment' => sub {
  for my $os ('linux', 'MSWin32') {
    local $^O = $os;
    my $log = $tmp->child("runhook-$os.log");
    local $ENV{DBLOG} = "$log";
    local $ENV{PERL5LIB} = '/caller/lib';
    local $ENV{DZIL_BINARY_PERL5LIB} = 'stale';
    my $seen = sub {
      my ($p5) = @_;
      $log->remove;
      $CLASS->can('_run_hook')->($SEEN, '/x/NAME', $p5) == 0 or die "hook failed";
      return scalar $log->slurp;
    };
    is $seen->('X'), "PERL5LIB:unset DZIL_BINARY_PERL5LIB:set=X\n",
      "_run_hook ($os): a third parameter reaches the hook as DZIL_BINARY_PERL5LIB, PERL5LIB is gone";
    is $seen->(''), "PERL5LIB:unset DZIL_BINARY_PERL5LIB:set=\n",
      "_run_hook ($os): an empty third parameter sets DZIL_BINARY_PERL5LIB, empty";
    is $seen->(undef), "PERL5LIB:unset DZIL_BINARY_PERL5LIB:unset=\n",
      "_run_hook ($os): no third parameter leaves DZIL_BINARY_PERL5LIB unset, a stale caller's value too";
    is $ENV{PERL5LIB}, '/caller/lib', "_run_hook ($os): the caller's PERL5LIB is restored";
    is $ENV{DZIL_BINARY_PERL5LIB}, 'stale', "_run_hook ($os): the caller's DZIL_BINARY_PERL5LIB is restored";
  }
};

# after_build: verify gets the caller's PERL5LIB in DZIL_BINARY_PERL5LIB, smoke gets neither.
block 'after_build hook environment' => sub {
  my $n = 0;
  for my $os ('linux', 'MSWin32') {
    for my $p5 ('/caller/lib/perl5', undef) {
      my $label = "after_build ($os, caller PERL5LIB " . (defined $p5 ? 'set' : 'unset') . ')';
      my $root   = build_root('envhook-' . $n++);
      my $bindir = $tmp->child("envhook-bin-$n");
      $bindir->mkpath;
      $bindir->child('pp')->spew($stub->slurp);
      chmod 0755, $bindir->child('pp');
      my $log = $tmp->child("envhook-$n.log");
      local $ENV{PATH} = "$bindir:$ENV{PATH}";
      local $ENV{DBLOG} = "$log";
      delete local $ENV{DZIL_BINARY_SKIP};
      delete local $ENV{PERL5LIB};
      local $ENV{PERL5LIB} = $p5 if defined $p5;
      local $ENV{DZIL_BINARY_PERL5LIB} = 'stale-from-caller';
      local $^O = $os;
      local $^X = "$stub" if $os eq 'MSWin32';
      plugin(verify => $SEEN, smoke => $SEEN)->after_build({ build_root => "$root" });
      my $want_v = defined $p5 ? "PERL5LIB:unset DZIL_BINARY_PERL5LIB:set=$p5" : "PERL5LIB:unset DZIL_BINARY_PERL5LIB:set=";
      is_deeply [ split /\n/, $log->slurp ], [ $want_v, 'PERL5LIB:unset DZIL_BINARY_PERL5LIB:unset=' ],
        "$label: verify gets DZIL_BINARY_PERL5LIB (the caller's PERL5LIB, empty without) and no PERL5LIB; smoke gets neither, a stale value included";
      is $ENV{PERL5LIB}, $p5, "$label: PERL5LIB is restored";
      is $ENV{DZIL_BINARY_PERL5LIB}, 'stale-from-caller', "$label: DZIL_BINARY_PERL5LIB is restored";
    }
  }
};

done_testing;
