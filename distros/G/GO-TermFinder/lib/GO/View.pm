package GO::View;

#########################################################################
# Module Name  :  View.pm
#
# Date created :  Oct. 2003
# 
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#########################################################################

# POD documentation - main docs before the code

# TODO

# have a much better options handling set of code, probably based on Getopt::Long
# see http://www.perl.com/pub/a/2007/07/12/options-and-configuration.html

=pod

=head1 NAME

GO::View - Creates a gif or png image for visualizing the GO DAG


=head1 DESCRIPTION

This perl module generates a graphic that displays the parent and child 
relationships of a selected GO term. It also provides the visualization 
for the GO::TermFinder perl module created by the Stanford Microarray 
Database (SMD). This module is useful when analyzing experimental or 
computational results that produce a set of gene products that may have 
a common function or process.

=head1 SYNOPSIS

    use GO::View;

    my $goView = 

       GO::View->new(-goid               => $goid,
		     -ontologyProvider   => $ontology,
		     -annotationProvider => $annotation,
		     -termFinder         => \@pvalues,
		     -aspect             => 'P',
		     -configFile         => $confFile,
		     -imageDir           => "/tmp",
		     -imageUrlRoot       => "http://www.ABC.com/tmp",
		     -imageName          => "GOview.88.png",
		     -tree               => 'up',
		     -nodeUrl            => $goUrl,
                     -geneUrl            => $geneUrl,
		     -pvalueCutOff       => '0.01',
		     -imageLabel         => "SGD");
				  

    argument              required             expect data and type
    -------------------------------------------------------------------------
    -goid                 No          A gene ontology ID (GOID).
                                      If nothing is passed in, the module 
                                      will use the top goid of each ontology 
                                      branch (i.e, goid for 
				      molecular_function, biological_process,
				      or cellular_component)

    -ontologyProvider	  Yes         An ontology provider instance.

    -annotationProvider   No          An annotation provider instance. It is
                                      required for creating tree for GO Term
                                      Finder result.
    
    -termFinder           No          An array of hash references returned 
                                      from 'findTerms' method of 
                                      GO::TermFinder module. It is required
                                      for creating tree for GO Term Finder 
                                      result. 

    -aspect               No          <P|C|F>. The aspect of the ontology 
                                      provider. It is required for creating 
                                      tree for GO Term Finder result.
    
    -configFile           Yes         The configuration file for setting the
                                      general variables for the graphic 
                                      display. 
				  
    -imageDir             Yes         The directory for storing the newly 
                                      created image file. It must be 
                                      world (nobody) readable and writable
                                      if you want to display the image to 
                                      the web.
 
    -imageUrlRoot         No          The url root for the -imageDir. It is
                                      required if you want to display the
                                      image to the web.

    -imageName            No          The image file name. By default, the 
                                      name will be something like 
                                      'GOview.xxxx.png'. The 'xxxx' will be
                                      the process id.  A suffix for the image (.png
                                      or .gif) should not be provided, as that will
                                      be determined at run time, depending on the
                                      capabilities of the GD library.

    -treeType             No          <up|down>. The tree type. 
                                      
                                      1. up   => display the ancestor tree 
                                                 for the given goid.
                                      2. down => display the descendant tree
                                                 for the given goid.
                                      By default, it will display the 
                                      descendant tree.

    -geneUrl              No          The URL for each Gene to link to.
                                      It needs to have the text <REPLACE_THIS> in 
                                      the url which will be substituted 
                                      by the real goid for a node.

    -nodeUrl              No          The url for each GO node to link to.
                                      It needs to have the text <REPLACE_THIS> in 
                                      the url which will be substituted 
                                      by the real goid for a node.

    -pvalueCutOff         No          The p-value cutoff for displaying
                                      the graphic for GO Term Finder. 
                                      The default is 0.01

    -imageLabel           No          The image label which will appear at
                                      the left bottom corner of the map.

    -maxTopNodeToShow     No          This argument is used to limit the
                                      amount of the graph that might be
                                      shown, for the sake of reducing run-
                                      time.  The default is 6.

    ------------------------------------------------------------------------

    To display the image on the web:

         $goView->showGraph;
    
    To create and return image file name with full path:
    
         my $imageFile = $goView->createImage;



=head1 FEEDBACK

=head2 Reporting Bugs

Bug reports can be submitted via email 

  shuai@genome.stanford.edu

=head1 AUTHOR

Shuai Weng, shuai@genome.stanford.edu

=head1 COPYRIGHT

Copyright (c) 2003 Stanford University. All Rights Reserved.
This module is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=head1 APPENDIX

The rest of the documentation details each of the public methods.

=cut

use strict;
use warnings;
use GD;
use GraphViz;
use IO::File;

use GO::View::GD;

use vars qw ($PACKAGE $VERSION);

$PACKAGE = 'GO::View';
$VERSION = 0.15;

my $kReplacementText = "<REPLACE_THIS>";

#########################################################################

=head1 METHODS

=cut

#########################################################################
sub new {
#########################################################################

=head2 new

 Title   : new
 Function: Initializes the GO::View object. 
         : Recognized named parameters are -goid, -ontologyProvider,
           -annotationProvider, -termFinder, -aspect, -configFile, 
           -imageDir, -imageUrlRoot, -imageName, -treeType, -nodeUrl, 
           -imageLabel
 Returns : a new object
 Args    : named parameters

=cut

#########################################################################
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $self->_init(%args);

    return $self;

}

#################################################################
sub graph {
#################################################################

=head2 graph

 Title   : graph
 Usage   : my $graph = $goView->graph;
 Function: Gets the newly created Graphviz instance.   
 Returns : a new Graphviz instance.
 
=cut

################################################################
 
    return $_[0]->{GRAPH};

}

################################################################
sub showGraph {
################################################################

=head2 showGraph

 Title   : showGraph
 Usage   : $goView->showGraph;
 Function: Creates the image and print the map image to a file.  
 Returns : the name of the file to which the image was written
 Throws  : Exception if the imageUrlRoot is not passed to the object.  

=cut
 
#########################################################################
    my ($self) = @_;

    if ($self->graph) {

	$self->_createAndShowImage;
    
    }

    return $self->{IMAGE_FILE};

}

#########################################################################
sub imageFile {
#########################################################################

=head2 imageFile

 Title   : imageFile
 Usage   : my $imageFile = $goView->imageFile;
 Function: Gets the newly created image file name (with full path).  
 Returns : image file name.

=cut
    
#########################################################################

    my ($self) = @_;

    return $self->{IMAGE_FILE};


}

################################################################
sub createImage {
################################################################

=head2 createImage

 Title   : createImage
 Usage   : $goView->createImage; 
 Function: Creates the GO tree image file. Calls it only if you 
           want to create the image file only and do not want to
           display the image.  
 Returns : The newly created image file name with full path.

=cut
    
#########################################################################
    
    my ($self) = @_;

    if ($self->graph) {

	$self->{CREATE_IMAGE_ONLY} = 1;

	return $self->_createAndShowImage;
	
    }

}

################################################################
sub imageMap{
################################################################

=head2 imageMap

 Title    : imageMap
 Usage    : my $map = $goView->imageMap;
 Function : returns the text that constitutes an image map for the
            created image.
 Returns  : a string

=cut

#########################################################################

    return $_[0]->{IMAGE_MAP};

}

################################################################
sub _goid {
################################################################
#
# =head2 _goid 
#
#  Title   : _goid
#  Usage   : my $goid = $self->_goid;
#  Function: Gets the goid that client interface passed in.
#  Returns : GOID
#  Args    : none    
# 
# =cut
# 
#########################################################################

    my ($self) = @_;

    return $self->{GOID};

}

#########################################################################
sub _ontologyProvider {
#########################################################################
#
# =head2 _ontologyProvider 
#
#  Title   : _ontologyProvider
#  Usage   : my $ontology = $self->_ontologyProvider;
#  Function: Gets the ontology provider instance which is passed in by 
#            client interface.
#  Returns : ontology provider instance 
#  Args    : none    
# 
# =cut
# 
#########################################################################

    my ($self) = @_;

    return $self->{ONTOLOGY};

}

#########################################################################
sub _annotationProvider {
#########################################################################
#
# =head2 _annotationProvider 
#
#  Title   : _annotationProvider
#  Usage   : my $annotation = $self->_annotationProvider;
#  Function: Gets the annotation provider instance which is passed in by 
#            client interface.
#  Returns : annotation provider instance 
#  Args    : none    
# 
# =cut
# 
#########################################################################

    my ($self) = @_;

    return $self->{ANNOTATION};

}

