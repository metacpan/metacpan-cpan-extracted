=pod

=head1 NAME

MOBY::Async::SimpleServer - a base class for simple Asynchronous MOBY Services

=head1 AUTHORS

Former developer
Enrique de Andres Saiz (enrique.deandres@pcm.uam.es) -
INB GNHC-1 (Madrid Science Park, Spain) (2006-2007).

Maintainers
Jose Maria Fernandez (jmfernandez@cnio.es),
Jose Manuel Rodriguez (jmrodriguez@cnio.es) - 
INB GN2 (CNIO, Spain).


=head1 DESCRIPTION

Provides a simple class that can be extended to build file based asynchronous
services. When submission, these services will just fork the a process,
returning inmediately and leaving running the service in background. They store
the state information in a file.

This class provides the WS-ResourceProperty and WS-ResourceLifetime methods
required for Asynchronous MOBY Services:

=over

=item WS-ResourceProperty:

 GetResourceProperty
 GetMultipleResourceProperties

=item WS-ResourceLifetime:

 Destroy

=back

Additionally, this class provides other methods in order to carry up
synchronous or asynchronous request of the service.

=head1 METHODS

=head2 sync

 Name       :    sync
 Function   :    answers synchronous requests of asynchronous BioMOBY
                 services; it tries to execute the service; if execution
		 time exceeds a defined timeout, it returns a moby exception
		 suggesting to invoke the service asynchronously.
 Usage      :    sub servicename {
                   my $self = shift @_;
                   return $self->sync($func, $timeout, @_);
                 }
 Args       :    $func    - the subroutine which carries out the service.
                 $timeout - the allowed timeout in seconds.
		 @_       - the parameters received from the client.
 Returns    :    a SOAP response containing a MOBY message.

=head2 error

 Name       :    error
 Function   :    answers synchronous requests of asynchronous BioMOBY
                 services; it just returns a moby exception indicating
		 that the service must be invoked asynchronously.
 Usage      :    sub servicename {
                   my $self = shift @_;
                   return $self->error(@_);
                 }
 Args       :    @_ - the parameters received from the client.
 Returns    :    a SOAP response containing a MOBY message.

=head2 async

 Name       :    async
 Function   :    answers asynchronous requests of asynchronous BioMOBY
                 services.
 Usage      :    sub servicename_submit {
                   my $self = shift @_;
                   return $self->async($func, @_);
                 }
 Args       :    $func - the subroutine which carries out the service.
                 @_    - the parameters received from the client.
 Returns    :    a SOAP response containing an EPR.

=cut

package MOBY::Async::SimpleServer;
use strict;
use CGI;
use XML::LibXML;
use POSIX qw(setsid);
use MOBY::CommonSubs qw(:all);
use MOBY::Async::LSAE;
use MOBY::Async::WSRF;

use base qw(WSRF::FileBasedMobyResourceLifetimes);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;

#===============================================================================
# async_create
#
# This variable is a subroutine which creates a WS-Resource and returns
# an EPR associated to it.
#
my $async_create = sub {
	my $class = shift @_;
	my $envelope = pop @_;
	
	# Get an identifier for the resource
	my $ID = WSRF::GSutil::CalGSH_ID();
	$ENV{ID} = $ID;
	
	# Create an EndpointReference for the resource
	my $EPR = WSRF::WS_Address->new();

        my($query)=CGI->new();
        my($proto)=($query->https())?'https':'http';
        my($host)=$query->virtual_host();
	# This line is needed to fix a bug in CGI library
	# which only appears when the server is living behind
	# more than one proxy
	$host =~ s/^([^,]+),.*/$1/;
        my($port)=$query->virtual_port();
	if(($proto eq 'http' && $port eq '80') || ($proto eq 'https' && $port eq '443')) {
		$port='';
	} else {
		$port = ':'.$port;
	}
        my($relpath)=$query->script_name();
        my($virtualrel)=$ENV{'HTTP_VIA'} || $ENV{'HTTP_FORWARDED'} || $ENV{'HTTP_X_FORWARDED_FOR'};
        if(defined($virtualrel) && $virtualrel =~ /^(?:https?:\/\/[^:\/]+)?(?::[0-9]+)?(\/.*)/) {
                $relpath=$1;
        }

	$EPR->Address("$proto://$host$port$relpath?asyncId=$ID");
	#$EPR->Address("http://".$ENV{SERVER_NAME}.$ENV{SCRIPT_NAME});
	$EPR->ReferenceParameters('<wsa:ReferenceParameters><mobyws:ServiceInvocationId xmlns:mobyws="'.$WSRF::Constants::MOBY.'">'.$ENV{ID}.'</mobyws:ServiceInvocationId></wsa:ReferenceParameters>');
	$EPR = XML::LibXML->new->parse_string($EPR->XML)->getDocumentElement->toString;
	
	# Write the properties to a file
	WSRF::File::toFile($ID);
	
	# Return the EndpointReference
	return WSRF::Header::header($envelope), SOAP::Data->uri($WSRF::Constants::MOBY)
						->name('body' => \SOAP::Data->value(
							SOAP::Data->type('xml'=>$EPR)
							)
						);
};

