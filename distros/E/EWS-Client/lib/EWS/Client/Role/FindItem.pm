package EWS::Client::Role::FindItem;
BEGIN {
  $EWS::Client::Role::FindItem::VERSION = '1.143070';
}
use Moose::Role;

has FindItem => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_FindItem {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'FindItem',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/FindItem' ),
    );
}

no Moose::Role;
1;

