package TestCmd;

use Test::Command   0.08    ()                      ;
use File::Temp      0.22    ('tempfile')            ;
use Monkey::Patch   0.03    ('patch_package')       ;


use base 'Exporter';
our @EXPORT = qw<
    cmd_stdout cmd_stdout_is cmd_stdout_isnt cmd_stdout_like cmd_stdout_unlike
    cmd_stderr cmd_stderr_is cmd_stderr_isnt cmd_stderr_like cmd_stderr_unlike
    cmd_exit_is
>;


# Test::Command methods we'll export directly
# but we're changing the names so they don't conflict with Test::Output
*cmd_stdout_is = \&Test::Command::stdout_is_eq;
*cmd_stdout_isnt = \&Test::Command::stdout_isnt_eq;
*cmd_stdout_like = \&Test::Command::stdout_like;
*cmd_stdout_unlike = \&Test::Command::stdout_unlike;
*cmd_stderr_is = \&Test::Command::stderr_is_eq;
*cmd_stderr_isnt = \&Test::Command::stderr_isnt_eq;
*cmd_stderr_like = \&Test::Command::stderr_like;
*cmd_stderr_unlike = \&Test::Command::stderr_unlike;
*cmd_exit_is = \&Test::Command::exit_is_num;

# private Test::Command methods we'll import for personal use only
*_get_result = \&Test::Command::_get_result;
*_slurp = \&Test::Command::_slurp;
*_build_name = \&Test::Command::_build_name;


# this one we have to monkey patch
our $p = patch_package 'Test::Command' => _run_cmd => sub
{
    my ($orig, $cmd) = @_;

    # Test::Command normally takes its commands in one of two forms:
    #   *   'ls /tmp'           -   string which is passed to the shell
    #   *   [ 'ls', '/tmp' ]    -   command-line args; circumvents the shell
    # This monkey-patch allows a third form:
    #   *   { perl => $prog }   -   a bit of Perl code which is run in a separate perl interpreter
    # This will use $^X as the Perl command, so it should get you the same Perl that your test runs
    # in. It takes your $prog and puts it in a tempfile, then uses the tempfile as a script (instead
    # of using -e).  This avoids any strange quoting issues (even on Windows).  Then it passes the
    # command line to the system, bypassing the shell.

    if (ref $cmd eq 'HASH')
    {
        my $proglet = $cmd->{'perl'} or die("must provide Perl program as a string with the key 'perl'");
        my ($fh, $tmpfile) = tempfile( UNLINK => 1 );
        print $fh $proglet;
        close($fh);
        $cmd = [ $^X, $tmpfile ];
    }
    $orig->($cmd);
};


# return stdout or stderr as a string
# not strictly a test, but often useful in test files

sub cmd_stdout
{
    my ($cmd) = @_;

    my $result = _get_result($cmd);
    return _slurp($result->{'stdout_file'});
}

sub cmd_stderr
{
    my ($cmd) = @_;

    my $result = _get_result($cmd);
    return _slurp($result->{'stderr_file'});
}


1;
