#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';
use Developer::Dashboard::CLI::Upgrade ();
use Developer::Dashboard::InternalCLI ();

{
    package Local::UpgradeResponse;

    sub new {
        my ( $class, %args ) = @_;
        return bless \%args, $class;
    }

    sub is_success      { return $_[0]->{success} ? 1 : 0 }
    sub code            { return $_[0]->{code} }
    sub message         { return $_[0]->{message} }
    sub header          { return $_[1] eq 'Client-Aborted' ? $_[0]->{client_aborted} : undef }
    sub decoded_content { return $_[0]->{content} }
}

{
    package Local::UpgradeUA;

    sub new {
        my ( $class, %args ) = @_;
        return bless \%args, $class;
    }

    sub get {
        my ( $self, $url ) = @_;
        push @{ $self->{urls} }, $url;
        return $self->{response};
    }
}

my $unix_installer = <<'SH';
#!/bin/sh
# Developer Dashboard install progress
DEFAULT_BOOTSTRAP_REPOSITORY_URL="https://github.com/manif3station/developer-dashboard.git"
exit 0
SH

my $windows_installer = <<'POWERSHELL';
& {
Set-StrictMode -Version Latest
$DefaultBootstrapRepository = 'https://github.com/manif3station/developer-dashboard.git'
Write-Host 'Developer Dashboard install progress'
}
POWERSHELL

sub upgrade_ua {
    my (%args) = @_;
    my $urls = $args{urls} || [];
    return Local::UpgradeUA->new(
        urls     => $urls,
        response => Local::UpgradeResponse->new(
            success => exists $args{success} ? $args{success} : 1,
            code    => $args{code} || 200,
            message => $args{message} || 'OK',
            content => $args{content},
            client_aborted => $args{client_aborted},
        ),
    );
}

sub dies_like {
    my ( $code, $pattern, $name ) = @_;
    my $error = eval { $code->(); 1 } ? '' : $@;
    like( $error, $pattern, $name );
}

{
    my @urls;
    my @commands;
    my $ua = upgrade_ua( urls => \@urls, content => $unix_installer );

    my $exit = Developer::Dashboard::CLI::Upgrade::run_upgrade(
        args     => [],
        platform => 'unix',
        ua       => $ua,
        runner   => sub {
            my ($argv) = @_;
            push @commands, [ @{$argv} ];
            return 0;
        },
    );

    is( $exit, 0, 'Given a Unix-like install, when upgrade runs, then it completes through the installer' );
    is_deeply(
        \@urls,
        ['https://raw.githubusercontent.com/manif3station/developer-dashboard/master/install.sh'],
        'the Unix-like upgrade downloads only the canonical HTTPS installer',
    );
    is( scalar @commands, 1, 'the downloaded Unix installer runs exactly once' );
    is( $commands[0][0], 'sh', 'the Unix-like installer runs through sh instead of shell interpolation' );
    ok( -f $commands[0][1], 'the Unix installer exists while the runner executes it' );
    is( ( stat $commands[0][1] )[2] & 07777, 0600, 'the downloaded Unix installer is private before execution' );
}

{
    my @urls;
    my @commands;
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::Upgrade::_powershell_command = sub { return 'pwsh' };
    my $exit = Developer::Dashboard::CLI::Upgrade::run_upgrade(
        args     => [],
        platform => 'windows',
        ua       => upgrade_ua( urls => \@urls, content => $windows_installer ),
        runner   => sub {
            my ($argv) = @_;
            push @commands, [ @{$argv} ];
            return 23;
        },
    );

    is( $exit, 23, 'Given Windows, installer failure status is returned unchanged' );
    is_deeply(
        \@urls,
        ['https://raw.githubusercontent.com/manif3station/developer-dashboard/master/install.ps1'],
        'the Windows upgrade downloads only the canonical HTTPS installer',
    );
    is_deeply(
        [ @{ $commands[0] }[ 0 .. 3 ] ],
        [ 'pwsh', '-NoProfile', '-ExecutionPolicy', 'Bypass' ],
        'the Windows installer runs through PowerShell with a process-scoped execution-policy bypass',
    );
    is( $commands[0][4], '-File', 'PowerShell receives the installer through -File' );
    like( $commands[0][5], qr/\.ps1\z/, 'the Windows temporary installer keeps its ps1 suffix' );
}

