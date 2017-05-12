package Linux::Slackware::SystemTests;

# ABSTRACT: Helper class for Slacware Linux system test harness.

# Encapsulates data and methods intended to be used by:
#    * the systests/*.t scripts
#    * the bin/slackware-systemtests test harness

use strict;
use warnings;
use JSON;
use File::Valet;
use Time::HiRes;
use vars qw(@EXPORT @EXPORT_OK @ISA $VERSION);

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    $VERSION = '1.00';
    @EXPORT = @EXPORT_OK = qw();  # zzapp -- do we want to export anything?
}

sub new {
    my ($class, %opt_hr) = @_;
    my $self = {
        opt_hr   => \%opt_hr,  # Anything the caller passes in gets stashed here so $self->opt() can be used to look it up later.
        ok       => 'OK',
        n_err    => 0,
        n_warn   => 0,
        n_fail   => 0,
        n_pass   => 0,
        err      => '',
        err_ar   => [],
        me       => 'Linux::Slackware::SystemTests',
        js_or    => JSON->new->ascii->allow_nonref->space_after()
    };
    bless ($self, $class);

    foreach my $k0 (keys %{$self->{opt_hr}}) {
        my $k1 = join('_', split(/-/, $k0));
        next if ($k0 eq $k1);
        $self->{opt_hr}->{$k1} = $self->{opt_hr}->{$k0};
        delete $self->{opt_hr}->{$k0};
    }

    # I was told File::ShareDir was The Answer, but that breaks when running out of the development directory, so reverting to the ugly hack:
    my $st_dir = $1 if ($INC{'Linux/Slackware/SystemTests.pm'} =~ /(.+?)\.pm$/);
    $self->{share_dir} = $self->opt('share_dir') // $st_dir;
    die "need to specify non-undef share_dir because INC of self is not parseable" unless(defined($self->{share_dir}));  # zzapp ick .. how to better word that?

    $self->{temp_dir}  = $self->opt('temp_dir')  // File::Valet::find_temp();
    die "need to specify non-undef temp_dir because File::Valet::find_temp cannot find one" unless(defined($self->{temp_dir}));  # zzapp ick .. how to better word that?

    $self->{tests_dir} = $self->opt('tests_dir') // "$self->{share_dir}/system_tests";
    $self->{data_dir}  = $self->opt('data_dir')  // "$self->{share_dir}/system_test_data";
    $self->{bin_dir}   = $self->opt('bin_dir')   // "$self->{share_dir}/bin";
    $self->{sys_hr}    = $self->opt('self_id')   // $self->invoke_self_id();

    return $self;
}

sub invoke_self_id {
    my ($self) = @_;
    my $filename = $self->opt('self_id_cache_pathname','/tmp/self_id.dat');

    my $id_txt;

    if (-e $filename && (stat($filename))[9] > time() - 8 * 3600) {
        $id_txt = rd_f($filename);
        die "unable to read self-id cache file $filename ($File::Valet::ERROR)\n" unless (defined($id_txt));
    } else {
        unlink($filename);
        die "Expired self-id cache file $filename exists and cannot be removed, which is likely a permissions issue.  Please remove, rename or chmod it and try again.\n" if (-e $filename);
        my $self_id_bin = "$self->{bin_dir}/self-id";
        die "self-id executable is missing from $self_id_bin"      unless (-e $self_id_bin);
        die "self-id executable is not executable at $self_id_bin" unless (-x $self_id_bin);
        $id_txt = `$self_id_bin`;  # zzapp -- yeah yeah, really should use IPC::Open3 or somesuch here
        wr_f($filename, $id_txt);  # zzapp -- check for errors
    }

    # zzapp -- check $id_txt for well-formedness, validate eval()'s output, rethrow any caught exceptions.
    return eval($id_txt);
}

sub log {
    my ($self, $mode, @errs) = @_;
    return if ($mode eq 'DEBUG' && !$self->opt('debug',0));
    my $err_js = $self->{js_or}->encode(\@errs) if ($self->opt('show_log',0));
    my $tm = Time::HiRes::time();
    my $lt = localtime();
    print STDERR "$tm $lt $$\t$mode\t$err_js\n" if ($self->opt('show_log',0));
    ap_f($self->opt('log_filename','/tmp/st.log'), $self->{js_or}->encode([$mode, $tm, $lt, $$, \@errs])) if ($self->opt('log',1));
    $self->{n_err}++  if ($mode eq 'ERROR');
    $self->{n_warn}++ if ($mode eq 'WARNING');
    $self->{n_fail}++ if ($mode eq 'FAIL');
    $self->{n_pass}++ if ($mode eq 'PASS');
    return;
}

