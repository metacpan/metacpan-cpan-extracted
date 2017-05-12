package MOBY::Client::SimpleArticle;
use strict;
use Carp;
use XML::LibXML;
use MOBY::MobyXMLConstants;
use vars qw($AUTOLOAD @ISA);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Client::SimpleArticle - a small object describing the Simple articles from the findService Response message of MOBY Central

=head1 SYNOPSIS


    foreach my $queryID(keys %$inputs){
        my $this_invocation = $inputs->{$queryID};  # this is the <mobyData> block with this queryID
	my $invocation_output = "";
	if (my $input = $this_invocation->{'This_articleName'}){
            # $input contains a MOBY::Client::SimpleArticle, ::CollectionArticle or ::SecondaryArticle
            next unless $input->isSimple;
	    $XML = $input->XML;  # get the raw XML of the object, including <Simple> or <Collection> elements
            $moby_object = $input->content; # get the raw XML of the object EXCLUDING <Simple> or <Collection> elements
            $DOM = $input->XML_DOM;  # get the XML as a LibXML DOM object
            $namespace = $input->namespace;  # get the namespace of the object
            $id = $input->id;  # get the id of the object (the id of the outermost MOBY object XML block)

            # do your business here and fill $invocation_output
	}

        $MOBY_RESPONSE .= simpleResponse( # create an empty response for this queryID
                $invocation_output   # response for this query
                , "myOutput"  # the article name of that output object
                , $queryID);    # the queryID of the input that we are responding to
    }
    return SOAP::Data->type('base64' => (responseHeader("illuminae.com") . $MOBY_RESPONSE . responseFooter));   


or to construct a representation of a simple article from a findService call
to MOBY::Central


=cut

=head1 DESCRIPTION

This describes the Simple articles from either the findService Response of MOBY Central
(i.e. the description of the service), or Simple articles
as provided in a service invocation or response message
(i.e. simple articles containing data)

Basically it parses the following part of a findService response:

<Simple articleName='foo'>
    <objectType>someNbject</objectType>
    <Namespace>someNamespace</Namespace>
    <Namespace>someNamespace2</Namespace>
</Simple>

OR  it parses the following part of a service invocation or response message:

<Simple articleName='foo'>
    <SomeObject namespace='someNamespace' id='someID'>.....</SomeObject>
</Simple>

The articleName is retrieved with ->articleName
The namespace(s) are retrieved with ->namespaces
The objectType is retrieved with ->objectType
the id (if instantiated) is retrieved with ->id


=head1 AUTHORS

Mark Wilkinson (markw at illuminae dot com)

=cut

=head1 METHODS


=head2 new

 Usage     :	my $SA = MOBY::Client::SimpleArticle->new(%args)
 Function  :	create SimpleArticle object
 Returns   :	MOBY::Client::SimpleArticle object
 Args      :    either of the following two methods may be used to auto-generate the
                object by passing the appropriate XML node as a string, or XML::DOM node object

                XML => $XML
                XML_DOM => $XML::LibXML::Node



=head2 articleName

 Usage     :	$name = $SA->articleName($name)
 Function  :	get/set articleName
 Returns   :	string
 Arguments :    (optional) string representing articleName to set

=head2 objectType

 Usage     :	$type = $SA->objectType($type)
 Function  :	get/set name
 Returns   :	string
 Arguments :    (optional) string representing objectType to set

=head2 objectLSID

 Usage     :	$type = $SA->objectLSID($type)
 Function  :	get/set LSID
 Returns   :	string
 Arguments :    (optional) string representing objectLSID to set

=head2 namespace

 Usage     :	$namespace = $SA->namespace
 Function  :	get namespace for the MOBY Object
 Returns   :	namespace as a string
 Arguments :    none

=head2 namespaces

 Usage     :	$namespaces = $SA->namespaces(\@namespaces)
 Function  :	get/set namespaces for the objectType in a service instance object
 Returns   :	arrayref of namespace strings
 Arguments :    (optional) arrayref of namespace strings to set

=head2 XML

 Usage     :   $SA = $SA->XML($XML)
 Function  :	set/reset all parameters for this object from the XML
 Returns   :	MOBY::Client::SimpleArticle
 Arguments :    (optional) XML fragment from and including <Simple>...</Simple>

=head2 content

 Usage     :	$XML = $SA->content
 Function  :	get XML of the article EXCLUDING the <Simple>..</Simple> tags
 Returns   :	string
 Arguments :    none


=head2 XML_DOM

 Usage     :	$namespaces = $SA->XML_DOM($XML_DOM_NODE)
 Function  :	set/reset all parameters for this object from the XML::DOM node for <Simple>
 Returns   :	MOBY::Client::SimpleArticle
 Arguments :    (optional) an $XML::DOM node from the <Simple> article of a DOM


=head2 addNamespace

 Usage     :	$namespaces = $IN->addNamespace($namespace)
 Function  :	add another namespace for the objectType
 Returns   :	namespace string

=head2 isSimple

 Usage     :	$boolean = $IN->isSimple()
 Function  :	is this a SimpleArticle type
                (yes, I know this is obvious, but since you can
                 get both Simple and Collection objects in your
                 Input and output lists, it is good to be able
                 to test what you have in-hand)
 Returns   :	1 (true)


