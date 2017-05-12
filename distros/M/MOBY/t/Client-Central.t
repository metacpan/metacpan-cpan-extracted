# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

# Note added by Frank Gibbons.
# Tests should, as far as possible, avoid the use of literals.
# If you register a service with authURI => mysite.com,
# and you want to test a retrieved description of the service, don't test that the service returns authURI eq "mysite.com",
# test so that it returns the same value as you used to register it in the first place.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
#use SOAP::Lite +trace;
use Test::More 'no_plan'
  ;    #skip_all => "Turn off for development"; # See perldoc Test::More for details
use strict;
use Data::Dumper;

#$ENV{MOBY_SERVER} = 'http://mobycentral.icapture.ubc.ca/cgi-bin/MOBY05/mobycentral.pl'
#unless ($ENV{MOBY_SERVER}) print;
#$ENV{MOBY_URI} = 'http://mobycentral.icapture.ubc.ca/MOBY/Central'
#unless ($ENV{MOBY_URI});

#Is the client-code even installed?
BEGIN {
	use_ok('MOBY::Client::Central');
	if ( defined $ENV{MOBY_VERBOSE} && $ENV{MOBY_VERBOSE} == 1 ) {
		my $C = MOBY::Client::Central->new();

		# Find the default registry, and pull out just the hostname, for clarity
		( my $default_registry = $C->default_MOBY_server() ) =~
		  /http:\/\/(.*?)\//;    # Parsimonious match
		$default_registry = $1;
		diag <<END;

    This is the MOBY Client Central test suite.
    By default this connects to the server at $default_registry

    If you want to test a different server you must set the following
    environment variables:
    MOBY_SERVER='http://your.server.name/path/to/mobycentral.pl'
    MOBY_URI='http://your.server.name/MOBY/Central'
END
	}
}

END {

	# Define cleanup of registry, to return it to its 'pristine' state,
	# so that later attempts to run tests don't run into problems caused
	# by failure of these tests, or abortion of the test script.
	# Reconnect to MOBY Central here, since other connections
	# will have gone out of scope by the time we get to this END block.

	# Also can't use %Obj,
	my $C = MOBY::Client::Central->new();
	my $r = $C->deregisterService( serviceName => 'myfirstservice',
								   authURI     => 'test.suite.com' );
	$r = $C->deregisterService( serviceName => '1myfirstservice',
								authURI     => 'test.suite.com' );
	$r = $C->deregisterService( serviceName => 'my]firstservice',
								authURI     => 'test.suite.com' );
	$r = $C->deregisterService( serviceName => 'myf_irstservice',
								authURI     => 'test.suite.com' );
	$r = $C->deregisterService( serviceName => 'mysecondservice',
								authURI     => 'test.suite.com' );
	$r = $C->deregisterService( serviceName => 'mySecondaryTestservice',
								authURI     => 'test.suite.com' );
	$r = $C->deregisterService( serviceName => 'myfirstservicemultiplesimples',
								authURI     => 'test.suite.com' );

	$r = $C->deregisterObjectClass( objectType => "Rubbish" );
	$r = $C->deregisterObjectClass( objectType => "Rubbish_Art" );

	$r = $C->deregisterNamespace( namespaceType => 'RubbishNamespace' );
        $r = $C->deregisterNamespace( namespaceType => 'Rubbish:Namespace');

	$r = $C->deregisterServiceType( serviceType => 'RubbishyService' );
	$r = $C->deregisterServiceType( serviceType => 'Rubbishy:Service' );
	$r = $C->deregisterServiceType( serviceType => 'RubbishyServiceNoParent' );
}

# Can we connect to the registry?
my $C = MOBY::Client::Central->new();
diag "\n\nUsing Moby Central located at: ", $C->default_MOBY_server, "\n\n";
isa_ok( $C, 'MOBY::Client::Central', "Connected to test MOBY Central" )
  or die("Cannot Connect to MOBY Central... cannot continue?");

if ( defined $ENV{MOBY_VERBOSE} && $ENV{MOBY_VERBOSE} == 1 ) {
	diag "\nFor the following tests I will be using the server at:\n\t"
	  . $C->Registries->{mobycentral}->{URL}, "\n\n";
}

############           ENFORCE REGISTRY API        ###############

# First, mandatory methods for all registries.
my @mandatory = qw/findService retrieveService
  retrieveResourceURLs retrieveServiceProviders retrieveServiceNames
  retrieveServiceTypes retrieveObjectNames retrieveObjectDefinition
  retrieveNamespaces Relationships/;

my @mandatory_if_write_access = qw/registerObjectClass deregisterObjectClass
  registerServiceType deregisterServiceType
  registerNamespace deregisterNamespace
  registerService deregisterService/;

my @optional_recommended = qw/DUMP registerServiceWSDL/;

can_ok( $C, @mandatory )
  or diag("Registry failed to supply mandatory methods");

# How do we check whether the registry has 'write' access - most will, so take as default.
can_ok( $C, @mandatory_if_write_access )
  or diag("Registry has 'write' access and failed to supply mandatory methods");

# Optional, but probably recommended methods
can_ok( $C, @optional_recommended )
  or diag(   "Registry does not supply certain optional methods;\n"
		   . "you should consider adding them" );

