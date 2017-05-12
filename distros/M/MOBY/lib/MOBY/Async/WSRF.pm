=pod

=head1 NAME

MOBY::Async::WSRF - utilities to work with WSRF in MOBY

=head1 AUTHORS

Former developer
Enrique de Andres Saiz (enrique.deandres@pcm.uam.es) -
INB GNHC-1 (Madrid Science Park, Spain) (2006-2007).

Maintainers
Jose Manuel Rodriguez (jmrodriguez@cnio.es),
Jose Maria Fernandez (jmfernandez@cnio.es) -
INB GN2 (CNIO, Spain).

=head1 DESCRIPTION

It extends L<WSRF::Lite> Perl module and provides everything required for
L<MOBY::Async::SimpleServer> class.

It is not intendeed to be used directly unless you want to create a new class
as L<WSRF::Async::SimpleServer>.

=cut

package MOBY::Async::WSRF;
use strict;
use WSRF::Lite 0.8.2.2;
use File::Path;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /: (\d+)\.(\d+)/;

$WSRF::WSRP::Private{queryIDs} = [];
$WSRF::WSRP::MobyPrivatePrefixes    = ['pid', 'input'];
$WSRF::WSRP::MobyPropertiesPrefixes = ['status', 'result'];

$WSRF::Constants::DataDir  = (exists($ENV{TMPDIR}) && defined($ENV{TMPDIR}) && $ENV{TMPDIR} ne '')?$ENV{TMPDIR}:'/tmp';
mkpath($WSRF::Constants::DataDir,1,0777);
$WSRF::Constants::DataPrefix  = 'moby_';
$WSRF::Constants::Data = $WSRF::Constants::DataDir .'/'. $WSRF::Constants::DataPrefix;
$WSRF::Constants::MOBY  = 'http://biomoby.org/';
$WSRF::Constants::MOBY_MESSAGE_NS  = 'http://www.biomoby.org/moby';
#$WSRF::Constants::WSA   = 'http://www.w3.org/2005/08/addressing';
#$WSRF::Constants::WSRP  = 'http://docs.oasis-open.org/wsrf/rp-2';
#$WSRF::Constants::WSRL  = 'http://docs.oasis-open.org/wsrf/rl-2';
#$WSRF::Constants::WSSG  = 'http://docs.oasis-open.org/wsrf/sg-2';
#$WSRF::Constants::WSBF  = 'http://docs.oasis-open.org/wsrf/bf-2';
#$WSRF::Constants::WSA_ANON = 'http://www.w3.org/2005/08/addressing/anonymous';
$WSRF::Constants::WSRPW  = 'http://docs.oasis-open.org/wsrf/rpw-2';
$WSRF::Constants::WSRLW  = 'http://docs.oasis-open.org/wsrf/rlw-2';

#===============================================================================
# WSRF::Serializer
# 
# THIS CODE IS TAKEN FROM WSRF::LITE. I HAVE PUT $WSRF_HEADER VARIABLE, THEN I
# CAN INSERT HEADERS WHEN A FAULT OCCURS
#
package WSRF::Serializer;
use base qw(WSRF::WSRFSerializer);

my $WSRF_HEADER;

