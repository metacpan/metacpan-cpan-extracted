package GO::OntologyProvider::OboParser;

# File       : OboParser.pm
# Authors    : Elizabeth Boyle; Gavin Sherlock
# Date Begun : Summer 2001
# Rewritten  : September 29th 2002
#
# Updated to parse the gene ontology info from the obo file.
# August 2006, Shuai Weng  
#
# $Id: OboParser.pm,v 1.4 2007/11/15 18:32:12 sherlock Exp $

# License information (the MIT license)

# Copyright (c) 2003 Gavin Sherlock; Stanford University

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

=pod

=head1 NAME

GO::OntologyProvider::OboParser - Provides API for retrieving data from Gene Ontology obo file.

=head1 SYNOPSIS

    use GO::OntologyProvider::OboParser;

    my $ontology = GO::OntologyProvider::OboParser->new(ontologyFile => "gene_ontology.obo",
                                                        aspect       => [P|F|C]);

    print "The ancestors of GO:0006177 are:\n";

    my $node = $ontology->nodeFromId("GO:0006177");

    foreach my $ancestor ($node->ancestors){
    
        print $ancestor->goid, " ", $ancestor->term, "\n";
    
    }

    $ontology->printOntology();


=head1 DESCRIPTION

GO::OntologyProvider::OboParser implements the interface defined by
GO::OntologyProvider, and parses the gene ontology obo file (GO) in
plain text (not XML) format.  These files can be obtained from the
Gene Ontology Consortium web site, http://www.geneontology.org/.  From
the information in the file, it creates a directed acyclic graph (DAG)
structure in memory.  This means that GO terms are arranged into
tree-like structures where each GO node can have multiple parent nodes
and multiple child nodes.  The file MUST be named with a .obo suffix.

This data structure can be used in conjunction with files in which
certain genes are annotated to corresponding GO nodes.

Each GO ID (e.g. "GO:1234567") has associated with it a GO node.  That
GO node contains the name of the GO term, a list of the nodes directly
above the node ("parent nodes"), and a list of the nodes directly
below the current node ("child nodes").  The "ancestor nodes" of a
certain node are all of the nodes that are in a path from the current
node to the root of the ontology, with all repetitions removed.

The example format is as follows:

[Term]
id: GO:0000006
name: high affinity zinc uptake transporter activity
namespace: molecular_function
def: "Catalysis of the reaction: Zn2+(out) = Zn2+(in), probably powered by proton motive force." [TC:2.A.5.1.1]
xref_analog: TC:2.A.5.1.1
is_a: GO:0005385 ! zinc ion transporter activity


[Term]
id: GO:0000005
name: ribosomal chaperone activity
namespace: molecular_function
def: "OBSOLETE. Assists in the correct assembly of ribosomes or ribosomal subunits in vivo, but is not a component of the assembled ribosome when performing its normal biological function." [GOC:jl, PMID:12150913]
comment: This term was made obsolete because it refers to a class of gene products and a biological process rather than a molecular
function. To update annotations, consider the molecular function term 'unfolded protein binding ; GO:0051082' and the biological process
term 'ribosome biogenesis and assembly ; GO:0042254' and its children.
is_obsolete: true

=cut

##################################################################
##################################################################

use strict;
use warnings;
use diagnostics;

use base qw (GO::OntologyProvider);
use GO::Node;
use Storable qw (nstore);

use IO::File;

our $VERSION = 0.01;
our $PACKAGE = "GO::OntologyProvider::OntologyOboParser";

##################################################################
#
# CLASS ATTRIBUTES
#
##################################################################

# All the following class attributes are constants, that should be
# initialized here at compile time.

my $DEBUG = 0;

my $kFile           = $PACKAGE.'::__file';
my $kAspect         = $PACKAGE.'::__aspect';
my $kRootNode       = $PACKAGE.'::__rootNode';
my $kNodes          = $PACKAGE.'::__nodes';
my $kSecondaryIds   = $PACKAGE.'::__secondaryIds';
my $kParent         = $PACKAGE.'::__parent';

