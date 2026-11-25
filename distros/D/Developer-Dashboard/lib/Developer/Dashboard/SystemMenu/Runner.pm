package Developer::Dashboard::SystemMenu::Runner;

use strict;
use warnings;

our $VERSION = '6.31';

use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempfile);
use JSON::XS ();

use Developer::Dashboard::GoRoutine qw(
  process_running
  spawn
  terminate_process
  wait_process
);
use Developer::Dashboard::SystemMenu;

# new(%args)
# Builds a platform-specific menu runner using the current indicator store.
# Input: config hash reference, store object, platform name, and optional
#        worker command array reference for tests or specialized
#        integrations (defaults to the private system-menu-foreground
#        helper, which runs the native menu in its own process).
# Output: runner object; invalid dependencies are rejected with an error.
sub new {
    my ( $class, %args ) = @_;
    die "config must be a hash reference\n" if ref( $args{config} ) ne 'HASH';
    die "store must provide list_indicators\n"
      if !ref( $args{store} ) || !$args{store}->can('list_indicators');
    die "platform must be a non-empty string\n"
      if !defined $args{platform} || ref( $args{platform} ) || $args{platform} eq '';
    die "worker_command must be an array reference\n"
      if defined $args{worker_command} && ref( $args{worker_command} ) ne 'ARRAY';

    return bless {
        config         => $args{config},
        store          => $args{store},
        platform       => $args{platform},
        worker_command => $args{worker_command},
        menu_pid       => undef,
        items_file     => undef,
    }, $class;
}

# start()
# Starts the native menu worker only when the current platform has visible
# configured indicators. The menu runs in its own process (the private
# system-menu-foreground helper): the items are plain data, so they travel
# as JSON on the worker's stdin, and the parent never needs to pump an
# engine while the foreground web service blocks in its server loop.
# Input: runner object.
# Output: worker process id when started, or undef when the menu is disabled.
sub start {
    my ($self) = @_;
    die "system menu runner is already active\n" if $self->{menu_pid};

    my $states = [ $self->{store}->list_indicators ];
    my $items = Developer::Dashboard::SystemMenu->items_for_platform(
        config     => $self->{config},
        indicators => $states,
        platform   => $self->{platform},
    );
    return if !@{$items};

    my $items_json = JSON::XS->new->utf8->canonical->encode($items);
    my ( $fh, $items_file ) = tempfile( UNLINK => 0 );
    print {$fh} $items_json or die "Unable to write menu items file: $!";
    close $fh or die "Unable to close menu items file: $!";
    my $command = $self->{worker_command} || $self->_default_worker_command;
    my $pid = spawn( $command, { stdin => $items_file } );
    $self->{menu_pid}   = $pid;
    $self->{items_file} = $items_file;
    return $pid;
}

# stop()
# Requests native menu shutdown and waits until its worker process exits.
# The worker stops cleanly on TERM (its signal handler asks the menu to
# stop, so the native helper is stopped too); on Windows TERM maps to
# native process termination and the helper exits when its stdin closes.
# Input: runner object.
# Output: true after clean shutdown.
sub stop {
    my ($self) = @_;
    my $pid = $self->{menu_pid} or return 0;
    terminate_process( $pid, 'TERM' ) if process_running($pid);
    wait_process($pid);
    $self->{menu_pid} = undef;
    if ( defined $self->{items_file} ) {
        unlink $self->{items_file};
        $self->{items_file} = undef;
    }
    return 1;
}

# run_with($callback)
# Runs one foreground service while the configured native menu worker is active,
# then stops and joins that worker on normal return or exception.
# Input: runner object and a code reference for the foreground service.
# Output: the service callback's scalar return value; propagates service or
#        shutdown errors without leaving an active menu worker.
sub run_with {
    my ( $self, $callback ) = @_;
    die "foreground callback must be a code reference\n" if ref($callback) ne 'CODE';

    my ( $result, $run_ok, $run_error );
    $run_ok = eval {
        $self->start;
        $result = $callback->();
        1;
    };
    $run_error = $@;

    my ( $stop_ok, $stop_error );
    $stop_ok = eval { $self->stop; 1 };
    $stop_error = $@;

    die "$run_error\nSystem menu shutdown also failed: $stop_error"
      if !$run_ok && !$stop_ok;
    die $run_error if !$run_ok;
    die $stop_error if !$stop_ok;
    return $result;
}

