#$Id: Central.pm,v 1.8 2009/03/31 21:19:36 kawas Exp $
package MOBY::Client::Central;
use SOAP::Lite;

#use SOAP::Lite + trace;  # for debugging
use strict;
use Carp;
use XML::LibXML;
use MOBY::MobyXMLConstants;
use MOBY::Client::ServiceInstance;
use MOBY::Client::Registration;
use MOBY::Client::SimpleArticle;
use MOBY::Client::CollectionArticle;
use MOBY::Client::SecondaryArticle;
use MOBY::Client::OntologyServer;
use vars qw($AUTOLOAD @ISA $MOBY_server $MOBY_uri);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.8 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Client::Central - a client side wrapper for MOBY Central

=cut

=head1 SYNOPSIS

 use MOBY::Client::Central;
 my $Central = MOBY::Client::Central->new();

 my ($Services, $REG) = $Central->findService(
	    input =>[
              [DNASequence => ['NCBI_gi', 'NCBI_Acc']],
                ],
		expandObjects => 1
		);
 unless ($Services){
	 print "Service discovery failed with the following errror: ";
	 print $REG->message;
	 end
 }
 foreach my $SERVICE(@{$Services}){
    print "Service Name: ", $SERVICE->name, "\n";
    print "Service Provider: ", $SERVICE->authority,"\n";

 }

=cut

=head1 DESCRIPTION

Client side "wrapper" for communicating with
the MOBY::Central registry.

Used to do various read-only transactions with MOBY-Central.  Parses
MOBY::Central XML output into Perlish lists, hashes, and objects.  This should
be sufficient for most or all MOBY Client activities written in Perl.


=cut


=head1 AUTHORS

Mark Wilkinson (markw@illuminae.com)

BioMOBY Project:  http://www.biomoby.org


=cut

=head1 METHODS



=head2 new

 Usage     :	my $MOBY = MOBY::Client::Central->new(Registries => \%regrefs)
 Function  :	connect to one or more MOBY-Central
                registries for searching
 Returns   :	MOBY::Client::Central object

 ENV & PROXY : you can set environment variables to change the defaults.
             By default, a call to 'new' will initialize MOBY::Client::Central
             to connect to the default MOBY Central registry.  The location of
             this registry can be determined by examining the redirect from:
                http://biomoby.org/mobycentral
             If you wish to chose another registry by default, or if you need
             to set up additional connection details (e.g. PROXY) then you may
             set the following environment variables to whatever you
             require:
             MOBY_SERVER  (default http://moby.ucalgary.ca/moby/MOBY-Central.pl)
             MOBY_URI     (default http://moby.ucalgary.ca/MOBY/Central)
             MOBY_PROXY   (no default)

 Args      :    user_agent - optional.  The name of your software application
                Registries - optional.
                           - takes the form
                              {$NAME1 => {
                                    URL => $URL,
                                    URI => $URI,
                                    PROXY => $proxy_server},
                               $NAME2 => {
                                    URL => $URL,
                                    URI => $URI,
                                    PROXY => $proxy_server},
                                }
                            - by default this becomes
                            {mobycentral => {
                                 URL => 'http://moby.ucalgary.ca/moby/MOBY-Central.pl',
                                 URI => 'http://moby.ucalgary.ca/MOBY/Central'}
                             }
 Discussion:    Each registry must have a different
                NAME.  If you have more than one
                registry with the same NAME, only
                one will be used.  You can NAME them
                however you please - this is for
                internal reference only.  You will
                make subsequent calls on one or more
                of these registries by NAME, or by
                default on all registries.
 Notes     :    BE CAREFUL WITH OBJECT/SERVICE
                REGISTRATION!! YOU WILL REGISTER
                IN EVERY MOBY-CENTRAL YOU HAVE
                NAMED!  If you do not host a MOBY::Central
                database locally, or don't know
                better,then don't use any arguments
                at all, and everything should work 


=cut

my $debug = 0;
if ($debug) {
	open( OUT, ">/tmp/CentralLogOut.txt" )
	  || die "cant open logfile CentralLogOut.txt $!\n";
	close OUT;
}
{

	# Encapsulated:
	# DATA
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		Connections             => [ undef,         'read/write' ],
		default_MOBY_servername => [ 'mobycentral', 'read/write' ],
		default_MOBY_server     => [ '',		'read/write'],
		default_MOBY_uri 	=> [ 'http://biomoby.org/MOBY/Central', 'read/write' ],
		default_MOBY_proxy  => [ undef,  'read/write' ],
		default_MOBY_type   => [ 'soap', 'read/write' ],
		Registries          => [ undef,  'read/write' ],
		multiple_registries => [ undef,  'read/write' ],
		user_agent 		=> [ "MOBY-Client-Central", 'read/write'],
		

# SWITCH TO THESE FOR A LOCAL MOBY CENTRAL REGISTRY
#default_MOBY_server 	=> ['http://localhost/cgi-bin/MOBY-Central.pl', 	'read/write'],
#default_MOBY_uri		=> ['http://localhost/MOBY/Central',				'read/write'],
	  );

	#_____________________________________________________________
	# METHODS, to operate on encapsulated class data
	# Is a specified object attribute accessible in a given mode
	sub _accessible {
		my ( $self, $attr, $mode ) = @_;
		return 0 unless ( $mode && $_attr_data{$attr} );
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

	sub Connection {
		my ( $self, $desired ) = @_;
		if ($desired) {
		    my @registries = @{$self->Connections};
		    foreach (@registries){
			my ( $name, $type, $connect ) = @{$_};
			return ( $type, $connect ) if $name eq $desired;
		    }
		}
		else {
			my ( $name, $type, $connect ) = @{ $self->Connections->[0] };
			return ( $type, $connect );
		}
		return ( undef, undef );
	}
}

sub _call {

# this method replaces the former calls directly
# to teh SOAP_Connection, to give more flexibility
# in how that call is made
#  most subroutines in here do the following:
#    $return = $self->SOAP_connection->call(registerObjectClass => ($message))->paramsall;
# or $payload = $self->SOAP_connection($reg)->call('Relationships' => ($m))->paramsall;
# so intercept that and figure out if we are actually making a SOAP call or not
# and determine which registry it is
	my ( $self, $reg, $method, @params ) = @_;
	$reg = $self->default_MOBY_servername if $reg eq "default";
	$reg = $self->default_MOBY_servername if !$reg;
	my ( $type, $connect ) = $self->Connection($reg);
	return "<result>EXECUTION ERROR - registry $reg not found</result>"
	  unless ( $type && $connect );
	my $param = join "", @params;    # must be a single message!
	if ( lc($type) eq "get" ) {

		#print STDERR "executing CGI call\n";
		use LWP::UserAgent;
		my $ua = LWP::UserAgent->new;
		$ua->agent($self->user_agent);
		use CGI;
		$param =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/eg;
		my $paramstring = "?action=$method";
		$paramstring .= ";payload=$param" if $param;
		my $req = HTTP::Request->new( GET => $connect . $paramstring );
		my $res = $ua->request($req);
		if ( $res->is_success ) {
			return $res->content;
		}
		else {
			return
"<result>EXECUTION ERROR - unsuccessful call to MOBY Central registry named '$reg'</result>";
		}
	}
	else {

		#print STDERR "executing SOAP call\n";
		my @payload = $connect->call( $method =>  SOAP::Data->type('string' => $param ) )->paramsall;
		return @payload;
	}
}

sub new {
  my ( $caller, %args ) = @_;
  my $caller_is_obj = ref($caller);
  return $caller if $caller_is_obj;
  my $class = $caller_is_obj || $caller;
  my $proxy;
  my $self = bless {}, $class;
  foreach my $attrname ( $self->_standard_keys ) {
    if ( exists $args{$attrname} ) {
      $self->{$attrname} = $args{$attrname};
    }
    elsif ($caller_is_obj) {
      $self->{$attrname} = $caller->{$attrname};
    }
    else {
      $self->{$attrname} = $self->_default_for($attrname);
    }
  }
  $self->Connections( [] );    # initialize;
  
 do {
  my ($central, $ontologyserver) = _getDefaultCentral();
  $self->default_MOBY_server($central) if $central;
 } unless $ENV{MOBY_SERVER};

  # if user has set up preferred servers, then use those by default

  $self->default_MOBY_server( $ENV{MOBY_SERVER} ) if $ENV{MOBY_SERVER};
  $self->default_MOBY_uri( $ENV{MOBY_URI} )       if $ENV{MOBY_URI};
  $self->default_MOBY_type( $ENV{MOBY_TYPE} )     if $ENV{MOBY_TYPE};
  $self->default_MOBY_proxy( $ENV{MOBY_PROXY} )   if $ENV{MOBY_PROXY};
  if ( $self->Registries ) {
    my $regno = 0;
    my %reg   = %{ $self->Registries };
    while ( my ( $name, $acc ) = each %reg ) {
	$self->default_MOBY_servername($name);  # set the current as the default... if there is only one, then it becomes default, which is nice!  If ther eis more than one, then the person shold be explicitly calling one or the other anyway
	
      $regno++;            # count how many registries we have in total
      my $url  = $acc->{URL}  ? $acc->{URL}  : $self->default_MOBY_server;
      my $uri  = $acc->{URI}  ? $acc->{URI}  : $self->default_MOBY_uri;
      my $type = $acc->{TYPE} ? $acc->{TYPE} : $self->default_MOBY_type;
      my $proxy = $acc->{PROXY} ? $acc->{PROXY} : $self->default_MOBY_proxy;
      $type ||= 'soap';
      if ( lc($type) eq "get" ) {
	push @{ $self->Connections }, [ $name, $type, $url ];
      }
      else {
	my @soapargs;
	if ($proxy) {
	  @soapargs = ( $url, proxy => [ 'http' => $proxy ], user_agent => $self->user_agent, );
	}
	else {
	  @soapargs = ($url);
	}
	push @{ $self->Connections },
	  [
	   $name, $type,
	   SOAP::Lite->proxy(@soapargs, agent=>$self->user_agent )->uri($uri)->on_fault(
			     sub {
			       my ( $soap, $res ) = @_;
			       die ref $res
				 ? ("\nConnection to MOBY Central at '$uri' died because:\n\t" . $res->faultstring)
				   : ("Failed with status:" . $soap->transport->status),
				     "\n ERROR ERROR ERROR\n";
			     }
							    )
	  ];
      }
    } # Done iterating over multiple registries
    $self->multiple_registries( $regno - 1 )
      ; # one is not "multiple", it is just a change in default -> set to "false" if only one
  }
  else { # no registries specified
    $self->multiple_registries(0);
    if ( lc( $self->default_MOBY_type ) eq "get" ) {
      push @{ $self->Connections },
	[
	 $self->default_MOBY_servername, $self->default_MOBY_type,
	 $self->default_MOBY_server
	];
    }
    else {
      $self->Registries(
			{
			 $self->default_MOBY_servername => {
							    URL => $self->default_MOBY_server,
							    URI => $self->default_MOBY_uri
							   }
			}
		       );
      my @soapargs;
      if ( $self->default_MOBY_proxy ) {
	@soapargs = (
		     $self->default_MOBY_server,
		     proxy => [ 'http' => $self->default_MOBY_proxy ]
		    );
      }
      else {
	@soapargs = ( $self->default_MOBY_server );
      }
      push @{ $self->Connections }, 
	[
	 $self->default_MOBY_servername,
	 $self->default_MOBY_type,
	 SOAP::Lite->proxy(@soapargs, agent=>$self->user_agent )->uri( $self->default_MOBY_uri )
	 ->on_fault(
		    sub {
		      my ( $soap, $res ) = @_;
		      die ref $res
			? ("\nConnection to default MOBY Central died because:\n\t" . $res->faultstring)
			  : ("Failed with status:" . $soap->transport->status),
			    "\n ERROR ERROR ERROR\n";
		    }
		   )
	];
    }
  }
  return undef unless $self->Connection();    # gotta have at least one...
  return $self;
}


sub _getDefaultCentral {

	use LWP::UserAgent;
	use HTTP::Request::Common qw(HEAD);
 
	my $ua = LWP::UserAgent->new;
	my $req = HEAD 'http://biomoby.org/mobycentral';
	my $res = $ua->simple_request($req);
	my $mobycentral = $res->header('location');
 
	$req = HEAD 'http://biomoby.org/ontologyserver';
	$res = $ua->simple_request($req);
	my $ontologyserver = $res->header('location');
	return ($mobycentral, $ontologyserver);
}

=head2 registerObject  a.k.a registerObjectClass

 Usage     :	$REG = $MOBY->registerObject(%args)
 Usage     :	$REG = $MOBY->registerObjectClass(%args)
 Function  :	register a new type of MOBY Object
 Returns   :	MOBY::Registration object
 Args      :	objectType => "the name of the Object"
                description => "a human-readable description of the object"
                contactEmail => "your@email.address"
                authURI => "URI of the registrar of this object"
                Relationships => {
                    relationshipType1 => [
                        {object      => Object1, 
                         articleName => ArticleName1},
                        {object      => Object2,
                         articleName => ArticleName2}
                    ],
                    relationshipType2 => [
                        {object      => Object3, 
                         articleName => ArticleName3}
                    ]
                }

=cut

sub registerObjectClass {
	my ( $self, %a ) = @_;
	return $self->registerObject(%a);
}

sub registerObject {
	my ( $self, %a ) = @_;
	return $self->errorRegXML(
		"Function not allowed when querying multiple registries")
	  if $self->multiple_registries;
	return $self->errorRegXML(
"Contact email address (contactEmail parameter) is required for object registration"
	  )
	  if ( !$a{contactEmail} );
	my $term = $a{'objectType'} || "";
	my $desc = $a{'description'} || "";
	if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
		$desc = $1;
	}
	my $contactEmail = $a{'contactEmail'} || "";
	my $authURI = $a{'authURI'} || "";
	my %Relationships = %{ $a{'Relationships'} };
	my $clobber       = $a{'Clobber'} ? $a{'Clobber'} : 0;
	my $message       = "<registerObjectClass>
	<objectType>$term</objectType>
	<Description><![CDATA[$desc]]></Description>
	<authURI>$authURI</authURI>
	<contactEmail>$contactEmail</contactEmail>
	<Clobber>$clobber</Clobber>\n";

	while ( my ( $type, $objlistref ) = each %Relationships ) {
		$message .= "<Relationship relationshipType='$type'>\n";
		foreach my $objnamepair ( @{$objlistref} ) {
			my $object  = $objnamepair->{object};
			my $article = $objnamepair->{articleName};
			return $self->errorRegXML(
				"Object name missing from one of your $type relationships")
			  unless ($object);
			$article ||= "";
			$message .=
			  "<objectType articleName='$article'>$object</objectType>\n";
		}
		$message .= "</Relationship>\n";
	}
	$message .= "</registerObjectClass>";

#	my $return = $self->SOAP_connection->call(registerObjectClass => ($message))->paramsall;
	my ($return) = $self->_call( 'default', 'registerObjectClass', $message );
	return ( $self->parseRegXML($return) );
}

=head2 deregisterObject a.k.a. deregisterObjectClass

 Usage     :	$REG = $MOBY->deregisterObject(%args)
 Usage     :	$REG = $MOBY->deregisterObjectClass(%args)
 Function  :	deregister a MOBY Object
 Returns   :	MOBY::Registration object
 Args      :	objectType => $objectName (from Object ontology)


=cut

sub deregisterObjectClass {
	my ( $self, %a ) = @_;
	return $self->deregisterObject(%a);
}

sub deregisterObject {
	my ( $self, %a ) = @_;
	return $self->errorRegXML(
		"Function not allowed when querying multiple registries")
	  if $self->multiple_registries;
	my $id = $a{'objectType'} || "";
	my $message = "
		<deregisterObjectClass>
			<objectType>$id</objectType>
		</deregisterObjectClass>";

#	my $return = $self->SOAP_connection->call(deregisterObjectClass => ($message))->paramsall;
	my ($return) = $self->_call( 'default', 'deregisterObjectClass', $message );
	return ( $self->parseRegXML($return) );
}



=head2 registerServiceType

 Usage     :	$REG = $MOBY->registerServiceType(%args)
 Function  :	register a new MOBY Service type
 Returns   :	MOBY::Registration object
 Args      :	serviceType        => $serviceType
                description => "human readable description"
                Relationships => {$relationshipType1 => \@services,
                                  $relationshipType2 => \@services}
                contactEmail => "your@email.address.here"
                authURI => "your.authority.info"

=cut

sub registerServiceType {
	my ( $self, %a ) = @_;
	return $self->errorRegXML(
		"Function not allowed when querying multiple registries")
	  if $self->multiple_registries;
	my $type = $a{'serviceType'} || "";
	my $desc = $a{'description'};
	if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
		$desc = $1;
	}
	$desc ||= "";
	my $email = $a{'contactEmail'} || "";
	my $auth = $a{'authURI'} || "";
	my %Relationships = %{ $a{'Relationships'} };
	my $message       = "
		<registerServiceType>
			<serviceType>$type</serviceType>
			<Description><![CDATA[$desc]]></Description>
			<contactEmail>$email</contactEmail>
			<authURI>$auth</authURI>\n";

	while ( my ( $type, $servlistref ) = each %Relationships ) {
		$message .= "<Relationship relationshipType='$type'>\n";
		foreach my $servicetype ( @{$servlistref} ) {
			$message .= "<serviceType>$servicetype</serviceType>\n";
		}
		$message .= "</Relationship>\n";
	}
	$message .= "</registerServiceType>";

#	my $return = $self->SOAP_connection->call(registerServiceType => ($message))->paramsall;
	my ($return) = $self->_call( 'default', 'registerServiceType', $message );
	return ( $self->parseRegXML($return) );
}

