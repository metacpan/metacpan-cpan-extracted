#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

my $root = File::Spec->catdir( $RealBin, File::Spec->updir );
my $helper = File::Spec->catfile( $root, 'share', 'private-cli', '_dashboard-core' );

ok( -f $helper, 'staged private _dashboard-core helper exists in the source tree' );

my $home = tempdir( CLEANUP => 1 );
my $fake_bin = tempdir( CLEANUP => 1 );
my $git_log = File::Spec->catfile( $home, 'git.log' );
my $stderr_log = File::Spec->catfile( $home, 'helper.err' );

make_path( File::Spec->catdir( $home, '.developer-dashboard', 'skills' ) );

_write_executable(
    File::Spec->catfile( $fake_bin, 'git' ),
    <<"SH",
#!/bin/sh
printf '%s\\n' "\$*" >> "$git_log"
sleep 3
exit 1
SH
);

my $pid = fork();
die "Unable to fork helper process test: $!" if !defined $pid;

if ( $pid == 0 ) {
    open STDOUT, '>', File::Spec->devnull() or die "Unable to redirect STDOUT: $!";
    open STDERR, '>', $stderr_log or die "Unable to redirect STDERR: $!";
    $ENV{HOME} = $home;
    $ENV{PATH} = $fake_bin . ':' . ( $ENV{PATH} || '' );
    $ENV{SHELL} = '/bin/sh';
    $ENV{DEVELOPER_DASHBOARD_REPO_LIB} = File::Spec->catdir( $root, 'lib' );
    exec $^X, $helper, 'skills', 'install', 'browser';
    die "Unable to exec $helper: $!";
}

my $ps_args = '';
my $saw_public_title = 0;
for ( 1 .. 50 ) {
    $ps_args = _ps_args($pid);
    if ( $ps_args =~ /\bdeveloper-dashboard skills install browser\b/ ) {
        $saw_public_title = 1;
        last;
    }
    select undef, undef, undef, 0.1;
}

ok( $saw_public_title, 'private helper process title uses the public developer-dashboard command form in ps output' )
  or diag "Last ps args: $ps_args";

my $wait = waitpid( $pid, 0 );
is( $wait, $pid, 'helper process exits after the fake git-backed install probe completes' );
cmp_ok( $? >> 8, '!=', 0, 'helper process can fail after the fake git probe because this test only checks the process title contract' );

ok( -f $git_log, 'helper reached the git-backed skills install path while the public process title was visible' );

done_testing();

sub _ps_args {
    my ($pid) = @_;
    return '' if !defined $pid || $pid !~ /\A\d+\z/;
    my $args = qx{ps -o args= -p $pid 2>/dev/null};
    $args =~ s/\s+\z//;
    return $args;
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
helpers. When a helper such as C<dashboard skills install browser> is running,
operators should see C<developer-dashboard skills install browser> in C<ps>
output instead of the staged helper path under F<~/.developer-dashboard/cli/dd/>.

=head1 WHAT IT TESTS

It launches the private C<_dashboard-core> helper against a fake git-backed
skills install path, inspects the live process table while the helper is still
running, and proves the visible command line uses the normalized
C<developer-dashboard ...> title.

=head1 WHY IT EXISTS

The public C<dashboard> entrypoint is intentionally thin and hands built-in
commands off to staged helpers. Without this regression test, operators can
end up seeing an ugly staged-helper path in C<ps> output and have to guess
which public dashboard command is actually running.

=head1 WHEN TO USE

Use this test when changing staged helper dispatch, built-in command process
titles, or the private helper runtime that sits behind C<dashboard>.

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