sub std_envelope {
	SOAP::Trace::trace('()');
	my $self = shift->new;
	my $type = shift;

	$self->autotype(0);
	$self->attr ({'xmlns:wsa'  => $WSRF::Constants::WSA,
		'xmlns:wsrl' => $WSRF::Constants::WSRL,
		'xmlns:wsrp' => $WSRF::Constants::WSRP,
		'xmlns:wsu'  => $WSRF::Constants::WSU,
		'xmlns:wsse' => $WSRF::Constants::WSSE,
		'xmlns:mobyws' => $WSRF::Constants::MOBY
	} );
	
	
	my(@parameters, @header);
	for (@_) { 
		# Find all the SOAP Headers
		if (defined($_) && ref($_) && UNIVERSAL::isa($_ => 'SOAP::Header')) {
			push(@header, $_); 

		# Find all the SOAP Message Parts (attachments)
		} elsif (defined($_) && ref($_) && 
			$self->context && $self->context->packager->is_supported_part($_)
		) {
			$self->context->packager->push_part($_);

		# Find all the SOAP Body elements
		} else {
			push(@parameters, $_);
		}
	}
	my $header = @header ? SOAP::Data->set_value(@header) : undef;
	$header = $WSRF_HEADER unless ($header); ########## THIS IS THE LINE I HAVE ADDED ##########
	my($body,$parameters);
	if ($type eq 'method' || $type eq 'response') {
		SOAP::Trace::method(@parameters);

		my $method = shift(@parameters);
		#	  or die "Unspecified method for SOAP call\n";

		$parameters = @parameters ? SOAP::Data->set_value(@parameters) : undef;
		if (!defined($method)) {
		} elsif (UNIVERSAL::isa($method => 'SOAP::Data')) {
			$body = $method;
		} elsif ($self->use_default_ns) {
			if ($self->{'_ns_uri'}) {
				$body = SOAP::Data->name($method)->attr( { 
					'xmlns' => $self->{'_ns_uri'},
				} ); 
			} else {
				$body = SOAP::Data->name($method); 
			}
		} else {
# Commented out by Byrne on 1/4/2006 - to address default namespace problems
#      $body = SOAP::Data->name($method)->uri($self->{'_ns_uri'});
#      $body = $body->prefix($self->{'_ns_prefix'}) if ($self->{'_ns_prefix'});

# Added by Byrne on 1/4/2006 - to avoid the unnecessary creation of a new
# namespace
# Begin New Code (replaces code commented out above)
			$body = SOAP::Data->name($method);
			my $pre = $self->find_prefix($self->{'_ns_uri'});
			$body = $body->prefix($pre) if ($self->{'_ns_prefix'});
# End new code

		}
		# This is breaking a unit test right now...
		$body->set_value(SOAP::Utils::encode_data($parameters ? \$parameters : ()))
			if $body;
	} elsif ($type eq 'fault') {
		SOAP::Trace::fault(@parameters);
		$body = SOAP::Data
			->name(SOAP::Utils::qualify($self->envprefix => 'Fault'))
		# parameters[1] needs to be escaped - thanks to aka_hct at gmx dot de
		# commented on 2001/03/28 because of failing in ApacheSOAP
		# need to find out more about it
		# -> attr({'xmlns' => ''})
			->value(\SOAP::Data->set_value(
				SOAP::Data->name(faultcode => SOAP::Utils::qualify($self->envprefix => $parameters[0]))->type(""),
				SOAP::Data->name(faultstring => SOAP::Utils::encode_data($parameters[1]))->type(""),
				defined($parameters[2]) ? SOAP::Data->name(detail => do{my $detail = $parameters[2]; ref $detail ? \$detail : $detail}) : (),
				defined($parameters[3]) ? SOAP::Data->name(faultactor => $parameters[3])->type("") : (),
      			));
	} elsif ($type eq 'freeform') {
		SOAP::Trace::freeform(@parameters);
		$body = SOAP::Data->set_value(@parameters);
	} elsif (!defined($type)) {
		# This occurs when the Body is intended to be null. When no method has been
		# passed in of any kind.
	} else {
		die "Wrong type of envelope ($type) for SOAP call\n";
	}
	
	$self->seen({}); # reinitialize multiref table
	# Build the envelope
	# Right now it is possible for $body to be a SOAP::Data element that has not
	# XML escaped any values. How do you remedy this?
	my($encoded) = $self->encode_object(
		SOAP::Data->name(
			SOAP::Utils::qualify($self->envprefix => 'Envelope') => \SOAP::Data->value(
				($header ? SOAP::Data->name(SOAP::Utils::qualify($self->envprefix => 'Header') => \$header) : ()),
				($body ? SOAP::Data
						->name(SOAP::Utils::qualify($self->envprefix => 'Body') => \$body)
						->attr( { 
							'wsu:Id'     => 'myBody'		 
						} )
					:
					SOAP::Data
						->name(SOAP::Utils::qualify($self->envprefix => 'Body')) 
						->attr( { 
							'wsu:Id'     => 'myBody'
					} ) 
				),
    			)
		)->attr($self->attr)
	);
	$self->signature($parameters->signature) if ref $parameters;
	
	# IMHO multirefs should be encoded after Body, but only some
	# toolkits understand this encoding, so we'll keep them for now (04/15/2001)
	# as the last element inside the Body 
	#                 v -------------- subelements of Envelope
	#                      vv -------- last of them (Body)
	#                            v --- subelements
	push(@{$encoded->[2]->[-1]->[2]}, $self->encode_multirefs) if ref $encoded->[2]->[-1]->[2];
	
	# Sometimes SOAP::Serializer is invoked statically when there is no context.
	# So first check to see if a context exists.
	# TODO - a context needs to be initialized by a constructor?
	if ($self->context && $self->context->packager->parts) {
		# TODO - this needs to be called! Calling it though wraps the payload twice!
		#  return $self->context->packager->package($self->xmlize($encoded));
	}
	return $self->xmlize($encoded);
}