#===============================================================================
# async_submit
# 
# This variable is a subroutine which submits a batch-call and returns all
# status properties.
#
my $async_submit = sub {
	my $class = shift @_;
	my $envelope = pop @_;
	my ($func, $data) = @_;
	
	# Get input queryIDs and store them
	my $ID=$ENV{ID};
	my $lock = WSRF::MobyFile->new($envelope,$ID);
	my $inputs = serviceInputParser($data);
	my @queryIDs = keys %$inputs;
	$WSRF::WSRP::Private{queryIDs} = \@queryIDs;
	$lock->toFile();
	
	# Get moby document
	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_string($data);
	my $moby = $doc->getDocumentElement();
	
	# Get authority
	my @mobyContents = ($moby->getChildrenByTagNameNS($WSRF::Constants::MOBY_MESSAGE_NS,'mobyContent'));
	my $mobyContent = shift(@mobyContents);
	my $auth = $mobyContent->getAttribute('authority') || $mobyContent->getAttributeNS($WSRF::Constants::MOBY_MESSAGE_NS,'authority');
	
	# Get mobyData and iterate over them in order to run the service for each one
	my @mobyData = ($mobyContent->getChildrenByTagNameNS($WSRF::Constants::MOBY_MESSAGE_NS,'mobyData'));

	foreach my $mobyData (@mobyData) {
		# This line avoids a serialization bug in XML::LibXML, which probably
		# is inherited from libxml2
		$mobyData->setNamespace($WSRF::Constants::MOBY_MESSAGE_NS, $mobyData->prefix(), 0);
		my $queryID = $mobyData->getAttribute('queryID') || $mobyData->getAttributeNS($WSRF::Constants::MOBY_MESSAGE_NS,'queryID');
		my $property_pid    = "pid_$queryID";
		my $property_input  = "input_$queryID";
		my $property_status = "status_$queryID";
		my $property_result = "result_$queryID";
		
		# Check if service is running or not
		my $lock = WSRF::MobyFile->new($envelope,$ID);
		if ($WSRF::WSRP::Private{$property_pid}) {
			$lock->toFile();
		} else {
			
			# Input
			my $parser = XML::LibXML->new();
			my $doc = $parser->parse_string(responseHeader($auth).$mobyData->toString().responseFooter());
			my $input = $doc->getDocumentElement->toString;
			
			# Fork
			unless (defined( my $pid = fork() )) {
				
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
				my $result;
				$result  = responseHeader($ENV{AUTHURI});
				$result .= "<serviceNotes xmlns='$WSRF::Constants::MOBY_MESSAGE_NS'><mobyException refQueryID=\'$queryID\' severity=\'error\'>";
				$result .= "<exceptionCode>701</exceptionCode>";
				$result .= "<exceptionMessage>Unable to submit job.</exceptionMessage>";
				$result .= "</mobyException>";
				$result .= "</serviceNotes>";
				$result .= simpleResponse('', '', $queryID) . responseFooter();
				$result  = XML::LibXML->new()->parse_string($result)->getDocumentElement()->toString();
				
				# New properties values
				$WSRF::WSRP::Private{$property_pid}  = '';
				$WSRF::WSRP::Private{$property_input} = $input;
				$WSRF::WSRP::ResourceProperties{$property_status} = $status->XML();
				$WSRF::WSRP::ResourceProperties{$property_result} = $result;
				$lock->toFile();
			
			} elsif ( $pid ) {
				
				#-----------------------------------------------------#
				# Fork has had success and this is the parent process #
				#-----------------------------------------------------#
				
				# Status
				my $status;
				if ($WSRF::WSRP::ResourceProperties{$property_status}) {
					
					# This is not the first execution of the service for this queryID
					# Previous state is the new state of the previous execution
					my $old_status = LSAE::AnalysisEventBlock->new($WSRF::WSRP::ResourceProperties{$property_status});
					$status = LSAE::AnalysisEventBlock->new();
					$status->type(LSAE_STATE_CHANGED_EVENT);
					$status->previous_state($old_status->new_state());
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
				$WSRF::WSRP::Private{$property_pid} = 'undef';
				$WSRF::WSRP::Private{$property_input} = $input;
				$WSRF::WSRP::ResourceProperties{$property_status} = $status->XML();
				$WSRF::WSRP::ResourceProperties{$property_result} = '';
				$lock->toFile();
				
			} else {
				
				#----------------------------------------------------#
				# Fork has had success and this is the child process #
				#----------------------------------------------------#
				
				# Daemonize 
				open STDIN, "/dev/null";
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
				$lock = WSRF::MobyFile->new($envelope,$ID);
				$WSRF::WSRP::Private{$property_pid} = $$;
				$WSRF::WSRP::ResourceProperties{$property_status} = $status->XML();
				$WSRF::WSRP::ResourceProperties{$property_result} = '';
				$lock->toFile();
				
				# Run service
				my $result;
				eval {
					my $xml = $func->($class, $input);
					if(UNIVERSAL::isa($xml,'XML::LibXML::Document')) {
						$result=$xml->getDocumentElement()->toString();
					} elsif(UNIVERSAL::isa($xml,'XML::LibXML::Node')) {
						$result=$xml->toString();
					} else {
						my $parser = XML::LibXML->new();
						my $toparse;
						if(ref(\$xml) eq 'SCALAR') {
							$toparse=$xml;
						} elsif(UNIVERSAL::isa($xml,'SOAP::Data')) {
							$toparse=$xml->value();
						} else {
							die "FATAL ERROR: Unable to handle result type ".ref($xml);
						}
						my $doc = $parser->parse_string($toparse);
						$result = $doc->getDocumentElement()->toString();
					}
				};
				
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
					
					# Result
					$result  = responseHeader($ENV{AUTHURI});
					$result .= "<serviceNotes xmlns='$WSRF::Constants::MOBY_MESSAGE_NS'><mobyException refQueryID=\'$queryID\' severity=\'error\'>";
					$result .= "<exceptionCode>701</exceptionCode>";
					$result .= "<exceptionMessage>Error while executing job.</exceptionMessage>";
					$result .= "</mobyException>";
					$result .= "</serviceNotes>";
					$result .= simpleResponse('', '', $queryID) . responseFooter();
					$result  = XML::LibXML->new()->parse_string($result)->getDocumentElement()->toString();
				}
				
				# New properties values
				$lock = WSRF::MobyFile->new($envelope,$ID);
				$WSRF::WSRP::Private{$property_pid} = '';
				$WSRF::WSRP::ResourceProperties{$property_status} = $status->XML();
				$WSRF::WSRP::ResourceProperties{$property_result} = $result;
				$lock->toFile();
				
				# Exits the child process
				exit;
			}
		}
	}
	
	# Compose response using the status properties
	$lock = WSRF::MobyFile->new($envelope,$ID);
	my $ans = '';
	foreach my $queryID (@queryIDs) {
		my $property_status = "status_$queryID";
		$ans .= "<".$WSRF::WSRP::PropertyNamespaceMap->{$property_status}{prefix}.":$property_status";
		my $ns = defined($WSRF::WSRP::PropertyNamespaceMap->{$property_status}{namespace}) ?
			" xmlns:".$WSRF::WSRP::PropertyNamespaceMap->{$property_status}{prefix}."=\"".
			$WSRF::WSRP::PropertyNamespaceMap->{$property_status}{namespace}."\">" :
			">";
		$ans .= $ns;
		$ans .= $WSRF::WSRP::ResourceProperties{$property_status};
		$ans .= "</".$WSRF::WSRP::PropertyNamespaceMap->{$property_status}{prefix}.":$property_status>";
	}
	$lock->toFile();
	
	# Return status properties
#	return WSRF::Header::header($envelope), SOAP::Data->uri($WSRF::Constants::MOBY)
#						->name('body' => \SOAP::Data->value(
#							SOAP::Data->type('xml'=>$ans)
#						));
	return WSRF::Header::header($envelope), SOAP::Data->type('xml'=>$ans);
};

