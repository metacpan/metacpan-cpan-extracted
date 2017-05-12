package Log::Structured;
{
  $Log::Structured::VERSION = '0.001003';
}

# ABSTRACT: Log events in a structured manner

use Moo;
use Sub::Quote;

use Time::HiRes qw(gettimeofday tv_interval);

has log_event_listeners => (
  is => 'ro',
  isa => quote_sub(q<
    die "log_event_listeners must be an arrayref!"
      unless ref $_[0] && ref $_[0] eq 'ARRAY';

    for (@{$_[0]}) {
      die "each log_event_listener must be a coderef!"
        unless ref $_ && ref $_ eq 'CODE';
    }
  >),
  default => quote_sub q{ [] },
);

has $_ => ( is => 'rw' ) for qw(
   caller_clan category priority start_time last_event
);

has caller_depth => (
   is => 'rw',
   predicate => 'has_caller_depth',
);

has "log_$_" => ( is => 'rw' ) for qw(
  milliseconds_since_start milliseconds_since_last_log
  line file package subroutine category priority
  date host pid stacktrace
);

sub add_log_event_listener {
  my $self = shift;
  my $code = shift;

  die 'log_event_listener must be a coderef!'
    unless ref $code && ref $code eq 'CODE';

   push @{$self->log_event_listeners}, $code
}

sub BUILD {
   $_[0]->start_time([gettimeofday]);
   $_[0]->last_event([gettimeofday]);
}

sub log_event {
   my $self = shift;
   my $event_data = shift;

   $self->${\"log_$_"} and $event_data->{$_} ||= $self->$_ for qw(
      milliseconds_since_start milliseconds_since_last_log
      line file package subroutine category priority
      date host pid stacktrace
   );

   $self->$_($event_data) for @{$self->log_event_listeners};

   $self->last_event([gettimeofday]);
}

sub milliseconds_since_start {
   int tv_interval(shift->start_time, [ gettimeofday ]) * 1000
}

sub milliseconds_since_last_log {
   int tv_interval(shift->last_event, [ gettimeofday ]) * 1000
}

sub line { shift->_caller->[2] }

sub file { shift->_caller->[1] }

sub package { shift->_caller->[0] }

sub subroutine { shift->_caller->[3] }

sub _caller {
  my $self = shift;

  $self->_sound_depth->[1]
}

sub date { return [localtime] }

sub host {
  require Sys::Hostname;
  return Sys::Hostname::hostname()
}

sub pid { $$ }

sub stacktrace {
  my $self = shift;

  my @trace;
  my $i = 1;
  while (my @callerinfo = caller($i)) {
    $i++;
    push @trace, \@callerinfo
  }
  \@trace
}

sub _sound_depth {
  my $self = shift;

  my $depth = $self->has_caller_depth ? $self->caller_depth : 0;
  my $clan  = $self->caller_clan;

  $depth += 3;

  if (defined $clan) {
    my $c; do {
      $c = caller ++$depth;
    } while $c && $c =~ $clan;
    return [$depth, [caller $depth]]
  } else {
    return [$depth, [caller $depth]]
  }
}

1;

__END__

=pod

=head1 NAME

Log::Structured - Log events in a structured manner

=head1 VERSION

version 0.001003

=head1 SYNOPSIS

 use Log::Structured;

 my $structured_log = Log::Structured->new({
   category            => 'Web Server',
   log_category        => 1,
   priority            => 'trace',
   log_priority        => 1,
   log_file            => 1,
   log_line            => 1,
   log_date            => 1,
   log_event_listeners => [sub {
      my ($self, $e) = @_;
      my @date = @{$e->{date}};

      my $ymd_hms  = "$date[5]-$date[4]-$date[3] $date[2]:$date[1]:$date[0]";
      my $location = "$e->{file}:$e->{line}";
      warn "[$ymd_hms][$location][$e->{priority}][$e->{category}] $e->{message}"
   }, sub {
      open my $fh, '>>', 'log';
      print {$fh} encode_json($_[1]) . "\n";
   }],
 });

 $structured_log->log_event({ message => 'Starting web server' });

 $structured_log->log_event({
   message => 'Oh no!  The database melted!',
   priority => 'fatal',
   category => 'Core',
 });

=head1 DESCRIPTION

This module is meant to produce logging data flexibly and powerfully.  All of
the data that it produces can easilly be serialized or put into a database or
printed on the top of a cake or whatever else you may want to do with it.

=head1 ATTRIBUTES

=head2 log_event_listeners

C<ArrayRef[CodeRef]>, coderefs get called in order, as methods, with log events
as an argument

=head2 caller_clan

A stringified regex matching packages to use when getting any caller
information (including stacktrace.)  Typically this will be used to B<exclude>
things from the caller information.  So to exclue L<DBIx::Class> and
L<SQL::Abstract> from your caller information:

 caller_clan => '^DBIx::Class|^SQL::Abstract',

=head2 category

String representing the category of the log event

=head2 priority

String representing the priority of the log event.  Should be debug, trace,
info, warn, error, or fatal.

=head2 start_time

Returns an C<ArrayRef> containing the time the object was instantiated

=head2 last_event

Returns an C<ArrayRef>h containing the last time a log event occurred

=head2 caller_depth

An integer caller levels to skip when getting any caller information (not
including stacktrace.)

=head1 ATTRIBUTES TO ENABLE LOG DATA

All of the following attributes will enable their respective data in the log
event:

=over 1

=item * log_milliseconds_since_start

=item * log_milliseconds_since_last_log

=item * log_line

=item * log_file

=item * log_package

=item * log_subroutine

=item * log_category

=item * log_priority

=item * log_date

=item * log_host

=item * log_pid

=item * log_stacktrace

=back

=head1 METHODS

=head2 add_log_event_listener

Takes a coderef to be added to the L</log_event_listeners>

=head2 log_event

Takes a hashref of the data to be passed to the event listeners.  All of the
data except for C<message>, C<category>, and C<priority> will be automatically
populated by the methods below, unless they are passed in.

=head2 milliseconds_since_start

Returns milliseconds since object has been instantiated

=head2 milliseconds_since_last_log

Returns milliseconds since previous log event

=head2 line

Returns the line at the correct depth

=head2 file

Returns the file at the correct depth

=head2 package

Returns the package at the correct depth

=head2 subroutine

Returns the subroutine at the correct depth

=head2 date

Returns an arrayref containing the results from C<localtime>

=head2 host

Returns the host of the machine being logged on

=head2 pid

Returns the pid of the process being logged

=head2 stacktrace

Returns the a stacktrace ending at the correct depth.  The stacktrace is an
arrayref of arrayrefs, where the inner arrayrefs match the return values of
caller in list context

=head1 SEE ALSO

During initial development all the code from this module was part of
L<Log::Sprintf>.  This module continues to work with C<Log::Sprintf>.
For example the L</SYNOPSIS>' example of instantiation could be rewritten as:

 use Log::Structured;
 use Log::Sprintf;

 my $formatter = Log::Sprintf->new({ format => "[%d][%F:%L][%p][%c] %m" });

 my $structured_log = Log::Structured->new({
   category            => 'Web Server',
   log_category        => 1,
   priority            => 'trace',
   log_priority        => 1,
   log_file            => 1,
   log_line            => 1,
   log_date            => 1,
   log_event_listeners => [sub {
      warn $formatter->sprintf($_[1])
   }, sub {
      open my $fh, '>>', 'log';
      print {$fh} encode_json($_[1]) . "\n";
   }],
 });

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
