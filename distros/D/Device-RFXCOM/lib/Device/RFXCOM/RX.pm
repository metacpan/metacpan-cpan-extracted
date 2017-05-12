use strict;
use warnings;
package Device::RFXCOM::RX;
$Device::RFXCOM::RX::VERSION = '1.163170';
# ABSTRACT: Module to support RFXCOM RF receiver


use 5.006;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_RX_DEBUG},
  TESTING => $ENV{DEVICE_RFXCOM_RX_TESTING},
};
use base 'Device::RFXCOM::Base';
use Carp qw/croak/;
use IO::Handle;
use IO::Select;
use Device::RFXCOM::Response;
use Module::Pluggable
  search_path => 'Device::RFXCOM::Decoder',
  instantiate => 'new';


sub new {
  my $pkg = shift;
  $pkg->SUPER::_new(device => '/dev/rfxcom-rx', @_);
}

sub _init {
  my ($self, $cb) = @_;
  $self->_write(hex => 'F020', desc => 'version check');
  $self->_write(hex => 'F02A', desc => 'enable all possible receiving modes');
  $self->_write(hex => 'F041', desc => 'variable length with visonic',
                callback => $cb || $self->{init_callback});
  $self->{init} = 1;
}


sub read {
  my ($self, $timeout) = @_;
  my $res = $self->read_one(\$self->{_buf});
  return $res if (defined $res);
  $self->_discard_buffer_check() if ($self->{_buf} ne '');
  $self->_discard_dup_cache_check();
  my $fh = $self->filehandle;
  my $sel = IO::Select->new($fh);
 REDO:
  my $start = $self->_time_now;
  $sel->can_read($timeout) or return;
  my $bytes = sysread $fh, $self->{_buf}, 2048, length $self->{_buf};
  $self->{_last_read} = $self->_time_now;
  $timeout -= $self->{_last_read} - $start if (defined $timeout);
  unless ($bytes) {
    croak defined $bytes ? 'closed' : 'error: '.$!;
  }
  $res = $self->read_one(\$self->{_buf});
  $self->_write_now() if (defined $res);
  goto REDO unless ($res);
  return $res;
}



sub read_one {
  my ($self, $rbuf) = @_;
  return unless ($$rbuf);

  print STDERR "rbuf=", (unpack "H*", $$rbuf), "\n" if DEBUG;
  my $header_byte = unpack "C", $$rbuf;
  my %result =
    (
     header_byte => $header_byte,
     type => 'unknown',
    );
  $result{master} = !($header_byte&0x80);
  my $bits = $header_byte & 0x7f;
  my $msg = '';
  my @bytes;
  if (exists $self->{_waiting} && $header_byte == 0x4d) {

    print STDERR "got version check response\n" if DEBUG;
    $msg = $$rbuf;
    substr $msg, 0, 1, '';
    $$rbuf = '';
    $result{type} = 'version';
    @bytes = unpack 'C*', $msg;

  } elsif (exists $self->{_waiting} &&
           ( $header_byte == 0x2c || $header_byte == 0x41 )) {

    print STDERR "got mode response\n" if DEBUG;
    substr $$rbuf, 0, 1, '';
    $result{type} = 'mode';

  } elsif ($bits == 0) {

    print STDERR "got empty message\n" if DEBUG;
    substr $$rbuf, 0, 1, '';
    $result{type} = 'empty';

  } else {

    my $length = $bits / 8;

    print STDERR "bits=$bits length=$length\n" if DEBUG;
    return if (length $$rbuf < 1 + $length);

    if ($length != int $length) {
      $length = 1 + int $length;
    }

    $msg = substr $$rbuf, 0, 1 + $length, ''; # message from buffer
    substr $msg, 0, 1, '';
    @bytes = unpack 'C*', $msg;

    $result{key} = $bits.'!'.$msg;
    my $entry = $self->_cache_get(\%result);
    if ($entry) {
      print STDERR "using cache entry\n" if DEBUG;
      @result{qw/messages type/} = @{$entry->{result}}{qw/messages type/};
      $self->_cache_set(\%result);
    } else {
      foreach my $decoder (@{$self->{plugins}}) {
        my $matched = $decoder->decode($self, $msg, \@bytes, $bits, \%result)
          or next;
        ($result{type} = lc ref $decoder) =~ s/.*:://;
        last;
      }
      $self->_cache_set(\%result);
    }
  }

  @result{qw/data bytes/} = ($msg, \@bytes);
  return Device::RFXCOM::Response->new(%result);
}

