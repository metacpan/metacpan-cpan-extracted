# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Getopt::Plus

This package tests the check/initialize/finalize/end utility of Getopt::Plus

=cut

use Env                        qw( @PATH );
use File::Basename             qw( basename );
use File::Spec::Functions  1.1 qw( catdir catfile updir );
use FindBin               1.42 qw( $Bin );
use IO::All                    qw( io );
use IPC::Run                   qw( harness );
use Test::Most                 tests => 29;

use lib $Bin;
use test  qw( BIN_DIR LIB_DIR PERL REF_DIR
              compare only_files
           );
# use test2 qw( simple_run_test );

BEGIN {
  # 1 for compilation test,
#  plan tests  => 29,
#       todo   => [],
}

# ----------------------------------------------------------------------------

# -------------------------------------
# PACKAGE CONSTANTS
# -------------------------------------

use constant DEBUG => 0;

# -------------------------------------
# PACKAGE FUNCTIONS
# -------------------------------------

=head2 runcheck

Run an external command, check the results.

=over 4

=item ARGUMENTS

=over 4

=item runargs

An arrayref of arguments as for L<IPC::Run/run>, excepting that array ref
arguments with an initial C<:> character on the first member will be
considered as perl scripts in the module built to run.

For example, an invocation of

  runcheck([[':reverse'], '<', '/etc/passwd'], "bob", \$err);

will convert the initial reverse to treat it as a perl script called
F<reverse> to find in the module, and execute that with the current running
perl.  The remaining arguments are left as is.

=item name

The name of the program to refer to in error messages

=item errref

Reference to a scalar to read in case of error.  Normally, this is bound to a
scalar where is deposited the stderr out of the command, using arguments

  '2>', $err

in L</runargs>.

=item exitcode

I<Optional>.  If defined, the exitcode to expect from the run program.
Defaults to zero.

=back

=item RETURNS

=over 4

=item success

1 if the command executed without failure; false otherwise.

=back

=back

=cut