{
    my $output = '';
    open my $out, '>', \$output or die "Unable to open scalar output: $!";
    my $exit = Developer::Dashboard::CLI::Upgrade::run_upgrade(
        args     => ['--dry-run'],
        platform => 'windows',
        out      => $out,
    );
    close $out;

    is( $exit, 0, 'Windows dry-run succeeds without resolving PowerShell' );
    is(
        $output,
        "Developer Dashboard upgrade plan\nPlatform: windows\nInstaller: https://raw.githubusercontent.com/manif3station/developer-dashboard/master/install.ps1\nCommand: pwsh|powershell -NoProfile -ExecutionPolicy Bypass -File <downloaded-install.ps1>\n",
        'Windows dry-run reports both supported PowerShell executables without claiming which one is installed',
    );
}

{
    my @urls;
    my @commands;
    my $output = '';
    my $ua = upgrade_ua( urls => \@urls, content => $unix_installer );
    open my $out, '>', \$output or die "Unable to open scalar output: $!";
    my $exit = Developer::Dashboard::CLI::Upgrade::run_upgrade(
        args     => ['--dry-run'],
        platform => 'unix',
        ua       => $ua,
        out      => $out,
        runner   => sub { push @commands, $_[0]; return 0 },
    );
    close $out;

    is( $exit, 0, 'dry-run succeeds' );
    is_deeply( \@urls, [], 'dry-run performs no network request' );
    is_deeply( \@commands, [], 'dry-run executes no installer' );
    is(
        $output,
        "Developer Dashboard upgrade plan\nPlatform: unix\nInstaller: https://raw.githubusercontent.com/manif3station/developer-dashboard/master/install.sh\nCommand: sh <downloaded-install.sh>\n",
        'dry-run reports the exact Unix platform, installer, and command plan',
    );
}

for my $case (
    [ [ '--unknown' ], qr/Usage: dashboard upgrade \[--dry-run\]/, 'unsupported options fail with upgrade usage' ],
    [ ['operand'],     qr/Usage: dashboard upgrade \[--dry-run\]/, 'positional operands fail with upgrade usage' ],
  )
{
    my $error = '';
    my ( undef, $stderr ) = capture {
        $error = eval {
            Developer::Dashboard::CLI::Upgrade::run_upgrade(
                args     => $case->[0],
                platform => 'unix',
            );
            1;
        } ? '' : $@;
    };
    like( $error, $case->[1], $case->[2] );
    is( $stderr, '', "$case->[2] without parser warnings" );
}

dies_like(
    sub {
        Developer::Dashboard::CLI::Upgrade::run_upgrade(
            args     => [],
            platform => 'unix',
            ua       => upgrade_ua( success => 0, code => 503, message => 'Unavailable' ),
        );
    },
    qr/Unable to download Developer Dashboard installer.*503 Unavailable/s,
    'download failure stops with the HTTP status and an actionable error',
);

dies_like(
    sub {
        Developer::Dashboard::CLI::Upgrade::run_upgrade(
            args     => [],
            platform => 'unix',
            ua       => upgrade_ua(
                content        => $unix_installer,
                client_aborted => 'max_size',
            ),
        );
    },
    qr/exceeds 512000 bytes/,
    'a response truncated by the transport size bound is rejected instead of executing partial content',
);

dies_like(
    sub {
        Developer::Dashboard::CLI::Upgrade::run_upgrade(
            args     => [],
            platform => 'unix',
            ua       => upgrade_ua( content => "<html>not an installer</html>\n" ),
        );
    },
    qr/not the expected Developer Dashboard unix installer/,
    'unexpected downloaded content is rejected before execution',
);

dies_like(
    sub { Developer::Dashboard::CLI::Upgrade::run_upgrade( args => [], platform => 'plan9' ) },
    qr/Unsupported upgrade platform 'plan9'/,
    'an unknown platform stops with an actionable error',
);

{
    no warnings 'redefine';
    local *Developer::Dashboard::Platform::command_in_path = sub { return 0 };
    dies_like(
        sub { Developer::Dashboard::CLI::Upgrade::_powershell_command() },
        qr/neither pwsh nor powershell is available/,
        'Windows upgrade fails clearly when PowerShell is unavailable',
    );
}

{
    local $SIG{__WARN__} = sub { };
    dies_like(
        sub { Developer::Dashboard::CLI::Upgrade::_run_command( ['missing-installer'] ) },
        qr/Unable to start Developer Dashboard installer/,
        'process creation failure is reported clearly',
    );
}

{
    is(
        Developer::Dashboard::CLI::Upgrade::_run_command( [ $^X, '-e', 'kill 15, $$' ] ),
        143,
        'a signalled installer returns the conventional 128-plus-signal status',
    );
    is(
        Developer::Dashboard::CLI::Upgrade::_run_command( [ $^X, '-e', 'exit 7' ] ),
        7,
        'a normally exiting installer returns its exit status unchanged',
    );
}

