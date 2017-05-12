package EWS::Client::Role::FindFolder;
BEGIN {
  $EWS::Client::Role::FindFolder::VERSION = '1.143070';
}

use Moose::Role;

has FindFolder => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_FindFolder {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'FindFolder',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/FindFolder' ),
    );
}

no Moose::Role;
1;
