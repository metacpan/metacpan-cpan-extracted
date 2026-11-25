#!/usr/bin/env perl

use strict;
use warnings;

use Config;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;
use Developer::Dashboard::GoRoutine ();

my $root = File::Spec->catdir( $RealBin, File::Spec->updir );
my $helper = File::Spec->catfile( $root, 'share', 'private-cli', '_dashboard-core' );

ok( -f $helper, 'staged private _dashboard-core helper exists in the source tree' );

my $home = tempdir( CLEANUP => 1 );
my $fake_bin = tempdir( CLEANUP => 1 );
my $git_log = File::Spec->catfile( $home, 'git.log' );
my $stderr_log = File::Spec->catfile( $home, 'helper.err' );

make_path( File::Spec->catdir( $home, '.developer-dashboard', 'skills' ) );

# The fake git is a Perl script so it needs no POSIX shell: it logs its
# arguments, lingers long enough for the process table to be read, and
# fails. Unix runs it through its shebang as plain "git". Windows program
# search cannot run an extensionless script, so there the same script gets a
# batch twin that hands it to the running perl.
my $fake_git = File::Spec->catfile( $fake_bin, 'git' );
_write_executable( $fake_git, <<"PERL" );
#!$^X
open my \$log, '>>', q{$git_log} or die "Unable to append git log: \$!";
print {\$log} "\@ARGV\\n";
close \$log;
sleep 3;
exit 1;
PERL
_write_executable( "$fake_git.bat", qq{\@"$^X" "$fake_git" %*\r\n} ) if $^O eq 'MSWin32';

my $pid = Developer::Dashboard::GoRoutine::spawn(
    [ $^X, $helper, 'skills', 'install', 'browser' ],
    {
        env => {
            HOME                         => $home,
            PATH                         => join( $Config{path_sep}, $fake_bin, ( $ENV{PATH} || '' ) ),
            SHELL                        => '/bin/sh',
            DEVELOPER_DASHBOARD_REPO_LIB => File::Spec->catdir( $root, 'lib' ),
        },
        stdout => File::Spec->devnull(),
        stderr => $stderr_log,
    },
);

# A $0 assignment rewrites what ps shows on Unix, but it never rewrites the
# launch command line Windows keeps for a process. The Windows contract is
# the one the product itself relies on there: the command line still names
# the staged helper followed by the public command words, so an operator can
# read which d2 command is running.
my $title_pattern =
  $^O eq 'MSWin32'
  ? qr/\b_dashboard-core"? skills install browser\b/
  : qr/\bdeveloper-dashboard skills install browser\b/;
my $ps_args = '';
my $saw_public_title = 0;
SKIP: {
    # The helper sets $0 to the public command form, but under qemu
    # user-mode emulation the guest's $0 write never reaches the host's
    # /proc, so ps shows the qemu-prefixed spawn argv and the title cannot
    # be observed there at all. Skipping this one assertion on such a host
    # is not skipping the test: the helper still has to run, fail, and reach
    # the git-backed install path (the assertions below), and the title
    # contract is verified on every host where a title is observable.
    skip 'a $0 process title is not observable in ps under qemu user-mode emulation', 1
      if _running_under_qemu();
    for ( 1 .. 50 ) {
        $ps_args = _ps_args($pid);
        if ( $ps_args =~ $title_pattern ) {
            $saw_public_title = 1;
            last;
        }
        select undef, undef, undef, 0.1;
    }

    ok( $saw_public_title, 'private helper process title uses the public developer-dashboard command form in ps output' )
      or diag "Last ps args: $ps_args";
}

my $exit = Developer::Dashboard::GoRoutine::wait_process($pid);
cmp_ok( $exit, '!=', 0, 'helper process can fail after the fake git probe because this test only checks the process title contract' );

ok( -f $git_log, 'helper reached the git-backed skills install path while the public process title was visible' );

done_testing();

# _ps_args($pid)
# Reads the command line the process table shows for one process. Windows
# has no ps, so there the product's own reader is used, which asks the
# Windows process table through CIM.
# Input: process id integer.
# Output: command line string, or an empty string when it cannot be read.
sub _ps_args {
    my ($pid) = @_;
    return '' if !defined $pid || $pid !~ /\A\d+\z/;
    my $args;
    if ( $^O eq 'MSWin32' ) {
        require Developer::Dashboard::CollectorRunner;
        $args = Developer::Dashboard::CollectorRunner->_read_process_title($pid);
    }
    else {
        $args = qx{ps -o args= -p $pid 2>/dev/null};
    }
    $args = '' if !defined $args;
    $args =~ s/\s+\z//;
    return $args;
}

# _running_under_qemu()
# Reports whether this test process itself runs under qemu user-mode
# emulation, by reading the PARENT process's /proc cmdline: an emulated
# process shows as `/usr/bin/qemu-<arch> <real-binary> <args>`. The parent
# is read, not self: inside the guest a process's OWN /proc/self/cmdline
# shows the guest argv with no qemu prefix - the prefix is only visible
# when reading ANOTHER process's cmdline. (Reading self always answered
# false on the ARM64 box, so the qemu skip below was dead code.)
# Output: boolean true when the first argv token names a qemu emulator.
sub _running_under_qemu {
    # getppid() is unimplemented on Strawberry Perl (Windows), so it must
    # never be called where /proc does not exist: the parent path is built
    # only when /proc is a directory. On Windows only /proc/self/cmdline
    # is tried, which is unreadable, so this returns 0 without dying.
    my @paths = ('/proc/self/cmdline');
    unshift @paths, '/proc/' . getppid() . '/cmdline' if -d '/proc';
    for my $path (@paths) {
        next if !-r $path;
        open my $fh, '<', $path or next;
        local $/;
        my $cmdline = <$fh> // '';
        close $fh;
        my ($first) = split /\0/, $cmdline;
        return 1 if defined $first && $first =~ m{(?:^|/)qemu-[^/\s]+\z};
    }
    return 0;
}

sub _write_executable {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    chmod 0755, $path or die "Unable to chmod $path: $!";
}

__END__

=pod

=head1 NAME

t/42-helper-process-title.t - verifies staged helper processes advertise the public developer-dashboard command name

=head1 PURPOSE

This test protects the process-title contract for staged dashboard-managed
helpers. When a helper such as C<d2 skills install browser> is running,
operators should see C<developer-dashboard skills install browser> in C<ps>
output instead of the staged helper path under F<~/.developer-dashboard/cli/dd/>.

=head1 WHAT IT TESTS

It launches the private C<_dashboard-core> helper through the Dashboard
GoRoutine process API against a fake git-backed
skills install path, inspects the live process table while the helper is still
running, and proves the visible command line uses the normalized
C<developer-dashboard ...> title.

=head1 WHY IT EXISTS

The public C<d2> entrypoint is intentionally thin and hands built-in
commands off to staged helpers. Without this regression test, operators can
end up seeing an ugly staged-helper path in C<ps> output and have to guess
which public d2 command is actually running.

=head1 WHEN TO USE

Use this test when changing staged helper dispatch, built-in command process
titles, or the private helper runtime that sits behind C<d2>.

=head1 WHAT USES IT

It is used by contributors working on staged helper internals and by the full
release gate so private helper process listings stay aligned with the public
command names.

=head1 HOW TO USE

Run it through the normal harness:

  prove -lv t/42-helper-process-title.t

=head1 EXAMPLES

Example 1:

  prove -lv t/42-helper-process-title.t

Run the focused regression test while editing staged helper process-title
behavior.

Example 2:

  prove -lr t

Run the full suite after changing helper staging or private built-in command
dispatch.

=cut
