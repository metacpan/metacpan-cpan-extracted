#$Id: CommonSubs.pm,v 1.9 2009/09/01 20:13:20 kawas Exp $

=head1 NAME

MOBY::CommonSubs.pm - a set of exportable subroutines that are
useful in clients and services to deal with the input/output from
MOBY Services

=head1 DESCRIPTION

CommonSubs are used to do various manipulations of MOBY service-invocation and
response messages.  It is useful both Client and Service side and will ensure
that the message structure is valid as per the latest version of the MOBY API.

It DOES NOT connect to MOBY Central for any of its functions, though it does
contact the ontology server for some of its functions, so it may require a
network connection.

NOTE THAT MOST LEGACY SUBROUTINES IN THIS MODULE HAVE BEEN DEPRECATED
The code is still here for legacy reasons only, but the documentation has
been removed permanently, so if there is a routine that you use that is no
longer documented, consider yourself on dangerous ground.  THIS CODE WILL NOT
FUNCTION WITH SERVICES THAT ARE NOT COMPLIANT WITH THE NEW API - FOR EXAMPLE
SERVICES THAT ARE NOT USING NAMED INPUTS AND OUTPUTS!

=head1 COMMON USAGE EXAMPLES

=head2 Client Side Paradigm


The following is a generalized architecture for all
BioMOBY services showing how to parse response messages
using the subroutines provided in CommonSubs

=head3 Services Returning Simples

    my $resp = $SI->execute(XMLInputList => \@input_data);

    my $responses = serviceResponseParser($resp); # returns MOBY objects
    foreach my $queryID(keys %$responses){
        $this_invocation = $responses->{$queryID};  # this is the <mobyData> block with this queryID
        my $this_output = "";

        if (my $data = $this_invocation->{'responseArticleName'}){  # whatever your articleName is...
            # $data is a MOBY::Client::Simple|Collection|ParameterArticle
            my ($namespace) = @{$data->namespaces};
            my $id = $data->id; 
            my $XML_LibXML = $data->XML_DOM;  # get access to the DOM 
            # assuming that you have an element of type "String"
            # with articleName "Description"
            my $desc = getNodeContentWithArticle($XML_LibXML, "String", "Description");
            ###################
            # DO SOMETHING TO RESPOSE DATA HERE
            ###################
        }

    }


=head3 Services Returning Collections

    my $resp = $SI->execute(XMLInputList => \@input_data);

    my $responses = serviceResponseParser($resp); # returns MOBY objects
    foreach my $queryID(keys %$responses){  # $inputs is a hashref of $input{queryid}->{articlename} = input object
        my $this_invocation = $responses->{$queryID};
        if (my $data = $this_invocation->{'responseArticleName'}){ # $input is a MOBY::Client::Simple|Collection|Parameter object
            my $simples = $data->Simples;
            foreach my $simple(@$simples){
                my ($ns) = @{$simple->namespaces};
                my $id = $simple->id;
                my $XML_LibXML = $input->XML_DOM;  # get access to the DOM 

            }
        }
    }




=head2 Service-Side Paradigm

The following is a generalized architecture for *all*
BioMOBY services showing how to parse incoming messages
using the subroutines provided in CommonSubs

=head3 Services Generating simple outputs

sub _generic_service_name {
    my ($caller, $data) = @_; 

    my $MOBY_RESPONSE; 

    my $inputs = serviceInputParser($data); # returns MOBY objects
    return SOAP::Data->type('base64' => responseHeader("illuminae.com") . responseFooter()) unless (keys %$inputs);
    foreach my $queryID(keys %$inputs){
        $this_invocation = $inputs->{$queryID};  # this is the <mobyData> block with this queryID
        my $this_output = "";

        if (my $input = $this_invocation->{incomingRequest}){
            my ($namespace) = @{$input->namespaces};
            my $id = $input->id; 
            my $XML_LibXML = $input->XML_DOM;  # get access to the DOM 

            ###################
            # DO YOUR BUSINESS LOGIC HERE
            ###################

            $this_output = "<moby:Object... rest of the output XML .../>";
        }

        $MOBY_RESPONSE .= simpleResponse(
                  $this_output   
                , "myArticleName" # the article name of that output object
                , $queryID);      # the queryID of the input that we are responding to
    }
    return SOAP::Data->type('base64' => (responseHeader("illuminae.com") . $MOBY_RESPONSE . responseFooter));
 }

=head3 Services generating collection outputs 

sub _generic_service_returning_collections {
    my($caller, $message) = @_;
    my $inputs = serviceInputParser($message);
    my $MOBY_RESPONSE = "";           # set empty response

    # return empty SOAP envelope if ther is no moby input

    return SOAP::Data->type('base64' => responseHeader().responseFooter()) unless (keys %$inputs);

    foreach my $queryID(keys %$inputs){  # $inputs is a hashref of $input{queryid}->{articlename} = input object
        my $this_invocation = $inputs->{$queryID};
        my @outputs;
        if (my $input = $this_invocation->{incomingArticleName}){ # $input is a MOBY::Client::Simple|Collection|Parameter object
                my $id = $input->id;
                my @agis = &_getMyOutputList($id);  # this subroutine contains your business logic and returns a list of ids
                foreach (@agis){
                        push @outputs, "<Object namespace='MyNamespace' id='$_'/>";
                }
        }
        $MOBY_RESPONSE .= collectionResponse (\@outputs, "myOutputArticleName", $queryID);
    }
    return SOAP::Data->type('base64' => (responseHeader("my.authority.org") . $MOBY_RESPONSE . responseFooter));
 }



=head1 EXAMPLE SERVICE CODE


A COMPLETE EXAMPLE OF AN EASY MOBY SERVICE

This is a service that:

 CONSUMES:  base Object in the GO namespace
 EXECUTES:  Retrieval
 PRODUCES:  GO_Term (in the GO namespace)


 # this subroutine is called from your dispatch_with line
 # in your SOAP daemon


 sub getGoTerm {

    use MOBY::CommonSubs qw{:all};
    my ($caller, $incoming_message) = @_;
    my $MOBY_RESPONSE; # holds the response raw XML
    my @validNS = validateNamespaces("GO");  # do this if you intend to be namespace aware!

    my $dbh = _connectToGoDatabase();  # connect to some database
    return SOAP::Data->type('base64' => responseHeader('my.authURI.com') . responseFooter()) unless $dbh;
    my $sth = $dbh->prepare(q{   # prepare your query
       select name, term_definition
       from term, term_definition
       where term.id = term_definition.term_id
       and acc=?});

    my $inputs= serviceInputParser($incoming_message); # get incoming invocations
        # or fail properly with an empty response if there is no input
    return SOAP::Data->type('base64' => responseHeader("my.authURI.com") . responseFooter()) unless (keys %$inputs);

    foreach my $queryID(keys %$inputs){
        my $this_invocation = $inputs->{$queryID};  # this is the <mobyData> block with this queryID
        my $invocation_output=""; # prepare a variable to hold the output XML from this invocation

        if (my $input = $this_invocation->{GO_id}){  # the articleName of your services input            
            my ($namespace) = @{$input->namespaces}; # this is returned as a list!
            my $id = $input->id;

            # optional - if we want to ENSURE that the incoming ID is in the GO namespace
            # we can validate it using the validateThisNamespace routine of CommonSubs
            # @validNS comes from validateNamespaces routine of CommonSubs (called above)
            next unless validateThisNamespace($namespace, @validNS); 

            # here's our business logic...
            $sth->execute($id);
            my ($term, $def) = $sth->fetchrow_array;
            if ($term){
                 $invocation_output =
                 "<moby:GO_Term namespace='GO' id='$id'>
                  <moby:String namespace='' id='' articleName='Term'>$term</moby:String>
                  <moby:String namespace='' id='' articleName='Definition'>$def</moby:String>
                 </moby:GO_Term>";
            }
        }

        # was our service execution successful?
        # if so, then build an output message
        # if not, build an empty output message
        $MOBY_RESPONSE .= simpleResponse( # simpleResponse is exported from CommonSubs
            $invocation_output   # response for this query
            , "A_GoTerm"  # the article name of that output object
            , $queryID);    # the queryID of the input that we are responding to
     }
    # now return the result
    return SOAP::Data->type('base64' => (responseHeader("illuminae.com") . $MOBY_RESPONSE . responseFooter));
}


=cut

package MOBY::CommonSubs;
use strict;
use warnings;

require Exporter;
use XML::LibXML;

