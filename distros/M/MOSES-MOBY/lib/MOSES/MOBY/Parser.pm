#-----------------------------------------------------------------
# MOSES::MOBY::Parser
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
#
# For copyright and disclaimer see below.
#
# $Id: Parser.pm,v 1.4 2008/04/29 19:45:01 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Parser;

use MOSES::MOBY::Base;
use base qw( MOSES::MOBY::Base XML::SAX::Base );
use XML::SAX::ParserFactory;

use MOSES::MOBY::Data::ProvisionInformation;
use MOSES::MOBY::Data::Xref;
use MOSES::MOBY::Data::Object;
use MOSES::MOBY::Tags;
use MOSES::MOBY::Package;
use MOSES::MOBY::ServiceException;
use MOSES::MOBY::Generators::GenTypes;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------
{
    my %_allowed =
	(
	 cachedir             => undef,
	 registry             => undef,
	 lowestKnownDataTypes => { type => 'HASH' },
	 generator            => { type => 'MOSES::MOBY::Generators::GenTypes' }
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->lowestKnownDataTypes ({});
}

my %pcdataNames              ;
my %pcdataNamesForPrimitives;
my @pcdataNamesArray;
my @pcdataNamesArrayForPrimitives;

# special logger just for the parser
my $PLOG;

BEGIN {
    @pcdataNamesArray =
	( NOTES, SERVICECOMMENT, VALUE, XREF, EXCEPTIONCODE, EXCEPTIONMESSAGE );
    @pcdataNamesArrayForPrimitives =
	( MOBYSTRING, MOBYINTEGER, MOBYFLOAT, MOBYBOOLEAN, MOBYDATETIME );
    
    foreach (@pcdataNamesArray) {
	$pcdataNames{$_} = 1;
    }
    foreach (@pcdataNamesArrayForPrimitives) {
	$pcdataNamesForPrimitives{$_} = 1;
    }

    # special logger just for the parser because debugging level from
    # the parser clutters other logging too much
    use Log::Log4perl qw(get_logger :levels :no_extra_logdie_message);
    $PLOG = get_logger ('parser');
}

############################################################
#          GLOBAL VARIABLES
############################################################
my %generated;	     # keep track of whether a type was generated or not
my @objectStack;     # type MobyObject
my @pcdataStack;     # strings
my $readingMobyObject = 0;    # true if inside Simple
my $readingCollection = 0;    # true if inside collection
my $readingXrefs      = 0;    # true if inside Crossreference
my $readingProvision  = 0;    # true if inside provision information
my $insubstitution    = 0;    # when just using 'lowestKnownDataTypes' it contains a name of substituted element
my $inServiceNotes    = 0;    # true if inside serviceNotes
my $inMobyException   = 0;
my $ignoring          = 0;    # count depth of ignored (unknown) data objects
my $result;                   # type MobyPackage - the whole result
my @articleNames;
my $locator;
######################END OF GLOBALS########################

#-----------------------------------------------------------------
# parse
#    args: method => 'string', data => direct XML
#            OR
#          method => 'file',   data => filename
#-----------------------------------------------------------------
sub parse {
    my ($self, %args) = @_;
    $self->throw ("parse() needs arguments 'method' and 'data'.")
	unless $args{method} and $args{data};

    # I could not assign this default value in init(), because it was
    # before 'cachedir' etc. were set
    my @generator_args = ();
    push (@generator_args, (cachedir => $self->cachedir)) if $self->cachedir;
    push (@generator_args, (registry => $self->registry)) if $self->registry;
    $self->generator ( new MOSES::MOBY::Generators::GenTypes (@generator_args) )
	unless $self->generator;

    $self->select_parser;
    my $parser = XML::SAX::ParserFactory->parser(Handler => $self);

    if ($args{method} eq 'string') {
	$parser->parse_string ($args{data});
    } elsif ($args{method} eq 'file') {
	$parser->parse_file ($args{data});
    } else {
	$self->throw ("in parse(): 'method' is neither 'string' nor 'file'.");
    }
    return $result if $result;
    $PLOG->error("There was a problem parsing\n$args{data}.\nIf this is a file, please make sure that the file exists, otherwise please ensure that the XML is 'valid'.");
    $self->throw ("There was a problem parsing\n$args{data}.\nIf this is a file, please make sure that the file exists, otherwise please ensure that the XML is 'valid'.");
}

#-----------------------------------------------------------------
# select_parser
#
# If there is a configuration option defining what XML parser to use,
# this method selects it. Otherwise, it leaves it to the parser
# factory to find it out.
#
#-----------------------------------------------------------------
sub select_parser {
    my $self = shift;
    if (defined $MOBYCFG::XML_PARSER) {
	$XML::SAX::ParserPackage = $MOBYCFG::XML_PARSER;
    }
}

#*********************************************************************
#
#		XML-SAX 2.0 handler routines.
#
#********************************************************************

sub start_element {
    my ( $self, $element ) = @_;

#	element is a hash reference with these properties:
#    Name 	The element type name (including prefix).
#    Attributes 	The attributes attached to the element, if any.
#    NamespaceURI 	The namespace of this element.
#    Prefix 	The namespace prefix used on this element.
#    LocalName 	The local name of this element.
#
#   Attributes is a reference to hash keyed by JClark namespace notation.
#   That is, the keys are of the form "{NamespaceURI}LocalName". If the attribute
#   has no NamespaceURI, then it is simply "{}LocalName". Each attribute is a hash reference with these properties:
#    Name 	The attribute name (including prefix).
#    Value 	The normalized value of the attribute.
#    NamespaceURI 	The namespace of this attribute.
#    Prefix 	The namespace prefix used on this attribute.
#    LocalName 	The local name of this attribute.
    $PLOG->debug ("Starting element $element->{Name} with local name $element->{LocalName} \n");

    if ( $ignoring > 0 ) {
	$ignoring++;
	return;
    }
    if ( exists $pcdataNames{ $element->{LocalName} } ) {
	my $st = "";
	push @pcdataStack, \$st;
    }
    if ($readingMobyObject) {
	if ( exists $pcdataNamesForPrimitives{ $element->{LocalName} } ) {
	    my $st = "";
	    push @pcdataStack, \$st;
	}
    }
    if ($readingMobyObject) {
	if ( $element->{LocalName} eq PROVISIONINFORMATION ) {
	    push @objectStack, \MOSES::MOBY::Data::ProvisionInformation->new();
	    $readingProvision = 1;
	}
	elsif ( $element->{LocalName} eq CROSSREFERENCE ) {
	    $readingXrefs = 1;
	}
	elsif ($readingXrefs) {
	    if ( $element->{LocalName} eq XREF ) {
		my $xref = MOSES::MOBY::Data::Xref->new();
		$xref->id( $self->getValue( attributes=>$element->{Attributes}, name=>OBJ_ID ) );
		$xref->namespace(
				 $self->getValue( attributes=>$element->{Attributes}, name=>OBJ_NAMESPACE ) );
		eval {
		    $xref->evidenceCode($self->getValue( attributes=>$element->{Attributes}, name=>EVIDENCECODE )
					);
		};
		if ($@) {
		    $self->error ($@);
		}
		my $serviceName =
		    $self->getValue( attributes=>$element->{Attributes}, name=>SERVICENAME );
		my $serviceAuthority =
		    $self->getValue( attributes=>$element->{Attributes}, name=>AUTHURI );
		if ($serviceName and $serviceAuthority) {
		    $xref->service ($serviceName);
		    $xref->authority ($serviceAuthority);
		}
		push @objectStack, \$xref;
	    }
	    elsif ( $element->{LocalName} eq MOBYOBJECT ) {
		my $xref = MOSES::MOBY::Data::Xref->new();
		$xref->id( $self->getValue( attributes=>$element->{Attributes}, name=>OBJ_ID ) );
		$xref->namespace(
				 $self->getValue( attributes=>$element->{Attributes}, name=>OBJ_NAMESPACE ) );
		#$xref->isSimpleXref(1);
		push @objectStack, \$xref;
	    }
	}
	elsif ($readingProvision) {
	    if ( $element->{LocalName} eq SERVICESOFTWARE ) {
		my $info = ${ $self->vPeek('MOSES::MOBY::Data::ProvisionInformation') };
		$info->softwareName(
				    $self->getValue( attributes=>$element->{Attributes}, name=>SOFTWARENAME ) );
		
		my $version =
		    $self->getValue( attributes=>$element->{Attributes}, name=>SOFTWAREVERSION );
		$version =
		    $self->getValue( attributes=>$element->{Attributes}, name=>PLAINVERSION )
		    unless $version;
		$info->softwareVersion($version);
		
		my $comment =
		    $self->getValue( attributes=>$element->{Attributes}, name=>SOFTWARECOMMENT );
		$comment = $self->getValue( attributes=>$element->{Attributes}, name=>COMMENT )
		    unless $comment;
		$info->softwareComment($comment);
		
	    }
	    elsif ( $element->{LocalName} eq SERVICEDATABASE ) {
		my $info = ${ $self->vPeek('MOSES::MOBY::Data::ProvisionInformation') };
		$info->dbName(
			      $self->getValue( attributes=>$element->{Attributes}, name=>DATABASENAME ) );
		
		my $version =
		    $self->getValue( attributes=>$element->{Attributes}, name=>DATABASEVERSION );
		$version =
		    $self->getValue( attributes=>$element->{Attributes}, name=>PLAINVERSION )
		    unless $version;
		$info->dbVersion($version);
		
		my $comment =
		    $self->getValue( attributes=>$element->{Attributes}, name=>DATABASECOMMENT );
		$comment = $self->getValue( attributes=>$element->{Attributes}, name=>COMMENT )
		    unless $comment;
		$info->dbComment($comment);
	    }
	}
	else {
	    
	    # deal with real data objects
	    my $theClass;
	    eval {
		$self->generator->load (datatype_names => [$element->{LocalName}]);
		$theClass = $self->datatype2module ($element->{LocalName});
		$generated{$element->{LocalName}} = 1 if $theClass;
	    };
	    if ( not $theClass and not $insubstitution ) {
		my $obj = ${ $self->peek() };
		if ( $obj->isa('MOSES::MOBY::Simple') ) {

		    # try to find a substitute
		    my $lowestKnownDataType;
		    if ($obj->name and exists $self->lowestKnownDataTypes->{$obj->name}) {
			$lowestKnownDataType = $self->lowestKnownDataTypes->{$obj->name};
			$self->generator->load ($lowestKnownDataType);
			$theClass = $self->datatype2module ($lowestKnownDataType);
			$generated{$lowestKnownDataType} = 1 if $theClass;
		    }
		    if ($theClass) {
			$insubstitution = $obj->name || 1;
			$LOG->warn ("'"	. $element->{LocalName}
				    . "' substituted by '"
				    . $lowestKnownDataType
				    . "'" );
		    }
		}
	    }
	    if ($theClass) {
		my $mobyObj = $theClass->new ( mobyname => $element->{LocalName} );
		$mobyObj->namespace(
				    $self->getValue( attributes=>$element->{Attributes}, name=>OBJ_NAMESPACE ) );
		$mobyObj->id(
			     $self->getValue( attributes=>$element->{Attributes}, name=>OBJ_ID ) );
		push @articleNames, $self->getValue( attributes=>$element->{Attributes}, name=>ARTICLENAME ) ;
		push @objectStack, \$mobyObj;
	    }
	    else {
		$ignoring++;
		if ( not $insubstitution ) {
		    $LOG->warn ("Ignoring unknown element '"
				. ( $element->{LocalName} || "" )
				. "'" );
		}
	    }
	}
    }
    elsif ( $element->{LocalName} eq MOBY ) {
	push @objectStack, \MOSES::MOBY::Package->new;
    }
    elsif ( $element->{LocalName} eq MOBYCONTENT ) {
	my $str = $self->getValue( attributes=>$element->{Attributes}, name=>AUTHORITY );
	${ $self->vPeek('MOSES::MOBY::Package') }
	->authority( $str )
	    if $str;
    }
    elsif ( $element->{LocalName} eq MOBYDATA ) {
	my $job = MOSES::MOBY::Job->new;
	$job->jid( $self->getValue( attributes=>$element->{Attributes}, name=>QUERYID ) );
	push @objectStack, \$job;
    }
    elsif ( $element->{LocalName} eq SERVICENOTES ) {
	$inServiceNotes = 1;
    }
    elsif ( $element->{LocalName} eq MOBYEXCEPTION ) {
	if ($inServiceNotes) {
	    my $se = MOSES::MOBY::ServiceException->new;
	    $se->severity(
			  $self->getValue( attributes=>$element->{Attributes}, name=>SEVERITY ) );
	    $se->jobId( $self->getValue( attributes=>$element->{Attributes}, name=>REFQUERYID ) );
	    $se->dataName(
			  $self->getValue( attributes=>$element->{Attributes}, name=>REFELEMENT ) );
	    push @objectStack, \$se;
	    $inMobyException = 1;
	}
    }
    elsif ( $element->{LocalName} eq SIMPLE ) {
	@articleNames = ();
	my $simple = MOSES::MOBY::Simple->new;
	$PLOG->error("A 'Simple' element cannot have an empty articlename unless it is a part of a collection.") if $self->getValue( attributes=>$element->{Attributes}, name=>ARTICLENAME ) eq "" and not $readingCollection;
	$self->throw("A 'Simple' element cannot have an empty articlename unless it is a part of a collection.") if $self->getValue( attributes=>$element->{Attributes}, name=>ARTICLENAME ) eq "" and not $readingCollection;
	$simple->name( $self->getValue( attributes=>$element->{Attributes}, name=>ARTICLENAME ) ) unless $readingCollection;
	push @objectStack, \$simple;
	$readingMobyObject = 1;
    }
    elsif ( $element->{LocalName} eq COLLECTION ) {
	my $collection = MOSES::MOBY::Collection->new;
	$PLOG->error("A 'Collection' element cannot have an empty articlename.") if $self->getValue( attributes=>$element->{Attributes}, name=>ARTICLENAME ) eq "" ;
	$self->throw("A 'Collection' element cannot have an empty articlename.") if $self->getValue( attributes=>$element->{Attributes}, name=>ARTICLENAME ) eq "" ;
	$collection->name(
			  $self->getValue( attributes=>$element->{Attributes}, name=>ARTICLENAME ) );
	push @objectStack, \$collection;
	$readingCollection = 1;
    }
    elsif ( $element->{LocalName} eq PARAMETER ) {
	my $parameter = MOSES::MOBY::Parameter->new;
	$parameter->name(
			 $self->getValue( attributes=>$element->{Attributes}, name=>ARTICLENAME ) );
	push @objectStack, \$parameter;
    }
    $PLOG->debug ($self->printInfo);
}

sub end_element {
    my ( $self, $element ) = @_;
    $PLOG->debug ("Ending element $element->{Name}\n");
    my ( $obj, $obj2 );
    if ( $ignoring > 0 ) {
	$ignoring--;
	return;
    }
    if ($readingMobyObject) {
	if ( $element->{LocalName} eq SIMPLE ) {
	    $obj  = pop @objectStack;
	    $obj  = ${$obj};
	    $obj2 = ${ $self->peek() };
	    
	    if ( $obj2->isa('MOSES::MOBY::Job') ) {
		$obj2->add_dataElements($obj);
	    }
	    elsif ( $obj2->isa('MOSES::MOBY::Collection') ) {
		$obj2->add_data($obj);
	    }
	    else {
		$self->error ("A simple element should not be in '"
			      . ref($obj2) . "'."
			      );
	    }
	    $readingMobyObject = 0;
	}
	elsif ( $element->{LocalName} eq PROVISIONINFORMATION ) {
	    $obj = pop @objectStack;
	    $obj = ${$obj};
	    ${ $self->vPeek("MOSES::MOBY::Data::Object") }->provision($obj);
	    $readingProvision = 0;
	}
	elsif ( $element->{LocalName} eq CROSSREFERENCE ) {
	    $readingXrefs = 0;
	}
	elsif ($readingXrefs) {
	    if ( $element->{LocalName} eq XREF ) {
		$obj = pop @pcdataStack;
		$obj = ${$obj};
		${ $self->vPeek("MOSES::MOBY::Data::Xref") }
		->description($obj);
		$obj = pop @objectStack;
		$obj = ${$obj};
		${ $self->vPeek("MOSES::MOBY::Data::Object") }->add_xrefs($obj);
	    }
	    elsif ( $element->{LocalName} eq MOBYOBJECT ) {
		$obj = pop @objectStack;
		$obj = ${$obj};
		${ $self->vPeek("MOSES::MOBY::Data::Object") }->add_xrefs($obj);
	    }
	}
	elsif ($readingProvision) {
	    if ( $element->{LocalName} eq SERVICECOMMENT ) {
		$obj = pop @pcdataStack;
		$obj = ${$obj};
		${ $self->vPeek("MOSES::MOBY::Data::ProvisionInformation") }
		->serviceComment($obj);
	    }
	}
	else {
	    if ($insubstitution or $generated{$element->{LocalName}}) {
		my $mobyObj = pop @objectStack;
		$mobyObj = ${$mobyObj};
		if ( $insubstitution
		     and $element->{LocalName} eq $insubstitution ) {
		    $insubstitution = 0;
		}
		if ( exists $pcdataNamesForPrimitives{ $element->{LocalName} } )
		{
		    my $value = pop @pcdataStack;
		    $value = ${$value};
		    $mobyObj->value($value);
		}
		$obj2 = ${ $self->peek() };
		if ( $obj2->isa("MOSES::MOBY::Simple") ) {
		    $obj2->data($mobyObj);
		}
		else {

		    # save original article name in data object itself
		    # (will be needed for creating back an XML of this object)
		    my $methodName = pop @articleNames;
		    $mobyObj->original_memberName ($methodName);

		    #is the article name for children empty? throw error
		    $PLOG->error("Invalid article name given for children of '".$obj2->mobyname."'. Please make sure that these fields are not empty.") if $methodName eq "";
		    $self->throw("Invalid article name given for children of '".$obj2->mobyname."'. Please make sure that these fields are not empty.") if $methodName eq "";
		    $methodName = $self->escape_name ($methodName);
		    $self->callMethod(
				      actor     => $obj2,
				      method    => $methodName,
				      parameter => $mobyObj,
				      );
		}
	    }
	}
    }
    elsif ( $element->{LocalName} eq MOBY ) {
	if ( scalar @objectStack == 0 ) {
	    $self->error( "Nothing came out from the parsed XML data.");
	}
	$obj = pop @objectStack;
	$obj = ${$obj};
	if ( not $obj->isa("MOSES::MOBY::Package") ) {
	    $self->error("The input XML does not start with a MOBY tag");
	}
	$result = $obj;
    }
    elsif ( $element->{LocalName} eq MOBYCONTENT ) {
	
	# do nothing
    }
    elsif ( $element->{LocalName} eq SERVICENOTES ) {
	$inServiceNotes = 0;
    }
    elsif ( $element->{LocalName} eq MOBYEXCEPTION ) {
	if ($inServiceNotes) {
	    $obj = pop @objectStack;
	    $obj = ${$obj};
	    ${ $self->vPeek("MOSES::MOBY::Package") }->add_exceptions($obj);
	    $inMobyException = 0;
	}
    }
    elsif ( $element->{LocalName} eq MOBYDATA ) {
	$obj = pop @objectStack;
	$obj = ${$obj};
	${ $self->vPeek("MOSES::MOBY::Package") }->add_jobs($obj);
    }
    elsif ( $element->{LocalName} eq COLLECTION ) {
	$obj = pop @objectStack;
	$obj = ${$obj};
	${ $self->vPeek("MOSES::MOBY::Job") }->add_dataElements($obj);
	$readingCollection = 0;
    }
    elsif ( $element->{LocalName} eq PARAMETER ) {
	$obj = pop @objectStack;
	$obj = ${$obj};
	${ $self->vPeek("MOSES::MOBY::Job") }->add_dataElements($obj);
    }
    elsif ( $element->{LocalName} eq NOTES ) {
	$obj = pop @pcdataStack;
	$obj = ${$obj};
	${ $self->vPeek("MOSES::MOBY::Package") }->serviceNotes($obj);
    }
    elsif ( $element->{LocalName} eq EXCEPTIONCODE ) {
	$obj = pop @pcdataStack;
	$obj = ${$obj};
	if ($inMobyException) {
	    ${ $self->vPeek("MOSES::MOBY::ServiceException") }->code($obj);
	}
    }
    elsif ( $element->{LocalName} eq EXCEPTIONMESSAGE ) {
	$obj = pop @pcdataStack;
	$obj = ${$obj};
	if ($inMobyException ){
	    ${ $self->vPeek("MOSES::MOBY::ServiceException") }->message($obj);
	}
    }
    elsif ( $element->{LocalName} eq VALUE ) {
	$obj = pop @pcdataStack;
	$obj = ${$obj};
	${ $self->vPeek("MOSES::MOBY::Parameter") }->value($obj);
    }
    $PLOG->debug ($self->printInfo) if $PLOG->is_debug;
}

sub characters {
    my ( $self, $characters ) = @_;
    $PLOG->debug ("characters: $characters->{Data}\n") if $PLOG->is_debug;
    
    #	characters is a hash reference with this property:
    #      Data 	The characters from the XML document.
    if ( @pcdataStack . "" == 0 ) {
	return;
    }
    my $text = $characters->{Data};
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    ${ $self->pcdataPeek() } = ${ $self->pcdataPeek() } . $text;
    
}

sub start_document {
    my ( $self, $document ) = @_;
    @objectStack = ();
    @articleNames = ();
    @pcdataStack = ();
    $ignoring    = 0;
}

sub end_document {
    my ( $self, $document ) = @_;
    @objectStack = undef;
    @pcdataStack = undef;
    $ignoring    = 0;
}

sub ignorable_whitespace {
    my ( $self, $characters ) = @_;
}

# returns type MobyObject or dies if shouldBeThere->isa(ref(objectStack.top))
sub vPeek {
    my ( $self, $shouldBeThere ) = @_;
    
    # my version of peek
    my $obj = pop @objectStack;
    push @objectStack, $obj;
    if ( $$obj->isa($shouldBeThere) ) {
	return $obj;
    }
    $PLOG->error("Wrong XML: Expected '$shouldBeThere' - but found " .ref $$obj);
    $self->error("Wrong XML: Expected '$shouldBeThere' - but found " .ref $$obj);
}

# returns type MobyObject
sub peek {
    my ($self) = @_;
    
    # my version of peek
    my $obj = pop @objectStack;
    push @objectStack, $obj;
    return $obj;
}

# returns string references
sub pcdataPeek {
    my ($self) = @_;
    
    # my version of peek
    my $obj = pop @pcdataStack;
    push @pcdataStack, $obj;
    return $obj;
}

# returns the value of an attribute either using a namespace or not
# attributes=>, name=>
sub getValue {
    my ( $self, %hash) = @_;
    my (%attributes, $name);
    
    %attributes = %{$hash{attributes}} if exists $hash{attributes};
    $name = $hash{name} if exists $hash{name};
#	die ("You need to provide attributes and an element name $name.") unless ($name and %attributes);
    
    my $attr =
	$attributes{ "{" . MOBY_XML_NS . "}$name" };
    my $string = $attr->{Value} || "";
    if ( $string eq "" ) {
	$attr = $attributes{"{}$name"};
	$string = $attr->{Value} || "";
    }
    return $string;
    
}

# call a method, methodName, on object actor using parameter
# actor=>, method=> parameter=>
sub callMethod {
    my ( $self, %hash ) = @_;
    my ( $actor, $methodName, $parameter );
    
    $actor = $hash{actor} ||'';
    $methodName = $hash{method} ||'';
    $parameter = $hash{parameter};
    eval { 
		if (ref($actor->$methodName) eq 'ARRAY' ) {
			my $method = "add_$methodName";
			$actor->$method($parameter);
		} else {
			$actor->$methodName($parameter);
		}
    };
    if ($@ and not $insubstitution) {
    	$PLOG->error("Method '$methodName' was not found in the object ". $actor->mobyname);
		$self->error( "Method '$methodName' was not found in the object " . $actor->mobyname);
    }

}

#*********************************************************************
#
#		XML-SAX 2.0 event to set document locator
#	unfortunately, this event is passed along as it should be
#	and as such, reporting exact errors specific to MOBY XML is hard
#
#********************************************************************
sub  set_document_locator {
	my ($self) = shift;
	$PLOG->debug ("setting the document locator");
	my( $loc) = @_;
	$locator = $loc;
}

#*********************************************************************
#
#		XML-SAX 2.0 error events
#
#********************************************************************

sub fatal_error {
    my ($self) = shift;
    my $msg = $self->_format_msg (@_);
    $self->throw ("Parsing XML fatally failed: $msg");
}

sub error {
    my ($self) = shift;
    my $msg = $self->_format_msg (@_);
    $self->throw ("Parsing XML failed: $msg");
}

sub warning {
    my ($self) = shift;
    my $msg = $self->_format_msg (@_);
    $LOG->warning ($msg);
}

sub _format_msg {
    my ($self, $message) = @_;
    return $message unless ref ($message) eq 'XML::SAX::Exception::Parse';

    my $pubId = $message->{PublicId}     || '';
    my $sysId = $message->{SystemId}     || '';
    my $linNo = $message->{LineNumber}   || '?';
    my $colNo = $message->{ColumnNumber} || '?';
    my $msg   = $message->{Message}      || '';

    return "$msg [line $linNo, column $colNo] $sysId $pubId";
}

sub printInfo {
    my $self = shift;
    return unless $PLOG->is_debug;
    use Data::Dumper;
    my $buf =
	  "##########################################################\n"
	. "#                          INFO                          #\n"
	. "##########################################################\n"
	. "Object stack currently holds:\n\tBOTTOM: ";
    foreach (@objectStack) {
	$buf .= Dumper($$_) . "\n";
    }
    $buf .= "TOP\n";
    $buf .= "pcdataStack currently holds:\n\tBOTTOM: ";
    foreach (@pcdataStack) {
	$buf .= Dumper($$_) . "\n";
    }
    $buf .= "TOP\n";
    $buf .=
	  "readingMobyObject: $readingMobyObject\n"
	. "readingCollection: $readingCollection\n"
	. "readingXrefs     : $readingXrefs\n"
	. "readingProvision : $readingProvision\n"
	. "insubstition     : $insubstitution\n"
	. "inServiceNotes   : $inServiceNotes\n"
	. "ignoring         : $ignoring\n";
    $buf .=
	  "##########################################################\n"
	. "#                        END INFO                        #\n"
	. "##########################################################\n";
    return $buf;
}

1;
__END__

=head1 NAME

MOSES::MOBY::Parser - parser of XML BioMoby messages

=head1 SYNOPSIS
	use MOSES::MOBY::Parser;
	
	# create a parser
	my $parser = new MOSES::MOBY::Parser ();
	
	# parse a file $package is a MOSES::MOBY::Pacakge reference
	my $package = $parser->parse ( method => 'file', data => "/home/moby/input.xml" );
	
	# parse a string of xml
	$package = $parser->parse ( method => 'string', data => $inputXML );
	
=head1 DESCRIPTION

The MOSES::MOBY::Parser is a SAX based parser used to parse BioMOBY service XML messages.

The Moby::Parser is able to read Biomoby service/client XML data,
parse the XML and create from them an instance of B<Moby::Package>. 
The parser can be invoked by using the subroutine B<parse>.

The parser depends on generated Perl modules that define all
of the Biomoby data types. There is a generator B<MOSES::MOBY::Generators::GenTypes>
that produces such modules into a package MOSES::MOBY::Data.

There is one situation when the parser tries to substitute an
unknown data type by a known one. If the parsing encoutered an XML
tag depicting a B<top-level> data object (not a member object
of some other data object) and if there is no class available for
such object, the parser can be instructed to create a substituted
object whose name was given in the parser constructor. This is to
prevent situation when a long-time running and deployed service
suddenly gets a request from a client that uses more up-to-date
list of data types. It would be bad to let such service die (or
minimally respond unproperly) just because its modules were
generated too long ago.

Because also skeletons for services can be generated, it is easy to
ensure that a service knows its "the most specialized" data type it
can still served, and that it passes it to the parser constructor.

If the parser finds an unknown object/tag but no substitute was
passed in the parser constructor, it prints a warning and ignores
the whole object, with all its descendants.

The parser also produces a warning if it makes the substitution
described above. Both these warnings should signal that new data
types should be generated, and services restarted. Fortunately, it
does not happen often at all.

Be aware, however, that this substitution may do a wrong thing if
there are more bad top-level objects - such as in case when a
result has more outputs.

If the parser finds another problem, usually related to the invalid
XML, it raises an Exception with error message containing line and column close
to place where the error happened (Not yet, but soon).

One possible problem would be when article names of the member data
types in the parsed XML do not correspond what was registered in
the Biomoby registry. Parser spots it and stops parsing (because
it does not know where to put this member object).

You can test parser by using a simple B<testing-parser.pl>
client. This is how to invoke it and how to get its help:

	 src/scripts/testing-parser.pl -h
	 
Sample input is located in the 'data' directory.

All XML tags and all attribute names that are recognized and
processed by this parser are stored as constants in the module 
B<Moby::Tags>

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them:

=over

=item B<cachedir> 

=item B<registry>

=item B<lowestKnownDataTypes>

=back

=head1 SUBROUTINES

=head2 new

Create a Parser object. The only argument to this method is

	lowestKnownDataTypes => { $input_name => $known_type }.
	
The purpose of lowestKnownDataTypes is mentioned above in the Description.
After constructing a parser, use the 'parse' subroutine.

=head2 parse

Creates a MOSES::MOBY::Package object based on the input XML. This is the only sub that should be
used in this module as the most of the other subroutines in this module implement 
the B<SAX> interface or are used by the subroutines that implement the SAX interface.

parse has the following arguments:
    args: method => 'string', data => direct XML
            OR
          method => 'file',   data => filename


=head1 AUTHORS, COPYRIGHT, DISCLAIMER

 Edward Kawas (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)

Copyright (c) 2006 Martin Senger, Edward Kawas. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided "as is" without warranty of any kind.

