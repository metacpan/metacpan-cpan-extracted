# (X)Emacs mode: -*- cperl -*-

package Log::Info::Fork;

=head1 NAME

Log::Info::Fork - a process that forks, and its output is captured and logged.

=head1 SYNOPSIS

Z<>

=head1 DESCRIPTION

Z<>

=cut

# ----------------------------------------------------------------------------

# Pragmas -----------------------------

require 5.005_62;
use strict;
use warnings;

# Inheritance -------------------------

use base qw( Exporter );
our (@EXPORT_OK);

BEGIN {
  @EXPORT_OK = qw( SRC_INFO );
}

# Utility -----------------------------

use B::Deparse         0.60 qw( );
use Carp                    qw( carp croak );
use Class::MethodMaker 1.02 qw( );
use Fatal              1.02 qw( :void close open seek sysopen );

use Log::Info qw( :default_channels :log_levels :DEFAULT
                  $PACKAGE $VERSION );

# ----------------------------------------------------------------------------

# CLASS METHODS --------------------------------------------------------------

# -------------------------------------
# CLASS CONSTANTS
# -------------------------------------

=head1 CLASS CONSTANTS

Z<>

=cut

# Buffer size used for fork reader
use constant BUFFER_SIZE        => 8192;

use constant SRC_INFO => ':info';

# -------------------------------------
# CLASS CONSTRUCTION
# -------------------------------------

# -------------------------------------
# CLASS COMPONENTS
# -------------------------------------

=head1 CLASS COMPONENTS

Z<>

=cut

# -------------------------------------
# CLASS HIGHER-LEVEL FUNCTIONS
# -------------------------------------

=head1 CLASS HIGHER-LEVEL FUNCTIONS

Z<>

=cut

=head2 fork_log

Fork, and log the output of the child.

=over 4

=item ARGUMENTS

=over 4

=item proc

What to execute in the child.  Either as an arrayref, being the name & args of
a process to execute, or as a coderef.

=item fhs

I<Optional>.  If defined, an arrayref of hashrefs, each having keys:

=over 4

=item fh

A filehandle object, or a (non-negative) integer specifying a file descriptor.

=item channel

I<Optional> The channel (name) to log to.  Defaults to C<CHAN_INFO>.

=item level

I<Optional> The level (name) to log at.  Defaults to C<LOG_INFO>.

=back

If not defined, defaults to logging stdout to CHAN_INFO at LOG_INFO, and
stderr to CHAN_INFO at LOG_WARNING.

=item log_opts

I<Optional>.

This value is actually a bitmask.  The recognized bits are:

=over 4

=item 1

Log the process start/end with name (see the C<name> argument).  This gets
logged to CHAN_INFO at LOG_INFO level.

=item 2

Log the process arguments (if a process passed), attempt to deparse code (if
code passwd).

=item 4

Log process results (as exit code if exec, or eval results if code).

=back

=item name

I<Optional> A name used for messages relating to this fork.

=item format

I<Optional> A coderef for formatting messages.  The ref is passed the
following arguments:

=over 4

=item channnel name

=item log level

=item source

filehandle name, or an C<SRC_> constant.

=item message

=back

The coderef is expected to return a string.

=back

=item RETURNS

=over 4

=item *

The exit status for an execd process (i.e., the value of C<$?>).

=back

=back

=cut

sub fork_log {
  my $class = shift;
  my ($proc, $fhs, $log_proc_start_stop, $name, $formatter) = @_;

  my %args = (proc => $proc);
  $args{fhs} = $fhs
    if defined $fhs;
  $args{name} = $name
    if defined $name;
  $args{format} = $formatter
    if defined $formatter;
  my $fork = $class->new(%args);

  if ( defined $log_proc_start_stop) {
    $fork->log_start_end(1)                 if $log_proc_start_stop & 1;
    $fork->log_args(1)                      if $log_proc_start_stop & 2;
    $fork->log_exit(1)                      if $log_proc_start_stop & 4;
  }

  $fork->fork;
  $fork->pump_all;
  return $fork->finalize;
}

