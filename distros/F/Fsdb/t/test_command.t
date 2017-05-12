#!/usr/bin/perl

#
# test_command.t
# Copyright (C) 1997-2013 by John Heidemann
# $Id$
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

=head1 NAME

test_command.t - test programs based on standard input and output

=head1 SYNOPSIS

test_command.t [-uv] [TEST/file.cmd]

=head1 DESCRIPTION

This program does unit tests against a set of programs,
where we test that the standard output of the program is as expected.

What to run is given by the file TEST/file.cmd.
That file is a shell-script-like file that defines
what to run with what arguments, input, and output.

We then run the program and compare the generated output
to what was expected.

(Alternatively, we all TEST/*.cmd files.)

Defaults are reasonble, so by default 
TEST/file.cmd reads TEST/file.in and expects to produce
TEST/file.out with no arguments, compared with diff.
All of these defaults can be overridden.

If a test fails, the output is left in TEST/file.trial
and the output of the compare program in TEST/file.diff.

Output of the program is consistent with the Test Anything Protocol.

=head1 OPTIONS

=over

=item B[-u]
Update known-good debugging output in place.

=item B[-d]
Enable debugging output.

=item B[-v]
Enable verbose output.

=item B<--help>
Show help.

=item B<--man>
Show full manual.

=back

=head1 EXAMPLE USAGE

Some typical use cases.

By default, run all tests in TEST:

    perl test_command.t

Run a specific test:

    perl test_command.t TEST/dbcol_ex.cmd

Show exactly how the test is run (typically so one can run
the test by hand to debug it):

    perl test_command.t -v TEST/dbcol_ex.cmd

Update saved output, after a program has changed.
Use this when you know the program is correct, but the correct saved output
is now different;
it updates F<TEST/dbcol_ex.out>:

    perl test_command.t -u TEST/dbcol_ex.cmd


=head1 CMD FILE OPTIONS

The following keys can be given in the F<FILE.cmd> file:

=over
=item C<cmp>
What program to run to do comparison.
Default: C<diff -cb >.

=item C<prog>
What program to run.
No default.

=item C<in>
What to give to C<prog> on standard input.
Default: F<FILE.in>.

=item C<out>
Expected correct output to compare standard output of C<prog> against.
Default: F<FILE.out>.

=item C<altout>
An alternative possible output to accept as correct.
Default: none.

=item C<cmd_tail>
Arbitrary arguments  to put after the command
(but before redirection).
Default: no additional arguments.

=item C<enabled>
Enable commands if non-zero, or disable if zero.
Default: 1 (enabled).

=item C<requires>
Perl modules that must exist or the command will be skipped.
Default: none.

=item C<suppress_warnings>
A ";" separated list of warnings that should be filtered out
of any output.
Default: none.

=item C<expected_exit_code>
How the program should exit (the program's "exit code").
By default, programs with non-zero exit are considered to fail,
unless this value is changed.
Default: 0 (correct execution).

=item C<cleanup>
An arbitrary shell command to run after running the test.
Default: none.

=back

=cut

use Test::More;
use Pod::Usage;
use Getopt::Long;
use File::Copy qw(mv cp);
use Config; # to get $Config{perlpath}

Getopt::Long::Configure ("bundling");
pod2usage(2) if ($#ARGV >= 0 && $ARGV[0] eq '-?');
#my(@orig_argv) = @ARGV;
my($prog) = $0;
my $debug = undef;
my $verbose = undef;
my $update = undef;
&GetOptions('d|debug+' => \$debug,   
 	'help' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-verbose => 2); },
	'u|update!' => \$update,
         'v|verbose+' => \$verbose) or &pod2usage(2);

my $src_root = ".";
chdir $src_root or die "$0: cannot chdir $src_root\n";
foreach (qw(README Makefile.PL Makefile)) {
    die "test_command.t: must be run from the Fsdb source root directory.\n\t(can't find $_)\n"
	if (! -f $_);
};

#
# now all releative to src root:
#
my $test_dir = "TEST";

my $env_cmd = '';
#
# set up a possible experimental working directory.
#
my $scripts_dir = "blib/script";
my $lib_dir = "blib/lib";
if (defined($ENV{PERLLIB})) {
    # xxx: not portable separator
    $ENV{PERLLIB} = $lib_dir . ":" . $ENV{PERLLIB};
    $env_cmd .= "PERLLIB=$lib_dir:\$PERLLIB ";
} else {
    $ENV{PERLLIB} = $lib_dir;
    $env_cmd .= "PERLLIB=$lib_dir ";
};
$ENV{PATH} = "$scripts_dir:" . $ENV{PATH};
$env_cmd .= "PATH=$scripts_dir:\$PATH ";

#
# what to run?
#
my @failed_tests = ();
my @TESTS = @ARGV;
if ($#TESTS == -1) {
    @TESTS = glob "$test_dir/*.cmd";
};

plan tests => ($#TESTS + 1);

foreach my $test (@TESTS) {
    ok(run_one($test), $test);
};

#
# show output
#
if ($#failed_tests >= 0) {
    diag "#### output of some failed tests\n";
    my $shown_count = 0;
    foreach my $failure (@failed_tests) {
	last if ($shown_count++ > 3);  # don't go overboard
	show_failure($failure);
    };
};

exit 0;

sub show_failure($) {
    my($cmd_base) = @_;
    my $diff_fn = "$cmd_base.diff";
    diag "# $cmd_base\n";
    if (-f $diff_fn) {
        open(DIFF, "< $diff_fn") || return undef;
	my $lines = 0;
	while (<DIFF>) {
	    if ($lines++ > 65) {
		# cap output to a reasonable amount
	    	diag "\t...";
		last;
	    };
	    diag "\t$_";
	};
	close DIFF;
    } else {
	diag "\t(no diff output)\n";
    };
}

#
# the .cmd is a pseudo-shell-script like thing.
# Parse that here.
#
sub parse_cmd_file($) {
    my($cmd_file) = @_;
    my %opts;
    open(CMD, "<$cmd_file") or die "$0: cannot read $cmd_file\n";
    while (<CMD>) {
	chomp;
	next if (/^\s*\#/);
	next if (/^\s*$/);
	my($key, $value) = /([^=]+)=(.*)$/;
	if (!defined($key) || !defined($value)) {
	    warn "confusion on cmd_file $cmd_file, line: $_\n";
	    next;
	};
	$value =~ s/^'(.*)'$/$1/;  # only support single quotes, allowing doubles to pass through to shell
	$opts{$key} = $value;
    };
    close CMD;
    return \%opts;
};

sub fix_prog_path($) {
    my ($prog) = @_;
    return $Config{perlpath} if ($prog eq 'perl');
    return $prog if ($prog =~ /^(\|\s*)?(\/|cmp|diff|false|perl|sh)\b/);
    my($head, $tail) = ($prog =~ /^(\|\s*)?([^| ].*)$/);
    $head = '' if (!defined($head));
    return $head . $scripts_dir . "/" . $tail;
}

sub diff_output($$$$$$) {
    my($cmd_base, $out, $trial, $cmp, $cmp_needs_input_flags, $altout_p) = @_;
    if (! -e $out) {
	diag "    test $cmd_base is missing output $out\n";
	return undef;
    };
    $cmp = fix_prog_path($cmp);
    my($input_flag) = '';
    my($cmp_env) = '';
    if (defined($cmp_needs_input_flags) && $cmp_needs_input_flags ne 'false') {
	$input_flag = '--input';
	$cmp_env = $env_cmd;
    };
    my $diff_cmd = "$cmp_env $cmp $input_flag $out $input_flag $cmd_base.trial >$cmd_base.diff";
    # print "$diff_cmd\n";
    my($ret) = system($diff_cmd);
    my($exit_status) = ($ret >> 8);
    if ($exit_status != 0) {
	open(DIFF, "<$cmd_base.diff") or die "cannot open $cmd_base.diff\n";
	my(@diff) = <DIFF>;
	close DIFF;
	if ($altout_p ne 'altout') {
	    diag "    test $cmd_base failed, delta:\n" . join('', @diff);
	};
	return undef;
    } else {
	unlink("$cmd_base.diff");
	unlink("$cmd_base.trial");
    };
}


sub run_one {
    my($cmd_file) = @_;
    die "confusion: run on non .cmd file: $cmd_file\n" if ($cmd_file !~ /\.cmd$/);

    my $cmd_base = $cmd_file;
    $cmd_base =~ s/\.cmd$//;

    my $optref = parse_cmd_file($cmd_file);

    my $prog_path = fix_prog_path($optref->{prog});

    my $in;
    if (!defined($optref->{in})) {
	$in = " < $cmd_base.in";
    } elsif ($optref->{in} eq '') {
	$in = '';
    } else {
	$in = " < " . $optref->{in};
    };
    my $out = "$cmd_base.out"; #  never used: (defined($optref->{out}) ? $optref->{out} : "$cmd_base.out");
    my $run_cmd = $prog_path . " " . (defined($optref->{args}) ? $optref->{args} : '') ." $in";
    $run_cmd .= fix_prog_path($optref->{cmd_tail}) if (defined($optref->{cmd_tail}));
    print "$env_cmd $run_cmd\n" if ($verbose);

    if (defined($optref->{enabled}) && !$optref->{enabled}) {
	diag "    test $cmd_file skipped (disabled in .cmd)\n";
	return 1;
    };
    if (defined($optref->{requires})) {
	# check for required modules:
	eval "use $optref->{requires};";
	if ($@ ne '') {
	    diag "   test $run_cmd skipped because of missing module $optref->{requires}\n";
	    return 1;
	};
    };

    if (!open(RUN, "$run_cmd 2>&1 |")) {
	diag "   failed to run $run_cmd\n";
	return undef;
    };
    # Icky.  Hack around some ithreads warnings that are hard to suppress.
    my $suppress_warnings_regexp = undef;
    if ($optref->{suppress_warnings}) {
	$suppress_warnings_regexp = '';
	my $this_perl_version = sprintf("%vd", $^V);
	foreach (split(/;/, $optref->{suppress_warnings})) {
	    my($version, $warning) = (/^([\[\-\]\.0-9]+):(.*)$/);
	    die "test_command.t: bad suppress warning entry: $_\n"
		if (!defined($version) || !defined($warning));
	    $version =~ s/\./\\\./g;   # allow [] to pass through; could be expaneded in the future.
	    if ($this_perl_version =~ /^$version/) {
		$suppress_warnings_regexp .= (quotemeta($warning) . "|")
	    };
	};
	$suppress_warnings_regexp =~ s/\|$//;
	$suppress_warnings_regexp = undef if ($suppress_warnings_regexp eq '');
    };
    open(OUT, ">$cmd_base.trial") or die "$0: cannot write $cmd_base.trial\n";
    while (<RUN>) {
	chomp;
	#
	# Carp has no period in perl-5.14, but gathers one by 5.17.
	# normalize the difference.
	#
	# Also, changes to the base perl version change the exact line that fails.
	# Fix that here.
	#
	s/^( at .* line) (\d+)\.?/$1 999./g;
	if (defined($suppress_warnings_regexp)) {
	    if (/^($suppress_warnings_regexp)/) {
	        # print "skipping: $_\n";
		next;
	    };
	};
	print OUT "$_\n";
    };
    if (!close RUN) {
	# unsuccessful program.  is this a bad thing?
        if ($? == -1) {
	    # yes... system failure
	    diag "failed to execute command: $!\n";
	    return undef;
	} elsif ($? & 127) {
	    # yes... crash
	    diag "program " . $optref->{prog} . " received signal...very bad! $!\n\t$run_cmd";
	    return undef;
	} else {
	    # maybe... failure
	    my $exit_code = ($? >> 8);
	    if (defined($optref->{expected_exit_code})) {
		my $expected_result = undef;
		if (!$expected_result && $optref->{expected_exit_code} eq 'fail' && $exit_code != 0) {
		    print "expected failure and got it ($exit_code)\n" if ($debug);
		    $expected_result = 1;
		};
		if (!$expected_result && $optref->{expected_exit_code} ne 'fail' && $exit_code == $optref->{expected_exit_code}) {
		    print "expected some code (". $optref->{expected_exit_code}. "), and got it\n" if ($debug);
		    $expected_result = 1;
		};
		if (!$expected_result) {
		    diag "test $cmd_file exited with unexpected exit code $exit_code (should be " . $optref->{expected_exit_code} . ")\n\t$run_cmd\n";
		    return undef;
		    # fall through
		};
	    } else {
		# fall through... got EXPECTED non-zero exit code
	    };
	};
    } else {
	# check for sucessful programs that maybe should have failed
	if (defined($optref->{expected_exit_code}) &&
		'0' ne $optref->{expected_exit_code}) {
	    diag "program " . $optref->{prog} . " exited successfully when expected exit code was " . $optref->{expected_exit_code} . "\n\t$run_cmd";
	    return undef;
	};
    };
    close OUT;

    if ($update) {
	print "	updating saved output $out\n";
	mv("$out", "$out-") if (-f "$out");
	cp("$cmd_base.trial", "$out") or die "copy failed: $!";
    };

    #
    # finally do the compare
    #
    my($out_ok) = 1;
    my $trial_fn = "$cmd_base.trial";
    $out_ok = diff_output($cmd_base, $out, $trial_fn, $optref->{cmp}, $optref->{cmp_needs_input_flags}, 'altout');
    if (!$out_ok && defined($optref->{altcmp})) {
        $out_ok = diff_output($cmd_base, $out, $trial_fn, $optref->{altcmp}, $optref->{altcmp_needs_input_flags},  'altout');
    };
    if (!$out_ok && defined($optref->{altout}) && $optref->{altout} eq 'true') {
	$out_ok = diff_output($cmd_base, "$cmd_base.altout", $trial_fn, $optref->{cmp}, $optref->{cmp_needs_input_flags}, 'out');
    };
    if (!$out_ok) {
	push (@failed_tests, $cmd_base);
        return undef;
    };

    system($optref->{cleanup}) if (defined($optref->{cleanup}));

    1;
}