#########################################################################
sub _termFinder {
#########################################################################
#
# =head2 _termFinder 
#
#  Title   : _termFinder
#  Usage   : my $termFinder = $self->_termFinderProvider;
#  Function: Gets the term finder result arrayref which is passed in by 
#            client interface.
#  Returns : term finder result arrayref 
#  Args    : none    
# 
# =cut
# 
#########################################################################

    my ($self) = @_;

    return $self->{TERM_FINDER};

}

#########################################################################
sub _init {
#########################################################################
#
# =head2 _init
#
# Title   : _init
# Usage   : n/a; automatically called by new()
# Function: Initializes the variables required for creating the map. 
# Returns : void 
# Args    : n/a
# Throws  : Exception if ontology provider instance or tmp image 
#           directory for storing the image file are not passed 
#           to this object.
#
# =cut
#
#########################################################################

    my ($self, %args) = @_;

    # first do some sanity checks

    if (!$args{-ontologyProvider} || !$args{-configFile} || 
	!$args{-imageDir}) {

	die "Can't build a $PACKAGE object without the ontologyProvider, configuration file, and tmp image directory name for storing the image file.";
		
    }

    $self->{ONTOLOGY} = $args{-ontologyProvider};

    if ($args{-goid} && $args{-goid} !~ /^[0-9]+$/ && 
	$args{-goid} !~ /^GO:[0-9]+$/) {

	die "The goid ($args{-goid}) passed to $PACKAGE is is not in a recognized format, such as GO:0000166.";

    }
	
    my $goid = $args{-goid};

    # fix format of the GOID, so it is padded preceded with GO: and properly padded

    if ($goid && $goid !~ /^GO:[0-9]+$/) { 

	$goid = $self->_formatGoid($goid); 

    }

    # if we have no goid passed in, then we're likely creating an
    # image based upon the output from GO::TermFinder.  In this case
    # we just set the goid to the node corresponding to the aspect
    # that is being dealt with

    if (!$goid) {

	# set top goid for the given ontology (molecular_function, 
	# biological_process, or cellular_component).

	$goid = $self->_initGoidFromOntology; 

    }

    # now store the goid

    $self->{GOID} = $goid;

    # work out the image name and url - note that they will both
    # receive a suffix later on that indicates the type of image that
    # has been output (png or gif)

    $self->{IMAGE_DIR} = $args{-imageDir};

    if ($self->{IMAGE_DIR} !~ /\/$/) {  

	$self->{IMAGE_DIR} .= "/"; 

    }

    my $suffix;

    if (GD::Image->can('png')){

	$suffix = 'png';

    }else{

	$suffix = 'gif';

    }

    my $imageName;

    if (exists $args{-imageName} && defined $args{-imageName} && $args{-imageName} ne ""){

	$imageName = $args{-imageName};

    }else{

	my $id = $$;

	# now keep incrementing $id, until the name
	# doesn't clash with an existing file

	while (-e $self->{IMAGE_DIR}."GOview.$id.$suffix"){

	    $id++;
     
	}

	$imageName = "GOview.$id";

    }

    $imageName .= ".$suffix";

    $self->{IMAGE_FILE} = $self->{IMAGE_DIR}.$imageName;

    if ($args{-imageUrlRoot}) {
	
	$self->{IMAGE_URL} = $args{-imageUrlRoot};
 
	if ($self->{IMAGE_URL} !~ /\/$/) { $self->{IMAGE_URL} .= "/"; }

	$self->{IMAGE_URL} .= $imageName;

    }else{

	# if we didn't get a root url, we just assume that the image will
	# be in the same directory as the image

	$self->{IMAGE_URL} = "./".$imageName;

    }

    # now set the TREE_TYPE, which can be up or down.

    $self->{TREE_TYPE} = $args{-treeType} || 'down';

    my $count;

    $self->{MAX_TOP_NODE_TO_SHOW} = $args{-maxTopNodeToShow} || 6;

    if ($args{-annotationProvider} && $args{-termFinder} && 
	$args{-aspect}) {

	# we're dealing with GO::TermFinder output, so we'll
	# store and initialize all the information we need

	$self->{PVALUE_CUTOFF} = $args{-pvalueCutOff} || 0.01;

	$self->{ANNOTATION} = $args{-annotationProvider};

	$self->{TERM_FINDER} = $args{-termFinder};

	$self->{ASPECT} = $args{-aspect};

	$count = $self->_initPvaluesGeneNamesDescendantGoids;

    }elsif ($args{-annotationProvider} || $args{-termFinder} || 
	    $args{-aspect}) {

	die "You have to pass annotation provider and term finder instances and GO aspect ([P|F|C]) to $PACKAGE if you want to display graphic for term finder result.";

    }
  
    # store some more variables    

    $self->{IMAGE_LABEL} = $args{-imageLabel};

    $self->{GENE_URL} = $args{-geneUrl};

    $self->{GO_URL} = $args{-nodeUrl};

    $self->_initVariablesFromConfigFile($args{-configFile});

    # only make the graph if we had at least one node passing our p value cutoff

    $self->_createGraph if ($count > 0);

}

################################################################
sub _createGraph {
################################################################
#
# =head2 _createGraph
#
# Title   : _createGraph
# Usage   : $self->_createGraph; 
#           automatically called by _init()
# Function: To create the GraphViz instance and add each descendant/ 
#           ancestor goid into the Graph tree.
# Returns : newly created GraphViz instance.
#
# =cut
#
#########################################################################

    my ($self) = @_;

    # If client does not ask for up (ancestor) tree and this is not
    # for the special tree paths client asked for the given goid to
    # its specified descendants (i.e. for GO Term Finder), then we
    # need to determine how many generations of the descendants we can
    # display.

    if ($self->{TREE_TYPE} !~ /up/i && 
	!$self->{DESCENDANT_GOID_ARRAY_REF}) {
	
	$self->_setGeneration($self->_goid);

    }

    # If this is for the ancestor tree, we need to determine up to
    # which ancestor we want to display the tree paths. We will
    # display tree path up to $self->{TOP_GOID}

    if ($self->{TREE_TYPE} =~ /up/i) {

	$self->_setTopGoid;

	if (!$self->{TOP_GOID}) { return; }
	    
	$self->{NODE_NUM} = $self->_descendantCount($self->{TOP_GOID},
						    $self->{GENERATION});

    }
    
    my $goid;

    if ($self->{TOP_GOID}) {

	$goid = $self->{TOP_GOID};

    }else {

	$goid = $self->_goid;

    }

    $self->_createGraphObject;

    my %foundNode;
    my %foundEdge;
    
    # add the top node to the graph

    $self->_addNode($goid,
		    fillcolor => $self->_colorForNode($goid),
		    color     => $self->_colorForNode($goid));

    # and record that we've seen it

    $foundNode{$goid}++;

    # draw go_path for ancestor goid ($self->{GOID}) to each
    # descendant goid in @{$self->{DESCENDANT_GOID_ARRAY_REF}}.  The
    # DESCENDANT_GOID_ARRAY_REF is only created if we were dealing
    # with output from GO::TermFinder

    if ($self->{DESCENDANT_GOID_ARRAY_REF}) {
	
	# get the top node

	my $topAncestorNode = $self->_ontologyProvider->nodeFromId($self->_goid);

	# and record its term

	$self->{TERM_HASH_REF_FOR_GOID}{$self->_goid} = $topAncestorNode->term;

	my $i;

	# now go through every GO Node to which our list of genes is
	# directly annotated that contibuted to the gene count of a
	# node that passed the cutoff

	foreach my $goid (@{$self->{DESCENDANT_GOID_ARRAY_REF}}) {

	    my $childNode = $self->_ontologyProvider->nodeFromId($goid);

	    # get the list of paths that link from this node up to the
	    # top - the first node in each path is the root, and the
	    # final node is the immediate parent of $childNode

	    my @path = $childNode->pathsToAncestor($topAncestorNode);

	    # now add that path to the graph

	    my $found = $self->_addAncestorPathToGraph($childNode, 
						       \@path, 
						       \%foundNode, 
						       \%foundEdge); 

	    # we can skip to the next goid if no new nodes were added
	    # to the graph

	    next if (!$found);

	    $i++;

	    # now add the genes that are annotated to this node

	    if ($self->{GENE_NAME_HASH_REF_FOR_GOID} &&
		$self->{GENE_NAME_HASH_REF_FOR_GOID}->{$goid}) {

		my $loci = $self->{GENE_NAME_HASH_REF_FOR_GOID}->{$goid};

		$loci =~ s/:/ /g;

		$self->_addNode($loci,
				fillcolor => 'grey65',
				color     => 'grey65',
				fontcolor => 'blue');

		$self->_addEdge($goid, $loci);

	    }

	}

	return;

    } 

    # draw part of the tree, and it can go up and down the tree.

    # draw up tree and only show ancestors in the paths from the given
    # goid to the ancestor goid $self->{TOP_GOID} since there are too
    # many nodes...

    if ($self->{TREE_TYPE} =~ /up/i && 
	$self->{NODE_NUM} > $self->{MAX_NODE}) {
	
	my $childNode = $self->_ontologyProvider->nodeFromId($self->_goid);

	my $topAncestorNode = $self->_ontologyProvider->nodeFromId($goid);

	my @path = $childNode->pathsToAncestor($topAncestorNode);

	$self->_addAncestorPathToGraph($childNode, 
				       \@path, 
				       \%foundNode, 
				       \%foundEdge); 

	return;

    }
		
    ##### draw down tree

    my $node = $self->_ontologyProvider->nodeFromId($goid);

    $self->_addChildOfTheNodeToGraph($node, 
				     \%foundNode,
				     \%foundEdge);

}