for my $case (
    [ sub { Developer::Dashboard::CLI::Upgrade::run_upgrade() }, qr/Missing upgrade arguments/, 'missing argument storage fails clearly' ],
    [ sub { Developer::Dashboard::CLI::Upgrade::run_upgrade( args => 'not-an-array' ) }, qr/array reference/, 'non-array arguments fail clearly' ],
    [ sub { Developer::Dashboard::CLI::Upgrade::_validate_installer( 'unix', undef ) }, qr/installer is empty/, 'undefined installer content is rejected' ],
    [ sub { Developer::Dashboard::CLI::Upgrade::_validate_installer( 'unix', '' ) }, qr/installer is empty/, 'empty installer content is rejected' ],
    [ sub { Developer::Dashboard::CLI::Upgrade::_validate_installer( 'unix', 'x' x 512_001 ) }, qr/exceeds 512000 bytes/, 'oversized installer content is rejected' ],
    [ sub { Developer::Dashboard::CLI::Upgrade::_validate_installer( 'unix', "#!/bin/sh\nDeveloper Dashboard install progress\n" ) }, qr/not the expected/, 'Unix installer without the canonical repository marker is rejected' ],
    [ sub { Developer::Dashboard::CLI::Upgrade::_validate_installer( 'unix', "#!/bin/sh\nmanif3station/developer-dashboard.git\n" ) }, qr/not the expected/, 'Unix installer without the progress marker is rejected' ],
    [ sub { Developer::Dashboard::CLI::Upgrade::_validate_installer( 'unix', "Developer Dashboard install progress\nmanif3station/developer-dashboard.git\n" ) }, qr/not the expected/, 'Unix installer without the shell header is rejected' ],
    [ sub { Developer::Dashboard::CLI::Upgrade::_validate_installer( 'windows', "Set-StrictMode -Version Latest\nDeveloper Dashboard install progress\n" ) }, qr/not the expected/, 'Windows installer without the canonical repository marker is rejected' ],
    [ sub { Developer::Dashboard::CLI::Upgrade::_validate_installer( 'windows', "Set-StrictMode -Version Latest\nmanif3station/developer-dashboard.git\n" ) }, qr/not the expected/, 'Windows installer without the progress marker is rejected' ],
    [ sub { Developer::Dashboard::CLI::Upgrade::_validate_installer( 'windows', "Developer Dashboard install progress\nmanif3station/developer-dashboard.git\n" ) }, qr/not the expected/, 'Windows installer without strict mode is rejected' ],
  )
{
    dies_like( $case->[0], $case->[1], $case->[2] );
}

{
    my $ua = Developer::Dashboard::CLI::Upgrade::_user_agent();
    # Derived, never hardcoded (DD-506). This literal said 4.24 while the module
    # reported 4.25, so the suite failed on master at the exact commit v4.25 was
    # tagged at. The bump procedure updates lib/** $VERSION, dist.ini, the main
    # POD and t/15 - a version string anywhere else is invisible to it, and the
    # only fix that survives the next bump is to ask the module what it is.
    is(
        $ua->agent,
        "Developer-Dashboard/$Developer::Dashboard::CLI::Upgrade::VERSION upgrade",
        'the production downloader identifies the installed dashboard version',
    );
    is( $ua->timeout, 60, 'the production downloader has a bounded timeout' );
    is( $ua->max_size, 512_000, 'the production downloader bounds installer size' );
    is( $ua->max_redirect, 3, 'the production downloader bounds redirects' );
    is_deeply( $ua->protocols_allowed, ['https'], 'the production downloader permits HTTPS only' );
}

