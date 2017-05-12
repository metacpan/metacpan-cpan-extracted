use strict;
use warnings;
package Device::W800;
$Device::W800::VERSION = '1.163170';
# ABSTRACT: Module to support W800 RF receiver


use 5.006;
use constant DEBUG => $ENV{DEVICE_W800_DEBUG};
use Carp qw/croak/;
use base 'Device::RFXCOM::RX';
use Device::RFXCOM::Response;


sub new {
  my ($pkg, %p) = @_;
  my @plugins;
  # TODO: Make 32-bit support a class method on the decoder so
  # this process (to restrict the plugins to a useful set) is
  # encapsulated better.
  foreach my $decoder (qw/RFXSensor X10 X10Security/) {
    my $module = 'Device::RFXCOM::Decoder::'.$decoder;
    my $file = 'Device/RFXCOM/Decoder/'.$decoder.'.pm';
    require $file; import $module;
    push @plugins, $module->new();
  }
  $pkg->SUPER::new(device => '/dev/w800', plugins => \@plugins, %p);
}

sub _write {
  croak "Writes not supported for W800: @_\n";
}

sub _write_now {
  # do nothing
}

sub _init {
  my $self = shift;
  $self->{init} = 1;
}


sub read_one {
  my ($self, $rbuf) = @_;
  return unless ($$rbuf);

  print STDERR "rbuf=", (unpack "H*", $$rbuf), "\n" if DEBUG;
  my $bits = 32;
  my $length = 4;
  my %result =
    (
     master => 1,
     header_byte => $bits,
     type => 'unknown',
    );
  my $msg = '';
  my @bytes;

  return if (length $$rbuf < $length);

  $msg = substr $$rbuf, 0, $length, ''; # message from buffer
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

  @result{qw/data bytes/} = ($msg, \@bytes);
  return Device::RFXCOM::Response->new(%result);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::W800 - Module to support W800 RF receiver

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # for a USB-based device
  my $rx = Device::W800->new(device => '/dev/ttyUSB0');

  $|=1; # don't buffer output

  # simple interface to read received data
  my $timeout = 10; # 10 seconds
  while (my $data = $rx->read($timeout)) {
    print $data->summary,"\n";
  }

  # for a networked device
  $rx = Device::W800->new(device => '10.0.0.1:10001');

=head1 DESCRIPTION

Module to decode messages from an W800 RF receiver from WGL &
Associates.

B<IMPORTANT:> This API is still subject to change.

=head1 METHODS

=head2 C<new(%parameters)>

This constructor returns a new W800 RF receiver object.
The only supported parameter is:

=over

=item device

The name of the device to connect to.  The value can be a tty device
name or a C<hostname:port> for TCP-based serial port redirection.

The default is C</dev/w800> in anticipation of a scenario where a udev
rule has been used to identify the USB tty device of the W800.

=back

=head2 C<read_one(\$buffer)>

This method attempts to remove a single RF message from the buffer
passed in via the scalar reference.  When a message is removed a data
structure is returned that represents the data received.  If insufficient
data is available then undef is returned.  If a duplicate message is
received then 0 is returned.

B<IMPORTANT:> This API is still subject to change.

=head1 SEE ALSO

L<Device::RFXCOM::RX>

W800 website: http://www.wgldesigns.com/w800.html

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