#===============================================================================
# sync
#
# Answers synchronous requests of asynchronous BioMOBY services.
# It tries to execute the service.
# If execution time exceeds a defined timeout, it returns a moby exception.
#
sub sync {
	my $class = shift @_;
	my $envelope = pop @_;
	my ($func, $timeout, $data) = @_;
	
	my $ans;
	$SIG{ALRM} = sub { die "timeout exceeded" };
	eval {
		alarm $timeout;
		$ans = $func->($class, $data);
		alarm 0;
	};
	
	if ($@ =~ /timeout exceeded/) {
		my $exception = '';
		my $response = '';
		
		my $inputs = serviceInputParser($data);
		foreach my $queryID (keys %$inputs) {
			
			$exception .= "<mobyException refQueryID=\'$queryID\' severity=\'error\'>";
			$exception .= "<exceptionCode>701</exceptionCode>";
			$exception .= "<exceptionMessage>Timeout exceeded. Try to invoke the service asynchronously.</exceptionMessage>";
			$exception .= "</mobyException>";
			
			$response .= simpleResponse('', '', $queryID);
		}
		
		$ans .= responseHeader($ENV{AUTHURI});
		$ans .= "<serviceNotes xmlns='$WSRF::Constants::MOBY_MESSAGE_NS'>$exception</serviceNotes>";
		$ans .= $response;
		$ans .= responseFooter();
		$ans  = SOAP::Data->value($ans)->type('string');
	}
	
	return $ans;
}

