=pod

=head1 NAME

MOBY::Async::Service - an object for communicating with Asynchronous MOBY Services

=head1 AUTHORS

Former developer
Enrique de Andres Saiz (enrique.deandres@pcm.uam.es) -
INB GNHC-1 (Madrid Science Park, Spain) (2006-2007).

Maintainers
Jose Maria Fernandez (jmfernandez@cnio.es),
Jose Manuel Rodriguez (jmrodriguez@cnio.es) - 
INB GN2 (CNIO, Spain).

=head1 DESCRIPTION

It provides a class to invoke asynchronous services. Its use is very similar to
MOBY::Client::Service because it is its super-class. It also provides additional
methods in order to have more control over the asynchronous service execution.

=head1 METHODS

=head2 new

 Name       :    new
 Function   :    create a service connection.
 Usage      :    $Service = MOBY::Async::Service->new(@args)
 Args       :    service - string with a WSDL defining an asynchronous
                           MOBY service
 Returns    :    MOBY::Async::Service object, undef if no wsdl.

=head2 silent

 Name       :    silent
 Function   :    get/set silent mode; if silent is not set, status messages
                 reported when execute method is invoked.
 Usage      :    $Service->silent()
                 $Service->silent($boolean)
 Args       :    $boolean - 0 or 1 (default).
 Returns    :    0 or 1.

=head2 execute

 Name       :    execute
 Function   :    execute the asynchronous MOBY service; this method invoke
                 internally to the submit, poll and result methods. It
		 calculates polling time according to the status messages
		 received from the provider. If from that messages is not
		 possible to infer the polling time, it calculates a
		 pseudo-random polling time, whoose value increases until
		 is up to around 1 hour.
 Usage      :    $result = $Service->execute(%args)
 Args       :    XMLinputlist => \@data
 Returns    :    a MOBY message containing whatever the service provides
                 as output.
 Comment    :    for more information about arguments look up execute
                 method at MOBY::Client::Service.

=head2 enumerated_execute

 Name       :    enumerated_execute
 Function   :    execute the asynchronous MOBY service using self-enumerated
                 inputs; this method invoke internally to the enumerated_submit,
                 poll and result methods. It calculates polling time according
                 to the status messages received from the provider. If from
                 that messages is not possible to infer the polling time, it
                 calculates a pseudo-random polling time, whoose value increases
                 until is up to around 1 hour.
 Usage      :    $result = $Service->execute(%args)
 Args       :    Input => \%data
 Returns    :    a MOBY message containing whatever the service provides
                 as output.
 Comment    :    for more information about arguments look up enumerated_execute
                 method at MOBY::Client::Service.

=head2 submit

 Name       :    submit
 Function   :    submit the asynchronous MOBY service.
 Usage      :    ($EPR, @queryIDs) = $Service->submit(%args)
 Args       :    XMLinputlist => \@data
 Returns    :    WSRF::WS_Address object with an EPR and the input queryIDs.
 Comment    :    for more information about arguments look up execute
                 method at MOBY::Client::Service.

=head2 enumerated_submit

 Name       :    enumerated_submit
 Function   :    submit the asynchronous MOBY service using self-enumerated
                 inputs.
 Usage      :    ($EPR, @queryIDs) = $Service->submit(%args)
 Args       :    XMLinputlist => \%data
 Returns    :    WSRF::WS_Address object with an EPR and the input queryIDs.
 Comment    :    for more information about arguments look up enumerated_execute
                 method at MOBY::Client::Service.

=head2 poll

 Name       :    poll
 Function   :    gets the status of a set of queryIDs.
 Usage      :    @status = $Service->poll($EPR, @queryIDs)
 Args       :    $EPR      - WSRF::WS_Address object.
                 @queryIDs - an array containing queryIDs values.
 Returns    :    an array of LSAE::AnalysisEventBlock objects.

=head2 result

 Name       :    result
 Function   :    get the result of a set of queryIDs.
 Usage      :    @result = $Service->result($EPR, @queryIDs)
 Args       :    $EPR      - WSRF::WS_Address object.
                 @queryIDs - an array containing queryIDs values.
 Returns    :    an array of MOBY messages.