sub _cache_get {
  my ($self, $result) = @_;
  $self->{_cache}->{$result->{key}};
}

sub _cache_set {
  my ($self, $result) = @_;
  return if ($result->{dont_cache});
  my $entry = $self->{_cache}->{$result->{key}};
  if ($entry) {
    $result->{duplicate} = 1 if ($self->_cache_is_duplicate($entry));
    $entry->{t} = $self->_time_now;
    return $entry;
  }
  $self->{_cache}->{$result->{key}} =
    {
     result => $result,
     t => $self->_time_now,
    };
}

sub _cache_is_duplicate {
  my ($self, $entry) = @_;
  ($self->_time_now - $entry->{t}) < $self->{dup_timeout};
}

sub _discard_buffer_check {
  my $self = shift;
  if ($self->{_buf} ne '' &&
      $self->{_last_read} < ($self->_time_now - $self->{discard_timeout})) {
    $self->{_buf} = '';
  }
}

sub _discard_dup_cache_check {
  my $self = shift;
  if ($self->{_last_read} < ($self->_time_now - $self->{dup_timeout})) {
    $self->{_cache} = {};
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::RX - Module to support RFXCOM RF receiver

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # for a USB-based device
  my $rx = Device::RFXCOM::RX->new(device => '/dev/ttyUSB0');

  $|=1; # don't buffer output

  # simple interface to read received data
  my $timeout = 10; # 10 seconds
  while (my $data = $rx->read($timeout)) {
    print $data->summary,"\n" unless ($data->duplicate);
  }

  # for a networked device
  $rx = Device::RFXCOM::RX->new(device => '10.0.0.1:10001');

=head1 DESCRIPTION

Module to decode messages from an RFXCOM RF receiver.

B<IMPORTANT:> This API is still subject to change.

=head1 METHODS

=head2 C<new(%parameters)>

This constructor returns a new RFXCOM RF receiver object.
The supported parameters are:

=over

=item device

The name of the device to connect to.  The value can be a tty device
name or C<hostname:port> for a TCP-based RFXCOM receiver.

The default is C</dev/rfxcom-rx> in anticipation of a scenario where a
udev rule has been used to identify the USB tty device for the device.
For example, a file might be created in C</etc/udev/rules.d/91-rfxcom>
with a line like:

  SUBSYSTEM=="tty", SYSFS{idProduct}=="6001", SYSFS{idVendor}=="0403", SYSFS{serial}=="AnnnnABC", NAME="rfxcom-rx"

where the C<serial> number attribute is obtained from the output
from:

  udevinfo -a -p `udevinfo -q path -n /dev/ttyUSB0` | \
    sed -e'/ATTRS{serial}/!d;q'

=item init_callback

This parameter can be set to a callback to be called when the device
initialization has been completed.

=back

=head2 C<read($timeout)>

This method blocks until a new message has been received by the
device.  When a message is received a data structure is returned
that represents the data received.

B<IMPORTANT:> This API is still subject to change.

=head2 C<read_one(\$buffer)>

This method attempts to remove a single RF message from the buffer
passed in via the scalar reference.  When a message is removed a data
structure is returned that represents the data received.  If insufficient
data is available then undef is returned.  If a duplicate message is
received then 0 is returned.

B<IMPORTANT:> This API is still subject to change.

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
