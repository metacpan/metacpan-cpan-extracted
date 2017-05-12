#$Id: OntologyServer.pm,v 1.3 2010/06/24 18:23:16 kawas Exp $

=head1 NAME

MOBY::Client::OntologyServer - A client interface to the Ontology
Server at MOBY Central

=cut

=head1 SYNOPSIS

 use MOBY::Client::OntologyServer;
 my $OS = MOBY::Client::OntologyServer->new();

 my ($success, $message, $existingURI) = $OS->objectExists(term => "Object");
 my ($success, $message, $existingURI) = $OS->serviceExists(term => "Retrieval");
 my ($success, $message, $existingURI) = $OS->namespaceExists(term => "NCBI_gi");
 my ($success, $message, $existingURI) = $OS->relationshipExists(term => "ISA");

 if ($success){
     print "object exists and it has the LSID $existingURI\n";
 } else {
    print "object does not exist; additional message from server: $message\n";
 }


=cut

=head1 DESCRIPTION

This module is used primarily as a way of dealing with the
flexibility MOBY allows in the use of "common" names
versus LSID's.  Calling the ontology server using this
module will return the LSID of whatever it is you send it,
even if you send the LSID itself.  As such, you can now simply
filter your terms through the ontologyserver and know that
what is returned will be an LSID, and skip the checking step
yourself.


=head1 PROXY SERVERS

If your site uses a proxy server, simply set the environment variable
MOBY_PROXY=http://your.proxy.server/address

=cut

=head1 AUTHORS


Mark Wilkinson (markw at illuminae.com)
Nina Opushneva (opushneva at yahoo.ca)

BioMOBY Project:  http://www.biomoby.org


=cut

=head1 METHODS


=head2 new

 Title     :	new
 Usage     :	my $OS = MOBY::OntologyServer->new(%args)
 Function  :	
 Returns   :	MOBY::OntologyServer object
 Args      :    host =>  URL to ontolgy_server script (default http://mobycentral.cbr.nrc.ca/cgi-bin/OntologyServer.cgi)
                proxy => URL to an HTTP proxy server if necessarray (optional)

=cut

package MOBY::Client::OntologyServer;
use strict;
use Carp;
use vars qw($AUTOLOAD);
use LWP::UserAgent;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

my $debug = 0;
my $user_agent = "MOBY-OntologyServer-Perl"; 

{

	#Encapsulated class data
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		host => ['' ,'read/write'],
		proxy => [ undef, 'read/write' ],
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
}

sub new {
	my ( $caller, %args ) = @_;
	my $caller_is_obj = ref( $caller );
	my $class         = $caller_is_obj || $caller;
	my $self          = bless {}, $class;
	foreach my $attrname ( $self->_standard_keys ) {
		if ( exists $args{$attrname} && defined $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		} elsif ( $caller_is_obj ) {
			$self->{$attrname} = $caller->{$attrname};
		} else {
			$self->{$attrname} = $self->_default_for( $attrname );
		}
	}
	# get ontology server if not defined in ENV
	do {
        my ($ontologyserver) = _getOntologyServer();  # get default from moby central
        $self->host($ontologyserver) if $ontologyserver;
    } unless $ENV{MOBY_ONTOLOGYSERVER};
    # use the ENV version if it exists
	$self->host($ENV{MOBY_ONTOLOGYSERVER}) if ($ENV{MOBY_ONTOLOGYSERVER});  # override with user preference if set in their environment
	return undef unless $self->host;
	return $self;
}


sub _getOntologyServer {
	use LWP::UserAgent;
	use HTTP::Request::Common qw(HEAD);
 	my $ua = LWP::UserAgent->new;
	my $req = HEAD 'http://biomoby.org/ontologyserver';
	my $res = $ua->simple_request($req);
	my $ontologyserver = $res->header('location');
	return $ontologyserver;
}

=head2 objectExists

=cut

sub objectExists {
	my ( $self, %args ) = @_;
	my $term = $args{'term'};
	$term =~ s/^moby://;    # if the term is namespaced, then remove that
	my $ua = $self->getUserAgent;
	my $req = HTTP::Request->new( POST => $self->host );
	$req->content( "objectExists=$term" );
	my $res = $ua->request( $req );
	if ( $res->is_success ) {
		return split "\n", $res->content;
	} else {
		return ( 0, "Request Failed for unknown reasons", "" );
	}
}

=head2 serviceExists

=cut

sub serviceExists {
	my ( $self, %args ) = @_;
	my $term = $args{'term'};
	$term =~ s/^moby://;    # if the term is namespaced, then remove that
	my $ua = $self->getUserAgent;
	my $req = HTTP::Request->new( POST => $self->host );
	$req->content( "serviceExists=$term" );
	my $res = $ua->request( $req );
	if ( $res->is_success ) {
		return split "\n", $res->content;
	} else {
		return ( 0, "Request Failed for unknown reasons", "" );
	}
}

=head2 namespaceExists

=cut

sub namespaceExists {
	my ( $self, %args ) = @_;
	my $term = $args{'term'};
	$term =~ s/^moby://;    # if the term is namespaced, then remove that
	my $ua = $self->getUserAgent;
	my $req = HTTP::Request->new( POST => $self->host );
	$req->content( "namespaceExists=$term" );
	my $res = $ua->request( $req );
	if ( $res->is_success ) {
		return split "\n", $res->content;
	} else {
		return ( 0, "Request Failed for unknown reasons", "" );
	}
}

=head2 relationshipExists

=cut

sub relationshipExists {
	my ( $self, %args ) = @_;
	my $term = $args{'term'};
	my $ontology = $args{'ontology'};
	$term =~ s/^moby://;    # if the term is namespaced, then remove that
	my $ua = $self->getUserAgent;
	my $req = HTTP::Request->new( POST => $self->host );
	$req->content( "relationshipExists=$term&ontology=$ontology" );
	my $res = $ua->request( $req );
	if ( $res->is_success ) {
		return split "\n", $res->content;
	} else {
		return ( 0, "Request Failed for unknown reasons", "" );
	}
}

sub getUserAgent {
	my ( $self, @args ) = @_;
	my $ua    = LWP::UserAgent->new();
	$ua->agent($user_agent);
	my $proxy = $ENV{MOBY_PROXY}
	  if $ENV{MOBY_PROXY};    # first check the environment
	$proxy = $self->proxy
	  if $self->proxy
	  ; # but if the object was initialized with a proxy argument then use that instead
	if ( $proxy ) {
		$ua->proxy( 'http', $proxy );
	}
	return $ua;
}
sub DESTROY { }

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
1;
