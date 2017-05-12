package EWS::Client::Role::SOAP;
BEGIN {
  $EWS::Client::Role::SOAP::VERSION = '1.143070';
}
use Moose::Role;

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use File::ShareDir ();

has server_version => (
    is => 'ro',
    isa => 'Str',
    default => 'Exchange2007_SP1',
    required => 0,
);

has use_negotiated_auth => (
    is => 'ro',
    isa => 'Any',
    default => 0,
    required => 0,
);

has transporter => (
    is => 'ro',
    isa => 'XML::Compile::Transport::SOAPHTTP',
    lazy_build => 1,
);

sub _build_transporter {
    my $self = shift;
    my $addr = $self->server . '/EWS/Exchange.asmx';

    if (not $self->use_negotiated_auth) {
        $addr = sprintf '%s:%s@%s',
            $self->username, $self->password, $addr;
    }

    my $t = XML::Compile::Transport::SOAPHTTP->new(
        address => 'https://'. $addr);
    
    if ($self->use_negotiated_auth) {
        $t->userAgent->credentials($self->server.':443', '',
            $self->username, $self->password);
    }

    # XXX disable all security checks
    $t->userAgent->ssl_opts( verify_hostname => 0, SSL_verify_mode => 0x00 );

    return $t;
}

has wsdl => (
    is => 'ro',
    isa => 'XML::Compile::WSDL11',
    lazy_build => 1,
);

sub _build_wsdl {
    my $self = shift;

    XML::Compile->addSchemaDirs( $self->schema_path );
    my $wsdl = XML::Compile::WSDL11->new('ews-services.wsdl');
    $wsdl->importDefinitions('ews-types.xsd');
    $wsdl->importDefinitions('ews-messages.xsd');

    # skip the t:Culture element in the ResolveNames response
    # it breaks the XML Parser for some reason
    $wsdl->addHook(path => "{http://schemas.microsoft.com/exchange/services/2006/messages}ResolveNamesResponse/ResponseMessages/ResolveNamesResponseMessage/ResolutionSet/Resolution/Contact",
        before => sub {
            my ($xml, $path) = @_;
            my @nodes = $xml->childNodes();
            foreach my $node (@nodes) {
                if($node->nodeName eq 't:Culture'){
                    $xml->removeChild($node);
                }
            }
            return $xml;
         });

    return $wsdl;
}

has schema_path => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_schema_path {
    my $self = shift;
    return File::ShareDir::dist_dir('EWS-Client');
}

no Moose::Role;
1;

