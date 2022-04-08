#!/usr/bin/perl -w
use strict;
use File::Path 'mkpath';
use File::Copy 'copy';
use Config;

my $VERSION = '1.08';			# Changelog at end
die "Debugging cycle detected"		# set to -1 to allow extra iteration
  if ++$ENV{PERL_DEBUG_MCODE_CYCLE} > 1;

my %opt;
$opt{$1} = shift while ($ARGV[0] || 0) =~ /^-([dq1OBU])$/;
if ($opt{1}) {
  open STDERR, '>&STDOUT' or warn "can't redirect STDERR to STDOUT";
} else {
  open STDOUT, '>&STDERR' or warn "can't redirect STDOUT to STDERR";
}

my $bd = (my $bd0 = 'dbg-bld') . ($opt{O} || '');
@ARGV >= 1 or die <<EOP;

Usage:
 $0 [-B] [-U] [-d] [-q] [-1] [-O] check-module [failing-script1 failing-script2 ...]

A tool to simplify remote debugging of build problems for XSUB modules.
By default, output goes to STDERR (to pass through the test suite wrappers).

If CHECK-MODULE is non-empty (and not 0) checks whether it may be
loaded (with -Mblib).  If any problem is detected, outputs the MakeMaker
arguments (extracted from the generated Makefiles).  

If CHECK-MODULE is empty (or 0), or if FAILING-SCRIPTS are present, 
rebuilds the current distribution with debugging (in subdirectory $bd),
and machine-code-debugs Perl crash when running each FAILING-SCRIPT.
Outputs as much info about the crash as it can massage from gdb, or
dbx, or lldb.

Some minimal intelligence to avoid a flood of useless information is applied:
if CHECK-MODULE cannot be loaded (but there is no crash during loading), no
debugging for FAILING-SCRIPTs is done.

Options:	With -d, prefers dbx to gdb (DEFAULT: prefer gdb).
		With -q and no FAILING-SCRIPTs, won't print anything unless a
			failure of loading is detected.
		With -1, all our output goes to STDOUT.
		With -O, makes a non-debugging build.
		With -B, builds in a subdirectory even if no debugger was found.
		With -U will reuse the build directory if present.

Assumptions:
  Should be run in the root of a distribution, or its immediate subdir.
  Running Makefile.PL with OPTIMIZE=-g builds debugging version.
	(Actually, v1.00 starts to massage CFLAGS, LDFLAGS and DLLDFLAGS too.)
  If FAILING-SCRIPTs are relative paths, they should be local w.r.t. the
	root of the distribution.
  gdb (or dbx, lldb) is fresh enough to understand the options we throw in.
  Building in a subdirectory does not break a module (e.g., there is
	no dependence on its position in its parent distribution, if any).

Creates a subdirectory ./$bd0 or  ./${bd0}O.  Add them to `clean' in Makefile.PL
(add also the temporary files triggering running this script, if applicable).

			Version: $VERSION
EOP
$bd .= ($opt{O} || '');

my ($chk_module) = (shift);

sub report_Makefile ($) {
  my($f, $in) = (shift, '');
  print STDERR "# reporting $f header:\n# ==========================\n";
  open M, "< $f" or die "Can't open $f";
  ($in =~ /ARGV/ and print STDERR $in), $in = <M> while defined $in and $in !~ /MakeMaker \s+ Parameters/xi;
  $in = <M>;
  $in = <M> while defined $in and $in !~ /\S/;
  print STDERR $in and $in = <M> while defined $in and $in =~ /^#/;
  close M;
  print STDERR "# ==========================\n";
}

# We assume that MANIFEST contains no filenames with spaces
chdir '..' or die "chdir ..: $!"
  if not -f 'MANIFEST' and -f '../MANIFEST';	# we may be in ./t

# Try to avoid debugging a code failing by some other reason than crashing.
# In principle, it is easier to do in the "trigger" code with proper BEGIN/END;
# just be extra careful, and recheck. (And we can be used standalone as well!)

# There are 4 cases detected below, with !@ARGV thrown in, one covers 8 types.
my($skip_makefiles, $mod_load_out);
if ($chk_module) {
  # Using blib may give a false positive (blib fails) unless distribution
  # is already built; but the cost is small: just a useless rebuild+test
  if (system $^X, q(-wle), q(use blib)) {
    warn <<EOW;

  Given that -Mblib fails, `perl Makefile.PL; make' was not run here yet...
  I can't do any intelligent pre-flight testing now;