TODO: {
	local $TODO = "Method 'retrieveObjectSchema yet to be implemented";
	can_ok( $C, "retrieveObjectSchema" )
	  or diag("Registry should be able to return Object Schema");
}
################## MOBY Registration Tests #################

##################    OBJECT REGISTRATION    #############
# Test 3  inherits from two isas - should fail
my %Obj = (
			objectType    => "Rubbish",
			description   => "a human-readable description of the object",
			contactEmail  => 'your@email.address',
			authURI       => "test.suite.com",
			Relationships => {
							   ISA => [
										{
										  object      => 'Object',
										  articleName => 'article1'
										},
										{
										  object      => 'Object',
										  articleName => 'articleName2'
										}
							   ],
							   HASA => [
										 {
										   object      => 'Object',
										   articleName => 'articleName3'
										 }
							   ]
			}
);
my $r = $C->registerObjectClass(%Obj);
ok( !$r->success, "Object registration correctly failed" )
  or diag( "Object can't inherit from two ISAs: " . $r->message );

# Object with only one ISA, but it's primitive.
# Object inherits from primitive type -> should fail.
$Obj{Relationships}->{ISA} = [
							   {
								 object      => 'String',
								 articleName => 'article1'
							   }
];
$r = $C->registerObjectClass(%Obj);
ok( !$r->success, "Object registration correctly failed" )
  or diag( "Shouldn't be possible to register Object that inherits from primitive"
		   . $r->message );

# Object with only one ISA, and it's NOT primitive -> should succeed.
$Obj{Relationships}->{ISA} = [
							   {
								 object      => 'Object',
								 articleName => 'article1'
							   }
];
$r = $C->registerObjectClass(%Obj);
ok( $r->success, "Object registration successful" )
  or diag( "Object registration failed: " . $r->message );

# De-register the object we just registered
$r = $C->deregisterObjectClass( objectType => $Obj{objectType} );
ok( $r->success, "Object deregistration successful" )
  or diag( "Object deregistration failed: " . $r->message );

# Register it again, having de-registered it.
$r = $C->registerObjectClass(%Obj);
ok( $r->success, "Object registration successful" )
  or diag( "Object re-registration failed: " . $r->message );

# confirm that we cannot register a datatype with similar article names
$r = $C->registerObjectClass(
	(
	   objectType    => "Rubbish_Art",
	   description   => "a human-readable description of the object",
	   contactEmail  => 'your@email.address',
	   authURI       => "test.suite.com",
	   Relationships => {
						  ISA => [
								   {
									 object      => 'Object',
									 articleName => 'article1'
								   }
						  ],
						  HASA => [
									{
									  object      => 'Object',
									  articleName => 'articleName3'
									},
									{
									  object      => 'String',
									  articleName => 'articleName3'
									}
						  ]
	   }
	)
);
ok( !$r->success, "Object registration correctly failed" )
  or diag(
	"Shouldn't be possible to register Object with similar articlenames for its members"
	  . $r->message );
$r = $C->deregisterObjectClass( objectType => "Rubbish_Art" );


# confirm that we cannot register a datatype with odd characters in its name
$r = $C->registerObjectClass(
	(
	   objectType    => "Rubbish_'Art",
	   description   => "a human-readable description of the object",
	   contactEmail  => 'your@email.address',
	   authURI       => "test.suite.com",
	   Relationships => {
						  ISA => [
								   {
									 object      => 'Object',
									 articleName => 'article1'
								   }
						  ],
						  HASA => [
									{
									  object      => 'Object',
									  articleName => 'articleName3'
									},
						  ]
	   }
	)
);
ok( !$r->success, "Object registration correctly failed" )
  or diag(
	"Shouldn't be possible to register Object with an invalid character in its name!"
	  . $r->message );
$r = $C->deregisterObjectClass( objectType => "Rubbish_'Art" );

# confirm that we cannot register a datatype with : characters in its name
$r = $C->registerObjectClass(
        (
           objectType    => "Rubbish:Art",
           description   => "a human-readable description of the object",
           contactEmail  => 'your@email.address',
           authURI       => "test.suite.com",
           Relationships => {
                                                  ISA => [
                                                                   {
                                                                         object      => 'Object',
                                                                         articleName => 'article1'
                                                                   }
                                                  ],
                                                  HASA => [
                                                                        {
                                                                          object      => 'Object',
                                                                          articleName => 'articleName3'
                                                                        },
                                                  ]
           }
        )
);
ok( !$r->success, "Object registration correctly failed" )
  or diag(
        "Shouldn't be possible to register Object with a ':' character in its name!"
          . $r->message );
$r = $C->deregisterObjectClass( objectType => "Rubbish:Art" );

# confirm that we cannot register a datatype with odd characters in its name
$r = $C->registerObjectClass(
	(
	   objectType    => "Rubbish_\"Art",
	   description   => "a human-readable description of the object",
	   contactEmail  => 'your@email.address',
	   authURI       => "test.suite.com",
	   Relationships => {
						  ISA => [
								   {
									 object      => 'Object',
									 articleName => 'article1'
								   }
						  ],
						  HASA => [
									{
									  object      => 'Object',
									  articleName => 'articleName3'
									},
						  ]
	   }
	)
);
ok( !$r->success, "Object registration correctly failed" )
  or diag(
	"Shouldn't be possible to register Object with an invalid character in its name!"
	  . $r->message );
$r = $C->deregisterObjectClass( objectType => "Rubbish_\"Art" );