sub init_work_file {
    my ($self, $filename) = @_;
    my $subject_file = "$self->{data_dir}/$filename";
    my $target_file  = "$self->{temp_dir}/$filename";
    return ('ERROR', "no such file $subject_file") unless (-e $subject_file);
    unlink($target_file);
    return ('ERROR', "failed to remove left over turd file $target_file") if (-e $target_file);
    my $ok = wr_f($target_file, rd_f($subject_file));
    return ('ERROR', "failed to copy $subject_file to $target_file ($File::Valet::ERROR)") unless ($ok);
    return ('OK', $target_file);
}

sub all_is_well {
    my ($self) = @_;
    $self->{ok}  = 'OK';
    $self->{err} = '';
    $self->{err_ar} = [];
    return;
}

sub opt {
    my ($self, $name, $default_value, $alt_hr) = @_;
    $alt_hr //= {};
    return $self->{opt_hr}->{$name} // $alt_hr->{$name} // $default_value;
}

1;

=head1 NAME

Linux::Slackware::SystemTests - System tests for Slackware Linux

=head1 SYNOPSIS

  # If you just want to -run- system tests, invoke the slackware-systemtests
  # test harness and stop reading this document:

  $ slackware-systemtests

  # If you are -writing- system tests, use an instance to get useful tools:

  use Linux::Slackware::SystemTests;
  my $st = Linux::Slackware::SystemTests->new();

  # Copy a data file from wherever they are installed to a temp directory so
  # it can be modified:

  my ($ok, $file_pathname) = $st->init_work_file("001_sed.1.txt");

  # $st->{sys_hr} provides useful details about the system being tested, so
  # you can change the test depending on what version of Slackware is being
  # tested, or 32-vs-64-bit, etc:

  if ($st->{sys_hr}->{version} eq "14.2") {
      # run test for just the Slackware 14.2 release
  }
  if ($st->{sys_hr}->{bits} eq "64") {
      # run test specific to 64-bit Slackware
  }

  # If you need to JSONify something, there's already a JSON object
  # instantiated with sane and robust operating parameters:

  ok `/bin/uname -a` =~ /CPU \@ ([\d\.]+)GHz (\w+)/, "processor is ".$st->{js_or}->encode([$1, $2]);

  # If you need to know where the test data files are installed, $st knows:

  my $data_pathname = "$st->{data_dir}/some_test_file.txt";

  # If you want to log structured data to a file, that can be done too:
  $st->log("WARNING", "Something not quite right with environment", \%ENV);

  # Alternatively, if your test needs none of these things, you don't have to
  # use this module at all!  Any test that produces TAP output should jfw.

=head1 DESCRIPTION

L<System tests|https://en.wikipedia.org/wiki/System_testing> are are short programs which exercise components of your
computer system and make sure they are running correctly.

This package implements tests for L<Slackware Linux|http://distrowatch.com/table.php?distribution=slackware> systems, 
and a test harness for running them and generating reports.

This module provides maybe-useful functionality for making those tests easier to write, and for helping to write test 
harnesses.

The eventual goal is to accumulate enough tests that when Slackware updates, you can just re-run the system tests and
know that everything works okay.  Some sort of continuous integration automation might also happen, eventually.

Another goal is to make it easy to write new system tests, to keep the barrier of entry low.  There is a lot to test 
in a full Slackware install, so please write tests and share them with the author :-)

=head1 USING THE MODULE

The Linux::Slackware::SystemTests module provides some data and methods which may or may not be useful to you.

If you do not find them useful, don't use the module! :-) System tests do not require the module.  It's just there 
to make your life easier, if you need it.

=head2 METHODS

=head3 my $st = Linux::Slackware::SystemTests-E<gt>new(%options)

Instantiates a new Linux::Slackware::SystemTests object.  Lacking options, sane defaults are assumed.

Supported options are:

=over 4

=item temp_dir => (path string)

Set this to override C<$st-E<gt>{temp_dir}>, which changes the behavior of the C<init_work_file> and C<invoke_self_id> methods.

When this option is not provided, an appropriate temporary directory will be found via C<File::Valet::find_temp>.

Some sane values to pass here might be "/tmp" or "/dev/shm".

=item debug => (0 or 1)

When true (1), invoking C<$st-E<gt>log> with a mode of "DEBUG" will be silently ignored.

When false (0), "DEBUG" mode logging messages will be written to the log file.

Defaults to false (0).

=item log_filename => (pathname string)

Sets the pathname of the structured data log file written to by C<$st-E<gt>log>.  Defaults to "/tmp/st.log".

=item show_log => (0 or 1)

When true (1), invoking C<$st-E<gt>log> will cause a human-friendly representation of the log record to be written to C<STDOUT>.

When false (0), no log records will be displayed.

Defaults to false (0).

=item log => (0 or 1)

When true (1), invoking C<$st-E<gt>log> will cause log messages to be written to the logile.