#===============================================================================
# error
#
# Answers synchronous requests of asynchronous BioMOBY services
# It just returns a moby exception
#
sub error {
	my $class = shift @_;
	my ($data) = @_;
	
	my $exception = '';
	my $response = '';
	
	my $inputs = serviceInputParser($data);
	foreach my $queryID (keys %$inputs) {
		
		$exception .= "<mobyException refQueryID=\'$queryID\' severity=\'error\'>";
		$exception .= "<exceptionCode>701</exceptionCode>";
		$exception .= "<exceptionMessage>Service must be invoked asynchronously.</exceptionMessage>";
		$exception .= "</mobyException>";
		
		$response .= simpleResponse('', '', $queryID);
	}
	
	my $ans;
	$ans .= responseHeader($ENV{AUTHURI});
	$ans .= "<serviceNotes xmlns='$WSRF::Constants::MOBY_MESSAGE_NS'>$exception</serviceNotes>";
	$ans .= $response;
	$ans .= responseFooter();
	
	return SOAP::Data->value($ans)->type('string');
}

#===============================================================================
# async
#
# Answers asynchronous requests of asynchronous BioMOBY services
#
sub async {
	my $wsa = $async_create->(@_);
	# The specification says that async always work
	# so any error related to job creation must
	# be got using poll.
	# That's the reason why we are ignoring the returned
	# value from $async_submit
	$async_submit->(@_);
	return $wsa;
}

#===============================================================================
# Destroy
# 
# Redefines WSRF-WSRL Destroy operation in order to kill running processes.
#
sub Destroy {
	my ($class, $envelope) = ($_[0], $_[$#_]);
	
	my $lock = WSRF::MobyFile->new($envelope);
	$lock->toFile();
	
	my @notkilled;
	foreach my $key (keys %WSRF::WSRP::Private) {
		if (index($key, "pid_") == 0) {
			my $pid = $WSRF::WSRP::Private{$key};
			if ($pid) {
				kill(9, $pid) or push(@notkilled, $pid)
			}
		}
	}
	WSRF::BaseFaults::die_with_fault( $envelope, (
		BaseFault   => "ResourceNotDestroyedFault",
		Description => "Could not kill WS-Resource process ".join(", ", @notkilled)
	) ) if (scalar(@notkilled));
	
        return $class->SUPER::Destroy(@_);
}

1;