my %kAspects = (
		'P' => 'biological_process',
		'F' => 'molecular_function',
		'C' => 'cellular_component'
		);

##################################################################

# The constructor, and associated initialization methods

##################################################################
sub new{
##################################################################
# This is the constructor for an OntologyOboParser object.
#
# The constructor expects one of two type of arguments, either an
# 'ontologyFile' and 'ontology' argument , or an 'objectFile' argument.  
# When instantiated with an ontologyFile argument, it expects the file
# to be in obo format. When instantiated with an objectFile argument, 
# it expects to open a previously created OboParser object that 
# has been serialized to disk.
#
#
# Usage :
#
#    my $ontology = GO::OntologyProvider::OboParser->new(ontologyFile=>$file,
#                                                        ontology=>[P|F|C]); 
#
#    my $ontology = GO::OntologyProvider::OboParser->new(objectFile=>$file);
#

    my ($class, %args) = @_;

    my $self;

    if (exists($args{'objectFile'})){

	$self = Storable::retrieve($args{'objectFile'})

    }elsif (exists($args{'ontologyFile'})){

	$self = {};
	
	bless $self, $class;
	
	$self->__setFile($args{'ontologyFile'},
			 $args{'aspect'});

	$self->__init;

    }
   
    return ($self);

}

############################################################################
sub __setFile{
############################################################################
# This private method simply stores the name of the file used for
# construction inside the object's hash

    my ($self, $file, $aspect) = @_;

    if (!-e $file){

	die "$file does not exist";

    }elsif (-d $file){

	die "$file is a directory";

    }elsif (!-r $file){

	die "$file is not readable";

    }elsif ($file !~ /\.obo/){

	die "$file must have a .obo suffix";

    }

    if (!defined $aspect) {

	die "You have to pass the GO aspect [".join("\|", sort keys %kAspects) ."] to the ", ref($self);

    }
    
    if (!exists $kAspects{$aspect}) {

	die "Unknown aspect name: $aspect. The allowable GO aspects are ". join(", ", sort keys %kAspects)."\n";

    }

    $self->{$kFile} = $file;

    $self->{$kAspect} = $aspect;

}

############################################################################
sub __file {
############################################################################
# This private method returns the name of the file used to construct the object

    return $_[0]->{$kFile};

}

############################################################################
sub __aspect {
############################################################################
# This private method returns the name of the ontology used to construct the object

    return $_[0]->{$kAspect};

}

############################################################################
sub __init { # okay
############################################################################
# This method initializes the ontologyOboParser object, by parsing an ontology
# file, and storing the structures represented therein, in memory.

    my $self = shift;

    my $ontologyFh = IO::File->new($self->__file, q{<} )|| die "$PACKAGE can't open file ". $self->__file ." : $!";

    my $aspect = $kAspects{$self->__aspect};

    # go through the ontology one line at a time

    my @entryLine;

    my $isValidEntry = 0;

    my $namespace;

    while (<$ontologyFh>){

	chomp;

	# finish parsing the obo file of we reach the typedef line.

	last if (/^\[Typedef\]/);       

	if ($_ eq '[Term]') {

	    # we reached a new term - so process the previous entry

	    if ($isValidEntry) {
	   
		$self->__processNode(\@entryLine);

	    }

	    # reset our variables

	    @entryLine = ();

	    $isValidEntry = 0;
	    $namespace    = '';

	}elsif ($_ eq "namespace: $aspect"){

	    # term is in the requested namespace

	    $namespace = $aspect;

	    $isValidEntry = 1;
	
	}elsif ($_ eq 'is_obsolete: true'){

	    # we don't want obsolete nodes - DO NOT COMMENT THIS OUT -
	    # infinite recursion will result!

	    # Note, the logic here relies on the is_obsolete line coming after the
	    # namespace line.

	    $isValidEntry = 0;
		
	}else {

	    # build up the information for this node

	    push(@entryLine, $_);

	}

    }

    # process the final node

    if ($namespace eq $aspect && $isValidEntry) {
    
	$self->__processNode(\@entryLine);

    }

    $ontologyFh->close || die "Can't close ". $self->__file ." : $!";

    # now populate ancestor paths for each node.

    $self->__populatePaths;

}

