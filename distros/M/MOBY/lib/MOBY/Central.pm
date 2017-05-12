#$Id: Central.pm,v 1.13 2010/05/03 18:34:40 kawas Exp $

=head1 NAME

MOBY::Central.pm - API for communicating with the MOBY Central registry

=cut

package MOBY::Central;
use strict;
use Carp;
use vars qw($AUTOLOAD $WSDL_TEMPLATE $WSDL_POST_TEMPLATE $WSDL_ASYNC_TEMPLATE $WSDL_ASYNC_POST_TEMPLATE);
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
use MOBY::RDF::Ontologies::Services;
use URI;
use LWP;
use MOBY::CommonSubs;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.13 $ =~ /: (\d+)\.(\d+)/;

use Encode;

use MOBY::MobyXMLConstants;
my $debug = 0;
my $listener = 1;

my %user_agent_args = (agent => "MOBY-Central-Perl"); 

if ($debug) {
	open( OUT, ">/tmp/CentralRegistryLogOut.txt" ) || die "cant open logfile\n";
	print OUT "created logfile\n";
	close OUT;
}


if ($listener) {
	eval {open(OUT, ">>/tmp/CentralRegistryListener.txt")};
	$listener = 0 if @!; # abort listening if the logging attempt failed
}

sub listener {
	return unless $listener;
	my (%args) = @_;
	my $authority = $args{authority};
	my $servicename = $args{servicename};
	my $ip = $ENV{REMOTE_ADDR};  # ="137.82.67.190"
	open(OUT, ">>/tmp/CentralRegistryListener.txt");
	use Time::localtime;
	my $time =  ctime;
	print OUT "$time\t$ip\t$authority\t$servicename\n";
	close OUT;
}

 
=head1 SYNOPSIS

REQUIRES MYSQL 3.23 or later!!!!

If you are a Perl user, you should be using the
MOBY::Client:Central module to talk to MOBY-Central

If you need to connect directly, here is how it
is done in perl 5.6 and 5.6.1.  It wont work
in Perl 5.8... sorry.  Look how MOBY::Client::Cent
does it if you want to use Perl 5.8


--------------------------------------
SERVER-SIDE

 use SOAP::Transport::HTTP;

 my $x = new SOAP::Transport::HTTP::CGI;
 # fill in your server path below...
 $x->dispatch_to('WWW_SERVER_PATH', 'MOBY::Central');
 $x->handle;


---------------------------------------

CLIENT-SIDE

 use SOAP::Lite +autodispatch => 
      proxy => 'http://moby.ucalgary.ca/moby/MOBY-Central.pl', # or whatever...
      on_fault => sub {
         my($soap, $res) = @_; 
         die ref $res ? $res->faultstring : $soap->transport->status, "\n";
      };

 my $NAMES_XML = MOBY::Central->retrieveObjectNames;
 print $NAMES_XML;
 # ... do something with the XML

----------------------------------------


=head1 DESCRIPTION

Used to do various transactions with MOBY-Central registry, including registering
new Object and Service types, querying for these types, registering new
Servers/Services, or queryiong for available services given certain input/output
or service type constraints.

=cut

=head1 CONFIGURATION

This depends on a config file to get its database connection information.  At a minimum
this config file must have the following clause:

 [mobycentral]
 url = some.url 
 username = foo
 password = bar
 port = portnumber
 dbname = mobycentral


The space before and after the '=' is critical.

The end of a clause is indicated by a blank line.

Additional identically formatted clauses may be added for each of:

  [mobyobject]
  [mobynamespace]
  [mobyservice]
  [mobyrelationship]

if these ontologies are being served from a local database (via the
OntologyServer module).  These clauses will be read by the OntologyServer
module if they are present, otherwise default connections will be made
to the MOBY Central ontology server.

The config file must be readable by the webserver, and the webserver
environment should include the following ENV variable:

$ENV{MOBY_CENTRAL_CONFIG} = /path/to/config/file.name


=head1 AUTHORS

Mark Wilkinson (markw@illuminae.com)

BioMOBY Project:  http://www.biomoby.org

=cut

=head1 Registration XML Object

This is sent back to you for all registration and
deregistration calls

 <MOBYRegistration>
   <success>$success</success>
   <id>$id</id>
   <message><![CDATA[$message]]></message>
 </MOBYRegistration>


success is a boolean indicating a
successful or a failed registration

id is the deregistration ID of your registered
object or service to use in a deregister call.

message will contain any additional information
such as the reason for failure.


=cut

sub Registration {
	my ($details) = @_;
	my $id        = $details->{id};
	my $success   = $details->{success};
	my $message   = $details->{message};
	my $RDF       = $details->{RDF};

	#	return "<MOBYRegistration>
	#				<id>$id</id>
	#				<success>$success</success>
	#				<message><![CDATA[$message]]></message>
	#                <RDF><![CDATA[$RDF]]></RDF>
	#			</MOBYRegistration>";
	return "<MOBYRegistration>
				<id>$id</id>
				<success>$success</success>
				<message><![CDATA[$message]]></message>
                <RDF>$RDF</RDF>
			</MOBYRegistration>";
}
=cut







=head1 METHODS



=head2 new

 Title     :	new
 Usage     :	deprecated

=cut

sub new {
	my ( $caller, %args ) = @_;
	print STDERR "\nuse of MOBY::Central->new is deprecated\n";
	return 0;
}

=head2 registerObjectClass

The registerObjectClass call is:

=over 3

=item * used to register a new object Class into the Class ontology

=item * can envision this as simply registering a new node into the Class ontology graph, and creating the primary connections from that node.

=item * MOBY, by default, supports three types of Class Relationships: ISA, HAS, and HASA (these are the relationship ontology terms)

=over 3

=item * Foo ISA bar is a straight inheritence, where all attributes of bar are guaranteed to be present in foo.

=item * foo HAS bar is a container type, where bar is an object inside of foo in one or more copies.

=item * foo HASA bar is a container type, where bar is an object inside of foo in one copy only

=back

=item * notice that, in a HAS and HASA relationships, it is necessary to indicate an article name for each contained object type. Thus, for example, you could have a sequence object that contained a String object with name "nucleotideSequence" and an Integer object with the name "sequenceLength".

=back

Input XML :

        <registerObjectClass>
            <objectType>NewObjectType</objectType>
            <Description><![CDATA[
                    human readable description
                    of data type]]>
            </Description>
            <Relationship relationshipType="RelationshipOntologyTerm">
               <objectType articleName="SomeName">ExistingObjectType</objectType>
               ...
               ...
            </Relationship>
            ...
            ...
            <authURI>Your.URI.here</authURI>
            <contactEmail>You@your.address.com</contactEmail>
        </registerObjectClass>


Output XML :

...Registration Object... 


=cut

sub registerObjectClass {

	# this contacts the ontology server to register
	# the ontology and writes the resulting URI into
	# the MOBY Central database
	my ( $pkg, $payload ) = @_;
	my ( $success, $message );
	my $OntologyServer    = &_getOntologyServer( ontology => 'object' );
	my $RelOntologyServer = &_getOntologyServer( ontology => 'relationship' );
	my ( $term, $desc, $relationships, $email, $auth, $clobber ) =
	  &_registerObjectPayload($payload);

	unless ( defined $term && defined $desc && defined $auth && defined $email )
	{
		if ( $term =~ /FAILED/ ) { return &_error( "Malformed XML;", "" ); }
		return &_error("Malformed XML; may be missing required parameters objectType, Description, authURI or contactEmail",
			""
		);
	}
	#print STDERR "$term, $desc, $auth, $email\n";
	#check encoding
	unless ( decode_utf8($term) eq $term && decode_utf8($desc) eq $desc && decode_utf8($auth) eq $auth && decode_utf8($email) eq $email )
	{
		return &_error("Invalid character encoding; one or all of objectType, Description, authURI or contactEmail were not UTF-8 encoded.",
			""
		);
	}
	return &_error( "Malformed authURI - must not have an http:// prefix", "" )
	  if $auth =~ '[/:]';
	return &_error( "Malformed authURI - must take the form NNN.NNN.NNN", "" )
	  unless $auth =~ /\./;
	return &_error("Malformed email - must be a valid email address of the form name\@organization.foo",
		""
	  )
	  unless $email =~ /\S\@\S+\.\S+/;
	return &_error("Object name may not contain spaces or other characters invalid in a URN",
		""
	  )
	  if $term =~ /[\/\'\\\s"\&\<\>\[\]\^\`\{\|\}:\~%\!\@#\$\*\+=]/;
	if ( $term =~ m"^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?" )
	{    # matches a URI
		return &_error( "Object name may not be an URN or URI", "" ) if $1;
	}
	my $ISAs;

# validate that the final ontology will be valid by testing against existing relationships and such
	while ( my ( $reltype, $obj ) = each %{$relationships} ) {
		my ( $success, $message, $URI ) =
		  $RelOntologyServer->relationshipExists(
			term     => $reltype,
			ontology => 'object'
		  );    # success = 1 if it does
		($success == 0) && return &_error( $message, $URI );
		foreach ( @{$obj} ) {
			++$ISAs if ( $URI =~ /isa$/i );
			my ( $objectType, $articleName ) = @{$_};
			return &_error("Object contains a child relationship with an invalid articlename. Articlenames name may not contain spaces or other special characters.","") 
			 if $articleName =~ /([\+\=\':\s\"\&\<\>\[\]\^\`\{\|\}\~\(\)\\\/\$\#\@\,\|\?\.!\*\;])/;
			 
			my ( $success, $message, $URI ) =
			  $OntologyServer->objectExists( term => $objectType )
			  ;    # success = 1 if it does
			($success == 0) && return &_error( $message, $URI );
		}
	}
	return &_error(
		"Object must have exactly one ISA parent in the MOBY Object ontology")
	  unless $ISAs == 1;
	$clobber = defined($clobber) ? $clobber : 0;
	$clobber = 0
	  unless ( $clobber eq 0 || $clobber eq 1 || $clobber eq 2 );    # safety!
	my ( $exists, $exists_message, $URI ) =
	  $OntologyServer->objectExists( term => $term );   # success = 1 if it does
	( ( $exists == 1 && !$clobber )
		  && return &_error( "Object $term already exists", $URI ) );
	$clobber = 0
	  unless ($exists)
	  ;    # it makes no sense to clobber something that doesnt' exist
	if ($exists) {

		if ( $clobber == 1 ) {
			my ( $success, $message ) =
			  $OntologyServer->deprecateObject( term => $term );
			($success == 0) && return &_error( $message, $URI );
		}
		elsif ( $clobber == 2 ) {
			my ( $success, $message ) =
			  $OntologyServer->deleteObject( term => $term );
			($success == 0) && return &_error( $message, $URI );
		}
	}

	# now test if the object inherits from primitives... if so, abort
	if ( keys %{$relationships} ) {
		while ( my ( $reltype, $obj ) = each %{$relationships} ) {
			next unless ($reltype =~ /isa/i); # we are only testing isa relationships here.
			foreach ( @{$obj} ) {
				my ( $objectType, $articleName ) = @{$_};
				if (&_testObjectTypeAgainstPrimitives($objectType)){
					return &_error( "Inheritance from Primitive data-types is now deprecated.  You shold construct your object using a HASA relationship.  for example, text-plain HASA string (as opposed to ISA string)", "" );
				}
			}
		}
	}
	# are the article names unique?
	if ( keys %{$relationships} ) {
		my $parent_type;
		my %art_names = ();
		while ( my ( $reltype, $obj ) = each %{$relationships} ) {
			# one isa relationship
			if ($reltype =~ /isa/i) {
				foreach ( @{$obj} ) {
					my ( $objectType, $articleName ) = @{$_};
					$parent_type = $objectType;	
				}
			} else {
				#has/hasa relationship
				foreach ( @{$obj} ) {
					my ( $objectType, $articleName ) = @{$_};
					return return &_error( "Article names for HAS/HASA relationships must be unique. Please ensure that names are unique!", "" )
					  if $art_names{$articleName};
					# add name to the hash
					$art_names{$articleName} = 1;
				}
			}
		}
		unless (&_extract_terms($parent_type, \%art_names)){
			return &_error( "Article names for HAS/HASA relationships (including those inherited) must be unique. Please ensure that names are unique!", "" );
		}
	}

	# should be good to go now...

	( $success, $message, $URI ) = $OntologyServer->createObject(
		node          => $term,
		description   => $desc,
		authority     => $auth,
		contact_email => $email
	);
	($success == 0) && return &_error( $message, $URI );
	my @failures;
	my $messages = "";
	if ( keys %{$relationships} ) {  # need to pull them out with ISA's first
		foreach my $reltype(qw{ISA HASA HAS}){
			my ( $obj ) = $relationships->{$reltype};
			foreach ( @{$obj} ) {
				my ( $objectType, $articleName ) = @{$_};
				my ( $success,    $message )     =
				  $OntologyServer->addObjectRelationship(
					subject_node  => $term,
					relationship  => $reltype,
					object_node   => $objectType,
					articleName   => $articleName,
					authority     => $auth,
					contact_email => $email
				  );
				unless ($success){
						   push @failures, $objectType;
						   $messages .= $message."; ";
				}
			}
		}
	}
	if ( scalar(@failures) ) {
		my ( $success, $message, $deleteURI ) =
		  $OntologyServer->deleteObject( term => $term )
		  ;    # hopefully this situation will never happen!
		($success == 0) && return &_error(
			"object failed ISA and/or HASA connections,
		and subsequently failed deletion.  This is a critical error,
		and may indicate corruption of the MOBY Central registry.", $deleteURI
		);
		return &_error("object failed to register due to failure during registration of ISA/HASA relationships.  Message returned was $messages"
			  . ( join ",", (@failures) ) . "\n",
			""
		);
	}
	return &_success( "Object $term registered successfully.", $URI );
}

###############################
#
###############################

sub _extract_terms {

	my ( $datatype, $articles ) = @_;
	my $ont_serv = MOBY::OntologyServer->new( ontology => "object" );
	my $stuff = $ont_serv->retrieveObject( type => $datatype );
	return 1 unless $stuff;

	# extract all isa/hasa/has relationships
	my $rels = $stuff->{Relationships} if defined $stuff->{Relationships};
	for my $relation ( keys %{$rels} ) {
		for my $term ( @{ $rels->{$relation} } ) {

			# pos 1 has articlename, pos 2 has datatype
			# if we are in isa, then drill into it
			if ( $relation =~ m/\:isa$/i ) {
				return 0 unless &_extract_terms( @{$term}[2], $articles );
			} else {

				# check if we already processed the articlename ...
				return 0 if defined @{$term}[1] and $articles->{ @{$term}[1] };
				$articles->{ @{$term}[1] } = 1 if @{$term}[1];
			}
		}
	}
	return 1;
}

#Eddie - converted
sub _registerObjectPayload {
	my ($payload) = @_;    #EDDIE - assuming that payload is a string
	my $Parser = XML::LibXML->new();
	my $doc    = $Parser->parse_string($payload);
	my $Object = $doc->documentElement();
	my $obj    = $Object->nodeName;
	return undef unless ( $obj eq 'registerObjectClass' );
	my $term    = &_nodeTextContent( $Object,  "objectType" );
	my $desc    = &_nodeCDATAContent( $Object, "Description" );
	my $authURI = &_nodeTextContent( $Object,  "authURI" );
	my $email   = &_nodeTextContent( $Object,  "contactEmail" );
	my $clobber = &_nodeTextContent( $Object,  "Clobber" );

	#my @ISA = &_nodeArrayContent($Object, "ISA");
	#my @HASA = &_nodeArrayExtraContent($Object, "HASA","articleName");
	my %att_value;
	my %relationships;
	my $x                = $doc->getElementsByTagName("Relationship");
	my $no_relationships = $x->size;
	for ( my $n = 1 ; $n <= $no_relationships ; ++$n ) {
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
			if ($article) { $article = $article->getValue() }
			my @child2 = $_->childNodes;
			foreach (@child2) {

				#print getNodeTypeName($_), "\t", $_->toString,"\n";
				next unless $_->nodeType == TEXT_NODE;
				push @{ $relationships{$relationshipType} },
				  [ $_->toString, $article ];
			}
		}
	}
	return ( $term, $desc, \%relationships, $email, $authURI, $clobber );
}

sub _testObjectTypeAgainstPrimitives{
	# THIS SUBROUTINE NEEDS TO BE REMOVED AND PLACED INTO THE ONTOLOGY SERVER
	# one day when MOBY Central and the ontologies are separated properly
	my ($type) = @_;
	my $OS = MOBY::OntologyServer->new(ontology => 'object');
	# get the inputlsid
	my ($success, $desc, $inputlsid) = $OS->objectExists(term => $type);

	my $CONF = MOBY::Config->new;
	my @primitives = @{$CONF->primitive_datatypes}; # get the list of known primitive datatypes
	my $x = 0; # set flag down
	# convert everything to an LSID first
	
	my @primitive_lsids = map{my ($s, $d, $l) = $OS->objectExists(term => $_); $l} @primitives;
	
	map {($x=1) if ($inputlsid eq $_)} @primitive_lsids; # test primitives against this one

	my $OSrel = MOBY::OntologyServer->new(ontology => 'relationship');
	my ($exists1, $desc2, $isalsid) = $OSrel->relationshipExists(term => 'isa', ontology => 'object');
	
	my $relationships = $OS->Relationships(
		ontology => 'object',
		term => $type,
		relationship => $isalsid,
		direction => 'root',
		expand =>  1);
	#relationships{relationship} = [[lsid1,articleNmae], [lsid2, articleName], [lsid3, articleName]]	
	my ($isa) = keys(%$relationships);  # can only be one key returned, and must be isa in this case
	my @ISAlist;
	(@ISAlist = @{$relationships->{$isa}}) if ($relationships->{$isa}) ;
	# for each of the inherited parents, check their articleNames
	foreach my $ISA(@ISAlist){  # $ISA = [lsid, articleName] (but articleName shuld be null anyway in this case)
		my $what_it_is = $ISA->{lsid};
		# my $articleName = $ISA->{articleName}
		map {($x=1) if ($what_it_is eq $_)} @primitive_lsids; # test primitives against this one
	}
	return $x; # return flag state
}



=head2 deregisterObjectClass

=over 3

=item *  used to remove an Object Class from the Class ontology

=item *  this will not be successful until you respond positively to an email sent to the address that you provided when registering that object.

=item *  you may only deregister Classes that you yourself registered!

=item *  you may not deregister Object Classes that are being used as input or output by ANY service

=item *  you may not deregister Object Classes that are in a ISA or HASA relationship to any other Object Class.

=back


Input XML :

 <deregisterObjectClass>
   <objectType>ObjectOntologyTerm</objectType>
 </deregisterObjectClass>

Ouptut XML :

...Registration Object... 

=cut

sub deregisterObjectClass {
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );

	my ( $pkg, $payload ) = @_;
	my $OntologyServer = &_getOntologyServer( ontology => 'object' );
	return &_error( "Message Format Incorrect", "" ) unless ($payload);
	my ($class) = &_deregisterObjectPayload($payload);
	$debug && &_LOG("deregister object type $class\n");
	return &_error( "Must include class of object to deregister", "" )
	  unless ($class);
	my ( $success, $message, $existingURI ) =
	  $OntologyServer->objectExists( term => $class );
	return &_error( "Object class $class does not exist", "" )
	  unless ($existingURI);

	my $errormsg = $adaptor->check_object_usage(type => $existingURI);
	return &_error(
		"Object class $class is used by a service and may not be deregistered",
		""
	  )
	  if ($errormsg);
	
	my ( $success2, $message2, $URI ) =
	  $OntologyServer->deleteObject( term => $class );
	($success2 == 0) && return &_error( $message2, $URI );
	return &_success( $message2, $URI );
}

#Eddie - converted
sub _deregisterObjectPayload {
	my ($payload) = @_;
	my $Parser    = XML::LibXML->new();
	my $doc       = $Parser->parse_string($payload);
	my $Object    = $doc->getDocumentElement();
	my $obj       = $Object->nodeName;
	return undef unless ( $obj eq 'deregisterObjectClass' );
	return &_nodeTextContent( $Object, "objectType" );
}

=head2 registerServiceType

=over 3


=item *  used to register a new node in the Service Ontology

=item *  the ISA ontology terms must exist or this registration will fail.

=item *  all parameters are required.

=item *  email must be valid for later deregistration or updates

=back


Input XML :

        <registerServiceType>
         <serviceType>NewServiceType</serviceType>
         <contactEmail>your_name@contact.address.com</contactEmail>
         <authURI>Your.URI.here</authURI>
         <Description>
           <![CDATA[ human description of service type here]]>
         </Description>
         <Relationship relationshipType="RelationshipOntologyTerm">
           <serviceType>ExistingServiceType</serviceType>
           <serviceType>ExistingServiceType</serviceType>
         </Relationship>
         <Relationship relationshipType="AnotherRelationship">
              ....
         </Relationship>
        </registerServiceType>


Output XML :

...Registration Object...

=cut

sub registerServiceType {

	# this contacts the ontology server to register
	# the ontology and writes the resulting URI into
	# the MOBY Central database
	my ( $pkg, $payload ) = @_;
	my ( $success, $message, $URI );
	my $OntologyServer = &_getOntologyServer( ontology => 'service' );
	$debug
	  && &_LOG(
"\n\npayload\n**********************\n$payload\n***********************\n\n"
	  );
	my ( $term, $desc, $relationships, $email, $auth ) =
	  &_registerServiceTypePayload($payload);
	$debug
	  && &_LOG(
"\n\nterm $term\ndesc $desc\nrel $relationships\nemail $email\nauth $auth"
	  );
	unless ( defined $term && defined $desc && defined $auth && defined $email )
	{

		if ( $term =~ /FAILED/ ) {
			return &_error( "Malformed XML\n $term", "" );
		}
		return &_error(
"Malformed XML\n may be missing required parameters serviceType, Description, authURI or contactEmail",
			""
		);
	}
	#check character encoding
	unless ( decode_utf8( $term ) eq $term && decode_utf8( $desc ) eq $desc && decode_utf8( $auth ) eq $auth && decode_utf8( $email ) eq $email )
	{
		return &_error(
"Invalid character encoding\n One of serviceType, Description, authURI or contactEmail were not UTF-8 encoded.",
			""
		);
	}

	return &_error( "Malformed authURI - must not have an http:// prefix", "" )
	  if $auth =~ '[/:]';
	return &_error( "Malformed authURI - must take the form NNN.NNN.NNN", "" )
	  unless $auth =~ /\./;
	return &_error(
"Malformed email - must be a valid email address of the form name\@organization.foo",
		""
	  )
	  unless $email =~ /\S\@\S+\.\S+/;
	 return &_error("serviceType name may not contain spaces or other characters invalid in a URN",
		""
	  )
	  if $term =~ /[\/\'\\\s"\&\<\>\[\]\^\`\{\|\}\~%\!\@#\$\*\+=:]/;

	# validate that the final ontology will be valid
	my ( $exists, $exists_message, $existingURI ) =
	  $OntologyServer->serviceExists( term => $term );  # success = 1 if it does
	( ( $exists == 1 )
		  && return &_error( "Service type $term already exists", $existingURI )
	);

	# is the relationship valid?
	my $OSrel = MOBY::OntologyServer->new( ontology => 'relationship' );
	if ( keys %{$relationships} ) {
		while ( my ( $reltype, $obj ) = each %{$relationships} ) {
			my ( $success, $desc, $URI ) = $OSrel->relationshipExists(
				term     => $reltype,
				ontology => 'service'
			);
			( !$success ) && return &_error(
"Relationship type $reltype does not exist in the relationship ontology",
				""
			);
		}
	}

	# are the predicate service types valid?
	my $OSsrv = MOBY::OntologyServer->new( ontology => 'service' );
	if ( keys %{$relationships} ) {
		while ( my ( $srvtype, $svcs ) = each %{$relationships} ) {
			foreach my $svc ( @{$svcs} ) {
				my ( $success, $desc, $URI ) =
				  $OSsrv->serviceExists( term => $svc );
				( !$success ) && return &_error(
"Service type $srvtype does not exist in the service ontology",
					""
				);
			}
		}
	}

	# hunky dorey.  Now register!
	( $success, $message, $URI ) = $OntologyServer->createServiceType(
		node          => $term,
		description   => $desc,
		authority     => $auth,
		contact_email => $email
	);
	($success == 0) && return &_error( $message, $URI );
	my @failures;
	if ( keys %{$relationships} ) {
		while ( my ( $reltype, $obj ) = each %{$relationships} ) {
			foreach my $serviceType ( @{$obj} ) {
				my ( $success, $message ) =
				  $OntologyServer->addServiceRelationship(
					subject_node  => $term,
					relationship  => $reltype,
					object_node   => $serviceType,
					authority     => $auth,
					contact_email => $email
				  );
				($success == 0) && push @failures, $serviceType;
			}
		}
	}
	if ( scalar(@failures) ) {
		my ( $success, $message, $deleteURI ) =
		  $OntologyServer->deleteServiceType( term => $term )
		  ;    # hopefully this situation will never happen!
		($success == 0) && return &_error(
			"Service registration failed ISA connections,
		and subsequently failed deletion.  This is a critical error,
		and may indicate corruption of the MOBY Central registry", $deleteURI
		);
		return &_error(
"Service failed to register due to failure during registration of relationships"
			  . ( join ",", (@failures) ) . "\n",
			""
		);
	}
	return &_success( "Service type $term registered successfully.", $URI );
}

#Eddie - converted
sub _registerServiceTypePayload {
	my ($payload) = @_;
	$debug && &_LOG("_registerServiceTypePayload payload=$payload\n");
	my $Parser = XML::LibXML->new();
	my $doc    = $Parser->parse_string($payload);
	my $Object = $doc->getDocumentElement();
	my $obj    = $Object->nodeName;
	return undef unless ( $obj eq 'registerServiceType' );
	my $type  = &_nodeTextContent( $Object,  "serviceType" );
	my $email = &_nodeTextContent( $Object,  "contactEmail" );
	my $auth  = &_nodeTextContent( $Object,  "authURI" );
	my $desc  = &_nodeCDATAContent( $Object, "Description" );
	my %relationships;
	my $x                = $doc->getElementsByTagName("Relationship");
	my $no_relationships = $x->size();

	for ( my $n = 1 ; $n <= $no_relationships ; ++$n ) {
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
			my @child2 = $_->childNodes;
			foreach (@child2) {

				#print getNodeTypeName($_), "\t", $_->toString,"\n";
				next unless $_->nodeType == TEXT_NODE;
				push @{ $relationships{$relationshipType} }, $_->toString;
			}
		}
	}
	$debug
	  && &_LOG(
"got $type, $desc, \%relationships, $email, $auth from registerServiceTypePayload\n"
	  );
	  
	return
		"FAILED! a service type '$type' was found to have no relationships\n" if keys( %relationships ) == 0 ;

	return ( $type, $desc, \%relationships, $email, $auth );
}

=head2 deregisterServiceType

=over 3

=item *  used to deregister a Service term from the Service ontology

=item *  will fail if any services are instances of that Service Type

=item *  will fail if any Service Types inherit from that Service Type.

=back


Input XML :

        <deregisterServiceType>
          <serviceType>ServiceOntologyTerm</serviceType>
        </deregisterServiceType>

Ouptut XML :

...Registration Object... 

=cut

sub deregisterServiceType {
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );

	my ( $pkg, $payload ) = @_;
	my $OntologyServer = &_getOntologyServer( ontology => 'service' );
	return &_error( "Message Format Incorrect", "" ) unless ($payload);
	my ($term) = &_deregisterServiceTypePayload($payload);
	$debug && &_LOG("deregister serviceType accession $term\n");
	return &_error(
		"Must include an accession number to deregister a serviceType", "" )
	  unless ($term);
	my ( $success, $message, $existingURI ) = $OntologyServer->serviceExists( term => $term );    # hopefully this situation will never happen!
	return &_error( "Service Type $term does not exist in the ontology", "" )
	  unless ($existingURI);
	
	my $result = $adaptor->query_service_instance(service_type_uri => $existingURI);
	my $row = shift(@$result);
	my $lsid = $row->{lsid};
	
	return &_error( "A registered service depends on this service type", "" )
	  if ($lsid);
	my ( $success2, $message2, $deleteURI ) =
	  $OntologyServer->deleteServiceType( term => $term )
	  ;    # hopefully this situation will never happen!
	(($success2 == 0)) && return &_error( $message2, $deleteURI );
	return &_success( "Service type $term deleted.", $deleteURI );
}

