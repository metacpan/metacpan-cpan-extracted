package MOBY::Client::SecondaryArticle;
use strict;
use Carp;
use XML::LibXML;
use MOBY::MobyXMLConstants;
use vars qw($AUTOLOAD @ISA);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Client::SecondaryArticle - a small object describing the Simple articles from the findService Response message of MOBY Central

=head1 SYNOPSIS


Can be used either in this way:

 use MOBY::CommonSubs qw{:all};
    foreach my $queryID(keys %$inputs){
        my $this_invocation = $inputs->{$queryID};  # this is the <mobyData> block with this queryID
	my $invocation_output = "";
	if (my $input = $this_invocation->{'This_articleName'}){
            # $input contains a MOBY::Client::SimpleArticle, ::CollectionArticle or ::SecondaryArticle
            next unless $input->isSecondary;  # make sure it is a ::SecondaryArticle
            $prameter_value = $input->value;  # get the value of the secondary parameter
            # do your business here and fill $invocation_output
	}

        $MOBY_RESPONSE .= simpleResponse( # create an empty response for this queryID
                $invocation_output   # response for this query
                , "myOutput"  # the article name of that output object
                , $queryID);    # the queryID of the input that we are responding to
    }
    return SOAP::Data->type('base64' => (responseHeader("illuminae.com") . $MOBY_RESPONSE . responseFooter));   

or to construct a representation of a Secondary article from a findService call
to MOBY::Central


=cut

=head1 DESCRIPTION

A module used to describe secondary articles in moby

=cut

=head1 AUTHORS

Mark Wilkinson (markw at illuminae dot com)

=cut

=head1 METHODS


=head2 new

 Usage     :	my $SA = MOBY::Client::SecondaryArticle->new(%args)
 Function  :	create SecondaryArticle object
 Returns   :	MOBY::Client::SecondaryArticle object
 Args      :    articleName => "NameOfArticle"
                datatype => Integer|Float|String|DateTime,
                default => $some_default_value,
                max => $maximum_value,
                min => $minimum_value,
		description => $free_text,
                enum => \@valid_values
                XML_DOM => $XML_DOM node of the Secondary article (optional)
                XML  => $XML XML string representing the Secondary article (optional)

=head2 articleName

 Usage     :	$name = $SA->articleName($name)
 Function  :	get/set articleName
 Returns   :	string
 Arguments :    (optional) string representing articleName to set

=head2 datatype

 Usage     :	$name = $SA->datatype($type)
 Function  :	get/set datatype: Integer, Float, DateTime, Boolean, String
 Returns   :	the datatype
 Arguments :    

=head2 min

 Usage     :	$name = $SA->min($value)
 Function  :	get/set the minimum value of a datatype
 Returns   :	min value 
 Arguments :    

=head2 max

 Usage     :	$name = $SA->max($value)
 Function  :	get/set maximum value of the datatype
 Returns   :	max value 
 Arguments :    

=head2 default

 Usage     :	$name = $SA->default($value)
 Function  :	get/set the default value of parameter
 Returns   :	default value
 Arguments :


=head2 enum

 Usage     :	$name = $SA->enum(\@possible_values)
 Function  :	get/set the enumerated values for discreet variables
 Returns   :	listref of string values
 Arguments :    


=head2 addEnum

 Usage     :	$name = $SA->addEnum($new_possible_values)
 Function  :	add to the list of enumerated values for discreet variables
 Returns   :	new listref of string values
 Arguments :    


=head2 description

 Usage     :	$namespaces = $SA->description("text description here")
 Function  :	get/set description of the parameter
 Returns   :	string
 Arguments :    (optional) string description


=head2 XML

 Usage     :   $SA = $SA->XML($XML)
 Function  :	set/reset all parameters for this object from the XML
 Returns   :	MOBY::Client::SecondaryArticle
 Arguments :    (optional) XML fragment from and including <Simple>...</Simple>

=head2 XML_DOM

 Usage     :	$namespaces = $SA->XML_DOM($XML_DOM_NODE)
 Function  :	set/reset all parameters for this object from the XML::DOM node for <Simple>
 Returns   :	MOBY::Client::SecondaryArticle
 Arguments :    (optional) an $XML::DOM node from the <Simple> article of a DOM

=head2 isSecondary

 Usage     :	$boolean = $IN->isSecondary()
 Function  :	is this a SecondaryArticle type? (yes, I know this is obvious)
 Returns   :	1 (true)