# confirm that we cannot register a datatype with odd characters in its name
$r = $C->registerObjectClass(
        (
           objectType    => "Rubbish_\%Art",
           description   => "a human-readable description of the object",
           contactEmail  => 'your@email.address',
           authURI       => "test.suite.com",
           Relationships => {
                                                  ISA => [
                                                                   {
                                                                         object      => 'Object',
                                                                         articleName => 'article1'
                                                                   }
                                                  ],
                                                  HASA => [
                                                                        {
                                                                          object      => 'Object',
                                                                          articleName => 'articleName3'
                                                                        },
                                                  ]
           }
        )
);
ok( !$r->success, "Object registration correctly failed" )
  or diag(
        "Shouldn't be possible to register Object with an invalid character in its name!"
          . $r->message );
$r = $C->deregisterObjectClass( objectType => "Rubbish_\%Art" );

# confirm that we cannot register a datatype with odd characters in its name
$r = $C->registerObjectClass(
	(
	   objectType    => "Rubbish_/Art",
	   description   => "a human-readable description of the object",
	   contactEmail  => 'your@email.address',
	   authURI       => "test.suite.com",
	   Relationships => {
						  ISA => [
								   {
									 object      => 'Object',
									 articleName => 'article1'
								   }
						  ],
						  HASA => [
									{
									  object      => 'Object',
									  articleName => 'articleName3'
									},
						  ]
	   }
	)
);
ok( !$r->success, "Object registration correctly failed" )
  or diag(
	"Shouldn't be possible to register Object with an invalid character in its name!"
	  . $r->message );
$r = $C->deregisterObjectClass( objectType => "Rubbish_/Art" );


##############     NAMESPACE REGISTRATION     ##############
# Register a new namespace
my %Namespace = (
				  namespaceType => 'RubbishNamespace',
				  authURI       => 'your.authority.URI',
				  description   => "human readable description of namespace",
				  contactEmail  => 'your@address.here'
);
$r = $C->registerNamespace(%Namespace);
ok( $r->success, "Name space registration successful" )
  or diag( "Name space registration failure: " . $r->message );

# check for invalid namespace registration

my %InvalidNamespace = (
                                  namespaceType => 'Rubbish:Namespace',
                                  authURI       => 'your.authority.URI',
                                  description   => "human readable description of namespace",
                                  contactEmail  => 'your@address.here'
);
$r = $C->registerNamespace(%InvalidNamespace);
ok( !$r->success, "Name space registration correctly failed with a ':' in the name" )
  or diag( "Name space registration incorrectly succeeded with a ':' in the name: " . $r->message );
$C->deregisterNamespace(%InvalidNamespace);

############     SERVICE-TYPE REGISTRATION        #############
#this registration should fail => empty relationship type
my %ServiceType = (
					serviceType   => "RubbishyServiceNoParent",
					description   => "a human-readable description of the service",
					contactEmail  => 'your@email.address',
					authURI       => "test.suite.com",
					Relationships => { ISA => [''] }
);
$r = $C->registerServiceType(%ServiceType);
ok( $r->success == 0,
	"\nService Type registration unsuccessful when no parent specified!" )
  or diag(
	   "\nService Type registration was successful when no parent type was specified:\n"
		 . $r->message );

%ServiceType = (
				 serviceType   => "RubbishyService",
				 description   => "a human-readable description of the service",
				 contactEmail  => 'your@email.address',
				 authURI       => "test.suite.com",
				 Relationships => { ISA => ['Retrieval'] }
);
$r = $C->registerServiceType(%ServiceType);
ok( $r->success, "Service Type registration successful" )
  or diag( "Service Type registration failure: " . $r->message );

$r = $C->Relationships( objectType => $Obj{objectType} );
isa_ok( $r, "HASH", "Relationship types hash" )
  or diag("Object Relationships didn't return a hashref for object types");
isa_ok( $r->{'isa'}, 'ARRAY' )
  or diag("Object Relationships didn't return a hash of arrayrefs");
isa_ok( $r->{'isa'}->[0], "HASH" )
  or diag("Object Relationships didn't return a hash of arrayrefs of hasrefs");
is( $r->{'isa'}->[0]->{term}, "Object" )
  or diag("Object Relationships(objectType) doesn't have the right parentage.");

$r = $C->Relationships( serviceType => $ServiceType{serviceType} );
isa_ok( $r, "HASH", "Relationship types hash" )
  or diag("Service Relationships didn't return a hashref for service types");
isa_ok( $r->{'isa'}, 'ARRAY' )
  or diag("Service Relationships didn't return a hash of arrayrefs for services");
isa_ok( $r->{'isa'}->[0], "HASH" )
  or diag("Service Relationships didn't return a hash of arrayrefs of hasrefs");
is( $r->{'isa'}->[0]->{term}, $ServiceType{Relationships}->{ISA}->[0] )
  or diag("Relationships (serviceType) doesn't have the right parentage.");

# check for invalid service type
my %InvalidServiceType = (
                                 serviceType   => "Rubbishy:Service",
                                 description   => "a human-readable description of the service",
                                 contactEmail  => 'your@email.address',
                                 authURI       => "test.suite.com",
                                 Relationships => { ISA => ['Retrieval'] }
);
$r = $C->registerServiceType(%InvalidServiceType);
ok( !$r->success, "Service Type registration with a ':' in the name correctly failed" )
  or diag( "Service Type registration incorrectly succeeded with a ':' in the name: " . $r->message );
