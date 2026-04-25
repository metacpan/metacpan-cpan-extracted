package MCP::Run::Bash;
our $VERSION = '0.004';
use Mojo::Base 'MCP::Run', -signatures;

# ABSTRACT: MCP server that executes commands via bash


use IPC::Open3;
use IO::Select;
use Symbol 'gensym';
use POSIX   ':sys_wait_h';

sub execute ($self, $command, $working_directory, $timeout) {
  my $full_command = $command;
  if (defined $working_directory && length $working_directory) {
    my $escaped = $working_directory;
    $escaped =~ s/'/'\\''/g;
    $full_command = "cd '$escaped' && $command";
  }

  my ($stdout, $stderr) = ('', '');
  my ($exit_code, $error);

  eval {
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, 'bash', '-c', $full_command);
    close $in;

    my $select = IO::Select->new($out, $err);
    my $timed_out = 0;

    local $SIG{ALRM} = sub { $timed_out = 1; die "alarm\n" };
    alarm($timeout);

    eval {
      while (my @ready = $select->can_read) {
        for my $fh (@ready) {
          my $buf;
          my $bytes = sysread($fh, $buf, 4096);
          if (!$bytes) {
            $select->remove($fh);
            next;
          }
          if ($fh == $out) { $stdout .= $buf }
          else             { $stderr .= $buf }
        }
      }
    };

    alarm(0);

    if ($timed_out) {
      kill 'TERM', $pid;
      waitpid($pid, 0);
      $exit_code = 124;
      $error     = "Command timed out after ${timeout}s";
    }
    else {
      waitpid($pid, 0);
      $exit_code = $? >> 8;
    }

    close $out;
    close $err;
  };

  if ($@ && !defined $exit_code) {
    $exit_code = 1;
    $error     = "$@";
    chomp $error;
  }

  chomp $stdout;
  chomp $stderr;

  return { exit_code => $exit_code, stdout => $stdout, stderr => $stderr, (defined $error ? (error => $error) : ()) };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Run::Bash - MCP server that executes commands via bash

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use MCP::Run::Bash;

    my $server = MCP::Run::Bash->new(
        allowed_commands  => ['ls', 'cat', 'grep'],
        working_directory => '/var/data',
        timeout           => 30,
    );
    $server->run;

=head1 DESCRIPTION

Concrete L<MCP::Run> subclass that executes commands by invoking
C<bash -c $command> via L<IPC::Open3>. Captures stdout and stderr separately,
enforces a per-command timeout using C<alarm>, and returns the exit code.

When a C<working_directory> is specified (either as a server default or
passed per-invocation), it is prepended to the command as
C<cd '$dir' && $command> before being handed to bash.

On timeout the child process is sent C<SIGTERM> and the exit code is set to
C<124> (matching the convention used by GNU C<timeout(1)>).

=head2 execute

    my $result = $self->execute($command, $working_directory, $timeout);

Implements L<MCP::Run/execute>. Runs C<$command> under C<bash -c>,
capturing stdout and stderr via L<IPC::Open3> and L<IO::Select>. If
C<$working_directory> is defined, prepends C<cd '$working_directory' &&> to
the command.

The timeout is enforced with C<alarm>. On expiry, C<SIGTERM> is sent to the
child process and the exit code is set to C<124>.

Returns a hashref with keys C<exit_code>, C<stdout>, C<stderr>, and
optionally C<error>.

=head1 SEE ALSO

=over

=item * L<MCP::Run> - Base class defining the C<run> MCP tool

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-mcp-run/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