=head2 destroy

 Name       :    destroy
 Function   :    destroy the resource associated to the execution of
                 an asynchronous MOBY service.
 Usage      :    $Service->result($EPR);
 Args       :    $EPR - WSRF::WS_Address object.
 Returns    :    nothing.

=cut

package MOBY::Async::Service;
use strict;
use XML::LibXML;
use MOBY::Async::WSRF;
use MOBY::Async::LSAE;
use MOBY::CommonSubs qw(:all);
use MOBY::Client::Service;
use base qw(MOBY::Client::Service);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

sub _getPollingTime($$$@);
sub _getServiceEndpoint($);
sub _getPseudoRandomPollingTime($$);
sub _composeResponse(@);

sub new {
	my ($this, %args) = @_;
	my $class = ref($this) || $this;
	
	my $self = $class->SUPER::new(%args);
	$self->{silent} = 1;
	
	bless $self, $class;
	return $self;
}

sub silent {
	my $self = shift;
	$self->{silent} = shift;
	return $self->{silent};
}

=head2 raw_execute

Calls the service asynchronously with the given scalar XML input. Behaves exactly as C<execute>.

=cut

sub raw_execute {
	my ($self, $input) = @_;
	
	my $start = time;
	my ($EPR, @queryIDs) = $self->raw_submit($input);
	
	my $pollingTime;
	my ($i, $j) = (0, 1);
	my @status;
	while ( $pollingTime = _getPollingTime($i, $j, $start, @status) ) {
		($i, $j) = ($j, $i+$j);
		
		print "(next polling in $pollingTime seconds)\n\n" unless ($self->{silent});
		
		sleep $pollingTime;
		@status = $self->poll($EPR, @queryIDs);
		
		unless ($self->{silent}) {
			foreach my $st (@status) {
				print $st->XML."\n";
			}
			print "\n";
		}
	}
	
	my @responses = $self->result($EPR, @queryIDs);
	$self->destroy($EPR);
	my $response = _composeResponse(@responses);
	
	print "Finished.\n\n" unless ($self->{silent});
	
	return $response;
}

sub execute {
	my ($self, %args) = @_;
	
	my $start = time;
	my ($EPR, @queryIDs) = $self->submit(%args);
	
	my $pollingTime;
	my ($i, $j) = (0, 1);
	my @status;
	while ( $pollingTime = _getPollingTime($i, $j, $start, @status) ) {
		($i, $j) = ($j, $i+$j);
		
		print "(next polling in $pollingTime seconds)\n\n" unless ($self->{silent});
		
		sleep $pollingTime;
		@status = $self->poll($EPR, @queryIDs);
		
		unless ($self->{silent}) {
			foreach my $st (@status) {
				print $st->XML."\n";
			}
			print "\n";
		}
	}
	
	my @responses = $self->result($EPR, @queryIDs);
	$self->destroy($EPR);
	my $response = _composeResponse(@responses);
	
	print "Finished.\n\n" unless ($self->{silent});
	
	return $response;
}