=head2 deregisterServiceType

 Usage     :	$REG = $MOBY->deregisterServiceType(%args)
 Function  :	deregister a deprecated MOBY Service Type
 Returns   :	MOBY::Registration object
 Args      :	serviceType => $serviceType (from ontology)


=cut

sub deregisterServiceType {
	my ( $self, %a ) = @_;
	return $self->errorRegXML(
		"Function not allowed when querying multiple registries")
	  if $self->multiple_registries;
	my $id = $a{'serviceType'} || "";
	my $message = "
		<deregisterServiceType>
			<serviceType>$id</serviceType>
		</deregisterServiceType>";

#	my $return = $self->SOAP_connection->call(deregisterServiceType => ($message))->paramsall;
	my ($return) = $self->_call( 'default', 'deregisterServiceType', $message );
	return ( $self->parseRegXML($return) );
}

=head2 registerNamespace

 Usage     :	$REG = $MOBY->registerNamespace(%args)
 Function  :	register a new Namespace
 Returns   :	MOBY::Registration object
 Args      :	namespaceType => $namespaceType (required)
                authURI => your.authority.URI (required)
                description => "human readable description of namespace" (required)
                contactEmail => "your@address.here" (required)


=cut

sub registerNamespace {
	my ( $self, %a ) = @_;
	return $self->errorRegXML(
		"Function not allowed when querying multiple registries")
	  if $self->multiple_registries;
	my $type = $a{'namespaceType'} || "";
	my $authURI = $a{'authURI'} || "";
	my $desc = $a{'description'};
	if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
		$desc = $1;
	}
	$desc ||= "";
	my $contact = $a{'contactEmail'} || "";
	my $message = "
		<registerNamespace>
			<namespaceType>$type</namespaceType>
			<Description><![CDATA[$desc]]></Description>
			<authURI>$authURI</authURI>	
			<contactEmail>$contact</contactEmail>
		</registerNamespace>";

#	my $return = $self->SOAP_connection->call(registerNamespace => ($message))->paramsall;
	my ($return) = $self->_call( 'default', 'registerNamespace', $message );
	return ( $self->parseRegXML($return) );
}

=head2 deregisterNamespace

 Usage     :	$REG = $MOBY->deregisterNamespace(%args)
 Function  :	deregister a deprecated MOBY Namespace
 Returns   :	MOBY::Registration object
 Args      :	namespaceType => $mynamespaceType (from ontology)


=cut