#===============================================================================
# WSRF::FileBasedMobyResourceProperties
# 
# Base module for the file based WSRF services - if a service inherits from this
# class then the ResourceProperties are stored in a file between calls.
# We inherit this to gain access to the envelope - see SOAP::Lite
#
# THIS CODE IS TAKEN FROM WSRF::LITE. I HAVE PUT WSRF::MobyFile INSTEAD OF	
# WSRF::File.
#
package WSRF::FileBasedMobyResourceProperties;
use strict;
use XML::LibXML;
use base qw(WSRF::WSRP);

# Load the ResourceProperties from the file into the ResourceProperties hash
# then call the super operation.
sub GetResourceProperty {
	my $self = shift @_;
	my $envelope = pop @_;
	
	my $lock = WSRF::MobyFile->new($envelope);
	$lock->toFile();

	my($isValidQName)=1;
	my($search)=undef;
	my($localsearch)=undef;
	eval {
		my($parser)=XML::LibXML->new();
		my($context)=XML::LibXML::XPathContext->new();
		$context->registerNs('wsrf-rp',$WSRF::Constants::WSRP);
		my($envxml)=$parser->parse_string($envelope->raw_xml());
		foreach my $searchnode ($context->findnodes('//wsrf-rp:GetResourceProperty',$envxml)) {
			$search=$searchnode->textContent();
			
			$localsearch=$search;
			my($prefix)='';
			my($icolon)=index($search,':');
			if($icolon!=-1) {
				$prefix=substr($search,0,$icolon);
				$localsearch=substr($search,$icolon+1);
			}
			my($nsnode)=$searchnode->lookupNamespaceURI($prefix);
			unless(defined($nsnode) && $nsnode eq $WSRF::Constants::MOBY) {
				$isValidQName=undef;
			}
			
			last;
		}
	};

	if($@) {
		$search = $envelope->valueof("//{$WSRF::Constants::WSRP}GetResourceProperty/");
		$localsearch=$search;
		my($prefix)='';
		my($icolon)=index($search,':');
		if($icolon!=-1) {
			$prefix=substr($search,0,$icolon);
			$localsearch=substr($search,$icolon+1);
		}
	}
	
	WSRF::BaseFaults::die_with_fault( $envelope, (
		BaseFault   => "InvalidResourcePropertyQNameFault",
		Description => "Property $search does not exist"
	) )  unless(defined($isValidQName) && exists($WSRF::WSRP::ResourceProperties{$localsearch}) && defined($WSRF::WSRP::ResourceProperties{$localsearch}));
	
	my @resp = $self->SUPER::GetResourceProperty($envelope);
	return @resp;
}

