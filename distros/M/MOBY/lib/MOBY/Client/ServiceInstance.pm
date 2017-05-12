package MOBY::Client::ServiceInstance;
use strict;
use Carp;
use vars qw($AUTOLOAD @ISA);
use MOBY::Client::MobyUnitTest;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Client::ServiceInstance - a small object describing a MOBY service

=head1 SYNOPSIS

 use MOBY::Client::ServiceInstance;
 my $Instance = MOBY::Client::ServiceInstance->new(
     authority => 'bioinfo.pbi.nrc.ca',
     authoritative => 0,
     URL => http://bioinfo.pbi.nrc.ca/runMe.pl,
     contactEmail => markw@illumin.com,
     name => 'marksFabulousService',
     type => 'Retrieve',
     input => [$SimpleArticle],
     category => 'moby',
     output => [$CollectionArticle, $SecondaryArticle],
     description => 'retrieves random sequences from a database',
	 XML => $xml, # the XML from MOBY::Central::findService
	 );

=cut

=head1 DESCRIPTION

a simple get/set object to hold information about a service instance.

This object is created by MOBY::Client::Central, and is not particularly
useful for anyone else to create it... it is meant to be read-only

=head1 AUTHORS

Mark Wilkinson (markw at illuminae dot com)

BioMOBY Project:  http://www.biomoby.org


=cut

=head1 METHODS


=head2 new

 Title     :	new
 Usage     :	my $MOBY = MOBY::Client::ServiceInstance->new(%args)
 Function  :	create ServiceInstance object
 Returns   :	MOBY::Client::ServiceInstance object
 Args      :    authority : required : string : default NULL
                            the URI of the service provider
                name      : required : string : default NULL
                            the name of the service
                type      : required : string : default NULL
                            the type of service from ontology
                input    : optional : listref : default empty listref
                            the SimpleArticle and CollectionArticle inputs for the service
                secondary    : optional : listref : default empty listref
                            the SecondaryArticle inputs for the service
                output    : optional : listref : default empty listref
                            the SimpleArticle and CollectionArticle outputs for the service
                description : required : string : default NULL
                            human-readable description of service

=cut

=head2 authority

 Title     :	authority
 Usage     :	$URI = $Service->authority($arg)
 Args      :    (optional) scalar string with authority URI
 Function  :	get/set authority
 Returns   :	string

=cut

=head2 name

 Title     :	name
 Usage     :	$name = $Service->name($arg)
 Args      :    (optional) scalar string with service name
 Function  :	get/set name
 Returns   :	string

=cut

=head2 type

 Title     :	type
 Usage     :	$type = $Service->type($arg)
 Args      :    (optional) scalar string with servivce type ontology term
 Function  :	get/set type
 Returns   :	string

=cut

=head2 category

 Title     :	category
 Usage     :	$category = $Service->category($arg)
 Args      :    (optional) scalar string with moby service category ['moby' | 'post' | 'moby-async']
 Function  :	get/set category
 Returns   :	string

=cut


=head2 input

 Title     :	input
 Usage     :	$input = $Service->input($args)
 Args      :    (optional) listref of SimpleArticle, and/or CollectionArticles
 Function  :	get/set input
 Returns   :	listref of MOBY::Client::SimpleArticle
                and/or MOBY::Client::CollectionArticle objects

=cut

=head2 output

 Title     :	output
 Usage     :	$output = $Service->output($args)
 Args      :    (optional) listref of SimpleArticle,
                CollectionArticle, or SecondaryArticle objects
 Function  :	get/set output
 Returns   :	listref of MOBY::Client::SimpleArticle
                and/or MOBY::Client::CollectionArticle objects

=cut


=head2 secondary

 Title     :	secondary
 Usage     :	$output = $Service->secondary($args)
 Args      :    (optional) listref of SecondaryArticle objects
 Function  :	get/set secondary inputs
 Returns   :	listref of MOBY::Client::SecondaryArticle

=cut

=head2 description

 Title     :	description
 Usage     :	$description = $Service->description($arg)
 Args      :    (optional) scalar string with description
 Function  :	get/set description
 Returns   :	string

=cut

=head2 authoritative

 Title     :	authoritative
 Usage     :	$auth = $Service->authoritative(1|0)
 Args      :    (optional) boolean 1 or 0
 Function  :	get/set authoritative flag
 Returns   :	current value

=cut

=head2 URL

 Title     :    URL
 Usage     :	$URL = $Service->URL($url)
 Args      :    (optional) string representing a URL
 Function  :	get/set service URL endpoint
 Returns   :	current value

=cut

=head2 contactEmail

 Title     :    contactEmail
 Usage     :	$email = $Service->contactEmail($email)
 Args      :    (optional) string representing an email address
 Function  :	get/set service email address
 Returns   :	current value

=cut


=head2 LSID

 Title     :    LSID
 Usage     :	$lsid = $Service->LSID()
 Args      :    none
 Function  :	get (readonly) service instance LSID
 Returns   :	current value as scalar string

=cut

=head2 signatureURL

 Title     :    signatureURL
 Usage     :	$sig = $Service->signatureURL()
 Args      :    (optional) string representing a URL
 Function  :	get/set the location of the RDF document that describes this service
 Returns   :	current value as scalar string

=cut

=head2 registry

 Title     :	registry
 Usage     :	$regname = $Service->registry([$description])
 Function  :	get/set registry
 Returns   :	string

=cut

=head2 unitTests

 Title     :	unitTests
 Usage     :	$test = $Service->unitTests()
 Function  :	get/set the MobyUnitTests for this service
 Returns   :	a listref of MOBY::Client::MobyUnitTest objects for this service 

=cut

{

	# Encapsulated:
	# DATA
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		authority     => [ undef, 'read/write' ],
		signatureURL  => [ undef, 'read/write' ],
		name          => [ undef, 'read/write' ],
		type          => [ undef, 'read/write' ],
		input         => [ undef, 'read/write' ],               # listref of Simple and Collection articles
		output        => [ undef, 'read/write' ],               # listref of Simple and Collection articles
		secondary     => [ undef, 'read/write' ],   # listref of SecondaryArticles
		category      => [ undef, 'read/write' ],
		description   => [ undef, 'read/write' ],
		registry      => [ 'MOBY_Central', 'read/write' ],
		XML           => [ undef,          'read/write' ],
		authoritative => [ undef,          'read/write' ],
		URL           => [ undef,          'read/write' ],
		contactEmail  => [ undef,          'read/write' ],
		LSID		  => [ undef, 		   'read/write'],
		unitTests      => [ undef, 		   'read/write'], # listref to a MobyUnitTest objects
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
	return $caller if $caller_is_obj;
	my $class = $caller_is_obj || $caller;
	my $proxy;
	my $self = bless {}, $class;
	foreach my $attrname ( $self->_standard_keys ) {
		if ( exists $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		} elsif ( $caller_is_obj ) {
			$self->{$attrname} = $caller->{$attrname};
		} else {
			$self->{$attrname} = $self->_default_for( $attrname );
		}
	}
	$self->input(     [] ) unless $self->input;
	$self->output(    [] ) unless $self->output;
	$self->secondary( [] ) unless $self->secondary;
	$self->unitTests ( [] ) unless $self->unitTests;
	return $self;
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
1;