sub runcheck {
  my ($runargs, $name, $errref, $exitcode) = @_;

  $exitcode ||= 0;

  my @args = map({ ( ref $_ eq 'ARRAY' and substr($_->[0],0,1) eq ':') ?
                     [ $^X, catfile(BIN_DIR, substr($_->[0],1)),
                       @{$_}[1..$#$_] ]                                :
                     $_ }
                 @$runargs);

  print STDERR Data::Dumper->new([\@args],[qw(args)])->Indent(0)->Dump, "\n"
    if defined $ENV{TEST_DEBUG} and $ENV{TEST_DEBUG} > 1;
  my $rv = _ipc_run(@args);

  if ( $rv >> 8 != $exitcode ) {
    if ( $ENV{TEST_DEBUG} ) {
      print STDERR
        sprintf("$name failed (expected %d) : exit/sig/core %d/%d/%d\n",
                $exitcode, $rv >> 8, $rv & 127, ( $rv & 128 ) >> 7);
      print STDERR
        "  $$errref\n"
          if defined $errref and defined $$errref and $$errref !~ /^\s*$/;
    }
    return;
  } else {
    return 1;
  }
}

sub _ipc_run {
  my @args = @_;
  my $harness = harness(@args);
  run $harness;
  return $harness->full_result;
}

# -------------------------------------

=head2 simple_run_test

This is designed to simplify the job of running a program, and testing the
output.  It performs 2+n tests; that the command executed without error, that
the n files named in the C<checkfiles> argument are each as expected, and that
no other files exist.

All files in the current directory are wiped after the test in preparation for
the next test.

=over 4

=item ARGUMENTS

The arguments are considered as name/value pairs.

=over 4to
L<runcheck|/runcheck>.

=item runargs

B<Mandatory>.  This is an arrayref; as for the runargs argument to
L<runcheck|/runcheck>.

=item name

B<Mandatory>.  The name to use in error messages.

=item checkfiles

This is an arrayref of files to check.  The named files are considered
relative to the working directory, and are checked against files taken
relative to the F<testref> directory of the build.  Therefore, absolute file
names are non-sensical, and will raise an exception.

=item errref

A ref to a scalar potentially containing any error output.  Typically, the
stderr of the command run is redirected to this by the runargs argument.

=item testref_subdir

A subdirectory of the testref directory in which to find the files to check
against.

=item exitcode

The exit code to expect from the program run.  Defaults to 0.  Obviously.

=back

=item RETURNS

I<None>

However, 2+n tests are performed, with ok/not ok sent to stdout.

=back

=cut

sub simple_run_test {
  my (%arg) = @_;

  die sprintf("%s: missing mandatory argument: %s\n", (caller(0))[3], $_)
    for grep ! exists $arg{$_}, qw( runargs name );

  ${$arg{errref}} = ''
    if exists $arg{errref};
  $arg{exitcode} = 0
    unless exists $arg{exitcode};
  my $runok = runcheck(@arg{qw(runargs name errref exitcode)});

  ok $runok, $arg{name};

  my $ref_dir = (exists $arg{testref_subdir}           ?
                 catdir(REF_DIR, $arg{testref_subdir}) :
                 REF_DIR);

  if ( exists $arg{checkfiles} ) {
    for (@{$arg{checkfiles}}) {
      my $target = catfile($ref_dir, basename $_);
      if ( -e $target ) {
        my @expect = io($target)->slurp;
        my @got    = io($_)->slurp;
        is_deeply \@got, \@expect, "$arg{name}: check file $_ vs. $target";
      } else {
        ok 0, "$arg{name}: missing reference file $target";
      }
    }
  }

  ok(only_files($arg{checkfiles}), "$arg{name}: no extra files");
  # Clean up files for next test.
  local *MYDIR;
  opendir MYDIR, '.';
  unlink $_
    for grep !/^\.\.?$/, readdir MYDIR;
  closedir MYDIR;
}

# ----------------------------------------------------------------------------

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

unshift @PATH, catdir $Bin, 'bin';

ok 1, 'compilation';

# -------------------------------------

=head2 Test 2--4: test-script-2

Run the test script.

( 1) Check that the script ran okay (and hence compiled okay)
( 2) Check that the output is as expected (and hence that the expected
     components ran in the order check/initialize/finalize/end)
( 3) Check that no extra files were created

=cut

{
  my ($out, $err) = "";
  my $fn = 'normal';
  simple_run_test(runargs        => [[PERL, -S => 'test-script-2'],
                                     '>', $fn, '2>', \$err],
                  name           => 'test-script-2',
                  errref         => \$err,
                  checkfiles     => [ $fn ],
                  testref_subdir => 'check',
                  );
}

# -------------------------------------

=head2 Test 5--8: fail1

Run the test script, with the --fail1 option

( 1) Check that the script exited code 3
( 2) Check that the output is as expected (and hence that the expected
     components ran in the expected order, with no finalize (since initialize
     failed)
( 3) Check that no extra files were created
( 4) Check "Squeek" was emitted on stderr

=cut

{
  my ($out, $err) = "";
  my $fn = 'fail1';
  simple_run_test(runargs        => [[PERL, -S => 'test-script-2', '--fail1'],
                                     '>', $fn, '2>', \$err],
                  name           => 'test-script-2',
                  errref         => \$err,
                  checkfiles     => [ $fn ],
                  testref_subdir => 'check',
                  exitcode       => 3,
                  );
  like $err, qr/^(Squeek\n)+(initialize failed\n)+$/,                 'fail1 ( 4)';
}

# -------------------------------------

=head2 Test 9--12: fail2

Run the test script, with the --fail2 option

( 1) Check that the script exited code 255
( 2) Check that the output is as expected (and hence that the expected
     components ran in the expected order, with no finalize (since initialize
     failed)
( 3) Check that no extra files were created
( 4) Check "Squeak" was emitted on stderr

=cut

{
  my ($out, $err) = "";
  my $fn = 'fail2';
  simple_run_test(runargs        => [[PERL, -S => 'test-script-2', '--fail2'],
                                     '>', $fn, '2>', \$err],
                  name           => 'test-script-2',
                  errref         => \$err,
                  checkfiles     => [ $fn ],
                  testref_subdir => 'check',
                  exitcode       => 255,
                  );
  like $err, qr/^(Squawk\n)+(initialize failed\n)+$/,              'fail2 ( 4)';
}

# -------------------------------------

=head2 Test 13--16: fail3

Run the test script, with the --fail3 option

( 1) Check that the script exited code 0
( 2) Check that the output is as expected (and hence that the expected
     components ran in the expected order, with finalize or initialize
     (since check succeeded)
( 3) Check that no extra files were created
( 4) Check "Check failed" was emitted on stderr

=cut

{
  my ($out, $err) = "";
  my $fn = 'fail3';
  simple_run_test(runargs        => [[PERL, -S => 'test-script-2', '--fail3'],
                                     '>', $fn, '2>', \$err],
                  name           => 'test-script-2',
                  errref         => \$err,
                  checkfiles     => [ $fn ],
                  testref_subdir => 'check',
                  exitcode       => 0,
                  );
  is $err, '',                                                   'fail3 ( 4)';
}

# -------------------------------------

=head2 Test 17--20: msg

Run the test script, with the --msg option

( 1) Check that the script exited code 255
( 2) Check that the output is as expected (and hence that the expected
     components ran in the expected order, with no finalize or initialize
     (since check failed)
( 3) Check that no extra files were created
( 4) Check "Message\nCheck failed\n" was emitted on stderr

=cut

{
  my ($out, $err) = "";
  my $fn = 'msg';
  simple_run_test(runargs        => [[PERL, -S => 'test-script-2', '--msg'],
                                     '>', $fn, '2>', \$err],
                  name           => 'test-script-2',
                  errref         => \$err,
                  checkfiles     => [ $fn ],
                  testref_subdir => 'check',
                  exitcode       => 255,
                  );
  like $err, qr/^(Message\n)+(check failed\n)+$/,                    'msg ( 4)';
}

# -------------------------------------

=head2 Test 21--23: help

Run the test script, with the --help option

( 1) Check that the script exited code 255
( 2) Check that the output is as expected (and hence that end ran)
( 3) Check that no extra files were created

=cut

{
  my ($out, $err) = "";
  my $fn = 'help';
  local $ENV{COLUMNS} = 80;
  simple_run_test(runargs        => [[PERL, -S => 'test-script-2', '--help'],
                                     # Redirect STDIN to force help to
                                     # default columns
                                     '<', \undef, '>', $fn, '2>', \$err],
                  name           => 'test-script-2',
                  errref         => \$err,
                  checkfiles     => [ $fn ],
                  testref_subdir => 'check',
                  exitcode       => 2,
                  );
}

# -------------------------------------

=head2 Test 24--26: secondary

Test the alternative modes, with the --secondary flag

( 1) Check that the script exited code 0
( 2) Check that the output is as expected
( 3) Check that no extra files were created

=cut

{
  my ($out, $err) = "";
  my $fn = 'secondary';
  simple_run_test(runargs        => [[PERL, -S =>'test-script-2','--secondary'],
                                     # Redirect STDIN to force help to
                                     # default columns
                                     '<', \undef, '>', $fn, '2>', \$err],
                  name           => 'test-script-2',
                  errref         => \$err,
                  checkfiles     => [ $fn ],
                  testref_subdir => 'check',
                  exitcode       => 0,
                  );
}

# -------------------------------------

=head2 Test 24--26: args_done

Test that the args_done callback operates

( 1) Check that the script exited code 0
( 2) Check that the output is as expected
( 3) Check that no extra files were created

=cut

{
  my ($out, $err) = "";
  my $fn = 'args_done';
  simple_run_test(runargs        => [[PERL, -S =>'test-script-4','--secondary',
                                      'blibble', 'blobble',],
                                     # Redirect STDIN to force help to
                                     # default columns
                                     '<', \undef, '>', $fn, '2>', \$err],
                  name           => 'test-script-4',
                  errref         => \$err,
                  checkfiles     => [ $fn ],
                  testref_subdir => 'check',
                  exitcode       => 0,
                  );
}

# ----------------------------------------------------------------------------