=head2 isSimple

 Usage     :	$boolean = $IN->isSimple()
 Function  :	is this a SimpleArticle type
 Returns   :	0 (false)

=head2 isCollection

 Usage     :	$boolean = $IN->isCollection()
 Function  :	is this a CollectionArticle type
 Returns   :	0 for false

=cut

{

	# Encapsulated:
	# DATA
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #  DEFAULT    	ACCESSIBILITY
	  (
		articleName  => [ undef, 'read/write' ],
		objectType   => [ undef, 'read/write' ],
		namespaces   => [ undef, 'read/write' ],
		XML_DOM      => [ undef, 'read/write' ],
		XML          => [ undef, 'read/write' ],
		isSecondary  => [ 1,     'read' ],
		isSimple     => [ 0,     'read' ],
		isCollection => [ 0,     'read' ],
		datatype     => [ undef, 'read/write' ],
		default      => [ undef, 'read/write' ],
		max          => [ undef, 'read/write' ],
		min          => [ undef, 'read/write' ],
		enum         => [ undef, 'read/write' ],
		description  => [ undef, 'read/write' ],
		value        => [ undef, 'read/write' ],
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

	sub addEnum {
	  # No return value necessary
	  my ( $self, $enum ) = @_;
	  $self->{enum} = [] unless $self->{enum};
	  return() unless defined ($enum);
	  push @{ $self->{enum} }, $enum;
	  return $self->enum;
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
  $self->{enum} = [] unless $self->enum;
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
	return 0 unless ( $root && ( $root->localname eq "Parameter" ) );
	return $self->createFromDOM( $root );
}

sub createFromDOM {
	my ( $self, $dom ) = @_;
	return 0 unless ( $dom && ( $dom->localname eq "Parameter" ) );
	$self->XML( $dom->toString );    # set the string version of the DOM
	$self->namespaces( [] );         # reset!
	$self->articleName( "" );
	$self->objectType( "" );
	my $attr        = $dom->getAttributeNode( 'articleName' );
	$attr  ||= $dom->getAttributeNode( 'moby:articleName' );
	$self->articleName( $attr ? $attr->getValue : "" );
	if ( @{ $dom->getElementsByLocalName( 'Value' ) }[0] ) {
	  return $self->_createInstantiatedArticle( $dom );
	} else {
	  return $self->_createTemplateArticle( $dom );
	}
}

sub _createTemplateArticle {
  my ( $self, $dom ) = @_;

  #datatype    => [undef,          'read/write'      ],
  #description => [undef,		'read/write' ],
  #default     => [undef,          'read/write'      ],
  #max         => [undef,          'read/write'      ],
  #min         => [undef,          'read/write'      ],
  #enum        => [[],          'read/write'      ],
  my @single_valued = qw/datatype default max min description/;
  my $objects;
  foreach my $param (@single_valued) {
    $objects = $dom->getElementsByTagName( $param );
    if ( $objects->get_node( 1 ) ) {
      my $data;
      foreach my $child ( $objects->get_node( 1 )->childNodes ) {
	next unless $child->nodeType == TEXT_NODE;
	$data .= $child->toString;
	($data =~ s/\s//g) unless ($param eq "description");	# Trim all whitespace except from description
      }
      $self->$param( $data );
    }
  }
  # Since it is (array)multi-valued, 'enum' is a little different from the others.
  $objects = $dom->getElementsByTagName( "enum" );
  if ( $objects->get_node( 1 ) ) {
    foreach ( 1 .. $objects->size() ) {
      foreach my $child ( $objects->get_node( $_ )->childNodes ) {
	my $val;
	next unless $child->nodeType == TEXT_NODE;
	$val = $child->toString;
	next unless defined( $val );
	# Trim space from front and back, but leave alone in middle....?
	$val =~ s/^\s//;
	$val =~ s/\s$//;
	$self->addEnum( $val );
      }
    }
  }
  return $self;
}

sub _createInstantiatedArticle {
  my ( $self, $dom ) = @_;

  #<Parameter articleName='foo'><Value>43764</Value></Parameter>
  my $values = $dom->getElementsByLocalName( 'Value' );
  $self->value( "" ); # Initialize to 1) avoid Perl warnings 2) be good.
  foreach my $child ( $values->get_node( 1 )->childNodes ) {
    next unless $child->nodeType == TEXT_NODE;
    # Would we *really* want to catenate values like this?
    $self->value( $self->value . $child->toString );
  }
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
