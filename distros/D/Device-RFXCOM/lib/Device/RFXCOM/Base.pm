use strict;
use warnings;
package Device::RFXCOM::Base;
$Device::RFXCOM::Base::VERSION = '1.163170';
# ABSTRACT: module for RFXCOM device base class


use 5.006;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_BASE_DEBUG},
  TESTING => $ENV{DEVICE_RFXCOM_TESTING},
};
use Carp qw/croak/;
use IO::Handle;
use IO::Select;
use Time::HiRes;
use Symbol qw/gensym/;
use Device::SerialPort qw( :PARAM :STAT 0.07 );
use Fcntl;

sub _new {
  my ($pkg, %p) = @_;
  my $self = bless
    {
     baud => 4800,
     port => 10001,
     discard_timeout => 0.03,
     ack_timeout => 2,
     dup_timeout => 0.5,
     _q => [],
     _buf => '',
     _last_read => 0,
     init_callback => undef,
     %p,
    }, $pkg;
  $self->{plugins} = [$self->plugins()] unless ($self->{plugins});
  $self->_open();
  $self->_init();
  $self;
}

sub DESTROY {
  my $self = shift;
  delete $self->{init};
}


sub queue {
  scalar @{$_[0]->{_q}};
}


sub _write {
  my $self = shift;
  my %p = @_;
  $p{raw} = pack 'H*', $p{hex} unless (exists $p{raw});
  $p{hex} = unpack 'H*', $p{raw} unless (exists $p{hex});
  print STDERR "Queued: ", $p{hex}, ' ', ($p{desc}||''), "\n" if DEBUG;
  push @{$self->{_q}}, \%p;
  $self->_write_now unless ($self->{_waiting});
  1;
}

sub _write_now {
  my $self = shift;
  my $rec = shift @{$self->{_q}};
  my $wait_record = $self->{_waiting};
  if ($wait_record) {
    delete $self->{_waiting};
    my $cb = $wait_record->[1]->{callback};
    $cb->() if ($cb);
  }
  return unless (defined $rec);
  $self->_real_write($rec);
  $self->{_waiting} = [ $self->_time_now, $rec ];
}

sub _real_write {
  my ($self, $rec) = @_;
  print STDERR "Sending: ", $rec->{hex}, ' ', ($rec->{desc}||''), "\n" if DEBUG;
  syswrite $self->{fh}, $rec->{raw}, length $rec->{raw};
}


sub filehandle {
  shift->{fh}
}

sub _open {
  my $self = shift;
  $self->{device} =~ m![/\\]! ?
    $self->_open_serial_port(@_) : $self->_open_tcp_port(@_)
}

sub _open_tcp_port {
  my $self = shift;
  my $dev = $self->{device};
  print STDERR "Opening $dev as tcp socket\n" if DEBUG;
  require IO::Socket::INET; import IO::Socket::INET;
  $dev .= ':'.$self->{port} unless ($dev =~ /:/);
  my $fh = IO::Socket::INET->new($dev) or
    croak "TCP connect to '$dev' failed: $!";
  return $self->{fh} = $fh;
}

sub _open_serial_port {
  my $self = shift;
  my $dev = $self->{device};
  print STDERR "Opening $dev as serial port\n" if DEBUG;
  my $fh = gensym();
  my $sport = tie (*$fh, 'Device::SerialPort', $dev) or
    croak "Could not tie serial port, $dev, to file handle: $!";
  $sport->baudrate($self->baud);
  $sport->databits(8);
  $sport->parity("none");
  $sport->stopbits(1);
  $sport->datatype("raw");
  $sport->write_settings();

  sysopen $fh, $dev, O_RDWR|O_NOCTTY|O_NDELAY or
    croak "sysopen of '$dev' failed: $!";
  $fh->autoflush(1);
  return $self->{fh} = $fh;
}


sub baud {
  shift->{baud}
}

sub _time_now {
  Time::HiRes::time
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Base - module for RFXCOM device base class

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # ... abstract base class

=head1 DESCRIPTION

Module for RFXCOM device base class.

=head1 METHODS

=head2 C<queue()>

Returns the number of messages in the queue to be sent to the
device.

=head2 C<filehandle()>

This method returns the file handle for the device.

=head2 C<baud()>

Returns the baud rate.

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