############################################################################
sub __processNode{
############################################################################
# This private method processes entry lines identified as a node.  
# The general idea is that it needs three pieces of
# information about the line to deal with it:
#
# 1. The name of the node.
# 2. The GOIDs associated with the node.
# 3. The parent node ids.
#
# It creates a node object for the current node and then indicates in that node 
# the identity of its parent(s).

    my ($self, $entryLineArrayRef) = @_;

    my ($nodeName, $goid, $secondaryGoidArrayRef, $parentGoidArrayRef)
	= $self->__getNodeInfoFromLine($entryLineArrayRef);

    my $node = $self->__createNode($goid, $nodeName);

    if (scalar (@{$parentGoidArrayRef}) == 0) { # no parent goid

	# The GOA has obsoleted the 'Gene_Ontology' term, but
	# currently we need it to make the graph work.  Thus, we'll
	# recreate the root, using it.s original id and name.  This
	# needs to be fixed in future.

	my $rootGoid = 'GO:0003673';
	my $rootTerm = 'Gene_Ontology';

	my $rootNode = $self->__createNode($rootGoid, $rootTerm);

	$self->{$kRootNode} = $rootNode;

	@{$parentGoidArrayRef} = ($rootGoid);

    }

    ## now hash any secondaries to the primary

    foreach my $secondaryId (@{$secondaryGoidArrayRef}){

	$self->{$kSecondaryIds}{$secondaryId} = $goid;

    }        

    $self->{$kParent}{$goid} = $parentGoidArrayRef;

}

############################################################################
sub __getNodeInfoFromLine { # okay
############################################################################

# This private method takes an array reference to the lines for a
# given GO term node entry and returns the term name, a reference
# that points to an array of goids associated with that term name, and
# a reference that points to an array of direct parent GOIDs.  The
# primary goid will be the first goid returned in the list.
#
# Usage:
#
#    my ($termName, $goidArrayRef, $parentGoidArrayRef) 
#	= $self->__getNodeInfoFromLine($entryLineArrayRef);

    my ($self, $entryLineArrayRef) = @_;

    my ($nodeName, $goid, @secondaryGoid, @parentGoid);

    foreach my $line (@{$entryLineArrayRef}) {

	if ($line =~ /^id: *(GO:0*[0-9]+)$/) {

	    $goid =  $1;

	}elsif ($line =~ /^name: *(.+)$/) {

	    $nodeName = $1;

	}elsif ($line =~ /^alt_id: *(GO:0*[0-9]+)$/) {
	    
	    push(@secondaryGoid, $1);

	}elsif ($line =~ /^(is_a:|relationship: part_of) *(GO:0*[0-9]+)/) {	    
	
            push(@parentGoid, $2);

	}
	    
    }

    # check that we can actually get some goids.  Added this in to
    # deal with when a broken file that appeared on the GO site, it
    # caused me to get email saying my code was broken...

    if (!$goid){

	die "There appears to be a problem with the ontology file.\n".
	    "No GOIDs could be extracted from '$nodeName'.n\n";
	    
    }

    # remove \'s from nodeName

    $nodeName =~ s/\\//g;

    return ($nodeName, $goid, \@secondaryGoid, \@parentGoid);


}

###############################################################################
sub __createNode {
###############################################################################
    
    my ($self, $goid, $nodeName) = @_;

    my $node;

    if ($self->__nodeIsAlreadyCreated($goid)){

	$node = $self->nodeFromId($goid);

    } else { # node has not already been created 

	# create node

	$node = GO::Node->new(goid => $goid,
			      term => $nodeName);

	# store it
	
	$self->{$kNodes}{$goid} = $node;

    }

    return $node;

}

