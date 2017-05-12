package MOBYXSLT;

my $TMP_DIR   = '/tmp/';#Where your temporary files will be written
my $XSLTPROC  = '/usr/bin/xsltproc';#Where your xsltproc binary is located
my $XSL_SHEET = 'xsl/parseMobyMessage.xsl';#Where your xsltproc style-sheet is located

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

#$Id: MOBYXSLT.pm,v 1.3 2008/09/02 13:14:18 kawas Exp $

=pod

=head1 NAME

MOBYXSLT - CommonSubs using XSLT

=head1 WHY

Because huge XML message parsing with XML::Dom take too much time.
xsltproc is a binary very  very efficient to parse huge files.


=head1 TO BE EDITED

    Globals variables are defined in this package:

	my $TMP_DIR   = '/tmp/'; #Where your temporary files will be written
	my $XSLTPROC  = '/usr/bin/xsltproc'; #Where your xsltproc binary is located
	my $XSL_SHEET = './parseMobyMessage.xsl'; #Where your xsltproc style-sheet is located


=head1 SYNOPSIS

sub MonWebservice
{

    my ($caller, $message) = (@_);

    my $moby_response;

    my $service_name = 'MonWebservice';

    #Message Parsing
    my ($service_notes,$ra_queries) = MOBYXSLT::getInputs($message); #Message Parsing

    foreach my $query (@{$ra_queries})
    {
        my $query_id = MOBYXSLT::getInputID($query);#Retrieve Query ID
	    my @a_input_articles = MOBYXSLT::getArticles($query);#Retrieve articles

        my ($fasta_sequences, $fasta_namespace, $fasta_id)  = ('','','');

        foreach my $input_article (@a_input_articles)
        {
            my ($article_name, $article) = @{$input_article};

            if (MOBYXSLT::isSimpleArticle($article))
            {
        		my $object_type = MOBYXSLT::getObjectType($article);

        		if (IsTheCorrectType($object_type))
                {
                        $fasta_sequences = MOBYXSLT::getObjectContent($article);
			            $fasta_namespace = MOBYXSLT::getObjectNamespace($article);
			            $fasta_id = MOBYXSLT::getObjectId($article);
                }
            }
            elsif (MOBYXSLT::isCollectionArticle($article))
            {
            }

            elsif (MOBYXSLT::isSecondaryArticle($article))
            {
	    	    my ($param_name,$param_value) = MOBYXSLT::getParameter($article);#Retrieve parameters
            }
        }

	######
	#What you want to do with your data
	######


        my $cmd ="...";

        system("$cmd");




	#########
	#Send result
	#########

        $moby_response .= MOBYXSLT::simpleResponse("<$output_object_type1>$out_data</$output_object_type1>", $output_article_name1, $query_id);
     }


    return SOAP::Data->type(
         'base64' => (MOBYXSLT::responseHeader(-authority => $auth_uri, -note => "Documentation about $service_name at $url_doc"))
           . $moby_response
           . MOBYXSLT::responseFooter());

}

=head1 GLOBALS

	my $TMP_DIR   = '/tmp/'; #Where your temporary files will be written
	my $XSLTPROC  = '/usr/bin/xsltproc'; #Where your xsltproc binary is located
	my $XSL_SHEET = './parseMobyMessage.xsl'; #Where your xsltproc style-sheet is located


=head1 DESCRIPTION

	Note: many functions have same names as those from MOBY::CommonSubs

=cut


use strict;
use Carp;

=head2 function getInputs

 Title        : getInputs
 Usage        : my ($servicenotes, $ra_queries) = getInputs($moby_message)
 Prerequisite : 
 Function     : Parse Moby message and build Perl structures to access
 		for each query to their articles and objects.
 Returns      : $servicenotes: Notes returned by service provider
 		$ra_queries: ARRAYREF of all queries analysed in MOBY message
 Args         : $moby_message: MOBY XML message
 Globals      : $XSLTPROC: /path/to/xsltproc binary
 		$XSL_SHEET: XSL Sheet for MobyMessage Parsing
		$TMP_DIR: /where

=cut