EOW
    die "Having no FAILING-SCRIPT makes no sense when -Mblib fails"
      unless @ARGV;
    warn <<EOW;
  ... so I just presume YOU know that machine-code debugging IS needed...

EOW
    $skip_makefiles = 1;
  } else {	#`
    # The most common "perpendicular" problem is that a loader would not load DLL ==> no crash.
    # Then there is no point in running machine code debugging; try to detect this:
    my $mod_load = `$^X -wle "use blib; print(eval q(use $chk_module; 1) ? 123456789 : 987654321)" 2>&1`;
    # Crashes ==> no "digits" output; DO debug.  Do not debug if no crash, and no load
    if ($mod_load =~ /987654321/) { # DLL does not load, no crash
      $mod_load_out = `$^X -wle "use blib; use $chk_module" 2>&1`;
      warn "Module $chk_module won't load: $mod_load_out";
      @ARGV = ();		# machine-code debugging won't help
    } elsif ($mod_load =~ /123456789/) { # Loads OK
      # a (suspected) failure has a chance to be helped by machine-code debug
      ($opt{'q'} or warn(<<EOW)), exit 0 unless @ARGV;

Module loads without a problem.  (No FAILING-SCRIPT, so I skip debugging step.)

EOW
    }				# else: Crash during DLL load.  Do debug
  }
}
unless ($skip_makefiles) {
  report_Makefile($_) for grep -f "$_.PL" && -f, map "$_/Makefile", '.', <*>;
}
exit 0 unless @ARGV or not $chk_module;

my $dbxname = 'dbx';
my $gdb = `gdb --version` unless $opt{d};
my $dbx = `dbx -V -c quit` unless $gdb;
my $lldb = `lldb --version` unless $gdb or $dbx;	# untested
$dbx = `dbxtool -V` and $dbxname = 'dbxtool' unless $gdb or $dbx or $lldb;

