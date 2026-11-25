use strict;
use warnings;
use utf8;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;
use JSON::XS qw(decode_json);

use lib 'lib';

use Developer::Dashboard::GoRoutine;

my $runner_loaded = eval { require Developer::Dashboard::SystemMenu::Runner; 1 };
ok( $runner_loaded, 'system-menu runner module loads without starting a native menu' )
  or diag( $@ || 'runner module failed to load' );

# _fake_worker_command($state_dir)
# Writes a fake menu worker script (a small Perl program that reads menu
# items JSON from stdin, records them, and waits for TERM) and returns the
# argv to spawn it. The worker records its lifecycle in files under the
# state directory because a child process cannot share the test's memory.
# Input: state directory path.
# Output: argv array reference for the fake worker.
sub _fake_worker_command {
    my ($state_dir) = @_;
    my $worker = File::Spec->catfile( $state_dir, 'fake-menu-worker.pl' );
    open my $fh, '>', $worker or die "Unable to write fake menu worker '$worker': $!";
    print {$fh} <<'WORKER' or die "Unable to write fake menu worker '$worker': $!";
use strict;
use warnings;
use JSON::XS ();
my ($state_dir) = @ARGV;
local $/;
my $json = <STDIN>;
my $items = JSON::XS->new->utf8->decode($json);
# Install the TERM/INT handler BEFORE signalling entry: entered.json is
# the readiness signal the test waits on, and run_with stops the worker
# as soon as the callback returns or dies after seeing it. A TERM
# delivered before the handler exists kills the worker by the default
# action, so no stopped file is ever written (round 55, t/241 test 15
# on the loaded Pi - the worker was descheduled between writing
# entered.json and installing the handler). With the handler first,
# "entered" means "ready to be stopped".
$SIG{TERM} = sub {
    open my $sfh, '>', "$state_dir/stopped" or die "fake worker cannot record stop: $!";
    print {$sfh} "stopped\n";
    close $sfh or die "fake worker cannot close stop file: $!";
    exit 0;
};
$SIG{INT} = $SIG{TERM};
open my $fh, '>', "$state_dir/entered.json" or die "fake worker cannot record entry: $!";
print {$fh} JSON::XS->new->utf8->canonical->encode($items);
close $fh or die "fake worker cannot close entry file: $!";
while (1) { sleep 1; }
WORKER
    close $fh or die "Unable to close fake menu worker '$worker': $!";
    return [ $^X, $worker, $state_dir ];
}

# _worker_stopped_ok($runner, $dir, $label)
# Asserts the menu worker is stopped after a run: on POSIX the worker
# records a clean TERM shutdown; on Windows it is terminated (no TERM
# handler runs) and the runner holds no worker pid.
# Input: runner object, worker state directory, and test label.
# Output: one test result.
sub _worker_stopped_ok {
    my ( $runner, $dir, $label ) = @_;
    if ( $^O ne 'MSWin32' ) {
        ok( -f File::Spec->catfile( $dir, 'stopped' ), $label );
    }
    else {
        ok( !$runner->{menu_pid}, $label );
    }
}

# _wait_for_file($path, $seconds)
# Polls until a file appears.
# Input: file path and maximum wait in seconds.
# Output: true when the file exists, false on timeout.
sub _wait_for_file {
    my ( $path, $seconds ) = @_;
    my $tries = int( $seconds / 0.05 );
    for ( 1 .. $tries ) {
        return 1 if -f $path;
        select undef, undef, undef, 0.05;
    }
    return -f $path ? 1 : 0;
}