sub getInputs
{
    my ($moby_message) = (@_);

    my $tmp_file       = 'MOBYXSLT' . $$ . $^T;
    my $header_with_ns = "<moby:MOBY xmlns:moby='http://www.biomoby.org/moby' ";

    $moby_message =~ s/xmlns:moby/xmlns:moby2/;

    $moby_message =~ s/<moby:MOBY/$header_with_ns/;

    open(TMP, ">$TMP_DIR$tmp_file") || confess("$! :$TMP_DIR$tmp_file");
    print TMP $moby_message;
    close TMP;

    my $parsed_message = `$XSLTPROC $XSL_SHEET $TMP_DIR$tmp_file`;
    
    
    
    my $servicenotes = '';
	my $ra_exceptions = ();
    my @a_queries    = ();

    my $servicenotes_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES#';
	$parsed_message =~ s/\n/__nl__/g;
    if ($parsed_message =~ /$servicenotes_tag(.*)$servicenotes_tag/)
    {
		my $notes = $1;
		
		($servicenotes,$ra_exceptions) = _AnalyseServiceNotes($notes);
		#($servicenotes) = ($parsed_message =~ /$servicenotes_tag(.+)$servicenotes_tag/);
    }
	$parsed_message =~ s/__nl__/\n/g;
    
    my $mobydata_tag = '#XSL_LIPM_MOBYPARSER_DATA_START#';
    my ($header, @a_mobydata_blocs) = split($mobydata_tag, $parsed_message);

    my $query_count = 0;

    foreach my $mobydata_bloc (@a_mobydata_blocs)
    {

        my $queryid_tag = '#XSL_LIPM_MOBYPARSER_QUERYID#';
        my ($queryid) = ($mobydata_bloc =~ /$queryid_tag(.+)$queryid_tag/);

        my $article_start_tag = '#XSL_LIPM_MOBYPARSER_ARTICLE_START#';
        my ($header_article, @a_article_blocs) = split($article_start_tag, $mobydata_bloc);

        my @a_input_articles = ();

        foreach my $article_bloc (@a_article_blocs)
        {
            my $articlename_tag = '#XSL_LIPM_MOBYPARSER_ARTICLENAME#';
            my ($articlename) = ($article_bloc =~ /$articlename_tag(.+)$articlename_tag/);

            my $articletype_tag = '#XSL_LIPM_MOBYPARSER_ARTICLETYPE#';
            my ($articletype) = ($article_bloc =~ /$articletype_tag(.+)$articletype_tag/);
            $articletype =~ s/^moby://;

            my $simple_start_tag = '#XSL_LIPM_MOBYPARSER_SIMPLE_START#';

            my $article_objects = '';
            if (_IsCollection($articletype))
            {
                my ($header_collec, @a_simple_blocs) = split($simple_start_tag, $article_bloc);
                my @a_simple_objects = ();
                foreach my $simple_bloc (@a_simple_blocs)
                {
                    my $rh_simple = _AnalyseSimple($simple_bloc);
                    push(@a_simple_objects, $rh_simple);
                }
                $article_objects = \@a_simple_objects;
            }
            elsif (_IsSimple($articletype))
            {
                my ($header_collec, $simple_bloc) = split($simple_start_tag, $article_bloc);
                $article_objects = _AnalyseSimple($simple_bloc);
            }
            elsif (_IsSecondary($articletype))
            {

                my $secondary_start = '#XSL_LIPM_MOBYPARSER_SECONDARY_START#';
                my $secondary_end   = '#XSL_LIPM_MOBYPARSER_SECONDARY_END#';
                my $secondary_sep   = '#XSL_LIPM_MOBYPARSER_SECONDARY_SEP#';
                my (@a_param) = ($article_bloc =~ /$secondary_start(.+)$secondary_sep(.+)$secondary_end/);
                $article_objects = \@a_param;
            }

            my %h_input_article = (
                                   'article_type'    => $articletype,
                                   'article_name'    => $articlename,
                                   'article_objects' => $article_objects
                                   );

            push(@a_input_articles, \%h_input_article);

        }

        my %h_query = (
                       'query_id'       => $queryid,
                       'query_articles' => \@a_input_articles
                       );

        push(@a_queries, \%h_query);

    }

    unlink("$TMP_DIR$tmp_file");
    return ($servicenotes, \@a_queries, $ra_exceptions);
}

=head2 function getInputID

 Title        : getInputID
 Usage        : my $query_id =getInputID($rh_query);
 Prerequisite : 
 Function     : Return query_id of a query from getInputs
 Returns      : $query_id
 Args         : $rh_query: query HASHREF structure from getInputs
 Globals      : none

=cut

sub getInputID
{
    my $rh_query = shift();
    return $rh_query->{'query_id'};
}

=head2 function getArticles

 Title        : getArticles
 Usage        : my @a_input_articles =getArticles($rh_query);
 Prerequisite : 
 Function     : For a query from getInputs, retrieve list of articles 
 		represented by a ARRAYREF corresponding to REF(articleName, articlePerlStructure)
 Returns      : @a_input_articles: ARRAY of articles ARRAYREF
 Args         : $rh_query: query HASHREF structure from getInputs
 Globals      : none

=cut

sub getArticles
{
    my $rh_query         = shift();
    my @a_input_articles = ();

    foreach my $rh_input_article (@{$rh_query->{'query_articles'}})
    {
        my @a_input_article = ($rh_input_article->{'article_name'}, $rh_input_article);
        push(@a_input_articles, \@a_input_article);
    }
    return (@a_input_articles);
}

=head2 function getCollectedSimples

 Title        : getCollectedSimples
 Usage        : my @a_simple_articles =getCollectedSimples($rh_collection_article);
 Prerequisite : 
 Function     : For a collection query from getArticles, retrieve list of 
 		simple articles
 Returns      : @a_simple_articles: ARRAY of articles HASHREF
 Args         : $rh_collection_article: collection article HASHREF structure from getArticles
 Globals      : none

=cut

sub getCollectedSimples
{
    my $rh_collection_article = shift();
    return @{$rh_collection_article->{'article_objects'}};
}

