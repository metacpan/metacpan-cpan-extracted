use strict;
use warnings;
package Device::CurrentCost;
$Device::CurrentCost::VERSION = '1.142240';
# ABSTRACT: Perl modules for Current Cost energy monitors


use constant DEBUG => $ENV{DEVICE_CURRENT_COST_DEBUG};

use Carp qw/croak carp/;
use Device::CurrentCost::Constants;
use Device::CurrentCost::Message;
use Device::SerialPort qw/:PARAM :STAT 0.07/;
use Fcntl;
use IO::Handle;
use IO::Select;
use Symbol qw(gensym);
use Time::HiRes;


sub new {
  my ($pkg, %p) = @_;
  my $self = bless {
                    buf => '',
                    discard_timeout => 1,
                    type => CURRENT_COST_ENVY,
                    history_callback => sub {},
                    %p
                   }, $pkg;
  croak $pkg.q{->new: 'device' parameter is required}
    unless (exists $p{device} or exists $p{filehandle});
  $self->open();
  $self;
}


sub device { shift->{device} }


sub type { shift->{type} }


sub baud {
  my $self = shift;
  defined $self->{baud} ? $self->{baud} :
    $self->type == CURRENT_COST_CLASSIC ? 9600 : 57600;
}


sub filehandle { shift->{filehandle} }


sub serial_port { shift->{serial_port} }


sub open {
  my $self = shift;

  my $fh = $self->filehandle;
  unless ($fh) {
    my $dev = $self->device;
    print STDERR 'Opening serial port: ', $dev, "\n" if DEBUG;
    my $fh = gensym();
    my $s = tie *$fh, 'Device::SerialPort', $dev or
      croak "Could not tie serial port, $dev, to file handle: $!";
    foreach my $setting ([ baudrate => $self->baud ],
                         [ databits => 8 ],
                         [ parity => 'none' ],
                         [ stopbits => 1 ],
                         [ datatype => 'raw' ]) {
      my ($setter, @v) = @$setting;
      $s->$setter(@v);
    }
    $s->write_settings();
    sysopen($fh, $dev, O_RDWR|O_NOCTTY|O_NDELAY) or
      croak "sysopen of '$dev' failed: $!";
    $self->{serial_port} = $s;
    $self->{filehandle} = $fh;
  }
  $self->filehandle;
}


sub read {
  my ($self, $timeout) = @_;
  my $res = $self->read_one(\$self->{buf});
  return $res if (defined $res);
  $self->_discard_buffer_check();
  my $fh = $self->filehandle;
  my $sel = IO::Select->new($fh);
  do {
    my $start = $self->_time_now;
    $sel->can_read($timeout) or return;
    my $bytes = sysread $fh, $self->{buf}, 2048, length $self->{buf};
    $self->{_last_read} = $self->_time_now;
    $timeout -= $self->{_last_read} - $start if (defined $timeout);
    unless ($bytes) {
      croak((ref $self).'->read: '.(defined $bytes ? 'closed' : 'error: '.$!));
    }
    print STDERR 'Read ', $bytes, "bytes\n" if DEBUG;
    $res = $self->read_one(\$self->{buf});
    return $res if (defined $res);
  } while (1);
}


sub read_one {
  my ($self, $rbuf) = @_;
  return unless ($$rbuf);
  print STDERR 'Read one from !', $$rbuf, "!\n" if DEBUG;
  if ($$rbuf =~ s!^.*?(<msg>.*?</msg>)[\r\n ]*!!s) {
    my $msg = Device::CurrentCost::Message->new(message => $1);
    my $t = $self->_time_now;
    if ($msg->has_history) {
      my $new = $msg->history;
      my $our= $self->{history} || ($self->{history} = {});
      foreach my $sensor (sort keys %$new) {
        foreach my $interval (sort keys %{$new->{$sensor}}) {
          foreach my $age (keys %{$new->{$sensor}->{$interval}}) {
            $our->{$sensor}->{$interval}->{pending}->{$age} =
              0+$new->{$sensor}->{$interval}->{$age};
          }
          if (exists $our->{$sensor}->{$interval}->{pending}->{1} ||
              ($interval eq 'hours' &&
               (exists $our->{$sensor}->{$interval}->{pending}->{4} ||
                exists $our->{$sensor}->{$interval}->{pending}->{2}))) {
            my $entries = keys %{$our->{$sensor}->{$interval}->{pending}};
            if ($entries == { years => 4, months => 21, # envy
                              days => 90, hours => 372 }->{$interval} ||
                $entries == { years => 4, months => 12, # classic
                              days => 31, hours => 13 }->{$interval}) {
              %{$our->{$sensor}->{$interval}->{current}} =
                %{$our->{$sensor}->{$interval}->{pending}};
              $our->{$sensor}->{$interval}->{time} = $t;
              $self->{history_callback}->($sensor, $interval,
                   $our->{$sensor}->{$interval}->{current});
            }
            $our->{$sensor}->{$interval}->{pending} = {};
          }
        }
      }
    }
    return $msg;
  } else {
    return;
  }
}