sub deregisterNamespace {
	my ( $self, %a ) = @_;
	return $self->errorRegXML(
		"Function not allowed when querying multiple registries")
	  if $self->multiple_registries;
	my $id = $a{'namespaceType'} || "";
	my $message = "
		<deregisterNamespace>
			<namespaceType>$id</namespaceType>
		</deregisterNamespace>";

#	my $return = $self->SOAP_connection->call(deregisterNamespace => ($message))->paramsall;
	my ($return) = $self->_call( 'default', 'deregisterNamespace', $message );
	return ( $self->parseRegXML($return) );
}

=head2 registerService

 Usage     :	$REG = $MOBY->registerService(%args)
 Function  :	register a new MOBY Service instance
 Returns   :	MOBY::Registration object
 Common Required Args :

     serviceName  => $serviceName,  
     serviceType  => $serviceType,  
     authURI      => $authURI,      
     contactEmail => "your@mail.address",      
     description => $human_readable_description, 
     category  =>  "moby" | "cgi-async" | "cgi" | "moby-async" | "doc-literal" | "doc-literal-async"
     URL    =>  $URL_TO_SERVICE  (or URL to WSDL document for wsdl-type services)

    input:	listref; (articleName may be undef) 
            input =>[
                     [articleName1,[objType1 => \@namespaces]], # Simple
                     [articleName2,       [[objType2 => \@namespaces]]], # collection of one object type
                     [articleName3,[[objType3 => \@namespaces],
                                    [objType4 => \@namespaces]]] # collection of multiple object types
                    ]


    output:  listref; (articleName may be undef)
            output =>[
                 [articleName1,[objType1 => \@namespaces]], # Simple
                 [articleName2,[[objType2 => \@namespaces]]], # collection of one object type
                 [articleName3,[[objType3 => \@namespaces],
                                [objType4 => \@namespaces]]] # collection of multiple object types
                  ]

    secondary: hashref
            secondary => {parametername1 => {
                           datatype => TYPE,
			   description => "cutoff value",
                           default => DEFAULT,
                           max => MAX,
                           min => MIN,
                           enum => [one, two]},
                          parametername2 => {
                           datatype => TYPE,
			   description => "e-value",
                           default => DEFAULT,
                           max => MAX,
                           min => MIN,
                           enum => [one, two]}
                          }



=cut

sub registerService {
	my ( $self, %a ) = @_;
	return $self->errorRegXML(
		"Function not allowed when querying multiple registries")
	  if $self->multiple_registries;
	my $name = $a{serviceName} || "";
	my $type = $a{serviceType} || "";
	my $authURI = $a{authURI} || "";
	my $email = $a{contactEmail} || "";
	my $URL = $a{URL} || "";
	my $desc = $a{description} || "";

	if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
		$desc = $1;
	}
	#TODO ensure that sigURL and URL are valid urls
	# ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))? <- matches any uri
	# ^((([^:/?#]+):)?(//)?[\w]+\.[\w](\.[w])*((\/|\.)?[\w]+)*)$ <- my version
	my $signatureURL = $a{signatureURL} || "";
	my $Category = lc( $a{category} );
	chomp $Category;
	$Category ||= "";

	#____________call RDFagent__________________________________________________
	if ( $signatureURL ne "" ) {
		my $ch = 0;
		my $sign_req;
		foreach $sign_req ( $name, $type, $authURI, $email, $URL, $desc,
			$Category )
		{
			if ( $sign_req ne "" ) {
				$ch = 1;

			}
		}
		if ( $ch == 0 ) {
			# print "call Agent\n";
			my $message = "
			<registerService>
			<Category></Category>
			<serviceName></serviceName>
			<serviceType></serviceType>
			<Description></Description>
                <signatureURL>$signatureURL</signatureURL>
			<URL></URL>
			<authURI></authURI>
			<contactEmail></contactEmail>
       		</registerService>";
			my ($return) =
			  $self->_call( 'default', 'registerService', $message );
			return ( $self->parseRegXML($return) );

		}
	}

#____________________________________________________________________________________________
	return $self->errorRegXML(
"Only 'moby', 'cgi', 'cgi-async', 'moby-async', 'doc-literal', 'doc-literal-async' Service Categories are currently allowed - you gave me $Category"
	  )
	  unless ( ( $Category eq 'moby' )
			  || ( $Category eq 'moby-async' )
			  || ( $Category eq 'cgi-async' )
			  || ( $Category eq 'doc-literal' )
			  || ( $Category eq 'doc-literal-async' )
			  || ( $Category eq 'cgi' ));
	return $self->errorRegXML(
"All Fields Required:  serviceName, serviceType, authURI, contactEmail, URL, description, Category, input, output, secondary"
	  )
	  unless ( $name
		&& $type
		&& $authURI
		&& $email
		&& $URL
		&& $desc
		&& $Category );
	my $message = "
		<registerService>
			<Category>$Category</Category>
			<serviceName>$name</serviceName>
			<serviceType>$type</serviceType>
			<Description><![CDATA[$desc]]></Description>
                        <signatureURL>$signatureURL</signatureURL>
			<URL>$URL</URL>
			<authURI>$authURI</authURI>
			<contactEmail>$email</contactEmail>";


		my %SEC;
		if ( $a{'secondary'} && ( ref( $a{'secondary'} ) eq 'HASH' ) ) {
			%SEC = %{ $a{secondary} };
		}
		elsif ( $a{'secondary'} && ( ref( $a{'secondary'} ) ne 'HASH' ) ) {
			return $self->errorRegXML(
				"invalid structure of secondary parameters.  Expected hashref."
			);
		}
		my %funkyhash = ( Input => $a{input}, Output => $a{output} );
		while ( my ( $inout, $param ) = each %funkyhash ) {
			my $inout_lc    = lc($inout);
			my @ALLARTICLES = @{$param};
			$message .= "<${inout_lc}Objects><${inout}>\n";

#		input =>[
#					[articleName1,[objType1 => \@namespaces]], # Simple
#                    [articleName2,       [[objType2 => \@namespaces]]], # collection of one object type
#                    [articleName3,[[objType3 => \@namespaces],
#		                    [objType4 => \@namespaces]]] # collection of multiple object types (THIS IS NOW ILLEGAL!)
#                    ]
			foreach my $article (@ALLARTICLES) {
				my ( $articleName, $def ) = @{$article};
				$articleName ||= "";
				my @Objects;    #
				unless ( ref($def) eq 'ARRAY') { # $def = [objType => \@ns]  or $def=[[objType => \@ns]]
					return $self->errorRegXML("invalid structure of $inout objects, expected SINGLE arrayref for article $articleName as required by the 0.86 API");
				}
				my @objectdefs;
				if ( ( ref $def->[0] ) eq 'ARRAY' ) {    # collection $def->[0] = [objType => \@ns]
					    # def= [[objType2 => [ns3, ns4...]], ...]
					$message .= "<Collection articleName='$articleName'>\n";
					if (scalar(@{$def->[0]} > 2)){
					  return $self->errorRegXML("invalid structure of $inout objects.  Collections may not have more than one Simple content type as per API version 0.86");
					}
                                        @objectdefs = @{$def};
					if (scalar(@objectdefs) > 1){
					  return $self->errorRegXML("invalid structure of $inout objects.  Collections may not have more than one Simple content type as per API version 0.86");
					}
				} else {    # Simple $def->[0] = objType
				  # def = [objType1 => [ns1, ns2...]],
				  @objectdefs = ($def);
				}
				foreach my $objectdef (@objectdefs) {
					if ( ref( $def->[0] ) eq 'ARRAY' ) {
						$message .= "<Simple>\n";
					}
					else {
						$message .= "<Simple articleName='$articleName'>\n";
					}
					my ( $type, $Namespaces ) = @{$objectdef};
					$type ||= "";
					$message .= "<objectType>$type</objectType>\n";
					unless ( ref($Namespaces) eq 'ARRAY' ) {
						return $self->errorRegXML(
"invalid structure of $inout namespaces for object $type in article $articleName; expected arrayref"
						);
					}
					foreach my $ns ( @{$Namespaces} ) {
						$message .= "<Namespace>$ns</Namespace>\n";
					}
					$message .= "</Simple>\n";
				}
				if ( ref( $def->[0] ) eq  'ARRAY' ) {
					$message .= "</Collection>\n";
				}
			}
			$message .= "</${inout}></${inout_lc}Objects>\n";
		}

		#		secondary => {parametername1 => {datatype => TYPE,
		#										default => DEFAULT,
		#										max => MAX,
		#										min => MIN,
		#										enum => [one, two]},
		#					parametername2 => {datatype => TYPE,
		#										default => DEFAULT,
		#										max => MAX,
		#										min => MIN,
		#										enum => [one, two]}
		#					  }
		#
		$message .= "<secondaryArticles>\n";
		while ( my ( $param, $desc ) = each %SEC ) {
			unless ( ref($desc) eq 'HASH' ) {
				return $self->errorRegXML( "invalid structure of secondary article $param; expected hashref of limitations"
				);
			}
			my %data     = %{$desc};
			my $default  = defined($data{default})?$data{default}:"";
			my $max      = defined($data{max})?$data{max}:"";
			my $min      = defined($data{min})?$data{min}:"";
			my $descr      = defined($data{description})?$data{description}:"";
			my $datatype = $data{datatype} || "";
			my $enums    = $data{enum} || [];
			unless ($datatype) {
				return $self->errorRegXML("a secondaryArticle must contain at least a datatype value in secondary article $param"
				);
			}
			unless ( $datatype =~ /Integer|Float|String|DateTime|Boolean/ )
			{
				return $self->errorRegXML("a secondaryArticle must have a datatype of Integer, Float, String, Boolean or DateTime"
				);
			}
			unless ( ref($enums) eq 'ARRAY' ) {
				return $self->errorRegXML("invalid structure of enum limits in secondary article $param; expected arrayref"
				);
			}
			my @enums = @{$enums};
			$message .= "<Parameter articleName='$param'>\n";
			$message .= "<default>$default</default>\n";
			$message .= "<description>$descr</description>\n";
			$message .= "<datatype>$datatype</datatype>\n";
			$message .= "<max>$max</max>\n";
			$message .= "<min>$min</min>\n";
			foreach (@enums) {
				$message .= "<enum>$_</enum>\n";
			}
			$message .= "</Parameter>\n";
		}
		$message .= "</secondaryArticles>\n";
		$message .= "</registerService>";


	$debug && &_LOG(" message\n\n$message\n\n");

	my ($return) = $self->_call( 'default', 'registerService', $message );