=head2 function getCrossReferences

 Title        : getCrossReferences
 Usage        : my @a_crossreferences =getCrossReferences($rh_simple_article);
 Prerequisite : 
 Function     : Takes a simple article structure (from getArticles or getCollectedSimples)
 		and retrieve the list of crossreferences HASHREF
 Returns      : @a_crossreferences: ARRAY of crossreferences HASHREF
 Args         : $rh_simple_article: simple article HASHREF structure from getArticles or getCollectedSimples
 Globals      : none

=cut

sub getCrossReferences
{
    my $rh_simple_article = shift();

	if (defined $rh_simple_article->{'article_objects'})
    {
        if ($rh_simple_article->{'article_objects'}->{'object_crossreference'} ne '')
        {
            return (@{$rh_simple_article->{'article_objects'}->{'object_crossreference'}});
        }
        else
        {
            return ();
        }
    }
    else
    {
        if ($rh_simple_article->{'object_crossreference'} ne '')
        {
            return @{$rh_simple_article->{'object_crossreference'}};
        }
        else
        {
            return ();
        }
    }
	
}

=head2 function getProvisionInformation

 Title        : getProvisionInformation
 Usage        : my @a_pib =getProvisionInformation($rh_simple_article);
 Prerequisite : 
 Function     : Takes a simple article structure (from getArticles or getCollectedSimples)
 		and retrieve the list of Provision Information HASHREF
 Returns      : @a_pib: ARRAY of provisionInformation HASHREF
 Args         : $rh_simple_article: simple article HASHREF structure from getArticles or getCollectedSimples
 Globals      : none

=cut

sub getProvisionInformation
{
    my $rh_simple_article = shift();

	if (defined $rh_simple_article->{'article_objects'})
    {
        if ($rh_simple_article->{'article_objects'}->{'object_pib'} ne '')
        {
            return (@{$rh_simple_article->{'article_objects'}->{'object_pib'}});
        }
        else
        {
            return ();
        }
    }
    else
    {
        if ($rh_simple_article->{'object_pib'} ne '')
        {
            return @{$rh_simple_article->{'object_pib'}};
        }
        else
        {
            return ();
        }
    }
	
}

=head2 function getObjectHasaElements

 Title        : getObjectHasaElements
 Usage        : my @a_hasa_elements =getObjectHasaElements($rh_simple_article);
 Prerequisite : 
 Function     : Takes a simple article structure (from getArticles or getCollectedSimples)
 		and retrieve the list of "HASA" element HASHREF
 Returns      : @a_hasa_elements: ARRAY of "HASA" element HASHREF
 Args         : $rh_object: simple article HASHREF structure from getArticles or getCollectedSimples
 Globals      : none

=cut

sub getObjectHasaElements
{
    my $rh_simple_article = shift();

    if (defined $rh_simple_article->{'article_objects'})
    {
        if ($rh_simple_article->{'article_objects'}->{'object_hasa'} ne '')
        {
            return (@{$rh_simple_article->{'article_objects'}->{'object_hasa'}});
        }
        else
        {
            return ();
        }
    }
    else
    {
        if ($rh_simple_article->{'object_hasa'} ne '')
        {
            return @{$rh_simple_article->{'object_hasa'}};
        }
        else
        {
            return ();
        }
    }

#    if ($rh_object->{'object_hasa'} ne '')
#    {
#       return (@{$rh_object->{'object_hasa'}});
#    }
#    else
#    {
#        return ();
#    }
}

=head2 function getObjectType

 Title        : getObjectType
 Usage        : my $object_type =getObjectType($rh_object);
 Prerequisite : 
 Function     : Returns object MOBY class/type
 Returns      : $object_type: object MOBY class/type
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectType
{
    my $rh_object = shift();
    if (defined $rh_object->{'article_objects'})
    {
        return ($rh_object->{'article_objects'}->{'object_type'});
    }
    else
    {
        return $rh_object->{'object_type'};
    }
}

=head2 function getObjectName

 Title        : getObjectName
 Usage        : my $object_name =getObjectName($rh_object);
 Prerequisite : 
 Function     : Returns object moby:articleName
 Returns      : $object_name:  moby:articleName
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectName
{
    my $rh_object = shift();
    if (defined $rh_object->{'article_objects'})
    {
        return ($rh_object->{'article_objects'}->{'object_name'});
    }
    else
    {
        return $rh_object->{'object_name'};
    }
}

=head2 function getObjectNamespace

 Title        : getObjectNamespace
 Usage        : my $object_namespace =getObjectNamespace($rh_object);
 Prerequisite : 
 Function     : Returns object moby:namespace
 Returns      : $object_name:  moby:namespace
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectNamespace
{
    my $rh_object = shift();
    if (defined $rh_object->{'article_objects'})
    {
        return ($rh_object->{'article_objects'}->{'object_namespace'});
    }
    else
    {
        return $rh_object->{'object_namespace'};
    }
}