# Load the ResourceProperties from the file into the ResourceProperties hash
# then call the super operation.
sub GetMultipleResourceProperties {
	my $self = shift @_;
	my $envelope = pop @_;

	my $lock = WSRF::MobyFile->new($envelope); 
	$lock->toFile();
	
	my @notfound;
	eval {
		my($parser)=XML::LibXML->new();
		my($context)=XML::LibXML::XPathContext->new();
		$context->registerNs('wsrf-rp',$WSRF::Constants::WSRP);
		my($envxml)=$parser->parse_string($envelope->raw_xml());
		foreach my $searchnode ($context->findnodes('//wsrf-rp:ResourceProperty',$envxml)) {
			my($search)=$searchnode->textContent();
			
			my($localsearch)=$search;
			my($prefix)='';
			my($icolon)=index($search,':');
			if($icolon!=-1) {
				$prefix=substr($search,0,$icolon);
				$localsearch=substr($search,$icolon+1);
			}
			my($isValidQName)=undef;
			my($nsnode)=$searchnode->lookupNamespaceURI($prefix);
			if(defined($nsnode) && $nsnode eq $WSRF::Constants::MOBY) {
				$isValidQName=1;
			}
			
			push(@notfound, $search)  unless(defined($isValidQName) && exists($WSRF::WSRP::ResourceProperties{$localsearch}) && defined($WSRF::WSRP::ResourceProperties{$localsearch}));
			
		}
	};

	if($@) {
		foreach my $search ($envelope->valueof("//{$WSRF::Constants::WSRP}ResourceProperty/")) {
			my($localsearch)=$search;
			my($prefix)='';
			my($icolon)=index($search,':');
			if($icolon!=-1) {
				$prefix=substr($search,0,$icolon);
				$localsearch=substr($search,$icolon+1);
			}
			
			push(@notfound, $search)  unless(exists($WSRF::WSRP::ResourceProperties{$localsearch}) && defined($WSRF::WSRP::ResourceProperties{$localsearch}));
		}
	}
	WSRF::BaseFaults::die_with_fault( $envelope, (
		BaseFault   => "InvalidResourcePropertyQNameFault",
		Description => "Property ".join(", ", @notfound) ." does not exist"
	) ) if (scalar(@notfound));
	
	my @resp = $self->SUPER::GetMultipleResourceProperties($envelope);
	return @resp;
}


#===============================================================================
# WSRF::FileBasedMobyResourceLifetimes
# 
# Inherits from WSRF::FileBasedMobyResourceProperties, this class adds the
# required WSRL operations to the Service. Again all the ResourceProperties are
# stored in a file between calls
#
# THIS CODE IS TAKEN FROM WSRF::LITE. I HAVE PUT WSRF::MobyFile INSTEAD OF	
# WSRF::File. I HAVE ALSO INCLUDED WSRF::BaseFaults.
#
package WSRF::FileBasedMobyResourceLifetimes;
use strict;
use base qw(WSRF::FileBasedMobyResourceProperties);

# Add resource property TerminationTime - initalise to nothing (infinity).
$WSRF::WSRP::ResourceProperties{'TerminationTime'} = '';
$WSRF::WSRP::PropertyNamespaceMap->{TerminationTime}{prefix} = "wsrl";
$WSRF::WSRP::Nillable{TerminationTime} = 1;
$WSRF::WSRP::NotModifiable{TerminationTime} = 1;

# Add resource property CurrentTime - in this case a subroutine that returns
# the current time in the correct format.
$WSRF::WSRP::ResourceProperties{'CurrentTime'} = sub {
	return "<wsrl:CurrentTime>".
		WSRF::Time::ConvertEpochTimeToString().
		"</wsrl:CurrentTime>"; };	 
$WSRF::WSRP::PropertyNamespaceMap->{CurrentTime}{prefix} = "wsrl";
$WSRF::WSRP::NotDeletable{CurrentTime} = 1;
$WSRF::WSRP::NotModifiable{CurrentTime} = 1;

# Remove the file with the resource properties in it.
sub Destroy {
	my $self = shift @_;
	my $envelope = pop @_;
	my $lock = WSRF::MobyFile->new($envelope);
	my $file = $WSRF::Constants::Data.$lock->ID();
	unlink $file or WSRF::BaseFaults::die_with_fault( $envelope, (
		BaseFault   => "ResourceNotDestroyedFault",
		Description => "Could not remove WS-Resource file"
	) );
	return WSRF::Header::header($envelope);
}


#===============================================================================
# WSRF::BaseFaults (WS-BaseFaults spec.)
# 
# This module allows you to return a WS-BaseFault. Simply call die_with_fault
# to case your service to through an exception.
# 
# The function takes hash with the following:
#   BaseFault            (specific fault of BaseFault as default)
#   OriginatorReference  (where did the fault originally originate)
#   ErrorCode            (some code number)
#   dialect              (URI that defines the context in which the ErrorCode 
#                         must be interpreted)
#   Description          (a description of the fault)
#   FaultCause           (underlying cause of this faulte)
#
# THIS CODE IS TAKEN FROM WSRF::LITE. I HAVE INCLUDED THE ENVELOPE PARAMETER
# (FOR CREATING THE WSRF HEADER WHEN THERE IS A FAULT) AND THE BASEFAULT KEY
# (FOR SPECIFYING WHICH KIND OF FAULT IT IS).
#
package WSRF::BaseFaults;
use strict;

