use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

my $root   = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );
my $runner = File::Spec->catfile( $root, 'integration', 'windows', 'run-host-windows-smoke.sh' );

my $should_run = $ENV{DD_WINDOWS_QEMU_SMOKE} || 0;

if ( !$should_run ) {
    plan skip_all => 'Set DD_WINDOWS_QEMU_SMOKE=1 after configuring WINDOWS_QEMU_ENV_FILE or a windows-qemu.env file to run the live Windows QEMU smoke';
}

my $env_file = $ENV{WINDOWS_QEMU_ENV_FILE};
if ( !$env_file || !-f $env_file ) {
    my $project_env = File::Spec->catfile( getcwd(), '.developer-dashboard', 'windows-qemu.env' );
    my $home_env    = File::Spec->catfile( $ENV{HOME} || '', '.developer-dashboard', 'windows-qemu.env' );
    $env_file = -f $project_env ? $project_env : $home_env;
}

ok( -f $runner, 'Windows host rerun helper exists' );
ok( -x $runner, 'Windows host rerun helper is executable' );
ok( -f $env_file, 'Windows QEMU env file exists for the live smoke run' );

my ( $stdout, $stderr ) = capture {
    system $runner;
};
my $exit = $? >> 8;

is( $exit, 0, 'Windows host rerun helper exits successfully' );
like( $stdout, qr/QEMU Windows smoke passed|Windows Strawberry Perl smoke passed/, 'Windows host rerun helper reports a successful Windows smoke run' );
is( $stderr, '', 'Windows host rerun helper keeps stderr clean' );

done_testing();

__END__

=head1 NAME

29-windows-qemu-smoke.t - optionally run the live Windows QEMU smoke helper

=head1 DESCRIPTION

This test is skipped unless C<DD_WINDOWS_QEMU_SMOKE=1> is set. When enabled,
it expects the checked-in Windows QEMU env-file configuration to be available
and runs the host-side Windows QEMU smoke helper end to end.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for This test is skipped unless C<DD_WINDOWS_QEMU_SMOKE=1> is set. When enabled, it expects the checked-in Windows QEMU env-file configuration to be available and runs the host-side Windows QEMU smoke helper end to end. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because This test is skipped unless C<DD_WINDOWS_QEMU_SMOKE=1> is set. When enabled, it expects the checked-in Windows QEMU env-file configuration to be available and runs the host-side Windows QEMU smoke helper end to end has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use it when the checked-in Windows QEMU smoke flow, env-file contract, or Windows host bootstrap path changes.

=head1 HOW TO USE

Run it directly with C<prove -lv t/29-windows-qemu-smoke.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release.  Set DD_WINDOWS_QEMU_SMOKE=1 and provide the Windows QEMU env-file before running it; otherwise the test skips by design on normal Unix-only development hosts.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  DD_WINDOWS_QEMU_SMOKE=1 prove -lv t/29-windows-qemu-smoke.t

Run the optional Windows QEMU smoke once the prepared env file is in place.

Example 2:

  prove -lv t/29-windows-qemu-smoke.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/29-windows-qemu-smoke.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 4:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