use MOBY::CrossReference;
use MOBY::Client::OntologyServer;
use MOBY::Client::SimpleArticle;
use MOBY::Client::CollectionArticle;
use MOBY::Client::SecondaryArticle;
use MOBY::MobyXMLConstants;

# create the namespace URI 
# can be modified by clients if they see fit using
# $MOBY::CommonSubs::MOBY_NS
our $MOBY_NS = 'http://www.biomoby.org/moby';

use constant COLLECTION => 1;
use constant SIMPLE     => 2;
use constant SECONDARY  => 3;
use constant PARAMETER  => 3;    # be friendly in case they use this instead
use constant BE_NICE    => 1;
use constant BE_STRICT  => 0;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(COLLECTION SIMPLE SECONDARY PARAMETER BE_NICE BE_STRICT);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;

our %EXPORT_TAGS = (
	all => [
		qw(
		  getSimpleArticleIDs
		  getSimpleArticleNamespaceURI
		  getInputArticles
		  getInputs
		  getInputID
		  getArticles
		  getCollectedSimples
		  getNodeContentWithArticle
		  extractRawContent
		  validateNamespaces
		  validateThisNamespace
		  isSimpleArticle
		  isCollectionArticle
		  isSecondaryArticle
		  extractResponseArticles
		  getResponseArticles
		  getCrossReferences
		  getExceptions
		  genericServiceInputParser
		  genericServiceInputParserAsObject
		  complexServiceInputParser
		  serviceInputParser
		  serviceResponseParser
		  whichDeepestParentObject
		  getServiceNotes
		  simpleResponse
		  collectionResponse
		  complexResponse
		  responseHeader
		  responseFooter
		  encodeException
		  COLLECTION
		  SIMPLE
		  SECONDARY
		  PARAMETER
		  BE_NICE
		  BE_STRICT
		  )
	]
);


our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

=head1 PARSING MOBY INPUT AND OUTPUT

=head2 serviceInputParser and serviceResponseParser

B<function:> These routines will take a Moby invocation (server side usage) or
response (client-side usage) and extract the Simple/Collection/Parameter objects out of it
as MOBY::Client::SimpleArticle, MOBY::Client::CollectionArticle,
and/or MOBY::Client::SecondaryArticle objects.  The inputs are broken
up into individual queryID's.  Each queryID is associated with
one or more individual articles, and each article is available by its articleName.

B<usage:> C<my $inputs = serviceInputParser($MOBY_invocation_mssage));>
B<usage:> C<my $outputs = serviceResponseParser($MOBY_response_message));>

B<args:> C<$message> - this is the SOAP payload; i.e. the XML document containing the MOBY message

B<returns:> C<$inputs> or C<$outputs> are a hashref with the following structure:

   $Xputs->{$queryID}->{articleName} =
       MOBY::Client::SimpleArticle |
       MOBY::Client::CollectionArticle |
       MOBY::Client::SecondaryArticle 

the SimpleArticle and CollectionArticle have methods to provide you with their
objectType, their namespace and their ID.  If you want to get more out of them,
you should retrieve the XML::LibXML DOM using the ->XML_DOM method call
in either of those objects.  This can be passed into other CommonSubs routines
such as getNodeContentWithArticle in order to retrieve sub-components of the
Moby object you have in-hand.


See also:

=head3  Simples

For example, the input message:

      <mobyData queryID = 'a1a'>
          <Simple articleName='name1'>
             <Object namespace=blah id=blah/>
          </Simple>
          <Parameter articleName='cutoff'>
             <Value>10</Value>
          </Parameter>
      </mobyData>

will become:

            $inputs->{a1a}->{name1} =  $MOBY::Client::Simple, # the <Simple> block
            $inputs->{a1a}->{cutoff} =  $MOBY::Client::Secondary # <Parameter> block


=head3  Collections 

With inputs that have collections these are presented as a listref of
Simple article DOM's.  So for the following message:

   <mobyData queryID = '2b2'>
       <Collection articleName='name1'>
         <Simple>
          <Object namespace=blah id=blah/>
         </Simple>
         <Simple>
          <Object namespace=blah id=blah/>
         </Simple>
       </Collection>
       <Parameter articleName='cutoff'>
          <Value>10</Value>
       </Parameter>
   </mobyData>

will become

            $inputs->{2b2}->{name1} = $MOBY::Client::Collection, #  the <Collection> Block
            $inputs->{2b2}->{cutoff} = $MOBY::Client::Secondary, #  the <Parameter> Block




=cut

sub serviceInputParser {
	my ( $message ) = @_;    # get the incoming MOBY query XML
	my @inputs;              # set empty response
	my @queries = _getInputs( $message );   # returns XML::LibXML nodes <mobyData>...</mobyData>
	my %input_parameters;      # $input_parameters{$queryID} = [
	foreach my $query ( @queries ) {
            my $queryID =  _getQID( $query );    # get the queryID attribute of the mobyData
            next unless $queryID;
            my @input_articles = _getArticlesAsObjects( $query );
	    # This is done for empty mobyData. It is a strange case
	    # but it can happen (a service which is a random answer
	    # generator, for instance)
	    $input_parameters{$queryID}={};
            foreach my $article ( @input_articles ) { 
                ${$input_parameters{$queryID}}{$article->articleName} =  $article if $article and $article->articleName ne '';
            }
	}
	return \%input_parameters;
}

*serviceResponseParser = \&serviceInputParser;
*serviceResponseParser = \&serviceInputParser;

sub _getInputs {
  my ( $XML ) = @_;
  my $moby =  _string_to_DOM($XML);
  my @queries;
  foreach my $querytag (qw(mobyData ))
    {
      my $x = $moby->getElementsByLocalName( $querytag );    # get the mobyData block
      for ( 1 .. $x->size() ) {    # there may be more than one mobyData per message
	push @queries, $x->get_node( $_ );
      }
    }
  return @queries;    # return them in the order that they were discovered.
}