sub die_with_fault {
	my ($envelope, %args) = @_;
	
	# Has the client defined a BaseFault
	my $fault;
	if (defined($args{BaseFault})) {
		$fault = "<wsbf:".$args{BaseFault}." xmlns:wsbf=\"$WSRF::Constants::WSBF\">"; 
	} else {
		$fault = "<wsbf:BaseFault xmlns:wsbf=\"$WSRF::Constants::WSBF\">"; 
	}
	
	# Timestamp
	$fault .= "<wsbf:Timestamp>".WSRF::Time::ConvertEpochTimeToString(time)."</wsbf:Timestamp>";
	
	# Has the client defined an OriginatorReference
	if (defined($args{OriginatorReference})) {
		$fault .= "<wsbf:OriginatorReference>".$args{OriginatorReference}."</wsbf:OriginatorReference>";
	}
	
	# Has the client defined an error code & dialect 
	if (defined($args{ErrorCode})) {
		if (defined($args{dialect})) {
			$fault .= "<wsbf:ErrorCode dialect=\"".$args{dialect}."\">".$args{ErrorCode}."</wsbf:ErrorCode>";
		} else {
			$fault .= "<wsbf:ErrorCode>".$args{ErrorCode}."</wsbf:ErrorCode>";
		}
	}
	
	# Has the client defined a Description
	if (defined($args{Description})) {
		$fault .= "<wsbf:Description>".$args{Description}."</wsbf:Description>";
	}
	
	# Has the client defined a BaseCause
	if (defined($args{FaultCause})) {
		$fault .= "<wsbf:FaultCause>".$args{FaultCause}."</wsbf:FaultCause>";
	}
	
	# Has the client defined a BaseFault
	if (defined($args{BaseFault})) {
		$fault .= "</wsbf:".$args{BaseFault}.">";
	} else {
		$fault .= "</wsbf:BaseFault>";
	}
	
	$WSRF_HEADER = WSRF::Header::header($envelope, ( Action => "http://docs.oasis-open.org/wsrf/fault" ));
	die SOAP::Fault->faultdetail($fault);
}


#===============================================================================
# WSRF::Header (WS-Address spec.)
# 
# header function creates a SOAP::Header that should be included
# in the response to the client. Handles the WS-Address stuff.
# Takes the original envelope and creates a Header from it - 
# the second paramter will be stuffed into the Header so must
# be XML
#
# BUG This should be better automated - probably in the SOAP serializer,
# not sure how because we need to remember the MessageID 
# 
# THIS CODE IS TAKEN FROM WSRF::LITE. I HAVE ADDED A SECOND PARAMETER
# WHICH IS A HASH WHOOSE KEYS ARE WSRF HEADERS WHICH MODIFIES
# THE DEFAULT BEHAVIOUR ON THE COMPOSITION OF THE HEADER.
#
package WSRF::Header;
use strict;

