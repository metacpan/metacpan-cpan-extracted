package GO::OntologyProvider::OntologyParser;

# File       : OntologyParser.pm
# Authors    : Elizabeth Boyle; Gavin Sherlock
# Date Begun : Summer 2001
# Rewritten  : September 29th 2002

# $Id: OntologyParser.pm,v 1.19 2007/03/18 03:11:19 sherlock Exp $

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

GO::OntologyProvider::OntologyParser - Provides API for retrieving data from Gene Ontology files

=head1 SYNOPSIS

    use GO::OntologyProvider::OntologyParser;

    my $ontology = GO::OntologyProvider::OntologyParser->new(ontologyFile => "process.ontology");

    print "The ancestors of GO:0006177 are:\n";

    my $node = $ontology->nodeFromId("GO:0006177");

    foreach my $ancestor ($node->ancestors){
    
        print $ancestor->goid, " ", $ancestor->term, "\n";
    
    }

    $ontology->printOntology();


=head1 DESCRIPTION

GO::OntologyProvider::OntologyParser implements the interface
defined by GO::OntologyProvider, and parses a gene ontology file
(GO) in plain text (not XML) format.  These files can be obtained from
the Gene Ontology Consortium web site, http://www.geneontology.org/.
From the information in the file, it creates a directed acyclic graph
(DAG) structure in memory.  This means that GO terms are arranged into
tree-like structures where each GO node can have multiple parent nodes
and multiple child nodes.

This data structure can be used in conjunction with files in which
certain genes are annotated to corresponding GO nodes.

Each GO ID (e.g. "GO:1234567") has associated with it a GO node.  That
GO node contains the name of the GO term, a list of the nodes directly
above the node ("parent nodes"), and a list of the nodes directly
below the current node ("child nodes").  The "ancestor nodes" of a
certain node are all of the nodes that are in a path from the current
node to the root of the ontology, with all repetitions removed.