###############################################################################
sub __populatePaths {
###############################################################################
# in this method, we populate all the paths to the root for each node
# in the ontology.  To do this, we have to call the recursive method,
# __findAncestor(), which will build up each path from a node to the
# root, and when it reaches the end of the path (the root itself),
# will add that path via the Node method addPathToRoot.

# POSSIBLE ALTERNATIVE APPROACH
#
# Profiling of the OboParser reveals that when building the ontology,
# ~77% of the time is spent in the recursive __findAncestor().  Thus,
# if a way could be found to decrease the number of recursive calls to
# that method, it might significantly positively impact the runtime
# performance.
#
# A possible alternative approach to the current method, might be to
# simply populate paths for every leaf node (we would need to know who
# they are), and as their paths are populated, also populate the paths
# for their ancestors as well, as the paths from the ancestors are
# subparts of the paths from leaves to the root.  However, care would
# have to be taken to not add the same path twice, as there would be
# issues with when a leaf has two or more paths to a particular node,
# whose paths are then being added.  Note also, if you encounter a
# node for whom you have already added paths, you don't need to add
# them again, so this might significantly save the number of recursive
# calls required.

    my $self = shift;

    # go through each GO node in the $kParent hash, the keys of which
    # are the goids that are parents of a given node.

    foreach my $childGoid ( keys %{$self->{$kParent}} ) {

	# note, we directly access the kNodes hash here, rather than
	# use nodeFromId().  This is for performance reasons only -
	# accessing the kNodes hash directly in this method, and the
	# __findAncestor method shaces about 40% of the runtime off of
	# the time taken to populate all the paths.

	my $childNode =  $self->{$kNodes}{$childGoid};

	# now go through each of this child's parents

	foreach my $parentGoid (@{$self->{$kParent}{$childGoid}}) {

	    ### Note, there has been a case in the obo file where
	    ### there was an error, and a node was listed as having
	    ### parent in a different aspect.  This results in a fatal
	    ### run time error, as when the parser reads the file, it
	    ### only keeps nodes of a given aspect, and is thus left
	    ### with a dangling reference.  In this case, parentNode
	    ### will be undef, and the call to addParentNodes ends up
	    ### in a run time error.  We can add some logic here to
	    ### give a better error message.

	    my $parentNode = $self->{$kNodes}{$parentGoid} 

	    || do { 

		print "There is an error in the obo file, where the relationship between ",
		$childNode->goid,
		" and one or more of its parents is not correctly defined.\n",
		"Please check the obo file.\n",
		"The program is unable to continue.\n\n";
		
		exit;

	    };

	    ### create connections between child node and its parent	    

	    $childNode->addParentNodes($parentNode);
  
	    $parentNode->addChildNodes($childNode);

	    # begin to build the ancestor path, starting with this
	    # parent

	    my @path = ($parentNode);

	    if (exists $self->{$kParent}{$parentGoid}){

		# if this parent has parents, then we continue to
		# build the path upwards to the root.  We pass in the
		# child node, so that each path which reaches the root
		# can be added during the recursive calls to find
		# ancestor

		$self->__findAncestors($childNode,
				       $parentGoid,
				       \@path); 

	    }else{

		# otherwise, the path only contains the root, and we add it.

		$childNode->addPathToRoot(@path);

	    }

	}

    }

}

