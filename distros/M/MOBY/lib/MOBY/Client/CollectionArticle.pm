package MOBY::Client::CollectionArticle;
use strict;
use Carp;
use XML::LibXML;
use MOBY::MobyXMLConstants;
use vars qw($AUTOLOAD @ISA);
use MOBY::Client::SimpleArticle;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Client::CollectionArticle - a small object describing the
Collection articles from the findService Response message of MOBY
Central or representing the collection part of a MOBY invocation or
response block

=head1 SYNOPSIS

This module can be used in two ways.  One is to represent the Collection
portion of a findService response.  The other is to represent the Collecion
portion of a MOBY service invocation or response message.

Parsing a MOBY Service Invocation

 use MOBY::CommonSubs qw(:all);

 sub myService {
    my ($caller, $data) = @_;


Can be used either in this way:

 use MOBY::CommonSubs qw{:all};

    foreach my $queryID(keys %$inputs){
        my $this_invocation = $inputs->{$queryID};  # this is the <mobyData> block with this queryID
	my $invocation_output = "";
	if (my $input = $this_invocation->{'This_articleName'}){
            # $input contains a MOBY::Client::SimpleArticle, ::CollectionArticle or ::SecondaryArticle
            next unless $input->isCollection;
            @simples= @{$input->Simples};
            # @simples contains a list of MOBY::Client::SimpleArticles
            # do your business here and fill $invocation_output
	}

        $MOBY_RESPONSE .= simpleResponse( # create an empty response for this queryID
                $invocation_output   # response for this query
                , "myOutput"  # the article name of that output object
                , $queryID);    # the queryID of the input that we are responding to
    }
    return SOAP::Data->type('base64' => (responseHeader("illuminae.com") . $MOBY_RESPONSE . responseFooter));   


or to construct a representation of a collection article from a findService call
to MOBY::Central


=head1 DESCRIPTION

This describes the Collection articles from either the findService Response of MOBY Central
(i.e. the description of the service), or Collection articles
as provided in a service invocation or response message
(i.e. simple articles containing data)

Basically it parses the following part of a findService response:

 <Collection articleName="foo">
  <Simple>
     <objectType>someNbject</objectType>
     <Namespace>someNamespace</Namespace>
     <Namespace>someNamespace2</Namespace>
  </Simple>
  <Simple>
     <objectType>someNbject</objectType>
     <Namespace>someNamespace</Namespace>
     <Namespace>someNamespace2</Namespace>
  </Simple>
 </Collection>

OR  it parses the following part of a service invocation or response message:

 <Collection articleName="foo">
  <Simple>
    <SomeObject namespace='someNamespace' id='someID'>.....</SomeObject>
  </Simple>
  <Simple>
    <SomeObject namespace='someNamespace' id='someID'>.....</SomeObject>
  </Simple>
 </Collection>


The articleName is retrieved with ->articleName
The contained Simples are retrieved as MOBY::Client::SimpleArticle objects
using the ->Simples method call.


=head1 AUTHORS

Mark Wilkinson (markw at illuminae dot com)

=head1 METHODS


=head2 new

 Usage     :	my $IN = MOBY::Client::CollectionArticle->new(%args)
 Function  :	create CollectionArticle object
 Returns   :	MOBY::Client::SimpleArticle object
 Args      :    either of the following two methods may be used to auto-generate the
                object by passing the appropriate XML node as a string, or XML::DOM node object

                XML => $XML
                XML_DOM => $XML::DOM::NODE

=head2 articleName

 Usage     :	$name = $IN->articleName($name)
 Function  :	get/set articleName
 Returns   :	string
 Arguments :    (optional) string to set articleName

=head2 Simples

 Usage     :	$simples = $IN->Simples(\@SimpleArticles)
 Function  :	get/set simple articles
 Returns   :	arrayRef of MOBY::Client::SimpleArticle's in this collection
 Arguments :    (optional) arrayRef of MOBY::Client::SimpleArticle's in this collection

=head2 addSimple

 Usage     :	$simples = $IN->addSimple($SimpleArticle)
 Function  :	add another SimpleArticle
 Returns   :	arrayref of MOBY::Client::SimpleArticle's or 0 if argument
                was not a MOBY::Client::SimpleArticle (or other failure)
 Arguments :    a new MOBY::Client::SimpleArticle to add to collection

=head2 XML

 Usage     :   $SA = $SA->XML($XML)
 Function  :	set/reset all parameters for this object from the XML
 Returns   :	MOBY::Client::SimpleArticle
 Arguments :    (optional) XML fragment from and including <Simple>...</Simple>

=head2 XML_DOM

 Usage     :	$namespaces = $SA->XML_DOM($XML_DOM_NODE)
 Function  :	set/reset all parameters for this object from the XML::DOM node for <Simple>
 Returns   :	MOBY::Client::SimpleArticle
 Arguments :    (optional) an $XML::DOM node from the <Simple> article of a DOM

=head2 isSimple

 Usage     :	$boolean = $IN->isSimple()
 Function  :	is this a SimpleArticle type
                (yes, I know this is obvious, but since you can
                 get both Simple and Collection objects in your
                 Input and output lists, it is good to be able
                 to test what you have in-hand)
 Returns   :	0 (false)

=head2 isCollection

 Usage     :	$boolean = $IN->isCollection()
 Function  :	is this a CollectionArticle type
                (yes, I know this is obvious, but since you can
                 get both Simple and Collection objects in your
                 Input and output lists, it is good to be able
                 to test what you have in-hand)
 Returns   :	1 (true)

=head2 isSecondary

 Usage     :	$boolean = $IN->isSecondary()
 Function  :	is this a SecondaryArticle type?
                (yes, I know this is obvious)
 Returns   :	0 (true)

=cut

{

	# Encapsulated:
	# DATA
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #   DEFAULT    	ACCESSIBILITY
	  (
		articleName =>  [ undef, 'read/write' ],
		Simples =>      [ undef,    'read/write' ],
		isSimple     => [ 0,     'read' ],
		isSecondary  => [ 0,     'read' ],
		isCollection => [ 1,     'read' ],
		XML          => [ undef, 'read/write' ],
		XML_DOM      => [ undef, 'read/write' ],
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

	sub addSimple {
		my ( $self, $s ) = @_;
		return $self->{Simples} unless $s;
		return 0                unless $s->isa( "MOBY::Client::SimpleArticle" );
		push @{ $self->{Simples} }, $s;
		return $self->{Simples};
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
	if ( $self->XML && ref( $self->XML ) ) {
		return 0;
	} elsif ( $self->XML_DOM && !( ref( $self->XML_DOM ) =~ /libxml/i ) ) {
		return 0;
	}
	$self->createFromXML                   if ( $self->XML );
	$self->createFromDOM( $self->XML_DOM ) if ( $self->XML_DOM );
	return $self;
}

sub createFromXML {
	my ( $self ) = @_;
	my $p        = XML::LibXML->new;
	my $doc      = $p->parse_string( $self->XML );
	my $root     = $doc->getDocumentElement;
	return 0 unless ( $root && ( $root->localname eq "Collection" ) );
	return $self->createFromDOM( $root );
}

sub createFromDOM {
    my ( $self, $dom ) = @_;
    return 0 unless ( $dom && ( $dom->localname eq "Collection" ) );
    $self->XML( $dom->toString );    # set the string version of the DOM
    $self->articleName( "" );
    $self->Simples( [] );
    my $attr        = $dom->getAttributeNode( 'articleName' );
	$attr  ||= $dom->getAttributeNode( 'moby:articleName' );
    my $articleName = "";
    $articleName = $attr->getValue if $attr;
    $self->articleName( $articleName );
    my $objects = $dom->getElementsByLocalName( "Simple" );
    
    for my $n ( 1 .. $objects->size ) {
        $self->addSimple(
            MOBY::Client::SimpleArticle->new(
                articleName => $self->articleName,
                XML_DOM => $objects->get_node( $n )
            )
        );
    }
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