The format of the GO file is as follows (taken from
http://www.geneontology.org/doc/GO.doc.html)

Comment lines: 

Lines that begin ! are comment lines. 

$ lines: 

Line in which the first non-space character is a $ either reflect the
domain and aspect of the ontology (i.e. $text) or the end of file
(i.e. the $ character on a line by itself).

Versioning: 

The first lines of each file after any html header information (in
*.html files) always carry information about the version, the date of
last update, (optionally) the source of the file, the name of the
database, the domain of the file and the editors of the file, e.g.:

!
!Gene Ontology
![domain of file]
!
!editors: Michael Ashburner (FlyBase), Midori Harris (GO), Judith Blake (MGD)
!Leonore Reiser (TAIR), Karen Christie (SGD) and colleagues
!with software by Suzanna Lewis (FlyBase Berkeley).

Syntax: 

Parent-child relationships between terms are represented by
indentation:

  parent_term
   child_term

Instance relationship: 


  %term0
   %term1 % term2


To be read as term1 being an instance of term0 and also an instance of
term2. Part of relationship:

  %term0
    %term1 < term2 < term3


To be read as term1 being an instance of term0 and also a part-of of
term2 and term3.

Line syntax (showing the order in which items appear on a line; *
indicates optional item):


< | % term [; db cross ref]* [; synonym:text]*  [ < | % term]*

=cut

##################################################################
##################################################################

use strict;
use warnings;
use diagnostics;

use IO::File;

use vars qw (@ISA $PACKAGE $VERSION);

use GO::OntologyProvider;
@ISA = qw (GO::OntologyProvider);

use GO::Node;

use Storable qw (nstore);

$VERSION = 0.15;
$PACKAGE = "GO::OntologyProvider::OntologyParser";

##################################################################
#
# CLASS ATTRIBUTES
#
##################################################################

# All the following class attributes are constants, that should be
# initialized here at compile time.

my $DEBUG = 0;

my $kFile           = $PACKAGE.'::__file';
my $kRootNode       = $PACKAGE.'::__rootNode';
my $kNodes          = $PACKAGE.'::__nodes';
my $kCurrentLineage = $PACKAGE.'::__currentLineage';
my $kSecondaryIds   = $PACKAGE.'::__secondaryIds';

##################################################################

# The constructor, and associated initialization methods

##################################################################
sub new{
##################################################################
# This is the constructor for an OntologyParser object.
#
# The constructor expects one of two arguments, either an
# 'ontologyFile' argument, or an 'objectFile' argument.  When
# instantiated with an ontologyFile argument, it expects it to
# correspond to an ontology file created by the GO consortium,
# according to their file format.  When instantiated with an
# objectFile argument, it expects to open a previously created
# ontologyParser object that has been serialized to disk.

#
#
# Usage :
#
#    my $ontology = GO::OntologyProvider::OntologyParser->new(ontologyFile=>$file);
#
#    my $ontology = GO::OntologyProvider::OntologyParser->new(objectFile=>$file);

    my ($class, %args) = @_;

    my $self;

    if (exists($args{'objectFile'})){

	$self = Storable::retrieve($args{'objectFile'})

    }elsif (exists($args{'ontologyFile'})){

	$self = {};
	
	bless $self, $class;
	
	$self->__setFile($args{'ontologyFile'});

	$self->__init;

    }
   
    return ($self);

}

############################################################################
sub __setFile{
############################################################################
# This private method simply stores the name of the file used for
# construction inside the object's hash

    my ($self, $file) = @_;

    if (!-e $file){

	die "$file does not exist";

    }elsif (-d $file){

	die "$file is a directory";

    }elsif (!-r $file){

	die "$file is not readable";

    }

    $self->{$kFile} = $file;

}

############################################################################
sub __file{
############################################################################
# This private method returns the name of the file used to construct the object

    return $_[0]->{$kFile};

}

############################################################################
sub __init{
############################################################################
# This method initializes the ontologyParser object, by parsing an ontology
# file, and storing the structures represented therein, in memory.

    my $self = shift;

    my $ontologyFh = IO::File->new($self->__file, q{<} )|| die "$PACKAGE can't open file ". $self->__file ." : $!";

    # go through the ontology one line at a time

    while (<$ontologyFh>){

	chomp;
	
	next if (/^\!/); # skip "!" comment lines

	$self->__processNode($_);
	
    }

    $ontologyFh->close || die "Can't close ". $self->__file ." : $!";

}

############################################################################
sub __processNode{
############################################################################
# This private method processes any line identified as a node (ie a
# non-comment line).  The general idea is that it needs three pieces of
# information about the line to deal with it:
#
# 1. The number of spaces at the beginning of the line, which indicate
#    its relationship to previous lines (nodes) in the file.
# 2. The name of the node.
# 3. Any GOIDs associated with the node.
#
# If it hasn't seen the node before (a node may appear many times in
# the file, if it has multiple parents) it will create a new node
# object, otherwise it will use the corresponding previously created
# node object.  It will then indicate in that node object the current
# parent, and lineage to the root.  It will also add the current node
# as a child of the present immediate parent in the lineage to the
# root.


    my ($self, $line) = @_;

    my $numSpaces = $self->__getNumSpaces($line) || 0;

    my ($nodeName, @goids) = $self->__getNodeInfoFromLine($line);

    my $node;
    
    if ($self->__nodeIsAlreadyCreated($goids[0])){

	$node = $self->nodeFromId($goids[0]);

    } else { # node has not already been created 

	# create node

	$node = GO::Node->new(goid => $goids[0],
			      term => $nodeName);

	# store it
	
	$self->{$kNodes}{$goids[0]} = $node;
	
	# # now hash any secondaries to the primary

	for (my $i=1; $i < @goids; $i++){

	    $self->{$kSecondaryIds}{$goids[$i]} = $goids[0];

	}

    }        

    # before we update the lineage, can we work out whether the last
    # node was a leaf, and thus for each parent, work out a path to a
    # leaf?  This will satisfy Shuai's needs to be able to look at
    # descendent paths, and avoid recursion.  It will however balloon
    # the required memory.

    # now add the current node to the lineage

    $self->__updateCurrentLineage($numSpaces, $node);        

    if ($numSpaces == 0){ # must be the root node

	$self->{$kRootNode} = $node;

    }else{

	# and add current path to root to the node

	my @path = @{$self->{$kCurrentLineage}};
	
	pop (@path); # remove current node from path;
	
	$node->addPathToRoot(@path);

	# create connections between current node and it parent

	my $currentParent = $self->__getCurrentParent();
    
	$node->addParentNodes($currentParent);

	$currentParent->addChildNodes($node);

    }

}

############################################################################
sub __getNumSpaces{
############################################################################
# This returns the number of spaces that occur at the beginning of a line.
############################################################################

    my ($self, $line) = @_;

    if ($line =~ /^( +)/){ # capture leading spaces

	return (length($1));

    }else{ # it must have been the top level node

	return 0;

    }

}

############################################################################
sub __getNodeInfoFromLine{
############################################################################
# This private method takes a line from an ontology file as an
# argument, and returns the term name, and any goids associated with
# that term name.  The primary goid will be the first goid returned in
# the list.  Because all multiple parent relationships should be in
# the file redundantly, such that relationships to additional parents
# are indicated through indentation, as well as additional information
# at the end of a line, this method simply ignores the additional
# relationships coded at the end of the line.  It only picks them up
# thruogh the repeated appearance of nodes under each of their
# parents.
#
# An example line would be:
#
# %deoxyribodipyrimidine photolyase ; GO:0003904 ; EC:4.1.99.3 % DNA photolyase ; GO:0003913
#
# Note that in addition to a database XRef for GO (the GOID) there may
# be database cross references to other databases (eg the EC number)
# 
# An example line with more than one GOID for a term is:
#
# %phospholipid transporter ; GO:0005548, GO:0008497 % lipid transporter ; GO:0005319
#
# Note that the GOIDs are separated by a comma.
#
# Usage:
#
#    my ($termName, @goids) = $self->__getNodeInfoFromLine($line);

    my ($self, $line) = @_;

    # strip off beginning of line, up to beginning of term name

    $line =~ s/^ +//;         # eliminate leading spaces
    $line =~ s/^(\$|\%|\<)//; # eliminate $, % and < characters

    # grab first two fields separated by " ; "

    # Note: $goids may contain extra junk at the end, if there are
    # additional parents, but no other DBXRefs

    my ($nodeName, $goids) = split(/ ; /, $line);

    # check that we can actually get some goids.  Added this in to
    # deal with when a broken file that appeared on the GO site, it
    # caused me to get email saying my code was broken...

    if (!defined $goids || $goids eq ""){

	die "There appears to be a problem with the ontology file.\n".
	    "No GOIDs could be extracted from line $. in ". $self->__file ."\n".
	    "The contents of that line in the file are :\n\n\'".$_[1]."\'\n\n".
	    "Please correct the ontology file and try again.\n\n";
	    
    }

    # get rid of anything following the goids, that pertains to secondary parents

    $goids =~ s/ (\<|\%).*//;

    # extract goids

    my @goids = split(/\, /, $goids);

    # remove \'s from nodeName

    $nodeName =~ s/\\//g;

    return ($nodeName, @goids);

}

############################################################################
sub __nodeIsAlreadyCreated{
############################################################################
# This private method returns a boolean to indicate whether a node has
# already been created for a given GO ID.


    return (exists($_[0]->{$kNodes}{$_[1]}));

}

############################################################################
sub __updateCurrentLineage{
############################################################################
# Based on the number of spaces before the node, the previous ancestors 
# that apply to this node also are determined. Cousins of the current node 
# are removed, and the current node is added to the lineage.
#
# So how does this work?
#
# Well, the number of spaces in front of an entry indicate how many
# ancestors it must have in a path to the root of the Ontology.  Thus,
# as we read through the file, the number of spaces will increase and
# decrease in front of entries.  The number of spaces may only ever
# increase by one, from one line to the next, but it may decrease by
# several, as we may jump up the ontology, as we finish deep in one
# branch, then go high up in another.  Because the number of spaces
# indicates the number of ancestors a term must have, we simply use an
# array, that holds those ancestors for the currently considered line.
# When we consider the node, we see how many ancestors it must have,
# by the number of spaces in front, then make the array have only that
# number of entries, by splicing any extra out.  We then push our node
# on the array.  In this fashion, the array will always hold the
# current path to the currently considered node.

    my ($self, $numSpaces, $newNode) = @_;

    # get rid of extra lineage elements that exist from the previously
    # considered line

    splice (@{$self->{$kCurrentLineage}}, $numSpaces);

    # and put new node onto end of lineage

    push (@{$self->{$kCurrentLineage}}, $newNode);

}

############################################################################
sub __getCurrentParent{
############################################################################
# This returns the current parent, which is the node at the
# second-to-last position of the currentLineage array, after the
# currentLineage array has been updated to consider the current node

    return ($_[0]->{$kCurrentLineage}[-2]);

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

This is the constructor for an OntologyParser object.  The constructor
expects one of two arguments, either an 'ontologyFile' argument, or an
'objectFile' argument.  When instantiated with an ontologyFile
argument, it expects it to correspond to an ontology file created by
the GO consortium, according to their file format.  When instantiated
with an objectFile argument, it expects to open a previously created
ontologyParser object that has been serialized to disk (see serializeToDisk).

Usage:

    my $ontology = GO::OntologyProvider::OntologyParser->new(ontologyFile => $ontologyFile);

    my $ontology = GO::OntologyProvider::OntologyParser->new(objectFile   => $objectFile);

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

=cut