sub submit {
	my ($self, %args) = @_;
	
	print "Creating WS-Resource...\n\n" unless ($self->{silent});
	
	# Compose the moby message (part of this block is copied from MOBY::Client::Service)
  	die "ERROR:  expected listref for XMLinputlist" unless ( ref( $args{XMLinputlist} ) eq 'ARRAY' );
	my @inputs = @{ $args{XMLinputlist} };
	my @queryIDs;
	my $data;
	foreach ( @inputs ) {
	
		die "ERROR:  expected listref [articleName, XML] for data element" unless ( ref( $_ ) eq 'ARRAY' );
		my $qID = $self->_nextQueryID;
		push (@queryIDs, $qID);
		$data .= "<moby:mobyData queryID='$qID'>";
		
		while ( my ( $articleName, $XML ) = splice( @{$_}, 0, 2 ) ) {
			
			$articleName ||= "";
			if (  ref( $XML ) ne 'ARRAY' ) {
				
				$XML ||= "";
				if ( $XML =~ /\<(moby\:|)Value\>/ ) {
					$data .= "<moby:Parameter moby:articleName='$articleName'>$XML</moby:Parameter>";
				} else {
					$data .= "<moby:Simple moby:articleName='$articleName'>\n$XML\n</moby:Simple>\n";
				}
				
			} elsif ( ref( $XML ) eq 'ARRAY' ) {
				
				my @objs = @{$XML};
				$data .= "<moby:Collection moby:articleName='$articleName'>\n";
				foreach ( @objs ) {
					$data .= "<moby:Simple>$_</moby:Simple>\n";
				}
				$data .= "</moby:Collection>\n";
			}
		}
		$data .= "</moby:mobyData>\n";
	}
	my $version = $self->{smessageVersion};
	$data = "<?xml version='1.0' encoding='UTF-8'?>
	<moby:MOBY moby:smessageVersion='$version' xmlns:moby='$WSRF::Constants::MOBY_MESSAGE_NS' xmlns='$WSRF::Constants::MOBY_MESSAGE_NS'>
	      <moby:mobyContent>
	          $data
	      </moby:mobyContent>
	</moby:MOBY>";
	
	# Create the resource and submit the batch-call
	my $func = $self->{serviceName}.'_submit';
	my $ans = WSRF::Lite
		-> proxy(_getServiceEndpoint($self->{service}))
		-> uri($WSRF::Constants::MOBY)
		-> $func(SOAP::Data->value($data)->type('string'));
	die "ERROR:  ".$ans->faultstring if ($ans->fault);
	
	# Get address from the returned Endpoint Reference
	my $address = $ans->match("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}Address") ?
	              $ans->valueof("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}Address") :
	              die "ERROR:  no EndpointReference returned";
	die "ERROR:  no address into returned EndpointReference" unless ($address);
	
	# Get resource identifier from the returned Endpoint Reference
	my $identifier;
	if ($ans->dataof("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}ReferenceParameters/*")) {
		foreach my $a ($ans->dataof("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}ReferenceParameters/*")) {
			my $name  = $a->name();
			my $uri   = $a->uri();
			my $value = $a->value();
			if ($name eq "ServiceInvocationId" && $uri eq $WSRF::Constants::MOBY) {
				$identifier = $value;
				last;
			}
		}
	}
	die "ERROR:  no identifier into returned EndpointReference" unless ($identifier);
	
	# Compose the Endpoint Reference
	my $EPR = WSRF::WS_Address->new();
	$EPR->Address($address);
	$EPR->ReferenceParameters('<mobyws:ServiceInvocationId xmlns:mobyws="'.$WSRF::Constants::MOBY.'">'.$identifier.'</mobyws:ServiceInvocationId>');
	
	print XML::LibXML->new->parse_string($EPR->XML)->getDocumentElement()->toString."\n\n" unless ($self->{silent});
	
	$SIG{TERM} = sub {
		$self->destroy($EPR);
		print "Finished.\n\n" unless ($self->{silent});
		exit;
	};
	$SIG{INT} = sub {
		$self->destroy($EPR);
		print "Finished.\n\n" unless ($self->{silent});
		exit;
	};
	
	# Return Endpoint Reference and the queryIDs
	return ($EPR, @queryIDs);
}