=head2 function getObjectContent

 Title        : getObjectContent
 Usage        : my $object_content =getObjectContent($rh_object);
 Prerequisite : 
 Function     : Returns object content (using HTML::Entities::decode)
 		Warning: this content could contain emptylines if
			your objects contains Crossreferences or Hasa Elements ...
 Returns      : $object_content:  object content (decoded using HTML::Entities::decode)
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectContent
{
    use HTML::Entities ();
    my $rh_object       = shift();
    my $encoded_content = '';
    if (defined $rh_object->{'article_objects'})
    {
        $encoded_content = $rh_object->{'article_objects'}->{'object_content'};
    }
    else
    {
        $encoded_content = $rh_object->{'object_content'};
    }
    my $decoded_object = HTML::Entities::decode($encoded_content);
    return ($decoded_object);
}

=head2 function getObjectXML

 Title        : getObjectXML
 Usage        : my $object_xml =getObjectXML($rh_object);
 Prerequisite : 
 Function     : Returns full object moby:xml string
 Returns      : $object_xml:  object moby:xml string
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectXML
{
    my $rh_object = shift();
    if (defined $rh_object->{'article_objects'})
    {
        return ($rh_object->{'article_objects'}->{'object_xml'});
    }
    else
    {
        return $rh_object->{'object_xml'};
    }

}

=head2 function getObjectId

 Title        : getObjectId
 Usage        : my $object_id =getObjectId($rh_object);
 Prerequisite : 
 Function     : Returns object moby:id
 Returns      : $object_id:  moby:id
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectId
{
    my $rh_object = shift();

    if (defined $rh_object->{'article_objects'})
    {
        return ($rh_object->{'article_objects'}->{'object_id'});
    }
    else
    {
        return $rh_object->{'object_id'};
    }
}

=head2 function getParameter

 Title        : getParameter
 Usage        : my ($parameter_name,$parameter_value) =getParameter($rh_article);
 Prerequisite : 
 Function     : Returns parameter name an value for a Secondary aricle
 Returns      : $parameter_name
 		$parameter_value
 Args         : $rh_article: secondary article HASHREF structure from getArticles
 Globals      : none

=cut

sub getParameter
{
    my $rh_article = shift();
    if (_IsSecondary($rh_article->{'article_type'}))
    {
        return (@{$rh_article->{'article_objects'}});
    }

    return;
}

=head2 function getNodeContentWithArticle

 Title        : getNodeContentWithArticle
 Usage        : my $content = getNodeContentWithArticle($rh_query, $article_type, $article_name)
 Prerequisite : 
 Function     : inside a mobyData bloc (structured in $rh_query),
 		look for an article of a defined type (Simple, Collection or Parameter).
		Foreach matching article, search for an object named $article_name.
		If found, return its content.
 Returns      : $content: content of article requested
 Args         : $rh_query: query HASHREF structure from getInputs
 		$article_type: 'Simple/Collection/Parameter'
		$article_name: attribute moby:articleName 
 Globals      : 

=cut

sub getNodeContentWithArticle
{
    my ($rh_query, $article_type, $article_name) = (@_);

    foreach my $rh_article (@{$rh_query->{'query_articles'}})
    {
        if (   (_IsSecondary($article_type))
            && ($rh_article->{'article_type'} =~ /^$article_type$/i)
            && ($article_name eq $rh_article->{'article_name'}))
        {
            my ($article_name, $article_value) = @{$rh_article->{'article_objects'}};
            return $article_value;
        }
        elsif (_IsSimple($article_type))
        {
            if ($rh_article->{'article_type'} =~ /^$article_type$/i)
            {

                if ($rh_article->{'article_name'} eq $article_name)
                {
                    return $rh_article->{'article_objects'}->{'object_content'};
                }
                elsif ($rh_article->{'article_objects'}->{'object_hasa'} ne '')
                {
                    foreach my $rh_object (@{$rh_article->{'article_objects'}->{'object_hasa'}})
                    {
                        if ($rh_object->{'object_name'} eq $article_name)
                        {
                            return $rh_object->{'object_content'};
                        }
                    }
                }
            }
        }
        elsif (_IsCollection($article_type))
        {
            if ($rh_article->{'article_type'} =~ /^$article_type$/i)
            {
                if ($rh_article->{'article_name'} eq $article_name)
                {
                    my $content = '';
                    foreach my $rh_object (@{$rh_article->{'article_objects'}})
                    {
                        $content .= $rh_object->{'object_content'};
                    }
                    return $content;
                }
                else
                {
                    foreach my $rh_object (@{$rh_article->{'article_objects'}})
                    {
                        if ($rh_object->{'object_name'} eq $article_name)
                        {
                            return $rh_object->{'object_content'};
                        }
                    }
                }

            }
        }
    }

    return;
}

=head2 function isSimpleArticle

 Title        : isSimpleArticle
 Usage        : isSimpleArticle($rh_article)
 Prerequisite : 
 Function     : Test if an article is a moby:Simple
 Returns      : $response: BOOLEAN
 Args         : $rh_article: article HASHREF structure from getArticles
 Globals      : none

=cut

sub isSimpleArticle
{
    my $rh_article = shift();
    my $response   = _IsSimple($rh_article->{article_type});
    return $response;
}