sub _getArticlesAsObjects {
  my ( $moby ) = @_;
  $moby = _string_to_DOM($moby);
  return undef unless $moby->nodeType == ELEMENT_NODE;
  return undef
    unless ($moby->localname =~ /^mobyData$/ and ($moby->namespaceURI() ? $moby->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1));
  my @articles;
  foreach my $child ( $moby->childNodes )
    { # there may be more than one Simple/Collection per input; iterate over them
      next unless $child->nodeType == ELEMENT_NODE;    # ignore whitespace
      next
	unless ( $child->localname =~ /^(Simple|Collection|Parameter)$/ and ($child->namespaceURI() ? $child->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1));
      my $object;
      if ( $child->localname=~ /^Simple$/ and ($child->namespaceURI() ? $child->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) {
	$object = MOBY::Client::SimpleArticle->new( XML_DOM => $child );
      } elsif ( $child->localname=~ /^Collection$/ and ($child->namespaceURI() ? $child->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) {
	$object = MOBY::Client::CollectionArticle->new( XML_DOM => $child );
      } elsif ( $child->localname =~ /^Parameter$/ and ($child->namespaceURI() ? $child->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) {
	$object = MOBY::Client::SecondaryArticle->new( XML_DOM => $child );
      }
      next unless $object;
      push @articles, $object;  # take the child elements, which are <Simple/> or <Collection/>
    }
  return @articles;    # return them.
}


sub _getQID {
  my ( $XML ) = @_;
  my $moby = _string_to_DOM($XML);
  return '' unless ( $moby->localname =~ /^mobyData$/ and ($moby->namespaceURI() ? $moby->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1));
  my $qid =  _moby_getAttribute($moby, 'queryID' );
  $qid ||= _moby_getAttribute($moby, 'moby:queryID' );
  return defined( $qid ) ? $qid : '';
}


=head1 MESSAGE COMPONENT IDENTITY AND VALIDATION

This section describes functionality associated with identifying parts of a message,
and checking that it is valid.

=head2 isSimpleArticle, isCollectionArticle, isSecondaryArticle

B<function:> tests XML (text) or an XML DOM node to see if it represents a Simple, Collection, or Secondary article

These routines are unlikely to be useful in a MOBY Object oriented service
but they have been retained for legacy reasons.

B<usage:> 

  if (isSimpleArticle($node)){do something to it}

or

  if (isCollectionArticle($node)){do something to it}

or

 if (isSecondaryArticle($node)){do something to it}

B< input :> an XML::LibXML node, an XML::LibXML::Document or straight XML

B<returns:> boolean

=cut

sub isSimpleArticle {
  my ( $DOM ) = @_;
  eval { $DOM = _string_to_DOM($DOM) };
  return 0 if $@;
  $DOM = $DOM->getDocumentElement if ( $DOM->isa( "XML::LibXML::Document" ) );
  return ($DOM->localname =~ /^Simple$/ and ($DOM->namespaceURI() ? $DOM->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) ? 1 : 0; #Optional 'moby:' namespace prefix
}

sub isCollectionArticle {
  my ( $DOM ) = @_;
  eval {$DOM = _string_to_DOM($DOM) };
  return 0 if $@;
  $DOM = $DOM->getDocumentElement if ( $DOM->isa( "XML::LibXML::Document" ) );
  return ( $DOM->localname =~ /^Collection$/ and ($DOM->namespaceURI() ? $DOM->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) ? 1 : 0; #Optional 'moby:' prefix
}

sub isSecondaryArticle {
  my ( $XML ) = @_;
  my $DOM;
  eval {$DOM = _string_to_DOM($XML)} ;
  return 0 if $@;
  $DOM = $DOM->getDocumentElement if ( $DOM->isa( "XML::LibXML::Document" ) );
  return ($DOM->localname =~ /^Parameter$/ and ($DOM->namespaceURI() ? $DOM->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) ? 1 : 0; #Optional 'moby:' prefix
}


=head2 validateNamespaces

B<function:> checks the namespace ontology for the namespace lsid

B<usage:> C<@LSIDs = validateNamespaces(@namespaces)>

B<args:> ordered list of either human-readable or lsid presumptive namespaces

B<returns:> ordered list of the LSID's corresponding to those
presumptive namespaces; undef for each namespace that was invalid

=cut

sub validateNamespaces {
  # give me a list of namespaces and I will return the LSID's in order
  # I return undef in that list position if the namespace is invalid
  my ( @namespaces ) = @_;
  my $OS = MOBY::Client::OntologyServer->new;
  my @lsids;
  foreach ( @namespaces ) {
    my ( $s, $m, $LSID ) = $OS->namespaceExists( term => $_ );
    push @lsids, $s ? $LSID : undef;
  }
  return @lsids;
}

=head2 validateThisNamespace

B<function:> checks a given namespace against a list of valid namespaces

B<usage:> C<$valid = validateThisNamespace($ns, @validNS);>

B<args:> ordered list of the namespace of interest and the list of valid NS's

B<returns:> boolean

=cut

sub validateThisNamespace {
  my ( $ns, @namespaces ) = @_;
  return 1 unless scalar @namespaces; # if you don't give me a list, I assume everything is valid...
  @namespaces = @{$namespaces[0]}  # if you send me an arrayref I should be kind... DWIM!
    if ( ref $namespaces[0] eq 'ARRAY' );
  return grep /$ns/, @namespaces;
}

=head1 CONSTRUCTING OUTPUT

This section describes how to construct output, in response to an
incoming message. Responses come in three varieties:

=over 4

=item *
Simple     - Only simple article(s)

=item *
Collection - Only collection(s) of simples

=item *
Complex    - Any combination of simple and/or collection and/or secondary articles.

=back

=head2 simpleResponse

B<function:> wraps a simple article in the appropriate (mobyData) structure.
Works only for simple articles. If you need to mix simples with collections and/or 
secondaries use complexReponse instead.

B<usage:> C<$responseBody = simpleResponse($object, $ArticleName, $queryID);>

B<args:> (in order)
C<$object>      - (optional) a MOBY Object as raw XML.
C<$articleName> - (optional) an article name for this article.
C<$queryID>     - (optional, but strongly recommended) the query ID value for the mobyData block to which you are responding.

B<notes:> As required by the API you must return a response for every
input.  If one of the inputs was invalid, you return a valid (empty)
MOBY response by calling simpleResponse(undef, undef, $queryID) with
no arguments.

=cut

sub simpleResponse {
  my ( $data, $articleName, $qID ) = @_;    # articleName optional
  $qID = _getQueryID( $qID )
    if ref( $qID ) =~ /XML\:\:LibXML/;    # in case they send the DOM instead of the ID
  $data        ||= '';    # initialize to avoid uninit value errors
  $articleName ||= "";
  $qID         ||= "";
  if ( $articleName || $data) { # Linebreaks in XML make it easier for human debuggers to read!
    return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Simple moby:articleName='$articleName'>$data</moby:Simple>
        </moby:mobyData>
        ";
  } else {
    return "
        <moby:mobyData moby:queryID='$qID'/>
	";
  }
}


=head2 collectionResponse

B<function:> wraps a set of articles in the appropriate mobyData structure. 
Works only for collection articles. If you need to mix collections with simples and/or 
secondaries use complexReponse instead.

B<usage:> C<$responseBody = collectionResponse(\@objects, $articleName, $queryID);>

B<args:> (in order)
C<\@objects>    - (optional) a listref of MOBY Objects as raw XML.
C<$articleName> - (optional) an artice name for this article.
C<$queryID>     - (optional, but strongly recommended) the ID of the query to which you are responding.

B<notes:> as required by the API you must return a response for every
input.  If one of the inputs was invalid, you return a valid (empty)
MOBY response by calling collectionResponse(undef, undef, $queryID).

=cut

sub collectionResponse {
  my ( $data, $articleName, $qID ) = @_;    # articleName optional
  my $content = "";
  $data ||= [];
  $qID  ||= '';
  # The response should only be completely empty when the input $data is completely empty.
  # Testing just the first element is incorrect.
  my $not_completely_empty = 0;
  foreach (@{$data}) { $not_completely_empty += defined $_ }
  unless ( ( ref($data) eq 'ARRAY' ) && $not_completely_empty )
    {    # we're expecting an arrayref as input data, and it must not be empty
      return "<moby:mobyData moby:queryID='$qID'/>";
    }
  foreach ( @{$data} ) { # Newlines are for ease of human reading (pretty-printing). 
    # It's really hard to keep this kind of thing in sync with itself, but for what it's worth, let's leave it in.
    if ( $_ ) {
      $content .= "<moby:Simple>$_</moby:Simple>\n";
    } else {
      $content .= "<moby:Simple/>\n";
    }
  }
  if ( $articleName ) {
    return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Collection moby:articleName='$articleName'>
                $content
            </moby:Collection>
        </moby:mobyData>
        ";
  } else {
    return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Collection moby:articleName='$articleName'>$content</moby:Collection>
        </moby:mobyData>
        ";
  }
}

=head2 complexResponse

B<function:> wraps articles in the appropriate (mobyData) structure. 
Can be used to send any combination of the three BioMOBY article types - 
simple, collection and secondary - back to a client.

B<usage:> C<$responseBody = complexResponse(\@articles, $queryID);>

B<args:> (in order)

C<\@articles>   - (optional) a listref of arrays. Each element of @articles is
itself a listref of [$articleName, $article], where $article is either
the article's raw XML for simples and secondaries or a reference to an array containing 
[$articleName, $simpleXML] elements for a collection of simples.

C<$queryID> - the queryID value for
the mobyData block to which you are responding

B<notes:> as required by the API you must return a response for every
input.  If one of the inputs was invalid, you return a valid (empty)
MOBY response by calling complexResponse(undef, $queryID) with no
arguments.

=cut

sub complexResponse {
  my ( $data, $qID ) = @_;
  #return 'ERROR:  expected listref [element1, element2, ...] for data' unless ( ref( $data ) =~ /array/i );
  return "<moby:mobyData moby:queryID='$qID'/>\n"
    unless ( ref( $data ) eq 'ARRAY' );
  $qID = _getQueryID( $qID )
    if ref( $qID ) =~ /XML\:\:LibXML/;    # in case they send the DOM instead of the ID
  my @inputs = @{$data};
  my $output = "<moby:mobyData queryID='$qID'>";
  foreach ( @inputs ) {
    #return 'ERROR:  expected listref [articleName, XML] for data element' unless ( ref( $_ ) =~ /array/i );
    return "<moby:mobyData moby:queryID='$qID'/>\n" 
      unless ( ref($_) eq 'ARRAY' );
    while ( my ( $articleName, $XML ) = splice( @{$_}, 0, 2 ) ) {
      if ( ref($XML) ne 'ARRAY' ) {
        $articleName ||= "";
        $XML         ||= "";
        if ( $XML =~ /\<(moby:|)Value\>/ ) {
          $output .=
            "<moby:Parameter moby:articleName='$articleName'>$XML</moby:Parameter>\n";
        } else {
          $output .=
            "<moby:Simple moby:articleName='$articleName'>\n$XML\n</moby:Simple>\n";
        }
      # Need to do this for collections also!!!!!!
      } else {
        my @objs = @{$XML};
        $output .= "<moby:Collection moby:articleName='$articleName'>\n";
        foreach ( @objs ) {
          $output .= "<moby:Simple>$_</moby:Simple>\n";
        }
        $output .= "</moby:Collection>\n";
      }
    }
  }
  $output .= "</moby:mobyData>\n";
  return $output;
}

=head2 responseHeader

B<function:> print the XML string of a MOBY response header +/- serviceNotes +/- Exceptions

B<usage:> 

  responseHeader('illuminae.com')

  responseHeader(
                -authority => 'illuminae.com',
                -note => 'here is some data from the service provider'
                -exception=>'an xml encoded exception string')


B<args:> a string representing the service providers authority URI, OR
a set of named arguments with the authority and the service provision
notes which can include already xml encoded exceptions

B< caveat   :>

B<notes:>  returns everything required up to the response articles themselves. i.e. something like:

 <?xml version='1.0' encoding='UTF-8'?>
    <moby:MOBY xmlns:moby='http://www.biomoby.org/moby'>
       <moby:Response moby:authority='http://www.illuminae.com'>

=cut

sub responseHeader {
  use HTML::Entities ();
  my ( $auth, $notes, $exception ) = _rearrange( [qw[AUTHORITY NOTE EXCEPTION]], @_ );
  $auth  ||= "not_provided";
  $notes ||= "";
  $exception ||="";
  my $xml =
    "<?xml version='1.0' encoding='UTF-8'?>"
    . "<moby:MOBY xmlns:moby='$MOBY_NS' xmlns='$MOBY_NS'>"
    . "<moby:mobyContent moby:authority='$auth'>";
  if ($exception) {
    $xml .= "<moby:serviceNotes>$exception";
    if ( $notes ) {
        my $encodednotes = HTML::Entities::encode( $notes );
        $xml .= "<moby:Notes>$encodednotes</moby:Notes>";
    }
    $xml .="</moby:serviceNotes>";
  }
  
  elsif ( $notes ) {
    my $encodednotes = HTML::Entities::encode( $notes );
    $xml .= "<moby:serviceNotes><moby:Notes>$encodednotes</moby:Notes></moby:serviceNotes>";
  }
  return $xml;
}


=head2 encodeException

B<function:> wraps a  Biomoby Exception with all its parameters into the appropiate MobyData structure

B<usage:> 

  encodeException(
                -refElement => 'refers to the queryID of the offending input mobyData',
                -refQueryID => 'refers to the articleName of the offending input Simple or Collection'
                -severity=>'error'
                -exceptionCode=>'An error code '
                -exceptionMessage=>'a human readable description for the error code')

B<args:>the different arguments required by the mobyException API
        severity can be either error, warning or information
        valid error codes are decribed on the biomoby website


B<notes:>  returns everything required to use for the responseHeader:

  <moby:mobyException moby:refElement='input1' moby:refQueryID='1' moby:severity =''>
                <moby:exceptionCode>600</moby:exceptionCode>
                <moby:exceptionMessage>Unable to execute the service</moby:exceptionMessage>
            </moby:mobyException>

=cut

sub encodeException{
  use HTML::Entities ();
  my ( $refElement, $refQueryID, $severity, $code, $message ) = _rearrange( [qw[REFELEMENT REFQUERYID SEVERITY EXCEPTIONCODE EXCEPTIONMESSAGE]], @_ );
  $refElement  ||= "";
  defined($refQueryID)  || ($refQueryID= "");
  $severity ||= "";
  defined($code) || ($code = "");
  $message ||= "not provided";
  my $xml="<moby:mobyException moby:refElement='$refElement' moby:refQueryID='$refQueryID' moby:severity ='$severity'>".
          "<moby:exceptionCode>$code</moby:exceptionCode>".
          "<moby:exceptionMessage>".HTML::Entities::encode($message)."</moby:exceptionMessage>".
          "</moby:mobyException>";
}

=head2 responseFooter

B<function:> print the XML string of a MOBY response footer

B<usage:> 

 return responseHeader('illuminae.com') . $DATA . responseFooter;

B<notes:>  returns everything required after the response articles themselves i.e. something like:

  </moby:Response>
     </moby:MOBY>

=cut

sub responseFooter {
  return "</moby:mobyContent></moby:MOBY>";
}



=head1 ANCILIARY ELEMENTS

This section contains subroutines that handle processing of optional message elements containing
meta-data. Examples are the ServiceNotes, and CrossReference blocks.

=head2 getServiceNotes

B<function:> to get the content of the Service Notes block of the MOBY message

B<usage:> C<getServiceNotes($message)>

B<args:> C<$message> is either the XML::LibXML of the MOBY message, or plain XML

B<returns:> String content of the ServiceNotes block of the MOBY Message

=cut

sub getServiceNotes {
  my ( $result ) = @_;
  return ( "" ) unless $result;
  my $moby = _string_to_DOM($result);
  my $responses = $moby->findnodes(".//serviceNotes/Notes | .//moby:serviceNotes/moby:Notes");
  my $content;
  foreach my $n ( 1 .. ( $responses->size() ) ) {
    my $resp = $responses->get_node( $n );
    foreach my $response_component ( $resp->childNodes ) {
      #            $content .= $response_component->toString;
      $content .= $response_component->nodeValue
	if ( $response_component->nodeType == TEXT_NODE );
      $content .= $response_component->nodeValue
	if ( $response_component->nodeType == CDATA_SECTION_NODE );
    }
  }
  return ( $content );
}

=head2 getExceptions

B<function:> to get the content of the Exception part of the Service Notes block of the MOBY message

B<usage:> C<getExceptions($message)>

B<args:> C<$message> is either the XML::LibXML of the MOBY message, or plain XML

B<returns:> an Array of Hashes containing the exception Elemtents and attributes

B<example:> my @ex=getExceptions($XML); 
            foreach my $exception (@ex) {
               print "Reference:",$exception->{refElement},"\n";
               print "Query ID:",$exception->{refQueryID},"\n";
               print "Severity of message:",$exception->{severity},"\n";
               print "Readable message:",$exception->{exceptionMessage},"\n";
               print "Exception Code:",$exception->{exceptionCode},"\n";
            }


=cut

sub getExceptions {
  my ( $result ) = @_;
  return ( "" ) unless $result;
  my $moby = _string_to_DOM($result);
  my $responses = $moby->findnodes(".//serviceNotes/mobyException | .//moby:serviceNotes/moby:mobyException");
  my @exceptions;
  foreach my $n ( 1 .. ( $responses->size() ) ) {
    my $except={};
    my $resp = $responses->get_node( $n );
    $except->{refElement}=$resp->getAttribute("refElement") || $resp->getAttribute("moby:refElement");
    $except->{refQueryID}=$resp->getAttribute("refQueryID") || $resp->getAttribute("moby:refQueryID");
    $except->{severity}=$resp->getAttribute("severity") || $resp->getAttribute("moby:severity");
    foreach my $child ($resp->childNodes) {
      if ($child->toString=~/exceptionCode>(.+)<\//) {$except->{exceptionCode}=$1};
      if($child->toString=~/exceptionMessage>(.+)<\//) {$except->{exceptionMessage}=$1};
    }
    push @exceptions,$except;
   }
  return ( @exceptions );
}


=head2 getCrossReferences

B<function:> to get the cross-references for a Simple article.  This is primarily a
             Client-side function, since service providers should not, usually, be
             interpreting Cross-references.

B<usage:> C<@xrefs = getCrossReferences($XML)>

B<args:> C<$XML> is either a SIMPLE article (<Simple>...</Simple>) or an
object (the payload of a Simple article), and may be either raw XML or
an XML::LibXML node.

B<returns:> an array of MOBY::CrossReference objects

B<example:>

   my (($colls, $simps) = getResponseArticles($query);  # returns DOM nodes
   foreach (@{$simps}){
      my @xrefs = getCrossReferences($_);
      foreach my $xref(@xrefs){
          print "Cross-ref type: ",$xref->type,"\n";
          print "namespace: ",$xref->namespace,"\n";
          print "id: ",$xref->id,"\n";
          if ($xref->type eq "Xref"){
             print "Cross-ref relationship: ", $xref->xref_type,"\n";
          }
      }
   }

=cut

sub getCrossReferences {
  my ( $XML ) = @_;
  if ($XML =~ /MOBY::Client/){$XML = $XML->XML_DOM}
  $XML = _string_to_DOM($XML);
  my @xrefs;
  my @XREFS;
  return () if ( $XML->localname =~ /^Collection$/ and ($XML->namespaceURI() ? $XML->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1));
  if ( $XML->localname =~ /^Simple$/ and ($XML->namespaceURI() ? $XML->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) {
    foreach my $child ( $XML->childNodes ) {
      next unless $child->nodeType == ELEMENT_NODE;
      $XML = $child;
      last;    # enforce proper MOBY message structure
    }
  }
  foreach ( $XML->childNodes ) {
    next unless (($_->nodeType == ELEMENT_NODE)
		 || ($_->localname && $_->localname =~ /^CrossReference$/ and ($_->namespaceURI() ? $_->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) );
    foreach my $xref ( $_->childNodes ) {
      next unless $xref && ( ($xref->nodeType == ELEMENT_NODE)
		    || ($xref->localname && $xref->localname =~ /^(Xref|Object)$/ and ($xref->namespaceURI() ? $xref->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) );
      push @xrefs, $xref;
    }
  }
  foreach ( @xrefs ) {
    my $x;
    if ($_->localname =~ /^Xref$/ and ($_->namespaceURI() ? $_->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) { $x = _makeXrefType( $_ ) }
    elsif ($_->localname =~ /^Object$/ and ($_->namespaceURI() ? $_->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) { $x = _makeObjectType( $_ ) }
    push @XREFS, $x if $x;
  }
  return @XREFS;
}


=head1 MISCELLANEOUS FUNCTIONS

This section contains routines that didn't quite seem to fit anywhere else.

=head2 getNodeContentWithArticle

B<function:>   give me a DOM, a TagName, an articleName and I will return you the content
                 of that node **as a string** (beware if there are additional XML tags in there!)
                 this is meant for MOBYesque PRIMITIVES - things like:
                 <String articleName="SequenceString">TAGCTGATCGAGCTGATGCTGA </String>
                 call _getNodeContentsWithAttribute($DOM_NODE, "String", "SequenceString")
                 and I will return "TACGATGCTAGCTAGCGATCGG"
                 Caveat Emptor - I will NOT chop off leading and trailing whitespace or
                 carriage returns, as these might be meaningful!

B<usage:> C<@content = getNodeContentWithArticle($XML_DOM, $elementname, $articleName)>

B<args:> $XML_DOM is the DOM of a MOBY Object
         $elementName is the Tag of an XML element
         $articleName is the articleName attribute of the desired XML element

B<returns:> an array of strings representing every line of every match (you probably want to
            concatenate these with a "join"... probably...

B<example:>
   given
   <SomeObject namespace='' id=''>
       <String namespace='' id='' articleName="SequenceString">TAGCTGATCGAGCTGATGCTGA </String>
   </SomeObject>

   my $seq = getNodeContentWithArticle($DOM, "String", "SequenceString");
   print "yeah!" if $seq eq "TAGCTGATCGAGCTGATGCTGA";


=cut

sub getNodeContentWithArticle {
  my ( $node, $element, $articleName ) = @_;
  my @contents;
  return () unless ( (ref( $node ) =~ /XML\:\:LibXML/) &&  $element);

  my $nodes = $node->getElementsByTagName( $element );
  unless ( $nodes->get_node( 1 ) ) {
    $nodes = $node->getElementsByTagName("moby:$element");
  }
  $node = $nodes->get_node(1);  # this routine should only ever be called if there is only one possible answer, so this is safe
  
  unless ($articleName){  # the request is for root node if no articleName
    my $resp;
    foreach my $child($node->childNodes){
      next unless ($child->nodeType == TEXT_NODE
		   || $child->nodeType == CDATA_SECTION_NODE);
      $resp .= $child->nodeValue;
    }
    push @contents, $resp;
    return @contents;
  }

  # if there is an articleName, then get that specific node
  for ( 1 .. $nodes->size() ) {
    my $child = $nodes->get_node( $_ );
    if ( _moby_getAttribute($child, "articleName")
	 && ( _moby_getAttribute($child, "articleName") eq $articleName )
       )
      {
	# now we have a valid child, get the content... stringified... regardless of what it is
	if ( isSecondaryArticle( $child ) ) {
	  my $resp;
	  my $valuenodes = $child->getElementsByTagName('Value');
	  unless ( $valuenodes->get_node( 1 ) ) {
	    $valuenodes = $child->getElementsByTagName("moby:Value");
	  }
	  for ( 1 .. $valuenodes->size() ) {
	    my $valuenode = $valuenodes->get_node( $_ );
	    foreach my $amount ( $valuenode->childNodes ) {
	      next unless ($amount->nodeType == TEXT_NODE
			   || $amount->nodeType == CDATA_SECTION_NODE);
	      $resp .= $amount->nodeValue;
	    }
	  }
	  push @contents, $resp;
	} else {
	  my $resp;
	  foreach ( $child->childNodes ) {
	    next unless ($_->nodeType == TEXT_NODE
			 || $_->nodeType == CDATA_SECTION_NODE);
	    $resp .= $_->nodeValue;
	  }
	  push @contents, $resp;
	}
      }
  }
  return @contents;
}


=head2 whichDeepestParentObject

B<function:> select the parent node from nodeList that is closest to the querynode

B<usage:> 

  ($term, $lsid) = whichDeepestParentObject($CENTRAL, $queryTerm, \@termList)

B<args:> 

C<$CENTRAL> - your MOBY::Client::Central object

C<$queryTerm> - the object type I am interested in

C<\@termlist> - the list of object types that I know about

B<returns:> an ontology term and LSID as a scalar, or undef if there is
no parent of this node in the nodelist.  note that it will only return
the term if you give it term names in the @termList.  If you give it
LSID's in the termList, then both the parameters returned will be
LSID's - it doesn't back-translate...)

=cut


sub whichDeepestParentObject {
	my ( $CENTRAL, $queryTerm, $termlist ) = @_;
	return ( undef, undef )
	  unless ( $CENTRAL && $queryTerm 
		   && $termlist && ( ref( $termlist ) eq 'ARRAY' ) );
	my %nodeLSIDs;
	my $queryLSID = $CENTRAL->ObjLSID( $queryTerm );
	foreach ( @$termlist ) {    # get list of known LSIDs
	  my $lsid = $CENTRAL->ObjLSID( $_ );
	  return ( $_, $lsid )
	    if ( $lsid eq $queryLSID );   # of course, if we find it in the list, then return it right away!
	  $nodeLSIDs{$lsid} = $_;
	}
	return ( undef, undef ) unless keys( %nodeLSIDs );
	my $isa =
	  $CENTRAL->ISA( $queryTerm, 'Object' )
	  ;       # set the complete parentage in the cache if it isn't already
	return ( undef, undef )
	  unless $isa;    # this should return true or we are in BIIIG trouble!
	my @ISAlsids =
	  $CENTRAL->ISA_CACHE( $queryTerm )
	  ;    # returns **LSIDs** in order, so we can shift our way back to root
	while ( my $thislsid = shift @ISAlsids ) {    # @isas are lsid's
		return ( $nodeLSIDs{$thislsid}, $thislsid ) if $nodeLSIDs{$thislsid};
	}
	return ( undef, undef );
}


#B<function:> Perform the same task as the DOM routine
#getAttribute(Node), but check for both the prefixed and un-prefixed
#attribute name (the prefix in question being, of course,
#"moby:"). 
#
#B<usage:>
#
#  $id = _moby_getAttribute($xml_libxml, "id");
#
#where C<id> is an attribute in the XML block given as C<$xml_libxml>
#
#B<notes:> This function is intended for use internal to this package
#only. It's not exported.
#
#=cut

sub _moby_getAttributeNode {
  # Mimics behavior of XML::LibXML method getAttributeNode, but if the unqualified attribute cannot be found,
  # we qualify it with "moby:" and try again.
  # We do this so often this module, it's worth having a separate subroutine to do this.
  my ($xref, $attr) = @_;
  my ($package, $filename, $line) = caller;
  if ( !(ref($xref) =~ "^XML\:\:LibXML") ) {
    warn "_moby_getAttributeNode: Looking for attribute '$attr'"
      . "Can't parse non-XML argument '$xref',\n"
	. " called from line $line";
    return '';
  }
  if (!defined $attr) {
    warn "_moby_getAttributeNode: Non-empty attribute is required"
      . "\n called from line $line";
    return '';
  }
  # check for just the attribute by name
  return $xref->getAttributeNode($attr)
    if $xref->getAttributeNode($attr);
  # check for a namespaced attribute by name
  return $xref->getAttributeNodeNS($MOBY_NS, $attr)
  	if $xref->getAttributeNodeNS($MOBY_NS, $attr);
  # check for a namespaced attribute with a prefix ... this is probably redundant!
  return $xref->getAttributeNode( $xref->lookupNamespacePrefix($MOBY_NS) . ":$attr") 
  	if $xref->lookupNamespacePrefix($MOBY_NS);
  # cant find it ...
  return '';
}

sub _moby_getAttribute {
  # Mimics behavior of XML::LibXML method getAttribute, but if the unqualified attribute cannot be found,
  # we qualify it with "moby:" and try again.
  # We do this so often this module, it's worth having a separate subroutine to do this.
  my ($xref, $attr) = @_;
  my ($package, $filename, $line) = caller;
  if ( !(ref($xref) =~ "^XML\:\:LibXML")) {
    warn "_moby_getAttribute: Looking for attribute '$attr', "
    ."can't parse non-XML argument '$xref'\n"
      . "_moby_getAttribute called from line $line";
    return '';
  }
  if (!defined $attr) {
    warn "_moby_getAttribute: Non-empty attribute is required"
    . "\n called from line $line";
    return '';
  }
  
  # check for just the attribute by name
  return $xref->getAttribute($attr)
    if $xref->getAttribute($attr);
  # check for a namespaced attribute by name
  return $xref->getAttributeNS($MOBY_NS, $attr)
  	if $xref->getAttributeNS($MOBY_NS, $attr);
  # check for a namespaced attribute with a prefix ... this is probably redundant!
  return $xref->getAttribute( $xref->lookupNamespacePrefix($MOBY_NS) . ":$attr") 
  	if $xref->lookupNamespacePrefix($MOBY_NS);
  # cant find it ...
  return '';
}

sub _makeXrefType {
  my ( $xref ) = @_;
  my $ns = _moby_getAttributeNode($xref, 'namespace' );
  return undef unless $ns;
  my $id = _moby_getAttributeNode($xref, 'id' );
  return undef unless $id;
  my $xr = _moby_getAttributeNode($xref, 'xref_type' );
  return undef unless $xr;
  my $ec = _moby_getAttributeNode($xref, 'evidence_code' );
  return undef unless $ec;
  my $au = _moby_getAttributeNode($xref, 'authURI' );
  return undef unless $au;
  my $sn = _moby_getAttributeNode($xref, 'serviceName' );
  return undef unless $sn;
  my $XREF = MOBY::CrossReference->new(
				       type          => "xref",
				       namespace     => $ns->getValue,
				       id            => $id->getValue,
				       authURI       => $au->getValue,
				       serviceName   => $sn->getValue,
				       evidence_code => $ec->getValue,
				       xref_type     => $xr->getValue
				      );
  return $XREF;
}


sub _makeObjectType {
  my ( $xref ) = @_;
  my $ns = _moby_getAttributeNode($xref, 'namespace' );
  return undef unless $ns;
  my $id = _moby_getAttributeNode($xref, 'id');
  return undef unless $id;
  my $XREF = MOBY::CrossReference->new(
				       type      => "object",
				       namespace => $ns->getValue,
				       id        => $id->getValue,
				      );
}


=head2 _rearrange (stolen from BioPerl ;-) )

B<usage:>   
         $object->_rearrange( array_ref, list_of_arguments)

B<Purpose :> Rearranges named parameters to requested order.

B<Example:> 
   $self->_rearrange([qw(SEQUENCE ID DESC)],@param);
Where C<@param = (-sequence => $s,  -desc     => $d,  -id       => $i);>

B<returns:> C<@params> - an array of parameters in the requested order.

The above example would return ($s, $i, $d).
Unspecified parameters will return undef. For example, if
       C<@param = (-sequence => $s);>
the above _rearrange call would return ($s, undef, undef)

B<Argument:> C<$order> : a reference to an array which describes the desired order of the named parameters.

C<@param :> an array of parameters, either as a list (in which case the function
simply returns the list), or as an associative array with hyphenated
tags (in which case the function sorts the values according to
@{$order} and returns that new array.)  The tags can be upper, lower,
or mixed case but they must start with a hyphen (at least the first
one should be hyphenated.)

B< Source:> This function was taken from CGI.pm, written by
Dr. Lincoln Stein, and adapted for use in Bio::Seq by Richard Resnick
and then adapted for use in Bio::Root::Object.pm by Steve Chervitz,
then migrated into Bio::Root::RootI.pm by Ewan Birney.

B<Comments:>
Uppercase tags are the norm, (SAC) This method may not be appropriate
for method calls that are within in an inner loop if efficiency is a
concern.

Parameters can be specified using any of these formats:
  @param = (-name=>'me', -color=>'blue');
  @param = (-NAME=>'me', -COLOR=>'blue');
  @param = (-Name=>'me', -Color=>'blue');
  @param = ('me', 'blue');

A leading hyphenated argument is used by this function to indicate
that named parameters are being used.  Therefore, the ('me', 'blue')
list will be returned as-is.

Note that Perl will confuse unquoted, hyphenated tags as function
calls if there is a function of the same name in the current
namespace:  C<-name => 'foo'> is interpreted as C<-&name => 'foo'>

For ultimate safety, put single quotes around the tag: C<('-name'=>'me', '-color' =>'blue');>

This can be a bit cumbersome and I find not as readable as using all
uppercase, which is also fairly safe:C<(-NAME=>'me', -COLOR =>'blue');>

Personal note (SAC): I have found all uppercase tags to be more
managable: it involves less single-quoting, the key names stand out
better, and there are no method naming conflicts.  The drawbacks are
that it's not as easy to type as lowercase, and lots of uppercase can
be hard to read. Regardless of the style, it greatly helps to line the parameters up
vertically for long/complex lists.

=cut

sub _rearrange {
	#    my $dummy = shift;
	my $order = shift;
	return @_ unless ( substr( $_[0] || '', 0, 1 ) eq '-' );
	push @_, undef unless $#_ % 2;
	my %param;
	while ( @_ ) {
		( my $key = shift ) =~ tr/a-z\055/A-Z/d;    #deletes all dashes!
		$param{$key} = shift;
	}
	map { $_ = uc( $_ ) } @$order;  # for bug #1343, but is there perf hit here?
	return @param{@$order};
}

sub _getQueryID {
  my ( $query ) = @_;
  $query = _string_to_XML($query);
  return '' unless ( $query->localname =~ /^mobyData$/ and ($query->namespaceURI() ? $query->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)); #Eddie - unsure
  return _moby_getAttribute($query, 'queryID' );
}


sub _string_to_DOM {
# Convert string to DOM.
# If DOM passed in, just return it (i.e., this should be idempotent)
# By Frank Gibbons, Aug. 2005
# Utility subroutine, not for external use (no export), widely used in this package.
  my $XML = shift;
  my $moby;
  return $XML if ( ref($XML) =~ /^XML\:\:LibXML/ );

  my $parser = XML::LibXML->new();
  my $doc;
  eval { $doc = $parser->parse_string( $XML ) };
  die("CommonSubs couldn't parse XML '$XML' because\n\t$@") if $@;
  return $doc->getDocumentElement();
}



=head1 DEPRECATED FUNCTIONS

=head2 processResponse

DEPRECATED

=cut

sub processResponse {
print STDERR "the processResponse subroutine in MOBY::CommonSubs is deprecated.  Please use serviceResponseParser for API compliance\n";
	my ( $result ) = @_;
	return ( [], [] ) unless $result;
	my $moby;
	unless ( ref( $result ) =~ /XML\:\:LibXML/ ) {
		my $parser = XML::LibXML->new();
		my $doc    = $parser->parse_string( $result );
		$moby = $doc->getDocumentElement();
	} else {
		$moby = $result->getDocumentElement();
	}
	my @objects;
	my @collections;
	my @Xrefs;
	my $success = 0;
	foreach my $which ('mobyData', 'moby:mobyData') {
		my $responses = $moby->getElementsByTagName( $which );
		next unless $responses;
		foreach my $n ( 1 .. ( $responses->size() ) ) {
			my $resp = $responses->get_node( $n );
			foreach my $response_component ( $resp->childNodes ) {
				next unless $response_component->nodeType == ELEMENT_NODE;
				if ( $response_component->localname =~ /^Simple$/ and ($response_component->namespaceURI() ? $response_component->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1))
				  {
					foreach my $Object ( $response_component->childNodes ) {
						next unless $Object->nodeType == ELEMENT_NODE;
						$success = 1;
						push @objects, $Object;
					}
				} elsif ( $response_component->localname =~ /^(.*:|)Collection$/ and ($response_component->namespaceURI() ? $response_component->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1))
				{
					my @objects;
					foreach my $simple ( $response_component->childNodes ) {
						next unless $simple->nodeType == ELEMENT_NODE;
						next unless ( $simple->localname =~ /^Simple$/ and ($simple->namespaceURI() ? $simple->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1));
						foreach my $Object ( $simple->childNodes ) {
							next unless $Object->nodeType == ELEMENT_NODE;
							$success = 1;
							push @objects, $Object;
						}
					}
					push @collections, \@objects
					  ;  #I'm not using collections yet, so we just use Simples.
				}
			}
		}
	}
	return ( \@collections, \@objects );
}


=head2 genericServiceInputParser

DEPRECATED

=cut

sub genericServiceInputParser {
print STDERR "the genericServiceInputParser function of MOBY::CommonSubs is deprecated.  Please see documentation\n";
  my ( $message ) = @_;    # get the incoming MOBY query XML
  my @inputs;              # set empty response
  my @queries = getInputs( $message );   # returns XML::LibXML nodes <mobyData>...</mobyData>
  foreach my $query ( @queries ) {
    my $queryID = getInputID( $query ); # get the queryID attribute of the mobyData
    my @input_articles =
      getArticles( $query )
	; # get the Simple/Collection/Secondary articles making up this query <Simple>...</Simple> or <Collection>...</Collection> or <Parameter>...</Parameter>
    foreach my $input ( @input_articles ) {    # input is a listref
      my ( $articleName, $article ) = @{$input};   # get the named article
      if ( isCollectionArticle( $article ) ) {
	my @simples = getCollectedSimples( $article );
	push @inputs, [ COLLECTION, $queryID, \@simples ];
      } elsif ( isSimpleArticle( $article ) ) {
	push @inputs, [ SIMPLE, $queryID, $article ];
      } elsif ( isSecondaryArticle( $article ) )
	{    # should never happen in a generic service parser!
	  push @inputs, [ SECONDARY, $queryID, $article ];
	}
    }
  }
  return @inputs;
}

=head2 complexServiceInputParser

DEPRECATED

=cut

sub complexServiceInputParser {
print STDERR "the complexServiceInputParser function of MOBY::CommonSubs is deprecated.  Please see documentation\n";
	my ( $message ) = @_;    # get the incoming MOBY query XML
	my @inputs;              # set empty response
	my @queries = getInputs( $message );   # returns XML::LibXML nodes <mobyData>...</mobyData>
	my %input_parameters;      # $input_parameters{$queryID} = [
	foreach my $query ( @queries ) {
	  my $queryID =  getInputID( $query );    # get the queryID attribute of the mobyData
		my @input_articles =
		  getArticles( $query )
		  ; # get the Simple/Collection/Secondary articles making up this query <Simple>...</Simple> or <Collection>...</Collection> or <Parameter>...</Parameter>
		foreach my $input ( @input_articles ) {    # input is a listref
			my ( $articleName, $article ) = @{$input};   # get the named article
			if ( isCollectionArticle( $article ) ) {
				my @simples = getCollectedSimples( $article );
				push @{ $input_parameters{$queryID} },
				  [ COLLECTION, \@simples ];
			} elsif ( isSimpleArticle( $article ) ) {
				push @{ $input_parameters{$queryID} }, [ SIMPLE, $article ];
			} elsif ( isSecondaryArticle( $article ) ) {
				push @{ $input_parameters{$queryID} }, [ SECONDARY, $article ];
			}
		}
	}
	return \%input_parameters;
}

=head2 getArticles

DEPRECATED

=cut

sub getArticles {
print STDERR "the getArticles function of MOBY::CommonSubs is deprecated.  Please see documentation\n";
  my ( $moby ) = @_;
  $moby = _string_to_DOM($moby);
  return undef
    unless ( ($moby->nodeType == ELEMENT_NODE)
	     && ( $moby->localname =~ /^(queryInput|queryResponse|mobyData)$/ and ($moby->namespaceURI() ? $moby->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) );
  my @articles;
  foreach my $child ( $moby->childNodes )
    { # there may be more than one Simple/Collection per input; iterate over them
      next unless ( ($child->nodeType == ELEMENT_NODE)    # ignore whitespace
		    && ( $child->localname =~ /^(Simple|Collection|Parameter)$/  and ($child->namespaceURI() ? $child->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) );
      my $articleName = _moby_getAttribute($child, 'articleName' );
      # push the named child DOM elements (which are <Simple> or <Collection>, <Parameter>)
      push @articles, [ $articleName, $child ];
    }
  return @articles;    # return them.
}

=head2 getSimpleArticleIDs

DEPRECATED

=cut


sub getSimpleArticleIDs {
print STDERR "the getSimpleArticleIDs function of MOBY::CommonSubs is deprecated.  Please see documentation\n";
  my ( $desired_namespace, $input_nodes ) = @_;
  if ( $desired_namespace && !$input_nodes )
    {    # if called with ONE argument, then these are the input nodes!
      $input_nodes       = $desired_namespace;
      $desired_namespace = undef;
    }
  $input_nodes = [$input_nodes]
    unless ref( $input_nodes ) eq 'ARRAY';    # be flexible!
  return undef unless scalar @{$input_nodes};
  my @input_nodes = @{$input_nodes};
  my $OS          = MOBY::Client::OntologyServer->new;
  my ( $s, $m, $namespace_lsid );
  if ( $desired_namespace ) {
    ( $s, $m, $namespace_lsid ) =
      $OS->namespaceExists( term => $desired_namespace ); # returns (success, message, lsid)
    unless ( $s ) {    # bail if not successful
      # Printing to STDERR is not very helpful - we should probably return something that can be dealt iwth programatically....
      die("MOBY::CommonSubs: the namespace '$desired_namespace' "
	   . "does not exist in the MOBY ontology, "
	   . "and does not have a valid LSID");
#      return undef;
    }
    $desired_namespace = $namespace_lsid; # Replace namespace with fully-qualified LSID
  }
  my @ids;
  foreach my $in ( @input_nodes ) {
    next unless $in;
    #$in = "<Simple><Object namespace='' id=''/></Simple>"
    next unless $in->localname =~ /^Simple$/ and ($in->namespaceURI() ? $in->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1);    # only allow simples
    my @simples = $in->childNodes;
    foreach ( @simples ) {    # $_ = <Object namespace='' id=''/>
      next unless $_->nodeType == ELEMENT_NODE;
      if ( $desired_namespace ) {
	my $ns = _moby_getAttributeNode($_, 'namespace' ); # get the namespace DOM node
	unless ( $ns ) {    # if we don't get it at all, then move on to the next input
	    push @ids, undef;    # but push an undef onto teh stack in order
	    next;
	  }
	$ns = $ns->getValue;    # if we have a namespace, then get its value
	( $s, $m, $ns ) = $OS->namespaceExists( term => $ns );
	# A bad namespace will return 'undef' which makes for a bad comparison (Perl warning).
	# Better to check directly for success ($s), THEN check that namespace is the one we wanted.
	unless ( $s && $ns eq $desired_namespace )
	  { # we are registering as working in a particular namespace, so check this
	    push @ids, undef;    # and push undef onto the stack if it isn't
	    next;
	  }
      }

      # Now do the same thing for ID's
      my $id = _moby_getAttributeNode($_, 'id' );
      unless ( $id ) {
	push @ids, undef;
	next;
      }
      $id = $id->getValue;
      unless ( defined $id ) {    # it has to have a hope in hell of retrieving something...
	  push @ids, undef;    # otherwise push undef onto the stack if it isn't
	  next;
	}
      push @ids, $id;
    }
  }
  return @ids;
}

=head2 getSimpleArticleNamespaceURI

DEPRECATED

=cut


sub getSimpleArticleNamespaceURI {
print STDERR "the getSimpleArticleNamespaceURI function of MOBY::CommonSubs is deprecated.  Please see documentation\n";

# pass me a <SIMPLE> input node and I will give you the lsid of the namespace of that input object
  my ( $input_node ) = @_;
  return undef unless $input_node;
  my $OS = MOBY::Client::OntologyServer->new;

  #$input_node = "<Simple><Object namespace='' id=''/></Simple>"
  my @simples = $input_node->childNodes;
  foreach ( @simples )
    { # $_ = <Object namespace='' id=''/>   # should be just one, so I will return at will from this routine
      next unless $_->nodeType == ELEMENT_NODE;
      my $ns = _moby_getAttributeNode($_, 'namespace' );     # get the namespace DOM node
	return undef unless ( $ns ); # if we don't get it at all, then move on to the next input
      my ( $s, $m, $lsid ) =
	$OS->namespaceExists( term => $ns->getValue );   # if we have a namespace, then get its value
      return undef unless $s;
      return $lsid;
    }
}


=head2 getInputs

DEPRECATED

=cut

sub getInputs {
  print STDERR "getInputs is now deprecated.  Please update your code to use the serviceInputParser\n";
  my ( $XML ) = @_;
  my $moby =  _string_to_DOM($XML);
  my @queries;
  foreach my $querytag (qw( queryInput moby:queryInput mobyData moby:mobyData ))
    {
      my $x = $moby->getElementsByTagName( $querytag );    # get the mobyData block
      for ( 1 .. $x->size() ) {    # there may be more than one mobyData per message
	push @queries, $x->get_node( $_ );
      }
    }
  return @queries;    # return them in the order that they were discovered.
}

=head2 getInputID

DEPRECATED

=cut

sub getInputID {
    print STDERR "getInputID method is now deprecated.  Please use serviceInputParser or serviceResponseParser\n";
  my ( $XML ) = @_;
  my $moby = _string_to_DOM($XML);
  return '' unless ( $moby->localname =~ /^queryInput|mobyData$/ and ($moby->namespaceURI() ? $moby->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1));
  my $qid =  _moby_getAttribute($moby, 'queryID' );
  $qid ||= _moby_getAttribute($moby, 'moby:queryID' );
  return defined( $qid ) ? $qid : '';
}

=head2 getArticlesAsObjects

DEPRECATED

=cut

sub getArticlesAsObjects {
    print STDERR "getArticlesAsObjects is now deprecated.  Please use the serviceInputParser";
  my ( $moby ) = @_;
  $moby = _string_to_DOM($moby);
  return undef unless $moby->nodeType == ELEMENT_NODE;
  return undef
    unless ($moby->localname =~ /^(queryInput|queryResponse|mobyData)$/ and ($moby->namespaceURI() ? $moby->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1));
  my @articles;
  foreach my $child ( $moby->childNodes )
    { # there may be more than one Simple/Collection per input; iterate over them
      next unless $child->nodeType == ELEMENT_NODE;    # ignore whitespace
      next
	unless ( $child->localname =~ /^(Simple|Collection|Parameter)$/ and ($child->namespaceURI() ? $child->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1));
      my $object;
      if ( $child->localname =~ /^Simple$/ and ($child->namespaceURI() ? $child->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) {
	$object = MOBY::Client::SimpleArticle->new( XML_DOM => $child );
      } elsif ( $child->localname =~ /^Collection$/ and ($child->namespaceURI() ? $child->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) {
	$object = MOBY::Client::CollectionArticle->new( XML_DOM => $child );
      } elsif ( $child->localname =~ /^Parameter$/ and ($child->namespaceURI() ? $child->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1)) {
	$object = MOBY::Client::SecondaryArticle->new( XML_DOM => $child );
      }
      next unless $object;
      push @articles, $object;  # take the child elements, which are <Simple/> or <Collection/>
    }
  return @articles;    # return them.
}

=head2 getCollectedSimples

DEPRECATED

=cut

sub getCollectedSimples {
print STDERR "the getCollectedSimples function of MOBY::CommonSubs is deprecated.  Please see documentation\n";
  my ( $moby ) = @_;
  $moby = _string_to_DOM($moby);
  return undef unless $moby->nodeType == ELEMENT_NODE;
  return undef unless ( $moby->localname =~ /^Collection$/ and ($moby->namespaceURI() ? $moby->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1));
  my @articles;
  foreach my $child ( $moby->childNodes )
    { # there may be more than one Simple/Collection per input; iterate over them
      next unless $child->nodeType == ELEMENT_NODE;    # ignore whitespace
      next unless ( $child->localname =~ /^Simple$/ and ($child->namespaceURI() ? $child->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1));
      push @articles, $child; # take the child elements, which are <Simple/> or <Collection/>
    }
  return @articles;    # return them.
}

=head2 getInputArticles

DEPRECATED

=cut

sub getInputArticles {
print STDERR "the getInputArticles function of MOBY::CommonSubs is deprecated.  Please see documentation\n";

  my ( $moby ) = @_;
  $moby = _string_to_DOM($moby);
  my $x;
  foreach ( 'queryInput', 'moby:queryInput', 'mobyData', 'moby:mobyData' ) {
    $x = $moby->getElementsByTagName( $_ );    # get the mobyData block
    last if $x->get_node( 1 );
  }
  return undef unless $x->get_node( 1 );   # in case there was no match at all
  my @queries;
  for ( 1 .. $x->size() ) {  # there may be more than one mobyData per message
    my @this_query;
    foreach my $child ( $x->get_node( $_ )->childNodes )
      { # there may be more than one Simple/Collection per input; iterate over them
	next unless $child->nodeType == ELEMENT_NODE;    # ignore whitespace
	push @this_query, $child;  # take the child elements, which are <Simple/> or <Collection/>
      }
    push @queries, \@this_query;
  }
  return @queries;    # return them in the order that they were discovered.
}

=head2 extractRawContent

DEPRECATED

=cut

sub extractRawContent {
print STDERR "the extractRawContent function of MOBY::CommonSubs is deprecated.  Please see documentation\n";
  my ( $article ) = @_;
  return "" unless ( $article || (ref( $article ) =~ /XML\:\:LibXML/) );
  my $response;
  foreach ( $article->childNodes ) {
    $response .= $_->toString;
  }
#  print STDERR "RESPONSE = $response\n";
  return $response;
}


*getResponseArticles = \&extractResponseArticles;
*getResponseArticles = \&extractResponseArticles;

=head2 getResponseArticles (a.k.a. extractResponseArticles)

DEPRECATED

=cut

sub extractResponseArticles {
print STDERR "the extractResponseArticles function of MOBY::CommonSubs is deprecated.  Please see documentation\n";
	my ( $result ) = @_;
	return ( [], [] ) unless $result;
	my $moby;
	unless ( ref( $result ) =~ /XML\:\:LibXML/ ) {
		my $parser = XML::LibXML->new();
		my $doc    = $parser->parse_string( $result );
		$moby = $doc->getDocumentElement();
	} else {
		$moby = $result->getDocumentElement();
	}
	my @objects;
	my @collections;
	my @Xrefs;
	my $success = 0;
	foreach my $which ( 'moby:queryResponse', 'queryResponse',
			    'mobyData', 'moby:mobyData' )
	{
		my $responses = $moby->getElementsByTagName( $which );
		next unless $responses;
		foreach my $n ( 1 .. ( $responses->size() ) ) {
			my $resp = $responses->get_node( $n );
			foreach my $response_component ( $resp->childNodes ) {
				next unless $response_component->nodeType == ELEMENT_NODE;
				if ( $response_component->localname =~ /^Simple$/ and ($response_component->namespaceURI() ? $response_component->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1))
				  {
					foreach my $Object ( $response_component->childNodes ) {
						next unless $Object->nodeType == ELEMENT_NODE;
						$success = 1;
						push @objects, $Object;
					}
				} elsif ( $response_component->localname =~ /^Collection$/ and ($response_component->namespaceURI() ? $response_component->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1))
				{
					my @objects;
					foreach my $simple ( $response_component->childNodes ) {
						next unless $simple->nodeType == ELEMENT_NODE;
						next unless ( $simple->localname =~ /^Simple$/ and ($simple->namespaceURI() ? $simple->namespaceURI() =~ m/\Q$MOBY_NS\E/i : 1));
						foreach my $Object ( $simple->childNodes ) {
							next unless $Object->nodeType == ELEMENT_NODE;
							$success = 1;
							push @objects, $Object;
						}
					}
					push @collections, \@objects
					  ;  #I'm not using collections yet, so we just use Simples.
				}
			}
		}
	}
	return ( \@collections, \@objects );
}


=head1 AUTHORS

Mark Wilkinson (markw at illuminae dot com), Pieter Neerincx, Frank Gibbons

BioMOBY Project:  http://www.biomoby.org


=head1 SEE ALSO


=cut


1;
 