my(%URI2ACTION)=(
	$WSRF::Constants::WSRP => [$WSRF::Constants::WSRPW,undef],
	$WSRF::Constants::WSRL => [$WSRF::Constants::WSRLW,'ImmediateResourceTermination']
);
no warnings 'redefine'; 
sub header {
	my ($envelope, %args) = @_;
	my $myHeader;
	
	# wsa:To
	if (defined($args{To})) {
		$myHeader .= "<wsa:To wsu:Id=\"To\">".$args{To}."</wsa:To>";
	} else {
		$myHeader .= "<wsa:To wsu:Id=\"To\">$WSRF::Constants::WSA_ANON</wsa:To>";
	}
	
	# wsa:From
	if (defined($args{From})) {
		$myHeader .= "<wsa:From wsu:Id=\"From\">".$args{From}."</wsa:From>";
	} else {
		if ( $envelope->match("/{$SOAP::Constants::NS_ENV}Envelope/{$SOAP::Constants::NS_ENV}Header/{$WSRF::Constants::WSA}To") ) {   
			my $from = $envelope->valueof("/{$SOAP::Constants::NS_ENV}Envelope/{$SOAP::Constants::NS_ENV}Header/{$WSRF::Constants::WSA}To");   
			$myHeader .= "<wsa:From wsu:Id=\"From\"><wsa:Address>$from</wsa:Address></wsa:From>";
		}
	}
	
	# wsa:MessageID
	if (defined($args{MessageID})) {
		$myHeader .= "<wsa:MessageID wsu:Id=\"MessageID\">".$args{MessageID}."</wsa:MessageID>";
	} else {
		$myHeader .= "<wsa:MessageID wsu:Id=\"MessageID\">".WSRF::WS_Address::MessageID()."</wsa:MessageID>";
	}
	
	# wsa:Action
	if (defined($args{Action})) {
		$myHeader .= "<wsa:Action wsu:Id=\"Action\">".$args{Action}."</wsa:Action>";
	} else {
		my $data = $envelope->match("/{$SOAP::Constants::NS_ENV}Envelope/{$SOAP::Constants::NS_ENV}Body/[1]")->dataof;
		my $method = $data->name;
		my $uri = $data->uri;
		if(exists($URI2ACTION{$uri})) {
			$uri = $URI2ACTION{$uri}[0].'/'.(defined($URI2ACTION{$uri}[1])?$URI2ACTION{$uri}[1]:$method);
		}
		$myHeader .= "<wsa:Action wsu:Id=\"Action\">".$uri."/".$method."Response</wsa:Action>";
	}
	
	# wsa:RelatesTo
	if (defined($args{RelatesTo})) {
		$myHeader .= "<wsa:RelatesTo wsu:Id=\"RelatesTo\">".$args{RelatesTo}."</wsa:RelatesTo>";
	} else {
		my $messageID = $envelope->headerof("//{$WSRF::Constants::WSA}MessageID");  
		if ( defined $messageID ) {
			$messageID = $envelope->headerof("//{$WSRF::Constants::WSA}MessageID")->value;
			$myHeader .= "<wsa:RelatesTo wsu:Id=\"RelatesTo\">".$messageID."</wsa:RelatesTo>";
		}
	}
	
	# Create the SOAP::Header object and return it
	return SOAP::Header->value($myHeader)->type('xml');
};

#===============================================================================
# WSRF::MobyFile
# 
# This module supports writing all the resource properties of a Resource to a 
# file. Allows the state of the resource to be stored in a file between calls 
# to the Resource.
# 
# THIS CODE IS TAKEN FROM WSRF::LITE. I HAVE ONLY MODIFIED WHERE TO SEARCH THE
# ID (FROM AN ENVIRONMENT VARIABLE INSTEAD OF ENVELOPE) AND THE PROCESS TO
# LOAD AUTOMATICALLY THE PROPERTIES IN new METHOD, AND DESTROYIN THE LOCK IN
# toFile METHOD.
#
package WSRF::MobyFile;
use strict;

use base qw(WSRF::File);