#_______call a new version RDFbuilder (by Eddie Kawas) _________________________________________
	my $reg = $self->parseRegXML($return);
 
	return $reg;

#_______________________________________________________________________________________________

}

=head2 registerServiceWSDL

 Usage     :	Needs documentation

=cut

sub registerServiceWSDL {
	my ( $self, %a ) = @_;
	return $self->errorRegXML(
		"Function not allowed when querying multiple registries")
	  if $self->multiple_registries;
	my $message = "";

#	my $return = $self->SOAP_connection->call(registerServiceWSDL => ($message))->paramsall;
	my ($return) = $self->_call( 'default', 'registerServiceWSDL', $message );

	return ( $self->parseRegXML($return) );
}

=head2 deregisterService

 Usage     :	$REG = $MOBY->deregisterService(%args)
 Function  :	deregister a registered MOBY Service
 Returns   :	MOBY::Registration object
 Args      :	serviceName => $serviceID, authURI => $authority


=cut

sub deregisterService {
	my ( $self, %a ) = @_;
	return $self->errorRegXML(
		"Function not allowed when querying multiple registries")
	  if $self->multiple_registries;
	my $name = $a{'serviceName'};
	my $auth = $a{'authURI'};
	( defined($name) && defined($auth) ) || return (
		&parseRegXML( "
		<MOBYRegistration>
			<id></id>
			<success>0</success>
			<message><![CDATA[you did not pass a valid service Identifier]]></message>
		</MOBYRegistration>" )
	);
	my $message = "
		<deregisterService>
			<serviceName>$name</serviceName>
			<authURI>$auth</authURI>
		</deregisterService>";

#	my $return = $self->SOAP_connection->call(deregisterService => ($message))->paramsall;
	my ($return) = $self->_call( 'default', 'deregisterService', $message );
	return ( $self->parseRegXML($return) );
}

=head2  findService

 Usage     :	($ServiceInstances, $RegObject) = $MOBY->findService(%args)
 Function  :	Find services that match certain search criterion
 Returns   :	ON SUCCESS: arrayref of MOBY::Client::ServiceInstance objects, and undef
				ON FAILURE: undef, and a MOBY::Registration object indicating the reason for failure
 Args      :	
	 Registry  => which registry do you want to search (optional)
     serviceName  => $serviceName,  (optional)
     serviceType  => $serviceType,  (optional)
     authURI      => $authURI,      (optional)
     authoritative => 1,    (optional)
     category  =>  "moby" | "cgi" | "moby-async"  (optional)
     expandObjects => 1,    (optional)
     expandServices => 1,    (optional)
     URL    =>  $URL_TO_SERVICE    (optional)
     keywords => [kw1, kw2, kw3]    (optional)
     input =>[    (optional)
              [objType1 => [ns1, ns2...]], # Simple
              [[objType2 => [ns3, ns4...]]], # collection of one object type
              [[objType3 => [ns3, ns4...]],
               [objType4 => [ns5, ns6...]]], # collection of multiple object types
              ]
     output =>[    (optional)
               [objType1 => [ns1, ns2...]], # Simple
               [[objType2 => [ns3, ns4...]]], # collection of one object type
               [[objType3 => [ns3, ns4...]],
                [objType4 => [ns5, ns6...]]], # collection of multiple object types
              ]


=cut

sub findService {
	my ( $self, %a ) = @_;
	my $reg = ( $a{Registry} ) ? $a{Registry} : $self->default_MOBY_servername;
	my $id = $a{'serviceID'};
	my $servicename = $a{'serviceName'} || "";
	my $authoritative = $a{'authoritative'} || "";
	my $serviceType = $a{'serviceType'} || "";
	my $authURI = $a{'authURI'} || "";
	my $category = $a{'category'} || "";
	my $exObj = $a{'expandObjects'} || 0;
	my $exServ = $a{'expandServices'} || 0;
	my $kw = $a{'keywords'} || [];
	ref($kw) eq 'ARRAY' || return (
		undef,
		$self->errorRegXML(
			"invalid structure of keywords.  Expected arrayref"
		)
	);
	my @kw      = @{$kw};
	my $message = "<findService>\n";
	defined($authoritative)
	  && ( $message .= "<authoritative>$authoritative</authoritative>\n" );
	$category    && ( $message .= "<Category>$category</Category>\n" );
	$serviceType && ( $message .= "<serviceType>$serviceType</serviceType>\n" );
	$servicename && ( $message .= "<serviceName>$servicename</serviceName>\n" );
	$authURI     && ( $message .= "<authURI>$authURI</authURI>\n" );
	defined($exObj)
	  && ( $message .= "<expandObjects>$exObj</expandObjects> \n" );
	defined($exServ)
	  && ( $message .= "<expandServices>$exServ</expandServices>\n" );

	if ( scalar(@kw) ) {
		$message .= "	<keywords>\n";
		foreach my $kwd (@kw) {
			$message .= "<keyword>$kwd</keyword>\n";
		}
		$message .= "</keywords>\n";
	}

	#$a{input} = [[]] unless (defined $a{input});
	#$a{output} = [[]] unless (defined $a{output});
	if ( defined $a{input} && ( ref( $a{input} ) ne 'ARRAY' ) ) {
		return (
			undef,
			$self->errorRegXML(
"invalid structure of input objects, expected arrayref for input"
			)
		);
	}
	if ( defined $a{output} && ( ref( $a{output} ) ne 'ARRAY' ) ) {
		return (
			undef,
			$self->errorRegXML(
"invalid structure of output objects, expected arrayref for output"
			)
		);
	}
	my %funkyhash;
	$funkyhash{Input}  = $a{input}  if ( defined $a{input} );
	$funkyhash{Output} = $a{output} if ( defined $a{output} );

  #input =>[
  #         [objType1 => [ns1, ns2...]], # Simple
  #         [[objType2 => [ns3, ns4...]]], # collection of one object type
  #         [[objType3 => [ns3, ns4...]],
  #          [objType4 => [ns5, ns6...]]], # collection of multiple object types
  #         ]
	while ( my ( $inout, $param ) = each %funkyhash ) {
		die "no inout parameter from teh funkyhash" unless defined $inout;
		die "no param parameter from teh funkyhash" unless defined $param;
		die "param parameter should be a listref"
		  unless ( ref($param) eq 'ARRAY' );
		my $inout_lc = lc($inout);
		my @PARAM    = @{$param};
		$message .= "<${inout_lc}Objects><${inout}>\n";
		foreach my $param (@PARAM) {
			unless ( ref($param) eq 'ARRAY' ) {
				return (
					undef,
					$self->errorRegXML(
"invalid structure of $inout objects, expected arrayref of class and \@namespaces"
					)
				);
			}
			my ( $class, $namespaces ) = @{$param};
			die "no class part of param " unless defined $class;

			#warn "no namespace part of the param" unless defined $namespaces;
			my @objectdefs;
			if ( ref $class  eq 'ARRAY' ) {    # collection
				$message .= "<Collection>\n";
				@objectdefs = $class;
			}
			else {                                 # Nipple
				@objectdefs = ($param);
			}
			foreach my $objectdef (@objectdefs) {
				$message .= "<Simple>\n";
				my ( $type, $Namespaces ) = @{$objectdef};
				die "type is missing from objectdef " unless $type;
				$message .= "<objectType>$type</objectType>\n";
				if ( defined($Namespaces)
					&& ( ref($Namespaces) ne 'ARRAY' ) )
				{
					return (
						undef,
						$self->errorRegXML(
"invalid structure of $inout namespaces for object $type; expected arrayref"
						)
					);
				}
				foreach my $ns ( @{$Namespaces} ) {
					next unless $ns;
					$message .= "<Namespace>$ns</Namespace>\n";
				}
				$message .= "</Simple>\n";
			}
			if ( ref($class) eq 'ARRAY' ) {
				$message .= "</Collection>\n";
			}
		}
		$message .= "</${inout}></${inout_lc}Objects>\n";
	}
	$message .= "</findService>\n";

#	my $return = $self->SOAP_connection($reg)->call('findService' => ($message))->paramsall;
	my ($return) = $self->_call( $reg, 'findService', $message );
	return ( $self->_parseServices( $reg, $return ), undef );
}

=head2 retrieveService
 
 Usage     :	$WSDL = $MOBY->retrieveService($ServiceInstance)
 Function  :	get the WSDL definition of the service with this name/authority URI
 Returns   :	a WSDL string
 Args      :	The ServiceInstance object for that service (from findService call)

=cut

sub retrieveService {
	my ( $self, $SI ) = @_;
	return undef unless $SI && $SI->isa('MOBY::Client::ServiceInstance');
	my $auth = $SI->authority;
	my $name = $SI->name;
	my $reg  = $SI->registry;
	return undef unless ( $auth && $name && $self->Connection($reg) );
	my $message = "
	<retrieveService>
	" . ( $SI->XML ) . "
	</retrieveService>";

	my ($return) = $self->_call( $reg, 'retrieveService', $message );
	my $parser = XML::LibXML->new();
	my $doc   = $parser->parse_string($return);
	my $de    = $doc->getDocumentElement;
	my @child = $de->childNodes;
	my $content;
	foreach (@child) {
		$debug && &_LOG( getNodeTypeName($_), "\t", $_->toString, "\n" );
		if ( $_->nodeType == TEXT_NODE ) {
			$content .= $_->nodeValue;    #else try $_->textContent
		}
		else {
			$content .= $_->toString;
		}
	}
	$content =~ s/^\n//gs;
	$content =~ s/<!\[CDATA\[((?>[^\]]+))\]\]>/$1/gs;

	return $content;
}


=head2 retrieveResourceURLs

 Usage     :	$names = $MOBY->retrieveResourceURLs()
 Function  :	get a hash of the URL's for each of the MOBY ontologies
 Returns   :	hashref to the following hash
                $names{Ontology} = [URL1, URL2,...]
 Args      :	none