#######################################################################  
sub __findAncestors { 
#######################################################################  
# Usage:
#
#    $self->__findAncestor($childNode,
#                          $parentGoid, 
#                          $pathArrayRef);
#
# This method looks through each goid in hash %{$self->{$kParent}} to
# find all ancestors and push everything to @{$pathArrayRef}..And if
# there is no ancestor found for the $parentGoid, it just add the path
# to the child node.

    my ($self, $childNode, $parentGoid, $pathArrayRef) = @_;

    # go through each immediate parent of the passed in parent 

    foreach my $ancestorGoid (@{$self->{$kParent}{$parentGoid}}) {

	# add the ancestor node to our path to the root which is being
	# built

	push (@{$pathArrayRef}, $self->{$kNodes}{$ancestorGoid});

	if (exists $self->{$kParent}{$ancestorGoid}){

	    # if this ancestor has parents, continue building the
	    # paths to the root recursively up the DAG

	    $self->__findAncestors($childNode,
				   $ancestorGoid, 
				   $pathArrayRef);

	}else {

	    $childNode->addPathToRoot(reverse @{$pathArrayRef});

	}

	# because there are multiple paths to the root for most nodes,
	# we have now remove the current ancestor from this time
	# through the loop so that the path is reset to the original
	# condition that it was in when passed in to this method

	pop @{$pathArrayRef};

    }

}

############################################################################
sub __nodeIsAlreadyCreated { # okay
############################################################################
# This private method returns a boolean to indicate whether a node has
# already been created for a given GO ID.


    return (exists($_[0]->{$kNodes}{$_[1]}));

}

############################################################################
sub printOntology{
############################################################################
# This prints out the ontology, with redundancies.

    my $self = shift;

    $self->__printNode($self->rootNode, 0);

}

############################################################################
sub __printNode{
############################################################################
# This recursive function prints the name of the specified node and the 
# names of all of its descendants.
#

    my ($self, $node, $indentationLevel) = @_;

    print " " x $indentationLevel, $node->term, " ; ", $node->goid, "\n";

    foreach my $childNode (sort {$a->term cmp $b->term} $node->childNodes) {

	$self->__printNode($childNode, $indentationLevel+1);

    }

}

############################################################################
sub allNodes{
############################################################################
# This method returns an array of all the nodes that have been created.
#
# Usage:
#
#    my @nodes = $ontologyParser->allNodes;

    return (values %{$_[0]->{$kNodes}});

}   

############################################################################
sub rootNode{
############################################################################
# This returns the root node in the ontology.
#
# Usage:
#
#    my $rootNode = $ontologyParser->rootNode;

    return ($_[0]->{$kRootNode});

}

############################################################################
sub nodeFromId{
############################################################################
# This public method takes a GOID and returns the GO::Node that
# it corresponds to.  It should also work with secondary id's
#
# Usage :
#
#    my $node = $ontologyParser->nodeFromId($goid);

    my ($self, $goid) = @_;

    if (exists ($self->{$kNodes}{$goid})){ # it's a primary

	return ($self->{$kNodes}{$goid});
	
    }elsif (exists ($self->{$kSecondaryIds}{$goid})){ # it's a secondary

	return $self->{$kNodes}{$self->{$kSecondaryIds}{$goid}};

    }else{

	return undef;

    }

}

############################################################################
sub numNodes{
############################################################################
# This public method returns the number of nodes that exist with the
# ontology
#
# Usage :
#
#    my $numNodes = $ontologyParser->numNodes;

    return scalar (keys %{$_[0]->{$kNodes}});

}

############################################################################
sub serializeToDisk {
############################################################################
# Saves the current state of the Ontology Parser Object to a file,
# using the Storable package.  Saves in network order for portability,
# just in case.  Returns the name of the file.  If no filename is
# provided, then the name of the file (and it's directory, if one was
# provided) used for object construction, will be used, with .obj
# appended.  If the object was instantiated from a file with a .obj
# suffix, then the same filename would be used, if none were provided.
#
# This method currently causes a segfault on MacOSX (at least 10.1.5
# -> 10.2.3), with perl 5.6, and Storable 1.0.14, when trying to store
# the process ontology.  This failure occurs using either store, or
# nstore, and is manifested by a segmentation fault.  It has not been
# investigated whether this is a perl problem, or a Storable problem
# (which has large amounts of C-code).  This does not cause a
# segmentation on Solaris, using perl 5.6.1 and Storable 1.0.13.  This
# doesn't make it clear whether it's a MacOSX problem or a perl
# problem or not.  It should be noted that newer versions of both perl
# and Storable exist, and the code should be tested with those as
# well.
#
# Usage:
#
#    my $objectFile = $ontologyParser->serializeToDisk(filename=>$filename);

    my ($self, %args) = @_;

    my $fileName;

    if (exists ($args{'filename'})){ # they supply their own filename

	$fileName = $args{'filename'};

    }else{ # we build a name from the file used to instantiate ourselves

	$fileName = $self->__file;
	
	if ($fileName !~ /\.obj$/){ # if we weren't instantiated from an object
	    
	    $fileName .= ".obj"; # add a .obj suffix to the name
	    
	}

    }

    nstore ($self, $fileName) || die "$PACKAGE could not serialize itself to $fileName : $!";

    return ($fileName);

}