sub sensor_history {
  my ($self, $sensor, $interval) = @_;
  return unless (exists $self->{history}->{$sensor}->{$interval}->{current});
  return {
          time => $self->{history}->{$sensor}->{$interval}->{time},
          data => $self->{history}->{$sensor}->{$interval}->{current}
         };
}

sub _discard_buffer_check {
  my $self = shift;
  if ($self->{buf} ne '' &&
      $self->{_last_read} < ($self->_time_now - $self->{discard_timeout})) {
    carp "Discarding '", $self->{buf}, "'";
    $self->{buf} = '';
  }
}

sub _time_now {
  Time::HiRes::time;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::CurrentCost - Perl modules for Current Cost energy monitors

=head1 VERSION

version 1.142240

=head1 SYNOPSIS

  use Device::CurrentCost;
  my $envy = Device::CurrentCost->new(device => '/dev/ttyUSB0');

  $|=1; # don't buffer output

  while (1) {
    my $msg = $envy->read() or next;
    print $msg->summary, "\n";
  }

  use Device::CurrentCost::Constants;
  my $classic = Device::CurrentCost->new(device => '/dev/ttyUSB1',
                                         type => CURRENT_COST_CLASSIC);
  # ...

  open my $cclog, '<', 'currentcost.log' or die $!;
  my $cc = Device::CurrentCost->new(filehandle => $cclog);

  while (1) {
    my $msg = $cc->read() or next;
    print $msg->summary, "\n";
  }

=head1 DESCRIPTION

Module for reading from Current Cost energy meters.

B<IMPORTANT:> This is an early release and the API is still subject to
change.

The API for history is definitely not complete.  This will change soon
and an mechanism for aggregating the history (which is split across
many messages) should be added.

=head1 METHODS

=head2 C<new(%parameters)>

This constructor returns a new Current Cost device object.  The
supported parameters are:

=over

=item device

The name of the device to connect to.  The value should be a tty
device name, e.g. C</dev/ttyUSB0> but a pipe or plain file should also
work.  This parameter is mandatory if B<filehandle> is not given.

=item filehandle

A filehandle to read from.  This parameter is mandatory if B<device> is
not given.

=item type

The type of the device.  Currently either C<CURRENT_COST_CLASSIC> or
C<CURRENT_COST_ENVY>.  The default is C<CURRENT_COST_ENVY>.

=item baud

The baud rate for the device.  The default is derived from the type and
is either C<57600> (for Envy) or C<9600> (for classic).

=item history_callback

A function, taking a sensor id, a time interval and a hash reference
of data as arguments, to be called every time a new complete set of
history data becomes available.  The data hash reference has keys of
the number of intervals ago and values of the reading at that time.

=back

=head2 C<device()>

Returns the path to the device.

=head2 C<type()>

Returns the type of the device.

=head2 C<baud()>

Returns the baud rate.

=head2 C<filehandle()>

Returns the filehandle being used to read from the device.

=head2 C<serial_port()>

Returns the Device::SerialPort object for the device.

=head2 C<open()>

This method opens the serial port and configures it.

=head2 C<read($timeout)>

This method blocks until a new message has been received by the
device.  When a message is received a data structure is returned
that represents the data received.

B<IMPORTANT:> This API is still subject to change.

=head2 C<read_one(\$buffer)>

This method attempts to remove a single Current Cost message from the
buffer passed in via the scalar reference.  When a message is removed
a data structure is returned that represents the data received.  If
insufficient data is available then undef is returned.

B<IMPORTANT:> This API is still subject to change.

=head2 C<sensor_history($sensor, $interval)>

This method returns the most recent complete sensor data for the
given sensor and the given interval (where interval must be one
of 'hours', 'days', 'months' or 'years').  The return value is
a hash reference with keys for 'time' and 'data'.  The 'time'
value is the time (in seconds since epoch).  The 'data' value
is a hash reference with keys of the number of intervals ago
and values of the reading at that time.

It returns undef if no history data has been received yet.

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