################################################################
sub _addChildOfTheNodeToGraph {
################################################################
#
# =head2 _addChildOfTheNodeToGraph
#
# Title   : _addChildOfTheNodeToGraph
# Usage   : $self->_addChildOfTheNodeToGraph($node, 
#                                            $foundNodeHashRef,
#                                            $foundEdgeHashRef);
#           
# Function: To add each unique descendant of the given node to the 
#           graph tree.
# Returns : void
#
# =cut
#
#########################################################################

# This is only called when we are dealing with a 'down' tree.  It is
# not called when dealing with GO::TermFinder output

    my ($self, $node, $foundNodeHashRef, $foundEdgeHashRef,
	$generation) = @_;

    if (!$generation) { $generation = 1; }
    
    my @childNodes = $node->childNodes;

    foreach my $childNode ($node->childNodes) {

	my $parentGoid = $node->goid;

	my $childGoid = $childNode->goid;

	if (!$foundNodeHashRef->{$parentGoid}) {

	    $self->_addNode($parentGoid);

	    $foundNodeHashRef->{$parentGoid}++;

	}

	if (!$foundNodeHashRef->{$childGoid}) {

	    $self->_addNode($childGoid);

	    $foundNodeHashRef->{$childGoid}++;

	}
	if (!$foundEdgeHashRef->{$parentGoid."::".$childGoid}) {

	    $self->_addEdge($parentGoid, $childGoid);

	    $foundEdgeHashRef->{$parentGoid."::".$childGoid}++;

        }

	if ($generation < $self->{GENERATION}) {

	    $self->_addChildOfTheNodeToGraph($childNode, 
					     $foundNodeHashRef, 
					     $foundEdgeHashRef,
					     $generation++);
	}

    }

}

################################################################
sub _addAncestorPathToGraph {
################################################################
#
# =head2 _addAncestorPathToGraph
#
# Title   : _addAncestorPathToGraph
# Usage   : $self->_addAncestorPathToGraph($node,
#                                          $ancestorPathArrayRef, 
#                                          $foundNodeHashRef,
#                                          $foundEdgeHashRef);
#           
# Function: To add each unique ancestor of the given node to the 
#           graph tree.
# Returns : void
#
# =cut
#
#########################################################################

# This is only called when we are dealing with an 'up' tree, or when
# dealing with GO::TermFinder output

    my ($self, $childNode, $ancestorPathArrayRef, 
	$foundNodeHashRef, $foundEdgeHashRef) = @_; 

    my $found;

    # go through each path back to the root

    foreach my $ancestorNodeArrayRef (@{$ancestorPathArrayRef}) {
	
	# add the child node to the path, so it gets included too
		
	push(@{$ancestorNodeArrayRef}, $childNode);

	# reverse the order, so that we have the child node first, and
	# the root last

	@{$ancestorNodeArrayRef} = reverse(@{$ancestorNodeArrayRef});

	# now go through the path

	for (my $i = 0; $i < @{$ancestorNodeArrayRef}; $i++) {

	    my ($goid1, $goid2);

	    # get the goid for the current node, and store it's term

	    if (defined $ancestorNodeArrayRef->[$i]) {

		$goid1 = $ancestorNodeArrayRef->[$i]->goid;

		$self->{TERM_HASH_REF_FOR_GOID}{$goid1} 
		        = $ancestorNodeArrayRef->[$i]->term;

	    }

	    # get the goid for the next node (the current node's
	    # parent), and store it's term too

	    if (defined $ancestorNodeArrayRef->[$i+1]) {

		$goid2 = $ancestorNodeArrayRef->[$i+1]->goid;

		$self->{TERM_HASH_REF_FOR_GOID}{$goid2} 
		        = $ancestorNodeArrayRef->[$i+1]->term;
		
	    }
    
	    # if the current node isn't already on the graph, add it

	    if ($goid1 && !$foundNodeHashRef->{$goid1}) {

		$self->_addNode($goid1,
				fillcolor => $self->_colorForNode($goid1),
				color     => $self->_colorForNode($goid1));

		# record that we've seen it

		$foundNodeHashRef->{$goid1}++;

	    }

	    # if we have a parent, and we haven't yet recorded an edge
	    # between the child and parent, let's add that

	    if ($goid1 && $goid2 && 
		!$foundEdgeHashRef->{$goid2."::".$goid1}) {

		$self->_addEdge($goid2, $goid1);

		# record that we've added the edge

		$foundEdgeHashRef->{$goid2."::".$goid1}++;

	    }

	}

	# record that something has been added to the graph (as it's
	# possible that we may end up finding we've added everything

	$found++;

    }

    # return whether something was added to the graph

    return $found;
    
}