=cut

sub retrieveResourceURLs {
	my ($self, %args) = shift;
	my $reg = $args{registry};
	$reg = $reg ? $reg : $self->default_MOBY_servername;
	return undef unless ( $self->Connection($reg) );
	my ($return) = $self->_call( $reg, 'retrieveResourceURLs', "" );
	my $parser = XML::LibXML->new();
	my $doc        = $parser->parse_string($return);
	my $root       = $doc->getDocumentElement;
	my $urls_list = $root->childNodes;
	my %urls;
	for ( my $x = 1 ; $x <= $urls_list->size() ; $x++ ) {
		next unless $urls_list->get_node($x)->nodeType == ELEMENT_NODE;
		my $ontology = $urls_list->get_node($x)->getAttributeNode('name')->getValue;
		my $url = $urls_list->get_node($x)->getAttributeNode('url')->getValue;
		push @{ $urls{$ontology} }, $url
	}
	return \%urls;
}


=head2 retrieveServiceNames

 Usage     :	$names = $MOBY->retrieveServiceNames(%args)
 Function  :	get a (redundant) list of all registered service names
                (N.B. NOT service types!)
 Returns   :	hashref to the following hash
                $names{$AuthURI} = [serviceName_1, serviceName_2, serviceName3...]
 Args      :	registry => $reg_name:  name of registry you wish to retrieve from (optional)
                as_lsid => $boolean: return service names as their corresponding LSID's (default off)

=cut

sub retrieveServiceNames {
	my ($self, %args) = @_;
	my $reg = $args{registry};
	my $aslsid = $args{as_lsid};
	
	$reg = $reg ? $reg : $self->default_MOBY_servername;
	return undef unless ( $self->Connection($reg) );

#    my $return = $self->SOAP_connection($reg)->call('retrieveServiceNames' => (@_))->paramsall;
	my ($return) = $self->_call( $reg, 'retrieveServiceNames', "" );
	my $parser = XML::LibXML->new();
	my $doc        = $parser->parse_string($return);
	my $root       = $doc->getDocumentElement;
	my $names_list = $root->childNodes;
	my %servicenames;
	for ( my $x = 1 ; $x <= $names_list->size() ; $x++ ) {
		next unless $names_list->get_node($x)->nodeType == ELEMENT_NODE;
		my $name =
		  $names_list->get_node($x)->getAttributeNode('name')->getValue;
		my $auth =
		  $names_list->get_node($x)->getAttributeNode('authURI')->getValue;
		my $lsid = $names_list->get_node($x)->getAttributeNode('lsid');
		if ($lsid){
		    $lsid = $lsid->getValue;
		} else {
		    $lsid = $name;
		}
		$lsid ||=$name;
		push @{ $servicenames{$auth} }, $aslsid?$lsid:$name;
	}
	return \%servicenames;
}

=head2 retrieveServiceProviders

 Usage     :	@URIs = $MOBY->retrieveServiceProviders([$reg_name])
 Function  :	get the list of all provider's AuthURI's
 Returns   :	list of service provider URI strings
 Args      :	$reg_name:  name of registry you wish to retrieve from (optional) 

=cut

sub retrieveServiceProviders {
	my ($self) = shift;
	my $reg = shift;
	$reg = $reg ? $reg : $self->default_MOBY_servername;
	return undef unless ( $self->Connection($reg) );

#	my $return    = $self->SOAP_connection($reg)->call('retrieveServiceProviders' => (@_))->paramsall;
	my ($return) = $self->_call( $reg, 'retrieveServiceProviders', "" );
	my $parser = XML::LibXML->new();
	my $doc       = $parser->parse_string($return);
	my $root      = $doc->getDocumentElement;
	my $providers = $root->childNodes;
	my @serviceproviders;
	for ( my $x = 1 ; $x <= $providers->size() ; $x++ ) {
		next unless $providers->get_node($x)->nodeType == ELEMENT_NODE;
		push @serviceproviders,
		  $providers->get_node($x)->getAttributeNode('name')->getValue;
	}
	return @serviceproviders;
}

=head2 retrieveServiceTypes

 Usage     :	$types = $MOBY->retrieveServiceTypes(%args)
 Function  :	get the list of all registered service types
 Returns   :	hashref of $types{$type} = $definition
 Args      :	registry => $reg_name:  name of registry you wish to retrieve from (optional)
                as_lsid  => $boolean:  return the $type as its corresponding LSID (defualt off)

=cut

sub retrieveServiceTypes {
	my ($self, %args) = shift;
	my $reg = $args{registry};
	my $as_lsid = $args{as_lsid};
	
	$reg = $reg ? $reg : $self->default_MOBY_servername;
	return undef unless ( $self->Connection($reg) );

#	my $return = $self->SOAP_connection($reg)->call('retrieveServiceTypes' => (@_))->paramsall;
	my ($return) = $self->_call( $reg, 'retrieveServiceTypes', "" );
	my $parser = XML::LibXML->new();
	my $doc   = $parser->parse_string($return);
	my $root  = $doc->getDocumentElement;
	my $types = $root->childNodes;
	my %servicetypes;
	for ( my $x = 1 ; $x <= $types->size() ; $x++ ) {
		next unless $types->get_node($x)->nodeType == ELEMENT_NODE;
		my $type = $types->get_node($x)->getAttributeNode('name')->getValue;
		my $lsid = $types->get_node($x)->getAttributeNode('lsid');
		if ($lsid){
		    $lsid = $lsid->getValue;
		} else {
		    $lsid = $type;
		}
		my $desc;
		for
		  my $elem ( $types->get_node($x)->getElementsByTagName('Description') )
		{
			$desc = $elem->firstChild->toString;
			if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
				$desc = $1;
			}
		}
		$desc =~ s/<!\[CDATA\[((?>[^\]]+))\]\]>/$1/gs;
		$servicetypes{$as_lsid?$lsid:$type} = $desc;
	}
	return \%servicetypes;
}


=head2 retrieveServiceTypesFull

 Usage     :	$types = $MOBY->retrieveServiceTypesFull(%args)
 Function  :	get all details of all service types
 Returns   :	hashref of $types{$type} = {Description => "definition",
                                            authURI  => "authority.uri.here",
					    contactEmail => "email@addy.here",
					    ISA => "parentType", # possibly empty string ""
					    ISA_LSID => "urn:lsid...parentLSID"} # possibly empty string ""
 Args      :	registry => $reg_name:  name of registry you wish to retrieve from (optional)
                as_lsid  => $boolean:  return the $type as its corresponding LSID (defualt off)

=cut


sub retrieveServiceTypesFull {
	my ($self, %args) = shift;
	my $reg = $args{registry};
	my $as_lsid = $args{as_lsid};
	
	$reg = $reg ? $reg : $self->default_MOBY_servername;
	return undef unless ( $self->Connection($reg) );

#	my $return = $self->SOAP_connection($reg)->call('retrieveServiceTypes' => (@_))->paramsall;
	my ($return) = $self->_call( $reg, 'retrieveServiceTypes', "" );
	my $parser = XML::LibXML->new();
	my $doc   = $parser->parse_string($return);
	my $root  = $doc->getDocumentElement;
	my $types = $root->childNodes;
	my %servicetypes;
	for ( my $x = 1 ; $x <= $types->size() ; $x++ ) {
		next unless $types->get_node($x)->nodeType == ELEMENT_NODE;
		my $type = $types->get_node($x)->getAttributeNode('name')->getValue;
		my $lsid = $types->get_node($x)->getAttributeNode('lsid');
		if ($lsid){
		    $lsid = $lsid->getValue;
		} else {
		    $lsid = $type;
		}
		my ($desc, $auth, $email, $ISA, $ISA_LSID) = ("","","","","");
		for
		  my $elem ( $types->get_node($x)->getElementsByTagName('Description') )
		{
			$desc = $elem->firstChild->toString;
			if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
				$desc = $1;
			}
		}
		for
		  my $elem ( $types->get_node($x)->getElementsByTagName('authURI') )
		{
			$auth = $elem->firstChild->toString;
			if ( $auth =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
				$auth = $1;
			}
		}
		for
		  my $elem ( $types->get_node($x)->getElementsByTagName('contactEmail') )
		{
			$email = $elem->firstChild->toString;
			if ( $email =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
				$email = $1;
			}
		}
		for
		  my $elem ( $types->get_node($x)->getElementsByTagName('ISA') )
		{
			$ISA = $elem->firstChild;
			$ISA = $ISA?$ISA->toString:"";
			if ( $email =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
				$email = $1;
			}
			$ISA_LSID = $elem->getAttributeNode('lsid')->getValue;
		}

		$desc =~ s/<!\[CDATA\[((?>[^\]]+))\]\]>/$1/gs;  # somehow these CDATA elements are nested sometimes???
		$servicetypes{$as_lsid?$lsid:$type} = {Description => $desc, authURI => $auth, contactEmail => $email, ISA => $ISA, ISA_LSID => $ISA_LSID};
	}
	return \%servicetypes;
}


=head2 retrieveObjectNames

 Usage     :	$names = $MOBY->retrieveObjectNames(%args)
 Function  :	get the list of all registered Object types
 Returns   :	hashref of hash:
                $names{$name} = $definition
 Args      :	registry => $reg_name:  name of registry you wish to retrieve from (optional)
                as_lsid  => $boolean:  return $name as its correspnding LSID (optional default off)

=cut

sub retrieveObjectNames {
	my ($self, %args) = @_;
	my $reg = $args{registry};
	my $as_lsid = $args{as_lsid};
	$reg = $reg ? $reg : $self->default_MOBY_servername;
	return undef unless ( $self->Connection($reg) );
	my ($return) = $self->_call( $reg, 'retrieveObjectNames', "" );
	my $parser = XML::LibXML->new();
	my $doc     = $parser->parse_string($return);
	my $root    = $doc->getDocumentElement;
	my $obnames = $root->childNodes;
	my %objectnames;
	for ( my $x = 1 ; $x <= $obnames->size() ; $x++ ) {
		next unless $obnames->get_node($x)->nodeType == ELEMENT_NODE;
		my $name = $obnames->get_node($x)->getAttributeNode('name')->getValue;
		my $lsid = $obnames->get_node($x)->getAttributeNode('lsid');
		if ($lsid){
		    $lsid = $lsid->getValue;
		} else {
		    $lsid = $name;
		}
		my $desc;
		for my $elem (
			$obnames->get_node($x)->getElementsByTagName('Description') )
		{
			$desc = $elem->firstChild->toString;
			if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
				$desc = $1;
			}
		}
		$desc =~ s/<!\[CDATA\[((?>[^\]]+))\]\]>/$1/gs;
		$objectnames{$as_lsid?$lsid:$name} = $desc;
	}
	return \%objectnames;
}


