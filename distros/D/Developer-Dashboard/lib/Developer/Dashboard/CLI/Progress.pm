package Developer::Dashboard::CLI::Progress;

use strict;
use warnings;

our $VERSION = '3.14';

# new(%args)
# Constructs a terminal progress renderer for restart/stop lifecycle commands.
# Input: title string, arrayref of task hashes, output stream handle, and dynamic flag.
# Output: Developer::Dashboard::CLI::Progress object.
sub new {
    my ( $class, %args ) = @_;
    my $tasks = $args{tasks} || [];
    die 'Progress tasks must be an array reference' if ref($tasks) ne 'ARRAY';
    my @order = map { $_->{id} } @{$tasks};
    my %task_lookup = map {
        my $task = $_;
        my $id   = $task->{id} || die 'Progress task missing id';
        $id => {
            id     => $id,
            label  => $task->{label} || $id,
            status => 'pending',
        }
    } @{$tasks};
    my $stream = $args{stream} || \*STDERR;
    my $self = bless {
        title    => $args{title} || 'dashboard progress',
        order    => \@order,
        tasks    => \%task_lookup,
        stream   => $stream,
        dynamic  => $args{dynamic} ? 1 : 0,
        color    => $args{color} ? 1 : 0,
        rendered => 0,
    }, $class;
    $self->render;
    return $self;
}

# callback()
# Returns a callback that updates task state from runtime lifecycle events.
# Input: none.
# Output: coderef that accepts one hash reference event.
sub callback {
    my ($self) = @_;
    return sub {
        my ($event) = @_;
        $self->update($event);
    };
}

# update($event)
# Applies one lifecycle progress event to the tracked task board.
# Input: hash reference with task_id, status, and optional label.
# Output: true value.
sub update {
    my ( $self, $event ) = @_;
    return 1 if !$event || ref($event) ne 'HASH';
    my $id = $event->{task_id} || return 1;
    my $task = $self->{tasks}{$id} || return 1;
    $task->{status} = $event->{status} if defined $event->{status} && $event->{status} ne '';
    $task->{label}  = $event->{label}  if defined $event->{label}  && $event->{label} ne '';
    $self->render;
    return 1;
}

# finish()
# Finalizes the rendered board by ensuring a trailing newline after dynamic redraws.
# Input: none.
# Output: true value.
sub finish {
    my ($self) = @_;
    return 1 if !$self->{dynamic} || !$self->{rendered};
    my $stream = $self->{stream};
    print {$stream} "\n";
    return 1;
}

# render()
# Renders the full task board to the configured output stream.
# Input: none.
# Output: true value.
sub render {
    my ($self) = @_;
    my $stream = $self->{stream};
    my $board  = $self->render_text;
    if ( $self->{dynamic} && $self->{rendered} ) {
        my $line_count = scalar( split /\n/, $board );
        for ( 1 .. $line_count ) {
            print {$stream} "\e[1A\e[2K";
        }
    }
    print {$stream} $board;
    $self->{rendered} = 1;
    return 1;
}

# render_text()
# Builds the current task board text for terminal output.
# Input: none.
# Output: multi-line string.
sub render_text {
    my ($self) = @_;
    my @lines = ( $self->{title} );
    for my $id ( @{ $self->{order} } ) {
        my $task   = $self->{tasks}{$id} || next;
        my $prefix = $self->_status_prefix( $task->{status} );
        push @lines, sprintf '%s %s', $self->_colorize( $prefix, $task->{status} ), $task->{label};
    }
    return join( "\n", @lines ) . "\n";
}

# _status_prefix($status)
# Maps one task status to the terminal marker shown beside the task label.
# Input: status string.
# Output: short ASCII marker string.
sub _status_prefix {
    my ( $self, $status ) = @_;
    return '[OK]' if defined $status && $status eq 'done';
    return '->'   if defined $status && $status eq 'running';
    return '[X]'  if defined $status && $status eq 'failed';
    return '[ ]';
}

# _colorize($text, $status)
# Wraps one marker with ANSI color escapes when terminal color output is enabled.
# Input: marker text string and status string.
# Output: plain or ANSI-colored marker string.
sub _colorize {
    my ( $self, $text, $status ) = @_;
    return $text if !$self->{color};
    return "\e[32m$text\e[0m" if defined $status && $status eq 'done';
    return "\e[33m$text\e[0m" if defined $status && $status eq 'running';
    return "\e[31m$text\e[0m" if defined $status && $status eq 'failed';
    return $text;
}

1;

__END__

=head1 NAME

Developer::Dashboard::CLI::Progress - terminal task-board renderer for lifecycle commands

=head1 SYNOPSIS

  my $progress = Developer::Dashboard::CLI::Progress->new(
      title => 'dashboard restart progress',
      tasks => [
          { id => 'stop_web',  label => 'Stop dashboard web service' },
          { id => 'start_web', label => 'Start dashboard web service' },
      ],
      stream  => \*STDERR,
      dynamic => 1,
      color   => 1,
  );
  my $callback = $progress->callback;
  $callback->( { task_id => 'stop_web', status => 'running' } );
  $callback->( { task_id => 'stop_web', status => 'done' } );
  $progress->finish;

=head1 DESCRIPTION

This module renders a simple terminal task board for long-running lifecycle
commands such as C<dashboard restart> and C<dashboard stop>.

=head1 METHODS

=head2 new, callback, update, finish, render, render_text

Construct and drive one progress board.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module turns runtime lifecycle events into a visible task list on the terminal so restart and stop do not leave the user staring at a blank prompt while the runtime waits through managed stability windows.

=head1 WHY IT EXISTS

It exists because the restart and stop flows intentionally wait for collectors and the web service to prove they stayed alive or shut down cleanly. Without a dedicated renderer that delay looks like a hang even when the runtime is behaving exactly as designed.

=head1 WHEN TO USE

Use this file when changing the terminal progress UX for lifecycle commands, when adding new restart or stop tasks that need to appear in the task list, or when adjusting how task boards redraw in interactive shells versus captured non-interactive runs.

=head1 HOW TO USE

Construct the object with a title and the full ordered task list before work begins, then pass the callback into the runtime lifecycle method. The runtime reports task-id and status updates, and this renderer prints the current state of the whole board to the configured stream.

=head1 WHAT USES IT

It is used by the private restart and stop CLI helpers so interactive terminal runs show visible progress while the runtime manager stops existing processes, starts configured collectors, and confirms the replacement web service.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::CLI::Progress -e '
    my $p = Developer::Dashboard::CLI::Progress->new(
      title => "demo",
      tasks => [ { id => "one", label => "First task" } ],
      dynamic => 0,
    );
    $p->update({ task_id => "one", status => "running" });
    $p->update({ task_id => "one", status => "done" });
  '

Render a non-interactive progress board and drive one task through running and done states.

Example 2:

  DEVELOPER_DASHBOARD_PROGRESS=1 dashboard restart

Force the restart helper to emit the task board even when stdout and stderr are being captured instead of attached to an interactive terminal.

Example 3:

  dashboard restart

Render the interactive lifecycle board with yellow running markers, green
C<[OK]> completion markers, and red C<[X]> failure markers when stderr is a
real terminal.

=cut