{
    my $output = '';
    open my $out, '>', \$output or die "Unable to open scalar output: $!";
    local *STDOUT = $out;
    is(
        Developer::Dashboard::CLI::Upgrade::run_upgrade( args => ['--dry-run'] ),
        0,
        'the default platform path resolves on the active host',
    );
    close $out;
    like( $output, qr/^Platform: unix$/m, 'the active non-Windows host resolves to the Unix installer family' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    is(
        Developer::Dashboard::CLI::Upgrade::_platform_name(),
        'windows',
        'a real Windows runtime resolves to the Windows installer family through the shared platform detector',
    );

    my $output = '';
    open my $out, '>', \$output or die "Unable to open scalar output: $!";
    my @urls;
    my @commands;
    is(
        Developer::Dashboard::CLI::Upgrade::run_upgrade(
            args   => ['--dry-run'],
            out    => $out,
            ua     => upgrade_ua( urls => \@urls, content => $windows_installer ),
            runner => sub { push @commands, $_[0]; return 0 },
        ),
        0,
        'Given a Windows runtime with no explicit platform override, when upgrade runs, then it plans without a network request',
    );
    close $out;
    like( $output, qr/^Platform: windows$/m, 'the forced Windows runtime selects the Windows installer family end to end' );
    like( $output, qr{^Installer: \Qhttps://raw.githubusercontent.com/manif3station/developer-dashboard/master/install.ps1\E$}m, 'the forced Windows runtime plans the canonical install.ps1 asset' );
    is_deeply( \@urls, [], 'the Windows plan performs no network request' );
    is_deeply( \@commands, [], 'the Windows plan executes no installer' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'darwin';
    is(
        Developer::Dashboard::CLI::Upgrade::_platform_name(),
        'unix',
        'macOS resolves to the Unix installer family so upgrade uses install.sh through sh',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::Upgrade::_user_agent = sub {
        return upgrade_ua( content => $unix_installer );
    };
    is(
        Developer::Dashboard::CLI::Upgrade::run_upgrade( args => [], platform => 'unix' ),
        0,
        'the default downloader and runner seams execute a validated installer successfully',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::Platform::command_in_path = sub { return $_[0] eq 'pwsh' ? '/bin/pwsh' : undef };
    is( Developer::Dashboard::CLI::Upgrade::_powershell_command(), 'pwsh', 'PowerShell Core is preferred when available' );
    local *Developer::Dashboard::Platform::command_in_path = sub { return $_[0] eq 'powershell' ? '/bin/powershell' : undef };
    is( Developer::Dashboard::CLI::Upgrade::_powershell_command(), 'powershell', 'Windows PowerShell is used when PowerShell Core is absent' );
}

is(
    Developer::Dashboard::InternalCLI::canonical_helper_name('upgrade'),
    'upgrade',
    'upgrade is registered as a first-class built-in helper',
);

my $repo_root = abs_path( File::Spec->catdir( dirname(__FILE__), '..' ) );
my $dashboard = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $d2 = File::Spec->catfile( $repo_root, 'bin', 'd2' );
my $lib = File::Spec->catdir( $repo_root, 'lib' );
my $home = tempdir( CLEANUP => 1 );
my ( $dashboard_out, $dashboard_err, $dashboard_status ) = capture {
    local $ENV{HOME} = $home;
    system $^X, '-I', $lib, $dashboard, 'upgrade', '--dry-run';
};
my ( $d2_out, $d2_err, $d2_status ) = capture {
    local $ENV{HOME} = $home;
    system $^X, '-I', $lib, $d2, 'upgrade', '--dry-run';
};
is( $dashboard_status >> 8, 0, 'dashboard upgrade --dry-run dispatches successfully' );
is( $dashboard_err, '', 'dashboard upgrade --dry-run emits no stderr' );
is( $d2_status >> 8, 0, 'd2 upgrade --dry-run reaches the same built-in command' );
is( $d2_err, '', 'd2 upgrade --dry-run emits no stderr' );
is( $d2_out, $dashboard_out, 'd2 upgrade output is identical to dashboard upgrade output' );
like( $dashboard_out, qr/^Developer Dashboard upgrade plan$/m, 'the public command prints the upgrade plan' );

ok(
    -f File::Spec->catfile( $repo_root, 'share', 'private-cli', 'upgrade' ),
    'the dedicated staged upgrade helper is shipped',
);

done_testing;

__END__

=pod

=head1 NAME

t/136-upgrade-cli.t - acceptance contract for dashboard and d2 self-upgrade

=head1 PURPOSE

This test is the automated BDD and ATDD contract for the first-class
C<dashboard upgrade> and C<d2 upgrade> command. It verifies that the command
selects the canonical platform installer, validates downloaded content, and
runs it without shell-string interpolation.

=head1 WHY IT EXISTS

Self-upgrade crosses a remote software-installation trust boundary. This test
keeps platform selection, transport failure, installer validation, argument
handling, and process status observable without making a real network request
or changing the test machine.

=head1 WHEN TO USE

Use this file whenever the built-in upgrade command, its staged helper, remote
installer URLs, or platform process invocation changes.

=head1 HOW TO USE

Run C<prove -lv t/136-upgrade-cli.t> during the RED-GREEN-REFACTOR loop, then
run the full test and coverage gates before shipping.

=head1 WHAT USES IT

Contributors and release automation use this acceptance test to prevent an
upgrade command from executing an unexpected response body or hiding installer
failures.

=head1 EXAMPLES

  prove -lv t/136-upgrade-cli.t
  prove -lr t

=cut
