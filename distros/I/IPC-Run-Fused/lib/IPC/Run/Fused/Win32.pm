use 5.008003;
use strict;
use warnings;

package IPC::Run::Fused::Win32;

our $VERSION = '1.000001';

# ABSTRACT: Implementation of IPC::Run::Fused for Win32

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use IO::Handle;
use Module::Runtime;


























use IPC::Run::Fused qw(_fail);
use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC );

use Exporter qw(import);
our @EXPORT_OK = qw( run_fused );

sub run_fused {
  my ( undef, @params ) = @_;
  if ( ref $params[0] and 'CODE' eq ref $params[0] ) {
    goto \&_run_fused_coderef;
  }
  goto \&_run_fused_job;
}

sub _run_fused_job {    ## no critic (Subroutines::RequireArgUnpacking)
  my ( $read_handle, @params ) = ( \shift @_, @_ );

  my $config = _run_fused_jobdecode(@params);

  Module::Runtime::require_module('File::Which');

  $config->{which} = File::Which::which( $config->{executable} );

  local $IPC::Run::Fused::FAIL_CONTEXT{which}      = $config->{which};
  local $IPC::Run::Fused::FAIL_CONTEXT{executable} = $config->{executable};
  local $IPC::Run::Fused::FAIL_CONTEXT{command}    = $config->{command};

  if ( not $config->{which} ) {
    _fail('Failed to resolve executable to path');
  }

  Module::Runtime::require_module('Win32::Job');

  pipe ${$read_handle}, my $writer;

  if ( my $pid = fork ) {
    return $pid;
  }

  my $job = Win32::Job->new();
  $job->spawn(
    $config->{which},
    $config->{command},
    {
      stdout => $writer,
      stderr => $writer,
    },
  ) or _fail('Could not spawn job');
  my $result = $job->run( -1, 0 );
  if ( not $result ) {
    my $status = $job->status();
    if ( exists $status->{exitcode} and 293 == $status->{exitcode} ) {
      _fail('Process used more than allotted time');
    }
    _fail( 'Child process terminated with exit code' . $status->{exitcode} );
  }
  exit;
}

sub _run_fused_jobdecode {
  my (@params) = @_;

  if ( ref $params[0] and 'SCALAR' eq ref $params[0] ) {
    my $command = ${ $params[0] };
    $command =~ s/\A\s*//msx;
    return {
      command    => $command,
      executable => _win32_command_find_invocant($command),
    };
  }
  return {
    executable => $params[0],
    command    => _win32_escape_command(@params),
  };
}

sub _run_fused_coderef {    ## no critic (Subroutines::RequireArgUnpacking)
  my ( $read_handle, $code ) = ( \shift @_, @_ );
  my ( $reader, $writer );

  socketpair $reader, $writer, AF_UNIX, SOCK_STREAM, PF_UNSPEC or _fail('creating socketpair');
  shutdown $reader, 1 or _fail('Cant close write to reader');
  shutdown $writer, 0 or _fail('Cant close read to writer');

  if ( my $pid = fork ) {
    ${$read_handle} = $reader;
    return $pid;
  }

  close *STDERR or _fail('Closing STDERR');
  close *STDOUT or _fail('Closing STDOUT');
  open *STDOUT, '>>&=', $writer or _fail('Assigning to STDOUT');
  open *STDERR, '>>&=', $writer or _fail('Assigning to STDERR');
  $code->();
  exit;

}

our $BACKSLASH         = chr 92;
our $DBLBACKSLASH      = $BACKSLASH x 2;
our $DOS_SPECIAL_CHARS = {
  chr 92 => [ 'backslash ',    $BACKSLASH x 2 ],
  chr 34 => [ 'double-quotes', $BACKSLASH . chr 34 ],

  #chr(60) => ['open angle bracket', $backslash . chr(60)],
  #chr(62) => ['close angle bracket', $backslash . chr(62)],
};
our $DOS_REV_CHARS = {
  map { ( $DOS_SPECIAL_CHARS->{$_}->[1], [ $DOS_SPECIAL_CHARS->{$_}->[0], $_ ] ) }
    keys %{$DOS_SPECIAL_CHARS},
};

sub _win32_escape_command_char {
  my ($char) = @_;
  return $char unless exists $DOS_SPECIAL_CHARS->{$char};
  return $DOS_SPECIAL_CHARS->{$char}->[1];
}

sub _win32_escape_command_token {
  ## no critic (RegularExpressions)
  my $chars = join q{}, map { _win32_escape_command_char($_) } split //, shift;
  return qq{"$chars"};
}

sub _win32_escape_command {
  my (@tokens) = @_;
  return join q{ }, map { _win32_escape_command_token($_) } @tokens;
}

sub _win32_command_find_invocant {
  my ($command) = @_;
  $command = "$command";
  my $first = q[];
  ## no critic (RegularExpressions)
  my @chars = split //, $command;
  my $inquote;

  while (@chars) {
    my $char  = $chars[0];
    my $dchar = $chars[0] . $chars[1];

    if ( not $inquote and q["] eq $char ) {
      $inquote = 1;
      shift @chars;
      next;
    }
    if ( $inquote and q["] eq $char ) {
      $inquote = undef;
      shift @chars;
      next;
    }
    if ( exists $DOS_REV_CHARS->{$dchar} ) {
      $first .= $DOS_REV_CHARS->{$dchar}->[1];
      shift @chars;
      shift @chars;
      next;
    }
    if ( q[ ] eq $char and not $inquote ) {
      if ( not length $first ) {
        shift @chars;
        next;
      }
      return $first;
    }
    if ( q[ ] eq $char and $inquote ) {
      $first .= $char;
      shift @chars;
      next;
    }
    $first .= $char;
    shift @chars;
  }
  if ($inquote) {
    _fail('Could not parse command from commandline');
  }
  return $first;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Run::Fused::Win32 - Implementation of IPC::Run::Fused for Win32

=head1 VERSION

version 1.000001

=head1 METHODS

=head2 run_fused

  run_fused( $fh, $executable, @params ) || die "$@";
  run_fused( $fh, \$command_string )     || die "$@";
  run_fused( $fh, sub { .. } )           || die "$@";

  # Recommended

  run_fused( my $fh, $executable, @params ) || die "$@";

  # Somewhat supported

  run_fused( my $fh, \$command_string ) || die "$@";

$fh will be clobbered like 'open' does, and $cmd, @args will be passed, as-is, through to exec() or system().

$fh will point to an IO::Handle attached to the end of a pipe running back to the called application.

the command will be run in a fork, and C<STDERR> and C<STDOUT> "fused" into a singular pipe.

B<NOTE:> at present, C<STDIN>'s FD is left unchanged, and child processes will inherit parent C<STDIN>'s, and will thus block
( somewhere ) waiting for response.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