When false (0), no log records will be written to file, but might still be written to C<STDOUT> if C<show_log> is set.

Defaults to true (1).

=item share_dir => (path string)

Set this to override C<$st-E<gt>{share_dir}>, the base directory from which C<data_dir>, C<bin_dir>, C<tests_dir> are derived.  Mostly useful for mocking purposes.

=item data_dir => (path string)

Set this to override C<$st-E<gt>{data_dir}>, where the test data files are stored.  Mostly useful for mocking purposes.

=item tests_dir => (path string)

Set this to override C<$st-E<gt>{tests_dir}>, where the system test executables are stored.  Mostly useful for mocking purposes.

=item bin_dir => (path string)

Set this to override C<$st-E<gt>{bin_dir}>, where the module's private executables are stored.  Mostly useful for mocking purposes.

=item self_id => (hash reference)

Set this to override C<$st-E<gt>{sys_hr}>.  Mostly useful for mocking purposes.

When this option is not provided, a C<self-id> script will be run which figures out various details about the local system.

=back

=head3 $st-E<gt>log(MODE, DESCRIPTION[, structured data ...])

Writes a JSON record to a structured data log file, and optionally to STDOUT as well.

=over 4

=item MODE 

Should be one of "DEBUG", "ERROR", "WARNING", "FAIL", or "PASS".

=item DESCRIPTION

Should be an B<invariant> string (without any variables interpolated into it).  Using an invariant makes possible a full enumeration of log record types, which is important for log collation.

=item structured data

Can be any number of arbitrarily complex data elements.  Elements not able to be represented by the C<JSON> module will instead be represented as C<nil>.  This includes code refs, glob refs and regex refs.

Each JSON record is newline-terminated, and contains the following fields:

  [MODE, EPOCH_TIME, LOCAL_TIME, PID, DESCRIPTION, structured data ...]

The C<MODE>, C<DESCRIPTION> and C<structured data> fields will be the JSON representations of the C<$st-E<gt>log> parameters.

The C<EPOCH_TIME> field will be a floating point representation of the epoch time at which the log record was created.

The C<LOCAL_TIME> field will be a human-readable representation of C<EPOCH_TIME> in the local timezone.

The C<PID> field will be the process identifier of the process which created the log record.

For instance, the following C<log> call:

    $st->log("WARNING", "skipped some tests", {name => "ichi", why => "ploo"}, {name => "ni", why => "glom"}, [1, 2, 3, {foo => "bar"}])

.. would append something like the following JSON to the logfile:

    ["WARNING", 1470253241.25485, "Wed Aug  3 12:40:41 2016", 1472, "skipped some tests", {"name": "ichi", "why": "ploo"}, {"name": "ichi", "why": "glom"}, [1, 2, 3, {"foo": "bar"}]]

Furthermore, if the C<show_log> parameter was set when C<$st> was instantiated, the following would be printed to STDOUT:

    1470253241.25485 Wed Aug  3 12:40:41 2016 1472\tWARNING\t["skipped some tests", {"name": "ichi", "why": "ploo"}, {"name": "ichi", "why": "glom"}, [1, 2, 3, {"foo": "bar"}]]

=back

=head3 ($ok, $pathname) = $st->init_work_file("314_some_test_file.txt")

When the module is installed, it is usually stored as read-only data in some obscure corner of the filesystem.  This is inconvenient when a test requires a data file which is writable.

Rather than forcing each test author to come up with a way to find the data and copy it to a temporary directory (which might not exist on the system), C<init_work_file> is provided to do the work for them.

C<init_work_file> will find the data file, find a temporary directory, delete any old files left over from a previous run, copy the file and return ('OK', $pathname) where $pathname is the full pathname of the copied file.

If it encounters any errors at any point in the process, it will return ('ERROR', $description) where $description describes what failed and (maybe) why.

If a copy of the file is not required, and a test only needs the full pathname of a data file for reading, use C<$st-E<gt>{data_dir}> instead, like so:

    my $full_pathname = "$st->{data_dir}/314_some_test_file.txt";

=head3 $st->opt(OPTION_NAME[, DEFAULT_VALUE[, ALTERNATIVE_HASHREF]])

    $st->opt("log")
    $st->opt("log", 0)
    $st->opt("log", 0, $alt_hr)

Fetches an option field from the object's instantiation parameters.

C<opt> will look in C<$st-E<gt>{opt_hr}-E<gt>{OPTION_NAME}> first.  If not present there, 
it will look in C<$alt_hr-E<gt>{OPTION_NAME}> if an C<$alt_hr> parameter was provided.

If no option by that name is found anywhere, C<opt> will return C<DEFAULT_VALUE> (0 in the above examples), or C<undef> if no default is provided.

=head2 WRITING SYSTEM TESTS

System tests can be very simple or as complicated as necessary.  They may be written in 
any language, although /bin/sh and perl are encouraged.