# -------------------------------------
# CLASS HIGHER-LEVEL PROCEDURES
# -------------------------------------

=head1 CLASS HIGHER-LEVEL PROCEDURES

Z<>

=cut

# INSTANCE METHODS -----------------------------------------------------------

# -------------------------------------
# INSTANCE CONSTRUCTION
# -------------------------------------

=head1 INSTANCE CONSTRUCTION

Z<>

=cut

=head2 new

Create & return a new thing.

=cut

Class::MethodMaker->import (new_with_init => 'new',
                            new_hash_init => 'hash_init',);

sub init {
  my $self = shift;
  my %args = @_;

  my @fhs = ({fh      => *STDERR{IO}, name  => 'stderr', level => LOG_WARNING},
             {fh      => *STDOUT{IO}, name  => 'stdout',},);;

  if ( exists $args{fhs} ) {
    if ( defined $args{fhs} and @{$args{fhs}} ) {
      @fhs = @{$args{fhs}};
    }
    delete $args{fhs};
  }

  $self->format(sub{return $_[3]});

  {
    my $count = 0;
    for (@fhs) {
      $_->{name} = sprintf("*FH %03d*", $count++)
        unless exists $_->{name};
      $_->{channel} = CHAN_INFO
        unless exists $_->{channel};
      $_->{level}   = LOG_INFO
        unless exists $_->{level};

      $self->fhs_push($_);
    }
  }

  if ( UNIVERSAL::isa($args{proc}, 'ARRAY') ) {
    my @proc = @{$args{proc}}; # Form closure
    $args{name} = join ' ', @proc
      unless exists $args{name} and defined $args{name};
  } elsif ( ! UNIVERSAL::isa($args{proc}, 'CODE') ) {
    croak "Proc $args{proc} must be code or arrayref\n";
  }

  $args{name} = '*NO NAME*'
    unless exists $args{name} and defined $args{name};

  $self->hash_init (%args);
}

# -------------------------------------
# INSTANCE FINALIZATION
# -------------------------------------

# -------------------------------------
# INSTANCE COMPONENTS
# -------------------------------------

=head1 INSTANCE COMPONENTS

Z<>

=cut

Class::MethodMaker->import
  (
   get_set => [qw/ proc pid name /],
   boolean => [qw/ log_start_end log_args log_exit /],

   # fhs: list of hashrefs; keys:
   #   fh
   #   channel
   #   name
   #   level
   #   pipe
   #   linebuf
   list    => [qw/ fhs  /],
   code    => [qw/ format /],
  );


# -------------------------------------
# INSTANCE HIGHER-LEVEL FUNCTIONS
# -------------------------------------

=head1 INSTANCE HIGHER-LEVEL FUNCTIONS

Z<>

=cut