$C->deregisterServiceType(%InvalidServiceType);

#############        SERVICE INSTANCE REGISTRATION      ###########
# Set up a service registration hash. We'll mess with it piece by piece in the next several tests,
# to make sure that registration is successful when you play by the rules.
my %RegSmpl = (
	serviceName  => "1myfirstservice",
	serviceType  => "Retrieval",
	authURI      => "test.suite.com",
	contactEmail => 'your@mail.address',
	description  => "this is my first service",
	category     => "moby",
	URL          => "http://illuminae/cgi-bin/service.pl",
	input        => [
			   [ 'articleName1', [ Object => ['RubbishNamespace'] ] ],    # Simple
	],
	output => [
				[ 'articleName2', [ String => ['RubbishNamespace'] ] ],    # Simple
	],
	secondary => {
				   parametername1 => {
									   datatype    => 'Integer',
									   description => "some parameter here",
									   default     => 0,
									   max         => 10,
									   min         => -10,
									   enum        => [ -10, 10, 0 ]
				   }
	}
);

# Service name can't start with numeric
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
"Service registration correctly failed with number as first character in serviceName"
  )
  or diag(
"Service registration should have failed with numerical first character in serviceName: "
	  . $r->message );

# Service name can't include non-alphanumeric
$RegSmpl{serviceName} = "myf]irstservice";
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed with ']' as character in serviceName" )
  or
  diag( "Service registration shuld have failed with invalid character in serviceName: "
		. $r->message );

# Service name can include an underscore
$RegSmpl{serviceName} = "myf_irstservice";
$r = $C->registerService(%RegSmpl);
ok( $r->success,
	"Service registration correctly succeeded with a '_' as character in serviceName" )
  or diag(
"Service registration failed on an underscore in the service name (underscore is valid)"
	  . $r->message );

# now get rid of it
$r = $C->deregisterService( serviceName => 'myf_irstservice',
							authURI     => 'test.suite.com' );

$RegSmpl{serviceName} = "myfirstservice";    # Fix serviceName
$RegSmpl{secondary} = {
	parametername1 => {
					  datatype    => 'INTEGER',               # Break parameter datatype
					  description => "some parameter here",
					  default     => 0,
					  max         => 10,
					  min         => -10,
					  enum        => [ -10, 10, 0 ]
	}
};
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing secondary datatype format" )
  or diag( "Service registration failure: " . $r->message );

$RegSmpl{secondary} = {
	parametername1 => {
						datatype    => 'Integer',               # Fix parameter datatype
						description => "some parameter here",
						default     => 0,
						max         => 10,
						min         => -10,
						enum        => [ -10, 10, 0 ]
	}
};
$RegSmpl{input} =
  [ [ '', [ Object => ['RubbishNamespace'] ] ] ];    # Break input (no articleName)