The only hard requirement is that they generate their output in L<Test Anything 
Protocol|http://testanything.org/>, which is pretty easy.  TAP libraries are available
for most languages.

Tests should be executable files located in C<lib/Linux/Slackware/SystemTests/system_tests/> with a C<.t> filename suffix.  All such files will be executed by running the C<slackware-system-test> script.

=head3 WRITING SYSTEM TESTS IN PERL

Writing tests in perl is easy.  Just copy C<lib/Linux/Slackware/SystemTests/system_tests/test_template.pl> to a new file (like C<123_my_test.t>) and edit the new file to add your test logic.  There are some goodies in C<test_template.pl> (like object instantiation) which are commented out.  Uncomment them if you need them.

C<test_template.pl> uses L<Test::Most|https://metacpan.org/pod/Test::Most>, but feel free to use any of the other TAP-compliant test modules, such as L<Test::More|https://metacpan.org/pod/Test::More> or L<Test2|https://metacpan.org/pod/Test2>.

If you have never written tests for perl before, read the L<Test::Most|https://metacpan.org/pod/Test::Most> documentation and look at the other C<.t> files in the C<system_tests> directory to get a notion.

The skinny of it is, C<Test::Most> provides functions like C<ok> and C<is>, to which you pass the results of your tests of system correctness, and it represents those results in TAP format.  For instance:

    ok `lsmod 2>\&1` =~ /ipv6/, "IPv6 module is loaded"

.. which displays C<ok 1 - IPv6 module is loaded> or C<not ok 1 - IPv6 module is loaded> depending on the results of the expression.

Also feel free to hop onto the C<#perl> IRC channel on C<irc.freenode.org> to ask for help.  The good folks there are very enthusiastic about good tests.  Just don't take mst's brisk manner personally.  He means well.

=head3 WRITING SYSTEM TESTS IN BASH

Work in progress.  More here later.

I'm still figuring this out.  There is a TAP implementation for bash L<test-more-bash|https://github.com/ingydotnet/test-more-bash> which might be appropriate, but I'm still assessing it.

If that doesn't work out, I'll teach C<slackware-system-test> to accept C<*.sh.t> tests which signal pass/fail with an exit code, and drop the TAP requirement.  The priority is to get more tests written, and barriers will be lowered to make that happen.

=head3 WRITING SYSTEM TESTS IN OTHER LANGUAGES

Work in progress.  More here later.

L<Test Anything Protocol|http://testanything.org/> claims TAP libraries are available for C, C++, Python, PHP, Perl, Java, JavaScript, "and others", which means whatever programming language you like to use, you can likely use it to write system tests.

The only stipulation is that the code should jfw using software that ships with stock Slackware.  Since C<gcc> and C<g++> are part of Slackware, C and C++ are fine, but Oracle's JVM does not.  That means unless your test works with C<gcc-java>, Java is off the table.

=head2 RUNNING SYSTEM TESTS

At the moment, the test harness is extremely simple.  More features will come.  The main priority is getting more tests written.

For the moment, invoking C<slackware-system-test> without parameters will cause it to run all of the C<*.t> executables in C<system_tests>, display their pathnames, and display only those tests which fail.

Invoking C<slackware-system-test> with arguments will treat those arguments as regex patterns which will be applied to the names of the C<*.t> executables in C<system_tests>, and only those which match will be executed.

Thus if C<system_tests> contains tests C<123_ichi.t>, C<234_ni.t> and C<345_san.t>, running C<slackware-system-test s> will cause only C<345_san.t> to run, while running C<slackware-system-test i> will cause only C<123_ichi.t> and C<234_ni.t> to run.

Alternatively, to run specific system tests, invoke them directly:

    $ lib/Linux/Slackware/SystemTests/system_tests/001_sed.t

Near future plans include a C<--retry> option which only runs tests which failed in the previous invocation and some sort of html report output.

Far future plans include continuous integration automation, so that new releases of Slackware can be installed to a VM and tested, and test results made available as a web page.

=head1 SEE ALSO

The L<Linux Testing Project|https://linux-test-project.github.io/> which does not work under Slackware and has more of a kernel focus.

=head1 CONTACTS AND RESOURCES

Github page L<https://github.com/ttkciar/linux-slackware-systemtests|https://github.com/ttkciar/linux-slackware-systemtests> is the official project site.  Submit bug reports and pull requests there (or just email TTK).

Channel C<##slackware> on irc.freenode.net, for Slackware-related questions

Channel C<#perl> on irc.freenode.net, for Perl-related questions

=head1 AUTHORS

Contribute some system tests and get yourself added to this list!

TTK Ciar, C<ttk@ciar.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, TTK Ciar and others.

This program is free software, you can redistribute it and/or modify it under
the terms of Perl itself.

=cut