=head2 function isCollectionArticle

 Title        : isCollectionArticle
 Usage        : isCollectionArticle($rh_article)
 Prerequisite : 
 Function     : Test if an article is a moby:Collection
 Returns      : $response: BOOLEAN
 Args         : $rh_article: article HASHREF structure from getArticles
 Globals      : none

=cut

sub isCollectionArticle
{
    my $rh_article = shift();
    my $response   = _IsCollection($rh_article->{article_type});
    return $response;
}

=head2 function isSecondaryArticle

 Title        : isSecondaryArticle
 Usage        : isSecondaryArticle($rh_article)
 Prerequisite : 
 Function     : Test if articleType is moby:Parameter (secondary article)
 Returns      : $response: BOOLEAN
 Args         : $rh_article: article HASHREF structure from getArticles
 Globals      : none

=cut

sub isSecondaryArticle
{
    my $rh_article = shift();
    my $response   = _IsSecondary($rh_article->{article_type});
    return $response;
}

=head2 function _AnalyseSimple

 Title        : _AnalyseSimple
 Usage        : _AnalyseSimple($simple_bloc)
 Prerequisite : 
 Function     : Analyse a "Simple Bloc" from XSL transformation parsing
 		Build a $rh_simple_article structure with fields:
			'object_name'		=> moby:articleName
			'object_type'		=> moby:Class
			'object_namespace'	=> moby:namespace
			'object_id'		=> moby:id
			'object_content'	=> text content of simple article
			'object_xml'		=> full xml content of article
			'object_hasa'		=> ARRAYREF of hasa elements 
						   (each one is structured in a same 
						   structured hash (recursivity)
			'object_crossreference' => ARRAYREF of crossreferences objects 
						   (each one is structured in a hash with fields
						   'type', 'id', 'namespace')

 Returns      : $rh_simple: article HASHREF
 Args         : $simple_bloc: from parsing of a "simple" XSLT transformation
 Globals      : none

=cut

sub _AnalyseSimple
{
    my $simple_bloc = shift();
    my @a_crossref  = ();
    my @a_pib  = ();
    my @a_hasa      = ();

    my ($object_type,$object_name,$object_id,$object_namespace) = ('','','','');
    my $object_type_tag = '#XSL_LIPM_MOBYPARSER_OBJECTTYPE#';
    
    if ($simple_bloc =~ /$object_type_tag(.+)$object_type_tag/)
    {
        $object_type = $1;
        $object_type =~ s/^moby://i;
    }

    my $object_namespace_tag = '#XSL_LIPM_MOBYPARSER_OBJECTNAMESPACE#';
    
    if ($simple_bloc =~ /$object_namespace_tag(.+)$object_namespace_tag/)
    {
        $object_namespace = $1;
    }
    
    my $object_id_tag = '#XSL_LIPM_MOBYPARSER_OBJECTID#';
    
    if ($simple_bloc =~ /$object_id_tag(.+)$object_id_tag/)
    {
        $object_id = $1;
    }
    
    my $object_name_tag = '#XSL_LIPM_MOBYPARSER_OBJECTNAME#';

    if ($simple_bloc =~ /$object_name_tag(.+)$object_name_tag/)
    {
        $object_name = $1
    }
    
    my $crossref_start_tag = '#XSL_LIPM_MOBYPARSER_CROSSREF_START#';
    my $crossref_end_tag   = '#XSL_LIPM_MOBYPARSER_CROSSREF_END#';
    my $crossref_sep_tag   = '#XSL_LIPM_MOBYPARSER_CROSSREF_SEP#';

    while ($simple_bloc =~ m/$crossref_start_tag(.*)$crossref_sep_tag(.*)$crossref_sep_tag(.*)$crossref_end_tag/g)
    {
		my %h_crossref = ('type' => $1, 'id' => $2, 'namespace' => $3);
		$simple_bloc =~ s/$crossref_start_tag$1$crossref_sep_tag$2$crossref_sep_tag$3$crossref_end_tag//;
        push(@a_crossref, \%h_crossref);
    }

    my $ra_crossref = \@a_crossref;
    if ($#a_crossref < 0)
    {
        $ra_crossref = '';
    }

    #19/12/2005
    #Provision Information Block
    
    my $pib_start_tag = '#XSL_LIPM_MOBYPARSER_PIB_START#';
    my $pib_end_tag   = '#XSL_LIPM_MOBYPARSER_PIB_END#';
    my $pib_software_start_tag   = '#XSL_LIPM_MOBYPARSER_SOFTWARE_START#';
    my $pib_software_end_tag   = '#XSL_LIPM_MOBYPARSER_SOFTWARE_END#';
    my $pib_software_sep_tag   = '#XSL_LIPM_MOBYPARSER_SOFTWARE_SEP#';
    my $pib_database_start_tag   = '#XSL_LIPM_MOBYPARSER_DATABASE_START#';
    my $pib_database_end_tag   = '#XSL_LIPM_MOBYPARSER_DATABASE_END#';
    my $pib_database_sep_tag   = '#XSL_LIPM_MOBYPARSER_DATABASE_SEP#';
    my $pib_comment_start_tag   = '#XSL_LIPM_MOBYPARSER_COMMENT_START#';
    my $pib_comment_end_tag   = '#XSL_LIPM_MOBYPARSER_COMMENT_END#';

		
    while ($simple_bloc =~ m/$pib_start_tag(.*)$pib_end_tag/g)
    {
    	my $provision_block = $1;
		$simple_bloc =~ s/$pib_start_tag$provision_block$pib_end_tag//;
	my ($software_name,$software_version,$software_comment) = ('','','');
	if ($provision_block =~ /$pib_software_start_tag(.*)$pib_software_end_tag/)
	{
		($software_name,$software_version,$software_comment) = split (/$pib_software_sep_tag/,$1);
	}
	my ($database_name,$database_version,$database_comment) = ('','','');
	if ($provision_block =~ /$pib_database_start_tag(.*)$pib_database_end_tag/)
	{
		($database_name,$database_version,$database_comment) = split (/$pib_database_sep_tag/,$1);
	}
	my ($service_comment) = ('');
	if ($provision_block =~ /$pib_comment_start_tag(.*)$pib_comment_end_tag/)
	{
		($service_comment) = ($1);
	}
        
	my %h_pib =	(	
				'software_name'		=> $software_name,
				'software_version'	=> $software_version,
				'software_comment'	=> $software_comment,
				'database_name'		=> $database_name,
				'database_version'	=> $database_version,
				'database_comment'	=> $database_comment,
				'service_comment'	=> $service_comment
			);
	
	open (TMP, ">>/tmp/pib.txt");
	print TMP <<END;
'software_name'		=> $software_name,
'software_version'	=> $software_version,
'software_comment'	=> $software_comment,
'database_name'		=> $database_name,
'database_version'	=> $database_version,
'database_comment'	=> $database_comment,
'service_comment'	=> $service_comment
END
	close TMP;
	chmod 0777, "/tmp/pib.txt";

        push(@a_pib, \%h_pib);
    }

    my $ra_pib = \@a_pib;
    if ($#a_pib < 0)
    {
        $ra_pib = '';
    }





    my $object_content_tag = '#XSL_LIPM_MOBYPARSER_OBJECTCONTENT#';
    my ($before, $object_content, $after) = ('','','');
    ($before, $object_content, $after) = split($object_content_tag, $simple_bloc);

	#Sebastien 21/12/2005
	#
	$object_content =~ s/^\s+//g;
    $object_content =~ s/\s+$//g;
    #
	
	my $object_hasa_start_tag = '#XSL_LIPM_MOBYPARSER_OBJECTHASA_START#';

    if ($simple_bloc =~ /$object_hasa_start_tag/)
    {
        my (@a_hasa_blocs) = split($object_hasa_start_tag, $simple_bloc);

		#Sebastien 19/12/2005
		#le premier est le pere
		#shift @a_hasa_blocs;
        foreach my $hasa_bloc (@a_hasa_blocs)
        {
            if ($hasa_bloc ne '')
            {
                my $rh_hasa = _AnalyseSimple($hasa_bloc);
                push(@a_hasa, $rh_hasa);
            }
        }
    }

    my $ra_hasa    = \@a_hasa;
    my $object_xml = '';

    if ($#a_hasa < 0)
    {
        $ra_hasa    = '';
        $object_xml =
          "<moby:$object_type moby:id='$object_id' moby:namespace='$object_namespace'>$object_content</moby:$object_type>";
    }
    else
    {
        $object_xml = "<moby:$object_type moby:id='$object_id' moby:namespace='$object_namespace'>\n";
        foreach my $rh_hasa (@a_hasa)
        {
            $object_xml .= $rh_hasa->{'object_content'} . "\n";
        }
        $object_xml .= "</moby:$object_type>";
    }

    my %h_simple = (
                    'object_name'           => $object_name,
                    'object_type'           => $object_type,
                    'object_namespace'      => $object_namespace,
                    'object_id'             => $object_id,
                    'object_content'        => $object_content,
                    'object_xml'            => $object_xml,
                    'object_crossreference' => $ra_crossref,
					'object_pib'            => $ra_pib,
                    'object_hasa'           => $ra_hasa
                    );

    return \%h_simple;
}

=head2 simpleResponse (stolen from MOBY::CommonSubs)

 name     : simpleResponse
 function : wraps a simple article in the appropriate (mobyData) structure
 usage    : $resp .= &simpleResponse($object, 'MyArticleName', $queryID);
 args     : (in order)
            $object   - (optional) a MOBY Object as raw XML
            $article  - (optional) an articeName for this article
            $query    - (optional, but strongly recommended) the queryID value for the
                        mobyData block to which you are responding
 notes    : as required by the API you must return a response for every input.
            If one of the inputs was invalid, you return a valid (empty) MOBY
            response by calling &simpleResponse(undef, undef, $queryID) with no arguments.

=cut

sub simpleResponse
{
    my ($data, $articleName, $qID) = @_;    # articleName optional

    $data        ||= '';                    # initialize to avoid uninit value errors
    $qID         ||= "";
    $articleName ||= "";
    if ($articleName)
    {
        return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Simple moby:articleName='$articleName'>$data</moby:Simple>
        </moby:mobyData>
        ";
    }
    elsif ($data)
    {
        return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Simple moby:articleName='$articleName'>$data</moby:Simple>
        </moby:mobyData>
        ";
    }
    else
    {
        return "
        <moby:mobyData moby:queryID='$qID'/>
	";
    }
}

=head2 collectionResponse (stolen from MOBY::CommonSubs)

 name     : collectionResponse
 function : wraps a set of articles in the appropriate mobyData structure
 usage    : return responseHeader . &collectionResponse(\@objects, 'MyArticleName', $queryID) . responseFooter;
 args     : (in order)
            \@objects - (optional) a listref of MOBY Objects as raw XML
            $article  - (optional) an articeName for this article
            $queryID  - (optional, but strongly recommended) the mobyData ID
                        to which you are responding
 notes    : as required by the API you must return a response for every input.
            If one of the inputs was invalid, you return a valid (empty) MOBY
            response by calling &collectionResponse(undef, undef, $queryID).

=cut

sub collectionResponse
{
    my ($data, $articleName, $qID) = @_;    # articleName optional
    my $content = "";
    $data ||= [];
    $qID  ||= '';
    unless ((ref($data) =~ /array/i) && $data->[0])
    {                                       # we're expecting an arrayref as input data,and it must not be empty
        return "<moby:mobyData moby:queryID='$qID'/>";
    }

    foreach (@{$data})
    {
        if ($_)
        {
            $content .= "
                <moby:Simple>$_</moby:Simple>
            ";
        }
        else
        {
            $content .= "
                <moby:Simple/>
            ";
        }
    }
    if ($articleName)
    {
        return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Collection moby:articleName='$articleName'>
                $content
            </moby:Collection>
        </moby:mobyData>
        ";
    }
    else
    {
        return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Collection moby:articleName='$articleName'>$content</moby:Collection>
        </moby:mobyData>
        ";
    }
}


=head2 complexResponse (stolen from MOBY::CommonSubs)

 name     : complexResponse
 function : wraps a set of articles in the one mobyData structure
 usage    : return responseHeader . &complexResponse(\@a_article_structures, $queryID) . responseFooter;
 args     : (in order)
            \@a_article_structures - (optional) a listref of structured articles 
                %h_article = (
                                article_type => 'collection/simple', 
                                article_content => 'MOBY XML formatted content', 
                                article_name => 'articleName attribut')
            $queryID  - (optional, but strongly recommended) the mobyData ID
                        to which you are responding
=cut


sub complexResponse
{
     my ($ra_data, $qID) = @_;

    $ra_data ||= [];
    $qID  ||= '';
    unless ((ref($ra_data) =~ /array/i) && $ra_data->[0])
    {                                       # we're expecting an arrayref as input data,and it must not be empty
        return "<moby:mobyData moby:queryID='$qID'/>";
    }
    my $moby_data_content = '';
    foreach my $rh_data_block (@{$ra_data})
    {
        my $article_name = $rh_data_block->{article_name};
        my $article_content = $rh_data_block->{article_content};

        if ($rh_data_block->{article_type} =~ /collection/i)
        {
            my $collection_content = "<moby:Collection moby:articleName='$article_name'>\n";
            if ((ref($article_content) =~ /array/i) && $article_content->[0])
            {
                foreach my $simple_element (@{$article_content})
                {
                    $collection_content .= "\t<moby:Simple>\n\t$simple_element\n\t</moby:Simple>\n";
                }
            }
            else
            {
                $collection_content .= "\t<moby:Simple/>\n";
            }
            $collection_content .= "</moby:Collection>\n";

            $moby_data_content .= $collection_content;

        }
        else
        {
            my $simple_content = "<moby:Simple moby:articleName='$article_name'>\n\t$article_content\n</moby:Simple>";
            $moby_data_content .= $simple_content;
        }
    }

    return "<moby:mobyData moby:queryID='$qID'>\n\t$moby_data_content\n</moby:mobyData>\n";
}


=head2 responseHeader (stolen from MOBY::CommonSubs)

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
    . "<moby:MOBY xmlns:moby='http://www.biomoby.org/moby' xmlns='http://www.biomoby.org/moby'>"
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


=head2 encodeException (stolen from MOBY::CommonSubs)

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


=head2 responseFooter (stolen from MOBY::CommonSubs)

 name     : responseFooter
 function : print the XML string of a MOBY response footer
 usage    : return responseHeader('illuminae.com') . $DATA . responseFooter;
 notes    :  returns everything required after the response articles themselves
             i.e. something like:

  </moby:Response>
     </moby:MOBY>

=cut

sub responseFooter
{
    return "</moby:mobyContent></moby:MOBY>";
}

=head2 function _IsCollection

 Title        : _IsCollection
 Usage        : _IsCollection($article_type)
 Prerequisite : 
 Function     : Compares a string to string 'collection'
 		Remove namespace 'moby:' from parameter string 
		Case insensitive
 Returns      : BOOLEAN
 Args         : $articletype: a string
 Globals      : none

=cut

sub _IsCollection
{
    my $articletype = shift();

    $articletype =~ s/^moby://;
    if ($articletype =~ /^collection$/i)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

=head2 function _IsSimple

 Title        : _IsSimple
 Usage        : _IsSimple($article_type)
 Prerequisite : 
 Function     : Compares a string to string 'simple'
 		Remove namespace 'moby:' from parameter string 
		Case insensitive
 Returns      : BOOLEAN
 Args         : $articletype: a string
 Globals      : none

=cut

sub _IsSimple
{
    my $articletype = shift();

    $articletype =~ s/^moby://;
    if ($articletype =~ /^simple$/i)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

=head2 function _IsSecondary

 Title        : _IsSecondary
 Usage        : _IsSecondary($article_type)
 Prerequisite : 
 Function     : Compares a string to string 'parameter'
 		Remove namespace 'moby:' from parameter string 
		Case insensitive
 Returns      : BOOLEAN
 Args         : $articletype: a string
 Globals      : none

=cut

sub _IsSecondary
{
    my $articletype = shift();

    $articletype =~ s/^moby://;
    if ($articletype =~ /^parameter$/i)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

=head2 _rearrange (stolen from MOBY::CommonSubs)


=cut

sub _rearrange
{

    #    my $dummy = shift;
    my $order = shift;

    return @_ unless (substr($_[0] || '', 0, 1) eq '-');
    push @_, undef unless $#_ % 2;
    my %param;
    while (@_)
    {
        (my $key = shift) =~ tr/a-z\055/A-Z/d;    #deletes all dashes!
        $param{$key} = shift;
    }
    map {$_ = uc($_)} @$order;                    # for bug #1343, but is there perf hit here?
    return @param{@$order};
}


=head2 function _AnalyseServiceNotes

 Title        : _AnalyseServiceNotes
 Usage        : _AnalyseServiceNotes($simple_bloc)
 Prerequisite : 
 Function     : Analyse a "Simple Bloc" from XSL transformation parsing
			Build a $rh_simple_article structure with fields:
			'object_name'		=> moby:articleName
			'object_type'		=> moby:Class
			'object_namespace'	=> moby:namespace
			'object_id'		=> moby:id
			'object_content'	=> text content of simple article
			'object_xml'		=> full xml content of article
			'object_hasa'		=> ARRAYREF of hasa elements 
						   (each one is structured in a same 
						   structured hash (recursivity)
			'object_crossreference' => ARRAYREF of crossreferences objects 
						   (each one is structured in a hash with fields
						   'type', 'id', 'namespace')

 Returns      : $services_notes: article HASHREF
 				$ra_exceptions: article HASHREF
 Args         : $service_notes_bloc: from parsing of a "serviceNotes" XSLT transformation
 Globals      : none

=cut

sub _AnalyseServiceNotes
{
    my $service_notes_block = shift();
    my @a_exceptions  = ();
    my $service_notes  = '';
	
    
    my $exception_start_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_START#';
    my $exception_end_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_END#';
    my $exception_refelement_start_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_REFELEMENT_START#';
    my $exception_refelement_end_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_REFELEMENT_END#';
    my $exception_refqueryid_start_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_REFQUERYID_START#';
    my $exception_refqueryid_end_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_REFQUERYID_END#';
    my $exception_severity_start_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_SEVERITY_START#';
    my $exception_severity_end_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_SEVERITY_END#';
    my $exception_code_start_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_CODE_START#';
    my $exception_code_end_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_CODE_END#';
    my $exception_message_start_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_MESSAGE_START#';
    my $exception_message_end_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_EXCEPTION_MESSAGE_END#';
   
		
    while ($service_notes_block =~ m/$exception_start_tag(.*)$exception_end_tag/g)
    {
    	my $exception_block = $1;
		my ($refelement,$refqueryid,$severity,$code,$message) = ('','','','','');
		if ($exception_block =~ /$exception_refelement_start_tag(.*)$exception_refelement_end_tag/)
		{
			$refelement = $1;
		}
		if ($exception_block =~ /$exception_refqueryid_start_tag(.*)$exception_refqueryid_end_tag/)
		{
			$refqueryid = $1;
		}
		if ($exception_block =~ /$exception_severity_start_tag(.*)$exception_severity_end_tag/)
		{
			$severity = $1;
		}
		if ($exception_block =~ /$exception_code_start_tag(.*)$exception_code_end_tag/)
		{
			$code = $1;
		}
		if ($exception_block =~ /$exception_message_start_tag(.*)$exception_message_end_tag/)
		{
			$message = $1; 
			$message =~ s/__nl__/\n/g;
		
		}

		my %h_exception =	(	
								'refelement'		=> $refelement,
								'refqueryid'	=> $refqueryid,
								'severity'	=> $severity,
								'code'		=> $code,
								'message'	=> $message
							);


        push(@a_exceptions, \%h_exception);
    }
    my $ra_exceptions = \@a_exceptions;
    if ($#a_exceptions < 0)
    {
        $ra_exceptions = '';
    }


	my $notes_start_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_NOTES_START#';
	my $notes_end_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES_NOTES_END#';
	
	if ($service_notes_block =~ /$notes_start_tag(.*)$notes_end_tag/)
	{
		$service_notes = $1;
	}

    return ($service_notes,$ra_exceptions);
}


1;
