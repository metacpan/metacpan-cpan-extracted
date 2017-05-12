#-----------------------------------------------------------------
# MOSES::MOBY::Async
# Author: Edward Kawas <edward.kawas@gmail.com>,
#
# For copyright and disclaimer see below.
#
# $Id: Async.pm,v 1.3 2009/05/06 13:47:31 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Async;
use base ("MOSES::MOBY::Base");

use POSIX;
use MOBY::Async::LSAE;
use MOBY::Async::WSRF;
use HTTP::Date;

use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Async - A module for interacting with HTTP POST WSRF asynchronous services 

=head1 SYNOPSIS

 use MOSES::MOBY::Async;

=head1 DESCRIPTION
	
This module is the main module used by asynchronous HTTP POST biomoby services. In most situations, it would be incorrect for you to instantiate a reference to this module.

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them (additionally
to the attributes from the parent classes)

=cut

{
	my %_allowed = (

	);

	sub _accessible {
		my ( $self, $attr ) = @_;
		exists $_allowed{$attr} or $self->SUPER::_accessible($attr);
	}

	sub _attr_prop {
		my ( $self, $attr_name, $prop_name ) = @_;
		my $attr = $_allowed{$attr_name};
		return ref($attr) ? $attr->{$prop_name} : $attr if $attr;
		return $self->SUPER::_attr_prop( $attr_name, $prop_name );
	}
}

#-----------------------------------------------------------------
# some FAULTS; their names, and descriptions
#-----------------------------------------------------------------
my %FAULT_DESCRIPTIONS = ();
my %FAULT_NAMES        = ();

=head2

The following are constants that refer to faults. 

I<none are exported>

=over

=item C<RESOURCE_UNKNOWN_FAULT>

=item C<RESOURCE_UNAVAILABLE_FAULT>

=item C<RESOURCE_NOT_DESTROYED_FAULT>

=item C<INVALID_RESOURCE_PROPERTY_QNAME_FAULT>

=back

=cut

use constant RESOURCE_UNKNOWN_FAULT                => 400;
use constant RESOURCE_UNAVAILABLE_FAULT            => 401;
use constant RESOURCE_NOT_DESTROYED_FAULT          => 402;
use constant INVALID_RESOURCE_PROPERTY_QNAME_FAULT => 403;

