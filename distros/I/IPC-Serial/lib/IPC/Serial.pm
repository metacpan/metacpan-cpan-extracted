# -*-cperl-*-
#
# IPC::Serial - Simple message passing over serial ports
# Copyright (c) 2016-2017 Ashish Gulhati <ipc-serial at hash.neo.tc>
#
# $Id: lib/IPC/Serial.pm v1.006 Sun Jun 11 12:42:55 PDT 2017 $

use strict;

package IPC::Serial;

use 5.008001;
use warnings;
use strict;

use Device::SerialPort qw(:STAT);
use Digest::MD5 qw(md5_hex);

use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.006 $' =~ /\s+([\d\.]+)/;

sub new {
  my $class = shift;
  my %args = @_;
  return undef unless $args{Port};
  return unless my $port = new Device::SerialPort ($args{Port});
  $port->read_char_time(0);     # don't wait for each character
  $port->read_const_time(10);   # 10 ms per unfulfilled "read" call
  $port->user_msg('ON');
  $port->databits(8);
  $port->baudrate(115200);
  $port->parity("none");
  $port->stopbits(1);
  $port->handshake("none");
  bless { Port => $port }, $class;
}

sub getmsg {
  my ($self, $idletimeout, $ack, $check) = @_;
  my ($buffer, $chars, $rcvd) = ('');
  until ($rcvd) {
    $buffer = '';
    if (defined $self->{savefragment}) { $buffer .= $self->{savefragment}; delete $self->{savefragment}; }
    my $timeout = $idletimeout;
    while ($timeout and $buffer !~ /\S\n/) {
      my ($count,$saw) = $self->{Port}->read(1024);
      if ($count > 0) {
	$buffer .= $saw;
	last if $buffer =~ /\S\n/;
	$timeout = $idletimeout;
      }
      else {
	$timeout--;
      }
    }
    if ($buffer =~ /\n/) {
      my $buf = $buffer;
      $buffer =~ s/^\s*(.+?)\:\n(.*)$/$1/s;
      my ($trailing, $cksum, $msg) = ($2);
      $self->{savefragment} .= $trailing if $trailing =~ /\S+/;
      if ($buffer =~ /(.+):(.*)/) {
	if ($2) {                        # Checksum attached
	  unless ($check) {
	    if ($ack) {                  # But wasn't expected. We seem to have missed an ACK
	      return 'ERR';
	    }
	  }
	  ($msg, $cksum) = ($1, $2);
	  if (_cksum($msg) eq $cksum) {   # Valid checksum, all good
	    $self->sendmsg('OK');
	    $buffer = $msg;
	    $rcvd = 1;
	  }
	  else {                         # Checksum mismatch
	    $self->_diag("GM B:$buffer\nBB:$buf\nM:$msg\nH:$cksum\n");
	    $self->sendmsg('ERR');
	  }
	}
	elsif ($check) {                 # No checksum but was expected, Error.
	  $self->_diag("GM B:$buffer\nBB:$buf\nM:$msg\nH:$cksum\n");
	  next if $buffer eq 'OK:';      # Ignore if it's a stray OK we missed
	  $self->sendmsg('ERR');
	}
	else {                           # No checksum in sent message, not expected
	  $buffer =~ s/\:$//;
	  $rcvd = 1;
	}
      }
      else {                             # No colon in sent message, serial ate it
	$self->_diag("GM B:$buffer\nBB:$buf\nM:$msg\nH:$cksum\n");
	$self->sendmsg('ERR');
      }
    }
    else {                               # Timed out waiting for response.
      $self->{savefragment} = $buffer if $buffer =~ /\S+/;
      return $ack ? 'ERR' : undef;       #  If we were waiting for an ACK, this is an error
    }
  }
  $buffer =~ s/(?<!\;)\;(?!\;)/\:/g; $buffer =~ s/\;\;/\;/g;
  return $buffer;
}

sub sendmsg {
  my ($self,$msg,$cksum) = @_;
  $self->_diag("sendmsg:$msg:\n");
  $msg =~ s/\;/\;\;/g; $msg =~ s/\:/\;/g;
  my $hexhash = $cksum ? _cksum($msg) : '';
  my $ack = ''; my $i = 1;
  while ($ack ne 'OK') {
    $self->_diag("sendmsg:$i:$msg:\n"); $i++;
    $self->{Port}->write("$msg:$hexhash:\n\n\n\n");
    $ack = $cksum ? $self->getmsg(100, 1, 0) : 'OK';
  }
  return 1;
}

sub close {
  my $self = shift;
  $self->port->close;
}

sub _cksum {
  md5_hex(shift);
}

sub _diag {
  my $self = shift;
  print STDERR @_;
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(port)$/x) {  
    return $self->{"\u$auto"};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

1; # End of IPC::Serial

=head1 NAME

IPC::Serial - Simple message passing over serial ports

=head1 VERSION

 $Revision: 1.006 $
 $Date: Sun Jun 11 12:42:55 PDT 2017 $

=head1 SYNOPSIS

Simple message passing over serial ports.

    use IPC::Serial;

    my $serial1 = new IPC::Serial (Port => '/dev/cua00');
    my $serial2 = new IPC::Serial (Port => '/dev/cua01');

    $serial1->sendmsg("Hello there!");
    my $msg = $serial2->getmsg;

=head1 METHODS

=head2 new

=head2 getmsg

=head2 sendmsg

=head2 close

=head1 AUTHOR

Ashish Gulhati, C<< <ipc-serial at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc-serial at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-Serial>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::Serial

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPC-Serial>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPC-Serial>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPC-Serial>

=item * Search CPAN

L<http://search.cpan.org/dist/IPC-Serial/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See L<http://www.perlfoundation.org/artistic_license_2_0> for the full
license terms.