#Eddie - converted
sub _deregisterServiceTypePayload {
	my ($payload) = @_;
	my $Parser    = XML::LibXML->new();
	my $doc       = $Parser->parse_string($payload);
	my $Object    = $doc->getDocumentElement();
	my $obj       = $Object->nodeName;                 #Eddie- unsure
	return undef unless ( $obj eq 'deregisterServiceType' );
	return &_nodeTextContent( $Object, "serviceType" );
}

=head2 registerNamespace

=over 3


=item *  used to register a new Namespace in the Namespace controlled vocabulary

=item *  must provide a valid email address

=item *  all parameters are required.

=back


Input XML :

        <registerNamespace>
           <namespaceType>NewNamespaceHere</namespaceType>
           <contactEmail>your_name@contact.address.com</contactEmail>
           <authURI>Your.URI.here</authURI>
           <Description>
              <![CDATA[human readable description]]>
           </Description>
        </registerNamespace>

Output XML :

...Registration Object...


=cut

sub registerNamespace {

	# this contacts the ontology server to register
	# the ontology and writes the resulting URI into
	# the MOBY Central database
	my ( $pkg, $payload ) = @_;
	my ( $success, $message );
	my $OntologyServer = &_getOntologyServer( ontology => 'namespace' );
	$debug
	  && &_LOG(
"\n\npayload\n**********************\n$payload\n***********************\n\n"
	  );
	my ( $term, $auth, $desc, $email ) = &_registerNamespacePayload($payload);

	$debug && &_LOG("\n\nterm $term\ndesc $desc\nemail $email\nauth $auth");
	unless ( defined $term && defined $desc && defined $auth && defined $email )
	{
		return &_error(
"Malformed XML; may be missing required parameters namespaceType, Description, authURI or contactEmail",
			""
		);
	}

	# check encoding
	unless ( decode_utf8( $term ) eq $term && decode_utf8( $desc ) eq $desc && decode_utf8( $auth ) eq $auth && decode_utf8( $email ) eq $email )
	{
		return &_error(
"Invalid character encoding; one or all of namespaceType, Description, authURI or contactEmail were not UTF-8 encoded.",
			""
		);
	}

	return &_error("Namespace name may not contain spaces or other characters invalid in a URN",
		""
	)
	  if $term =~ /[\/\'\\\s"\&\<\>\[\]\^\`\{\|\}\~%\!\@#\$\*\+=:]/;
	return &_error( "Malformed authURI - must not have an http:// prefix", "" )
	  if $auth =~ '[/:]';
	return &_error( "Malformed authURI - must take the form NNN.NNN.NNN", "" )
	  unless $auth =~ /\./;
	return &_error(
"Malformed email - must be a valid email address of the form name\@organization.foo",
		""
	  )
	  unless $email =~ /\S\@\S+\.\S+/;
	my ( $exists, $exists_message, $URI ) =
	  $OntologyServer->namespaceExists( term => $term )
	  ;    # success = 1 if it does
	( ( $exists == 1 )
		  && return &_error( "Namespace $term already exists", $URI ) );
	( $success, $message, $URI ) = $OntologyServer->createNamespace(
		node          => $term,
		description   => $desc,
		authority     => $auth,
		contact_email => $email
	);
	($success == 0) && return &_error( $message, $URI );
	return &_success( "Namespace type $term registered successfully.", $URI );
}

#Eddie - converted
sub _registerNamespacePayload {
	my ($payload) = @_;
	my $Parser    = XML::LibXML->new();
	my $doc       = $Parser->parse_string($payload);
	my $Object    = $doc->getDocumentElement();
	my $obj       = $Object->nodeName;
	return undef unless ( $obj eq 'registerNamespace' );
	my $type    = &_nodeTextContent( $Object,  "namespaceType" );
	my $authURI = &_nodeTextContent( $Object,  "authURI" );
	my $desc    = &_nodeCDATAContent( $Object, "Description" );
	my $contact = &_nodeTextContent( $Object,  "contactEmail" );
	return ( $type, $authURI, $desc, $contact );
}

=head2 deregisterNamespace

=over

=item *   used to remove a Namespace from the controlled vocabulary

=item *  will fail if that namespace is being used by any services

=item *  you will recieve an email for confirmation of the deregistration

=back


Input XML :

        <deregisterNamespace>
           <namespaceType>MyNamespace</namespaceType>
        </deregisterNamespace>

Ouptut XML :

...Registration Object... 


=cut

sub deregisterNamespace {
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );

	my ( $pkg, $payload ) = @_;
	my $OntologyServer = &_getOntologyServer( ontology => 'namespace' );
	return &_error( "Message Format Incorrect", "" ) unless ($payload);
	my ($term) = &_deregisterNamespacePayload($payload);
	$debug && &_LOG("deregister namespaceType accession $term\n");
	return &_error( "Must include a Namespace type to deregister.", "" )
	  unless ($term);
	my ( $success, $message, $existingURI ) =
	  $OntologyServer->namespaceExists( term => $term );
	return &_error( "Namespace Type $term does not exist", "" )
	  unless ($existingURI);
	my ($err, $errstr) = $adaptor->check_namespace_usage(namespace_type_uris => $existingURI,
							     type => $term);
	return &_error( $errstr, "")
			  if ($err);
			  			  	
	my ( $success2, $message2, $URI ) =
	  $OntologyServer->deleteNamespace( term => $term );
	($success2 == 0) && return &_error( $message2, $URI );
	return &_success( "Namespace type $term deregistered successfully.", $URI );
}

#Eddie - converted
sub _deregisterNamespacePayload {
	my ($payload) = @_;
	my $Parser    = XML::LibXML->new();
	my $doc       = $Parser->parse_string($payload);
	my $Object    = $doc->getDocumentElement();
	my $obj       = $Object->nodeName;
	return undef unless ( $obj eq 'deregisterNamespace' );
	return &_nodeTextContent( $Object, "namespaceType" );
}

=head2 registerService

=over 3

=item *  all elements are required

=item *  a service must have at least one Input OR Output Object Class.  Either Input or Output may be blank to represent "PUT" or "GET" services respectively

=item *  the contactEmail address must be valid, as it is used to authorize deregistrations and changes to the service you registered.

=item *  the "authoritativeService" tag is used to indicate whether or not the registered service is "authoritative" for that transformation. i.e. if anyone else were to perform the same transformation they would have to have obtained the information to do so from you. This is similar to, but not necessarily identical to, mirroring someone elses data, since the data in question may not exist prior to service invocation.

=item *  only Input Secondary articles are defined during registration; Output Secondary objects are entirely optional and may or may not be interpreted Client-side using their articleName tags.

=item *  Service Categories:

=over 3

=item *  moby - for services that use the MOBY SOAP messaging format and object structure (i.e. the objects used in service transaction inherit from the root 'Object' Class in the MOBY Class ontology).

=over 2

=item *  authURI - a URI representing your organization (e.g. yourdomain.com); no http-prefix, and no trailing path information is allowed.

=item *  serviceName - an arbitrary, but unique, name for your service within your authURI namespace

=item *  URL - the URL to a SOAP CGI server that can invoke a method as described by your serviceName

=back

=item *  wsdl - for other SOAP services that do not use the MOBY messaging format. The other elements in the registration should be interpreted as follows:

=over 2

=item *  authURI - a URI representing your organization (e.g. yourdomain.com); no http-prefix, and no trailing path information is allowed.

=item *  serviceName - an arbitrary, but unique, name for your service within your authURI namespace

=item *  URL - the URL from which a WSDL document describing your service can be retrieved by an HTTP GET call.

=back

=item *  Comments about Input and Output for MOBY and non-MOBY services

=over 2

=item *  in "moby" services, the input and output messaging structure is defined by the BioMOBY API, and the services use data Objects that are defined in the Class ontology as inheriting from the root "Object" Class.

=item *  For "wsdl" services, there is additional flexibility:

=over 2

=item *  Similar to a "moby" service, your "wsdl" service must consume/produce named data types.  These are represented as LSID's

=item *  YOU DO NOT NEED TO REGISTER THESE DATA TYPES in MOBY Central; it is up to you what your LSID's represent, and MOBY Central WILL NOT try to resolve them!

=item *  You may mix ontologies when describing your service - i.e. you may freely use any MOBY Object as your input or (XOR) your output and use a non-MOBY object (LSID) for the alternate so long as you follow the MOBY message structure for the parameter that uses the MOBY Object

=over 2

=item *  You may register, for example, a service that consumes a non-MOBY data Class and outputs a MOBY data class, so long as you follow the MOBY Messaging format for the output data

=item *  You may register, for example, a service that consumes a MOBY data Class and outputs a non-MOBY data class, so long as you follow the MOBY Messaging format for the input data

=item *  NOTE: Nether of the cases above are considered MOBY services, and are therefore described in the category of "soap" service

=back

=back

=item *  secondaryArticles  - not applicable; should be left out of message.

=back

=back

=back


 Input XML :

      <registerService>
         <Category>moby</Category> <!-- one of 'moby', 'moby-async', 'doc-literal', 'doc-literal-async', 'cgi', 'cgi-async'; 'moby' and 'moby-async' are RPC encoded -->
         <serviceName>YourServiceNameHere</serviceName>
         <serviceType>TypeOntologyTerm</serviceType>
         <signatureURL>http://path.to/your/signature/RDF.rdf</sisgnatureURL>
         <servieLSID>urn:lsid:biomoby.org:serviceinstance:myservice:version</serviceLSID>
         <authURI>your.URI.here</authURI>
         <URL>http://URL.to.your/Service.script</URL>;
         <contactEmail>your_name@contact.address.com</contactEmail>
         <authoritativeService>1 | 0 </authoritativeService>
         <Description><![CDATA[
               human readable COMPREHENSIVE description of your service]]>
         </Description>
         <Input>
              <!-- zero or more Primary (Simple and/or Collection) articles -->
         </Input>
         <secondaryArticles>
              <!-- zero or more INPUT Secondary articles -->
         </secondaryArticles>
         <Output>
              <!-- zero or more Primary (Simple and/or Collection) articles --> 
         </Output>
      </registerService>

 Output XML :

   ...Registration Object...

 There are two forms of Primary articles:

=over 3

=item *  Simple - the article consists of a single MOBY Object

=item *  Collection - the article consists of a collection ("bag") of MOBY Objects (not necessarily the same object type).

=over 3

=item *  Their number/order is not relevant, nor predictable

=item *  If order is important to the service provider, then a collection should not be used, rather the collection should be broken into named Simple parameters. This may impose limitations on the the types of services that can be registered in MOBY Central. If it becomes a serious problem, a new Primary article type will be added in a future revision.

=item *  The use of more than one Class in a collection is difficult to interpret, though it is equally difficult to envision a service that would require this. It is purposely left losely defined since any given Service Instance can tighten up this definition during the registration process.

=item *  A collection may contain zero or more Objects of each of the Classes defined in the XML during Service Instance registration.

=over 3

=item *  Each distinct Object Class only needs to be included once in the XML. Additional entries of that Class within the same Collection definition must be ignored.

=back

=back

=back

An example of the use of each of these might be another BLAST service, where you provide the sequences that make up the Blast database as well as the sequence to Blast against it. The sequences used to construct the database might be passed as a Collection input article containing multiple Sequence Objects, while the sequence to Blast against it would be a Simple input article consisting of a single Sequence Object.

There is currently only one form of Secondary article:

=over 3

=item *  Secondary - the article may or may not be specifically configured by the client as Input, and may or may not be returned by the Service as output.

=over 3

=item *  In the case of inputs, they are generally user-configurable immediately prior to service invocation.

=item *  During service invocation a Client must send all Secondary articles defined in the Service Instance, even if no value has been provided either as default, or Client-side.

=item *  Secondary articles that are considered "required" by the Service should be registered with a default value.

=item *  The Service may fail if an unacceptable value is passed for any Secondary Article.

=back

=back


Articles are, optionally, named using the articleName attribute. This might be used if, for example, the service requires named inputs. The order of non-named articles in a single Input or Output set MUST not be meaningful.

The XML structure of these articles is as follows:

=over 3

=item *  Simple (note that the lsid attribute of the objectType and Namespace element need only be present in the article when it is present in a response document from MOBY Central such as the result of a findService call.  These attributes are ignored by MOBY Central when they appear in input messages such as registerService)

         <Simple articleName="NameOfArticle">
           <objectType lsid='urn:lsid:...'>ObjectOntologyTerm</objectType>
           <Namespace lsid='urn:lsid:...'>NamespaceTerm</Namespace>
           <Namespace lsid='urn:lsid:...'>...</Namespace><!-- one or more... -->
         </Simple>

=item *  Collection note that articleName of the contained Simple objects is not required, and is ignored.


         <Collection articleName="NameOfArticle">
            <Simple>......</Simple> <!-- Simple parameter type structure -->
            <Simple>......</Simple> <!-- DIFFERENT Simple parameter type (used only when multiple Object Classes appear in a collection) -->
         </Collection>

=item *  Secondary


          <Parameter articleName="NameOfArticle">
                <datatype>Integer|Float|String|DateTime</datatype>
		<description><![CDATA[freetext description of purpose]]></description>
                <default>...</default> <!-- any/all of these -->
                <max>...</max>         <!-- ... -->
                <min>...</min>         <!-- ... -->
                <enum>...<enum>        <!-- ... -->
                <enum>...<enum>        <!-- ... -->
          </Parameter>

=back


=cut			  

# inputXML (FOR CGI GET SERVICES):
# <registerService>
#  <Category>cgi</Category>
#  <serviceName>YourServiceNameHere</serviceName>
#  <serviceType>YourServiceTypeHere</serviceType>
#  <authURI>your.URI.here</authURI>
#  <contactEmail>blah@blow.com</contactEmail>
#  <URL>http://URL.to.your/CGI.pl</URL>
#  <authoritativeService>your.URI.here</authoritativeService>
#  <Input>
#     <!-- zero or more pimary (simple or collection) articles -->
#  </Input>
#  <Output>
#     <!-- zero or more pimary (simple or collection) articles -->
#  </Output>
#  <secondaryArticles>
#  </secondaryArticles>
#  <Description><![CDATA[
#	  human readable description of your service]]>
#  </Description>
# </registerService>

