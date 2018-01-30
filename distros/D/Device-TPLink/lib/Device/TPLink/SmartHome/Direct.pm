package Device::TPLink::SmartHome::Direct;

use 5.008003;
use Moose;
use IO::Socket;

extends 'Device::TPLink::SmartHome';

has addr => (
  is => 'rw',
  isa => 'Str',
);

has port =>(
  is => 'rw',
  isa => 'Int',
);

=head1 NAME

Device::TPLink::SmartHome::Direct - Control TP-Link Smart Home devices over a direct TCP connection

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Device::TPLink::SmartHome::Direct;

    my $foo = Device::TPLink::SmartHome::Direct->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 passthrough

Recieves an object, formats it as a JSON command and passes it to the device. Returns a response object.

=cut

sub passthrough {
  my $self = shift;
  my ($requestData) = @_;

  my $remote_host = $self->addr;
  my $remote_port = $self->port;

  my $socket = IO::Socket::INET->new(
    PeerAddr => $remote_host,
    PeerPort => $remote_port,
    Proto => "tcp",
    Type => SOCK_STREAM
  ) or die "Couldn't connect to $remote_host:$remote_port : $@\n";

  my $json = JSON->new->allow_nonref;
  # Fun fact: For the HS105, your JSON cannot have any newlines in it, so no pretty JSON for us...
  # $json = $json->pretty(1);
  my $plaintext = $json->encode($requestData);
  my $ciphertext = encrypt($plaintext);
  print $socket $ciphertext or die "Socket not connected? ";
  my $responseData;
  my $responseLength = 1;
  while ($responseLength) {
    my $buffer;
    my $retValue = $socket->recv($buffer, 4096);
    $responseData .= $buffer;
    $responseLength = unpack("N", substr($responseData,0,4));
    if (length($responseData) > 0 && length($responseData) >= ($responseLength + 4)) { $responseLength = 0; }
  }
  $responseData = decrypt($responseData);
  my $responseDataScalar = $json->decode($responseData);
  return $responseDataScalar;
}

=head2 function2

=cut

# Pass the command to the device
around [qw(on off getSystemInfo reboot)] => sub {
  my $next = shift;
  my $self = shift;
  my $requestData = $next->($self);
  return $self->passthrough($requestData);
};

=head2 encrypt

Encrypts plain text in the manner expected by TP-Link devices.

=cut

sub encrypt {
  my $plaintext = shift;
  my $key = 171;
  my $ciphertext = pack("N", length($plaintext));
  foreach my $i (split //, $plaintext) {
    my $a = $key ^ ord($i);
    $key = $a;
    $ciphertext = $ciphertext . chr($a);
  }
  return $ciphertext;
}

=head2 decrypt

Decrypts text returned from TP-Link device.

=cut

sub decrypt {
  my $ciphertext = shift;
  $ciphertext = substr($ciphertext,4);
  my $key = 171;
  my $plaintext = "";
  foreach my $i (split //, $ciphertext) {
    my $a = $key ^ ord($i);
    $key = ord($i);
    $plaintext = $plaintext . chr($a);
  }
  return $plaintext;
}


=head1 AUTHOR

Verlin Henderson, C<< <verlin at gmail.com> >>

=head1 BUGS / SUPPORT

To report any bugs or feature requests, please use the github issue tracker: L<https://github.com/verlin/Device-TPLink/issues>

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Verlin Henderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable;

1; # End of Device::TPLink::SmartHome::Direct
