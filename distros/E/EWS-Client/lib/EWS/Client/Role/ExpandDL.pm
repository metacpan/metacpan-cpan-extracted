package EWS::Client::Role::ExpandDL;
BEGIN {
  $EWS::Client::Role::ExpandDL::VERSION = '1.143070';
}
use Moose::Role;

has ExpandDL => (
    is         => 'ro',
    isa        => 'CodeRef',
    lazy_build => 1,
);

sub _build_ExpandDL {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'ExpandDL',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/ExpandDL'
        ),
    );
}

no Moose::Role;
1;
