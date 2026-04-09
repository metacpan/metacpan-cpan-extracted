package Developer::Dashboard::CLI::Ticket;

use strict;
use warnings;

our $VERSION = '2.02';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use Exporter 'import';

our @EXPORT_OK = qw(
  build_ticket_plan
  resolve_ticket_request
  run_ticket_command
  session_exists
  ticket_environment
  tmux_command
);

# resolve_ticket_request(%args)
# Resolves the target ticket reference from argv or the current environment.
# Input: args array reference and optional env_ticket scalar.
# Output: non-empty ticket/session name string or dies when none is available.
sub resolve_ticket_request {
    my (%args) = @_;
    my $argv = $args{args} || [];
    die 'Ticket args must be an array reference' if ref($argv) ne 'ARRAY';

    my $ticket = $argv->[0];
    $ticket = $args{env_ticket} if !defined $ticket || $ticket eq '';
    die "Please specify a ticket name\n" if !defined $ticket || $ticket eq '';
    return $ticket;
}

# ticket_environment($ticket)
# Builds the tmux environment values that travel with one ticket session.
# Input: non-empty ticket/session name string.
# Output: hash reference of tmux environment variable names and values.
sub ticket_environment {
    my ($ticket) = @_;
    die "Ticket name is required\n" if !defined $ticket || $ticket eq '';
    return {
        TICKET_REF => $ticket,
        B          => $ticket,
        OB         => "origin/$ticket",
    };
}

# tmux_command(%args)
# Runs one tmux command and captures stdout, stderr, and exit status.
# Input: args array reference for tmux.
# Output: hash reference with stdout, stderr, and exit_code keys.
sub tmux_command {
    my (%args) = @_;
    my $argv = $args{args} || [];
    die 'tmux args must be an array reference' if ref($argv) ne 'ARRAY';

    my ( $stdout, $stderr, $exit_code ) = capture {
        system 'tmux', @{$argv};
        return $? >> 8;
    };

    return {
        stdout    => $stdout,
        stderr    => $stderr,
        exit_code => $exit_code,
    };
}

# session_exists(%args)
# Checks whether the requested tmux session already exists.
# Input: session name and optional tmux runner coderef.
# Output: 1 when the session exists, 0 when it does not, or dies on tmux errors.
sub session_exists {
    my (%args) = @_;
    my $session = $args{session} || die 'Missing session name';
    my $tmux = $args{tmux} || \&tmux_command;
    my $result = $tmux->(
        args => [ 'has-session', '-t', $session ],
    );

    return 1 if $result->{exit_code} == 0;
    return 0 if $result->{exit_code} == 1;
    die sprintf "Unable to inspect tmux session '%s': %s%s",
      $session,
      ( $result->{stderr} || '' ),
      ( $result->{stdout} || '' );
}

# build_ticket_plan(%args)
# Builds the tmux create/attach plan for one ticket session request.
# Input: args array reference, optional cwd/env_ticket values, and optional tmux runner coderef.
# Output: hash reference describing the session, cwd, environment, and tmux argv lists.
sub build_ticket_plan {
    my (%args) = @_;
    my $ticket = resolve_ticket_request(
        args       => $args{args} || [],
        env_ticket => $args{env_ticket},
    );
    my $plan_cwd = $args{cwd};
    $plan_cwd = cwd() if !defined $plan_cwd || $plan_cwd eq '';

    my $env = ticket_environment($ticket);
    my $exists = session_exists(
        session => $ticket,
        tmux    => $args{tmux},
    );

    my @env_args;
    for my $name ( sort keys %{$env} ) {
        push @env_args, '-e', "$name=$env->{$name}";
    }

    return {
        session     => $ticket,
        cwd         => $plan_cwd,
        env         => $env,
        exists      => $exists,
        create      => $exists ? 0 : 1,
        create_argv => [
            'new-session',
            '-d',
            @env_args,
            '-c', $plan_cwd,
            '-s', $ticket,
            '-n', 'Code1',
        ],
        attach_argv => [
            'attach-session',
            '-t', $ticket,
        ],
    };
}

# run_ticket_command(%args)
# Creates a tmux ticket session when needed and attaches to it.
# Input: args array reference plus optional cwd/env_ticket values and optional tmux runner coderef.
# Output: plan hash reference after successful tmux create/attach operations.
sub run_ticket_command {
    my (%args) = @_;
    my $tmux = $args{tmux} || \&tmux_command;
    my $plan = build_ticket_plan(
        %args,
        tmux => $tmux,
    );

    if ( $plan->{create} ) {
        my $created = $tmux->( args => $plan->{create_argv} );
        die sprintf "Unable to create tmux ticket session '%s': %s%s",
          $plan->{session},
          ( $created->{stderr} || '' ),
          ( $created->{stdout} || '' )
          if $created->{exit_code} != 0;
    }

    my $attached = $tmux->( args => $plan->{attach_argv} );
    die sprintf "Unable to attach tmux ticket session '%s': %s%s",
      $plan->{session},
      ( $attached->{stderr} || '' ),
      ( $attached->{stdout} || '' )
      if $attached->{exit_code} != 0;

    return $plan;
}

1;

__END__

=head1 NAME

Developer::Dashboard::CLI::Ticket - private tmux ticket helper for Developer Dashboard

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Ticket qw(run_ticket_command);
  run_ticket_command( args => \@ARGV );

=head1 DESCRIPTION

Provides the shared implementation behind the private C<ticket> helper staged
under F<~/.developer-dashboard/cli/dd/> so C<dashboard ticket> can stay part of
the dashboard toolchain without installing a public top-level executable.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Perl module in the Developer Dashboard codebase. This file builds and opens configured ticket URLs from dashboard settings.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::CLI::Ticket> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::CLI::Ticket -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