sub new {
	my( $class, $envelope, $ID) = @_;

	unless(defined($ID)) {
		$ID = $envelope->valueof("/{$SOAP::Constants::NS_ENV}Envelope/{$SOAP::Constants::NS_ENV}Header/{$WSRF::Constants::MOBY}ServiceInvocationId");
		$ENV{ID} = $ID;
	}
	
	
	# Check the ID is safe - we do not accept dots,
	# All paths will be relative to $ENV{WRF_MODULES}
	# Only allow alphanumeric, underscore and hyphen
	if( $ID =~ /^([-\w]+)$/ ) {
		$ID = $1;
	} else {
		WSRF::BaseFaults::die_with_fault( $envelope, (
			BaseFault   => "ResourceUnknownFault",
			Description => "Badly formed WS-Resource Identifier $ID"
		) );
	}
	
	# ID can be of the form 1341-4565, we use this form to all multiple
	# WS-Resources to share the same state, the state is in the file
	# 1341 - we use this with ServiceGroup/ServiceGroupEntry   
	my $ID_clipped = $ID;
	$ID_clipped =~ s/-\w*//o;
	
	# File containing resource properties
	my $path = $WSRF::Constants::Data.$ID_clipped;
	WSRF::BaseFaults::die_with_fault( $envelope, (
		BaseFault   => "ResourceUnknownFault",
		Description => "No WS-Resource with Identifer $ID"
	) ) if ( ! -e $path );
	
	# The address of the lock file
	my $lock =  $path.".lock"; 
	
	# Acquire a lock for the file 
	my $Lock = WSRF::FileLock->new($lock);
	
	my $hashref = Storable::lock_retrieve($path); 
	%WSRF::WSRP::Private = (%WSRF::WSRP::Private, %{$hashref->{Private}});
	foreach my $queryID (@{$WSRF::WSRP::Private{queryIDs}}) {
		foreach my $privatePrefix (@{$WSRF::WSRP::MobyPrivatePrefixes}) {
			$WSRF::WSRP::Private{$privatePrefix.'_'.$queryID} = $WSRF::WSRP::Private{$privatePrefix.'_'.$queryID} || '';
		}
		foreach my $propertyPrefix (@{$WSRF::WSRP::MobyPropertiesPrefixes}) {
			$WSRF::WSRP::ResourceProperties{$propertyPrefix.'_'.$queryID} = $WSRF::WSRP::ResourceProperties{$propertyPrefix.'_'.$queryID} || '';
			$WSRF::WSRP::PropertyNamespaceMap->{$propertyPrefix.'_'.$queryID}{prefix} = 'mobyws';
			$WSRF::WSRP::PropertyNamespaceMap->{$propertyPrefix.'_'.$queryID}{namespace} = $WSRF::Constants::MOBY;
			$WSRF::WSRP::NotDeletable{$propertyPrefix.'_'.$queryID} = 1;
			$WSRF::WSRP::NotModifiable{$propertyPrefix.'_'.$queryID} = 1;
		}
	}
	%WSRF::WSRP::ResourceProperties = (%WSRF::WSRP::ResourceProperties, %{$hashref->{Properties}});
	
	# Check that the resource is still alive - if TT time is not
	# set then TT is infinity
	if ( defined($WSRF::WSRP::ResourceProperties{'TerminationTime'}) &&
	     ($WSRF::WSRP::ResourceProperties{'TerminationTime'} ne "") ) {
		if ( WSRF::Time::ConvertStringToEpochTime($WSRF::WSRP::ResourceProperties{'TerminationTime'}) < time ) {
        		
			unlink $path or die SOAP::Fault->faultcode("Container Failure")
		                                       ->faultstring("Container Failure: Could not remove file");
			rmdir $lock or die SOAP::Fault->faultcode("Container Failure")
		                                      ->faultstring("Container Failure: Could not remove lock file");
			WSRF::BaseFaults::die_with_fault( $envelope, (
				BaseFault   => "ResourceUnknownFault",
				Description => "No such WS-Resource $ID - Lifetime expired"
			) );
		}
	}
	
	bless {
		_ID        => $ID,
		_path      => $path,
		_lock      => $Lock	  
	}, $class;
}

sub toFile {
	my $class = $_[0];
	$class->SUPER::toFile(@_);
	my $lock = ref($class) ? $class->{_lock} : '';
	$lock->DESTROY if ($lock);
}


#===============================================================================
# WSRF::FileLock
#
# This module provides file locking for us - when an object of this class is
# created a lock file is created. The lock file is automatically removed when
# the object is destroyed.
#
# THIS CODE IS TAKEN FROM WSRF::LITE. I HAVE ONLY DELETED LOGS.
#
package WSRF::FileLock;
use strict;

sub new {
	my ($self, $file) = @_;
	until ( mkdir $file ) {
		select(undef,undef,undef,0.5);
	}
	bless{
		_file => $file
	}, $self; 
}

sub DESTROY {
	my ($self) = @_; 
	if( -d $self->{_file} ) {
		rmdir $self->{_file} or die SOAP::Fault->faultcode("Container Failure")
		                                       ->faultstring("Container Failure: Could not remove WS-Resource lock file");
	}
}

1;