################################################################
sub _createAndShowImage {
################################################################
#
# =head2 _createAndShowImage
#
# Title   : _createAndShowImage
# Usage   : $self->_createAndShowImage();
#           automatically called by showGraph() and createImage().
# Function: To create the graph tree image. It will print the image to
#           stdout if it is called by showGraph().
# Returns : returns graphText file if the text format is changed. 
#           returns image file name if called by createImage().
#
# =cut
#
#########################################################################

    my ($self) = @_;

    my ($width, $height);

    # first thing we do is get the contents of the graph in text form.
    # We will then use this text to create a gif or png image, with
    # various boxes etc that have the coordinates as indicated by the
    # text from the graph image.

    # the actual contents of the text string will be something like:
    
    # digraph test {
    #        node [label="\N", shape=box];
    #        graph [bb="0,0,662,1012"];
    #        node1 [label=" biological_process\nGO:GO:0008150", pos="342,986", width="1.97", height="0.50"];
    #        node2 [label="pre-replicative\ncomplex\nformation and\n maintenance\nGO:GO:0006267", pos="162,122", width="1.69", height="1.17"];
    #        node3 [label="DNA-dependent\n DNA replication\nGO:GO:0006261", pos="353,226", width="1.86", height="0.72"];
    #        node4 [label=" DNA replication\nGO:GO:0006260", pos="353,306", width="1.86", height="0.50"];
    #        node5 [label="DNA replication\nand chromosome\n cycle\nGO:GO:0000067", pos="299,394", width="1.83", height="0.94"];
    #        node6 [label=" cell cycle\nGO:GO:0007049", pos="271,482", width="1.72", height="0.50"];
    #        node7 [label="cell\n proliferation\nGO:GO:0008283", pos="271,586", width="1.67", height="0.72"];
    #        node8 [label="cell growth\nand/or\n maintenance\nGO:GO:0008151", pos="271,706", width="1.61", height="0.94"];
    #        node9 [label="cellular\nphysiological\n process\nGO:GO:0050875", pos="272,810", width="1.67", height="0.94"];
    #        node10 [label="cellular\n process\nGO:GO:0009987", pos="272,906", width="1.69", height="0.72"];
    #        node11 [label="physiological\n process\nGO:GO:0007582", pos="412,906", width="1.69", height="0.72"];
    #        node12 [label=" DNA metabolism\nGO:GO:0006259", pos="422,482", width="1.97", height="0.50"];
    #        node13 [label="nucleobase,\nnucleoside,\nnucleotide and\nnucleic acid\n metabolism\nGO:GO:0006139", pos="421,586", width="1.64", height="1.39"];
    #        node14 [label=" metabolism\nGO:GO:0008152", pos="420,706", width="1.64", height="0.50"];
    #        node15 [label=" 1: MCM4 MCM3 CDC6 MCM2", pos="119,26", width="3.31", height="0.50"];
    #        node16 [label=" DNA unwinding\nGO:GO:0006268", pos="353,122", width="1.92", height="0.50"];
    #        node17 [label=" 2: MCM4 MCM3 MCM2", pos="353,26", width="2.69", height="0.50"];
    #        node18 [label="DNA replication\n initiation\nGO:GO:0006270", pos="534,122", width="1.78", height="0.72"];
    #        node19 [label=" 3: MCM4 MCM3 MCM2", pos="565,26", width="2.69", height="0.50"];
    #        node5 -> node4 [pos="e,342,324 320,360 325,351 331,341 337,332"];
    #        node13 -> node12 [pos="e,422,500 421,536 421,527 422,517 422,509"];
    #        node12 -> node4 [pos="e,360,324 415,464 402,433 377,369 363,333"];
    #        node4 -> node3 [pos="e,353,252 353,288 353,280 353,271 353,262"];
    #        node3 -> node2 [pos="e,223,155 305,200 283,187 256,173 232,160"];
    #        node3 -> node16 [pos="e,353,140 353,200 353,184 353,165 353,149"];
    #        node3 -> node18 [pos="e,489,148 399,200 423,186 454,168 480,153"];
    #        node2 -> node15 [pos="e,127,44 143,80 139,70 135,61 131,52"];
    #        node16 -> node17 [pos="e,353,44 353,104 353,90 353,69 353,53"];
    #        node18 -> node19 [pos="e,559,44 542,96 547,82 552,66 556,53"];
    #        node6 -> node5 [pos="e,288,428 277,464 279,457 282,447 285,438"];
    #        node11 -> node14 [pos="e,419,724 413,880 415,842 418,773 419,734"];
    #        node11 -> node9 [pos="e,322,844 374,880 361,871 345,860 330,850"];
    #        node1 -> node11 [pos="e,389,932 358,968 365,959 374,949 382,940"];
    #        node1 -> node10 [pos="e,295,932 326,968 319,959 310,949 302,940"];
    #        node8 -> node7 [pos="e,271,612 271,672 271,656 271,638 271,621"];
    #        node14 -> node13 [pos="e,420,636 420,688 420,677 420,661 420,647"];
    #        node7 -> node6 [pos="e,271,500 271,560 271,544 271,525 271,509"];
    #        node10 -> node9 [pos="e,272,844 272,880 272,872 272,863 272,854"];
    #        node9 -> node8 [pos="e,271,740 272,776 272,768 271,758 271,749"];
    # }

    # a description of the dot language can be found at:
    #
    # http://www.research.att.com/~erg/graphviz/info/lang.html

    if (defined $self->{MAKE_PS} && $self->{MAKE_PS}){

	my $file = $self->{IMAGE_FILE};

	$file =~ s/\.\w+$/\.ps/;

	my $fh = IO::File->new($file, q{>} )|| die "Cannot create $file : $!";

	print $fh $self->graph->as_ps;

	$fh->close;

    }

    # hence we can determine the size of the image, the positions and sizes
    # of every box, and how to draw the edges between the boxes 

    my $graphText = $self->graph->as_text;

    # the following line *may* fix reported problems when running on
    # Windows, that I think are a result of dot.exe using CRLF line
    # endings.

    $graphText =~ s/\015?\012/\n/g;

    # if we can get the height and width, we'll get them

    if ($graphText =~ /graph \[bb=\"0,0,([0-9]+),([0-9]+)\" *\]\;/) {
       
	$width  = $1 * $self->{WIDTH_DISPLAY_RATIO};

	$height = $2 * $self->{HEIGHT_DISPLAY_RATIO};

    }else {

	# otherwise, we simply create a png image and we're done

	# this seems to be undocumented - I'm not sure under what
	# circumstances we can't actually get the height and width

	$self->graph->as_png($self->{IMAGE_DIR}."goPath.$$.png");

        return $self->{IMAGE_DIR}."goPath.$$.png";

    }

    my @graphLine = split(/\n/, $graphText);

    # add borders sizes to the height and width

    my $border = 25;
    
    my $mapWidth  = $width  + 2 * $border;

    my $mapHeight = $height + 2 * $border;

    my $keyY;

    # now modify the height and width according to unclear rules....

    if ($self->{PVALUE_HASH_REF_FOR_GOID} || !$self->{GENE_NAME_HASH_REF_FOR_GOID}) {

	$keyY = $mapHeight;

	# make the width to be at least the minimum acceptable width

	if ($mapWidth < $self->{MIN_MAP_WIDTH}) { 

	    $mapWidth = $self->{MIN_MAP_WIDTH}; 

	}

	# modify the height 

	if (!$self->{GENE_NAME_HASH_REF_FOR_GOID}) {

	    # if there are no genes annotated to nodes, use some
	    # complex, opaque and unclear rule to change the height

	    $mapHeight += int((length($self->{MAP_NOTE})*6/($mapWidth-100))*15) + 65;

	}else {

	    # otherwise just add 50, the 'magic number'...

	    $mapHeight += 50;

	}

    }

    # now create a GD image of the appropriate height and width

    my $gd = GO::View::GD->new(width  => $mapWidth,
			       height => $mapHeight);

    # add a border, with a label and a date

    $self->_drawFrame($gd, $mapWidth, $mapHeight);

    my (@nodeLine, @edgeLine);

    my $preLine;

    # now go through each line of the output from the graph->as_text method

    foreach my $line (@graphLine) {

	if ($line =~ /\\$/) { 

	    # if it ends with a backslash (i.e. is a wrapped line), we
	    # simply remove the trailing slash, and any leading
	    # spaces, and remember it.

	    $line =~ s/\\$//;

	    $line =~ s/^ *//;

	    $preLine .= $line;

	    next;

	}elsif ($preLine && $line =~ /\;$/ && $line !~ / *node[0-9]/) {

	    # if we have some remembered previous line, and this line
	    # ends in a semi-colon (which terminates the entity), and
	    # this line does not begin the definition of a node, then
	    # we add the previous line information to this line, and
	    # undef the $preLine variable

	    $line = $preLine.$line;

	    undef $preLine;

	}

	# now store type of entity (nodes vs edges) in different
	# arrays

	if ($line =~ / *node[0-9]+ *\[(label=.+)\]\;$/i) {

	    # it's a node

	    push(@nodeLine, $1);

	}elsif ($line  =~ / *node[0-9]+ *-> *node[0-9]+ \[pos=\"(.+)\"\]\;$/i) {

	    # it's an edge

	    push(@edgeLine, $1);

	}

    }

    # add the keys, which are either keys for the p-value colors, or a
    # general description about GO terms and their annotations

    if (exists $self->{PVALUE_HASH_REF_FOR_GOID} && 
	$height > $self->{MIN_MAP_WIDTH_FOR_ONE_LINE_KEY}) {

	### draw keys on the top of the map
	if ($width < $self->{MIN_MAP_WIDTH_FOR_ONE_LINE_KEY}) {

	    $self->{MOVE_Y} = 15;

	}

	$self->_drawKeys($gd, $mapWidth, 5, 'isTop');

    }

    if ($self->{PVALUE_HASH_REF_FOR_GOID} || 
	!$self->{GENE_NAME_HASH_REF_FOR_GOID}) {

	$self->_drawKeys($gd, $mapWidth, $keyY);

    }

    # now draw the actual edges and nodes

    # do the edges first
    
    foreach my $line (@edgeLine) {

	$self->_drawEdge($gd, $height, $border, $line);

    }

    # and now the nodes

    foreach my $line (@nodeLine) {

	$self->_drawNode($gd, $height, $border, $line);

    }

    # now output the image to a file

    my $imageFile = $self->{IMAGE_FILE}; 
    my $imageUrl  = $self->{IMAGE_URL};

    my $fh = IO::File->new($imageFile, q{>} )|| die "Cannot create $imageFile : $!";

    binmode $fh;

    if ($gd->im->can('png')) {

	print $fh $gd->im->png;

    }else {

	print $fh $gd->im->gif;

    }

    $fh->close;

    if ($self->{CREATE_IMAGE_ONLY}) {
	
	return $imageFile;

    }else{

	my $map = $gd->imageMap;

	if (defined ($map)){

	    $self->{IMAGE_MAP} = 
		
		"<MAP NAME='goPathImage'>\n".
		$gd->imageMap.
		"</MAP>".
		"<center><img src='$imageUrl' usemap='#goPathImage'></center><p>\n";

	}

    }

}

######################################################################
sub _drawNode {
######################################################################
#
# =head2 _drawNode
#
# Title   : _drawNode
# Usage   : $self->_drawNode($gd, $height, $border, $line);
#           automatically called by _createAndShowImage().
# Function: To draw each node.
# Returns : void
#           
# =cut
#
#########################################################################

    my ($self, $gd, $height, $border, $line) = @_;

    # let's let's extract the information from the line, e.g. which may look like:
    #
    #        label="MCM4 MCM3 MCM2", pos="565,26", width="2.69", height="0.50"
    #
    # or:
    #
    #        label=MET28, color=grey65, fillcolor=grey65, fontcolor=blue, pos="735,561", width="0.92", height="0.50"
    #
    # or:
    #
    #        label=" DNA unwinding\nGO:GO:0006268", pos="353,122", width="1.92", height="0.50"
    #
    # depending on whether it's genes annotating a GO node, or a box
    # representing a GO Node itself

    # get the label - may or may not be surrounded in quotes

    my $label;

    if ($line =~ /label=\"([^\"]*)\"/){
    
	$label = $1;

    }elsif ($line =~ /label=(.+?), /){

	$label = $1;
	
    }

    my @label = split(/\\n/, $label);

    # get the width and height, and convert to number of pixels - I
    # don't know where the use of the value '60' comes from.  The documentation for graphviz says that
    # the default scale is actually 72 pixels per inch...

    $line =~ /width=\"([^\"]+)\"/;

    my $boxW = $1 * 60;

    $line =~ /height=\"([^\"]+)\"/;

    my $boxH = $1 * 60;

    # remove some arbitrary amount based on the label - presumably
    # this is because we're removing the GO id from the label?

    $boxH -= 4*(@label-1);

    # and for some reason subtract an extra 10 if we have a
    # p-value for it?

    if ($self->{PVALUE_HASH_REF_FOR_GOID}) {

	$boxH -= 10;

    }
	
    if (!$self->{MOVE_Y}) { 

	$self->{MOVE_Y} = 0;

    }

    # now get the coordinates of the center of box for the node, and
    # use that to work out the coordinate of the bounding box for the
    # node.

    $line =~ /pos=\"([0-9]+),([0-9]+)\"/;

    my $x1 = $1 * $self->{WIDTH_DISPLAY_RATIO}-$boxW/2 + $border;
    
    my $y1 = $height - $2 * $self->{HEIGHT_DISPLAY_RATIO} - $boxH/2 + $border + $self->{MOVE_Y};

    my $x2 = $x1 + $boxW;

    my $y2 = $y1 + $boxH;

    my $goid;

    if ($label =~ /(GO:[0-9]+)$/) {
	
	$goid = $1;
	
    }
    
    if (!$goid) {
	
	$boxH = 9*(@label) + 4;
	
    }
    
    my $geneNum;
    my $totalGeneNum;
    my $barColor;
    my $outline;
    my $linkUrl;
    
    # now work out the color for the box, and work out URL links
    # for the nodes
    
    if ($self->{PVALUE_HASH_REF_FOR_GOID} && $goid) {
	
	# we must be dealing with GO::TermFinder output for a goid
	
	$barColor = $self->_getBoxColor($gd, $goid);
	
	if (!$self->{CREATE_IMAGE_ONLY}) {
	    
	    $linkUrl = $self->{GO_URL};
	    
	    $linkUrl =~ s/$kReplacementText/$goid/ if $linkUrl;
	    
	}
	
    }elsif ($goid) {
	
	# non GO::TermFinder output for a GOID
	
	my $node = $self->_ontologyProvider->nodeFromId($goid);
	
	if ($node && $node->childNodes) {
	    
	    $barColor = $gd->lightBlue;
	    
	    if (!$self->{CREATE_IMAGE_ONLY}) {
		
		$linkUrl = $self->{GO_URL};
		
		$linkUrl =~ s/$kReplacementText/$goid/ if $linkUrl;
		
	    }
	    
	}else {
	    
	    # the box isn't representing a GOID, e.g. annotating genes
	    
	    $barColor = $gd->grey;
	    
	}
	
    }else { 
	
	$barColor = $gd->grey;
	
    }
    
    
    my $onInfoText;
    
    if (( $self->{TOP_GOID} && $goid && $goid eq $self->{TOP_GOID}) ||
	(!$self->{TOP_GOID} && $goid && $goid eq $self->_goid)) {
	
	$self->_drawUpArrow($gd, $goid, ($x1+$x2)/2-7, 
			    ($x1+$x2)/2+7, $y1-15, 10, 
			    $linkUrl);
	
    }
    
    # now draw the box itself
    
    $gd->drawBar(barColor   => $barColor,
		 numX1      => $x1,
		 numX2      => $x2,
		 numY       => $y1,
		 linkUrl    => $linkUrl,
		 barHeight  => $boxH,
		 outline    => $outline,
		 onInfoText => $onInfoText);
	
    
    # and now add the label to the box, one line at a time
    
    my $i = 0;
    
    foreach my $label (@label) {
	
	# skip if it's a GOID or is blank
	
	next if (!$label || $label =~ /^GO:/i);
	
	if (!$goid) {
	    
	    $label =~ s/[0-9]+://i;
	    
	}
	
	my $nameColor = $gd->black;
	
	if (!$goid) {
	    
	    $nameColor = $gd->blue;
	    
	}elsif ($goid eq $self->_goid) {
	    
	    $nameColor = $gd->red;
	    
	}
	
	my $startPixel = int(($boxW - length($label)*6)/2);
	my $numX1 = $x1 + $startPixel;
	my $numY1 = $y1 + $i*10;
	
	if ($goid) {
	    
	    # the box we're labeling is for a goid
	    
	    $gd->drawName(name      => $label,
			  nameColor => $nameColor,  
			  numX1     => $numX1,
			  numY      => $numY1);
	    
	}else {
	    
	    # $numX1 -= 10;
	    
	    # we're adding in a list of genes
	    
	    my @gene = split(' ', $label);
	    
	    # add in each one - the image map being generated by
	    # the GO::View::GD object will have the relevant
	    # information added to support linking genes to it.

	    # go through each gene
	    
	    foreach my $gene(@gene) {
		
		my $linkUrl;
		
		if (!$self->{CREATE_IMAGE_ONLY} && $self->{GENE_URL}) {
		    
		    $linkUrl = $self->{GENE_URL};
		    
		    $linkUrl =~ s/$kReplacementText/$gene/;
		    
		}
		
		# add the gene name
		
		$gd->drawName(name      => $gene,
			      nameColor => $nameColor,
			      linkUrl   => $linkUrl,
			      numX1     => $numX1,
			      numY      => $numY1);
		
		$numX1 += (length($gene)+1)*6;
		
	    }
	    
	}
	
	$i++;
	
    }
    
    # I think this is supposed to say something about how many
    # genes are annotated to a given node, but am not sure that
    # $geneNum ever gets defined...
    
    if ($geneNum) {
	
	my $label = $geneNum." gene";
	
	if ($totalGeneNum != 1) {
	    
	    $label .= "s";
	    
	}
	
	my $startPixel = int(($boxW - length($label)*6)/2);
	
	my $numX1 = $x1 + $startPixel+2;
	
	my $numY1 = $y1 + $i*10+2;
	
	$gd->drawName(name      => $label,
		      nameColor => $gd->maroon,  
		      numX1     => $numX1,
		      numY      => $numY1);
	
    }
    
}

######################################################################
sub _drawEdge {
######################################################################
#
# =head2 _drawEdge
#
# Title   : _drawEdge
# Usage   : $self->_drawEdge($gd, $height, $border, $line);
#           automatically called by _createAndShowImage().
# Function: To draw each edge.
# Returns : void
#           
# =cut
#
#########################################################################

    my ($self, $gd, $height, $border, $line) = @_;

    # $line will contain something like:
    #
    # 342,324 320,360 325,351 331,341 337,332
    #
    # where each pair of coordinates defines a point on the line.
    # Thus to draw the line, we simply connect the points.

    my @point = split(/ /, $line);

    # get rid of everything prior to the first point
    
    my ($preX, $preY);

    # now go through each point

    foreach my $point (@point) {

	my ($x, $y) = split(/\,/, $point);

	# modify the x coorfinate to take account of the border and
	# scaling factor

	$x *= $self->{WIDTH_DISPLAY_RATIO};

	$x += $border;

	if (!defined $self->{MOVE_Y}) { $self->{MOVE_Y} = 0; }

	# modify the y coordinate based on the scaling factor, the border
	# the 'MOVE_Y' (whatever that is) and an arbitrary 5

	$y = $height - $y*$self->{HEIGHT_DISPLAY_RATIO} + $border +
	     $self->{MOVE_Y} + 5;

	# now if we have a prior x and y coordinate, we can draw a
	# line from it to the current point

	if ($preX && $preY) {

	    $gd->im->line($x, $y, $preX, $preY, $gd->black);

	}

	# remember these coordinates for the next time through the loop

	$preX = $x;

	$preY = $y;

    }

}

#################################################################
sub _drawUpArrow {
#################################################################
#
# =head2 _drawUpArrow
#
# Title   : _drawUpArrow
# Usage   : $self->_drawUpArrow($gd, $goid, $X1, $X2, $Y, $barHeight,
#                               $linkUrl);
#           automatically called by _drawNode().
# Function: To draw an up arrow on the tree map. 
# Returns : void
#           
# =cut
#
#########################################################################

    my ($self, $gd, $goid, $X1, $X2, $Y, $barHeight, 
	$linkUrl) = @_;

    my $node = $self->_ontologyProvider->nodeFromId($goid);

    my $maxGenerationUp = $node->lengthOfLongestPathToRoot;

    if ($maxGenerationUp <= 1) { return; } 

    if (!$self->{CREATE_IMAGE_ONLY} && $linkUrl) {
    
	$linkUrl .= "&tree=up";
    
    }

    $gd->drawBar(barColor  => $gd->blue,
		 numX1     => $X1,
		 numX2     => $X2,
		 numY      => $Y,
		 linkUrl   => $linkUrl,
		 barHeight => $barHeight,
		 outline   => 1,
		 arrow     => 'up');

}

######################################################################
sub _drawKeys {
######################################################################
#
# =head2 _drawKeys
#
# Title   : _drawKeys
# Usage   : $self->_drawKeys($gd, $mapWidth, $keyY, $isTop);
#           automatically called by _createAndShowImage().
# Function: To draw the display keys on the top or bottom of the tree map. 
# Returns : void
#           
# =cut
#
#########################################################################

    my ($self, $gd, $mapWidth, $keyY, $isTop) = @_;
    
    if (!$self->{GENE_NAME_HASH_REF_FOR_GOID}) {
	
	my $y = $keyY;
	
	my $boxH = 10;
	
	my $startX = 50;
	
	$gd->drawBar(barColor  => $gd->lightBlue,
		     numX1     => $startX,
		     numX2     => $startX + 20,
		     numY      => $y,
		     barHeight => $boxH);

	my $numX1 = $startX + 20;

	$gd->drawName(name      => " = GO term with child(ren)",
		      nameColor => $gd->black,  
		      numX1     => $numX1,
		      numY      => $y-2);

	$y += 15;

	$gd->drawBar(barColor  => $gd->grey,
		     numX1     => $startX,
		     numX2     => $startX + 20,
		     numY      => $y,
		     barHeight => $boxH);

	$gd->drawName(name      => " = GO term with no child(ren)",
		      nameColor => $gd->black,  
		      numX1     => $numX1,
		      numY      => $y-2);

	my $maxTextLen = int(($mapWidth-2*$startX)/6);

	my $text = $self->_processLabel($self->{MAP_NOTE}, $maxTextLen);

	my @geneNumExample = split(/\12/, $text);
	
	$y += 15;

	foreach my $text (@geneNumExample){

	    $text =~ s/^ *//;

	    $gd->drawName(name      => $text,
			  nameColor => $gd->black,  
			  numX1     => $startX,
			  numY      => $y-2);

	    $y += 15;

	}
 
	return;

    }

    my $y1 = $keyY;

    my $boxH = 15;

    my $boxW = 88;

    my $startX = 48 + ($mapWidth - $boxW*6 - 35 - 48)/2;
    
    my $twoLine;

    if ($startX < 48) {

	$startX = 48 + ($mapWidth - $boxW*3 - 15 - 48)/2;

	$twoLine = 1;

	if (!$isTop) { $y1 -= 10; }

    }

    ####### new code

    if ($isTop) {

	#$startX = 48;

    }

    $gd->drawName(name      => 'pvalue:',
		  nameColor => $gd->black,  
		  numX1     => 10,
		  numY      => $y1+1);
    
    my $i;
    my $preX2 = $startX;

    foreach my $name ('<=1e-10', '1e-10 to 1e-8', '1e-8 to 1e-6', 
			'1e-6 to 1e-4', '1e-4 to 1e-2', '>0.01') {
	
	$i++;

	my $pvalue = $name;

	$pvalue =~ s/^<=//;

	$pvalue =~ s/^>0.01/1/;

	$pvalue =~ s/^.+ to (.+)$/$1/;

	my $barColor = $self->_color4pvalue($gd, $pvalue);

	if ($i == 4 && $twoLine) {
	    $preX2 = $startX;
	    $y1 += 20;
	}

	my $x1 = $preX2 + 5; 

	my $x2 = $x1 + $boxW;

	$gd->drawBar(barColor  => $barColor,
		     numX1     => $x1,
		     numX2     => $x2,
		     numY      => $y1,
		     barHeight => $boxH);

	my $numX1 = $x1 + ($boxW-length($name)*6)/2;

        my $numY1 = $y1 + 2;

	$gd->drawName(name      => $name,
		      nameColor => $gd->black,  
		      numX1     => $numX1,
		      numY      => $numY1);

	$preX2 = $x2;

    }

}

######################################################################
sub _drawFrame {
######################################################################
#
# =head2 _drawFrame
#
# Title   : _drawFrame
# Usage   : $self->_drawFrame($gd, $width, $height);
#           automatically called by _createAndShowImage().
# Function: To draw a frame around the image map with date and label 
#           on the bottom corner. 
# Returns : void
#           
# =cut
#
#########################################################################

    my ($self, $gd, $width, $height) = @_;

    $gd->drawFrameWithLabelAndDate(width  => $width,
				   height => $height,
				   text   => $self->{IMAGE_LABEL});

}

################################################################
sub _createGraphObject {
################################################################
#
# =head2 _createGraphObject
#
# Title   : _createGraphObject
# Usage   : my $self->_createGraphObject();
#           automatically called by _createGraph().
# Function: Gets newly created empty GraphViz instance. 
# Returns : newly created empty GraphViz instance.
#           
# =cut
#
#########################################################################

    my ($self) = @_;

    my %args;

    if (defined $self->{MAKE_PS} && $self->{MAKE_PS}){

	%args = (width => 7.5,
		 height => 10,
		 pagewidth => 8.5, 
		 pageheight => 11.5);

    }

    $self->{GRAPH} = GraphViz->new(node => { shape => 'box',
					     style => 'filled' },
				   edge => { arrowhead => 'none' },

				   overlap => 'false',

				   %args);

}

################################################################
sub _addNode {
################################################################
#
# =head2 _addNode 
#
# Title   : _addNode 
# Usage   : $self->_addNode($goid);
#           automatically called by _createGraph().
# Function: Adds node to the GraphViz instance. 
# Returns : void
#           
# =cut
#
#########################################################################

    my ($self, $goid, %args) = @_;
    
    my $label;

    if ($goid !~ /^GO:[0-9]+$/) {

	# if the label is not a goid (i.e. it's a list of genes that
	# annotate a term), we'll process it, so that there are no
	# lines longer than 30 characters

	$label = $self->_processLabel($goid, 30);

    }else{

	# otherwise, we'll get the term for the goid
	
	$label = $self->{TERM_HASH_REF_FOR_GOID}->{$goid};
	
	if (!$label) {
	    
	    # if we didn't get a term, we'll go back to the
	    # ontologyProvider to get one
	    
	    my $node = $self->_ontologyProvider->nodeFromId($goid);
	    
	    $label = $node->term;
	    
	}
	
	# reformat the goid
	
	my $stdGoid;
	
	if (!$self->{PVALUE_HASH_REF_FOR_GOID}) {
	    
	    $stdGoid = $self->_formatGoid($goid);
	    
	}else {
	    
	    $stdGoid = $goid;
	    
	}
	
	# append the goid to the processed label
	
	if ($label) {
	    
	    $label = $self->_processLabel($label)."\n".$stdGoid;
	    
	}else { 
	    
	    $label = $stdGoid;
	    
	}

    }
   
    # now add the node to the graph, with the appropriate label
    
    $self->graph->add_node($goid,
			   label => $label,
			   %args);
  

}

################################################################
sub _addEdge {
################################################################
#
# =head2 _addEdge 
#
# Title   : _addEdge 
# Usage   : $self->_addEdge($parentGoid, $childGoid);
#           automatically called by _createGraph().
# Function: Adds edge to the GraphViz instance. 
# Returns : void
#           
# =cut
#
#########################################################################

    my ($self, $parentGoid, $childGoid) = @_;

    $self->graph->add_edge($parentGoid => $childGoid);

}

########################################################################
sub _descendantCount {
########################################################################
#
# =head2 _descendantCount
#
# Title   : _descendantCount
# Usage   : my $nodeCount = 
#                $self->_descendantCount($goid, $generationDown);
#           automatically called by _createGraph().
# Function: Gets total descendant node number down to a given generation. 
# Returns : The total descendant node number down to a given generation.
#           
# =cut
#
#########################################################################

    my ($self, $goid, $generationDown) = @_;

    my $node = $self->_ontologyProvider->nodeFromId($goid);

    my %descendantCount4generation;

    $self->_descendantCount4generation($node, \%descendantCount4generation); 

    my $nodeNum = 0;
    
    foreach my $generation (1..$generationDown) {

	$nodeNum += $descendantCount4generation{$generation};
	
    }

    return $nodeNum;
    
}

########################################################################
sub _setGeneration {
#######################################################################
#
# =head2 _setGeneration
#
# Title   : _setGeneration
# Usage   : $self->_setGeneration($goid);
#           automatically called by _createGraph().
# Function: Sets the maximum generation number it will display.
# Returns : void
#           
# =cut
#
#########################################################################

    my ($self, $goid) = @_;
 
    my $node = $self->_ontologyProvider->nodeFromId($goid);

    my %descendantCount4generation;

    $self->_descendantCount4generation($node, \%descendantCount4generation); 
    
    my $nodeNum = 0; 
    my $preNodeNum = 0;
    
    foreach my $generation (sort {$a<=>$b} (keys %descendantCount4generation)) {

	$nodeNum += $descendantCount4generation{$generation};

	if ($nodeNum == $self->{MAX_NODE}) { 

	    $self->{GENERATION} = $generation;

	    $self->{NODE_NUM} = $nodeNum;

	    last;

	}

	if ($nodeNum > $self->{MAX_NODE}) {

	    $self->{GENERATION} = $generation-1;

	    $self->{NODE_NUM} = $preNodeNum;

	    last;

	}
	
        $preNodeNum = $nodeNum;

    }

    if (!$self->{GENERATION} || $self->{GENERATION} < 1) { 

	$self->{GENERATION} = 1;

	if (!$node->childNodes) {

	    $self->{TREE_TYPE} = 'up';
 
	}

    }

}

########################################################################
sub _descendantCount4generation {
########################################################################
#
# =head2 _descendantCount4generation
#
# Title   : _descendantCount4generation
# Usage   : $self->_descendantCount4generation($node, 
#                                              $nodeCountHashRef,
#                                              $generation);
#           automatically called by _descendantCount(),
#                                   _setGeneration(), and itself.
# Function: Gets the descebdant count for each generation.
# Returns : void
#           
# =cut
#
#########################################################################

    my ($self, $node, $nodeCountHashRef, $generation) = @_;
    
    if (!$generation) { $generation = 1; }
    
    my @childNodes = $node->childNodes;

    $nodeCountHashRef->{$generation} += scalar(@childNodes);

    foreach my $childNode ($node->childNodes) {

	$self->_descendantCount4generation($childNode, 
					   $nodeCountHashRef, 
					   $generation++);

    }

}

################################################################
sub _setTopGoid {
################################################################
#
# =head2 _setTopGoid
#
# Title   : _setTopGoid
# Usage   : $self->_setTopGoid();
#           automatically called by _createGraph().
# Function: Sets the top ancestor goid. We want to display the 
#           tree up to this goid.  
# Returns : void
#           
# =cut
#
#########################################################################

    my ($self) = @_;

    my $node = $self->_ontologyProvider->nodeFromId($self->_goid);

    my $maxGenerationUp = $node->lengthOfLongestPathToRoot - 1;

    my @pathsToRoot = $node->pathsToRoot;

    my %count4goid;
    my %generation4goid;

    my $pathNum = scalar(@pathsToRoot);

    foreach my $path (@pathsToRoot) {

	my @nodeInPath = reverse(@{$path});

	my $generation = 0;

	foreach my $node (@nodeInPath) {

	    $count4goid{$node->goid}++;

	    $generation++;

	    if (!$generation4goid{$node->goid} || 
		$generation4goid{$node->goid} < $generation) {

		$generation4goid{$node->goid} = $generation;

	    }

	    if ( $pathNum == $count4goid{$node->goid} ) {
		### the same goid appears on all the paths.
		
		$self->{TOP_GOID} = $node->goid;
		
		$self->{GENERATION} = $generation4goid{$node->goid};

		last;

	    }
 
	}

    }

}

################################################################
sub _initGoidFromOntology {
################################################################
#
# =head2 _initGoidFromOntology
#
# Title   : _initGoidFromOntology
# Usage   : my $goid = $self->_initGoidFromOntology;
#           automatically called by _init().
# Function: Gets the top goid for the given ontology  
#           (biological_process, molecular_function, or 
#           cellular_component)
# Returns : goid
#           
# =cut
#
#########################################################################

    my ($self) = @_;

    # gene_ontology super node

    my $rootNode = $self->_ontologyProvider->rootNode;

    # node for molecular_function, biological_process, or 
    # cellular_component 

    my ($topNode) = $rootNode->childNodes;

    return $topNode->goid;

}

#######################################################################
sub _initPvaluesGeneNamesDescendantGoids {
#######################################################################
#
# =head2 _initPvaluesGeneNamesDescendantGoids
#
# Title   : _initPvaluesGeneNamesDescendantGoids
# Usage   : $self->_initPvaluesGeneNamesDescendantGoids;
#           automatically called by _init().
# Function: Sets $self->{PVALUE_HASH_REF_FOR_GOID}, 
#           $self->{GENE_NAME_HASH_REF_FOR_GOID},
#           and $self->{DESCENDANT_GOID_ARRAY_REF} 
# Returns : void
#           
# =cut
#
#########################################################################

# This method reads through all of the hypotheses that came from the
# TermFinder analysis, and records various information that is
# subsequently used to construct the image.

# TODO - naming of the $pvalue variable and _termFinder methods is
# very poor, and misleading.  This should be changed.
#
# TODO - currently, when we compare the maxTopNodeToShow, we shouldn't
# increment the count when a node that is being added is the parent or
# child of a node already on the graph.

    my ($self) = @_;
 
    my %foundGoid;
    my %foundGoidGene;

    my @directAnnotatedGoid;
    my %loci4goid;
    my %pvalue4goid;

    # $maxTopNodeToShow is used to limit the size of the output graph.
    # The default value (set during initialization is 6, but can be
    # modified via a user argument

    my $maxTopNodeToShow = $self->{MAX_TOP_NODE_TO_SHOW};

    my $count = 0;

    # go through each hypothesis

    foreach my $pvalue (@{$self->_termFinder}){

	# map the goid to the corrected p-value for later retrieval
	# when deciding on what color a node should have

	$pvalue4goid{$pvalue->{NODE}->goid} = $pvalue->{CORRECTED_PVALUE};

	# skip if it has a p-value worse than our threshold note

	next if ($pvalue->{CORRECTED_PVALUE} > $self->{PVALUE_CUTOFF});
        
	# skip if we've exceeded the maxTopNodeToShow value
	#
	# NB, we do 'next', rather than 'last', so that the mapping of the
	# goid to p-value still gets recorded for any subsequent nodes, which
	# ensures that their colors will be correct

	next if ($count >= $maxTopNodeToShow);

	# grab the GO::Node object for this hypothesis

	my $ancestorNode = $pvalue->{NODE};

	# now we go through the list of genes directly annotated to
	# this node and get every goid to which any of those genes are
	# annotated - thus we'll build up a list of all nodes to which
	# the genes are annotated.  We'll also record which nodes are
	# directly annotated by the genes

	foreach my $databaseId (keys %{$pvalue->{ANNOTATED_GENES}}) {

	    # get every goid that the gene maps to.

	    my $goidArrayRef = $self->_annotationProvider->goIdsByDatabaseId(databaseId => $databaseId,
									     aspect     => $self->{ASPECT});

	    # get the name of the gene, as it was passed to TermFinder

	    my $gene = $pvalue->{ANNOTATED_GENES}->{$databaseId};
	
	    # now go through each goid that the gene was annotated to

	    foreach my $goid (@{$goidArrayRef}) {

		# get a GO::Node object for it

		my $node = $self->_ontologyProvider->nodeFromId($goid);

		# the following check is probably superfluous, but
		# there may be cases where a node in the annotation
		# provider is not in the ontology provider, so we just
		# ignore them

		next if (!$node);

		# We only want to keep information about genes
		# directly annotated to this node if it is a
		# descendant of the '$ancestorNode', which we know
		# passes the p-value cut-off, or if it is the node
		# itself.  In this way, we only record nodes to which
		# our genes of interest are annotated if they have
		# contributed to the count associated with the
		# significant '$ancestorNode', and thus prune the
		# tree, as we don't show all nodes to which any of the
		# genes are annotated.

		next unless ($node->isADescendantOf($ancestorNode) || $goid eq $ancestorNode->goid);

		# now record some information about the this goid and the gene

		if (!exists $foundGoidGene{$goid."::".$gene}) {  

		    # record the genes in the list that are annotated
		    # to this node

		    $loci4goid{$goid} .= ":".$gene;

		    # and remember that we've recorded this annotation

		    $foundGoidGene{$goid."::".$gene}++;

		}

		# skip if we've already seen the goid

		next if ($foundGoid{$goid});

		# record the goid as directly annotated by a gene of interest

		push(@directAnnotatedGoid, $goid);
	    
		# and remember that we've seen it

		$foundGoid{$goid}++;

	    }

	}

	$count++; # keep a count of the number of nodes that exceed the cutoff
   
    }

    # now record all of our information within ourselves

    $self->{DESCENDANT_GOID_ARRAY_REF}   = \@directAnnotatedGoid;
    $self->{PVALUE_HASH_REF_FOR_GOID}    = \%pvalue4goid;
    $self->{GENE_NAME_HASH_REF_FOR_GOID} = \%loci4goid;

    # and return the number of top nodes recorded, which is used to
    # decide whether to print the graph or not.

    return $count;

}

##########################################################################
sub _initVariablesFromConfigFile {
##########################################################################
    my ($self, $configFile) = @_;

    my $fh = IO::File->new($configFile, q{<}) || die "Can't open '$configFile' for reading : $!";

    while(<$fh>) {

	chomp;

	# skip comments, blank, and whitespace only lines

	if (/^\#/ || /^\s*$/) { next; }
	
	my ($name, $value) = split(/=/);

	$value =~ s/^ *(.+) *$/$1/;
	
	if ($name =~ /^maxNode/i) {

	    $self->{MAX_NODE} = $value;

	}elsif ($name =~ /^maxNodeNameWidth/i) {

	    $self->{MAX_NODE_NAME_WIDTH} = $value;

	}elsif ($name =~ /^widthDisplayRatio/i) {

	    $self->{WIDTH_DISPLAY_RATIO} = $value;

	}elsif ($name =~ /^heightDisplayRatio/i) {

	    $self->{HEIGHT_DISPLAY_RATIO} = $value;

        }elsif ($name =~ /^minMapWidth\b/i) { # need the \b, as it is a substring of minMapWidth4OneLineKey

	    $self->{MIN_MAP_WIDTH} = $value;

	}elsif ($name =~ /^minMapHeight4TopKey/i) {

	    $self->{MIN_MAP_HEIGHT_FOR_TOP_KEY} = $value;

	}elsif ($name =~ /^minMapWidth4OneLineKey/i) {

	    $self->{MIN_MAP_WIDTH_FOR_ONE_LINE_KEY} = $value;

	}elsif ($name =~ /^mapNote/i) {

	    $self->{MAP_NOTE} = $value;
    
	}elsif ($name =~ /^binDir/i) {

	    $ENV{PATH} .= ":".$value;

	}elsif ($name =~ /^libDir/i) {

	    $ENV{LD_LIBRARY_PATH} .= ":".$value;

	}elsif ($name =~ /^makePs/i){

	     $self->{MAKE_PS} = $value;

	 }
    
    }

    $fh->close;

}

################################################################
sub _getBoxColor {
################################################################
#
# =head2 _getBoxColor
#
# Title   : _getBoxColor
# Usage   : my $boxColor = $self->_getBoxColor($gd, $goid);
#           automatically called by _drawNode().
# Function: Gets the color for the node box in the display.
# Returns : gd color
#           
# =cut
#
#########################################################################

    my ($self, $gd, $goid) = @_;
    
    if ($self->{PVALUE_HASH_REF_FOR_GOID} && 
	$self->{PVALUE_HASH_REF_FOR_GOID}->{$goid}) {

	return $self->_color4pvalue($gd, 
				    $self->{PVALUE_HASH_REF_FOR_GOID}->{$goid});
     
    }

    return $gd->tan;

}

################################################################
sub _color4pvalue {
################################################################
#
# =head2 _color4pvalue
#
# Title   : _color4pvalue
# Usage   : my $boxColor = $self->_color4pvalue($gd, $pvalue);
#           automatically called by _drawKeys() and _getBoxColor().
# Function: Gets the color for the node box in the display.
# Returns : gd color
#           
# =cut
#
#########################################################################

    my ($self, $gd, $pvalue) = @_;

    if ($pvalue <= 1e-10) {

	return $gd->orange; 

    }elsif ($pvalue <= 1e-8) {

	return $gd->yellow; 

    }elsif ($pvalue <= 1e-6) {

	return $gd->green4;

    }elsif ($pvalue <= 1e-4) {

	return $gd->lightBlue;

    }elsif ($pvalue <= 1e-2) {

	return $gd->blue4;

    }else {

	return $gd->tan;

    }

}

################################################################
sub _colorForNode{
################################################################

    my ($self, $goid) = @_;
    
    if ($self->{PVALUE_HASH_REF_FOR_GOID} && 
	$self->{PVALUE_HASH_REF_FOR_GOID}->{$goid}) {

	my $pvalue = $self->{PVALUE_HASH_REF_FOR_GOID}->{$goid};

	if ($pvalue <= 1e-10) {
	    
	    return 'orange'; 
	    
	}elsif ($pvalue <= 1e-8) {
	    
	    return 'yellow'; 
	    
	}elsif ($pvalue <= 1e-6) {
	    
	    return 'green';
	    
	}elsif ($pvalue <= 1e-4) {
	    
	    return 'cyan';
	    
	}elsif ($pvalue <= 1e-2) {
	    
	    return 'royalblue1';
	    
	}else {
	    
	    return 'burlywood2';
	    
	}

	
    }
    
    return 'burlywood2';
    
}

################################################################
sub _processLabel {
################################################################
#
# =head2 _processLabel
#
# Title   : _processLabel
# Usage   : my $newLabel = $self->_processLabel($label,
#                                               $maxLabelLen);
#           automatically called by _drawKeys() and _addNode().
# Function: Splits the label into multiple lines if the label is too 
#           long. 
# Returns : new label string
#           
# =cut
#
#########################################################################

    my ($self, $label, $maxLabelLen) = @_;
    
    if (!$maxLabelLen) { 

	$maxLabelLen = $self->{MAX_NODE_NAME_WIDTH} || 15;

    }

    # separate the label into its constituent words

    my @words = split(/ /, $label);

    my (@lines, $line);

    # go through each word

    foreach my $word (@words) {

	# if the line we're building up is too long already, or it'll
	# be too long when we add the next word, add it to the array
	# of lines, and start a new one

	if ((defined $line && length($line) >= $maxLabelLen) ||
	    (defined $line && (length($line)+length($word) > $maxLabelLen)) ) {

	    # get rid of leading space

	    $line =~ s/^ +//;

	    push (@lines, $line);

	    undef $line;

	}

	# add the current word onto the line

	$line .= " ".$word;

    }

    # add in a final line if there is one

    if (defined $line){

	$line =~ s/^ +//;

	push (@lines, $line);

    }

    return join("\n", @lines);

}

################################################################
sub _formatGoid {
################################################################
#
# =head2 _formatGoid
#
# Title   : _formatGoid
# Usage   : my $goid = $self->_formatGoid($goid); 
#           automatically called by _init() and _addNode().
# Function: Reformats the goid (plain number) to STD GOID format 
#           (GO:0000388)
# Returns : std GOID
#           
# =cut
#
#########################################################################

    my ($self, $goid) = @_;

    my $len = length($goid);

    for (my $i = 1; $i <= 7 - $len; $i++) {

	$goid = "0".$goid;

    }

    $goid = "GO:".$goid;

    return $goid;

}

#######################################################################
sub DESTROY {
#######################################################################

    # nothing needs to be done

}

#######################################################################
1;
#######################################################################

