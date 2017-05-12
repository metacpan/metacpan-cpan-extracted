#$Id: Service.pm,v 1.4 2009/02/12 19:03:32 kawas Exp $

=head1 NAME

MOBY::Client::Service - an object for communicating with MOBY Services

=head1 SYNOPSIS

 use MOBY::Client::Service;

 my $Service = MOBY::Client::Service->new(service => $WSDL);
 my $result = $Service->execute(@args);

=head1 DESCRIPTION

Deals with all SOAPy rubbish required to communicate with a MOBY Service.
The object is created using the WSDL file returned from a
MOBY::Client::Central->retrieveService() call.  The only useful method call
in this module is "execute", which executes the service.

=head1 AUTHORS

Mark Wilkinson (markw@illuminae.com)

BioMOBY Project:  http://www.biomoby.org

=head1 METHODS

=head2 new

 Usage     :	$Service = MOBY::Client::Service->new(@args)
 Function  :	create a service connection
 Returns   :	MOBY::Client::Service object, undef if no wsdl.
 Args      :	service : string ; required
                          a WSDL file defining a MOBY service
                uri     : string ; optional ; default NULL
                          if the URI of the soap call needs to be personalized
                          this should almost never happen...

=cut

package MOBY::Client::Service;
use SOAP::Lite;

#use SOAP::Lite + 'trace';
use strict;
use Carp;
use Cwd;
use URI::Escape;
use vars qw($AUTOLOAD @ISA);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

my $debug = 0;
if ( $debug ) {
	open( OUT, ">/tmp/ServiceCallLogOut.txt" ) || die "cant open logfile\n";
	close OUT;
}

sub BEGIN {
}
{

	#Encapsulated class data
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		service      => [ undef, 'read/write' ],
		uri          => [ undef, 'read/write' ],
		serviceName  => [ undef, 'read/write' ],
		_soapService => [ undef, 'read/write' ],
		smessageVersion => ['0.88', 'read'	],
		category	=> ['moby', 'read/write'],
	  );

	#_____________________________________________________________
	# METHODS, to operate on encapsulated class data
	# Is a specified object attribute accessible in a given mode
	sub _accessible {
		my ( $self, $attr, $mode ) = @_;
		$_attr_data{$attr}[1] =~ /$mode/;
	}

	# Classwide default value for a specified object attribute
	sub _default_for {
		my ( $self, $attr ) = @_;
		$_attr_data{$attr}[0];
	}

	# List of names of all specified object attributes
	sub _standard_keys {
		keys %_attr_data;
	}
	my $queryID = 0;

	sub _nextQueryID {
		return ++$queryID;
	}
}

