package EWS::Client::Role::GetItem;
BEGIN {
  $EWS::Client::Role::GetItem::VERSION = '1.143070';
}
use Moose::Role;

has GetItem => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_GetItem {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'GetItem',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/GetItem' ),
    );
}

no Moose::Role;
1;