sub log {
  my $self = shift;
  my ($channel, $level, $source, @message) = @_;

  my $message;
  if ( @message > 1 ) {
    # It's the weirdest thing...
    # sprintf @message here seems to force @message into a scalar context!
    # even making the lhs a list context doesn't help.  Spook!
    $message = sprintf ($message[0], @message[1..$#message]);
  } elsif ( @message == 1 ) {
    $message = $message[0];
  } else {
    $message = sprintf "Empty log invoked at %s:%s", (caller)[0,1];
  }

  $message = $self->format($channel, $level, $source, $message);
  Log ($channel, $level, $message);
}

# -------------------------------------
# INSTANCE HIGHER-LEVEL PROCEDURES
# -------------------------------------

=head1 INSTANCE HIGHER-LEVEL PROCEDURES

Z<>

=cut

=head2 fork

Fork, passing any parameters to the procedure.

=cut

# -------------------------------------

sub fork {
  my $self = shift;

  $_->{pipe} = IO::Pipe->new
    for ($self->fhs);

  if ( $self->log_args ) {
    my $args = (UNIVERSAL::isa($self->proc, 'CODE')          ?
                B::Deparse->new()->coderef2text($self->proc) :
                join ' ', @{$self->proc});
    $args =~ tr/ \t\n/ /s;
    $self->log(CHAN_INFO, LOG_INFO+1, SRC_INFO,
               "Process Args: %s: %s", $self->name, $args);
  }

  if ( $self->log_start_end ) {
    $self->log(CHAN_INFO, LOG_INFO, SRC_INFO,
               "Starting process: %s", $self->name);
  }

  my $pid = fork;
  croak "Couldn't fork: $!\n"
    unless defined $pid;

  unless ( $pid ) {
    # Child
    $_->{pipe}->writer
      for ($self->fhs);

    my $proc = $self->proc;
    if ( UNIVERSAL::isa($proc, 'ARRAY') ) {
      my @proc = @$proc; # Form closure
      $proc = sub { exec @proc }
    }

    for (grep ! ref $_->{fh}, $self->fhs) {
      open my $fh, '>&=' . $_->{fh};
      $_->{fh} = $fh;
    }

    # Set process group for potential infanticide
    setpgrp;

    open($_->{fh}, '>&' . $_->{pipe}->fileno), $_->{fh}->autoflush
      for $self->fhs;

    eval {
      $proc->(@_);
    }; if ($@) {
      die sprintf "Code %s to fork died: $@\n", $self->name;
    }
    exit 0;
  }

  # Parent
  $_->{pipe}->reader
    for ($self->fhs);

  $self->pid($pid);
}

# -------------------------------------

sub pump_all {
  my $self = shift;

  my $selector = IO::Select->new;
  $selector->add($_->{pipe}), $_->{linebuf} = ''
    for $self->fhs;

  my ($readcount, @lines);
  my ($outname, $bufr);

  while ( $selector->count ) {
    # Block waiting for read.
    my @can_read = $selector->can_read;

    foreach my $fh (@can_read) {
      my $fh_info;
    FH:
      for ($self->fhs) {
        if ( $_->{pipe} == $fh ) {
          $fh_info = $_;
          last FH;
        }
      }

      croak "Whoa!  Where did this FH come from? $fh\n"
        unless defined $fh_info;

      $outname = $fh_info->{name};
      $bufr = \$fh_info->{linebuf};

      $readcount = $fh->sysread ($$bufr, BUFFER_SIZE, length $$bufr);
      if ( $readcount ) {
        @lines = grep $_ ne '', split /(.*\n)/, $$bufr;
        if ( substr ($lines[-1], -1) ne "\n" ) {
          $$bufr = splice @lines, -1;
        } else {
          $$bufr = '';
        }

        $self->log($fh_info->{channel}, $fh_info->{level}, $fh_info->{name},
                   $_)
          for map { chomp; $_ } @lines;
      } else {

        $self->log($fh_info->{channel}, $fh_info->{level}, $fh_info->{name},
                   $$bufr)
          if length($$bufr);
        $selector->remove ($fh);
      }
    }
  }
}

# -------------------------------------

sub finalize {
  my $self = shift;

  my $err = waitpid $self->pid, 0;
  my $status = $?;

  if ( $err = $self->pid ) {
    $self->log(CHAN_INFO, LOG_INFO, SRC_INFO,
               "Process exited: %s: Exit/Core/Sig: %d/%d/%d",
               $self->name, $status >> 8, $status & 127, $status & 128)
      if $self->log_exit;
  } else {
    $self->log(CHAN_INFO, LOG_INFO, SRC_INFO,
               "Failed to collect process: %s", $self->name)
      if $self->log_exit;
    $self->log(CHAN_INFO, LOG_WARNING, SRC_INFO,
               "Failed to collect process: %s", $self->name);
  }

  if ( $self->log_start_end ) {
    $self->log(CHAN_INFO, LOG_INFO, SRC_INFO,
               "Finishing process: %s", $self->name);
  }

  return $status;
}

# ----------------------------------------------------------------------------

=head1 EXAMPLES

Z<>

=head1 BUGS

Z<>

=head1 REPORTING BUGS

Email the author.

=head1 AUTHOR

Martyn J. Pearce C<fluffy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2003 Martyn J. Pearce.  This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Z<>

=cut

1; # keep require happy.

__END__