SKIP: {
    skip 'system-menu runner is not implemented yet', 14 if !$runner_loaded;

    my $disabled_dir = tempdir( CLEANUP => 1 );
    my $disabled = Developer::Dashboard::SystemMenu::Runner->new(
        config => { indicators => [
            { name => 'build', indicator => { macos => 0 } },
        ] },
        platform       => 'macos',
        store          => Local::SystemMenuTestStore->new,
        worker_command => _fake_worker_command($disabled_dir),
    );

    ok( !$disabled->start, 'disabled platform setting does not launch a menu worker' );
    ok( !_wait_for_file( File::Spec->catfile( $disabled_dir, 'entered.json' ), 1 ),
        'disabled setting spawns no worker process' );

    my $enabled_dir = tempdir( CLEANUP => 1 );
    my $enabled = Developer::Dashboard::SystemMenu::Runner->new(
        config => { indicators => [
            { name => 'build', indicator => { macos => 1 } },
            { name => 'hidden', indicator => { macos => 0 } },
        ] },
        platform       => 'macos',
        store          => Local::SystemMenuTestStore->new,
        worker_command => _fake_worker_command($enabled_dir),
    );

    my $pid = $enabled->start;
    ok( $pid && $pid =~ /\A[0-9]+\z/, 'enabled setting starts a controlled menu worker process' );

    my $entered_file = File::Spec->catfile( $enabled_dir, 'entered.json' );
    ok( _wait_for_file( $entered_file, 10 ), 'worker enters the native menu run loop' );
    my $entered_json = do { local $/; open my $efh, '<', $entered_file or die "Unable to read entered file: $!"; <$efh> };
    is 0 + utf8::is_utf8( decode_json($entered_json)->[0]{icon} ), 1,
      'worker menu input retains the icon UTF-8 flag';
    is_deeply(
        decode_json($entered_json), [ { name => 'build', icon => '✅' } ],
        'menu receives only enabled indicators and their latest stored icons',
    );

    ok( $enabled->stop, 'stop requests clean menu shutdown and waits for the worker' );
    ok( !process_running($pid), 'menu worker process exits after stop' );
    _worker_stopped_ok( $enabled, $enabled_dir, 'menu worker stops cleanly on TERM' );

    my $service_dir = tempdir( CLEANUP => 1 );
    my $service_runner = Developer::Dashboard::SystemMenu::Runner->new(
        config => { indicators => [
            { name => 'build', indicator => { macos => 1 } },
        ] },
        platform       => 'macos',
        store          => Local::SystemMenuTestStore->new,
        worker_command => _fake_worker_command($service_dir),
    );
    my $served = $service_runner->run_with( sub {
        _wait_for_file( File::Spec->catfile( $service_dir, 'entered.json' ), 10 );
        return 'server-exit';
    } );
    is( $served, 'server-exit', 'foreground service return value is preserved' );
    _worker_stopped_ok( $service_runner, $service_dir,
        'foreground service exit stops and joins the enabled menu worker' );

    my $failure_dir = tempdir( CLEANUP => 1 );
    my $failure_runner = Developer::Dashboard::SystemMenu::Runner->new(
        config => { indicators => [
            { name => 'build', indicator => { macos => 1 } },
        ] },
        platform       => 'macos',
        store          => Local::SystemMenuTestStore->new,
        worker_command => _fake_worker_command($failure_dir),
    );
    my $failure_ok = eval {
        $failure_runner->run_with( sub {
            _wait_for_file( File::Spec->catfile( $failure_dir, 'entered.json' ), 10 );
            die "server failed\n";
        } );
        1;
    };
    ok( !$failure_ok, 'foreground service exception is propagated' );
    like( $@, qr/server failed/, 'foreground service preserves the original failure text' );
    _worker_stopped_ok( $failure_runner, $failure_dir,
        'foreground service failure still stops and joins the menu worker' );
}

my $core_path = File::Spec->catfile( $RealBin, File::Spec->updir, 'share', 'private-cli', '_dashboard-core' );
open my $core_fh, '<', $core_path or die "Unable to read private dashboard runtime '$core_path': $!";
my $core_source = do { local $/; <$core_fh> };
close $core_fh or die "Unable to close private dashboard runtime '$core_path': $!";
like( $core_source,
    qr/elsif\s*\(\s*\$cmd\s+eq\s+'web-foreground'.*?SystemMenu::Runner->new\(.*?config\s*=>\s*\$config->merged.*?store\s*=>\s*\$indicators.*?->run_with\(/s,
    'web-foreground starts the configured native menu around the long-lived service' );

done_testing;

package Local::SystemMenuTestStore;

# new()
# Creates the test indicator store.
# Input: class name.
# Output: in-memory store object.
sub new { bless {}, shift }

# list_indicators()
# Returns the current in-memory indicator snapshot.
# Input: store object.
# Output: array reference of indicator state hashes.
sub list_indicators {
    return (
        { name => 'build', icon => '✅', status => 'ok' },
        { name => 'hidden', icon => '❌', status => 'error' },
    );
}

1;

__END__

=head1 NAME

t/241-system-menu-runner.t - system-menu runner lifecycle regression tests

=head1 PURPOSE

This test specifies the opt-in boundary between configured Dashboard indicators,
the current indicator store, the platform menu adapter, and the menu worker
process. It uses an injected fake worker command (a small Perl program that
reads the items JSON from stdin and records its lifecycle in files), so Linux
Docker can test selection and shutdown without claiming that a native desktop
menu is visible.

=head1 WHY IT EXISTS

The System Menu integration must not launch a helper when no indicator is
enabled for the current platform. When enabled, it must pass the current
indicator projection to one controlled worker and stop that worker cleanly.
These checks protect the runtime contract independently of AppKit, Windows
notification-area, or Ubuntu desktop availability.

=head1 WHEN TO USE

Run this file in the dev Docker container when changing the system-menu runner,
its indicator-store integration, or menu worker lifecycle handling. Native
platform visibility still requires the corresponding hosted platform workflow.

=head1 HOW TO USE

    d2 docker compose exec dev prove -lv t/241-system-menu-runner.t

The test loads C<Developer::Dashboard::SystemMenu::Runner>, verifies that a
disabled platform setting is inert, starts an enabled fake menu worker, checks
the projected indicator data, then requests stop and verifies worker exit.
It also verifies that the staged private runtime wraps the long-lived
C<web-foreground> service in this lifecycle using merged configuration and the
shared indicator store.

=head1 EXAMPLES

The disabled case configures C<macos =E<gt> 0> and proves that no worker
process is started. The enabled case configures one visible and one hidden
indicator, verifies the visible entry carries the stored icon, then calls
C<stop> and checks the worker process exits. The service wrapper example
returns a value from a short server callback and proves the value is preserved
while the menu worker is joined. A second callback throws an error and the test
checks both that the original error remains visible and that menu shutdown
still occurs.

=head1 WHAT USES IT

The Docker unit suite uses this test as the platform-independent contract for
C<Developer::Dashboard::SystemMenu::Runner> and its private service wiring. It
does not replace the native macOS, Windows, and Ubuntu integration workflows,
which must exercise each platform-specific adapter on an appropriate host.

=cut