=head2 retrieveObjectDefinition

 Usage     : $DEF = $MOBY->retrieveObjectDefinition(objectType => $objectType)
 Function  : retrieve the $XML that was used to register an object and its relationships
 Returns   : hashref, identical to the hash sent during Object registration, plus
             an additional XML hash key that contains the actual XML containing
             the object definition as sent by MOBY Central (used for a visual
             overview, rather than parsing all of the hash keys)
             objectType => "the name of the Object"
             objectLSID => "urn:lsid:..."
             description => "a human-readable description of the object"
             contactEmail => "your@email.address"
             authURI => "URI of the registrar of this object"
             Relationships => {
               relationshipType1 => [
                 {object      => Object1,
                  articleName => ArticleName1, 
                  lsid        => lsid1},
                 {object      => Object2,
                  articleName => ArticleName2, 
                  lsid        => lsid2}
               ],
               relationshipType2 => [
                 {object      => Object3,
                  articleName => ArticleName3, 
                  lsid        => lsid3}
               ]
             }
             XML => <....XML of object registration.../>

 Args      : objectType =>  the name or LSID URI for an object

=cut

sub retrieveObjectDefinition {
	my ( $self, %a ) = @_;
	my $id = $a{objectType};
	return $self->errorRegXML(
		"Function not allowed when querying multiple registries")
	  if $self->multiple_registries;
	my %def;
	return \%def unless $id;
	my $message = "
		<retrieveObjectDefinition>
			<objectType>$id</objectType>
		</retrieveObjectDefinition>";
	my ($return) =
	  $self->_call( 'default', 'retrieveObjectDefinition', $message );
	return \%def unless $return;
	my ( $term, $lsid, $desc, $relationships, $email, $authURI ) =
	  &_ObjectDefinitionPayload($return);
	$def{objectType}    = $term;
	$def{objectLSID}    = $lsid;
	$def{description}   = $desc;
	$def{contactEmail}  = $email;
	$def{authURI}       = $authURI;
	$def{Relationships} = $relationships;
	$def{XML}           = $return;
	return ( \%def );
}

sub _ObjectDefinitionPayload {
	my ($payload) = @_;
	my $Parser    = XML::LibXML->new();
	my $doc       = $Parser->parse_string($payload);
	my $Object    = $doc->getDocumentElement();
	my $obj       = $Object->nodeName;
	return undef unless ( $obj eq 'retrieveObjectDefinition' );
	my $term = &_nodeTextContent( $Object,  "objectType" );
	my $lsid = &_nodeAttributeValue( $Object, "objectType", "lsid");
	my $desc = &_nodeCDATAContent( $Object, "Description" );
	if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
		$desc = $1;
	}
	my $authURI = &_nodeTextContent( $Object, "authURI" );
	my $email   = &_nodeTextContent( $Object, "contactEmail" );
	my %att_value;
	my %relationships;
	my $x                = $doc->getElementsByTagName("Relationship");
	my $no_relationships = $x->size();
	for ( my $n = 1 ; $n <= $no_relationships ; ++$n ) { #get_node starts at one
		my $relationshipType =
		  $x->get_node($n)->getAttributeNode('relationshipType')
		  ;    # may or may not have a name
		if ($relationshipType) {
			$relationshipType = $relationshipType->getValue();
		}
		else {
			return
			  "FAILED! must include a relationshipType in every relationship\n";
		}
		my @child = $x->get_node($n)->childNodes;
		foreach (@child) {
			next unless $_->nodeType == ELEMENT_NODE;
			my $article =
			  $_->getAttributeNode('articleName');  # may or may not have a name
			my $rlsid =
			  $_->getAttributeNode('lsid');  # may or may not have a name
			if ($article) { $article = $article->getValue() }
			if ($rlsid) { $rlsid = $rlsid->getValue() }
			
			my @child2 = $_->childNodes;
			foreach (@child2) {

				#print getNodeTypeName($_), "\t", $_->toString,"\n";
				next unless $_->nodeType == TEXT_NODE;
				push @{ $relationships{$relationshipType} },
					{ object => $_->toString,
					  articleName => $article,
					  lsid => $rlsid };
			}
		}
	}
	return ( $term, $lsid, $desc, \%relationships, $email, $authURI );
}



=head2 retrieveNamespaces

 Usage     :	$ns = $MOBY->retrieveNamespaces(%args)
 Function  :	get the list of all registered Namespace types
 Returns   :	hashref of hash:
                $ns{$namespace} = $definition
 Args      :	registry => $reg_name:  name of registry you wish to retrieve from (optional)
                as_lsid  => $boolean:  retrieve $namespace as its corresponding LSID (default off)

=cut

sub retrieveNamespaces {
	my ($self, %args) = shift;
	my $reg = $args{registry};
	$reg = $reg ? $reg : $self->default_MOBY_servername;
	return undef unless ( $self->Connection($reg) );
	my $as_lsid = $args{as_lsid};
	
	my ($return) = $self->_call( $reg, 'retrieveNamespaces', "" );
	my $parser = XML::LibXML->new();
	my $doc    = $parser->parse_string($return);
	my $root   = $doc->getDocumentElement;
	my $namesp = $root->childNodes;
	my %namespaces;
	for ( my $x = 1 ; $x <= $namesp->size() ; $x++ ) {
		next unless $namesp->get_node($x)->nodeType == ELEMENT_NODE;
		my $ns = $namesp->get_node($x)->getAttributeNode('name')->getValue;
		my $lsid = $namesp->get_node($x)->getAttributeNode('lsid');
		if ($lsid){
		    $lsid = $lsid->getValue;
		} else {
		    $lsid = $ns;
		}
		my $desc;
		for my $elem (
			$namesp->get_node($x)->getElementsByTagName('Description') )
		{
			$desc = $elem->firstChild;
			$desc = $desc ? $desc->toString : "";
			$desc ||="";
			if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
				$desc = $1;
			}
		}
#		$desc =~ s/<!\[CDATA\[((?>[^\]]+))\]\]>/$1/gs;
		$namespaces{$as_lsid?$lsid:$ns} = $desc;
	}
	return \%namespaces;
}

=head2 retrieveNamespacesFull

 Usage     :	$ns = $MOBY->retrieveNamespaces(%args)
 Function  :	get all details about all namespaces
 Returns   :	hashref of hash:
                $ns{$namespace} = {Definition => $definition,
		                   authURI => $authority,
				   contactEmail => $email} 
 Args      :	registry => $reg_name:  name of registry you wish to retrieve from (optional)
                as_lsid  => $boolean:  retrieve $namespace as its corresponding LSID (default off)

=cut

sub retrieveNamespacesFull {
	my ($self, %args) = shift;
	my $reg = $args{registry};
	$reg = $reg ? $reg : $self->default_MOBY_servername;
	return undef unless ( $self->Connection($reg) );
	my $as_lsid = $args{as_lsid};
	
	my ($return) = $self->_call( $reg, 'retrieveNamespaces', "" );
	my $parser = XML::LibXML->new();
	my $doc    = $parser->parse_string($return);
	my $root   = $doc->getDocumentElement;
	my $namesp = $root->childNodes;
	my %namespaces;
	for ( my $x = 1 ; $x <= $namesp->size() ; $x++ ) {
		next unless $namesp->get_node($x)->nodeType == ELEMENT_NODE;
		my $ns = $namesp->get_node($x)->getAttributeNode('name')->getValue;
		my $lsid = $namesp->get_node($x)->getAttributeNode('lsid');
		if ($lsid){
		    $lsid = $lsid->getValue;
		} else {
		    $lsid = $ns;
		}
		my ($desc, $auth, $email);
		for my $elem (
			$namesp->get_node($x)->getElementsByTagName('Description') )
		{
			$desc = $elem->firstChild;
			$desc = $desc ? $desc->toString : "";
			$desc ||="";
			if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
				$desc = $1;
			}
		}
		for my $elem (
			$namesp->get_node($x)->getElementsByTagName('authURI') )
		{
			$auth = $elem->firstChild;
			$auth = $auth ? $auth->toString : "";
			$auth ||="";
			if ( $auth =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
				$auth = $1;
			}
		}
		for my $elem (
			$namesp->get_node($x)->getElementsByTagName('contactEmail') )
		{
			$email = $elem->firstChild;
			$email = $email ? $email->toString : "";
			$email ||="";
			if ( $email =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
				$email = $1;
			}
		}
		$namespaces{$as_lsid?$lsid:$ns} = {Description => $desc, authURI => $auth, contactEmail => $email};
	}
	return \%namespaces;
}


=head2 retrieveObject

 Usage     :	$objects = $MOBY->retrieveObjectNames(%args)
 Function  :	get the object xsd
 Returns   :	hashref of hash:
                $objects{$name} = $W3C_XML_Schema_string
 Args      :	registry => $reg - name of MOBY Central you want to use (must pass undef otherwise)
                objectType => $name - object name (from ontology) or undef to get all objects
		as_lsid => $boolean - return $name as its corresponding LSID (default off)

=cut