sub raw_submit {
	my ($self, $xml) = @_;
	
	print "Creating WS-Resource...\n\n" unless ($self->{silent});
	
	my @queryIDs = $self->_get_query_ids($xml);
	my $data = $xml;
	
	# Create the resource and submit the batch-call
	my $func = $self->{serviceName}.'_submit';
	my $ans = WSRF::Lite
		-> proxy(_getServiceEndpoint($self->{service}))
		-> uri($WSRF::Constants::MOBY)
		-> $func(SOAP::Data->value($data)->type('string'));
	die "ERROR:  ".$ans->faultstring if ($ans->fault);
	
	# Get address from the returned Endpoint Reference
	my $address = $ans->match("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}Address") ?
	              $ans->valueof("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}Address") :
	              die "ERROR:  no EndpointReference returned";
	die "ERROR:  no address into returned EndpointReference" unless ($address);
	
	# Get resource identifier from the returned Endpoint Reference
	my $identifier;
	if ($ans->dataof("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}ReferenceParameters/*")) {
		foreach my $a ($ans->dataof("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}ReferenceParameters/*")) {
			my $name  = $a->name();
			my $uri   = $a->uri();
			my $value = $a->value();
			if ($name eq "ServiceInvocationId" && $uri eq $WSRF::Constants::MOBY) {
				$identifier = $value;
				last;
			}
		}
	}
	die "ERROR:  no identifier into returned EndpointReference" unless ($identifier);
	
	# Compose the Endpoint Reference
	my $EPR = WSRF::WS_Address->new();
	$EPR->Address($address);
	$EPR->ReferenceParameters('<mobyws:ServiceInvocationId xmlns:mobyws="'.$WSRF::Constants::MOBY.'">'.$identifier.'</mobyws:ServiceInvocationId>');
	
	print XML::LibXML->new->parse_string($EPR->XML)->getDocumentElement()->toString."\n\n" unless ($self->{silent});
	
	$SIG{TERM} = sub {
		$self->destroy($EPR);
		print "Finished.\n\n" unless ($self->{silent});
		exit;
	};
	$SIG{INT} = sub {
		$self->destroy($EPR);
		print "Finished.\n\n" unless ($self->{silent});
		exit;
	};
	
	# Return Endpoint Reference and the queryIDs
	return ($EPR, @queryIDs);
}

sub _get_query_ids {
	my ($self, $input) = @_;
	my @query_ids = ();
	my $parser    = XML::LibXML->new();
	my $doc       = $parser->parse_string($input);
	my $iterator  = $doc->getElementsByLocalName("mobyData");
	for ( 1 .. $iterator->size() ) {
		my $node = $iterator->get_node($_);
		my $id   = $node->getAttribute("queryID")
		  || $node->getAttribute(
				 $node->lookupNamespacePrefix($WSRF::Constants::MOBY_MESSAGE_NS)
				   . ":queryID" );
		push @query_ids, $id;
	}
	return @query_ids;
}

sub enumerated_execute {
	my ($self, %args) = @_;
	
	my $start = time;
	my ($EPR, @queryIDs) = $self->enumerated_submit(%args);
	
	my $pollingTime;
	my ($i, $j) = (0, 1);
	my @status;
	while ( $pollingTime = _getPollingTime($i, $j, $start, @status) ) {
		($i, $j) = ($j, $i+$j);
		
		print "(next polling in $pollingTime seconds)\n\n" unless ($self->{silent});
		
		sleep $pollingTime;
		@status = $self->poll($EPR, @queryIDs);
		
		unless ($self->{silent}) {
			foreach my $st (@status) {
				print $st->XML."\n";
			}
			print "\n";
		}
	}
	
	my @responses = $self->result($EPR, @queryIDs);
	$self->destroy($EPR);
	my $response = _composeResponse(@responses);
	
	print "Finished.\n\n" unless ($self->{silent});
	
	return $response;
}

