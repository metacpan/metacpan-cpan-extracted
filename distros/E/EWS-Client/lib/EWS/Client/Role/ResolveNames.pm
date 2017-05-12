package EWS::Client::Role::ResolveNames;
BEGIN {
  $EWS::Client::Role::FindItem::VERSION = '1.141040';
}
use Moose::Role;

has ResolveNames => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_ResolveNames {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'ResolveNames',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/ResolveNames' ),
    );
}

no Moose::Role;
1;

