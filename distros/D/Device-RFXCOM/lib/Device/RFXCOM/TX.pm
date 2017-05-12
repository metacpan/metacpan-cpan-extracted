use strict;
use warnings;
package Device::RFXCOM::TX;
$Device::RFXCOM::TX::VERSION = '1.163170';
# ABSTRACT: Module to support an RFXCOM RF transmitter


use 5.006;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_TX_DEBUG},
  TESTING => $ENV{DEVICE_RFXCOM_TX_TESTING},
};
use base 'Device::RFXCOM::Base';
use Carp qw/croak carp/;
use IO::Handle;
use IO::Select;
use Module::Pluggable
  search_path => 'Device::RFXCOM::Encoder',
  instantiate => 'new';


sub new {
  my $pkg = shift;
  my $self = $pkg->SUPER::_new(device => '/dev/rfxcom-tx',
                               ack_timeout => 6,
                               receiver_connected => 0,
                               flamingo => 0,
                               harrison => 0,
                               koko => 0,
                               x10 => 1,
                               @_);
  foreach my $plugin ($self->plugins()) {
    my $p = lc ref $plugin;
    $p =~ s/.*:://;
    $self->{plugin_map}->{$p} = $plugin;
    print STDERR "Initialized plugin for $p messages\n" if DEBUG;
  }
  $self;
}


sub receiver_connected { shift->{receiver_connected} }


sub flamingo { shift->{flamingo} }


sub harrison { shift->{harrison} }


sub koko { shift->{koko} }


sub x10 { shift->{x10} }

sub _init {
  my $self = shift;
  $self->_write(hex => 'F030F030', desc => 'version check');
  $self->_write(hex => 'F03CF03C', desc => 'enabling harrison')
    if ($self->harrison);
  $self->_write(hex => 'F03DF03D', desc => 'enabling klikon-klikoff')
    if ($self->koko);
  $self->_write(hex => 'F03EF03E', desc => 'enabling flamingo')
    if ($self->flamingo);
  $self->_write(hex => 'F03FF03F', desc => 'disabling x10') unless ($self->x10);
  $self->_init_mode($self->{init_callback});
  $self->{init} = 1;
}

sub _init_mode {
  my ($self, $cb) = @_;
  my @args =
    $self->receiver_connected ?
      (hex => 'F033F033',
       desc => 'variable length mode w/receiver connected') :
         (hex => 'F037F037',
          desc=> 'variable length mode w/o receiver connected');
  push @args, callback => $cb if ($cb);
  $self->_write(@args);
}

sub _reset_device {
  my $self = shift;
  carp "No ack from transmitter!\n";
  $self->init_device();
  1;
}


sub transmit {
  my ($self, %p) = @_;
  my $type = $p{type} || 'x10';
  my @args = @{$p{args}||[]};
  my $plugin = $self->{plugin_map}->{$type} or
    croak $self, '->transmit: ', $type, ' encoding not supported';
  my $encode = $plugin->encode($self, \%p);
  if (ref $encode eq 'ARRAY') {
    foreach my $e (@$encode) {
      $self->_write(%$e, @args);
    }
    return scalar @$encode;
  } else {
    $self->_write(%$encode, @args);
    return 1;
  }
}


sub wait_for_ack {
  my ($self, $timeout) = @_;
  $timeout = $self->{ack_timeout} unless (defined $timeout);
  my $fh = $self->filehandle;
  my $sel = IO::Select->new($fh);
  $sel->can_read($timeout) or return;
  my $buf;
  my $bytes = sysread $fh, $buf, 2048;
  unless ($bytes) {
    croak defined $bytes ? 'closed' : 'error: '.$!;
  }
  $self->_write_now();
  print STDERR "Received: ", (unpack 'H*', $buf), "\n" if DEBUG;
  return $buf;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::TX - Module to support an RFXCOM RF transmitter

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # for a USB-based device, transmitting X10 RF messages
  my $tx = Device::RFXCOM::TX->new(device => '/dev/ttyUSB0', x10 => 1);
  $tx->transmit(type => 'homeeasy', command => 'on',
                # ...
               );
  $tx->wait_for_ack() while ($tx->queue);

=head1 DESCRIPTION

Module to encode messages for an RFXCOM RF receiver.
Module for sending RF messages with an RFXCOM transmitter.

B<IMPORTANT:> This API is still subject to change.

=head1 METHODS

=head2 C<new(%parameters)>

This constructor returns a new RFXCOM RF transmitter object.
The supported parameters are:

=over

=item device

The name of the device to connect to.  The value can be a tty device
name or C<hostname:port> for a TCP-based RFXCOM transmitter.

The default is C</dev/rfxcom-tx> in anticipation of a scenario where a
udev rule has been used to identify the USB tty device for the device.
For example, a file might be created in C</etc/udev/rules.d/91-rfxcom>
with a line like:

  SUBSYSTEM=="tty", SYSFS{idProduct}=="6001", SYSFS{idVendor}=="0403", SYSFS{serial}=="AnnnnABC", NAME="rfxcom-tx"

where the C<serial> number attribute is obtained from the output
from:

  udevinfo -a -p `udevinfo -q path -n /dev/ttyUSB0` | \
    sed -e'/ATTRS{serial}/!d;q'

=item init_callback

This parameter can be set to a callback to be called when the device
initialization has been completed.

=item receiver_connected

This parameter should be set to a true value if a receiver is connected
to the transmitter.

=item flamingo

This parameter should be set to a true value to enable the
transmission for "flamingo" RF messages.

=item harrison

This parameter should be set to a true value to enable the
transmission for "harrison" RF messages.

=item koko

This parameter should be set to a true value to enable the
transmission for "klik-on klik-off" RF messages.

=item x10

This parameter should be set to a false value to disable the
transmission for "x10" RF messages.  This protocol is enable
by default in keeping with the hardware default.

=back

There is no option to enable homeeasy messages because they use either
the klik-on klik-off protocol or homeeasy specific commands in order
to trigger them.

=head2 C<receiver_connected()>

Returns true if the transmitter is operating with a receiver
connected.

=head2 C<flamingo()>

Returns true if the transmitter is configured to transmit "flamingo"
RF messages.

=head2 C<harrison()>

Returns true if the transmitter is configured to transmit "harrison"
RF messages.

=head2 C<koko()>

Returns true if the transmitter is configured to transmit "klik-on
klik-off" RF messages.

=head2 C<x10()>

Returns true if the transmitter is configured to transmit "x10" RF messages.
This attribute defaults to true.

=head2 C<transmit(%params)>

This method sends an RF message to the device for transmission.

=head2 C<wait_for_ack($timeout)>

This method blocks until a new message has been received by the
device.  When a message is received a data structure is returned
that represents the data received.

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