sub new {
	my ( $caller, %args ) = @_;
	my $caller_is_obj = ref( $caller );
	my $class         = $caller_is_obj || $caller;
	my $self          = bless {}, $class;
	foreach my $attrname ( $self->_standard_keys ) {
		if ( exists $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		} elsif ( $caller_is_obj ) {
			$self->{$attrname} = $caller->{$attrname};
		} else {
			$self->{$attrname} = $self->_default_for( $attrname );
		}
	}
	my $wsdl = $self->service;
	return undef unless $wsdl;

	if ($wsdl =~ /<http:binding verb=['"]POST['"]\/>/){
		$self->category('post');
	}

	# TODO - added to make old WSDL compliant with soap lite 0.69
	if ( $wsdl =~ /element="xsd1:NOT_YET_DEFINED_INPUTS"/ ) {
		$wsdl =~ s/name="body" element="xsd1:NOT_YET_DEFINED_INPUTS"/name="data" type="xsd:string"/g;
		$wsdl =~ s/element="xsd1:NOT_YET_DEFINED_OUTPUTS"/type="xsd:string"/g;
	}
	
	$wsdl = URI::Escape::uri_escape( $self->service );    # this seems to fix the bug
	
	my $soap = SOAP::Lite->service( "data:,$wsdl" );
	$soap->soapversion('1.1');
	$self->_soapService( $soap );
	if ( $self->uri ) { $soap->uri( $self->uri ) }
	$self->serviceName( $self->_getServiceName() );
	return undef unless $self->serviceName;  # servicename could not be determined, so no methods can be called
	return $self;
}

=head2 execute

 Usage     :	$result = $Service->execute(%args)
 Function  :	execute the MOBY service
 Returns   :	whatever the Service provides as output
 Args      :	XMLinputlist => \@data
 Comment   :    @data is a list of single invocation inputs; the XML goes between the
                <queryInput> tags of a servce invocation XML.
Each element of @data is itself a listref of [articleName, $XML].
                articleName may be undef if it isn't required.
                $XML is the actual XML of the Input object

=head3 Examples 

There are several ways in which you can execute a service. You may
wish to invoke the service on several objects, and get the response
back in a single message. You may wish to pass in a collection of
objects, which should be treated as a single entity. Or you may wish
to pass in parameters, along with data. In each case, you're passing in 

   XMLinputlist => [ ARGS ]

The structure of @ARGS helps MOBY to figure out what you want.

=over 4 

=item Iterate over multiple Simples

To have the service iterate over multiple equivalent objects, and
return all the results in a single message, use this syntax (ARGS =
([...], [...], ...).  Here, the articleName of the input parameter is
"input1":

  $Service->execute(XMLinputlist => [ 
                        ['input1', '<Object namespace="blah" id="123"/>'],
                        ['input1', '<Object namespace="blah" id="234"/>']
                            ]);

This would invoke the service twice (in a single message) the first
time with an object "123" and the second time with object "234". 

=item Process a Collection

To pass in a Collection, you need this syntax (ARGS = [ '', [..., ..., ...] ]).
Here, the articleName of the input is "input1".

  $Service->execute(XMLinputlist => [
                 ['input1', [
                     '<Object namespace="blah" id="123"/>',
                     '<Object namespace="blah" id="234"/>']
              ]);

This would invoke the service once with a collection of inputs that
are not required to be named ('').

=item Process multiple Simple inputs

To pass in multiple inputs, to be considered neither a Collection nor sequentially
evaluated, use this syntax (ARGS = [..., ..., ...]).  Here, the service consumes
two inputs with articleName input1 and input2

  $Service->execute(XMLinputlist => [
            [
             'input1', '<Object namespace="blah" id="123"/>',
             'input2', '<Object namespace="blah" id="234"/>',
            ]
		     ]);

This would cause a single invocation of a service.

=item Parameters

Finally, MOBY will recognize parameters by virtue of their having been
declared when the service was registered. You need to specify the name
correctly.

  $Service->execute(XMLinputlist => [
                 [
             'input1', '<Object namespace="blah" id="123"/>',
             'input2', '<Object namespace="blah" id="234"/>',
             'param1', '<Value>0.001</Value>',
             ]
              ]);

This would cause a single invocation of a service requiring two input
parameters named "input1" and "input2", and a parameter named 'param1'
with a value of 0.001

=back

=cut

sub execute {
  # The biggest unanswered question for this subroutine is how it should respond in the event 
  # that there is a problem with the service. 
  # It should probably die() rather than just return strings as error messages.
  my ( $self, %args ) = @_;
  die "ERROR:  expected listref for XMLinputlist"
    unless ( ref( $args{XMLinputlist} ) eq 'ARRAY' );
  my @inputs = @{ $args{XMLinputlist} };
  my $data;
  foreach ( @inputs ) {
    die "ERROR:  expected listref [articleName, XML] for data element"
      unless ( ref( $_ ) eq 'ARRAY' );
    my $qID = $self->_nextQueryID;
    $data .= "<moby:mobyData queryID='$qID'>";
    while ( my ( $articleName, $XML ) = splice( @{$_}, 0, 2 ) ) {
      $articleName ||= "";
      if (  ref( $XML ) ne 'ARRAY' ) {
	$XML         ||= "";
	if ( $XML =~ /\<(moby\:|)Value\>/ )
	  {
	    $data .=
	      "<moby:Parameter moby:articleName='$articleName'>$XML</moby:Parameter>";
	  } else {
	    $data .=
	      "<moby:Simple moby:articleName='$articleName'>\n$XML\n</moby:Simple>\n";
	  }
	
	# need to do this for collections also!!!!!!
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
  ###################
  #  this was added on January 19th, 2005 and may not work!
  ###################
  ###################
  my $version = $self->smessageVersion();
  $data = "<?xml version='1.0' encoding='UTF-8'?>
	<moby:MOBY xmlns:moby='http://www.biomoby.org/moby' moby:smessageVersion='$version'>
	      <moby:mobyContent>
	          $data
	      </moby:mobyContent>
	</moby:MOBY>";
#  $data =~ s"&"&amp;"g;  # encode content in case it has CDATA
#  $data =~ s"\<"&lt;"g;
#  $data =~ s"\]\]\>"\]\]&gt;"g;
  
  ####################
  ####################
  ### BEFORE IT WAS JUST THIS
  
  #$data = "<![CDATA[<?xml version='1.0' encoding='UTF-8'?>
  #<moby:MOBY xmlns:moby='http://www.biomoby.org/moby-s'>
  #      <moby:mobyContent>
  #          $data
  #      </moby:mobyContent>
  #</moby:MOBY>]]>";
  my $METHOD = $self->serviceName;
  &_LOG( %args, $METHOD );
  my $response;

	if ($self->category eq 'moby'){
		eval { ( $response ) = $self->_soapService->$METHOD( $data ) };
		if ($@) { die "Service execution failed: $@"}
		else {return $response;} # the service execution failed then pass back ""
	} elsif ($self->category eq 'post'){
		my $response = $self->_executePOSTService(data => $data, method => $METHOD);
		# currently SOAP::Lite does not execute POST WSDL, so we need to
		# use LWP or something like that in the executePOSTService method
		#eval { ( $response ) = $self->_soapService->$METHOD( $data ) };
		unless ($response){ die "Service execution failed: $@"}
		else {return $response;} # the service execution failed then pass back ""
	}
}


=head2 raw_execute

 Usage     :	$result = $Service->raw_execute(inputXML => "<../>")
 Function  :	execute the MOBY service using a raw MOBY input block
 Returns   :	whatever the Service provides as output
 Args      :	inputXML => "<moby:MOBY>.....</moby:MOBY>"

=cut

sub raw_execute {
	my ( $self, %args ) = @_;
	my $data = $args{inputXML};

  my $METHOD = $self->serviceName;
  my $response;

	if ($self->category eq 'moby'){
		eval { ( $response ) = $self->_soapService->$METHOD( $data ) };
		if ($@) { die "Service execution failed: $@"}
		else {return $response;} # the service execution failed then pass back ""
	} elsif ($self->category eq 'cgi'){
		my $response = $self->_executePOSTService(data => $data, method => $METHOD);
		# currently SOAP::Lite does not execute POST WSDL, so we need to
		# use LWP or something like that in the executePOSTService method
		#eval { ( $response ) = $self->_soapService->$METHOD( $data ) };
		unless ($response){ die "Service execution failed: $@"}
		else {return $response;} # the service execution failed then pass back ""
	}
	
	
}
sub _executePOSTService {
	my ($self, %args) = @_;
	my $serviceName = $args{method};
	my $data = $args{data};
	my $wsdl = $self->service;
	$wsdl =~ /address\slocation=['"]([^'"]+)/s;
	my $location = $1;
	$wsdl =~/operation\slocation=['"]([^'"]+)/s;
	my $path = $1;
	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new;
	
	# Create a request
	my $req = HTTP::Request->new(POST => "$location/$path");
	$req->content_type('application/x-www-form-urlencoded');
	$req->content('data=$data');
	
	# Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	my $result;
	# Check the outcome of the response
	if ($res->is_success) {
	  $result = $res->content;
	}
	else {
	  $result = "";
	}
	return $result;
}


=head2 enumerated_execute

 Usage     :	$result = $Service->enumerated_execute(%args)
 Function  :	execute the MOBY service using self-enumerated inputs
 Returns   :	whatever the Service provides as output
 Args      :	Input => %data
 Comment   :    %data is a hash of single invocation inputs
                the structure of %data is:

				$data{$queryID} = {articleName => $inputXML1, # for simples and parameters
				                   articleNmae => [$inputXML2, $inputXML3], # for collections
								   }
                $inputXML is the actual XML of the Input object
				for example <Object namespace="NCBI_gi" id="163483"/>

 a full example might be:

 $data{invocation1} = {id_to_match => "<Object namespace="GO" id="0003875"/>",
                       id_list => ["<Object namespace="GO" id="0003875"/>,
					               "<Object namespace="GO" id="0009984"/>,...
								   ]
						cutoff => "<Value>10</Value>"
						}


=cut



sub enumerated_execute {
  my ( $self, %args ) = @_;
  die "ERROR:  expected Input to be a HASH ref "
    unless ( ref( $args{Input} ) eq 'HASH' );
  my %inputs = %{$args{Input}};
# structure of %input is:
#$input{qid} = {articleName => "<XML>",  # for simples
#			   articleName2 => ["<XML>", "<XML>"], # for collections
#			  }

  my $data;
  foreach my $qID( keys %inputs ) {
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
  ###################
  #  this was added on January 19th, 2005 and may not work!
  ###################
  ###################
  my $version = $self->smessageVersion();
  $data = "<?xml version='1.0' encoding='UTF-8'?>
	<moby:MOBY xmlns:moby='http://www.biomoby.org/moby' moby:smessageVersion='$version'>
	      <moby:mobyContent>
	          $data
	      </moby:mobyContent>
	</moby:MOBY>";  
  my $METHOD = $self->serviceName;
  &_LOG( %args, $METHOD );
  my $response;

	if ($self->category eq 'moby'){
		eval { ( $response ) = $self->_soapService->$METHOD(  $data ) };
		if ($@) { die "Service execution failed: $@"}
		else {return $response;} # the service execution failed then pass back ""
	} elsif ($self->category eq 'post'){
		my $response = $self->_executePOSTService(data => $data, method => $METHOD);
		# currently SOAP::Lite does not execute POST WSDL, so we need to
		# use LWP or something like that in the executePOSTService method
		#eval { ( $response ) = $self->_soapService->$METHOD( $data ) };
		unless ($response){ die "Service execution failed: $@"}
		else {return $response;} # the service execution failed then pass back ""
	}
}




=head2 methods

 Usage     :	$name = $Service->methods()
 Function  :	retrieve all possible method calls for a given service
 Returns   :	listref of method names as strings
 Args      :	none

=cut

sub methods {
	my ($self) = @_;
	my $service = $self->_soapService;
	no strict;
	my @methods =  @{ join '::', ref $service, 'EXPORT_OK' };
	return \@methods
}


=head2 serviceName

 Usage     :	$name = $Service->serviceName()
 Function  :    get the name of the service
 Returns   :	string
 Args      :	none

=cut

=head2 _getServiceName

 Usage     :	$name = $Service->_getServiceName()
 Function  :	Internal method to retrieve the name of the service from the SOAP object
                In the case of Asynchronous services it will return the base name of
		the service (i.e. myService, rather than myService_submit).  This base name
		is not guaranteed to give you any output if you call it!
 Returns   :	string
 Args      :	none

=cut

sub _getServiceName {
	my ( $self ) = @_;
	my @methods = @{$self->methods};
	return shift @methods if scalar @methods <=1;  # in case of non-asynch services it is the only one there.
	foreach (@methods){
		next unless m/^(\S+)_submit/;
		return $1;
	}
	return undef
}



sub AUTOLOAD {
	no strict "refs";
	my ( $self, $newval ) = @_;
	$AUTOLOAD =~ /.*::(\w+)/;
	my $attr = $1;
	if ( $self->_accessible( $attr, 'write' ) ) {
		*{$AUTOLOAD} = sub {
			if ( defined $_[1] ) { $_[0]->{$attr} = $_[1] }
			return $_[0]->{$attr};
		};    ### end of created subroutine
###  this is called first time only
		if ( defined $newval ) {
			$self->{$attr} = $newval;
		}
		return $self->{$attr};
	} elsif ( $self->_accessible( $attr, 'read' ) ) {
		*{$AUTOLOAD} = sub {
			return $_[0]->{$attr};
		};    ### end of created subroutine
		return $self->{$attr};
	}

	# Must have been a mistake then...
	croak "No such method: $AUTOLOAD";
}
sub DESTROY { }

sub SOAP::Transport::HTTP::Client::get_basic_credentials {
	my ( $username, $password );
	print "ENTER USERNAME: ";
	$username = <STDIN>;
	chomp $username;
	print "ENTER PASSWORD: ";
	$password = <STDIN>;
	chomp $password;
	return $username => $password;
}

sub _LOG {
	return unless $debug;
	open LOG, ">>/tmp/ServiceCallLogOut.txt" or die "can't open logfile $!\n";
	print LOG join "\n", @_;
	print LOG "\n---\n";
	close LOG;
}

#
#
# --------------------------------------------------------------------------------------------------------
#
##
##
1;