=head2 isCollection

 Usage     :	$boolean = $IN->isCollection()
 Function  :	is this a CollectionArticle type
                (yes, I know this is obvious, but since you can
                 get both Simple and Collection objects in your
                 Input and output lists, it is good to be able
                 to test what you have in-hand)
 Returns   :	0 for false

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
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		articleName  => [ undef, 'read/write' ],
		objectType   => [ undef, 'read/write' ],
		objectLSID   => [ undef, 'read/write' ],
		namespaces   => [ undef, 'read/write' ],
		id           => [ undef, 'read/write' ],
		XML_DOM      => [ undef, 'read/write' ],
		XML          => [ undef, 'read/write' ],
		isSecondary  => [ 0,     'read' ],
		isSimple     => [ 1,     'read' ],
		isCollection => [ 0,     'read' ],
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

	sub addNamespace {
		my ( $self, $ns ) = @_;
		return $self->{namespaces} unless $ns;
		push @{ $self->{namespaces} }, $ns;
		return $self->{namespaces};
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
  } elsif ( $self->XML_DOM && !( ref( $self->XML_DOM ) =~ /XML\:\:LibXML/ ) ) {
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
  return 0 unless ( $root && ( $root->localname eq "Simple" ) );
  return $self->createFromDOM( $root );
}

sub createFromDOM {
  my ( $self, $dom ) = @_;
  return 0 unless ( $dom && ( $dom->localname eq "Simple" ) );
  $self->XML($dom->toString);
  $self->namespaces( [] );         # reset!
  $self->articleName( "" );
  $self->objectType( "" );
  my $attr = $dom->getAttributeNode( 'articleName' );
  $attr ||= $dom->getAttributeNode( 'moby:articleName' );
  my $articleName = $attr ? $attr->getValue : "";
  $attr = $dom->getAttributeNode( 'lsid' );
  my $lsid = $attr ? $attr->getValue : "";

  $self->articleName( $articleName )
    if $articleName; # it may have already been set if this Simple is part of a Collection...
  $self->objectLSID( $lsid) if $lsid;

  # fork here - it may be an instantiated object (coming from a service invocation/response)
  # or it may be a template object as in the SimpleArticle element of a registration call
  # if the objectType tag exists, then it is a template object
  if ( @{ $dom->getElementsByLocalName( "objectType" ) }[0] ) {
    return $self->_createTemplateArticle( $dom );
  } else {
    return $self->_createInstantiatedArticle( $dom );
  }
  # otherwise it should simpy contain an instantiated MOBY object
}

sub namespace {
    my ( $self) = @_;
    my $namespaces = $self->namespaces;
    my @namespace = @{$namespaces};
    return $namespace[0] || "";
}

sub content {
    my ( $self) = @_;
    my $DOM = $self->XML_DOM;
    my $XML;
    foreach my $child ( $DOM->childNodes )
    { # there should be only one child node, and that is the data object itself; ignore whitespace
            next unless $child->nodeType == ELEMENT_NODE;
            $XML .= $child->toString;
    }
    return $XML;
}
    
sub _createInstantiatedArticle {
	my ( $self, $dom ) = @_;

	# this will take a <Simple> node from a MOBY invocation message
	# and extract the object-type and namespace from the
	# contained data object
	foreach my $child ( $dom->childNodes )
	{ # there should be only one child node, and that is the data object itself; ignore whitespace
		next unless $child->nodeType == ELEMENT_NODE;
		$self->objectType( $child->localname );
		my $attr = $child->getAttributeNode( 'namespace' );
		$attr ||= $child->getAttributeNode( 'moby:namespace' );
		$self->addNamespace( $attr->getValue ) if $attr;
		my $id = $child->getAttributeNode( 'id' );
		$id ||= $child->getAttributeNode( 'moby:id' );
		$self->id( $id->getValue ) if $id;
	}
	return $self;
}

sub _createTemplateArticle {
	my ( $self, $dom ) = @_;

	# this will take a <Simple> node from a MOBY findServiceResponse
	# message and extract the objectType and namespace array
	# from the service signature.
	my $objects = $dom->getElementsByLocalName( "objectType" );
	foreach my $child ( $objects->get_node( 1 )->getChildNodes )
	{    # there must be only one in a simple!  so take first element
		next unless $child->nodeType == TEXT_NODE;
		$self->objectType( $child->toString );
	}
	$objects = $dom->getElementsByLocalName( "Namespace" );
	foreach ( 1 .. $objects->size() ) {
		foreach my $child ( $objects->get_node( $_ )->childNodes )
		{    # there must be only one in a simple!  so take element 0
			next unless $child->nodeType == TEXT_NODE;
			next unless $child->toString;
			$self->addNamespace( $child->toString );
		}
	}
	return $self;
}

sub value {
	my ( $self ) = @_;

	# ?????  what to do here ????
}

sub AUTOLOAD {
  # It seems desirable that if the XML() method is called, the XML should be parsed, rather than just being 
  no strict "refs";
  my ( $self, $newval ) = @_;
  $AUTOLOAD =~ /.*::(\w+)/;
  my $attr = $1;
  if ( $self->_accessible( $attr, 'write' ) ) {
    *{$AUTOLOAD} = sub {
      if ( defined $_[1] ) { $_[0]->{$attr} = $_[1]; }
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