sub registerService {
	my ( $pkg, $payload ) = @_;
	my (
		$serviceName,  $serviceType, $AuthURI,
		$contactEmail, $URL,         $authoritativeService,
		$desc,         $Category,    $INPUTS,
		$OUTPUTS,      $SECONDARY,   $signatureURL, $serviceLSID
	  )
	  = &_registerServicePayload($payload);

	#--------RDFagent call----------------------------------------
	
	# THIS IS A CALL TO moby cENTRAL REGISTER SERVICE THAT CONTAINED ONLY A sIGNATUREURL
	# THE IMPLICATION IS THAT THEY ARE ASKING YOU TO VISIT THEIR urL now!!!!
	if ( defined $signatureURL ) {
		my $ch = 0;
		my $i;  # first check if any other parameters were filled-in.  If so, then the implication is that they want us to register based on the data they have provided
		foreach $i ( $serviceName, $serviceType, $AuthURI, $contactEmail, $URL, $desc)
		{
			if ( defined $i && $i ne "") {
				$ch = 1;
			}
		}

		if ( $ch == 0 ) {
			my $conf = MOBY::Config->new();
			my $path = $conf->{mobycentral}->{rdfagent};
			#Assumes JAVA_HOME is set!!!
			my $JAVA_HOME = $ENV{JAVA_HOME} || "";
			if ($JAVA_HOME) {
				$JAVA_HOME .="/bin/java";
			} else {
				$JAVA_HOME ="java";
			}
			$signatureURL =~ s/\s+//g;
			my $exit = system ("$JAVA_HOME", "-DRDFagent.home=$path", '-jar', $path. '/RDFagent.jar','-url',$signatureURL);
			my $rez = _how_exit($exit);
			return &_success( "The RDFagent call was successful.",
				"",""
			  )
			  if ( $rez == 0 );
			return &_error(
				"The call to the RDF agent resulted in failure. The agent encountered problems communicating with the registry. Please try again.", "" )
			  if ( $rez == 10 );
			return &_error(
				"The call to agent failed because the agent is using a bad URL/URI for the registry. Please contact the registry's administrator and let them know.", "" )
			  if ( $rez == 11 );
			return &_error(
				"The RDF agent call was partially successful, but there was an internal error. Please let the administrator of the registry know about this problem.", "" )
			  if ( $rez == 12 );
			return &_error(
				"No services in the registry match the given URL and the signatureURL didn't contain any services. The RDF agent was called, but found nothing useful.", "" )
			  if ( $rez == 13 );
			return &_success( "The RDFagent call was successful. All services described by $signatureURL have been removed because the URL was unreachable.",
				"",""
			  )
			  if ( $rez == 14 );
			
			return &_error(
				"The call to the RDF agent resulted in failure and I am not sure why. Please try again and if the error persists, let the administrator of the registry know.", "" )
			  if ( $rez != 0 );

		}
	}

	#---------------------------------------------------------------

	$authoritativeService = (defined($authoritativeService) && $authoritativeService) ? 1 : 0;
	my $error;
	$error .= "missing serviceName \n" unless defined $serviceName;
	$error .= "missing serviceType \n" unless defined $serviceType;
	$error .= "invalid character string for serviceName.  Must start with a letter followed by [A-Za-z0-9_]\n" if ($serviceName =~ /^[^A-Za-z]/);
	$error .= "invalid character string for serviceName.  Must start with a letter followed by [A-Za-z0-9_]\n" if ($serviceName =~ /^.+?[^A-Za-z0-9_]/);
	$error .= "service name may not contain spaces or other characters invalid in a URN" if $serviceName =~ /[\/\'\\\s"\&\<\>\[\]\^\`\{\|\}\~%\!\@#\$\*\+=]/;

	#	$error .="missing signatureURL \n" unless defined $signatureURL;
	$error .= "missing authURI \n"      unless defined $AuthURI;
	$error .= "invalid character encoding; authURI not encoded as UTF-8\n" unless decode_utf8( $AuthURI ) eq $AuthURI;
	$error .= "missing contactEmail \n" unless defined $contactEmail;
	$error .= "invalid character encoding; contactEmail not encoded as UTF-8\n" unless decode_utf8( $contactEmail ) eq $contactEmail;
	return &_error( "Malformed authURI - must not have an http:// prefix", "" )
	  if $AuthURI =~ '[/:]';
	return &_error( "Malformed authURI - must take the form NNN.NNN.NNN", "" )
	  unless $AuthURI =~ /\./;
	return &_error("Malformed email - must be a valid email address of the form name\@organization.foo","")
	  unless $contactEmail =~ /\S\@\S+\.\S+/;
	$error .= "missing URL \n"         unless defined $URL;
	$error .= "invalid character encoding; URL not encoded as UTF-8\n" unless decode_utf8( $URL ) eq $URL;
	$error .= "missing description \n" unless defined $desc;
	$error .= "invalid character encoding; description not encoded as UTF-8\n" unless decode_utf8( $desc ) eq $desc;
	$error .= "missing Category \n"    unless defined $Category;
	$error .= "invalid character encoding; service name not encoded as UTF-8\n" unless decode_utf8( $serviceName ) eq $serviceName;
	return &_error( "malformed payload $error\n\n", "" ) if ($error);
	return &_error(
		"Category may take the (case sensitive) values 'moby', 'moby-async', 'cgi', 'cgi-async', 'doc-literal', and 'doc-literal-async', \n",
		""
	  )
	  unless (
		( $Category eq "wsdl" )
		|| ( $Category eq "moby" )
		|| ( $Category eq "moby-async" )
		|| ( $Category eq "cgi" )
		|| ( $Category eq "cgi-async" )
	    || ( $Category eq "doc-literal" )
		|| ( $Category eq "doc-literal-async"));

#test the existence of the service
	return &_error( "This service already exists", "" ) if (MOBY::service_instance->new(
		servicename   => $serviceName,
		authority_uri => $AuthURI,
		test => 1));


	my @IN   = @{$INPUTS};
	my @OUT  = @{$OUTPUTS};
	my @SECS = @{$SECONDARY};
	return &_error(
		"must include at least one input and/or one output object type", "" )
	  unless ( scalar @IN || scalar @OUT );
	my %objects_to_be_validated;
	foreach ( @IN, @OUT ) {

		foreach my $objectName ( &_extractObjectTypes($_) ) {
			$objects_to_be_validated{$objectName} = 1;
		}
	}
	my $OS = MOBY::OntologyServer->new( ontology => 'object' );
	foreach ( keys %objects_to_be_validated ) {
		my ( $valid, $message, $URI ) = $OS->objectExists( term => $_ );
		return &_error( "$message", "$URI" )
		  unless ( $valid
			|| ( ( $_ =~ /urn:lsid/i ) && !( $_ =~ /urn:lsid:biomoby.org/i ) )
		  );    # either valid, or a non-moby LSID
	}
	$debug
	  && &_LOG(
		"\n\n\aall objects okay - either valid MOBY objects, or LSID's\n");
	$OS = MOBY::OntologyServer->new( ontology => 'service' );
	my ( $valid, $message, $URI ) = $OS->serviceExists( term => $serviceType );

	#print STDERR "\n\nChecking $URI\n\n";
	return &_error( "$message", "$URI" )
	  unless (
		$valid
		|| ( ( $serviceType =~ /urn:lsid/i )
			&& !( $serviceType =~ /urn:lsid:biomoby.org/i ) )
	  );    # either valid, or a non-MOBY LSID
	        #print STDERR "\n\nChecking $URI OK!!\n\n";
	        # right, registration should be successful now!
	my $SVC = MOBY::service_instance->new(
		category      => $Category,
		servicename   => $serviceName,
		service_type  => $serviceType,
		authority_uri => $AuthURI,
		url           => $URL,
		contact_email => $contactEmail,
		authoritative => $authoritativeService,
		description   => $desc,
		signatureURL  => $signatureURL,
		lsid		=> $serviceLSID
	);
	return &_error( "Service registration failed for unknown reasons", "" ) if ( !defined $SVC );

	$debug && &_LOG("new service instance created\n");

	foreach my $IN (@IN) {
		my ( $success, $msg ) = &_registerArticles( $SVC, "input", $IN, undef );
		unless ( $success == 1 ){
		    $SVC->DELETE_THYSELF;
		    return &_error("Registration Failed During INPUT Article Registration: $msg", "" )
		}
	}
	foreach my $OUT (@OUT) {
		my ( $success, $msg ) = &_registerArticles( $SVC, "output", $OUT, undef );
		unless ( $success == 1 ){
		    $SVC->DELETE_THYSELF;
		    return &_error("Registration Failed During OUTPUT Article Registration: $msg", "" )
		}
	}
	foreach my $SEC (@SECS) {
		my ( $success, $msg ) = &_registerArticles( $SVC, "secondary", $SEC, undef );
		unless ( $success == 1 ){
		    $SVC->DELETE_THYSELF;
		    return &_error("Registration Failed During SECONDARY Article Registration: $msg", "" )
		}
	}

 # we're going to do a findService here to find the service that we just created
 # and use the resulting XML to create a MOBY::Client::ServiceInstance object
 # that we can then use to retrieve the RDF for that service signature.
 # this is roundabout, I agree, but it is the most re-usable way to go at
 # the moment.
	my ( $si, $reg ) = &findService(
		'', "<findService>
                                                  <authURI>$AuthURI</authURI>;
                                                  <serviceName>$serviceName</serviceName>;
                                            </findService>"
	);
	unless ($si) {
		$SVC->DELETE_THYSELF;
		return &_error("Registration Failed - newly registered service could not be discovered","");
	}


	my $RDF = _getServiceInstanceRDF(name=>$serviceName, auth=>$AuthURI);
	unless ($RDF) {
		return &_success( "Registration successful but unable to create RDF - please contact your MOBY Central administrator",
			$SVC->lsid, "" );
	}
	unless ( $RDF =~ /RDF/ ) {
		return &_success(
			"Registration successful but RDF is not correctly formatted:\n\n $RDF",
			$SVC->lsid, "" );
	}
	# wrap RDF in CDATA - moved it here, so that we can return the 'bad' rdf above
	return &_success( "Registration successful", $SVC->lsid,
		"<![CDATA[$RDF]]>" );
}

sub _getServiceInstanceRDF {
	my ( %args ) = @_;
	my $x = MOBY::RDF::Ontologies::Services->new;
	my $xml = "";
	eval {
		$xml = $x->findService(
			{
				serviceName => $args{name},
				authURI => $args{auth},
				isAlive => 'no'
			}
	 );
	};
	if ($@) {
		return "";
	}
 	print STDERR "$xml\n";
 	if ($x) {
		return "$xml" unless ( $xml =~ /title>Service Instance Not Found</ );
 	}
 	return "";
}

#Eddie - Converted
sub _registerArticles {
	my ( $SVC, $inout, $node, $collid ) = @_
	  ; # node is a node of the XML dom representing an article to be registered
	return ( -1, 'Bad node' ) unless $node->nodeType == ELEMENT_NODE;

	# this is a Simple, Collection, or Parameter object
	my $simp_coll = $node->nodeName;
	$debug && &_LOG("TAGNAME in $inout _registerArticle is $simp_coll");
	my $article = $node->getAttributeNode("articleName");

	if ($article) { 
		$article = $article->getValue();
	}
	return (-1,"Invalid articlename name found. Articlenames may not contain spaces or other special characters.") 
			 if $article =~ /([\+\=:\s\&\<\>\[\]\^\`\{\|\}\~\(\)\\\/\$\#\@\,\|\?\.!\*\;\'\"])/;
	
	#check encoding for those articles that are not the empty string or a string of whitespace
	return (-1,"Invalid character encoding; articlename not UTF-8 encoded.") 
		 unless decode_utf8( $article ) eq $article;

	$debug && &_LOG("ARTICLENAME in _registerArticle is $article");
	if (lc($inout) eq "input"){
	    return (-1, "Input Simples and collections are required to have an articleName as of API version 0.86") if (!$article && !$collid);
	}

	my ( $object_type, @namespaces );
	if ( $simp_coll eq "Collection" ) {
		$debug && &_LOG("Collection!\n");
		my $collection_id;
		if ( $inout eq 'input' ) {
			$collection_id =
			  $SVC->add_collection_input( article_name => $article );
		}
		elsif ( $inout eq 'output' ) {
			$collection_id =
			  $SVC->add_collection_output( article_name => $article );
		}
		else {
			$SVC->DELETE_THYSELF;
			return ( -1, "found article that was neither input nor output" );
		}

		my $Simples = $node->getElementsByTagName('Simple');
		my $length  = $Simples->size();
		unless ( $length > 0 ) {
			return ( -1,"Your collection must be a collection of one Simple type"
			);
		}
		unless ( $length == 1 ) {
			return ( -1,"As of API v0.86, Collections must not be of more than one Simple type"
			);
		}
		for ( my $x = 1 ; $x <= $length ; ++$x ) {
			my ( $success, $message ) = &_registerArticles( $SVC, $inout, $Simples->get_node($x), $collection_id );
			unless ( $success == 1 ) { return ( -1, $message ); }
		}
	} elsif ( $simp_coll eq "Simple" ) {
		my $article = $node->getAttributeNode("articleName");
		$article = $article->getValue() if $article;

		# get object type and its URI from the ontoogy server
		my $types = $node->getElementsByTagName('objectType');
		my $OE = MOBY::OntologyServer->new( ontology => "object" );
		foreach ( $types->get_node(1)->childNodes ) { # should only ever be one!
			( $_->nodeType == TEXT_NODE ) && ( $object_type = $_->toString );
		}
		my ( $success, $message, $typeURI ) =
		  $OE->objectExists( term => $object_type );
		if (   ( !($success) && ( $object_type =~ /urn:lsid:biomoby.org/i ) )
			|| ( !($success) && !( $object_type =~ /urn:lsid/i ) ) )
		{    # if the object doesn't exist, and it isn't an LSID
			$SVC->DELETE_THYSELF;
			return ( -1,
				"object: $object_type does not exist, and is not an LSID" );
		}    # kill it all unless this was successful!
		my $namespace_string;
		my $namespaces = $node->getElementsByTagName('Namespace');
		my $num_ns     = $namespaces->size();
		$OE = MOBY::OntologyServer->new( ontology => "namespace" );
		for ( my $n = 1 ; $n <= $num_ns ; ++$n ) {
			foreach my $name ( $namespaces->get_node($n)->childNodes ) {
				if ( $name->nodeType == TEXT_NODE ) {
					my $term = $name->toString;
					my ( $success, $message, $URI ) =
					  $OE->namespaceExists( term => $term );
					if ( ( !($success) && ( $term =~ /urn:lsid:biomoby.org/i ) )
						|| ( !($success) && !( $term =~ /urn:lsid/i ) ) )
					{    # if the object doesn't exist, and it isn't an LSID
						$SVC->DELETE_THYSELF;
						return ( -1,
							"namespace: $term doesn't exist and is not an LSID"
						);
					}
					$namespace_string .= $URI . ",";
				}
			}
		}
		chop($namespace_string);    # remove trailing comma

		my $service_instance_id;
		unless ($collid)
		{ # this SIMPLE is either alone, or is part of a COLLECTION ($collid > 0)
			 # therefore we want either its service instance ID, or its Collection ID.
			$service_instance_id = $SVC->service_instance_id;
		}    # one or the other, but not both
		if ( $inout eq 'input' ) {
			my $sinput = $SVC->add_simple_input(
				object_type_uri     => $typeURI,
				namespace_type_uris => $namespace_string,
				article_name        => $article,
				collection_input_id => $collid,
			);
			unless ($sinput) {
				$SVC->DELETE_THYSELF;
				return ( -1, "registration failed during registration of input object $typeURI.  Unknown reasons.");
			}
		}
		elsif ( $inout eq 'output' ) {
			my $soutput = $SVC->add_simple_output(
				object_type_uri      => $typeURI,
				namespace_type_uris  => $namespace_string,
				article_name         => $article,
				collection_output_id => $collid,
			);
			unless ($soutput) {
				$SVC->DELETE_THYSELF;
				return ( -1,"registration failed during registration of output object $typeURI.  Unknown reasons."
				);
			}
		}
	}
	elsif ( $simp_coll eq "Parameter" ) {
		my $parameter = $node;
		my $article   = $parameter->getAttributeNode("articleName");
		$article = $article->getValue() if $article;
		
		return (-1,"Secondary inputs must be registered with articlenames.")
			unless $article;
		
		# make sure that the articlename is corrects
		return (-1,"Secondary input had an invalid articlename. Articlenames may not contain spaces or other special characters.") 
			 if $article =~ /([\+\=\':\s\"\&\<\>\[\]\^\`\{\|\}\~\(\)\\\/\$\#\@\,\|\?\.!\*\;])/;
		
		my ( $datatype, $def, $max, $min, $description, @enums );
		my $types = $parameter->getElementsByTagName('datatype');
		if ( $types->get_node(1) ) {
			foreach ( $types->get_node(1)->childNodes )
			{    # should only ever be one!
				( $_->nodeType == TEXT_NODE ) && ( $datatype .= $_->nodeValue );
			}
		}

		#ensure that thet type is correct (Integer | String | Float | DateTime| Boolean)
		$datatype =~ s/\s//g;
		my $secondaries = $CONFIG->{valid_secondary_datatypes};
		my $valid;
		map { $valid = 1 if $datatype eq $_ } @{$secondaries};
		unless ($valid) {
			$SVC->DELETE_THYSELF;
			return ( -1,"Registration failed.  $datatype must be one of type Integer, String, DateTime, Boolean or Float."
			);
		}
		
		my $defs = $parameter->getElementsByTagName('default');
		if ( $defs->get_node(1) ) {
			foreach ( $defs->get_node(1)->childNodes )
			{    # should only ever be one!
				( $_->nodeType == TEXT_NODE ) && ( $def .= $_->nodeValue );
			}
		}
		my $maxs = $parameter->getElementsByTagName('max');
		if ( $maxs->get_node(1) ) {
			foreach ( $maxs->get_node(1)->childNodes )
			{    # should only ever be one!
				( $_->nodeType == TEXT_NODE ) && ( $max .= $_->nodeValue );
			}
		}
		my $mins = $parameter->getElementsByTagName('min');
		if ( $mins->get_node(1) ) {
			foreach ( $mins->get_node(1)->childNodes )
			{    # should only ever be one!
				( $_->nodeType == TEXT_NODE ) && ( $min .= $_->nodeValue );
			}
		}
		my $descs = $parameter->getElementsByTagName('description');
		if ( $descs->get_node(1) ) {
			foreach ( $descs->get_node(1)->childNodes )
			{    # should only ever be one!
				( $_->nodeType == TEXT_NODE ) && ( $description .= $_->nodeValue );
			}
		}

		my $enums    = $parameter->getElementsByTagName('enum');
		my $numenums = $enums->size();
		for ( my $n = 1 ; $n <= $numenums ; ++$n ) {
			foreach ( $enums->get_node($n)->childNodes )
			{    # should only ever be one!
				( $_->nodeType == TEXT_NODE )
				  && ( push @enums, $_->nodeValue );
			}
		}
		my $enum_string = join "", ( map { $_ . "," } @enums );
		chop $enum_string;    # get rid of trailing comma
		$datatype =~ s/^\s+//;
		$datatype =~ s/\s+$//;
		$def      =~ s/^\s+//;
		$def      =~ s/\s+$//;
		$max      =~ s/^\s+//;
		$max      =~ s/\s+$//;
		$min      =~ s/^\s+//;
		$min      =~ s/\s+$//;
		my $sec = $SVC->add_secondary_input(
			default_value => $def,
			maximum_value => $max,
			minimum_value => $min,
			enum_value    => $enum_string,
			datatype      => $datatype,
			article_name  => $article,
			description	=> $description,
		);

		unless ($sec) {
			$SVC->DELETE_THYSELF;
			return ( -1,
"registration failed during registration of parameter $article.  Must be of type Integer, String, DateTime, or Float."
			);
		}
	}
	return 1;
}

#Eddie - converted
sub _registerServicePayload {
	my ($payload) = @_;
	my $Parser    = XML::LibXML->new();
	my $doc       = $Parser->parse_string($payload);
	my $Object    = $doc->getDocumentElement();
	my $obj       = $Object->nodeName;
	return undef unless ( $obj eq 'registerService' );
	my $serviceName  = &_nodeTextContent( $Object, "serviceName" );
	my $Category     = &_nodeTextContent( $Object, "Category" );
	my $serviceType  = &_nodeTextContent( $Object, "serviceType" );
	my $AuthURI      = &_nodeTextContent( $Object, "authURI" );
	my $contactEmail = &_nodeTextContent( $Object, "contactEmail" );
	my $authoritativeService =
	  &_nodeTextContent( $Object, "authoritativeService" );
	my $URL          = &_nodeTextContent( $Object,  "URL" );
	my $signatureURL = &_nodeTextContent( $Object,  "signatureURL" );
	my $serviceLSID = &_nodeTextContent( $Object,  "serviceLSID" );
	my $desc         = &_nodeCDATAContent( $Object, "Description" );
	my $INPUTS  = &_nodeRawContent( $Object, "Input" );     # returns array ref
	my $OUTPUTS = &_nodeRawContent( $Object, "Output" );    # returns array ref
	my $SECONDARIES =
	  &_nodeRawContent( $Object, "secondaryArticles" );     # returns array ref
	return (
		$serviceName,  $serviceType, $AuthURI,
		$contactEmail, $URL,         $authoritativeService,
		$desc,         $Category,    $INPUTS,
		$OUTPUTS,      $SECONDARIES, $signatureURL, $serviceLSID
	);
}

#Eddie - converted
sub _extractObjectTypes {
	my ($DOM) = @_;    # DOM is either a <Simple/> or a <Collection/> article
	$debug && &_LOG("\n\n\nExtracting object types from \n$DOM	\n\n");
	unless ( ref($DOM) =~ /^XML/ ) {
		my $Parser = XML::LibXML->new();
		my $doc    = $Parser->parse_string($DOM);
		$DOM = $doc->getDocumentElement();
	}
	my $x = $DOM->getElementsByTagName("objectType");
	my @objectnames;
	my $l = $x->size();  # might be a Collection object with multiple simples...
	for ( my $n = 1 ; $n <= $l ; ++$n ) {
		my @child = $x->get_node($n)->childNodes;
		foreach (@child) {
			$debug
			  && &_LOG( getNodeTypeName($_), "\t", $_->toString, "\n" )
			  ;          #hopefully uses MobyXMLConstants.pm
			next unless ( $_->nodeType == TEXT_NODE );
			my $name = $_->toString;
			chomp $name;
			push @objectnames, $name;
		}
	}
	return (@objectnames);
}

=head2 registerServiceWSDL

 Title     :	NOT YET IMPLEMENTED
 Usage     :	


=cut

sub registerServiceWSDL {
	my ( $pkg, $serviceType, $wsdl ) = @_;
	return &_error( "not yet implemented", "" );
}

=head2 deregisterService

 Title     :	deregisterService
 Usage     :	$REG = $MOBY->deregisterService($inputXML)
 Function  :	deregister a Service
 Returns   :	$REG object 
 inputXML  :
	<deregisterService>
	  <authURI>biomoby.org</authURI>
	  <serviceName>MyFirstService</serviceName>
	</deregisterService>

 ouptutXML :  see Registration XML object


=cut

sub deregisterService {
	my ( $pkg, $payload ) = @_;
	$debug && &_LOG("\nstarting deregistration\n");
	my ( $authURI, $serviceName ) = &_deregisterServicePayload($payload);
	return &_error( "must provide an authority and a service name\n", "" )
	  unless ( $authURI && $serviceName );
	return &_error("The service specified by authority=$authURI servicename=$serviceName does not exist in the registry","")
	  unless (
		MOBY::service_instance->new(
			servicename   => $serviceName,
			authority_uri => $authURI,
			test          => 1
		));
	my $SERVICE = MOBY::service_instance->new(
		servicename   => $serviceName,
		authority_uri => $authURI
	);
	return &_error("service lookup failed for unknown reasons","") unless ($SERVICE);

	if ( $SERVICE->signatureURL ) {
		return &_error(
"it is illegal to deregister a service that has a signatureURL.  Such services must be deregistered by deleting the RDF at the location identified by the signatureURL",
			""
		);
	}

	my $result = $SERVICE->DELETE_THYSELF;
	if ($result) {
		return &_success( "Service Deregistered Successfully", "" );
	}
	else {
		return &_error( "Service deletion failed for unknown reasons", "" );
	}
}

#Eddie - converted
sub _deregisterServicePayload {
	my ($payload) = @_;
	$debug && &_LOG( "deregisterService payload: ", ($payload), "\n" );
	my $Parser = XML::LibXML->new();
	my $doc    = $Parser->parse_string($payload);
	my $Object = $doc->getDocumentElement();
	my $obj    = $Object->nodeName;                 #Eddie - unsure
	return undef unless ( $obj eq 'deregisterService' );
	my $authURI = &_nodeTextContent( $Object, "authURI" );
	my $name    = &_nodeTextContent( $Object, "serviceName" );
	return ( $authURI, $name );
}

=head2 findService

 inputXML:
          <findService>
             <!--  Service Query Object -->
          </findService>

 ServiceQueryObject XML:

To query MOBY Central, you fill out the relevant elements of a Query Ojbect. These include the input and/or output data Classes (by name from the Class ontology), the Service-type (by name from the Service-type ontology), the authority (service provider URI), or any number of keywords that must appear in the service description.

=over 3

=item *  MOBY Central finds all services which match the contents of the Query Object.

=item *  All elements are optional, however at least one must be present.

=item *  All elements present are considered as increasingly limiting on the search (i.e. "AND").

=item *  keywords are:

=over 3

=item * comma-delimited

=item * sentence-fragments are enclosed in double-quotes

=item * wildcard "*" is allowed in combination with keyword fragments and or sentence fragments (lone "*" is meaningless and ignored)

=item * multiple keywords are considered joined by "AND".

=back

=back

In addition to the search parameters, there are two "flags" that can be set in the Query object:

=over 3

=item *  expandServices: this flag will cause MOBY Central to traverse the Service ontology and discover services that are child types (more specific) than the Service-type you requested

e.g. you might request "alignment", and it would discover services such as "Blast", "Smith Waterman", "Needleman Wunsch"

=item *  expandObjects: this flag will cause MOBY Central to traverse the Class ontology to find services that operate not only on the Object Class you are querying, but also any parent types or sub-objects of that Object Class.

e.g. if you request services that work on AnnotatedSequence Objects this flag will also return services that work on Sequence objects, since AnnotatedSequence objects inherit from Sequence objects

=back

The Query object structure is as follows:

 <inputObjects>
   <Input>
      <!-- one or more Simple or Collection Primary articles -->
   </Input>
 </inputObjects>
 <outputObjects>
    <Output>
       <!-- one or more Simple or Collection Primary articles -->
    </Output>
 </outputObjects>
 <authoritative>1</authoritative>
 <Category>moby</Category>
 <serviceType>ServiceTypeTerm</serviceType>
 <serviceName>ServiceName</serviceName>
 <authURI>http://desired.service.provider</authURI>;
 <signatureURL>http://location.of.document/signature.rdf</signatureURL>
 <expandObjects>1|0</expandObjects> 
 <expandServices>1|0</expandServices>
 <keywords>
 <keyword>something</keyword>
    ....
    ....
 </keywords>


 outputXML

 <Services>
  <Service authURI="authority.URI.here" serviceName="MyService" lsid="urn:lsid:authority.uri:serviceinstance:id">
	<serviceType lsid='urn:...'>Service_Ontology_Term</serviceType>
	<Protocol>moby</Protocol> <!-- or 'cgi' or 'soap' -->
	<authoritative>1</authoritative>
	<contactEmail>your@email.address</contactEmail>
	<URL>http://endpoint.of.service</URL>
	<Input>
		 <!-- one or more Simple and/or Collection Primary articles -->
	</Input>
	<Output>
		 <!-- one or more Simple and/or Collection Primary articles --> 
	</Output>
	<secondaryArticles>
		 <!-- one or more Secondary articles -->
	</secondaryArticles>
	<Description><![CDATA[free text description here]]></Description>
  </Service>
  ...  <!--  one or more Service blocks may be returned -->
  ...
  ...
</Services>


=cut

sub findService {
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );

	my ( $pkg, $payload ) = @_;
	$debug && &_LOG("\nLOOKING FOR SERVICES\n");
	my %findme = &_findServicePayload($payload);
	$debug && &_LOG(
		"'serviceType' => $findme{serviceType},
			'authURI' => $findme{authURI},
			'servicename' => $findme{servicename},
			'expandObjects' => $findme{expandObjects},
			'expandServices' => $findme{expandServices},
			'authoritative' => $findme{authoritative},
			'category' => $findme{category},
			'signatureurl' => $findme{signatureURL},
			'keywords' => $findme{keywords},
			"
	);
	my %valid_service_ids;
	my $criterion_count = 0;

# we want to avoid joins, since they slow things down, so...
# the logic is that we keep a hash of valid id's
# and the number of times they are discovered
# we also count the number of criterion
# we only want the service_id's that appear as many times as the criterion we have
# since they will have matched every criterion.

	if ( $findme{authoritative} ) {
		++$criterion_count;
		$debug
		  && _LOG(
			"authoritative added; criterion count is now $criterion_count\n");
		my $ids = _extract_ids($adaptor->query_service_instance(authoritative => $findme{authoritative}));
		
		
		
		###  MARK - we need to extract ids at each step...
		
		
		
		unless ( scalar @{$ids} ) {
			return &_serviceListResponse(undef );
		}
		$debug
		  && _LOG( "services " . ( join ',', @{$ids} ) . " incrememted\n" );
		foreach ( @{$ids} ) {
			$debug && &_LOG("found service_instance_id $_\n");
			++$valid_service_ids{$_};    # increment that particular id's count by one
		}
	}
	if ( $findme{serviceType} ) {  # must have something more than empty content
		my $OS = MOBY::OntologyServer->new( ontology => 'service' );
		$findme{serviceType} =~ s/^moby\://;
		my ( $exists, $message, $URI ) =
		  $OS->serviceExists( term => $findme{serviceType} );
		unless ($exists) {
			return &_serviceListResponse(undef );
		}
		++$criterion_count;
		$debug
		  && _LOG(
			"serviceType added; criterion count is now $criterion_count\n");
		my $children_string = "'$URI',";
		if ( $findme{'expandServices'} ) {
			$debug && _LOG("Expanding Services\n");
			my $OS = MOBY::OntologyServer->new( ontology => 'service' );
			my %relationships = %{ $OS->traverseDAG( $URI, "leaves" ) };
			my (@children) =
			  @{ $relationships{'urn:lsid:biomoby.org:servicerelation:isa'} };
			$children_string .= ( join ',', map { "\'$_\'" } @children );
			#*******FIX this isn't very perlish... sending a comma-delimited string to a subroutine instead of an array
			# need to change that one day soon!
		}
		$children_string =~ s/\,$//;
		my $ids = _extract_ids($adaptor->match_service_type_uri(service_type_uri => $children_string));
		
		$debug
		  && _LOG( "services " . ( join ',', @{$ids} ) . " incrememted\n" );
		foreach ( @{$ids} ) {
			$debug && &_LOG("found service_instance_id $_\n");
			++$valid_service_ids{$_};    # increment that particular id's count by one
		}
	}
	if ( $findme{authURI} ) {
		++$criterion_count;
		$debug
		  && _LOG("authURI added; criterion count is now $criterion_count\n");
		my $ids = _extract_ids($adaptor->query_service_instance(authority_uri => $findme{'authURI'}));

		unless ( scalar @{$ids} ) {
			return &_serviceListResponse(undef );
		}
		$debug
		  && _LOG( "services " . ( join ',', @{$ids} ) . " incrememted\n" );
		foreach ( @{$ids} ) {
			$debug && &_LOG("found service_instance_id $_\n");
			++$valid_service_ids{$_};    # increment that particular id's count by one
		}
	}
	if ( $findme{signatureurl} ) {
		++$criterion_count;
		$debug
		  && _LOG("sigurl added; criterion count is now $criterion_count\n");
		my $ids = _extract_ids($adaptor->query_service_instance(signatureURL => $findme{'signatureurl'}));

		unless ( scalar @{$ids} ) {
			return &_serviceListResponse(undef );
		}
		$debug
		  && _LOG( "services " . ( join ',', @{$ids} ) . " incrememted\n" );
		foreach ( @{$ids} ) {
			$debug && &_LOG("found service_instance_id $_\n");
			++$valid_service_ids{$_};    # increment that particular id's count by one
		}
	}
	if ( $findme{servicename} ) {
		++$criterion_count;
		$debug
		  && _LOG(
			"servicename added; criterion count is now $criterion_count\n");

		my $ids = _extract_ids($adaptor->query_service_instance(servicename => $findme{servicename}));

		unless ( scalar @{$ids} ) {
			return &_serviceListResponse( undef );
		}
		$debug
		  && _LOG( "services " . ( join ',', @{$ids} ) . " incrememted\n" );
		foreach ( @{$ids} ) {
			$debug && &_LOG("found service_instance_id $_\n");
			++$valid_service_ids{$_};    # increment that particular id's count by one
		}
	}
	
	if ( $findme{category} ) {
		++$criterion_count;
		$debug
		  && _LOG("category added; criterion count is now $criterion_count\n");

		my $ids = _extract_ids($adaptor->query_service_instance(category => lc( $findme{category}) ));
	
		unless ( scalar @{$ids} ) {
			return &_serviceListResponse( undef );
		}
		$debug
		  && _LOG( "services " . ( join ',', @{$ids} ) . " incrememted\n" );
		foreach ( @{$ids} ) {
			$debug && &_LOG("found service_instance_id $_\n");
			++$valid_service_ids{$_};    # increment that particular id's count by one
		}
	}
	if ( $findme{keywords} && ( scalar @{ $findme{keywords} } ) ) {
		++$criterion_count;
		$debug
		  && _LOG("Keywords added; criterion count is now $criterion_count\n");
		  
		my ($ids) = $adaptor->check_keywords(keywords => \@{$findme{keywords}});
		$ids = _extract_ids($ids);  # this is the hash-list that comes back from do_query
		  
		unless ( scalar @{$ids} ) {
			return &_serviceListResponse( undef );
		}
		$debug
		  && _LOG( "services " . ( join ',', @{$ids} ) . " incrememted\n" );
		foreach ( @{$ids} ) {
			$debug && &_LOG("found service_instance_id $_\n");
			++$valid_service_ids{$_};    # increment that particular id's count by one
		}
	}
	if ( $findme{inputObjects} && ( scalar @{ $findme{inputObjects} } ) ) {
		++$criterion_count;
		$debug
		  && _LOG(
			"inputObject added; criterion count is now $criterion_count\n");
		my $obj = ( shift @{ $findme{inputObjects} } );
		my @si_ids;
		@si_ids =
		  &_searchForServicesWithArticle( "input", $obj,$findme{'expandObjects'}, '' )
		  if defined $obj;
		$debug
		  && _LOG("Initial Search For Services with INPUT Article found @si_ids\n");
		my %instances;

		# we need to do a join, without doing a join...
		if ( scalar @si_ids ) {
			map { $instances{$_} = 1 }
			  @si_ids;    # get an id of the good services from the first object
			while ( my $obj = shift( @{ $findme{inputObjects} } ) )
			{             # iterate through the rest of the objects
				next unless $obj;
				$debug
				  && _LOG( "FIRST: ", "input", $obj,
					$findme{'expandObjects'}, '' );
				my @new_ids =
				  &_searchForServicesWithArticle("input", $obj,$findme{'expandObjects'}, '' );    # get their service ids
				$debug
				  && _LOG("Subsequent Search For Services with INPUT Article found @new_ids\n");
				my @good_ids;
				my %good_ids;
				foreach my $id (@new_ids)
				{ # check the new id set against the set we know is already valid
					next unless defined $id;
					if ( $instances{$id} ) {
						push @good_ids, $id;
					}    # if they are in common, then that id is still good
				}
				map { $good_ids{$_} = 1 }
				  @good_ids;    # make a hash of the new good id's
				%instances = %good_ids
				  ;   # and replace the original list with this more limited one
			}
		}

		# now %instances contains only valid ID numbers
		$debug
		  && _LOG( "Final results incremented of search for INPUT: "
			  . ( join ',', ( keys %instances ) )
			  . "\n" );
		foreach ( keys %instances ) {
			$debug && &_LOG("found id $_\n");
			++$valid_service_ids{$_};
		}
	}
	if ( $findme{outputObjects} && ( scalar @{ $findme{outputObjects} } ) ) {
		++$criterion_count;
		$debug
		  && _LOG(
			"outputObject added; criterion count is now $criterion_count\n");
		my $obj = ( shift @{ $findme{outputObjects} } );
		my @si_ids;
		@si_ids = &_searchForServicesWithArticle("output", $obj, '' )if defined $obj;
		$debug
		  && _LOG(
			"Initial Search For Services with OUTPUT Article found @si_ids\n");
		my %instances;

		# we need to do a join, without doing a join...
		if ( scalar @si_ids ) {
			map { $instances{$_} = 1 }
			  @si_ids;    # get an id of the good services from the first object
			while ( my $obj = shift( @{ $findme{outputObjects} } ) )
			{             # iterate through the rest of the objects
				next unless $obj;
				my @new_ids =
				  &_searchForServicesWithArticle("output", $obj, '' )
				  ;       # get their service ids
				$debug
				  && _LOG("Subsequent Search For Services with OUTPUT Article found @new_ids\n"
				  );
				my @good_ids;
				my %good_ids;
				foreach my $id (@new_ids)
				{ # check the new id set against the set we know is already valid
					next unless defined $id;
					if ( $instances{$id} ) {
						push @good_ids, $id;
					}    # if they are in common, then that id is still good
				}
				map { $good_ids{$_} = 1 }
				  @good_ids;    # make a hash of the new good id's
				%instances = %good_ids
				  ;   # and replace the original list with this more limited one
			}
		}

		# now %instances contains only valid ID numbers
		$debug
		  && _LOG( "Final results incremented of search for OUTPUT: "
			  . ( join ',', ( keys %instances ) )
			  . "\n" );
		foreach ( keys %instances ) {
			$debug && &_LOG("found id $_\n");
			++$valid_service_ids{$_};
		}
	}
	unless ($criterion_count){  # in case all criterion are null, find everything
		++$criterion_count;  # this is an AWFUL hack.  We need to add a criterion in order for teh next while loop to be successful in finding each of these services.  This is really really terrible, but it works until someone tries to "fix" something...
		
		my $ids = _extract_ids($adaptor->query_service_instance(category => "IS NOT NULL" ));
		unless ( scalar @{$ids} ) {
			return &_serviceListResponse( undef );
		}
		foreach ( @{$ids} ) {
			$debug && &_LOG("found service_instance_id $_\n");
			++$valid_service_ids{$_};    # increment that particular id's count by one
		}		
	}
	my @final;
	while ( my ( $id, $freq ) = each %valid_service_ids ) {
		$debug
		  && _LOG(
			"TALLY IS ID: $id  FREQ:$freq\n CRITERION COUNT $criterion_count\n"
		  );
		next
		  unless $freq ==
		  $criterion_count;    # has to have matched every criterion
		push @final, $id;
	}
	return &_serviceListResponse(@final );
}

sub _extract_ids {
	my ($linehash) = @_;
	# ths data comes from the do_query of the mysql call
	#  -->  [{...}]
	my @lines = @$linehash;
	return [] unless scalar(@lines);
	my @ids;
	foreach (@lines){
		my $id = $_->{service_instance_id};
		push @ids, $id;
	}
	return \@ids
}

sub _how_exit {
    my ($exit) = @_;
    my ($status) = $exit >> 8;
    my ($signal) = $exit & 255;
    return $status unless $signal;
    return $signal;
}

#Eddie - converted
sub _searchForServicesWithArticle {
	my ($inout, $node, $expand, $coll ) = @_;
	return ()
	  unless $node->nodeType ==
	  ELEMENT_NODE;  # this will erase all current successful service instances!
	$debug
	  && _LOG( "searchServWthArticle ", $inout, $node, $expand, $coll );

	# this element node may be a Simple or a Collection object
	my $simp_coll = $node->nodeName;
	$debug && &_LOG("TAGNAME in _searchForArticle is $simp_coll");
	my @valid_ids;
	if ( $simp_coll eq "Collection" ) {
		@valid_ids = &_searchForCollection( $node, $expand, $inout );
	}
	elsif ( $simp_coll eq "Simple" ) {
		@valid_ids = &_searchForSimple( $node, $expand, $inout );
	}
	return @valid_ids;
}

sub _searchForSimple {
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );

	# returns list of service_instance ID's
	# that match this simple
	my ( $node, $expand, $inout ) = @_;
	$debug && _LOG( $node, $expand, $inout );
	my ( $objectURI, $namespaceURIs ) =
	  &_extractObjectTypesAndNamespaces($node);  # (objectType, [ns1, ns2, ns3])
	unless ($objectURI) { return () }
	my $ancestor_string = "'$objectURI',";
	if ($expand) {
		$debug && _LOG("Expanding Objects\n");
		my $OS = MOBY::OntologyServer->new( ontology => 'object' );
		my %relationships = %{ $OS->traverseDAG( $objectURI, "root" ) };
		my (@ancestors) =
		  @{ $relationships{'urn:lsid:biomoby.org:objectrelation:isa'} };
		$ancestor_string .= ( join ',', map { "\'$_\'" } @ancestors );
	}
	$ancestor_string =~ s/\,$//;
	
	my $result = $adaptor->find_by_simple(inout => $inout,
					     ancestor_string => $ancestor_string,
					     namespaceURIs => $namespaceURIs);

	my @valid_services;
	
	foreach my $row (@$result)
	{    
	    # get the service instance ID and the namespaces that matched
	    my $id = $row->{service_instance_id};
	    my $nss = $row->{namespace_type_uris};
		if ( $nss && scalar @{$namespaceURIs} )
		{    # if this service cares about namespaces at all,
			    # and if namespaces were specified in the query,
			    # then validate the discovered service against this list
			my @ns = split ",", $nss
			  ; # because of the database structure we have to re-test for *identity*, not just like%% similarity
			my %nshash = map { ( $_, 1 ) } @ns, @{ $namespaceURIs
			  }; #we're going to test identity by building a hash of namespaces as keys
			if (
				scalar( keys %nshash ) <
				scalar(@ns) + scalar( @{$namespaceURIs} ) )
			{ # if the number of keys is less than the sum of the number of keys goign into the hash, then one of them was identical
				push @valid_services,
				  $id;    # and therefore it really is a match, and is valid
			}
		}
		else {    # if no namespace was specified, then all of them are valid
			push @valid_services, $id;
		}
	}
	$debug
	  && _LOG( "Resulting IDs were " . ( join ',', @valid_services ) . "\n" );
	return @valid_services;
}

#Eddie - converted
sub _searchForCollection {
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );

	my ( $node, $expand, $inout ) =
	  @_;         # $node in this case is a Collection object

	# luckily, we can return a redundant list of service id's and
	# this will be cleaned up in the caller
	my @validservices;
	foreach my $simple ( $node->childNodes() ) {
		next unless ( $simple->nodeType == ELEMENT_NODE );
		next unless ( $simple->nodeName =~ /simple/i );
		my ( $objectURI, $namespaceURIs ) =
		  &_extractObjectTypesAndNamespaces($simple);

		my $result = $adaptor->find_by_collection(inout => $inout,
							 objectURI => $objectURI,
							 namespaceURIs => $namespaceURIs);

		foreach my $row (@$result )
		{    # get the service instance ID and the namespaces that matched
		    my $id = $row->{service_instance_id};
		    my $nss = $row->{namespace_type_uris};
			if ( $nss && scalar @{$namespaceURIs} )
			{    # if this service cares about namespaces at all,
				    # and if namespaces were specified in the query,
				    # then validate the discovered service against this list
				my @ns = split ",", $nss
				  ; # because of the database structure we have to re-test for *identity*, not just like%% similarity
				my %nshash = map { ( $_, 1 ) } @ns, @{ $namespaceURIs
				  }; #we're going to test identity by building a hash of namespaces as keys
				if (
					scalar( keys %nshash ) <
					scalar(@ns) + scalar( @{$namespaceURIs} ) )
				{ # if the number of keys is less than the sum of the number of keys goign into the hash, then one of them was identical
					push @validservices,
					  $id;    # and therefore it really is a match, and is valid
				}
			}
			else {   # if no namespace was specified, then all of them are valid
				push @validservices, $id;
			}
		}
	}
	return @validservices;
}

#Eddie - converted
sub _findServicePayload {
	my ($payload) = @_;
	my $Parser    = XML::LibXML->new();
	my $doc       = $Parser->parse_string($payload);
	my $Object    = $doc->getDocumentElement();
	my $obj       = $Object->nodeName;
	return undef unless ( $obj eq 'findService' );
	my $serviceType = &_nodeTextContent( $Object, "serviceType" );
	$serviceType && ( $serviceType =~ s/\s+//g );
	my $servicename = &_nodeTextContent( $Object, "serviceName" );
	$servicename && ( $servicename =~ s/\s+//g );
	my $authoritative = &_nodeTextContent( $Object, "authoritative" );
	$authoritative && ( $authoritative =~ s/\s+//g );
	my $Category = &_nodeTextContent( $Object, "Category" );
	$Category && ( $Category =~ s/\s+//g );
	my $AuthURI = &_nodeTextContent( $Object, "authURI" );
	$AuthURI && ( $AuthURI =~ s/\s+//g );
	
	# add signatureURL to the list of things to find
	my $signatureURL = &_nodeTextContent( $Object, "signatureURL" );
	$signatureURL && ( $signatureURL =~ s/\s+//g );
	
	my $expandObjects = &_nodeTextContent( $Object, "expandObjects" );
	$expandObjects && ( $expandObjects =~ s/\s+//g );
	my $expandServices = &_nodeTextContent( $Object, "expandServices" );
	$expandServices && ( $expandServices =~ s/\s+//g );
	my @kw      = &_nodeArrayContent( $Object, "keywords" );
	my $INPUTS  = &_nodeRawContent( $Object,   "Input" );    # returns array ref
	my $OUTPUTS = &_nodeRawContent( $Object,   "Output" );   # returns array ref
	return (
		'serviceType'    => $serviceType,
		'authURI'        => $AuthURI,
		'signatureurl'   => $signatureURL,
		'servicename'    => $servicename,
		'expandObjects'  => $expandObjects,
		'expandServices' => $expandServices,
		'authoritative'  => $authoritative,
		'category'       => $Category,
		'inputObjects'   => $INPUTS,
		'outputObjects'  => $OUTPUTS,
		'keywords'       => \@kw
	);
}

#Eddie - converted
sub _extractObjectTypesAndNamespaces {

# takes a SINGLE simple article and return regular list ($objectURI, [nsURI1, nsURI2, nsURI3])
	my ($DOM) = @_;
	$debug
	  && &_LOG(
"\n\n_extractObjectTypesAndNamespaces\nExtracting object types from \n$DOM	\n\n"
	  );
	unless ( ref($DOM) =~ /^XML/ ) {
		my $Parser = XML::LibXML->new();
		my $doc    = $Parser->parse_string($DOM);
		$DOM = $doc->getDocumentElement();
	}
	my $x = $DOM->getElementsByTagName("objectType");
	my $objectname;
	my @child = $x->get_node(1)->childNodes;
	foreach (@child) {
		$debug && &_LOG( getNodeTypeName($_), "\t", $_->toString, "\n" );
		next unless ( $_->nodeType == TEXT_NODE );
		my $name = $_->toString;
		chomp $name;
		$objectname = $name;
	}
	$objectname =~ s/^moby\://
	  ; # damn XML DOM can't deal with namespaces... so get rid of it if it exists, though this is going to limit us to only MOBY objects again :-(
	my $OS = MOBY::OntologyServer->new( ontology => 'object' );
	my ( $exists, $message, $objectURI ) =
	  $OS->objectExists( term => $objectname );
	return ( undef, [] ) unless $objectURI;
	my $ns = $DOM->getElementsByTagName("Namespace");
	my @namespaces;
	my $nonamespaces = $ns->size();
	$OS = MOBY::OntologyServer->new( ontology => 'namespace' );

	for ( my $n = 1 ; $n <= $nonamespaces ; ++$n ) {
		my @child = $ns->get_node($n)->childNodes;
		foreach (@child) {
			$debug && &_LOG( getNodeTypeName($_), "\t", $_->toString, "\n" );
			next unless ( $_->nodeType == TEXT_NODE );
			my $name = $_->toString;
			chomp $name;
			my ( $success, $message, $URI ) =
			  $OS->namespaceExists( term => $name );
			$URI
			  ? ( push @namespaces, $URI )
			  : ( push @namespaces, "__MOBY__INVALID__NAMESPACE__" );
		}
	}
	return ( $objectURI, \@namespaces );
}

=head2 retrieveService

 Title     :	retrieveService
 Usage     :	$WSDL = $MOBY->retrieveService($inputXML)
 Function  :	get the WSDL descriptions for services with this service name
 Returns   :	XML (see below)
 Comment   :    the WSDL that you get back is invalid w.r.t. the object structure
	            It will always be so.
	            It should be used only to create stubs for the connection to the service.
 inputXML  :
	<retrieveService>
         <Service authURI="authority.uri.here" serviceName="myServ"/>
	<retrieveService>

 outputXML (by category):

     moby: <Service lsid='urn:lsid:...'><![CDATA[WSDL document here]]</Service>


=cut

sub retrieveService {
	my ( $pkg, $payload ) = @_;
	my ( $AuthURI, $serviceName, $InputXML, $OutputXML, $SecondaryXML ) =
	  &_retrieveServicePayload($payload);
	unless ( $AuthURI && $serviceName ) { return "<Services/>" }
	my $SI = MOBY::service_instance->new(
		authority_uri => $AuthURI,
		servicename   => $serviceName
	);
	my $servlsid = $SI->lsid;
	my $wsdls;
	return "<Services/>" unless ($SI);
	&listener(authority => $AuthURI, servicename => $serviceName);  # log the requst for research purposes	
	my $wsdl = &_getServiceWSDL( $SI, $InputXML, $OutputXML, $SecondaryXML );
	if ($wsdl) {
		if ( $wsdl =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
			$wsdl = $1;
		}
		$wsdls .= "<Service lsid='$servlsid'><![CDATA[$wsdl]]></Service>\n";
	}
		
	#$debug && &_LOG("WSDL_________________$wsdls\n____________________");
	return $wsdls;
}

#Eddie - converted
sub _retrieveServicePayload {
	my ($payload)   = @_;
	my $Parser      = XML::LibXML->new();
	my $doc         = $Parser->parse_string($payload);
	my $x           = $doc->getElementsByTagName("Service");
	my $authURI     = "";
	my $serviceName = "";
	my $l = $x->size();  # might be a Collection object with multiple simples...
	for ( my $n = 1 ; $n <= $l ; ++$n ) {
		$authURI =
		  $x->get_node($n)->getAttributeNode("authURI")
		  ;              # may or may not have a name
		if ($authURI) { $authURI = $authURI->getValue() }
		$serviceName =
		  $x->get_node($n)->getAttributeNode("serviceName")
		  ;              # may or may not have a name
		if ($serviceName) { $serviceName = $serviceName->getValue() }
	}
	my $INPUT    = $doc->getElementsByTagName("Input");
	my $InputXML = "";
	if ( $INPUT->get_node(1) ) {
		$InputXML = $INPUT->get_node(1)->toString;
	}
	my $OUTPUT    = $doc->getElementsByTagName("Output");
	my $OutputXML = "";
	if ( $OUTPUT->get_node(1) ) {
		$OutputXML = $OUTPUT->get_node(1)->toString;
	}
	my $SECONDARY    = $doc->getElementsByTagName("Output");
	my $SecondaryXML = "";
	if ( $SECONDARY->get_node(1) ) {
		$SecondaryXML = $SECONDARY->get_node(1)->toString;
	}
	return ( $authURI, $serviceName, $InputXML, $OutputXML, $SecondaryXML );
}

=head2 retrieveResourceURLs

 Title     :    retrieveResourceURLs
 Usage     :    $urls = $MOBY->retrieveResourceURLs
 Function  :    to retrieve the location(s) of the RDF versions of the various
                MOBY-S Ontologies
 Args      :    none
 Returns   :    XML (see below).  The "name" attribute indicates which ontology
                is described by the URL (Service, Object, Namespace, ServiceInstance, Full),
		and the "url" attribute provides a URL that, when called with an
		HTTP GET, will return RDF-XML describing that ontology.
 XML       :
        <resourceURLs>
	    <Resource name="Service" url="http://mobycentral.org/RESOURCES/MOBY-S/Services/>
	    <Resource name="Object" url="..."/>
	    <Resource name="Namespace" url="...X..."/>
	    <Resource name="Namespace" url="...Y..."/>
	</resourceURLs>

=cut

sub retrieveResourceURLs {

    $CONFIG ||= MOBY::Config->new;    # exported by Config.pm
    my $central = $CONFIG->{mobycentral}->{resourceURL};
    my $service = $CONFIG->{mobyservice}->{resourceURL};
    my $namespace = $CONFIG->{mobynamespace}->{resourceURL};
    my $object = $CONFIG->{mobyobject}->{resourceURL};
    my $all = $CONFIG->{mobycentral}->{allResources};

    my $message ="<resourceURLs>";
    $message .="<Resource name='ServiceInstance' url='$central'/>" if $central;
    $message .="<Resource name='Object' url='$object'/>" if $object;
    $message .="<Resource name='Service' url='$service'/>" if $service;
    $message .="<Resource name='Namespace' url='$namespace'/>" if $namespace;
    $message .="<Resource name='Full' url='$all'/>" if $all;
    $message .="</resourceURLs>";
    return $message;
}
 
 
=head2 retrieveServiceProviders

 Title     :	retrieveServiceProviders
 Usage     :	$uris = $MOBY->retrieveServiceProviders()
 Function  :	get the list of all provider's AuthURI's
 Returns   :	XML (see below)
 Args      :	none
 XML       :
	<serviceProviders>
	   <serviceProvider name="authority.info.here"/>
		...
		...
	</serviceProviders>

=cut

sub retrieveServiceProviders {
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );

	my ($pkg) = @_;

	my $result = $adaptor->get_all_authorities();

	my $providers = "<serviceProviders>\n";
	foreach my $prov (@$result) {
		$providers .= "<serviceProvider name='".($prov->{authority_uri})."'/>\n";
	}
	$providers .= "</serviceProviders>\n";
	return $providers;
}

=head2 retrieveServiceNames

 Title     :	retrieveServiceNames
 Usage     :	$names = $MOBY->retrieveServiceNames()
 Function  :	get a (redundant) list of all registered service names
                (N.B. NOT service types!)
 Returns   :	XML (see below)
 Args      :	none
 XML       :
	<serviceNames>
	   <serviceName name="serviceName" authURI='authority.info.here' lsid = 'urn:lsid...'/>
		...
		...
	</serviceNames>

=cut

sub retrieveServiceNames {
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );

	my ($pkg) = shift;

	my $result = $adaptor->get_service_names();
	my $names = "<serviceNames>\n";
	foreach my  $row (@$result) {
		my $name = $row->{servicename};
		my $auth = $row->{authority_uri};
		my $lsid = $row->{lsid};
		$names .= "<serviceName name='$name' authURI='$auth' lsid='$lsid'/>\n";
	}
	$names .= "</serviceNames>\n";
	return $names;
}

=head2 retrieveServiceTypes

 Title     :	retrieveServiceTypes
 Usage     :	$types = $MOBY->retrieveServiceTypes()
 Function  :	get the list of all registered service types
 Returns   :	XML (see below)
 Args      :	none
 XML       :
	<serviceTypes>
	   <serviceType name="serviceTypeName" lsid="urn:lsid...">
		  <Description><![CDATA[free text description here]]></Description>
		  <contactEmail>your@email.here</contactEmail>
		  <authURI>authority.uri.here</authURI>
		  <ISA lsid="urn:lsid...">parentTypeName</ISA>  <!-- both empty for root Service! -->
	   </serviceType>
		...
		...
	</serviceTypes>

=cut

sub retrieveServiceTypes {
	my ($pkg) = @_;
	my $OS    = MOBY::OntologyServer->new( ontology => 'service' );
	my %types = %{ $OS->retrieveAllServiceTypes() };
	my $types = "<serviceTypes>\n";
	while ( my ( $serv, $descr ) = each %types ) { #UNCOMMENT
		my ($desc, $lsid, $contact, $auth, $isa_type, $isa_lsid) = @$descr;
		if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
			$desc = $1;
		}
		$isa_type ||="";
		$isa_lsid ||="";
		$types .="<serviceType name='$serv' lsid='$lsid'>
		<Description><![CDATA[$desc]]></Description>
		<contactEmail>$contact</contactEmail>
		<authURI>$auth</authURI>
		<ISA lsid='$isa_lsid'>$isa_type</ISA>
		</serviceType>\n"; #UNCOMMENT
	}
	$types .= "</serviceTypes>\n";
	return $types;
}

=head2 retrieveRelationshipTypes

 Title     :	retrieveRelationshipTypes
 Usage     :	$types = $MOBY->retrieveRelationshipTypes($xml)
 Function  :	get the list of all registered relationship types in the given ontology
 Returns   :	XML (see below)
 Args      :	input XML (ontologies are 'object', 'service', 'namespace', 'relationship')

 Input XML :  <Ontology>OntologyName</Ontology>
 Output XML:
	<relationshipTypes>
	   <relationshipType relationship="ontologyterm" authority="biomoby.org">
		  <Description><![CDATA[free text description here]]></Description>
	   </relationshipType>
		...
		...
	</relationshipTypes>

=cut

#Eddie - converted
sub retrieveRelationshipTypes {
	my ( $pkg, $payload ) = @_;
	my $Parser   = XML::LibXML->new();
	my $doc      = $Parser->parse_string($payload);
	my $ontology = &_nodeTextContent( $doc, "Ontology" );
	my $OS       = MOBY::OntologyServer->new( ontology => 'relationship' );
	my %types    = %{ $OS->getRelationshipTypes( ontology => $ontology ) };
	my $types    = "<relationshipTypes>\n";
	while ( my ( $lsid, $authdesc ) = each %types ) {
		my $name = $authdesc->[0];
		my $auth = $authdesc->[1];
		my $desc = $authdesc->[2];
		if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
			$desc = $1;
		}
		$types .="<relationshipType relationship='$name' authority='$auth' lsid='$lsid'>\n<Description><![CDATA[$desc]]></Description>\n</relationshipType>\n";
	}
	$types .= "</relationshipTypes>\n";
	return $types;
}

=head2 retrieveObjectNames

 Title     :	retrieveObjectNames
 Usage     :	$names = $MOBY->retrieveObjectNames()
 Function  :	get the list of all registered Object types
 Returns   :	XML (see below)
 Args      :	none
 XML       :
	<objectNames>
	   <Object name="objectName" lsid="urn:lsid:...">
		  <Description><![CDATA[free text description here]]></Description>
	   </Object>
		...
		...
	</objectNames>

=cut

sub retrieveObjectNames {
	my ($pkg) = @_;
	my $OS    = MOBY::OntologyServer->new( ontology => 'object' );
	my %types = %{ $OS->retrieveAllObjectTypes() };
	my $obj   = "<objectNames>\n";
	while ( my ( $name, $descr ) = each %types ) {
		my ($desc, $lsid) = @$descr;
		if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
			$desc = $1;
		}
		$obj .="<Object name='$name' lsid='$lsid'>\n<Description><![CDATA[$desc]]></Description>\n</Object>\n";
	}
	$obj .= "</objectNames>\n";
	return $obj;
}

=head2 retrieveObjectDefinition

 Title     :	retrieveObjectDefinition
 Usage     :	$registerObjectXML = $MOBY->retrieveObjectDefinition($inputXML)
 Function  :	get the full description of an object, as registered
 Returns   :	see input XML for registerObjectClass
 Input XML :
         <retrieveObjectDefinition>
			 <obqjectType>ExistingObjectClassname</objectType>
		 </retrieveObjectDefinition>

 Ouptut XML :
        <retrieveObjectDefinition>
            <objectType lsid="urn:lsid:...">NewObjectType</objectType>
            <Description><![CDATA[
                    human readable description
                    of data type]]>
            </Description>
            <Relationship relationshipType="urn:lsid...">
               <objectType articleName="SomeName" lsid="urn:lsid...">ExistingObjectType</objectType>
            </Relationship>
            ...
            ...
            <authURI>owner.URI.here</authURI>
            <contactEmail>owner@their.address.com</contactEmail>
        </retrieveObjectDefinition>


=cut

#Eddie - converted
sub retrieveObjectDefinition {
	my ( $pkg, $payload ) = @_;
	my $Parser = XML::LibXML->new();
	my $doc    = $Parser->parse_string($payload);
	my $term   = &_nodeTextContent( $doc, "objectType" );
	return "<retrieveObjectDefinition/>" unless $term;
	my $OS = MOBY::OntologyServer->new( ontology => 'object' );
	my $def =
	  $OS->retrieveObject( node => $term )
	  ; # will return undef if this term does not exist, and does not look like an LSID
	return "<retrieveObjectDefinition/>" unless $def;
	my %def = %{ $OS->retrieveObject( type => $term ) };

	if ( $def{description} =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
		$def{description} = $1;
	}

	my $response;
	$response = "<retrieveObjectDefinition>
	<objectType lsid='$def{objectLSID}'>$def{objectType}</objectType>
	<Description><![CDATA[$def{description}]]></Description>
	<authURI>$def{authURI}</authURI>
	<contactEmail>$def{contactEmail}</contactEmail>\n";
	my %relationships = %{ $def{Relationships} };
	
    while ( my ( $rel, $objdefs ) = each %relationships ) {
        $response .= "<Relationship relationshipType='$rel'>\n";
		foreach my $def ( @{$objdefs} ) {
			my ( $lsid, $articlename,$type, $def, $auth, $contac ) = @{$def};
			$articlename = "" unless defined $articlename;
			$response .=
			  "<objectType articleName='$articlename' lsid='$lsid'>$type</objectType>\n";
		}
		$response .= "</Relationship>\n";
	}
	$response .= "</retrieveObjectDefinition>\n";
	return $response;
}

=head2 retrieveNamespaces

 Title     :	retrieveNamespaces
 Usage     :	$ns = $MOBY->retrieveNamespaces()
 Function  :	get the list of all registered Object types
 Returns   :	XML (see below)
 Args      :	none
 XML       :
	<Namespaces>
	   <Namespace name="namespace" lsid="urn:lsid:...">
		  <Description><![CDATA[free text description here]]></Description>
		  <contactEmail>email@address.here</contactEmail>
		  <authURI>authority.uri.here</authURI>
	   </Namespace>
		...
		...
	</Namespaces>

=cut

sub retrieveNamespaces {
	my ($pkg) = @_;
	my $OS    = MOBY::OntologyServer->new( ontology => 'namespace' );
	my %types = %{ $OS->retrieveAllNamespaceTypes() };
	my $ns    = "<Namespaces>\n";
	while ( my ( $namespace, $descr ) = each %types ) {
		my ($desc, $lsid, $auth, $contact) = @$descr;
		if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
			$desc = $1;
		}
#		$ns .= "<Namespace name='$namespace' lsid='$lsid'>\n<Description><![CDATA[$desc]]></Description>\n</Namespace>\n"; #COMMENT/REMOVE
		$ns .= "<Namespace name='$namespace' lsid='$lsid'>\n<Description><![CDATA[$desc]]></Description>\n<contactEmail>$contact</contactEmail>\n<authURI>$auth</authURI>\n</Namespace>\n";#UNCOMMENT
	}
	$ns .= "</Namespaces>";
	return $ns;
}

=head2 retrieveObject

 NOT YET IMPLEMENTED
 Title     :	retrieveObject
 Usage     :	$objects = $MOBY->retrieveObject($inputXML)
 Function  :	get the object xsd
 Returns   :	XML (see below)
 Args      :	$name - object name (from ontology) or "all" to get all objects

 inputXML  :
	<retrieveObject>
	 <objectType>ObjectType | all</objectType>
	</retrieveObject>

 outputXML       :
	<Objects>
	   <Object name="namespace">
		  <Schema><XSD schema fragment here></Schema>
	   </Object>
		...
		...
	</Objects>

=cut

sub retrieveObject {
	my ( $pkg, $payload ) = @_;
	my $response = "<Objects>\n";
	$response .= "<NOT_YET_IMPLEMENTED/>\n";
	$response .= "</Objects>\n";
	return $response;
}

#Eddie - converted
sub _retrieveObjectPayload {
	my ($payload) = @_;
	my $Parser    = XML::LibXML->new();
	my $doc       = $Parser->parse_string($payload);
	my $Object    = $doc->getDocumentElement();
	my $obj       = $Object->nodeName;
	return undef unless ( $obj eq 'retrieveObject' );
	my $type = &_nodeTextContent( $Object, "objectType" );
	return ($type);
}

=head2 Relationships

 Title     :	Relationships
 Usage     :	$ns = $MOBY->Relationships()
 Function  :	get the fist level of relationships for the given term
 Returns   :	output XML (see below)
 Args      :	Input XML (see below).  
 Notes     :    expandRelationships behaviour
                   - for ISA relationships means traverse to root/leaves
		   - for HAS and HASA means traverse ISA to root/leaves and
		     for each node in the ISA hierarchy return the HAS/HASA
                     relationship partners, where 'root' matches container objects
                     and 'leaves' matches contained objects.
                     Example: suppose a relationship "objA HAS objB",
                     a) if query is objectType=>objA, direction=>'root', relationship=>'HAS',
                        then objB is in result set
                     b) if query is objectType=>objB, direction=>'leaves', relationship=>'HAS',
                        then objA is in result set

 input XML :
	<Relationships>
	   <objectType>$term</objectType>
	   <expandRelationship>1|0</expandRelationship>
           <direction>root|leaves</direction>
	   <relationshipType>$relationship_term</relationshipType>
	   ... more relationship types
	   ...
	</Relationships>
 OR
	<Relationships>
	   <serviceType>$term</serviceType>
	   <expandRelationship>1|0</expandRelationship>
           <direction>root|leaves</direction>
	   <relationshipType>$relationship_term</relationshipType>
	   ... more relationship types
	   ...
	</Relationships>


 outputXML :
  <Relationships>
    <Relationship relationshipType="RelationshipOntologyTerm">
       <objectType lsid='urn:lsid...'>ExistingObjectType</objectType>
       <objectType lsid='urn:lsid...'>ExistingObjectType</objectType>
    </Relationship>
    <Relationship relationshipType="AnotherRelationshipTerm">
        ....
    </Relationship>
  </Relationships>

 OR

  <Relationships>    
    <Relationship relationshipType="RelationshipOntologyTerm">
       <serviceType lsid='urn:lsid...'>ExistingServiceType</serviceType>
       <serviceType lsid='urn:lsid...'>ExistingServiceType</serviceType>
    </Relationship>
    <Relationship relationshipType="AnotherRelationshipTerm">
        ....
    </Relationship>
  </Relationships>


=cut

sub Relationships {
	my ( $pkg, $payload ) = @_;
	my $ontology;
	my $Parser              = XML::LibXML->new();
	my $doc                 = $Parser->parse_string($payload);
	my $x                   = $doc->getElementsByTagName("relationshipType");
	my $l                   = $x->size();
	my $exp                 = $doc->getElementsByTagName("expandRelationship");
	my $expl                = $exp->size();
	my $expand_relationship = &_nodeTextContent( $doc, 'expandRelationship' );
	$expand_relationship =~ s/\s//g;
	$expand_relationship ||= 0;

	
	# find out direction:
	my $direction = &_nodeTextContent( $doc, "direction" );
	$direction = 'root' unless $direction; # make root default to stay compatible
	# it has to be either 'leaves' or 'root'
	$direction = ($direction eq 'leaves') ? 'leaves' : 'root';
	
	
	my %reltypes;
	my $relationship;


	
	for ( my $n = 1 ; $n <= $l ; ++$n ) {
		my @child = $x->get_node($n)->childNodes;
		foreach (@child) {
			next unless ( $_->nodeType == TEXT_NODE );
			my $name .= $_->toString;
			$name =~ s/\s//g;
			$reltypes{$name} = 1; # make a hash of desired relationship types $reltypes{isa}=1; $reltypes{hasa}=1, etc
		}
	}

	# are we working on a service or an object?
	my $term = &_nodeTextContent( $doc, "objectType" );
	$ontology = "object" if $term; # pick up the ontology "object" that we used here if we got an object term
	$term ||= &_nodeTextContent( $doc, "serviceType" );    # if we didn't get anything using objectType try serviceType
	return undef unless $term;    # and bail out if we didn't succeed
	$ontology ||= "service"; # if we have now succeeded and haven't already taken the ontology then it must be the service ontology
	$debug && &_LOG("Ontology was $ontology; Term was $term\n");

	## replace $reltypes{isa}=1  with $reltypes{urn:lsid:...:isa}= 1
	#foreach ( keys %reltypes ) {    # for each of our desired types
	#	my $rellsid = $OSrel->getRelationshipURI( $ontology, $_ );    # get the LSID
	#	delete $reltypes{$_};    # remove the non-LSID version from the hash
	#	$reltypes{$rellsid} = 1; # set the LSID as valid
	#}


	my $response = "<Relationships>\n";  # outermost tag containing individual relationship blocks

	my %relationships_found;  # the final list of discovered relationships
	my $OS = MOBY::OntologyServer->new( ontology => $ontology );

	foreach $relationship(keys %reltypes){  # we are going to concatenate the hashes here; keys are "ISA", "HASA", etc
		%relationships_found =(%relationships_found, %{ $OS->Relationships(     # concatentate (%a,%b) --> %rels = $rels{relationship_lsid} = [lsid, lsid,lsid]
						 term => $term,
						 expand => $expand_relationship,
						 relationship => $relationship,
						 direction => $direction,
						 )});    # %relationships_found = $rels{relationship_lsid} = [lsid, lsid,lsid]
	}
	
	
	my $OSrel    = MOBY::OntologyServer->new( ontology => 'relationship' );
	# now for each of the relationship types that we were returned
	foreach my $this_rel( keys %reltypes ) { # keys are "isa" or "hasa"...
		my $rellsid = $OSrel->getRelationshipURI( $ontology, $this_rel );  # convert ISA to urn:lsid...:isa
		next unless $rellsid;
		next unless $relationships_found{$rellsid};  # e.g. $rels{urn:lsid...isa}=["urn:lsid...:Object","urn:lsid...:VirtSeq"]
		my @lsids_articles = @{$relationships_found{$rellsid}};
		next unless scalar @lsids_articles;

		$response .= "<Relationship relationshipType='$this_rel' lsid='$rellsid'>\n";
		foreach my $lsid_article ( @lsids_articles ) {
			my $lsid = $lsid_article->{lsid};
			my $term = $lsid_article->{term};
			if ($this_rel =~ /isa/i){
				$response .= "<${ontology}Type lsid='$lsid' ";
				$response .= ">$term</${ontology}Type>\n";
			} else {
				my @articleNames = keys %{$lsid_article->{'articleName'}};
				foreach my $articleName(@articleNames){
					$response .= "<${ontology}Type lsid='$lsid' ";
					$response .= "articleName='$articleName'" if $articleName;  # wont be there for Service type ontology
					$response .= ">$term</${ontology}Type>\n";
				}
			}
		}
		$response .= "</Relationship>\n";
	}

	$response .= "</Relationships>\n";
	return $response;
}

=head2 DUMP_MySQL

 Title     :	DUMP_MySQL
 Usage     :	$SQL = $MOBY->DUMP_MySQL; ($central,$object,$service,$namespace,$relat) = @{$SQL};
 Function  :	return a mysql dump of each of the current MOBY Central databases
 Returns   :	an array of SQL strings that can be used to recreate the database locally
 Args      :	none

=cut

sub DUMP_MySQL {
	my ($pkg)      = @_;
	my $config     = MOBY::Config->new();
	my @dbsections = (
		'mobycentral', 'mobyobject',
		'mobyservice', 'mobynamespace',
		'mobyrelationship'
	);
	my @response;
	foreach my $dbsection (@dbsections) {
		my $dbname   = ${ ${$config}{$dbsection} }{'dbname'};
		my $username = ${ ${$config}{$dbsection} }{'username'};
		my $password = ${ ${$config}{$dbsection} }{'password'};
		my $host     = ${ ${$config}{$dbsection} }{'url'};
		my $port     = ${ ${$config}{$dbsection} }{'port'};
		open( IN,
"mysqldump -h $host -P $port -u $username --password=$password $dbname|"
		  )
		  || die "can't open $dbname for dumping";
		my @dbdump;
		while (<IN>) {
			push @dbdump, $_;
		}
		my $dbdump = ( join "", @dbdump );
		push @response, $dbdump;
	}
	return [@response];
}
*DUMP = \&DUMP_MySQL;    # alias it for backward compatibility

#sub _flatten {
#	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
#	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );
#
#	# from a given term, traverse the ontology
#	# and flatten it into a list of parent terms
#	my ( $dbh, $type, $term, $seen ) = @_;
#
#	my $result = $adaptor->get_parent_terms(relationship_type_id => $type,
#						term => $term);
#
#	foreach my $row (@$result) {
#		my $term = $row->{term};
#		next if ${$seen}{$term};
#		&_flatten( $dbh, $type, $term, $seen );
#		${$seen}{$term} = 1;
#	}
#}

#Eddie - Converted
sub _ISAPayload {
	my ($payload) = @_;
	my $Parser    = XML::LibXML->new();
	my $doc       = $Parser->parse_string($payload);
	my $Object    = $doc->getDocumentElement();
	my $obj       = $Object->nodeName;
	return undef unless ( $obj eq 'ISA' );
	my $type = &_nodeTextContent( $Object, "objectType" );
	return ($type);
}
=cut








=head1 Internal Object Methods


=cut

=head2 _getValidServices

 Title     :	_getValidServices
 Usage     :	%valid = $MOBY->_getValidServices($sth_hash, $query, $max_return)
 Function  :	execute the query in $query to return a non-redundant list of matching services
 Returns   :	XML 
 Args      :	none

=cut

#sub _getValidServices {
#	my ($sth_hash, $query, $max_return ) = @_;
#	my %sth = %{$sth_hash};
#	$debug && &_LOG("QUERY: \n$query\n\n");
#	my $this_query = $dbh->prepare($query);
#	$this_query->execute;
#	my $response;
#	my %seen;
#	$response = "<Services>\n";
#
#	while ( my ( $serviceName, $objectOUT, $AuthURI, $desc, $type, $cat ) =
#		$this_query->fetchrow_array() )
#	{
#		$debug
#		  && &_LOG("$serviceName, $objectOUT, $AuthURI,$desc, $type, $cat\n");
#		next
#		  if $seen{ "$AuthURI" . "||"
#			  . "$serviceName" };    # non-redundant list please
#		$seen{ "$AuthURI" . "||" . "$serviceName" } = 1;
#		$response .=
#		  "<Service authURI='$AuthURI' serviceName='$serviceName'>\n";
#		$response .= "<Category>$cat</Category>\n";
#		$response .= "<serviceType>$type</serviceType>\n";
#		$response .= "<outputObject>$objectOUT</outputObject>\n";
#		if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
#			$desc = $1;
#		}
#		$response .= "<Description><![CDATA[$desc]]></Description>\n";
#		$response .= "</Service>\n";
#		if ($max_return) { --$max_return; last unless $max_return }
#	}
#	$response .= "</Services>\n";
#	$debug && &_LOG("\nFINAL RESPONSE IS \n$response\n\n");
#	return $response;
#}

=head2 _getServiceWSDL

 Title     :	_getServiceWSDL
 Usage     :	@valid = $MOBY->_getValidServices($dbh, $sth_hash, $query)
 Function  :	execute the query in $query to return a non-redundant list of matching services
 Returns   :	list of response strings in wsdl
 Args      :	none

=cut

sub _getServiceWSDL {
	my ( $SI, $InputXML, $OutputXML, $SecondaryXML ) = @_;

# the lines below causes no end of grief.  It is now in a variable.
#open (WSDL, "./MOBY/Central_WSDL_SandR.wsdl") || die "can't open WSDL file for search and replace\n";
#my $wsdl = join "", (<WSDL>);

	#close WSDL;
	# do substitutions
    my $serviceType = $SI->category;
    my $wsdl;
	if ($serviceType eq "cgi"){
	    $wsdl = &_doPostWSDLReplacement(@_)
	} elsif ($serviceType eq "moby"){
	    $wsdl = &_doMobyWSDLReplacement(@_)
	} elsif ($serviceType eq "moby-async"){
	    $wsdl = &_doAsyncWSDLReplacement(@_)
	} elsif ($serviceType eq "cgi-async"){
	    $wsdl = &_doAsyncPostWSDLReplacement(@_)
	}
	return $wsdl;
}

sub _doAsyncWSDLReplacement {
	# this routine does not work at the moment
	# we're just waiting for an example of an async
	# wsdl document from IMB
	my ( $SI, $InputXML, $OutputXML, $SecondaryXML ) = @_;
	my $wsdl = $WSDL_ASYNC_TEMPLATE;
	$wsdl =~ s/^\n//gs;
	my $serviceName = $SI->servicename;
	my $AuthURI     = $SI->authority_uri;
	my $desc        = $SI->description;
	if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
		$desc = $1;
	}
	$desc =~ s"\<"&lt;"g;  # XMl encode now that it is not CDATAd
	$desc =~ s"\>"&gt;"g;  # XML encode now that it is not CDATAd
	my $URL    = $SI->url;
	my $IN     = "NOT_YET_DEFINED_INPUTS";
	my $OUT    = "NOT_YET_DEFINED_OUTPUTS";
	my $INxsd  = &_getInputXSD( $InputXML, $SecondaryXML );
	my $OUTxsd = &_getOutputXSD($OutputXML);
	$INxsd  ||= "<NOT_YET_IMPLEMENTED_INPUT_XSD/>";
	$OUTxsd ||= "<NOT_YET_IMPLEMENTED_OUTPUT_XSD/>";
	$wsdl =~ s/MOBY__SERVICE__NAME__/$serviceName/g;    # replace all of the goofy portbindingpottype crap
	$wsdl =~s/\<\!\-\-\s*MOBY__SERVICE__DESCRIPTION\s*\-\-\>/Authority: $AuthURI  -  $desc/g;    # add a sensible description
	$wsdl =~ s/MOBY__SERVICE__URL/$URL/g;    # the URL to the service
	$wsdl =~ s/MOBY__SERVICE__NAME/$serviceName/g;    # finally replace the actual subroutine call
	return $wsdl;
}

sub _doAsyncPostWSDLReplacement {
	my ( $SI, $InputXML, $OutputXML, $SecondaryXML ) = @_;
	my $wsdl = $WSDL_ASYNC_POST_TEMPLATE;
	$wsdl =~ s/^\n//gs;
	my $serviceName = $SI->servicename;
	my $AuthURI     = $SI->authority_uri;
	my $desc        = $SI->description;
	if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
		$desc = $1;
	}
	$desc =~ s"\<"&lt;"g;  # XMl encode now that it is not CDATAd
	$desc =~ s"\>"&gt;"g;  # XML encode now that it is not CDATAd
	my $URL    = $SI->url;
    $URL =~ "(http://[^/]+)(/.*)";
    my $baseURL = $1;
	my $relativeURL = $2;
	my $IN     = "NOT_YET_DEFINED_INPUTS";
	my $OUT    = "NOT_YET_DEFINED_OUTPUTS";
	my $INxsd  = &_getInputXSD( $InputXML, $SecondaryXML );
	my $OUTxsd = &_getOutputXSD($OutputXML);
	$INxsd  ||= "<NOT_YET_IMPLEMENTED_INPUT_XSD/>";
	$OUTxsd ||= "<NOT_YET_IMPLEMENTED_OUTPUT_XSD/>";
	$wsdl =~ s/MOBY__SERVICE__NAME__/$serviceName/g;    # replace all of the goofy portbindingpottype crap
	$wsdl =~s/\<\!\-\-\s*MOBY__SERVICE__DESCRIPTION\s*\-\-\>/Authority: $AuthURI  -  $desc/g;    # add a sensible description
	$wsdl =~ s/MOBY__SERVICE__URL/$baseURL/g;    # the URL to the service
	$wsdl =~ s/MOBY__SERVICE__POST/$relativeURL/g;    # the URL to the service
	$wsdl =~ s/MOBY__SERVICE__NAME/$serviceName/g;    # finally replace the actual subroutine call
	return $wsdl;
}

sub _doPostWSDLReplacement {
	my ( $SI, $InputXML, $OutputXML, $SecondaryXML ) = @_;
	my $wsdl = $WSDL_POST_TEMPLATE;
	$wsdl =~ s/^\n//gs;
	my $serviceName = $SI->servicename;
	my $AuthURI     = $SI->authority_uri;
	my $desc        = $SI->description;
	if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
		$desc = $1;
	}
	$desc =~ s"\<"&lt;"g;  # XMl encode now that it is not CDATAd
	$desc =~ s"\>"&gt;"g;  # XML encode now that it is not CDATAd
	my $URL    = $SI->url;
    $URL =~ "(http://[^/]+)(/.*)";
    my $baseURL = $1;
	my $relativeURL = $2;
	my $IN     = "NOT_YET_DEFINED_INPUTS";
	my $OUT    = "NOT_YET_DEFINED_OUTPUTS";
	my $INxsd  = &_getInputXSD( $InputXML, $SecondaryXML );
	my $OUTxsd = &_getOutputXSD($OutputXML);
	$INxsd  ||= "<NOT_YET_IMPLEMENTED_INPUT_XSD/>";
	$OUTxsd ||= "<NOT_YET_IMPLEMENTED_OUTPUT_XSD/>";
	$wsdl =~ s/MOBY__SERVICE__NAME__/$serviceName/g;    # replace all of the goofy portbindingpottype crap
	$wsdl =~s/\<\!\-\-\s*MOBY__SERVICE__DESCRIPTION\s*\-\-\>/Authority: $AuthURI  -  $desc/g;    # add a sensible description
	$wsdl =~ s/MOBY__SERVICE__URL/$baseURL/g;    # the URL to the service
	$wsdl =~ s/MOBY__SERVICE__POST/$relativeURL/g;    # the URL to the service
	$wsdl =~ s/MOBY__SERVICE__NAME/$serviceName/g;    # finally replace the actual subroutine call
	return $wsdl;
}


sub _doMobyWSDLReplacement {
	my ( $SI, $InputXML, $OutputXML, $SecondaryXML ) = @_;
	my $wsdl = $WSDL_TEMPLATE;
	$wsdl =~ s/^\n//gs;
	my $serviceName = $SI->servicename;
	my $AuthURI     = $SI->authority_uri;
	my $desc        = $SI->description;
	if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
		$desc = $1;
	}
	$desc =~ s"\<"&lt;"g;  # XMl encode now that it is not CDATAd
	$desc =~ s"\>"&gt;"g;  # XML encode now that it is not CDATAd
	my $URL    = $SI->url;
	my $IN     = "NOT_YET_DEFINED_INPUTS";
	my $OUT    = "NOT_YET_DEFINED_OUTPUTS";
	my $INxsd  = &_getInputXSD( $InputXML, $SecondaryXML );
	my $OUTxsd = &_getOutputXSD($OutputXML);
	$INxsd  ||= "<NOT_YET_IMPLEMENTED_INPUT_XSD/>";
	$OUTxsd ||= "<NOT_YET_IMPLEMENTED_OUTPUT_XSD/>";
	$wsdl =~ s/MOBY__SERVICE__NAME__/$serviceName/g;    # replace all of the goofy portbindingpottype crap
	$wsdl =~s/\<\!\-\-\s*MOBY__SERVICE__DESCRIPTION\s*\-\-\>/Authority: $AuthURI  -  $desc/g;    # add a sensible description
	$wsdl =~ s/MOBY__SERVICE__URL/$URL/g;    # the URL to the service
	$wsdl =~ s/MOBY__SERVICE__NAME/$serviceName/g;    # finally replace the actual subroutine call
	return $wsdl
}


#sub _getCGIService {
#	my ( $dbh, $sth_hash, $id, $serviceName, $AuthURI, $URL, $desc, $category )
#	  = @_;
#	my %sth = %{$sth_hash};
#
#   # "Select OE.term, O.xsd, SP.type
#   # from Object as O, OntologyEntry as OE, ServiceParameter as SP, Service as S
#   # where O.ontologyentry_id = OE.id
#   # AND SP.ontologyentry_id = OE.id
#   # and SP.service_id = ?
#	my $sth = $dbh->prepare( $sth{get_server_parameters} );
#	$sth->execute($id);
#	my ( $Object, $sprintf, $in ) = $sth->fetchrow_array();
#	if ( $sprintf =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
#		$sprintf = $1;
#	}
#	return "<GETstring><![CDATA[$sprintf]]></GETstring>";
#}


#Eddie - converted
sub _nodeTextContent {

	# will get text of **all** child $node from the given $DOM
	# regardless of their depth!!
	my ( $DOM, $node ) = @_;
	$debug && &_LOG( "_nodeTextContent received DOM:  ",
		$DOM->toString, "\nsearching for node $node\n" );
	my $x = $DOM->getElementsByTagName($node);
	return undef unless $x->get_node(1);
	my @child = $x->get_node(1)->childNodes;
	my $content;
	foreach (@child) {
		$debug
		  && &_LOG( $_->nodeType, "\t", $_->toString, "\n" );

		#next unless $_->nodeType == TEXT_NODE;
		$content .= $_->textContent;
	}
	return $content;
}

sub _nodeCDATAContent {

	# will get text of **all** child $node from the given $DOM
	# regardless of their depth!!
	my ( $DOM, $node ) = @_;
	$debug && &_LOG( "_nodeTextContent received DOM:  ",
		$DOM->toString, "\nsearching for node $node\n" );
	my $x = $DOM->getElementsByTagName($node);
	return undef unless $x->get_node(1);
	my @child = $x->get_node(1)->childNodes;
	my $content;
	foreach (@child) {
		$debug
		  && &_LOG( $_->nodeType, "\t", $_->toString, "\n" );

		#next unless $_->nodeType == TEXT_NODE;
		if ( $_->toString =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
			$content .= $1;
		}
		else {
			$content .= $_->textContent;
		}
	}
	return $content;
}

#Eddie - converted
sub _nodeRawContent {

	# will get raw child nodes of $node from the given $DOM
	my ( $DOM, $nodename ) = @_;
	my @content;
	$debug && &_LOG( "_nodeRawContent received DOM:  ",
		$DOM->toString, "\nsearching for node $nodename\n" );
	my $x    = $DOM->getElementsByTagName($nodename);
	my $node = $x->get_node(1);
	return [] unless $node;
	foreach my $child ( $node->childNodes ) {
		next unless $child->nodeType == ELEMENT_NODE;
		push @content, $child;
	}
	return \@content;
}

#Eddie - converted
sub _nodeArrayContent {

	# will get array content of all child $node from given $DOM
	# regardless of depth!
	# e.g. the following XML:
	#<ISA>
	#   <objectType>first</objectType>
	#   <objectType>second</objectType>
	#</ISA>
	#will return the list "first", "second"
	my ( $DOM, $node ) = @_;
	$debug && &_LOG( "_nodeArrayContext received DOM:  ",
		$DOM->toString, "\nsearching for node $node\n" );
	my @result;
	my $x = $DOM->getElementsByTagName($node);
	return @result unless $x->get_node(1);
	my @child = $x->get_node(1)->childNodes;
	foreach (@child) {
		next unless $_->nodeType == ELEMENT_NODE;
		my @child2 = $_->childNodes;
		foreach (@child2) {

			#print getNodeTypeName($_), "\t", $_->toString,"\n";
			next unless $_->nodeType == TEXT_NODE;
			next unless ( length( $_->toString ) > 0 );
			push @result, $_->toString;
		}
	}
	$debug && _LOG("_nodeArrayContent resulted in @result\n");
	return @result;
}

#Eddie - converted
sub _nodeArrayExtraContent {

	# will get array content of all child $node from given $DOM
	# regardless of depth!
	# e.g. the following XML:
	#<ISA>
	#   <objectType articleName="thisone">first</objectType>
	#   <objectType articleName="otherone">second</objectType>
	#</ISA>
	#will return the list
	# ['first',{'articleName' => 'thisone'}],
	# ['second',{'articleName' => 'otherone'},...
	my ( $DOM, $node, @attrs ) = @_;
	$debug && &_LOG( "_nodeArrayExtraContext received DOM:  ",
		$DOM->toString, "\nsearching for node $node\n" );
	my @result;
	my %att_value;
	my $x     = $DOM->getElementsByTagName($node);
	my @child = $x->get_node(1)->childNodes;
	foreach (@child) {
		next unless $_->nodeType == ELEMENT_NODE;
		foreach my $attr (@attrs) {
			$debug && &_LOG( "_nodeArrayExtraContext received DOM:  ",
				$DOM->toString, "\nsearching for attributre $attr\n" );
			my $article =
			  $_->getAttributeNode($attr);    # may or may not have a name
			if ($article) { $article = $article->getValue() }
			$att_value{$attr} = $article;
		}
		my @child2 = $_->childNodes;
		foreach (@child2) {

			#print getNodeTypeName($_), "\t", $_->toString,"\n";
			next unless $_->nodeType == TEXT_NODE;
			push @result, [ $_->toString, \%att_value ];
		}
	}
	$debug && &_LOG(@result);
	return @result;
}

sub _serviceListResponse {
	
	
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );

	my (@ids ) = @_;
	my $output = "";
	my $OSobj  = MOBY::OntologyServer->new( ontology => 'object' );
	my $OSns   = MOBY::OntologyServer->new( ontology => 'namespace' );
	my $OSserv = MOBY::OntologyServer->new( ontology => 'service' );

	my $root = new XML::LibXML::Element("Services");
	
	foreach (@ids) {
		my $result = $adaptor->query_service_instance(service_instance_id => $_);
		my $row = shift(@$result);
		my $category = $row->{category};
		my $url = $row->{url};
		my $servicename = $row->{servicename};
		my $service_type_uri = $row->{service_type_uri};
		my $authority_uri = $row->{authority_uri};
		my $desc = $row->{description};
		my $authoritative = $row->{authoritative};
		my $email = $row->{contact_email};
		my $signatureURL = $row->{signatureURL};
		my $lsid = $row->{lsid};
		
		if ( $desc =~ /<!\[CDATA\[((?>[^\]]+))\]\]>/ ) {
			$desc = $1;
		}

		$signatureURL ||= "";
		next unless ( $servicename && $authority_uri );
		my $service_type = $OSserv->getServiceCommonName($service_type_uri);

		my $serviceNode = new XML::LibXML::Element("Service");
		$serviceNode->setAttribute("authURI",$authority_uri);
		$serviceNode->setAttribute("serviceName",$servicename);
		$serviceNode->setAttribute("lsid",$lsid);
		
		my $subElement = new XML::LibXML::Element("serviceType");
		$subElement->setAttribute("lsid",$service_type_uri);
		$subElement->appendText($service_type);
		$serviceNode->appendChild($subElement);
		
		$subElement = new XML::LibXML::Element("authoritative");
		$subElement->appendText($authoritative);
		$serviceNode->appendChild($subElement);
		
		$subElement = new XML::LibXML::Element("Category");
		$subElement->appendText($category);
		$serviceNode->appendChild($subElement);
		
		$subElement = new XML::LibXML::Element("Description");
		$subElement->appendChild(XML::LibXML::CDATASection->new($desc));
		$serviceNode->appendChild($subElement);
		
		$subElement = new XML::LibXML::Element("contactEmail");
		$subElement->appendText($email);
		$serviceNode->appendChild($subElement);
		
		$subElement = new XML::LibXML::Element("signatureURL");
		$subElement->appendText($signatureURL);
		$serviceNode->appendChild($subElement);
		
		$subElement = new XML::LibXML::Element("URL");
		$subElement->appendText($url);
		$serviceNode->appendChild($subElement);
		
		$subElement = new XML::LibXML::Element("Input");
		
		
		#$output .= "\t<Service authURI='$authority_uri' serviceName='$servicename' lsid='$lsid'>\n";
		#$output .= "\t<serviceType lsid='$service_type_uri'>$service_type</serviceType>\n";
		#$output .= "\t<authoritative>$authoritative</authoritative>\n";
		#$output .= "\t<Category>$category</Category>\n";
		#$output .= "\t<Description><![CDATA[$desc]]></Description>\n";
		#$output .= "\t<contactEmail>$email</contactEmail>\n";
		#$output .= "\t<signatureURL>$signatureURL</signatureURL>\n";
		#$output .= "\t<URL>$url</URL>\n";
		#$output .= "\t<Input>\n";

		$result = $adaptor->query_simple_input(service_instance_lsid => $lsid);
		
		foreach my $row (@$result)
		{
			my $objURI = $row->{object_type_uri};
			my $nsURI = $row->{namespace_type_uris};
			my $article = $row->{article_name};

			my $objName = $OSobj->getObjectCommonName($objURI);
			$nsURI ||= "";
			my @nsURIs = split ",", $nsURI;
			$article ||= "";
			
			my $simpleElement = new XML::LibXML::Element("Simple");
			$simpleElement->setAttribute("articleName",$article);
			my $typeElement = new XML::LibXML::Element("objectType");
			$typeElement->setAttribute("lsid", $objURI);
			$typeElement->appendText($objName);
			$simpleElement->appendChild($typeElement);
			
			
			#$output .= "\t\t<Simple articleName='$article'>\n";
			#$output .= "\t\t\t<objectType lsid='$objURI'>$objName</objectType>\n";
			foreach my $ns (@nsURIs) {
				my $NSname = $OSns->getNamespaceCommonName($ns);
				#$output .= "\t\t\t<Namespace lsid='$ns'>$NSname</Namespace>\n" if $NSname;
				my $nsElement = new XML::LibXML::Element("Namespace");
				$nsElement->setAttribute("lsid", $ns) if $NSname;
				$nsElement->appendText($NSname) if $NSname;
				$simpleElement->appendChild($nsElement) if $NSname;
			}
			#$output .= "\t\t</Simple>\n";
			$subElement->appendChild($simpleElement);
		}
		$result = $adaptor->query_collection_input(service_instance_lsid => $lsid);

		foreach my $row (@$result)
		{
		    my $collid = $row->{collection_input_id};
		    my $articlename = $row->{article_name};

		    #$output .= "\t\t<Collection articleName='$articlename'>\n";
			my $collectionElement = new XML::LibXML::Element("Collection");
			$collectionElement->setAttribute("articleName",$articlename);
						
		    my $result2 = $adaptor->query_simple_input(service_instance_lsid => undef, collection_input_id => $collid);
			foreach my $row2 (@$result2)
			{
			    my $objURI = $row2->{object_type_uri};
			    my $nsURI = $row2->{namespace_type_uris};
			    my $article = $row2->{article_name};

				my $objName = $OSobj->getObjectCommonName($objURI);
				$nsURI ||= "";
				my @nsURIs = split ",", $nsURI;
				$article ||= "";
				
				#$output .= "\t\t\t<Simple articleName='$article'>\n";
				#$output .= "\t\t\t\t<objectType lsid='$objURI'>$objName</objectType>\n";
				
				my $simpleElement = new XML::LibXML::Element("Simple");
				$simpleElement->setAttribute("articleName",$article);
				my $typeElement = new XML::LibXML::Element("objectType");
				$typeElement->setAttribute("lsid", $objURI);
				$typeElement->appendText($objName);
				$simpleElement->appendChild($typeElement);
				
				foreach my $ns (@nsURIs) {
					my $NSname = $OSns->getNamespaceCommonName($ns);
					#$output .= "\t\t\t\t<Namespace lsid='$ns'>$NSname</Namespace>\n" if $NSname;
					my $nsElement = new XML::LibXML::Element("Namespace");
					$nsElement->setAttribute("lsid", $ns) if $NSname;
					$nsElement->appendText($NSname) if $NSname;
					$simpleElement->appendChild($nsElement) if $NSname;
				}
				#$output .= "\t\t\t</Simple>\n";
				$collectionElement->appendChild($simpleElement);
			}
			$subElement->appendChild($collectionElement);
			#$output .= "\t\t</Collection>\n";
		}
		#$output .= "\t</Input>\n";
		$serviceNode->appendChild($subElement);
		#$output .= "\t<Output>\n";
		
		$subElement = new XML::LibXML::Element("Output");
		
		$result = $adaptor->query_simple_output(service_instance_lsid => $lsid, collection_output_id => undef);
		
		foreach my $row (@$result)
		{
		    my $objURI = $row->{object_type_uri};
		    my $nsURI = $row->{namespace_type_uris};
		    my $article = $row->{article_name};

		    my $objName = $OSobj->getObjectCommonName($objURI);
		    $nsURI ||= "";
		    my @nsURIs = split ",", $nsURI;
		    $article ||= "";
		    my $simpleElement = new XML::LibXML::Element("Simple");
			$simpleElement->setAttribute("articleName",$article);
			my $typeElement = new XML::LibXML::Element("objectType");
			$typeElement->setAttribute("lsid", $objURI);
			$typeElement->appendText($objName);
			$simpleElement->appendChild($typeElement);
		    
		    #$output .= "\t\t<Simple articleName='$article'>\n";
		    #$output .= "\t\t\t<objectType lsid='$objURI'>$objName</objectType>\n";
		    foreach my $ns (@nsURIs) {
				my $NSname = $OSns->getNamespaceCommonName($ns);
				#$output .= "\t\t\t<Namespace lsid='$ns'>$NSname</Namespace>\n" if $NSname;
				my $nsElement = new XML::LibXML::Element("Namespace");
				$nsElement->setAttribute("lsid", $ns) if $NSname;
				$nsElement->appendText($NSname) if $NSname;
				$simpleElement->appendChild($nsElement) if $NSname;
		    }
		    #$output .= "\t\t</Simple>\n";
		    $subElement->appendChild($simpleElement);
		}

		$result = $adaptor->query_collection_output(service_instance_lsid => $lsid);
		foreach my $row (@$result)
		{
		    my $collid = $row->{collection_output_id};
		    my $articlename = $row->{article_name};
		    #$output .= "\t\t<Collection articleName='$articlename'>\n";
			
			my $collectionElement = new XML::LibXML::Element("Collection");
			$collectionElement->setAttribute("articleName",$articlename);
		    
		    my $result2 = $adaptor->query_simple_output(service_instance_lsid => undef, collection_output_id => $collid);
		    foreach my $row2 (@$result2 )
		    {
				my $objURI = $row2->{object_type_uri};
				my $nsURI = $row2->{namespace_type_uris};
				my $article = $row2->{article_name};
				my $objName = $OSobj->getObjectCommonName($objURI);
				$nsURI ||= "";
				my @nsURIs = split ",", $nsURI;
				$article ||= "";
				#$output .= "\t\t\t<Simple articleName='$article'>\n";
				#$output .= "\t\t\t\t<objectType lsid='$objURI'>$objName</objectType>\n";
			
				my $simpleElement = new XML::LibXML::Element("Simple");
				$simpleElement->setAttribute("articleName",$article);
				my $typeElement = new XML::LibXML::Element("objectType");
				$typeElement->setAttribute("lsid", $objURI);
				$typeElement->appendText($objName);
				$simpleElement->appendChild($typeElement);
				
				foreach my $ns (@nsURIs) {
				    my $NSname = $OSns->getNamespaceCommonName($ns);
				    #$output .= "\t\t\t\t<Namespace lsid='$ns'>$NSname</Namespace>\n" if $NSname;
				    my $nsElement = new XML::LibXML::Element("Namespace");
					$nsElement->setAttribute("lsid", $ns) if $NSname;
					$nsElement->appendText($NSname) if $NSname;
					$simpleElement->appendChild($nsElement) if $NSname;
				}
				#$output .= "\t\t\t</Simple>\n";
				$collectionElement->appendChild($simpleElement);
		    }
		    #$output .= "\t\t</Collection>\n";
		    $subElement->appendChild($collectionElement);
		}
		#$output .= "\t</Output>\n";
		$serviceNode->appendChild($subElement);
		
		
		#$output .= "\t<secondaryArticles>\n";
		$subElement = new XML::LibXML::Element("secondaryArticles");
		$result = $adaptor->query_secondary_input(service_instance_lsid => $lsid);
		foreach my $row (@$result)
		{  my($default_value, $maximum_value, $minimum_value, $enum_value, $datatype, $description,$article_name) = ("","","","","","");
		    $default_value = $row->{default_value};
		    $maximum_value = $row->{maximum_value};
		    $minimum_value = $row->{minimum_value};
		    $enum_value = $row->{enum_value};
		    $datatype = $row->{datatype};
		    $description = $row->{description};
		    $article_name = $row->{article_name};
		    
		    my $parElement = new XML::LibXML::Element("Parameter");
		    $parElement->setAttribute("articleName",$article_name);
		    $parElement->appendTextChild( "datatype" , $datatype);
			# TODO should this description be wrapped in CDATA??
			$parElement->appendTextChild( "description" , $description);
			$parElement->appendTextChild( "default" , $default_value);
			$parElement->appendTextChild( "max" , $maximum_value);
			$parElement->appendTextChild( "min" , $minimum_value);
			
			#$output .= "\t\t\t<Parameter articleName='$article_name'>\n";
			#$output .= "\t\t\t\t<datatype>$datatype</datatype>\n";
			#$output .= "\t\t\t\t<description>$description</description>\n";
			#$output .= "\t\t\t\t<default>$default_value</default>\n";
			#$output .= "\t\t\t\t<max>$maximum_value</max>\n";
			#$output .= "\t\t\t\t<min>$minimum_value</min>\n";
			
			my @enums = split ",", $enum_value;

			if ( scalar(@enums) ) {
				foreach my $enum (@enums) {
					#$output .= "\t\t\t\t<enum>$enum</enum>\n";
					$parElement->appendTextChild( "enum" , $enum);
				}
			}
			else {
				#$output .= "\t\t\t\t<enum></enum>\n";
				$parElement->appendChild( new XML::LibXML::Element("enum") );
			}
			#$output .= "\t\t\t</Parameter>\n";
			$subElement->appendChild($parElement);
		}
		
		#$output .= "\t\t</secondaryArticles>\n";
		$serviceNode->appendChild($subElement);
		#$output .= "\t</Service>\n";	
		$root->appendChild($serviceNode);
	}
	return $root->toString(1);
	#return "<Services>\n$output\n</Services>\n";
}

sub _error {
	my ( $message, $id ) = @_;
	$id ||="";
	$message ||="";
	
	my $reg = &Registration(
		{
			success => 0,
			message => "$message",
			id      => "$id",
		}
	);
	return $reg;
}

sub _success {
	my ( $message, $id, $RDF ) = @_;
	my $reg = &Registration(
		{
			success => 1,
			message => "$message",
			id      => "$id",
			RDF     => $RDF,
		}
	);
	return $reg;
}

sub _getOntologyServer {    # may want to make this more complex
	my (%args) = @_;
	my $OS = MOBY::OntologyServer->new(%args);
	return $OS;
}
sub DESTROY { }

sub _LOG {

	return unless $debug;
	#print join "\n", @_;
	#print  "\n---\n";
	#return;
	open LOG, ">>/tmp/CentralRegistryLogOut.txt"
	  or die "can't open mobycentral error logfile $!\n";
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

=head2 _getInputXSD

  name    : _getInputXSD($InputXML, $SecondaryXML)
  function: to get an XSD describing the input to a MOBY Service,
            e.g. to use in a WSDL document
  args    : (see _serviceListResponse code above for full details of XML)
           $InputXML - the <Input>...</Input> block of a findService
           response message

           $SecondaryXML - the <secondaryArticles>...<sescondaryArticles>
           fragment of a findService response message

  returns :  XSD fragment of XML (should not return an XML header!)
  notes   : the structure of an Input block is as follows:
           <Input>
              <!-- one or more Simple or Collection articles -->
           </Input>

           the structure of a secondaryArticle block is as follows:
           <sescondaryArticles>
              <!-- one or more Parameter blocks -->
           </secondaryArticles>


=over

=item *  Simple

         <Simple articleName="NameOfArticle">
           <objectType>ObjectOntologyTerm</objectType>
           <Namespace>NamespaceTerm</Namespace>
           <Namespace>...</Namespace><!-- one or more... -->
         </Simple>

=item *  Collection note that articleName of the contained Simple objects is not required, and is ignored.


         <Collection articleName="NameOfArticle">
            <Simple>......</Simple> <!-- Simple parameter type structure -->
            <Simple>......</Simple> <!-- DIFFERENT Simple parameter type
                                      (used only when multiple Object Classes
                                      appear in a collection) -->
         </Collection>

=item *  Secondary


          <Parameter articleName="NameOfArticle">
                <datatype>INT|FLOAT|STRING</datatype>
                <default>...</default> <!-- any/all of these -->
                <max>...</max>         <!-- ... -->
                <min>...</min>         <!-- ... -->
                <enum>...<enum>        <!-- ... -->
                <enum>...<enum>        <!-- ... -->
          </Parameter>

=back

=cut

sub _getInputXSD {
	my ( $Input, $Secondary ) = @_;
	my $XSD;
	return $XSD;
}

=head2 _getOuputXSD

  name    : _getOutputXSD($OutputXML)
  function: to get an XSD describing the output from a MOBY Service
            e.g. to use in a WSDL document
  args    : (see _serviceListResponse code above for full details)
           $InputXML - the <Input>...</Input> block of a findService
           response message

           $SecondaryXML - the <secondaryArticles>...<sescondaryArticles>
           fragment of a findService response message

  returns :  XSD fragment of XML (should not return an XML header!)
  notes   : the structure of an Output block is as follows:
           <Input>
              <!-- one or more Simple or Collection articles -->
           </Input>

=over

=item *  Simple

         <Simple articleName="NameOfArticle">
           <objectType>ObjectOntologyTerm</objectType>
           <Namespace>NamespaceTerm</Namespace>
           <Namespace>...</Namespace><!-- one or more... -->
         </Simple>

=item *  Collection note that articleName of the contained Simple objects is not required, and is ignored.


         <Collection articleName="NameOfArticle">
            <Simple>......</Simple> <!-- Simple parameter type structure -->
            <Simple>......</Simple> <!-- DIFFERENT Simple parameter type
                                      (used only when multiple Object Classes
                                       appear in a collection) -->
         </Collection>

=back

=cut

sub _getOutputXSD {
	my ($Output) = @_;
	my $XSD;
	return $XSD;
}



=head2 WSDL_Templates

=cut

#===============================================
#===============================================
#===============================================

# Standard MOBY WSDL Template


$WSDL_TEMPLATE = <<END;
<?xml version="1.0"?>
<wsdl:definitions name="MOBY_Central_Generated_WSDL"
                targetNamespace="http://biomoby.org/Central.wsdl"
                xmlns:tns="http://biomoby.org/Central.wsdl"
                xmlns:xsd1="http://biomoby.org/CentralXSDs.xsd"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns="http://schemas.xmlsoap.org/wsdl/"
                xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                xmlns:wsdlsoap="http://schemas.xmlsoap.org/wsdl/soap/">

                 
  <wsdl:message name="MOBY__SERVICE__NAME__Input">
          <wsdl:part name="data" type="xsd:string"/>
  </wsdl:message>

  <wsdl:message name="MOBY__SERVICE__NAME__Output">
          <wsdl:part name="body" type="xsd:string"/>
  </wsdl:message>

  <wsdl:portType name="MOBY__SERVICE__NAME__PortType">
          <wsdl:operation name="MOBY__SERVICE__NAME">
                 <wsdl:input message="tns:MOBY__SERVICE__NAME__Input"/>
                 <wsdl:output message="tns:MOBY__SERVICE__NAME__Output"/>
          </wsdl:operation>
  </wsdl:portType>
                
  <wsdl:binding name="MOBY__SERVICE__NAME__Binding" type="tns:MOBY__SERVICE__NAME__PortType">
          <wsdlsoap:binding style="rpc" transport="http://schemas.xmlsoap.org/soap/http"/>
          <wsdl:operation name="MOBY__SERVICE__NAME"><!-- in essense, this is the name of the subroutine that is called -->
                 <wsdlsoap:operation soapAction='http://biomoby.org/#MOBY__SERVICE__NAME' style='rpc'/>
                 <wsdl:input>
                         <wsdlsoap:body use="encoded" namespace="http://biomoby.org/" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
                 </wsdl:input>
                 <wsdl:output>
                         <wsdlsoap:body use="encoded" namespace="http://biomoby.org/" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
                 </wsdl:output>
          </wsdl:operation>
  </wsdl:binding>
                
  <wsdl:service name="MOBY__SERVICE__NAME__Service">
          <wsdl:documentation><!-- MOBY__SERVICE__DESCRIPTION --></wsdl:documentation>  <!-- service description goes here -->
          <wsdl:port name="MOBY__SERVICE__NAME__Port" binding="tns:MOBY__SERVICE__NAME__Binding">
                 <wsdlsoap:address location="MOBY__SERVICE__URL"/>    <!-- URL to service scriptname -->
          </wsdl:port>
  </wsdl:service>

</wsdl:definitions>


END


# MOBY CGI service template

$WSDL_POST_TEMPLATE = <<END2;
<?xml version="1.0"?>
<wsdl:definitions name="MOBY_Central_Generated_WSDL"
                targetNamespace="http://biomoby.org/Central.wsdl"
                xmlns:tns="http://biomoby.org/Central.wsdl"
                xmlns:xsd1="http://biomoby.org/CentralXSDs.xsd" 
                xmlns:xsd="http://www.w3.org/1999/XMLSchema"
                xmlns="http://schemas.xmlsoap.org/wsdl/"
				xmlns:http="http://schemas.xmlsoap.org/wsdl/http/"
				xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/"
				xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">

  
  <wsdl:message name="MOBY__SERVICE__NAME__Input">
          <wsdl:part name="data" type="xsd:string"/>
  </wsdl:message>
        
  <wsdl:message name="MOBY__SERVICE__NAME__Output">
          <wsdl:part name="body" type="xsd:string"/>
  </wsdl:message>
          
  <wsdl:portType name="MOBY__SERVICE__NAME__PortType">
          <wsdl:operation name="MOBY__SERVICE__NAME">
                 <wsdl:input message="tns:MOBY__SERVICE__NAME__Input"/>
                 <wsdl:output message="tns:MOBY__SERVICE__NAME__Output"/>
          </wsdl:operation>
  </wsdl:portType>
 
  <wsdl:binding name="MOBY__SERVICE__NAME__Binding" type="tns:MOBY__SERVICE__NAME__PortType">
		<http:binding verb="POST"/>
          <wsdl:operation name="MOBY__SERVICE__NAME"><!-- in essense, this is the name of the subroutine that is called -->
                 <http:operation location='MOBY__SERVICE__POST'/>
                 <wsdl:input>
                         <mime:content type="application/x-www-form-urlencoded"/>
                 </wsdl:input>
                 <wsdl:output>
                         <mime:content type="text/xml"/>
                 </wsdl:output>
          </wsdl:operation>
  </wsdl:binding>
                
  <wsdl:service name="MOBY__SERVICE__NAME__Service">
          <wsdl:documentation><!-- MOBY__SERVICE__DESCRIPTION --></wsdl:documentation>  <!-- service description goes here -->
          <wsdl:port name="MOBY__SERVICE__NAME__Port" binding="tns:MOBY__SERVICE__NAME__Binding">
                 <http:address location="MOBY__SERVICE__URL"/>    <!-- URL to service scriptname -->
          </wsdl:port>
  </wsdl:service>

</wsdl:definitions>


END2

$WSDL_ASYNC_POST_TEMPLATE =<<END;
<?xml version="1.0"?>
<wsdl:definitions name="MOBY_Central_Generated_WSDL"
	targetNamespace="http://biomoby.org/Central.wsdl"
	xmlns:tns="http://biomoby.org/Central.wsdl"
	xmlns:xsd1="http://biomoby.org/CentralXSDs.xsd"
	xmlns:xsd="http://www.w3.org/1999/XMLSchema"
	xmlns="http://schemas.xmlsoap.org/wsdl/"
	xmlns:http="http://schemas.xmlsoap.org/wsdl/http/"
	xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/"
	xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
	xmlns:p="http://www.w3.org/2001/XMLSchema">


	<wsdl:message name="MOBY__SERVICE__NAME__Input">
		<wsdl:part name="data" type="xsd:string" />
	</wsdl:message>

	<wsdl:message name="MOBY__SERVICE__NAME__Output">
		<wsdl:part name="body" type="xsd:string" />
	</wsdl:message>

	<wsdl:portType name="MOBY__SERVICE__NAME__PortType">
		<wsdl:operation name="MOBY__SERVICE__NAME">
			<wsdl:input message="tns:MOBY__SERVICE__NAME__Input" />
			<wsdl:output message="tns:MOBY__SERVICE__NAME__Output" />
		</wsdl:operation>
	</wsdl:portType>
	<!-- submit -->
	<wsdl:service name="MOBY__SERVICE__NAME__Service">
		<wsdl:documentation><!-- MOBY__SERVICE__DESCRIPTION --></wsdl:documentation>
		<!-- service description goes here -->
		<wsdl:port name="MOBY__SERVICE__NAME__Port"
			binding="tns:MOBY__SERVICE__NAME__Binding">
			<http:address location="MOBY__SERVICE__URL" />
			<!-- URL to service scriptname -->
		</wsdl:port>
	</wsdl:service>
	<wsdl:binding name="MOBY__SERVICE__NAME__Binding"
		type="tns:MOBY__SERVICE__NAME__PortType">
		<http:binding verb="POST" />
		<wsdl:operation name="MOBY__SERVICE__NAME"><!-- in essense, this is the name of the subroutine that is called -->
			<http:operation location='MOBY__SERVICE__POST' />
			<wsdl:input>
				<mime:content part="MOBY__SERVICE__NAME__Input"
					type="application/x-www-form-urlencoded" />
			</wsdl:input>
			<wsdl:output>
				<mime:content part="MOBY__SERVICE__NAME__Output"
					type="text/xml" />
			</wsdl:output>
		</wsdl:operation>
	</wsdl:binding>

	<!-- results -->
	<wsdl:service name="MOBY__SERVICE__NAME__Service_results">
		<wsdl:documentation><!-- MOBY__SERVICE__DESCRIPTION --></wsdl:documentation>
		<!-- service description goes here -->
		<wsdl:port name="MOBY__SERVICE__NAME__Port_results"
			binding="tns:MOBY__SERVICE__NAME__Binding_results">
			<http:address location="MOBY__SERVICE__URL" />
			<!-- URL to service scriptname -->
		</wsdl:port>
	</wsdl:service>
	<wsdl:binding name="MOBY__SERVICE__NAME__Binding_results"
		type="tns:MOBY__SERVICE__NAME__PortType">
		<http:binding verb="POST" />
		<wsdl:operation name="MOBY__SERVICE__NAME"><!-- in essense, this is the name of the subroutine that is called -->
			<http:operation location='MOBY__SERVICE__POST' />
			<wsdl:input>
				<mime:content part="MOBY__SERVICE__NAME__Input"
					type="application/x-www-form-urlencoded" />
			</wsdl:input>
			<wsdl:output>
				<mime:content part="MOBY__SERVICE__NAME__Output"
					type="text/xml" />
			</wsdl:output>
		</wsdl:operation>
	</wsdl:binding>
	
	
	<!-- status -->
	<wsdl:service name="MOBY__SERVICE__NAME__Service_status">
		<wsdl:documentation><!-- MOBY__SERVICE__DESCRIPTION --></wsdl:documentation>
		<!-- service description goes here -->
		<wsdl:port name="MOBY__SERVICE__NAME__Port_status"
			binding="tns:MOBY__SERVICE__NAME__Binding_status">
			<http:address location="MOBY__SERVICE__URL" />
			<!-- URL to service scriptname -->
		</wsdl:port>
	</wsdl:service>
	<wsdl:binding name="MOBY__SERVICE__NAME__Binding_status"
		type="tns:MOBY__SERVICE__NAME__PortType">
		<http:binding verb="POST" />
		<wsdl:operation name="MOBY__SERVICE__NAME"><!-- in essense, this is the name of the subroutine that is called -->
			<http:operation location='MOBY__SERVICE__POST' />
			<wsdl:input>
				<mime:content part="MOBY__SERVICE__NAME__Input"
					type="application/x-www-form-urlencoded" />
			</wsdl:input>
			<wsdl:output>
				<mime:content part="MOBY__SERVICE__NAME__Output"
					type="text/xml" />
			</wsdl:output>
		</wsdl:operation>
	</wsdl:binding>
	<!-- destroy -->
	<wsdl:service name="MOBY__SERVICE__NAME__Service_destroy">
		<wsdl:documentation><!-- MOBY__SERVICE__DESCRIPTION --></wsdl:documentation>
		<!-- service description goes here -->
		<wsdl:port name="MOBY__SERVICE__NAME__Port_destroy"
			binding="tns:MOBY__SERVICE__NAME__Binding_destroy">
			<http:address location="MOBY__SERVICE__URL" />
			<!-- URL to service scriptname -->
		</wsdl:port>
	</wsdl:service>
	<wsdl:binding name="MOBY__SERVICE__NAME__Binding_destroy"
		type="tns:MOBY__SERVICE__NAME__PortType">
		<http:binding verb="POST" />
		<wsdl:operation name="MOBY__SERVICE__NAME"><!-- in essense, this is the name of the subroutine that is called -->
			<http:operation location='MOBY__SERVICE__POST' />
			<wsdl:input>
				<mime:content part="MOBY__SERVICE__NAME__Input"
					type="application/x-www-form-urlencoded" />
			</wsdl:input>
			<wsdl:output>
				<mime:content part="MOBY__SERVICE__NAME__Output"
					type="text/xml" />
			</wsdl:output>
		</wsdl:operation>
	</wsdl:binding>
</wsdl:definitions>
END

# for MOBY Asynchronous services.  This WSDL is not correct YET!

$WSDL_ASYNC_TEMPLATE = <<END;
<?xml version="1.0" encoding="UTF-8"?>
<wsdl:definitions name="MOBY_Central_Generated_WSDL" targetNamespace="http://biomoby.org/Central.wsdl"
   xmlns:tns="http://biomoby.org/Central.wsdl"
   xmlns:xsd1="http://biomoby.org/CentralXSDs.xsd"
   xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
   xmlns:wsoap="http://schemas.xmlsoap.org/soap/envelope/"
   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
   xmlns="http://schemas.xmlsoap.org/wsdl/"
   xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
   xmlns:wsrp="http://docs.oasis-open.org/wsrf/rp-2"
   xmlns:wsrl="http://docs.oasis-open.org/wsrf/rl-2"
   xmlns:wsbf="http://docs.oasis-open.org/wsrf/bf-2"
   xmlns:wsrpw="http://docs.oasis-open.org/wsrf/rpw-2"
   xmlns:wsrlw="http://docs.oasis-open.org/wsrf/rlw-2"
   xmlns:wsrw="http://docs.oasis-open.org/wsrf/rw-2"
   xmlns:wsa="http://www.w3.org/2005/08/addressing">

   <wsdl:import
      namespace="http://docs.oasis-open.org/wsrf/rpw-2"
      location="http://docs.oasis-open.org/wsrf/rpw-2.wsdl"/>
   <wsdl:import
      namespace="http://docs.oasis-open.org/wsrf/rlw-2"
      location="http://docs.oasis-open.org/wsrf/rlw-2.wsdl"/>
   <wsdl:import
      namespace="http://docs.oasis-open.org/wsrf/rw-2"
      location="http://docs.oasis-open.org/wsrf/rw-2.wsdl"/>
   <wsdl:types>
      <xsd:schema elementFormDefault="qualified"
         targetNamespace="http://biomoby.org/Central.wsdl"
         xmlns="http://biomoby.org/Central.wsdl"
      >
         <xsd:import
            namespace="http://docs.oasis-open.org/wsrf/bf-2"
            schemaLocation="http://docs.oasis-open.org/wsrf/bf-2.xsd"/>
         <xsd:import
            namespace="http://docs.oasis-open.org/wsrf/rl-2"
            schemaLocation="http://docs.oasis-open.org/wsrf/rl-2.xsd"/>
         <xsd:import
            namespace="http://www.w3.org/2005/08/addressing"
            schemaLocation="http://www.w3.org/2002/ws/addr/ns/ws-addr" />
         <xsd:complexType name="MOBY_async_OutputType">
            <xsd:sequence minOccurs="1" maxOccurs="1">
               <xsd:element ref="wsa:EndpointReference"/>
            </xsd:sequence>
         </xsd:complexType>
         
         <xsd:element name="ResourceProperties">
            <xsd:complexType>
               <xsd:sequence>
                  <xsd:any minOccurs="0" maxOccurs="unbounded"/>
               </xsd:sequence>
            </xsd:complexType>
         </xsd:element>
      </xsd:schema>
   </wsdl:types>
   <wsdl:message name="MOBY__SERVICE__NAME__Input">
      <wsdl:part name="data" type="xsd:string"/>
   </wsdl:message>
   <wsdl:message name="MOBY__SERVICE__NAME__Output">
      <wsdl:part name="body" type="xsd:string"/>
   </wsdl:message>
   <wsdl:message name="MOBY__SERVICE__NAME___submitInput">
      <wsdl:part name="data" type="xsd:string"/>
   </wsdl:message>
   <wsdl:message name="MOBY__SERVICE__NAME___submitOutput">
      <wsdl:part name="body" type="tns:MOBY_async_OutputType"/>
   </wsdl:message>
   <wsdl:portType name="MOBY__SERVICE__NAME__PortType" wsrp:ResourceProperties="tns:ResourceProperties">
      <wsdl:operation name="MOBY__SERVICE__NAME__">
         <wsdl:input message="tns:MOBY__SERVICE__NAME__Input"/>
         <wsdl:output message="tns:MOBY__SERVICE__NAME__Output"/>
      </wsdl:operation>
      <wsdl:operation name="MOBY__SERVICE__NAME___submit">
         <wsdl:input message="tns:MOBY__SERVICE__NAME___submitInput"/>
         <wsdl:output message="tns:MOBY__SERVICE__NAME___submitOutput"/>
      </wsdl:operation>
   </wsdl:portType>
   <wsdl:portType name="WSRF_Operations_PortType" wsrp:ResourceProperties="tns:ResourceProperties">
      <wsdl:operation name="GetResourceProperty">
         <wsdl:input name="GetResourcePropertyRequest" message="wsrpw:GetResourcePropertyRequest"/>
         <wsdl:output name="GetResourcePropertyResponse" message="wsrpw:GetResourcePropertyResponse"/>
         <wsdl:fault name="ResourceUnknownFault" message="wsrw:ResourceUnknownFault"/>
         <wsdl:fault name="ResourceUnavailableFault" message="wsrw:ResourceUnavailableFault"/>
         <wsdl:fault name="InvalidResourcePropertyQNameFault"
            message="wsrpw:InvalidResourcePropertyQNameFault"/>
      </wsdl:operation>
      <wsdl:operation name="GetMultipleResourceProperties">
         <wsdl:input name="GetMultipleResourcePropertiesRequest"
            message="wsrpw:GetMultipleResourcePropertiesRequest"/>
         <wsdl:output name="GetMultipleResourcePropertiesResponse"
            message="wsrpw:GetMultipleResourcePropertiesResponse"/>
         <wsdl:fault name="ResourceUnknownFault" message="wsrw:ResourceUnknownFault"/>
         <wsdl:fault name="ResourceUnavailableFault" message="wsrw:ResourceUnavailableFault"/>
         <wsdl:fault name="InvalidResourcePropertyQNameFault"
            message="wsrpw:InvalidResourcePropertyQNameFault"/>
      </wsdl:operation>
      <wsdl:operation name="Destroy">
         <wsdl:input message="wsrlw:DestroyRequest"/>
         <wsdl:output message="wsrlw:DestroyResponse"/>
         <wsdl:fault name="ResourceUnknownFault" message="wsrw:ResourceUnknownFault"/>
         <wsdl:fault name="ResourceUnavailableFault" message="wsrw:ResourceUnavailableFault"/>
         <wsdl:fault name="ResourceNotDestroyedFault" message="wsrlw:ResourceNotDestroyedFault"/>
      </wsdl:operation>
   </wsdl:portType>
   <wsdl:binding name="MOBY__SERVICE__NAME__Binding" type="tns:MOBY__SERVICE__NAME__PortType">
      <soap:binding style="rpc" transport="http://schemas.xmlsoap.org/soap/http"/>
      <wsdl:operation name="MOBY__SERVICE__NAME__">
         <soap:operation soapAction="http://biomoby.org/#MOBY__SERVICE__NAME__" style="rpc"/>
         <wsdl:input>
            <soap:body use="encoded" namespace="http://biomoby.org/"
               encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
         </wsdl:input>
         <wsdl:output>
            <soap:body use="encoded" namespace="http://biomoby.org/"
               encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
         </wsdl:output>
      </wsdl:operation>
      <wsdl:operation name="MOBY__SERVICE__NAME___submit">
         <soap:operation soapAction="http://biomoby.org/#MOBY__SERVICE__NAME___submit" style="rpc"/>
         <wsdl:input>
            <soap:body use="encoded" namespace="http://biomoby.org/"
               encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
         </wsdl:input>
         <wsdl:output>
            <soap:body use="encoded" namespace="http://biomoby.org/"
               encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
         </wsdl:output>
      </wsdl:operation>
   </wsdl:binding>
   <wsdl:binding name="WSRF_Operations_Binding" type="tns:WSRF_Operations_PortType">
      <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
      <wsdl:operation name="GetResourceProperty">
         <soap:operation soapAction="http://docs.oasis-open.org/wsrf/rpw-2/GetResourceProperty/GetResourcePropertyRequest" />
         <wsdl:input>
            <soap:body use="literal"/>
         </wsdl:input>
         <wsdl:output>
            <soap:body use="literal"/>
         </wsdl:output>
         <wsdl:fault name="ResourceUnknownFault">
            <soap:fault name="ResourceUnknownFault" use="literal"/>
         </wsdl:fault>
         <wsdl:fault name="ResourceUnavailableFault">
            <soap:fault name="ResourceUnavailableFault" use="literal"/>
         </wsdl:fault>
         <wsdl:fault name="InvalidResourcePropertyQNameFault">
            <soap:fault name="InvalidResourcePropertyQNameFault" use="literal"/>
         </wsdl:fault>
      </wsdl:operation>
      <wsdl:operation name="GetMultipleResourceProperties">
         <soap:operation soapAction="http://docs.oasis-open.org/wsrf/rpw-2/GetMultipleResourceProperties/GetMultipleResourcePropertiesRequest" />
         <wsdl:input>
            <soap:body use="literal"/>
         </wsdl:input>
         <wsdl:output>
            <soap:body use="literal"/>
         </wsdl:output>
         <wsdl:fault name="ResourceUnknownFault">
            <soap:fault name="ResourceUnknownFault" use="literal"/>
         </wsdl:fault>
         <wsdl:fault name="ResourceUnavailableFault">
            <soap:fault name="ResourceUnavailableFault" use="literal"/>
         </wsdl:fault>
         <wsdl:fault name="InvalidResourcePropertyQNameFault">
            <soap:fault name="InvalidResourcePropertyQNameFault" use="literal"/>
         </wsdl:fault>
      </wsdl:operation>
      <wsdl:operation name="Destroy">
         <soap:operation soapAction="http://docs.oasis-open.org/wsrf/rlw-2/ImmediateResourceTermination/DestroyRequest" />
         <wsdl:input>
            <soap:body use="literal"/>
         </wsdl:input>
         <wsdl:output>
            <soap:body use="literal"/>
         </wsdl:output>
         <wsdl:fault name="ResourceUnknownFault">
            <soap:fault name="ResourceUnknownFault" use="literal"/>
         </wsdl:fault>
         <wsdl:fault name="ResourceUnavailableFault">
            <soap:fault name="ResourceUnavailableFault" use="literal"/>
         </wsdl:fault>
         <wsdl:fault name="ResourceNotDestroyedFault">
            <soap:fault name="ResourceNotDestroyedFault" use="literal"/>
         </wsdl:fault>
      </wsdl:operation>
   </wsdl:binding>
   <wsdl:service name="MOBY__SERVICE__NAME__Service">
      <wsdl:documentation><!-- MOBY__SERVICE__DESCRIPTION --></wsdl:documentation>
      <wsdl:port name="MOBY__SERVICE__NAME__Port" binding="tns:MOBY__SERVICE__NAME__Binding">
         <soap:address location="MOBY__SERVICE__URL"/>
      </wsdl:port>
      <wsdl:port name="WSRF_Operations_Port" binding="tns:WSRF_Operations_Binding">
         <soap:address location="MOBY__SERVICE__URL"/>
      </wsdl:port>
   </wsdl:service>
</wsdl:definitions>

END




1;

