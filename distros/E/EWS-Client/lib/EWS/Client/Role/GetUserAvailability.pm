package EWS::Client::Role::GetUserAvailability;
BEGIN {
  $EWS::Client::Role::GetFolder::VERSION = '1.141040';
}

use Moose::Role;

has GetUserAvailability => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_GetUserAvailability {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'GetUserAvailability',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/GetUserAvailability' ),
    );
}

no Moose::Role;
1;