sub retrieveObject {
	my ($self, %args)  = shift;
	my ($reg)   = $args{registry};
	my $type    = $args{objectType};
	my $as_lsid = $args{as_lsid};
	my $message = "
	<retrieveObject>
		 <objectType>$type</objectType>
	</retrieveObject>";
	$reg = $reg ? $reg : $self->default_MOBY_servername;
	return undef unless ( $self->Connection($reg) );

	my ($return) = $self->_call( $reg, 'retrieveObject', $message );
	my $parser = XML::LibXML->new();
	my $doc     = $parser->parse_string($return);
	my $root    = $doc->getDocumentElement;
	my $objects = $root->childNodes;
	my %objects;
	for ( my $x = 1 ; $x <= $objects->size() ; $x++ ) {
		next unless $objects->get_node($x)->nodeType == ELEMENT_NODE;
		my $name = $objects->get_node($x)->getAttributeNode('name')->getValue;
		my $lsid = $objects->get_node($x)->getAttributeNode('lsid');
		if ($lsid){
		    $lsid = $lsid->getValue;
		} else {
		    $lsid = $name;
		}
		my $desc;
		for my $elem ( $objects->get_node($x)->getElementsByTagName('Schema') )
		{
			$desc = $elem->firstChild->nodeValue;
			if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
				$desc = $1;
			}
		}
		$desc =~ s/<!\[CDATA\[((?>[^\]]+))\]\]>/$1/gs;
		$objects{$name} = $desc;
	}
	return \%objects;
}

=head2 Relationships

 Usage     :	$def = $MOBY->Relationships(%args)
 Function  :	traverse and return the relationships in the ontology
 Returns   :    hashref of
                FOR SERVICES:
		        $hash{'isa'}=[{lsid => $lsid, term => 'termy'},...]
		FOR OBJECTS:
		        $hash{relationship_type}=[{lsid => $lsid, articleName => 'thingy', term => 'termy'},...]
 Args      :	EITHER serviceType => $term_or_lsid
                OR     objectType => $term_or_lsid
                Relationships => \@relationship_types (optional, 'all' if parameter is missing)
                Registry => $registry_name  (optional)
                expandRelationships => [1/0] (optional)
                direction => ['root'/'leaves'] (optional)

=cut

sub Relationships {
	my ( $self, %args ) = @_;
	my $object  = $args{'objectType'};
	my $service = $args{'serviceType'};
	my $expand  = $args{'expandRelationships'};
	$expand = $args{'expandRelationship'}
	  unless defined($expand);    # be forgiving of typos
	my $direction =  $args{'direction'} ?
	                 $args{'direction'} :
	                 'root';  # make 'root' default to stay compatible
	my @relationships;
	@relationships = @{ $args{'Relationships'} }
	  if ( $args{'Relationships'}
		&& ( ref( $args{'Relationships'} ) eq 'ARRAY' ) );
	push @relationships, 'isa' unless $relationships[0];  # need to have at least one relationship
	my $reg = $args{'Registry'};
	my $m;
	my $payload;
	return {} unless ( $object || $service );

	if ($object) {
		$m = "
		<Relationships>
            <objectType>$object</objectType>\n";
		foreach (@relationships) {
			$m .= "<relationshipType>$_</relationshipType>\n";
		}
		$m .= "<expandRelationship>1</expandRelationship>\n" if $expand;
		$m .= "<direction>$direction</direction>\n";
		$m .= "</Relationships>";
		$reg = $reg ? $reg : $self->default_MOBY_servername;
		return undef unless ( $self->Connection($reg) );

#$payload = $self->SOAP_connection($reg)->call('Relationships' => ($m))->paramsall;
		($payload) = $self->_call( $reg, 'Relationships', $m );
	}
	elsif ($service) {
		$m = "
		<Relationships>
            <serviceType>$service</serviceType>\n";
		foreach (@relationships) {
			$m .= "<relationshipType>$_</relationshipType>\n";
		}
		$m .= "<expandRelationship>1</expandRelationship>\n" if $expand;
		$m .= "<direction>$direction</direction>\n";
		$m .= "</Relationships>";
		$reg = $reg ? $reg : $self->default_MOBY_servername;
		return undef unless ( $self->Connection($reg) );

#		$payload = $self->SOAP_connection($reg)->call('Relationships' => ($m))->paramsall;
		($payload) = $self->_call( $reg, 'Relationships', $m );
	}
	return &_relationshipsPayload($payload);
}

sub _relationshipsPayload {
	my ($payload) = @_;
	return undef unless $payload;
	my %att_value;
	my %relationships;
	my $Parser           = XML::LibXML->new();
	my $doc              = $Parser->parse_string($payload);
	my $x                = $doc->getElementsByTagName("Relationship");
	my $no_relationships = $x->size();
	for ( my $n = 1 ; $n <= $no_relationships ; ++$n ) {
		my $relationshipType = $x->get_node($n)->getAttributeNode('relationshipType');    # may or may not have a name
		if ($relationshipType) {
			$relationshipType = $relationshipType->getValue();
		} else {
			return "FAILED! must include a relationshipType in every relationship\n";
		}
		my @child = $x->get_node($n)->childNodes;
		foreach my $child(@child) {
			my ($lsid, $article, $term) = ("", "", "");
			next unless $child->nodeType == ELEMENT_NODE;
			my $lsidattr = $child->getAttributeNode('lsid');    # may or may not have a name
			if ($lsidattr) {
				$lsid = $lsidattr->getValue();
			}
			my $ARTattr = $child->getAttributeNode('articleName');    # may or may not have a name
			if ($ARTattr) {
				$article = $ARTattr->getValue();
			}
			my %info;
			$info{lsid} = $lsid;
			($info{articleName} = $article) if $article;
			my @child2 = $child->childNodes;
			foreach my $child2(@child2) {
				next unless $child2->nodeType == TEXT_NODE;
				$info{term} = $child2->toString;
				push @{ $relationships{$relationshipType} }, \%info;
			}
		}
	}
	return \%relationships;
}

=head2 ISA

 Usage     :	$def = $MOBY->ISA($class1, $class2)
 Function  :	a pre-canned use of the Relationships function
                to quickly get an answer to whether class1 ISA class2
 Returns   :    Boolean
 Args      :	$class1  - an Object ontology term or LSID
                $class2 - an Object ontology term or LSID

=cut

sub ISA {
	my ( $self, $class1, $class2 ) = @_;
	return 1
	  if ( ( $class1 eq $class2 )
		|| ( "moby:$class1" eq $class2 )
		|| ( $class1        eq "moby:$class2" ) );
	my $lsid1 = $self->ObjLSID($class1);
	my $lsid2 = $self->ObjLSID($class2);
	return 0 unless $lsid1 && $lsid2;
	my @lsids;
	unless ( @lsids = $self->ISA_CACHE($lsid1) ) {
		my $resp = $self->Relationships(
			objectType         => $lsid1,
			expandRelationship => 1,
			Relationships      => ['isa']
		);
		my $lsids = $resp->{'isa'};
		map {push @lsids, $self->ObjLSID($_->{lsid})} @$lsids;  # convert to LSID
		$self->ISA_CACHE( $lsid1,  [@lsids] );
		$self->ISA_CACHE( $class1, [@lsids] );
		my @hold = @lsids;
		while ( shift @hold ) {
			$self->ISA_CACHE( $_, [@hold] );
			if ( $_ =~ /^urn:lsid:biomoby.org.\w+\.(\S+)/ ) {
				$self->ISA_CACHE( $1, [@lsids] );
			}
		}
	}
	foreach (@lsids) {
	    return 1 if $_ eq $lsid2;
	}
	return 0;
}

=head2 DUMP

 Usage     :	($mobycentral, $mobyobject, $mobyservice, $mobynamespace, $mobyrelationship) = $MOBY->DUMP(['registry'])
 Function  :	DUMP the mysql for the current MOBY Central database
 Returns   :	text
 Args      :	$reg - name of MOBY Central you want to use if not default


=cut

sub DUMP {
	my ($self) = shift;
	my ($reg)  = shift;
	my $type   = shift;
	$reg = $reg ? $reg : $self->default_MOBY_servername;
	return undef unless ( $self->Connection($reg) );

	#	return $self->SOAP_connection($reg)->call('DUMP')->paramsall;
	my ($SQLs) = $self->_call( $reg, 'DUMP_MySQL', "" );
	my (
            $mobycentral,   $mobyobject, $mobyservice,
            $mobynamespace, $mobyrelationship
        ) = @{$SQLs} unless ref($SQLs) eq 'HASH';

		# cases where soap message is serialized as a HASH
        (
            $mobycentral,   $mobyobject, $mobyservice,
            $mobynamespace, $mobyrelationship
        ) = @{$SQLs->{item}} if ref($SQLs) eq 'HASH';
        
	return (
		$mobycentral,   $mobyobject, $mobyservice,
		$mobynamespace, $mobyrelationship
	);
}
*DUMP_MySQL = \&DUMP;
*DUMP_MySQL = \&DUMP;