# _default_worker_command()
# Resolves the private system-menu-foreground helper beside the running
# d2 helper, in the same way the SSL backend command does.
# Input: runner object.
# Output: argv array reference for the menu worker process.
sub _default_worker_command {
    my ($self) = @_;
    my $running_helper = $ENV{DEVELOPER_DASHBOARD_RUNNING_HELPER};
    die 'Missing private Dashboard helper for system menu process'
      if !defined $running_helper || $running_helper eq '';
    my $helper = File::Spec->catfile( dirname($running_helper), '_dashboard-core' );
    return [ $^X, $helper, 'system-menu-foreground' ];
}

1;

__END__

=head1 NAME

Developer::Dashboard::SystemMenu::Runner - opt-in native indicator menu lifecycle

=head1 PURPOSE

This module maps the configured Dashboard indicators for one operating system
and runs the native System Menu adapter in its own worker process. It keeps
the blocking native event loop out of the command's main execution path and
out of the GoRoutine engine: the menu worker is a plain process, so the
foreground web service never has to pump an engine while it blocks in its
server loop.

=head1 WHY IT EXISTS

System Menu's C<run> method owns a blocking native event loop. Running that loop
directly would prevent the Dashboard process from continuing its normal work.
This runner starts no native adapter when the current platform has no enabled
indicator, and it retains one explicit stop-and-wait lifecycle for enabled
menus. The worker is a separate process because the foreground callback blocks
in the web server (Starman for plain HTTP, the SSL frontend for HTTPS), and
neither server loop pumps the GoRoutine engine: a timer routine driving the
menu would never fire. The menu items are plain data (name and icon only, no
code references), so they travel to the worker as JSON on its stdin.

=head1 WHEN TO USE

Use this runner from the private C<web-foreground> runtime after configuration
layers and current indicator state have been loaded. Do not instantiate it
from lightweight CLI commands. Native desktop visibility and shutdown still
require hosted checks on each supported operating system.

=head1 HOW TO USE

    my $runner = Developer::Dashboard::SystemMenu::Runner->new(
        config   => $config,
        store    => $indicator_store,
        platform => 'macos',
    );
    my $worker = $runner->start;
    # ... normal Dashboard runtime ...
    $runner->stop if $worker;

C<start> returns undef and does not load the native adapter when there are no
visible configured indicators. When enabled, it projects current states in
configuration order, writes them as JSON to a temporary file, and spawns the
private C<system-menu-foreground> helper with that file as the worker's stdin.
C<stop> terminates the worker, waits for it to exit, and removes the items
file.

C<run_with($callback)> owns the common foreground-service lifecycle. It starts
the menu, invokes the callback, then requests and waits for menu shutdown after
either a normal callback return or an exception. The callback must be a code
reference. Its scalar result is returned unchanged; service errors are
re-thrown, and shutdown errors remain visible (including alongside a service
error).

=head1 EXAMPLES

An opt-in macOS configuration can select the build indicator:

    {
        indicators => [
            { name => 'build', indicator => { macos => 1 } },
        ],
    }

The same runner accepts C<windows> or C<ubuntu> as its platform key. Tests may
pass a C<worker_command> array reference to substitute a fake worker process
instead of the private helper; production callers omit it. A disabled
configuration returns no worker and does not spawn a process.

The foreground web service uses the wrapper form:

    my $status = $runner->run_with(sub { $server->run });

=head1 WHAT USES IT

The runtime menu integration uses this class to connect merged configuration,
IndicatorStore state, the pure SystemMenu projection, and the native event loop.
The focused Docker regression test injects a fake worker command to verify
selection and lifecycle without claiming native UI behavior.

=cut