1; # to keep perl happy


# P O D   D O C U M E N T A T I O N #

=pod

=head1 Instance Constructor

=head2 new

This is the constructor for an OboParser object.  The constructor
expects one of two arguments, either an 'ontologyFile' argument, or an
'objectFile' argument.  When instantiated with an ontologyFile
argument, it expects it to correspond to an obo file created by the GO
consortium, according to their file format, and in addition, also
requires an 'aspect' argument.  When instantiated with an objectFile
argument, it expects to open a previously created ontologyParser
object that has been serialized to disk (see serializeToDisk).

Usage:

    my $ontology = GO::OntologyProvider::OboParser->new(ontologyFile => $ontologyFile,
                                                        aspect       => $aspect);

    my $ontology = GO::OntologyProvider::OboParser->new(objectFile   => $objectFile);

=head1 Instance Methods

=head2 printOntology

This prints out the ontology, with redundancies, to STDOUT.  It does
not yet print out all of the ontology information (like relationship
type etc).  This method will be likely be removed in a future version,
so should not be relied upon.

Usage:

    $ontologyParser->printOntology;

=head2 allNodes

This method returns an array of all the GO:Nodes that have been
created.

Usage:

    my @nodes = $ontologyParser->allNodes;

=head2 rootNode

This returns the root node in the ontology.

    my $rootNode = $ontologyParser->rootNode;

=head2 nodeFromId

This public method takes a GOID and returns the GO::Node that
it corresponds to.

Usage :

    my $node = $ontologyParser->nodeFromId($goid);

If the GOID does not correspond to a GO node, then undef will be
returned.  Note if you try to call any methods on an undef, you will
get a fatal runtime error, so if you can't guarantee all GOIDs that
you supply are good, you should check that the return value from this
method is defined.

=head2 numNodes

This public method returns the number of nodes that exist with the
ontology

Usage :

    my $numNodes = $ontologyParser->numNodes;

=head2 serializeToDisk

Saves the current state of the Ontology Parser Object to a file, using
the Storable package.  Saves in network order for portability, just in
case.  Returns the name of the file.  If no filename is provided, then
the name of the file (and its directory, if one was provided) used for
object construction, will be used, with .obj appended.  If the object
was instantiated from a file with a .obj suffix, then the same
filename would be used, if none were provided.

This method currently causes a segfault on MacOSX (at least 10.1.5 ->
10.2.3), with perl 5.6, and Storable 1.0.14, when trying to store the
process ontology.  This failure occurs using either store, or nstore,
and is manifested by a segmentation fault.  It has not been
investigated whether this is a perl problem, or a Storable problem
(which has large amounts of C-code).  This does not cause a
segmentation on Solaris, using perl 5.6.1 and Storable 1.0.13.  This
does not make it clear whether it is a MacOSX problem or a perl
problem or not.  It should be noted that newer versions of both perl
and Storable exist, and the code should be tested with those as well.

Usage: 

    my $objectFile = $ontologyParser->serializeToDisk(filename=>$filename);

=head1 Authors

    Gavin Sherlock; sherlock@genome.stanford.edu
    Elizabeth Boyle; ell@mit.edu
    Shuai Weng; shuai@genome.stanford.edu

=cut