sub enumerated_submit {
	my ($self, %args) = @_;
	
	print "Creating WS-Resource...\n\n" unless ($self->{silent});
	
	# Compose the moby message (part of this block is copied from MOBY::Client::Service)
	die "ERROR:  expected Input to be a HASH ref" unless ( ref( $args{Input} ) eq 'HASH' );
	my %inputs = %{$args{Input}};
	my @queryIDs = keys %inputs;
	my $data;
	foreach my $qID ( @queryIDs ) {
	
		die "ERROR:  expected hashref {articleName => XML} for each queryID" unless ( ref($inputs{$qID}) eq 'HASH' );
		my %articles = %{$inputs{$qID}};
		$data .= "<moby:mobyData queryID='$qID'>";
		
		foreach my $articleName(keys %articles){
			
			my $XML = $articles{$articleName};
			if (  ref( $XML ) ne 'ARRAY' ) {
				
				$XML ||= "";
				if ( $XML =~ /\<(moby\:|)Value\>/ ){
					$data .= "<moby:Parameter moby:articleName='$articleName'>$XML</moby:Parameter>";
				} else {
					$data .= "<moby:Simple moby:articleName='$articleName'>\n$XML\n</moby:Simple>\n";
				}
				
			} elsif ( ref( $XML ) eq 'ARRAY' ) {
				
				my @objs = @{$XML};
				$data .= "<moby:Collection moby:articleName='$articleName'>\n";
				foreach ( @objs ) {
					$data .= "<moby:Simple>$_</moby:Simple>\n";
				}
				$data .= "</moby:Collection>\n";
			}
		}
		$data .= "</moby:mobyData>\n";
	}
	my $version = $self->{smessageVersion};
	$data = "<?xml version='1.0' encoding='UTF-8'?>
	<moby:MOBY moby:smessageVersion='$version' xmlns='$WSRF::Constants::MOBY_MESSAGE_NS' xmlns:moby='$WSRF::Constants::MOBY_MESSAGE_NS'>
	      <moby:mobyContent>
	          $data
	      </moby:mobyContent>
	</moby:MOBY>";
	
	# Create the resource and submit the batch-call
	my $func = $self->{serviceName}.'_submit';
	my $ans = WSRF::Lite
		-> proxy(_getServiceEndpoint($self->{service}))
		-> uri($WSRF::Constants::MOBY)
		-> $func(SOAP::Data->value($data)->type('string'));
	die "ERROR:  ".$ans->faultstring if ($ans->fault);
	
	# Get address from the returned Endpoint Reference
	my $address = $ans->match("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}Address") ?
	              $ans->valueof("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}Address") :
	              die "ERROR:  no EndpointReference returned";
	die "ERROR:  no address into returned EndpointReference" unless ($address);
	
	# Get resource identifier from the returned Endpoint Reference
	my $identifier;
	if ($ans->dataof("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}ReferenceParameters/*")) {
		foreach my $a ($ans->dataof("//{$SOAP::Constants::NS_ENV}Body//{$WSRF::Constants::WSA}ReferenceParameters/*")) {
			my $name  = $a->name();
			my $uri   = $a->uri();
			my $value = $a->value();
			if ($name eq "ServiceInvocationId" && $uri eq $WSRF::Constants::MOBY) {
				$identifier = $value;
				last;
			}
		}
	}
	die "ERROR:  no identifier into returned EndpointReference" unless ($identifier);
	
	# Compose the Endpoint Reference
	my $EPR = WSRF::WS_Address->new();
	$EPR->Address($address);
	$EPR->ReferenceParameters('<mobyws:ServiceInvocationId xmlns:mobyws="'.$WSRF::Constants::MOBY.'">'.$identifier.'</mobyws:ServiceInvocationId>');
	
	print XML::LibXML->new->parse_string($EPR->XML)->getDocumentElement()->toString."\n\n" unless ($self->{silent});
	
	$SIG{TERM} = sub {
		$self->destroy($EPR);
		print "Finished.\n\n" unless ($self->{silent});
		exit;
	};
	$SIG{INT} = sub {
		$self->destroy($EPR);
		print "Finished.\n\n" unless ($self->{silent});
		exit;
	};
	
	# Return Endpoint Reference and the queryIDs
	return ($EPR, @queryIDs);
}