sub _parseServices {
	my ( $self, $Registry, $XML ) = @_;
	my $Parser   = XML::LibXML->new();
	# fix empty string problem
	return [] unless $XML;
	my $doc      = $Parser->parse_string($XML);
	my $Object   = $doc->getDocumentElement();
	my $Services = $Object->getElementsByTagName("Service");
	my $num      = $Services->size();
	my @Services;
	for ( my $x = 1 ; $x <= $num ; $x++ ) {
		my $Service       = $Services->get_node($x);
		my $AuthURI       = $Service->getAttributeNode('authURI')->getValue;
		my $servicename   = $Service->getAttributeNode('serviceName')->getValue;
		my $lsid          = $Service->getAttributeNode('lsid');
		if ($lsid){
		    $lsid = $lsid->getValue;
		} else {
		    $lsid = "";
		}
		my $Type          = &_nodeTextContent( $Service, 'serviceType' );
		my $signatureURL          = &_nodeTextContent( $Service, 'signatureURL' );
		my $authoritative = &_nodeTextContent( $Service, 'authoritative' );
		my $contactEmail  = &_nodeTextContent( $Service, 'contactEmail' );
		my $URL           = &_nodeTextContent( $Service, 'URL' );

		#my $Output = &_nodeTextContent($Service, 'outputObject');
		my $Description = &_nodeCDATAContent( $Service, 'Description' );
		$Description =~ s/<!\[CDATA\[((?>[^\]]+))\]\]>/$1/gs;
		my $cat = &_nodeTextContent( $Service, 'Category' );
		my @INPUTS;
		my @OUTPUTS;
		foreach my $inout ( "Input", "Output" ) {
			my $xPuts =
			  $Service->getElementsByTagName($inout)
			  ;    # there should only be one, but... who knows what
			for my $in ( 1 .. $xPuts->size() ) {
				my $current = $xPuts->get_node($in);
				foreach my $child ( $current->childNodes )
				{    # child nodes will be either "Simple" or "Collection" tagnames
					next unless $child->nodeType == ELEMENT_NODE;
					my $THIS;
					if ( $child->nodeName eq "Simple" ) {
						$THIS =
						  MOBY::Client::SimpleArticle->new( XML_DOM => $child );
					}
					elsif ( $child->nodeName eq "Collection" ) {
						$THIS =
						  MOBY::Client::CollectionArticle->new(
							XML_DOM => $child );
					}
					else {
						next;
					}
					if ( $inout eq "Input" ) {
						push @INPUTS, $THIS;
					}
					else {
						push @OUTPUTS, $THIS;
					}
				}
			}
		}
		my @SECONDARIES;
		my $secs =
		  $Service->getElementsByTagName("secondaryArticles")
		  ;    # there should only be one, but... who knows what
		for my $in ( 1 .. $secs->size() ) {
			my $current = $secs->get_node($in);
			foreach my $param ( $current->childNodes )
			{    # child nodes will be "Parameter" tag names
				next
				  unless $param->nodeType == ELEMENT_NODE
				  && $param->nodeName eq "Parameter";
				my $THIS;
				$THIS =
				  MOBY::Client::SecondaryArticle->new( XML_DOM => $param );
				push @SECONDARIES, $THIS;
			}
		}
		my $Instance = MOBY::Client::ServiceInstance->new(
			authority     => $AuthURI,
			authoritative => $authoritative,
			URL           => $URL,
			LSID		=> $lsid,
			contactEmail  => $contactEmail,
			name          => $servicename,
			type          => $Type,
			category      => $cat,
			input         => \@INPUTS,
			output        => \@OUTPUTS,
			secondary     => \@SECONDARIES,
			description   => $Description,
			registry      => $Registry,
			signatureURL => $signatureURL,
			XML           => $Service->toString,
		);
		push @Services, $Instance;
	}
	return \@Services;
}

#        my ($e, $m, $lsid) = $OS->objectExists(term => $_);

=head2 ObjLSID

=cut

sub ObjLSID {
	my ( $self, $term ) = @_;
	return undef unless $term;
	my $lsid;
	if ( $lsid = $self->LSID_CACHE($term) ) {
		return $lsid;
	}
	else {
		my $os = MOBY::Client::OntologyServer->new;
		my ( $s, $m, $tlsid ) = $os->objectExists( term => $term );
		if ($tlsid) {
			$self->LSID_CACHE( $term,  $tlsid );    # link both the term
			$self->LSID_CACHE( $tlsid, $tlsid );    # and the lsid to itself
			return $tlsid;
		}
		else {
			return undef;
		}
	}
}

=head2 LSID_CACHE

 Usage     :	$lsid = $MOBY->LSID_CACHE($term, $lsid)
 Function  :	get/set LSID from the cache
 Returns   :	lsid as a scalar
 Args      :	the term for which you have/want an lsid,
                and optionally the lsid to set.

=cut

sub LSID_CACHE {
	my ( $self, $term, $lsid ) = @_;
	if ( $term && $lsid ) {
		$self->{LSID_CACHE}->{$term} = $lsid;
		return $self->{LSID_CACHE}->{$term};
	}
	elsif ($term) {
		return $self->{LSID_CACHE}->{$term};
	}
	else {
		return undef;
	}
}

=head2 ISA_CACHE

 Usage     : @lsids = $MOBY->ISA_CACHE($lsid, \@isas)
 Function  : get/set the ISA relationships in the cache
 Returns   : list of ISA relationships.  The ISA list
             is IN ORDER from, excluding the term itself, to
             root Object. Base Object returns an empty list.
 Args      : The LSID for which you have/want the ISA parentage,
             and optionally the parentage listref to set.
 Note      : WHAT COMES BACK ARE LSIDs!!!   

=cut

sub ISA_CACHE {
	my ( $self, $desiredterm, $isas ) = @_;
	my $term = $desiredterm;
	return (undef) if $isas && ( ref($isas) ne 'ARRAY');
	if ( $term && $isas ) {
		my @isalsids;
		foreach (@$isas){
		    my $lsid = $self->ObjLSID($_);
		    next unless ($lsid =~ /^urn\:lsid/);
		    push @isalsids, $lsid;
		}
		$self->{ISA_CACHE}->{$desiredterm} = [(@isalsids)];  # can't assign a listreference or it will empty itself!
		while ( my $term = shift(@isalsids) ) {  # traverse down and flatten the list
			$self->{ISA_CACHE}->{$term} = [(@isalsids)];
		}
		return @{ $self->{ISA_CACHE}->{$desiredterm} };
	}
	elsif ( $term && $self->{ISA_CACHE}->{$desiredterm} ) {
		return @{ $self->{ISA_CACHE}->{$desiredterm} };
	}
	else {
		return ();
	}
}

sub parseRegXML {

	#<MOBYRegistration>
	#	<id>$id</id>
	#	<success>$success</success>
	#	<message><![CDATA[$message]]></message>
	#</MOBYRegistration>
	my ( $self, $xml ) = @_;
	my $Parser = XML::LibXML->new();

	#print STDERR $xml;
	my $doc    = $Parser->parse_string($xml);
	my $Object = $doc->getDocumentElement();
	my $obj    = $Object->nodeName;
	return undef unless ( $obj eq 'MOBYRegistration' );
	my $id      = &_nodeTextContent( $Object,  'id' );
	my $success = &_nodeTextContent( $Object,  'success' );
	my $message = &_nodeCDATAContent( $Object, 'message' );

	#print STDERR "******$message******\n";
	my $RDF = &_nodeRawContent( $Object, 'RDF' );
	my $reg = MOBY::Client::Registration->new(
		success         => $success,
		message         => $message,
		registration_id => $id,
		RDF             => $RDF,
		id              => $id
	);
	return $reg;
}

sub errorRegXML {
	my ( $self, $message ) = @_;
	my $reg = MOBY::Client::Registration->new(
		success         => 0,
		message         => $message,
		registration_id => -1,
	);
	return $reg;
}

sub _nodeCDATAContent {

	# will get text of **all** child $node from the given $DOM
	# regardless of their depth!!
	my ( $DOM, $node ) = @_;
	my $x = $DOM->getElementsByTagName($node);
	unless ( $x->get_node(1) ) { return }
	my @child = $x->get_node(1)->childNodes;
	my $content;
	foreach (@child) {

		#print getNodeTypeName($_), "\t", $_->toString,"\n";
		next
		  unless ( ( $_->nodeType == TEXT_NODE )
			|| ( $_->nodeType == CDATA_SECTION_NODE ) );
		$content = $_->textContent;
	}
	$content ||= "";
	$content =~ s/<!\[CDATA\[((?>[^\]]+))\]\]>/$1/gs;
	return $content;
}

sub _nodeTextContent {

	# will get text of **all** child $node from the given $DOM
	# regardless of their depth!!
	my ( $DOM, $node ) = @_;
	my $x = $DOM->getElementsByTagName($node);
	unless ( $x->get_node(1) ) { return }
	my @child = $x->get_node(1)->childNodes;
	my $content;
	foreach (@child) {

		#print getNodeTypeName($_), "\t", $_->toString,"\n";
		next
		  unless ( ( $_->nodeType == TEXT_NODE )
			|| ( $_->nodeType == CDATA_SECTION_NODE ) );
		$content = $_->textContent;
	}
	return $content;
}

sub _nodeAttributeValue {

	my ( $DOM, $node, $attr ) = @_;
	return "" unless $attr;
	my $x = $DOM->getElementsByTagName($node);
	unless ( $x->get_node(1) ) { return "" }
	my $n = $x->get_node(1);
	my $nodemap = $n->attributes($attr);  # XML::LibXML::NamedNodeMap - the worst documented (i.e. undocumented) piece of code ever written!  You have to read the source to figure out the interface...
	my $attrnode = $nodemap->getNamedItem($attr);
	my $attrval = $attrnode?($attrnode->value):"";
	return $attrval;
}

sub _nodeRawContent {

	# will get XML of **all** child $node from the given $DOM
	# regardless of their depth!!
	my ( $DOM, $node ) = @_;
	my $x = $DOM->getElementsByTagName($node);
	unless ( $x->get_node(1) ) { return }
	my @child = $x->get_node(1)->childNodes;
	my $content;
	foreach (@child) {

		#print getNodeTypeName($_), "\t", $_->toString,"\n";
		#        next unless $_->nodeType == TEXT_NODE;
		$content .= $_->toString;
	}
	return $content;
}

sub _nodeArrayContent {

	# will get array content of all child $node from given $DOM
	# regardless of depth!
	my ( $DOM, $node ) = @_;
	$debug && &_LOG( "_nodeArrayContext received DOM:  ",
		$DOM->toString, "\nsearching for node $node\n" );
	my @result;
	my $x     = $DOM->getElementsByTagName($node);
	my @child = $x->get_node(1)->childNodes;
	foreach (@child) {
		next unless $_->nodeType == ELEMENT_NODE;
		my @child2 = $_->childNodes;
		foreach (@child2) {

			#print getNodeTypeName($_), "\t", $_->toString,"\n";
			next
			  unless ( ( $_->nodeType == TEXT_NODE )
				|| ( $_->nodeType == CDATA_SECTION_NODE ) );
			push @result, $_->textContent;
		}
	}
	return @result;
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
	}
	elsif ( $self->_accessible( $attr, 'read' ) ) {
		*{$AUTOLOAD} = sub {
			return $_[0]->{$attr};
		};    ### end of created subroutine
		return $self->{$attr};
	}

	# Must have been a mistake then...
	croak "No such method: $AUTOLOAD";
}
sub DESTROY { }

sub _LOG {
	return unless $debug;
	open LOG, ">>/tmp/CentralLogOut.txt" or die "can't open logfile $!\n";
	print LOG join "\n", @_;
	print LOG "\n---\n";
	close LOG;
}
1;
