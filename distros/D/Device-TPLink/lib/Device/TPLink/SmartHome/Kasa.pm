package Device::TPLink::SmartHome::Kasa;

use 5.008003;
use Moose;
use LWP::JSON::Tiny;

extends 'Device::TPLink::SmartHome';

has token => (
  is => 'rw',
  isa => 'Str',
);

=head1 NAME

Device::TPLink::SmartHome::Kasa - Use Perl to control TP-Link Smart Home devices using the Kasa cloud service

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Interacts with TP-Link smart home devices using the Kasa cloud service.

=head1 SUBROUTINES/METHODS

=head2 passthrough

Passes an arbitrary object to the device after converting it to JSON and wrapping it in a Kasa request. Used internally to package commands and send them to the device.

    $HS100-> = Device::TPLink::SmartHome::Kasa->new();

=cut

sub passthrough {
  my $self = shift;
  my ($token, $requestData) = @_;

  my $json = JSON->new->allow_nonref;
  $json = $json->pretty(1);

  my $user_agent = LWP::UserAgent::JSON->new;
  my $params = { deviceId => $self->deviceId, requestData => $json->encode($requestData) };
  my $request_object = {
    method => 'passthrough', params => $params
  };
  my $url = $self->appServerUrl . "?token=$token";
  my $request = HTTP::Request::JSON->new(POST => $url);
  $request->header('Accept' => '*/*');
  $request->json_content( $request_object );

  my $response = $user_agent->request($request);
  my $response_json_string =  $response->content;
  my $responseData =  $json->decode( $response_json_string )->{result}{responseData};
  my $responseDataScalar = $json->decode($responseData);
  return $responseDataScalar;
}


=head2 function2

=cut

around [qw(on off getSystemInfo reboot)] => sub { # Pass the command to the device
  my $next = shift;
  my $self = shift;
  my $token = $self->token;
  my $requestData = $next->($self);
  return $self->passthrough($token, $requestData);
};


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

1; # End of Device::TPLink::SmartHome::Kasa