sub poll {
	my ($self, $EPR, @queryIDs) = @_;
	
	print "Polling...\n\n" unless ($self->{silent});
	
	my $searchTerm = "";
	foreach my $queryID (@queryIDs) {
		#$searchTerm .= "<wsrp:ResourceProperty xmlns:wsrp='$WSRF::Constants::WSRP' xmlns:mobyws='$WSRF::Constants::MOBY'>";
		#$searchTerm .= "mobyws:status_".$queryID;
		#$searchTerm .= "</wsrp:ResourceProperty>"; 
		$searchTerm .= "<wsrp:ResourceProperty xmlns:wsrp='$WSRF::Constants::WSRP' xmlns:mobyws='$WSRF::Constants::MOBY'>";
		$searchTerm .= "mobyws:status_".$queryID;
		$searchTerm .= "</wsrp:ResourceProperty>"; 
	}
	
#	my $ans = WSRF::Lite
#		-> uri($WSRF::Constants::WSRPW)
#		-> on_action( sub {sprintf '%s/%s', @_} )
#		-> wsaddress($EPR)
#		-> GetMultipleResourceProperties(SOAP::Data->value($searchTerm)->type('xml'));
	my $ans = WSRF::Lite
		-> uri($WSRF::Constants::WSRP)
		-> on_action( sub {sprintf '%s/%s/%sRequest', $WSRF::Constants::WSRPW,$_[1],$_[1]} )
		-> wsaddress($EPR)
		-> GetMultipleResourceProperties(SOAP::Data->value($searchTerm)->type('xml'));
	die "ERROR:  ".$ans->faultstring if ($ans->fault);
	
	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_string($ans->raw_xml);
	my $soap = $doc->getDocumentElement();
	
	my @ans;
	foreach my $queryID (@queryIDs) {
		my $prop_name = "status_".$queryID;
		
		my ($prop) = $soap->getElementsByTagNameNS($WSRF::Constants::MOBY, $prop_name);
		my $event = $prop->getFirstChild->toString;
		my $status = LSAE::AnalysisEventBlock->new($event);
		push(@ans, $status);
	}
	
	return @ans;
}

sub result {
	my ($self, $EPR, @queryIDs) = @_;
	
	print "Retrieving results...\n\n" unless ($self->{silent});
	
	my $searchTerm = "";
	foreach my $queryID (@queryIDs) {
		$searchTerm .= "<wsrp:ResourceProperty xmlns:wsrp='$WSRF::Constants::WSRP' xmlns:mobyws='$WSRF::Constants::MOBY'>";
		$searchTerm .= "mobyws:result_".$queryID;
		$searchTerm .= "</wsrp:ResourceProperty>"; 
	}
	
	my $ans = WSRF::Lite
		-> uri($WSRF::Constants::WSRP)
		-> on_action( sub {sprintf '%s/%s/%sRequest', $WSRF::Constants::WSRPW,$_[1],$_[1]} )
		-> wsaddress($EPR)   
		-> GetMultipleResourceProperties(SOAP::Data->value($searchTerm)->type('xml'));
	die "ERROR:  ".$ans->faultstring if ($ans->fault);
	
	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_string($ans->raw_xml);
	my $soap = $doc->getDocumentElement();
	
	my @ans;
	foreach my $queryID (@queryIDs) {
		my $prop_name = "result_".$queryID;
		
		my ($prop) = $soap->getElementsByTagNameNS($WSRF::Constants::MOBY, $prop_name);
		my $result = $prop->getFirstChild->toString;
		push(@ans, $result);
	}
	
	return @ans;
}

sub destroy {
	my ($self, $EPR) = @_;
	
	print "Destroying WS-Resource...\n\n" unless ($self->{silent});
	
	my $ans = WSRF::Lite
		-> uri($WSRF::Constants::WSRL)
		-> on_action( sub {sprintf '%s/ImmediateResourceTermination/%sRequest', $WSRF::Constants::WSRLW,$_[1]} )
		-> wsaddress($EPR)
		-> Destroy();
	die "ERROR:  ".$ans->faultstring if ($ans->fault);
}