BEGIN {

	# set the fault descriptions
	$FAULT_DESCRIPTIONS{RESOURCE_UNKNOWN_FAULT}       = "Resource unknown";
	$FAULT_DESCRIPTIONS{RESOURCE_UNAVAILABLE_FAULT}   = "Resource unavailable";
	$FAULT_DESCRIPTIONS{RESOURCE_NOT_DESTROYED_FAULT} = "Resource not destroyed";
	$FAULT_DESCRIPTIONS{INVALID_RESOURCE_PROPERTY_QNAME_FAULT} =
	  "Invalid resource property QName";

	# set the fault names
	$FAULT_NAMES{RESOURCE_UNKNOWN_FAULT}       = "ResourceUnknownFault";
	$FAULT_NAMES{RESOURCE_UNAVAILABLE_FAULT}   = "ResourceUnavailableFault";
	$FAULT_NAMES{RESOURCE_NOT_DESTROYED_FAULT} = "ResourceNotDestroyedFault";
	$FAULT_NAMES{INVALID_RESOURCE_PROPERTY_QNAME_FAULT} =
	  "InvalidResourcePropertyQNameFault";
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {

}

#-----------------------------------------------------------------
# submit
#	takes in the Service, the service invocation id, the current Job,
# 		the incoming Package and the outgoing Package.
#		invokes the Service and creates a WSRF resource for it.
#	return: nothing
#-----------------------------------------------------------------

=head2

 Name       :    submit
 Function   :    submits an asynchronous job
 Usage      :    $async->submit($obj, $id, $job, $in_package, $out_package);
 Args       :    $obj         - a child of MOSES::MOBY::Service::ServiceBase
                 $id 	      - a scalar string representing the service invocation id
                 $job         - a MOSES::MOBY::Job, representing the current job 
                 $in_package  - a MOSES::MOBY::Package, representing the incoming message 
                 $out_package - a MOSES::MOBY::Package, representing the outgoing message

=cut

sub submit {
	my ( $self, $obj, $ID, $job, $in_package, $out_package ) = @_;

	my $queryID         = $job->jid;
	my $property_pid    = "pid_$queryID";
	my $property_input  = "input_$queryID";
	my $property_status = "status_$queryID";
	my $property_result = "result_$queryID";

	my $lock;

	# Fork
	my $pid = fork();
	do {

		#-----------------#
		# Fork has failed #
		#-----------------#

		# Status
		my $status = LSAE::AnalysisEventBlock->new();
		$status->type(LSAE_STATE_CHANGED_EVENT);
		$status->previous_state('created');
		$status->new_state('terminated_by_error');
		$status->id($queryID);

		# Result
		$out_package->record_error(
								   { code => 701, msg => 'Unable to submit the job' } );
		$lock = WSRF::MobyFile->new( undef, $ID );

		# New properties values
		$WSRF::WSRP::Private{$property_pid}               = '';
		$WSRF::WSRP::ResourceProperties{$property_status} = $status->XML();
		$WSRF::WSRP::ResourceProperties{$property_result} =
		  $out_package->job_by_id( $job->jid )->toXML();
		$lock->toFile();

	} unless defined($pid);

	if ($pid) {

		#-----------------------------------------------------#
		# Fork has had success and this is the parent process #
		#-----------------------------------------------------#

		# Status
		my $status;
		if ( $WSRF::WSRP::ResourceProperties{$property_status} ) {

			# This is not the first execution of the service for this queryID
			# Previous state is the new state of the previous execution
			my $old_status = LSAE::AnalysisEventBlock->new(
									$WSRF::WSRP::ResourceProperties{$property_status} );
			$status = LSAE::AnalysisEventBlock->new();
			$status->type(LSAE_STATE_CHANGED_EVENT);
			$status->previous_state( $old_status->new_state() );
			$status->new_state('created');
			$status->id($queryID);

		} else {

			# This is the first execution of the service for this queryID
			$status = LSAE::AnalysisEventBlock->new();
			$status->type(LSAE_STATE_CHANGED_EVENT);
			$status->previous_state('created');
			$status->new_state('created');
			$status->id($queryID);
		}

		# New properties values
		$lock = WSRF::MobyFile->new( undef, $ID );
		$WSRF::WSRP::Private{$property_pid}               = undef;
		$WSRF::WSRP::ResourceProperties{$property_status} = $status->XML();
		$WSRF::WSRP::ResourceProperties{$property_result} = '';
		$lock->toFile();

	} elsif ( $pid == 0 ) {

		#----------------------------------------------------#
		# Fork has had success and this is the child process #
		#----------------------------------------------------#

		# Daemonize
		open STDIN,  "/dev/null";
		open STDOUT, ">/dev/null";
		open STDERR, ">/dev/null";
		setsid;

		# Status
		my $status = LSAE::AnalysisEventBlock->new();
		$status->type(LSAE_STATE_CHANGED_EVENT);
		$status->previous_state('created');
		$status->new_state('running');
		$status->id($queryID);

		# New properties values
		$lock = WSRF::MobyFile->new( undef, $ID );
		$WSRF::WSRP::Private{$property_pid}               = $$;
		$WSRF::WSRP::ResourceProperties{$property_status} = $status->XML();
		$WSRF::WSRP::ResourceProperties{$property_result} = '';
		$lock->toFile();

		# Run service
		eval {
			$obj->process_it( $job, $out_package->job_by_id( $job->jid ),
							  $out_package );
		};

		my $result;

		# Check if there has been errors during service execution

		unless ($@) {

			# Service has been executed successfully
			# Status
			$status = LSAE::AnalysisEventBlock->new();
			$status->type(LSAE_STATE_CHANGED_EVENT);
			$status->previous_state('running');
			$status->new_state('completed');
			$status->id($queryID);
		} else {

			# Service execution has failed
			# Status
			$status = LSAE::AnalysisEventBlock->new();
			$status->type(LSAE_STATE_CHANGED_EVENT);
			$status->previous_state('running');
			$status->new_state('terminated_by_error');
			$status->id($queryID);

			# Result INTERNAL_PROCESSING_ERROR
			$out_package->job_by_id( $job->jid )
			  ->record_error(
							{ code => 701, msg => "Error while executing job: '$@'" } );
		}
		# now lets create the MOBY XML for this job
		my ($out_package_for_this_job) = new MOSES::MOBY::Package;
        $out_package_for_this_job->add_jobs($out_package->job_by_id( $job->jid ));
        $out_package->job_by_id( $job->jid )->_context($out_package_for_this_job);

		# any service notes?
        $out_package_for_this_job->serviceNotes($out_package->serviceNotes) if $out_package->serviceNotes;
        # any exceptions?
        $out_package_for_this_job->exceptions(@{$out_package->exceptions}) if $out_package->exceptions and scalar @{$out_package->exceptions};

		# New properties values
		$lock = WSRF::MobyFile->new( undef, $ID );
		$WSRF::WSRP::Private{$property_pid}               = '';
		$WSRF::WSRP::ResourceProperties{$property_status} = $status->XML();
		$WSRF::WSRP::ResourceProperties{$property_result} =
		  #$out_package_for_this_job->job_by_id( $job->jid )->toXML->toString(0);
		  $out_package_for_this_job->toXML->toString(0);
		$lock->toFile();

		# Exits the child process
		exit;
	}

}

#-----------------------------------------------------------------
# destroy
#	takes in the moby-wsrf header and the XML message and destroys
#		the underlying wsrf resource.
#	return: the moby-wsrf header and XML conveying the destruction
#		of the underlying wsrf resource.
#-----------------------------------------------------------------

=head2

 Name       :    destroy
 Function   :    destroys an asynchronous job
 Usage      :    $async->destroy($header, $data);
 Args       :    $header - a string of XML representing the moby-wsrf header 
                 $data 	 - a string of XML representing the WSRF destroy resource call.

=cut

sub destroy {
	my ( $self, $header, $data ) = @_;
	my $parser = XML::LibXML->new();
	my $doc;
	eval { $doc = $parser->parse_string($header); };

	#throw error if $@
	return $self->create_fault( RESOURCE_NOT_DESTROYED_FAULT, '', $@ ) if $@;

	# this the TO url that we need for our header/faults
	my $URL = $doc->getElementsByLocalName("To");
	$URL = $URL->get_node(1)->textContent if $URL->size > 0;

	# get the service invocation id
	my $ID = $doc->getElementsByLocalName("ServiceInvocationId");

	# throw error if $ID->size() <= 0
	return
	  $self->create_fault( RESOURCE_NOT_DESTROYED_FAULT, $URL,
						   'Missing the ServiceInvocationId in the moby-wsrf header.' )
	  unless $ID->size() > 0;
	$ID = $ID->get_node(1)->textContent if $ID->size > 0;
	$ID =~ s/ //gi;

	# wrap in eval{}; because either lifetime expired or invalid ID!
	my $lock;
	eval {$lock = WSRF::MobyFile->new( undef, $ID );};
	
	return
	  $self->create_fault( RESOURCE_NOT_DESTROYED_FAULT, $URL,
						   'Either the requested resource cannot be found or it\'s lifetime expired.' ) if $@;
	my @notkilled;
	foreach my $key ( keys %WSRF::WSRP::Private ) {
		if ( index( $key, "pid_" ) == 0 ) {
			my $pid = $WSRF::WSRP::Private{$key};
			if ($pid) {
				kill( 9, $pid ) or push( @notkilled, $pid );
			}
		}
	}
	$lock->toFile();

	# throw error if some processes were not destroyed
	return
	  $self->create_fault( RESOURCE_NOT_DESTROYED_FAULT, $URL,
				 "Could not kill WS-Resource process(es): " . join( ", ", @notkilled ) )
	  if ( scalar(@notkilled) );

	# wrap in eval{}; because either lifetime expired or invalid ID!
	eval {$lock = WSRF::MobyFile->new( undef, $ID );};
	
	return
	  $self->create_fault( RESOURCE_NOT_DESTROYED_FAULT, $URL,
						   'Either the requested resource cannot be found or it\'s lifetime expired.' ) if $@;
	
	my $file = $WSRF::Constants::Data . $lock->ID();
	unlink $file or die "error destroying resource";

	# return the following if successful
	return
	  $self->_resource_property_header( "ImmediateResourceTermination/DestroyResponse",
										$URL ),
	  '<DestroyResponse xmlns="http://docs.oasis-open.org/wsrf/rl-2"/>';
}

#-----------------------------------------------------------------
# result
#	takes in the moby-wsrf header and the XML message and obtains
#		the result for the underlying wsrf resource.
#	return: the moby-wsrf header and XML representing the result
#		for the underlying wsrf resource.
#-----------------------------------------------------------------

=head2

 Name       :    result
 Function   :    obtains the result of an asynchronous job
 Usage      :    $async->result($header, $data);
 Args       :    $header - a string of XML representing the moby-wsrf header 
                 $data 	 - a string of XML representing the WSRF result call.

=cut

sub result {
	my ( $self, $header, $data ) = @_;
	my $parser = XML::LibXML->new();
	my $doc;
	eval { $doc = $parser->parse_string($header); };

	# throw error if $@
	return
	  $self->create_fault( INVALID_RESOURCE_PROPERTY_QNAME_FAULT,
						   "", "moby-wsrf header was invalid:\n$@" )
	  if $@;

	# this the TO url that we need incase we throw a fault
	my $URL = $doc->getElementsByLocalName("To");

	# TODO throw error if $URL->size <= 0
	$URL = $URL->get_node(1)->textContent if $URL->size > 0;

	# get the service invocation id
	my $ID = $doc->getElementsByLocalName("ServiceInvocationId");

	# throw error if $ID->size() <= 0
	return
	  $self->create_fault( RESOURCE_UNKNOWN_FAULT, $URL,
						   "You neglected to provide a ServiceInvocationId" )
	  unless $ID->size > 0;
	$ID = $ID->get_node(1)->textContent if $ID->size > 0;
	$ID =~ s/ //gi;
	# wrap in eval{}; because either lifetime expired or invalid ID!
	my $lock;
	eval {$lock = WSRF::MobyFile->new( undef, $ID );};
	return
	  $self->create_fault( RESOURCE_UNKNOWN_FAULT, $URL,
						   'Either the requested resource cannot be found or it\'s lifetime expired.' ) if $@;

	# get the query ids from the $data
	my @ids = @{ $self->_get_query_ids( $data, ":result_" ) };

	# throw error if no ids found
	return
	  $self->create_fault( RESOURCE_UNKNOWN_FAULT, $URL,
						   "No IDs in request for results." )
	  unless scalar @ids;

	my $ans = '';
	foreach my $queryID (@ids) {
		my $property_status = "result_$queryID";
		# TODO - does the property exist? if not throw error so we dont pass invalid XML
		$ans .= "<"
		  . $WSRF::WSRP::PropertyNamespaceMap->{$property_status}{prefix}
		  . ":$property_status";
		my $ns =
		  defined( $WSRF::WSRP::PropertyNamespaceMap->{$property_status}{namespace} )
		  ? " xmlns:"
		  . $WSRF::WSRP::PropertyNamespaceMap->{$property_status}{prefix} . "=\""
		  . $WSRF::WSRP::PropertyNamespaceMap->{$property_status}{namespace} . "\">"
		  : ">";
		$ans .= $ns;
		$ans .= $WSRF::WSRP::ResourceProperties{$property_status};
		$ans .= "</"
		  . $WSRF::WSRP::PropertyNamespaceMap->{$property_status}{prefix}
		  . ":$property_status>";
	}
	$lock->toFile();

	# parse the XML to see what kind of response we need to send back
	eval { $doc = $parser->parse_string($data); };

	# return an error if there is a problem parsing $data
	return
	  $self->create_fault( INVALID_RESOURCE_PROPERTY_QNAME_FAULT,
						   "",
						   "WSRF resource request was not structured correctly:\n$@" )
	  if $@;

	$ans =
"<GetMultipleResourcePropertiesResponse xmlns='http://docs.oasis-open.org/wsrf/rp-2'>"
	  . $ans
	  . "</GetMultipleResourcePropertiesResponse>"
	  if $doc->getElementsByLocalName("ResourceProperty")->size() > 0;
	$ans =
	    "<GetResourcePropertyResponse xmlns='http://docs.oasis-open.org/wsrf/rp-2'>"
	  . $ans
	  . "</GetResourcePropertyResponse>"
	  unless $doc->getElementsByLocalName("ResourceProperty")->size() > 0;

	# return the header and the data
	return (
			 $self->_resource_property_header(
				  "GetMultipleResourceProperties/GetMultipleResourcePropertiesResponse",
				  $URL
			 ),
			 $ans
	) if $doc->getElementsByLocalName("ResourceProperty")->size() > 0;
	return (
			 $self->_resource_property_header(
								 "GetResourceProperty/GetResourcePropertyResponse", $URL
			 ),
			 $ans
	) unless $doc->getElementsByLocalName("ResourceProperty")->size() > 0;
}

#-----------------------------------------------------------------
# poll
#	takes in the moby-wsrf header and the XML message and checks
#		the status for the underlying wsrf resource.
#	return: the moby-wsrf header and XML representing the status
#		of the underlying wsrf resource.
#----------------------------------------------------------------

=head2

 Name       :    poll
 Function   :    polls the status of an asynchronous job
 Usage      :    $async->poll($header, $data);
 Args       :    $header - a string of XML representing the moby-wsrf header 
                 $data 	 - a string of XML representing the WSRF poll resource status call.

=cut

sub poll {

	my ( $self, $header, $data ) = @_;
	my $parser = XML::LibXML->new();
	my $doc;
	eval { $doc = $parser->parse_string($header); };

	# throw error if $@
	return
	  $self->create_fault( INVALID_RESOURCE_PROPERTY_QNAME_FAULT,
						   "", "moby-wsrf header was invalid:\n$@" )
	  if $@;

	# this the TO url that we need incase we throw a fault
	my $URL = $doc->getElementsByLocalName("To");

	# TODO throw error if $URL->size <= 0
	$URL = $URL->get_node(1)->textContent if $URL->size > 0;

	# get the service invocation id
	my $ID = $doc->getElementsByLocalName("ServiceInvocationId");

	# throw error if $ID->size() <= 0
	return
	  $self->create_fault( RESOURCE_UNKNOWN_FAULT, $URL,
						   "You neglected to provide a ServiceInvocationId" )
	  unless $ID->size > 0;
	# get the service invocation id
	$ID = $ID->get_node(1)->textContent if $ID->size > 0;
	$ID =~ s/ //gi;
	
	# TODO wrap in eval{}; because either lifetime expired or invalid ID!
	my $lock;
	eval {$lock = WSRF::MobyFile->new( undef, $ID );};
	return
	  $self->create_fault( RESOURCE_UNKNOWN_FAULT, $URL,
						   'Either the requested resource cannot be found or it\'s lifetime expired.' ) if $@;
	# get the query ids from the $data
	my @ids = @{ $self->_get_query_ids( $data, ":status_" ) };

	# throw error if no ids found
	return
	  $self->create_fault( RESOURCE_UNKNOWN_FAULT, $URL,
						   "No IDs in request for resource status update." )
	  unless scalar @ids;

	my $ans = '';
	foreach my $queryID (@ids) {
		my $property_status = "status_$queryID";
		# does our property exist? 
		# TODO - throw error if property doesnt exist so that we dont pass invalid XML
		$ans .= "<"
		  . $WSRF::WSRP::PropertyNamespaceMap->{$property_status}{prefix}
		  . ":$property_status";
		my $ns =
		  defined( $WSRF::WSRP::PropertyNamespaceMap->{$property_status}{namespace} )
		  ? " xmlns:"
		  . $WSRF::WSRP::PropertyNamespaceMap->{$property_status}{prefix} . "=\""
		  . $WSRF::WSRP::PropertyNamespaceMap->{$property_status}{namespace} . "\">"
		  : ">";
		$ans .= $ns;
		$ans .= $WSRF::WSRP::ResourceProperties{$property_status};
		$ans .= "</"
		  . $WSRF::WSRP::PropertyNamespaceMap->{$property_status}{prefix}
		  . ":$property_status>";
	}
	$lock->toFile();

	# parse the XML to see what kind of response we need to send back
	eval { $doc = $parser->parse_string($data); };

	$ans =
"<GetMultipleResourcePropertiesResponse xmlns='http://docs.oasis-open.org/wsrf/rp-2'>"
	  . $ans
	  . "</GetMultipleResourcePropertiesResponse>"
	  if $doc->getElementsByLocalName("ResourceProperty")->size() > 0;
	$ans =
	    "<GetResourcePropertyResponse xmlns='http://docs.oasis-open.org/wsrf/rp-2'>"
	  . $ans
	  . "</GetResourcePropertyResponse>"
	  unless $doc->getElementsByLocalName("ResourceProperty")->size() > 0;

	# return the header and the data
	return (
			 $self->_resource_property_header(
				  "GetMultipleResourceProperties/GetMultipleResourcePropertiesResponse",
				  $URL
			 ),
			 $ans
	) if $doc->getElementsByLocalName("ResourceProperty")->size() > 0;
	return (
			 $self->_resource_property_header(
								 "GetResourceProperty/GetResourcePropertyResponse", $URL
			 ),
			 $ans
	) unless $doc->getElementsByLocalName("ResourceProperty")->size() > 0;
}

#-----------------------------------------------------------------
# create_epr:
#    takes in a CGI variable
#    creates a WSRF file resource and returns the EPR for it
#-----------------------------------------------------------------

=head2

 Name       :    create_epr
 Function   :    creates an endpoint reference for the given CGI object
 Usage      :    $async->create_epr($cgi);
 Args       :    $cgi - a CGI variable

=cut

sub create_epr {
	my ( $self, $query ) = @_;

	# Get an identifier for the resource
	my $ID = WSRF::GSutil::CalGSH_ID();
	$ENV{ID} = $ID;

	# Create an EndpointReference for the resource
	my $EPR = WSRF::WS_Address->new();

	my ($proto) = ( $query->https() ) ? 'https' : 'http';
	my ($host)  = $query->virtual_host();
	my ($port)  = $query->virtual_port();
	if (    ( $proto eq 'http' && $port eq '80' )
		 || ( $proto eq 'https' && $port eq '443' ) )
	{
		$port = '';
	} else {
		$port = ':' . $port;
	}
	my ($relpath) = $query->script_name();
	my ($virtualrel) =
	     $ENV{'HTTP_VIA'}
	  || $ENV{'HTTP_FORWARDED'}
	  || $ENV{'HTTP_X_FORWARDED_FOR'};
	if ( defined($virtualrel)
		 && $virtualrel =~ /^(?:https?:\/\/[^:\/]+)?(?::[0-9]+)?(\/.*)/ )
	{
		$relpath = $1;
	}

	$EPR->Address("$proto://$host$port$relpath?asyncId=$ID");
	$EPR->ReferenceParameters(
				   '<wsa:ReferenceParameters><mobyws:ServiceInvocationId xmlns:mobyws="'
					 . $WSRF::Constants::MOBY . '">'
					 . $ENV{ID}
					 . '</mobyws:ServiceInvocationId></wsa:ReferenceParameters>' );
	$EPR = XML::LibXML->new->parse_string( $EPR->XML )->getDocumentElement->toString;

	# Write the properties to a file
	WSRF::File::toFile($ID);

	# strip newlines from the EPR
	$EPR =~ s/[\r\n]+//g;

	# Return the EndpointReference
	return $EPR;

}

#-----------------------------------------------------------------
# create_fault
#	creates a fault given a fault type and a service url.
#	return: the moby-wsrf header and the fault as XML
#-----------------------------------------------------------------

=head2

 Name       :    create_fault
 Function   :    creates a WSRF resource fault
 Usage      :    $async->create_fault($fault_type, $url);
 Args       :    $fault_type - one of C<RESOURCE_UNKNOWN_FAULT>, C<RESOURCE_UNAVAILABLE_FAULT>, C<RESOURCE_NOT_DESTROYED_FAULT> or C<INVALID_RESOURCE_PROPERTY_QNAME_FAULT> 
                 $url 	     - the service url
                 $desc		 - an optional message to include in the fault.

=cut

sub create_fault {

	# fault_type is the type of fault
	# service is the service URL
	my ( $self, $fault_type, $service, $m ) = @_;

	# create the timestamp
	my $timestamp = HTTP::Date::time2isoz();

	# get the fault details
	my $desc = $FAULT_DESCRIPTIONS{$fault_type} || "fault";
	my $name = $FAULT_NAMES{$fault_type}        || "BaseFault";
	$desc .= "\n$m" if defined $m;

	# create the fault
	my $msg = <<EOF;
<$name xmlns="http://docs.oasis-open.org/wsrf/bf-2">
    <Timestamp>$timestamp</Timestamp>  
	<Description>$desc</Description>  
</$name> 
EOF

	my $header = <<EOF;
<moby-wsrf>
  <wsa:From xmlns:wsa"http://www.w3.org/2005/08/addressing" wsa:Id="From">$service</wsa:From>
  <wsa:Action xmlns:wsa="http://www.w3.org/2005/08/addressing">http://docs.oasis-open.org/wsrf/fault</wsa:Action>
</moby-wsrf> 
EOF

	#remove the newlines
	$header =~ s/[\r\n]+//g;

	# return the $header and the data
	return $header, $msg;
}

#-----------------------------------------------------------------
# _resource_property_header
#	creates the moby-wsrf header given a $type
#		(one our FAULT constants) and a $url (the services URL).
#	return: a string of XML representing the moby-wsrf header
#-----------------------------------------------------------------
sub _resource_property_header {
	my ( $self, $type, $url ) = @_;
	return <<EOF;
<moby-wsrf>
  <From xmlns:wsu='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd' xmlns='http://www.w3.org/2005/08/addressing' wsu:Id="From">$url</From>  
  <Action xmlns='http://www.w3.org/2005/08/addressing'>http://docs.oasis-open.org/wsrf/rpw-2/$type</Action>
<moby-wsrf>
EOF
}

#-----------------------------------------------------------------
# _get_query_ids
# 	given $xml and $str, it searchs for query ids using $str as a
#      the prefix to search for and then takes all the text
#      afterwards
#	return: an array ref of query ids
#-----------------------------------------------------------------
sub _get_query_ids {
	my ( $self, $xml, $str ) = @_;
	my @ids;
	my $parser = XML::LibXML->new();
	my $doc;
	eval { $doc = $parser->parse_string($xml); };

	# return undef if there is invalid XML
	return @ids if $@;

	# check for one or more ResourceProperty elements
	my $nodes = $doc->getElementsByLocalName("ResourceProperty");
	if ( $nodes->size() > 0 ) {

		# extract the query ids
		for ( 1 ... $nodes->size() ) {
			my $id = $nodes->get_node($_)->textContent;
			if ( $id =~ m/\Q$str\E(.*)$/gi ) {
				push @ids, $1;
			}
		}
	}

	# check for the single GetResourceProperty element
	if ( $nodes->size == 0 ) {
		$nodes = $doc->getElementsByLocalName("GetResourceProperty");
		if ( $nodes->size() == 1 ) {

			# extract the single query id
			my $id = $nodes->get_node(1)->textContent;
			if ( $id =~ m/\Q$str\E(.*)$/gi ) {
				push @ids, $1;
			}
		}
	}
	return \@ids;
}

1;
__END__
