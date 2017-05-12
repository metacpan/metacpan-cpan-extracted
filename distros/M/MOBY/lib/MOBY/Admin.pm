
=head1 NAME

MOBY::Admin.pm - API for adminning the MOBY Central registry

=cut

package MOBY::Admin;
use strict;
use Carp;
use vars qw($AUTOLOAD $WSDL_TEMPLATE);
use XML::LibXML;
use MOBY::OntologyServer;
use MOBY::service_type;
use MOBY::authority;
use MOBY::service_instance;
use MOBY::simple_input;
use MOBY::simple_output;
use MOBY::collection_input;
use MOBY::collection_output;
use MOBY::secondary_input;
use MOBY::central_db_connection;
use MOBY::Config;
use MOBY::CommonSubs;
use MOBY::MobyXMLConstants;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

sub deregisterService {
	my ( $self, $xml ) = @_;

	# parse the xml that is passed into this method
	# pass the hash to the _deregisterService sub routine.
	use XML::LibXML;
	my ( $name, $authority, $phrase );
	my $Parser = XML::LibXML->new();
	my $doc    = $Parser->parse_string($xml);

	# extract the element 'name'
	my $element = $doc->getElementsByTagName("name")->get_node(1);
	$name = $element->textContent || "";

	# extract the element 'authority'
	$element   = $doc->getElementsByTagName("authority")->get_node(1);
	$authority = $element->textContent || "";

	# extract the element 'phrase'
	$element = $doc->getElementsByTagName("phrase")->get_node(1);
	$phrase = $element->textContent || "";
	my $returnValue = $self->_deregisterService(
												 servicename => $name,
												 authority   => $authority,
												 phrase      => $phrase
	);
	return $returnValue;
}

###ERROR CODES RETURNED ###################
# 101 = no authority URI
# 102 = no service name
# 103 = no keyphrase
# 501 = key phrase dont match
# 200 = service successfully deleted
# 404 = service not found
# 500 = other unknown error
############################################
sub _deregisterService {
	my ( $self, %args ) = @_;
	my $uri = $args{authority};
	my $val = '500';
	if ( not $uri ) {
		return '101';
	}

	my $name = $args{servicename};
	if ( not $name ) {
		return '102';
	}

	my $phrase = $args{phrase};
	if ( not $phrase ) {
		return '103';

	}
	eval {

		# get the passphrase
		my $CONF = MOBY::Config->new;

		if ( $CONF->{mobycentral}{keyphrase} ne $phrase ) {
			$val = '501';
		}

		my $service = MOBY::service_instance->new(
												   servicename   => $name,
												   authority_uri => $uri,
												   test          => 1
		);

		if ($service) {
			$service = MOBY::service_instance->new(          servicename   => $name,
													authority_uri => $uri, );

			$val = '200' if $service->DELETE_THYSELF;
		}
		else {

			$val = '404';
		}
	};
	if ($@) {
		print STDERR "Error in deregisterService: : " . $@;
		return 500;
	}
	return $val;
}

1;
