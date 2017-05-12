package EWS::Client::Role::GetFolder;
BEGIN {
  $EWS::Client::Role::GetFolder::VERSION = '1.143070';
}

use Moose::Role;

has GetFolder => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_GetFolder {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'GetFolder',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/GetFolder' ),
    );
}

no Moose::Role;
1;