# Input must have  articleName
$r = $C->registerService(%RegSmpl);
ok( !$r->success, "Service registration correctly failed testing lack of articleName" )
  or diag(
"Service registration was supposed to fail due to lack of articleName on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a !
$RegSmpl{input} =
  [ [ 'my!articlename', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a !) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a ~
$RegSmpl{input} =
  [ [ 'myarticlename~', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a ~) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a @
$RegSmpl{input} =
  [ [ 'myarticlename\@', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a @) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a #
$RegSmpl{input} =
  [ [ '\#myarticlename', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a #) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a $
$RegSmpl{input} =
  [ [ 'myarticlename\$', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a \$) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a ^
$RegSmpl{input} =
  [ [ 'myarticlename^', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a ^) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a *
$RegSmpl{input} =
  [ [ 'myarticlename*', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a *) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a (
$RegSmpl{input} =
  [ [ 'myarticlename(', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a () on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a )
$RegSmpl{input} =
  [ [ 'myarticlename)', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a )) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a +
$RegSmpl{input} =
  [ [ 'myarticlename+', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a +) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a =
$RegSmpl{input} =
  [ [ 'myarticlename=', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a =) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a \
$RegSmpl{input} =
  [ [ 'myarticlename\\', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a \\) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a |
$RegSmpl{input} =
  [ [ 'myarticlename|', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a |) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a {
$RegSmpl{input} =
  [ [ 'myarticlename{', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a {) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a }
$RegSmpl{input} =
  [ [ 'myarticlename}', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a }) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a ;
$RegSmpl{input} =
  [ [ 'myarticlename;', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a ;) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a :
$RegSmpl{input} =
  [ [ 'myarticlename:', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a :) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a "
$RegSmpl{input} =
  [ [ 'myarticlename"', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a \") on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a ,
$RegSmpl{input} =
  [ [ 'myarticlename,', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a ,) on input, but didn't: "
	  . $r->message );

# Invalid input articlename - contains a .
$RegSmpl{input} =
  [ [ 'myarticlename.', [ Object => ['RubbishNamespace'] ] ] ]
  ;                                                  # Break input (invalid articleName)
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration correctly failed testing an invalid articleName" )
  or diag(
"Service registration was supposed to fail due to an invalid articleName (contained a .) on input, but didn't: "
	  . $r->message );

# Cannot have multiple Simples as part of Collection
$RegSmpl{input} = [
	[
	   'articleNameMultiSimples',
	   [
		  [
			 Object => ['RubbishNamespace'],
			 String => ['RubbishNamespace']
		  ]
	   ]
	]    # Simple
];
$RegSmpl{output} =
  [ [ 'articleNameSimpleSingle', [ String => ['RubbishNamespace'] ] ] ];    # Simple
$RegSmpl{serviceName} = "myfirstservicemultiplesimples";
$r = $C->registerService(%RegSmpl);
ok( !$r->success,
	"Service registration of two Simples in a Collection successfully failed" )
  or diag(
"Service registration should have failed when registering two Simples in a Collection: "
	  . $r->message );

# OK - now we'll play honest, this test should pass.
$RegSmpl{input}  = [ [ 'articleName1', [ Object => ['RubbishNamespace'] ] ] ];
$RegSmpl{output} = [ [ 'articleName2', [ String => ['RubbishNamespace'] ] ] ];
$r = $C->registerService(%RegSmpl);
ok( $r->success, "Service registration successful" )
  or diag( "Service registration failure: " . $r->message );

###TEST A SERVICE THAT CONSUMES A BOOLEAN SECONDARY PARAMETER########

my %boolSimpl = (
	serviceName  => "mySecondaryTestservice",
	serviceType  => "Retrieval",
	authURI      => "test.suite.com",
	contactEmail => 'your@mail.address',
	description  => "this is my first secondary service",
	category     => "moby",
	URL          => "http://illuminae/cgi-bin/service.pl",
	input        => [
			   [ 'articleName1', [ Object => ['RubbishNamespace'] ] ],    # Simple
	],
	output => [
				[ 'articleName2', [ String => ['RubbishNamespace'] ] ],    # Simple
	],
	secondary => {
		parametername1 => {
			  datatype    => 'BOOLEAN',                              #bad parameter type
			  description => "some parameter here",
			  default     => 'false'
		}
	}
);

#attempt to register this service, should fail
$r = $C->registerService(%boolSimpl);
ok( !$r->success,
"Service registration correctly failed because of the parameter type BOOLEAN in the secondary input."
  )
  or
  diag( "Service registration succeeded on a parameter type of BOOLEAN (should fail) "
		. $r->message );

# fix the parameter type
$boolSimpl{secondary} = {
	parametername1 => {
						datatype    => 'Boolean',               # Fix parameter datatype
						description => "some parameter here",
						default     => 'false'
	}
};

# register it now
$r = $C->registerService(%boolSimpl);
ok( $r->success,
	"Service registration correctly succeeded with secondary parameter type 'Boolean'."
  )
  or diag(
"Service registration incorrectly failed on a secondary parameter type of Boolean (should not fail) "
	  . $r->message );

# now get rid of it
$r = $C->deregisterService( serviceName => 'mySecondaryTestservice',
							authURI     => 'test.suite.com' );
################# SERVICE RETRIEVAL ##################
# Service has now been succesfully registered. Can we find it, and is the description correct.
# test 11 - find by auth & name
my ( $si, $ri ) =
  $C->findService( serviceName => $RegSmpl{serviceName},
				   authURI     => $RegSmpl{authURI} );
is( $ri, undef, "Service discovery successful" )
  or diag("Service discovery failure");

isa_ok( $si, 'ARRAY' ) or diag("findService didn't return an array ref");
is( scalar(@$si), 1 ) or diag("findService found wrong number of services");
my $SI = shift @$si;
isa_ok( $SI, 'MOBY::Client::ServiceInstance' )
  or diag("findService didn't return a MOBY::Client::ServiceInstance");
isa_ok( $SI->input, 'ARRAY' ) or diag("ServiceInstance object input is not a listref");
isa_ok( $SI->output, 'ARRAY' )
  or diag("ServiceInstance object output is not a listref");
is( $SI->name, $RegSmpl{serviceName} ) or diag("servicename wrong");
is( $SI->authoritative, defined $RegSmpl{authoritative} ? $RegSmpl{authoritative} : 0 )
  or diag("service incorrectly reported to be authoritative");
is( $SI->authority,    $RegSmpl{authURI} )      or diag("authURI incorrect");
is( $SI->type,         $RegSmpl{serviceType} )  or diag("service type incorrect");
is( $SI->description,  $RegSmpl{description} )  or diag("service description wrong");
is( $SI->URL,          $RegSmpl{URL} )          or diag("service URL incorrect");
is( $SI->contactEmail, $RegSmpl{contactEmail} ) or diag("contact email incorrect");
is( $SI->category,     $RegSmpl{category} )     or diag("service category incorrect");

my @ins  = @{ $SI->input };
my @outs = @{ $SI->output };
my @secs = @{ $SI->secondary };
is( scalar(@ins), scalar @{ $RegSmpl{input} } )
  or diag("incorrect number of inputs in service instance");
is( scalar(@outs), scalar @{ $RegSmpl{output} } )
  or diag("incorrect number of outputs in service instance");
is( scalar(@secs), scalar keys %{ $RegSmpl{secondary} } )
  or diag("incorrect number of secondary in service instance");

my $in  = shift @ins;
my $out = shift @outs;
my $sec = shift @secs;

isa_ok( $in, 'MOBY::Client::SimpleArticle' )
  or diag("->inputs did not return a MOBY::Client::SimpleArticle input object");
isa_ok( $out, 'MOBY::Client::SimpleArticle' )
  or diag("->outputs did not return a MOBY::Client::SimpleArticle output object");
isa_ok( $sec, 'MOBY::Client::SecondaryArticle' )
  or diag("->secondaries did not return a MOBY::Client:Secondary input object");

is( $in->objectType, $RegSmpl{input}->[0]->[1]->[0] )
  or diag("simple input type reported incorrectly");
is( $in->articleName, $RegSmpl{input}->[0]->[0] )
  or diag("simple input article name reported incorrectly");
isa_ok( $in->namespaces, 'ARRAY' )
  or diag("simple input namespaces not returned as an arrayref");
my @ns = @{ $in->namespaces };
is( scalar(@ns), scalar @{ $RegSmpl{input}->[0]->[1]->[1] } )
  or diag("simple input reporting wrong number of namespaces");
my $ns = shift @ns;
is( $ns, $RegSmpl{input}->[0]->[1]->[1]->[0] )
  or diag("simple input reporting wrong namespace");

is( $out->objectType, $RegSmpl{output}->[0]->[1]->[0] )
  or diag("simple output type reported incorrectly");
is( $out->articleName, $RegSmpl{output}->[0]->[0] )
  or diag("simple output article name reported incorrectly");
isa_ok( $out->namespaces, 'ARRAY' )
  or diag("simple output namespaces not returned as an arrayref");
@ns = @{ $out->namespaces };
is( scalar(@ns), scalar @{ $RegSmpl{output}->[0]->[1]->[1] } )
  or diag("simple output reporting wrong number of namespaces");
is( $ns[0], $RegSmpl{output}->[0]->[1]->[1]->[0] )
  or diag("simple output reporting wrong namespace");

# Check Secondary Article (parameter)
is( $sec->articleName, ( keys %{ $RegSmpl{secondary} } )[0] )
  or diag("secondary article reporting wrong article name");
my $Reg_sec = $RegSmpl{secondary}->{ $sec->articleName };
is( $sec->datatype, $Reg_sec->{datatype} )
  or diag("secondary article reporting wrong datatype");

#diag("SECONDARY: " . Dumper($Reg_sec));
is( $sec->default, $Reg_sec->{default} )
  or diag("secondary article reporting wrong default");
is( $sec->max, $Reg_sec->{max} ) or diag("secondary article reporting wrong max");
is( $sec->min, $Reg_sec->{min} ) or diag("secondary article reporting wrong min");
is( $sec->description, $Reg_sec->{description} )
  or diag("secondary article reporting wrong description");
isa_ok( $sec->enum, 'ARRAY' ) or diag("enum is not returning an array ref");
my @enum = @{ $sec->enum };
is( scalar(@enum), scalar @{ $Reg_sec->{enum} } )
  or diag("enum not returning correct number of elements");

# Check that all values registered are contained in the reported enum component.
for my $e ( @{ $Reg_sec->{enum} } ) {
	ok( grep( /$e/, @enum ), "Enum missing" )
	  or diag("Value '$e' is missing from enum returned by SecondaryArticle");
}

# Check that no extra values are reported, other than what was originally registered.
for my $e (@enum) {
	ok( grep( /$e/, @{ $Reg_sec->{enum} } ), "Extra enum" )
	  or diag(
"Value '$e' returned by SecondaryArticle->{enum} but not specified in registration." );
}

######################       SERVICE WITH COLLECTIONS       #################
# Now register a second service, this time taking Collections for input and output.
my %RegColl = (
	serviceName  => "mysecondservice",
	serviceType  => "Retrieval",
	authURI      => "test.suite.com",
	contactEmail => 'your@mail.address',
	description  => "this is my second service",
	category     => "moby",
	URL          => "http://illuminae/cgi-bin/service.pl",
	input        => [
			 [ 'articleName1', [ [ Object => ['RubbishNamespace'] ] ] ],    # Collection
	],
	output => [
			 [ 'articleName2', [ [ String => ['RubbishNamespace'] ] ] ],    # Collection
	],
	secondary => {
				   parametername1 => {
									   datatype => 'Integer',
									   default  => 0,
									   max      => 10,
									   min      => -10,
									   enum     => [ -10, 10, 0 ]
				   }
	}
);

$r = $C->registerService(%RegColl);
ok( $r->success, "Service registration of collections successful" )
  or diag( "Service registration of collections failure: " . $r->message );

# Find the second service, and test it
( $si, $r ) =
  $C->findService( serviceName => $RegColl{serviceName},
				   authURI     => $RegColl{authURI} );
is( $r, undef, "Service discovery of collections successful" )
  or diag("Service discovery of collections failure");

isa_ok( $si, 'ARRAY' )
  or diag("findService with collections didn't return an array ref");
is( scalar(@$si), 1 ) or diag("findService with collections found too many services");
$SI = shift @$si;

#print STDERR "$SI";
isa_ok( $SI, 'MOBY::Client::ServiceInstance' )
  or diag("findService collections didn't return a MOBY::Client::ServiceInstance");
isa_ok( $SI->input, 'ARRAY' )
  or diag("ServiceInstance object input is not a listref (collections test)");
isa_ok( $SI->output, 'ARRAY' )
  or diag("ServiceInstance object output is not a listref (collections test)");
is( $SI->name, $RegColl{serviceName} ) or diag("servicename wrong (collections test)");
is( $SI->authoritative, defined $RegColl{authoritative} ? $RegColl{authoritative} : 0 )
  or diag("service reported to be incorrectly authoritative (collections test)");
is( $SI->authority, $RegColl{authURI} ) or diag("authURI incorrect (collections test)");
is( $SI->type, $RegColl{serviceType} )
  or diag("service type incorrect (collections test)");
is( $SI->description, $RegColl{description} )
  or diag("service description wrong (collections test)");
is( $SI->URL, $RegColl{URL} ) or diag("service URL incorrect (collections test)");
is( $SI->contactEmail, $RegColl{contactEmail} )
  or diag("contact email incorrect (collections test)");
is( $SI->category, $RegColl{category} )
  or diag("service category incorrect (collections test)");

@ins  = @{ $SI->input };
@outs = @{ $SI->output };
@secs = @{ $SI->secondary };
is( scalar(@ins), scalar @{ $RegColl{input} } )
  or diag("incorrect number of inputs in service instance (collections test)");
is( scalar(@outs), scalar @{ $RegColl{output} } )
  or diag("incorrect number of outputs in service instance (collections test)");
is( scalar(@secs), scalar keys %{ $RegColl{secondary} } )
  or diag("incorrect number of secondary in service instance (collections test)");

$in  = shift @ins;
$out = shift @outs;
$sec = shift @secs;

isa_ok( $in, 'MOBY::Client::CollectionArticle' )
  or diag(
"->inputs did not return a MOBY::Client::Collection input object or client parser failed for MOBY::Client::CollectionArticle"
  );

isa_ok( $out, 'MOBY::Client::CollectionArticle' )
  or diag(
"->outputs did not return a MOBY::Client::CollectionArticle output object or client parser failed for MOBY::Client::CollectionArticle"
  );

isa_ok( $sec, 'MOBY::Client::SecondaryArticle' )
  or diag("->secondaries did not return a MOBY::Client::SecondaryArticle input object");

is( $in->articleName, $RegColl{input}->[0]->[0] )
  or diag("simple input article name reported incorrectly (collections test)");
is( $out->articleName, $RegColl{output}->[0]->[0] )
  or diag("simple output article name reported incorrectly (collections test)");

isa_ok( $in->Simples, 'ARRAY' )
  or diag("->Simples did not return an arrayref  (collections test)");
isa_ok( $out->Simples, 'ARRAY' )
  or diag("->Simples did not return an arrayref  (collections test)");
my $simplesin  = $in->Simples;
my $simplesout = $out->Simples;

is( scalar(@$simplesin), scalar @{ $RegColl{input}->[0]->[1] } )
  or diag("->Simples returning wrong number of simple inputs in the collection");
is( scalar(@$simplesout), scalar @{ $RegColl{output}->[0]->[1] } )
  or diag("->Simples returning wrong number of simple outputs in the collection");

# Check that reported input matches input as registered
$in = shift @$simplesin;
my $reg_in = $RegColl{input}->[0]->[1]->[0];
is( $in->objectType, $reg_in->[0] )
  or diag("simple input type reported incorrectly (collections test)");
isa_ok( $in->namespaces, 'ARRAY' )
  or diag("simple input namespaces not returned as an arrayref (collections test)");
@ns = @{ $in->namespaces };
is( scalar(@ns), scalar @{ $reg_in->[1] } )
  or diag("simple input reporting wrong number of namespaces (collections test)");
$ns = shift @ns;
is( $ns, $reg_in->[1]->[0] )
  or diag("simple input reporting wrong namespace (collections test)");

# Check that reported output matches output as registered
my $reg_out = $RegColl{output}->[0]->[1]->[0];
$out = shift @$simplesout;
is( $out->objectType, $reg_out->[0] )
  or diag("simple output type reported incorrectly (collections test)");
isa_ok( $out->namespaces, 'ARRAY' )
  or diag("simple output namespaces not returned as an arrayref (collections test)");
@ns = @{ $out->namespaces };
is( scalar(@ns), scalar @{ $reg_out->[1] } )
  or diag("simple output reporting wrong number of namespaces (collections test)");
$ns = shift @ns;
is( $ns, $reg_out->[1]->[0] )
  or diag("simple output reporting wrong namespace (collections test)");

#$names{$AuthURI} = [serviceName_1, serviceName_2, serviceName3...]
############################
# Get all service names
$r = $C->retrieveServiceNames();
isa_ok( $r, "HASH", "Service Names Hash" )
  or diag("retrieveServiceNames didn't return a hashref");
isa_ok( $r->{ $RegSmpl{authURI} }, 'ARRAY' )
  or diag("retrieveServiceNames didn't return a hasref of arrayrefs");
my @serviceNames = @{ $r->{ $RegSmpl{authURI} } };
ok( grep( /myfirstservice/, @serviceNames ), "'myfirstservice' not found" )
  or diag("retrieveServiceNames didn't return myfirstservice");
ok( grep( /mysecondservice/, @serviceNames ), "'mysecondservice' not found" )
  or diag("retrieveServiceNames didn't return mysecondservice");

$r = $C->retrieveServiceNames( as_lsid => 1 );
isa_ok( $r, "HASH", "Service Names Hash" )
  or diag("retrieveServiceNames as lsid didn't return a hashref");
isa_ok( $r->{ $RegSmpl{authURI} }, 'ARRAY' )
  or diag("retrieveServiceNames as lsid didn't return a hasref of arrayrefs");
my @serviceNamesLSID = @{ $r->{ $RegSmpl{authURI} } };
ok( grep( /urn\:lsid/, @serviceNamesLSID ), "'myfirstservice' lsid not found" )
  or diag("retrieveServiceNames as LSID didn't return LSIDs");

$r = $C->deregisterService( serviceName => $RegSmpl{serviceName},
							authURI     => $RegSmpl{authURI} );
ok( $r->success, "Service deregistration successful" )
  or diag( "Service deregistration failure: " . $r->message );

# Try to deregister it again, after it's already been deregistered
$r = $C->deregisterService( serviceName => $RegSmpl{serviceName},
							authURI     => $RegSmpl{authURI} );
ok( !$r->success, "Service deregistration successful" )
  or diag( "Service re-deregistration success (should have failed): " . $r->message );

$r = $C->deregisterService( serviceName => $RegColl{serviceName},
							authURI     => $RegColl{authURI} );
ok( $r->success, "Service deregistration successful" )
  or diag( "Service deregistration failure (second service): " . $r->message );

# TESTS FOR ONTOLOGY TRAVERSAL AND SO ON
$r = $C->retrieveObjectDefinition( objectType => $Obj{objectType} );
isa_ok( $r, "HASH", "Object definition returns hashref" )
  or diag("Object definition did not return as a hashref");
is( $r->{objectType}, $Obj{objectType}, "Object reporting correct type" )
  or diag("Object definition did not report correct type");
is( $r->{description}, $Obj{description}, "Object reporting correct desccription" )
  or diag("Object definition did not report correct desc");

is( $r->{contactEmail}, $Obj{contactEmail}, "Object reporting correct email" )
  or diag("Object definition did not report correct email");
is( $r->{authURI}, $Obj{authURI}, "Object reporting correct auth" )
  or diag("Object definition did not report correct auth");
isa_ok( $r->{Relationships}, "HASH", "Object reporting correct Relationships hash" )
  or diag("Object definition did not report hash on relationships");
my %rel = %{ $r->{Relationships} };

isa_ok( $rel{'urn:lsid:biomoby.org:objectrelation:isa'},
		'ARRAY', "Object reporting correct ISA as arrayref" )
  or diag("Object definition did not report ISA arrayref");

isa_ok( $rel{'urn:lsid:biomoby.org:objectrelation:hasa'},
		'ARRAY', "Object reporting correct HASA as arrayref" )
  or diag("Object definition did not report HASA arrayref");

my $isa  = shift @{ $rel{'urn:lsid:biomoby.org:objectrelation:isa'} };
my $hasa = shift @{ $rel{'urn:lsid:biomoby.org:objectrelation:hasa'} };
isa_ok( $isa, 'HASH', "" )
  or diag("Object didn't return an array of hashes for its ISA relationships");
isa_ok( $hasa, 'HASH', "" )
  or diag("Object didn't return an array of hashes for its HASA relationships");
is( ${$isa}{object}, $Obj{Relationships}->{ISA}->[0]->{object} )
  or diag("ISA reporting wrong object name");
is( ${$isa}{articleName}, $Obj{Relationships}->{ISA}->[0]->{articleName} )
  or diag("ISA reporting wrong articleName for object");
is( ${$hasa}{object}, $Obj{Relationships}->{HASA}->[0]->{object} )
  or diag("HASA reporting wrong object name");
is( ${$hasa}{articleName}, $Obj{Relationships}->{HASA}->[0]->{articleName} )
  or diag("HASA reporting wrong articleName for object");

#TODO: {
#  local $TODO = "LSIDs will be time-stamped in near future.";
like(
	  $r->{objectLSID},
qr/urn:lsid:biomoby.org:objectclass:$Obj{objectType}:\d\d\d\d\-\d\d\-\d\dT\d\d-\d\d-\d\d/
) or diag("Object class LSID reported incorrectly");

#}

$r = $C->retrieveNamespaces();
isa_ok( $r, "HASH", "Namespace hash" )
  or diag("retrieveNamespaces didn't return a hashref");
is( $r->{RubbishNamespace}, $Namespace{description} )
  or diag("namespace definition not returned correctly");

$r = $C->retrieveServiceTypes();
isa_ok( $r, "HASH", "Service types hash" )
  or diag("retrieveServiceTypes didn't return a hashref");
is( $r->{ $ServiceType{serviceType} }, $ServiceType{description} )
  or diag("service type description not returned correctly");

$r = $C->retrieveObjectNames();
isa_ok( $r, "HASH", "Object types hash" )
  or diag("retrieveObjectNames didn't return a hashref");
is( $r->{ $Obj{objectType} }, $Obj{description} )
  or diag("object name definition not returned correctly");

# Deregister objecttype, servicetype, and namespace
$r = $C->deregisterObjectClass( objectType => $Obj{objectType} );
ok( $r->success, "Object deregistration successful" )
  or diag( "Object deregistration failure: " . $r->message );

$r = $C->deregisterServiceType( serviceType => $ServiceType{serviceType} );
ok( $r->success, "Service Type deregistration successful" )
  or diag( "Service Type deregistration failure: " . $r->message );

$r = $C->deregisterNamespace( namespaceType => $Namespace{namespaceType} );
ok( $r->success, "namespace deregistration successful" )
  or diag( "namespace deregistration failure: " . $r->message );

