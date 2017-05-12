package Log::Saftpresse::Input::Command::Child;

use Moose;

# ABSTRACT: process control for child processes of Command input
our $VERSION = '1.6'; # VERSION

use IO::File;

has 'pid' => ( is => 'rw', isa => 'Maybe[Int]' );

has 'stdout' => ( is => 'rw' );
has 'stderr' => ( is => 'rw' );

has 'command' => ( is => 'ro', isa => 'Str', required => 1 );

has 'blocking' => ( is => 'ro', isa => 'Bool', default => 1 );

sub _setup_pipe {
  my $reader = IO::File->new;
  my $writer = IO::File->new;
  pipe( $reader, $writer)
    or die "failed creating pipe: $!";
  return $reader, $writer;
}

sub start {
  my ( $self ) = @_;
  if( $self->pid ) {
    die "child is already running";
  }

  my ( $parent_out, $child_out) = _setup_pipe;
  my ( $parent_err, $child_err) = _setup_pipe;
  my $pid;

  eval {
    $pid = fork(); 1;
  } or do {
    my $error = $@ ne '' ? $@ : "errno=$!";
    die "error forking child: $error";
  };
  defined $pid or die "cant fork child command: $!";
  if( ! $pid )  {
    # child
    eval {
      alarm(0);
      $parent_out->close;
      $parent_err->close;

      open( STDIN, '<', '/dev/null' )
        or die "cant reopen STDOUT of child: $!";
      open( STDOUT, '>&', $child_out )
        or die "cant reopen STDOUT of child: $!";
      open( STDERR, '>&', $child_err )
        or die "cant reopen STDERR of child: $!";

      my $cmd = $self->command;
      exec $cmd or die "cant exec $cmd: $!";
    };
    exit 1;
  }
  # parent
  $child_out->close();
  $child_err->close();
  $self->pid( $pid );
  $parent_out->blocking( $self->blocking );
  $parent_err->blocking( $self->blocking );
  $self->stdout( $parent_out );
  $self->stderr( $parent_err );

  return;
}

sub _is_pid_alive {
  my $self = shift;
  return  kill(0, $self->pid);
}

sub stop {
  my $self = shift;

  if( ! defined $self->pid ) {
    return;
  }

  if( $self->_is_pid_alive ) {
    kill( 'TERM', $self->pid);
    waitpid( $self->pid, 0 );
  }

  if( $self->pid ) {
    $self->pid( undef );
    $self->stdout->close;
    $self->stderr->close;
  }

  return;
}

sub DESTROY {
  my $self = shift;
  $self->stop;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Input::Command::Child - process control for child processes of Command input

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