sub _getServiceEndpoint($) {
	my ($wsdl) = @_;
	
	$wsdl =~ /address location\s*=\s*["|'](.+)["|']/;
	my $serviceEndpoint = $1;
	
	return $serviceEndpoint;
}

sub _getPollingTime($$$@) {
	my ($i, $j, $start, @status) = @_;
	
	return _getPseudoRandomPollingTime($i, $j) unless (scalar(@status));
	
	my $pollingTime = 0;
	foreach my $status (@status) {
		my $pTime;
		
		if ($status->type == LSAE_PERCENT_PROGRESS_EVENT) {
			if ($status->percentage >= 100) {
				
				$pTime = 0;
				
			} elsif ($status->percentage < 100) {
				
				$pTime = int( ( (100 - $status->percentage) * (time - $start) ) / $status->percentage ) + 1;
				
			} else {
				die "ERROR:  analysis event block not well formed.\n";
			}
			
		} elsif ($status->type == LSAE_STATE_CHANGED_EVENT) {
			if ( ($status->new_state eq "completed") ||
			     ($status->new_state eq "COMPLETED") ||
			     ($status->new_state eq "terminated_by_request") ||
			     ($status->new_state eq "TERMINATED_BY_REQUEST") ||
			     ($status->new_state eq "terminated_by_error") ||
			     ($status->new_state eq "TERMINATED_BY_ERROR") ) {
				
				$pTime = 0;
				
			} elsif ( ($status->new_state eq "created") ||
			          ($status->new_state eq "CREATED") ||
			          ($status->new_state eq "running") ||
			          ($status->new_state eq "RUNNING") ) {
				
				$pTime = _getPseudoRandomPollingTime($i, $j);
				
			} else {
				die "ERROR:  analysis event block not well formed.\n";
			}
			
		} elsif ($status->type == LSAE_STEP_PROGRESS_EVENT) {
			if ($status->steps_completed >= $status->total_steps) {
				
				$pTime = 0;
				
			} elsif ($status->steps_completed < $status->total_steps) {
				
				$pTime = int ( ( ($status->total_steps - $status->steps_completed) * (time - $start) ) / $status->steps_completed ) + 1;
				
			} else {
				die "ERROR:  analysis event block not well formed.\n";
			}
			
		} elsif ($status->type == LSAE_TIME_PROGRESS_EVENT) {
			if ($status->remaining == 0) {
				
				$pTime = 0;
				
			} elsif ($status->remaining > 0) {
				
				$pTime = $status->remaining;
				
			} else {
				die "ERROR:  analysis event block not well formed.\n";
			}
		}
		
		$pollingTime = $pTime if ($pTime > $pollingTime);
	}
	
	return $pollingTime;
}

sub _getPseudoRandomPollingTime($$) {
	my ($i, $j) = @_;
	my $c = 15;
	my $p = 0.1;
	my $k = $i + $j;
	$k = 240 if ($k > 240);
	my $delay = ($c*$k) + int(rand(int(2*$p*$c*$k))) - int($p*$c*$k);
	return $delay;
}

sub _composeResponse(@) {
	my (@datas) = @_;
	
	my @authorities;
	my @exceptions;
	my @queries;
	
	foreach my $data (@datas) {
		
		# Get moby document
		my $parser = XML::LibXML->new();
		my $doc = $parser->parse_string($data);
		my $moby = $doc->getDocumentElement();
		
		# Get authority
		my @mobyContents = ($moby->getChildrenByTagNameNS($WSRF::Constants::MOBY_MESSAGE_NS, 'mobyContent'));
		my $mobyContent = shift(@mobyContents);
		my $authority = $mobyContent->getAttribute('authority') || $mobyContent->getAttributeNS($WSRF::Constants::MOBY_MESSAGE_NS, 'authority');
		push(@authorities, $authority);
		
		# Get exceptions
		my @mobyException = ($moby->getElementsByTagNameNS($WSRF::Constants::MOBY_MESSAGE_NS, 'mobyException'));
		foreach my $mobyException (@mobyException) {
			push(@exceptions, $mobyException->toString());
		}
		
		# Get queries
		my @mobyData = ($moby->getElementsByTagNameNS($WSRF::Constants::MOBY_MESSAGE_NS, 'mobyData'));
		foreach my $mobyData (@mobyData) {
			push(@queries, $mobyData->toString());
		}
	}
	
	my $moby;
	$moby  = responseHeader(shift(@authorities));
	$moby .= "<moby:serviceNotes xmlns:moby='$WSRF::Constants::MOBY_MESSAGE_NS'>".join("", @exceptions)."</moby:serviceNotes>" if (scalar(@exceptions));
	$moby .= join("", @queries) if (scalar(@queries));
	$moby .= responseFooter();
	
	return $moby;
}

1;