sub find_candidates () {
  my($sep, @cand) = quotemeta $Config{path_sep};
  for my $dir (split m($sep), ($ENV{PATH} || '')) {
    for my $f (<$dir/*>) {
      push @cand, $f if $f =~ m{dbx|gdb|lldb}i and -x $f;
    }
  }
  warn 'Possible candidates for debuggers: {{{'. join('}}} {{{', @cand), '}}}' if @cand;
}

unless ($gdb or $dbx or $lldb) {
  find_candidates() unless $gdb = `gdb --version`;
}

sub report_no_debugger () {
  die "Can't find gdb or dbx or lldb" unless defined $gdb or defined $dbx or defined $lldb;
  die "Can't parse output of gdb --version: {{{$gdb}}}"
    unless $dbx or $lldb or $gdb =~ /\b GDB \b | \b Copyright \b .* \b Free Software \b/x;
  die "Can't parse output of `dbx -V -c quit': {{{$dbx}}}"
    unless $gdb or $lldb or $dbxname eq 'dbxtool' or $dbx =~ /\b dbx \s+ debugger \b/xi;
  warn "Can't parse output of `dbxtool -V': {{{$dbx}}}"
    unless $gdb or $lldb or $dbxname eq 'dbx' or $dbx =~ /\b dbx \s+ debugger \b/xi;
  die "Can't parse output of lldb --version: {{{$lldb}}}"
    unless $dbx or $gdb or $lldb =~ /\b lldb-\S*\d/x;
}

$@ = '';
my $postpone = ( eval {report_no_debugger(); 1 } ? '' : "$@" );
if ($opt{B}) {
  warn "No debugger found.  Nevertheless, I build a new version per -B switch." if $postpone;
} else {
  die $postpone if $postpone;
}

my $build_was_OK = -f "$bd/autodebug-make-ok";
die "Directory $bd exist; won't overwrite" if -d $bd and not ($opt{U} and $build_was_OK);
mkdir $bd or die "mkdir $bd: $!" unless -d $bd;
chdir $bd or die "chdir $bd: $!";

sub do_subdir_build () {
  open MF, '../MANIFEST' or die "Can't read MANIFEST: $!";
  while (<MF>) {
    next unless /^\S/;
    s/\s.*//;
    my ($f, $d) = m[^((.*/)?.*)];
    -d $d or mkpath $d if defined $d;	# croak()s itself
    copy "../$f", $f or die "copy `../$f' to `$f' (inside $bd): $!";
  }
  close MF or die "Can't close MANIFEST: $!";

  my(@extraflags, $more, $subst) = 'OPTIMIZE=-g';
  # Work around bugs in Config: 'ccflags' may contain (parts???) of 'optimize'.
  if ($opt{O}) {			# Do not change debugging
    @extraflags = ();
  } elsif ($Config{ccflags} =~ s/(?<!\S)\Q$Config{optimize}\E(?!\S)//) {
    # e.g., Strawberry Perl
    $subst++;
  } elsif ($Config{gccversion} or $Config{cc} =~ /\b\w?cc\b/i) {	# assume cc-flavor
    #     http://www.cpantesters.org/cpan/report/ef2ee424-1c8e-11e6-b928-8293027c4940
    #     http://www.cpantesters.org/cpan/report/4837b230-1d9d-11e6-91cb-6b7bc172c7fc
    # Extra check:
    $more++ if $Config{optimize} =~ /(?<!\S)-O(\d*|[a-z]?)(?!\S)/;
  }
  if ($more or $subst) {
    my $FL;
    $subst++ if ($FL = $Config{ccflags}) =~ s/(?<!\S)-(s|O(\d*|[a-z]?)|fomit-frame-pointer)(?!\S)//g;
    push @extraflags, qq(CCFLAGS=$FL) if $subst;
    for my $f (qw(ldflags lddlflags)) {
      push @extraflags, qq(\U$f\E=$FL)
        if ($FL = $Config{$f}) =~ s/(?<!\S)-s(?!\S)//g;
    }
  }

  system $^X, 'Makefile.PL', @extraflags and die "system(Makefile.PL @extraflags): rc=$?";
  my $make = $Config{make};
  $make = 'make' unless defined $make;
  system $make and die "system($make): rc=$?";
  { open my $f, '>', 'autodebug-make-ok'; }	# Leave a footprint of a successful build
  warn "Renaming Makefile.PL to orig-Makefile.PL\n\t(to avoid recursive calls from Makefile.PL in the parent directory)";
  rename 'Makefile.PL', 'orig-Makefile.PL'; # ignore error
}

do_subdir_build() unless -f 'autodebug-make-ok';

die $postpone if $postpone;	# Reached without a debugger only with -B

my $p = ($^X =~ m([\\/]) ? $^X : `which perl`) || $^X;
chomp $p unless $p eq $^X;
my(@cmd, $ver, $ver_done, $cand_done, $dscript);

for my $script (@ARGV) {
  $script = "../$script" if not -f $script and -f "../$script";
  if ($gdb) {
    $ver = $gdb;
    my $gdb_in = 'gdb-in';
    open TT, ">$gdb_in" or die "Can't open $gdb_in for write: $!";
    # bt full: include local vars (not in 5.0; is in 6.5; is in 6.1, but crashes on 6.3:
	# http://www.cpantesters.org/cpan/report/2fffc390-afd2-11df-834b-ae20f5ac70d3)
    # disas /m : with source lines (FULL function?!) (not in 6.5; is in 7.0.1)
    # XXX all-registers may take 6K on amd64; maybe put at end?
    # sharedlibrary: present on 7.3.1 (2011)
    my $proc = (-d "/proc/$$" ? <<EOP : '');	# Not working on cygwin 2016, gdb v7.8??? Move to end
info proc mapping
echo \\n=====================================\\n\\n
EOP
    my $extra = '';
    $extra .= <<EOE if $^O =~ /cygwin|MSWin/;	# Present on 7.3.1 (2011)
info w32 thread-information-block
echo \\n=====================================\\n\\n
EOE
    print TT ($dscript = <<EOP);		# Slightly different order than dbx...
run -Mblib $script
echo \\n=====================================\\n\\n
bt
echo \\n=====================================\\n\\n
info all-registers
echo \\n=====================================\\n\\n
disassemble
echo \\n=====================================\\n\\n
bt 5 full
echo \\n=====================================\\n\\n
disassemble /m
echo \\n=====================================\\n\\n
${extra}info sharedlibrary
echo \\n=====================================\\n\\n
${proc}quit
EOP
    close TT or die "Can't close $gdb_in for write: $!";

    #open STDIN, $gdb_in or die "cannot open STDIN from $gdb_in: $!";
    @cmd = (qw(gdb -batch), "--command=$gdb_in", $p);
  } elsif ($lldb) {
    $ver = $lldb;
    warn <<EOW;

!!!!  I seem to have found LLDB, but extra work may be needed.  !!!
!!!!  If you see something like this:                           !!!

  (lldb) run -Mblib t/000_load-problem.t
  error: process exited with status -1 (developer mode is not enabled on this machine and this is a non-interactive debug session.)

!!!!  Inspect the following recipe                              !!!
!!!!     from https://developer.apple.com/forums/thread/678032  !!!

  	sudo DevToolsSecurity -enable
	Developer mode is now enabled.

!!!!  This was Step 1; it should lead to the following error:   !!!

  error: process exited with status -1 (this is a non-interactive debug session, cannot get permission to debug processes.)

!!!!  You also need Step 2 (security implications???):          !!!

	sudo dseditgroup -o edit -a UUU -t user _developer
	###   replace UUU with your user name.

!!!!  I'm crossing my virtual fingers and proceed.              !!!

EOW
    my $lldb_in = 'lldb-in';
    open TT, ">$lldb_in" or die "Can't open $lldb_in for write: $!";
    # bt full: include local vars (not in 5.0; is in 6.5; is in 6.1, but crashes on 6.3:
	# http://www.cpantesters.org/cpan/report/2fffc390-afd2-11df-834b-ae20f5ac70d3)
    # disas /m : with source lines (FULL function?!) (not in 6.5; is in 7.0.1)
    # XXX all-registers may take 6K on amd64; maybe put at end?
    # sharedlibrary: present on 7.3.1 (2011)
    my $proc = (-d "/proc/$$" ? <<EOP : '');	# Not working on cygwin 2016, gdb v7.8??? Move to end
script print "??? info proc mapping"
script print "\\n=====================================\\n"
EOP
    my $extra = '';
    $extra .= <<EOE if $^O =~ /cygwin|MSWin/;	# Present on 7.3.1 (2011)
script print "??? info w32 thread-information-block"
script print "\\n=====================================\\n"
EOE
    print TT ($dscript = <<EOP);		# Slightly different order than dbx...
run -Mblib $script
script print "\\n=====================================\\n"
bt
script print "\\n=====================================\\n"
frame variable
script print "\\n=====================================\\n"
register read
script print "\\n=====================================\\n"
disassemble --frame
script print "\\n=====================================\\n"
bt 5 full
script print "\\n=====================================\\n"
disassemble --frame --mixed
script print "\\n=====================================\\n"
image list
script print "\\n=====================================\\n"
image dump sections 
script print "\\n=====================================\\n"
register read --all
script print "\\n=====================================\\n"
${extra}${proc}quit
EOP
    close TT or die "Can't close $lldb_in for write: $!";

    #open STDIN, $gdb_in or die "cannot open STDIN from $gdb_in: $!";
    @cmd = (qw(lldb -batch -s), $lldb_in, $p);
  } else {			# Assume $script has no spaces or metachars
	# Linux: /proc/$proc/maps has the text map
	# Solaris: /proc/$proc/map & /proc/$proc/rmap: binary used/reserved
	#   /usr/proc/bin/pmap $proc (>= 2.5) needs -F (force) inside dbx
    $ver = $dbx;
    # where -v		# Verbose traceback (include function args and line info)
    # dump                  # Print all variables local to the current procedure
    # regs [-f] [-F]        # Print value of registers (-f/-F: SPARC only)
    # list -<n>             # List previous <n> lines (next with +)
    #   -i or -instr        # Intermix source lines and assembly code
    @cmd = ($dbxname, qw(-c),		# We do not do non-integer registers...
	    qq(run -Mblib $script; echo; echo =================================; echo; where -v; echo; echo =================================; echo; dump; echo; echo =================================; echo; regs; echo; echo =================================; echo; list -i +1; echo; echo =================================; echo; list -i -10; echo; echo =================================; echo; echo ============== up 1:; up; dump; echo; echo ============== up 2:; up; dump; echo; echo ============== up 3:; up; dump; echo; echo ============== up 4:; up; dump; echo ==============; /usr/proc/bin/pmap -F \$proc; quit),
	    $p);
  }
  warn "\nDebugger's version: $ver\n" unless $ver_done++;
  warn 'Running {{{', join('}}} {{{', @cmd), "}}}\n\n";
  if (system @cmd) {
    warn "Running @cmd: rc=$?", ($dscript ? "\n========= script begin\n$dscript\n========= script end\n\t" : '');
    find_candidates();
    die "I stop here,"
  }
}
1;

__END__

# Changelog:
0.01	Print version of the debugger at end
	For GDB, protect against non-present disassemble /m
0.02	Add process memory map (for gdb; for dbx at least under Solaris)
1.00	`use Config' for 'make'.
	Work around bugs in Config:
		'ccflags' may contain (parts???) of 'optimize'.
		Likewise for ldflags and lddlflags.
			(Checked on Strawberry Perl.)
	Use info sharedlibrary; w32 thread-information-block on Windows platforms.
	Better docs.
1.01	Better docs.
	Emit the child's command line before running.
	On newer Perls %Config::Config may be read-only.
	Move gdb report of /proc to the end (not working on cygwin 2016, gdb v7.8)
1.02	Scan and report possible candidates for a debugger.
	New option -B.
1.03	Misprint fixed in splitting $ENV{PATH}.
	Report candidates in more situations.
	Remove unused code.
	May try to open (failing) scripts in ../ (happens with Math::Pari if the build in a subdirectory "finds" a different version).
		XXX Propagate flags for Makefile.PL???
1.04	Try to support lldb (untested; mapping of /proc and w32 thread-information-block unsupported).
	Remove extra quoting from the Makefile.PL command-line.
1.05	Recognize version string of lldb.
	Add instructions for enabling security settings for lldb debugging (Apple???).
	report_no_debugger() was called twice.
	Debugger's version was reported too late (after a possible die()!).
	Were emitting a wrong section from Makefile's.
	Emit MakeMaker's ARGV from Makefile too.
1.06	Report the script if the debugger failed.
	Leave ./autodebug-make-ok in the build directory if make was successful.
	New option -U for using an existing directory with a successful build.
1.07	Update the error message if no debugger found.
	Inspect dbxtool as a way of debugging ???.  (untested)
	Report other debugger candidates if a run of a debugger fails.
1.08	Rename Makefile.PL in the subdirectory (to avoid recursive calls from Makefile.PL in the parent directory).
	Remove the corresponding warning from ./README too.