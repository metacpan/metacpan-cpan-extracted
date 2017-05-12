package GO::Node;

# File        : Node.pm
# Author      : Gavin Sherlock
# Date Begun  : December 23rd 2002

# $Id: Node.pm,v 1.11 2007/03/18 02:54:46 sherlock Exp $ 

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

GO::Node - provides information about a node in the Gene Ontology

=head1 DESCRIPTION

The GO::Node package is intended to be used as a container for
information about a node in one of the three Gene Ontologies.  It
allows the storage of the goid, and immediate parents and children, as
well as paths to the top of the ontology.  This package provides
methods to both store and retrieve that information.

It should be strongly noted that clients are not expected to create
individual Node objects themselves, but instead should rely in a Node
Factory to create nodes and return them.  Such a factory would be a
concrete subclass of the abstract GO::OntologyProvider package.

=head1 TODO

The following items needs to be done at some point to make the Node
class more flexible, and for it to better model the data.

    Add in methods to deal with secondary GOIDs

    Add in methods to allow definitions to be associated with, and
    retrieved from Nodes.

    Add in methods to allow dbxrefs to be included.

    Not require Factories to add the paths to the root, but instead
    have this class generate those paths from the inherent structure
    of the graph in which the Nodes sit.  This will also be useful to
    generate paths to leaves/descendants.

=cut

use strict;
use warnings;
use diagnostics;

use vars qw ($PACKAGE $VERSION);

$VERSION = 0.16;
$PACKAGE = "GO::Node";

# CLASS CONSTANTS

my $kGoid = $PACKAGE.'::__goid';
my $kTerm = $PACKAGE.'::__term';

my $kParents   = $PACKAGE.'::__parents';
my $kChildren  = $PACKAGE.'::__children';
my $kPaths     = $PACKAGE.'::__paths';
my $kAncestors = $PACKAGE.'::__ancestors';


##################################################################

# The constructor, and associated initialization methods

##################################################################
sub new{
##################################################################
# This is the constructor for the Node object
#
# At a minimum, the constructor expects, as named arguments, a GOID
# and a GO term, with which to create the node object.
#
# Usage:
#
#    my $node = GO::Node->new(goid => $goid,
#                             term => $term);

    my ($class, %args) = @_;

    my $self = {};

    bless $self, $class;

    if (!exists ($args{'goid'}) || !defined ($args{'goid'})){

	$self->_handleMissingArgument(argument=>'goid');

    }elsif (!exists ($args{'term'}) || !defined ($args{'term'})){

	$self->_handleMissingArgument(argument=>'term');

    }

    $self->{$kGoid}  = $args{'goid'};
    $self->{$kTerm}  = $args{'term'};

    $self->{$kPaths} = [];

    return $self;

}

##################################################################
#
# PUBLIC SETTER METHODS
#
##################################################################

##################################################################
sub addChildNodes{
##################################################################
# The public setter method allows a client to indicate that an array
# of nodes are children of the 'self' node.  Only one node per child
# goid will get stored.
#
# Usage:
#
#    $node->addChildNodes(@childNodes);

    my $self = shift;

    foreach my $node (@_){

	# store children as a hash, with the goid as the key and the
	# node itself as the value

	$self->{$kChildren}{$node->goid} = $node;

    }

}

##################################################################
sub addParentNodes{
##################################################################
# The public setter method allows a client to indicate that an array
# of nodes are parents of the 'self' node.  Only one node per parent
# goid will get stored.
#
# Usage:
#
#    $node->addParentNodes(@parentNodes);

    my $self = shift;

    foreach my $node (@_){

	# store parents as a hash, with the goid as the key and the
	# node itself as the value

	$self->{$kParents}{$node->goid} = $node;

    }

}

##################################################################
sub addPathToRoot{
##################################################################

# This public setter method expects an array of nodes, that indicates
# a direct path to the root of the ontology.  The array should not
# contain the self node, but should contain the root node.  The last
# entry in the array is expected to be an immediate parent of the self
# node, while the first entry is expected to be the root node itself.
# This method will NOT check to see if the supplied path has not
# already been added.  It is the Node Factory's responsibility to only
# add a unique path once.  Furthermore, it will not check whether
# there is consistency between addedPaths and addedParents (this can
# be done using the isValid method though).

#
# Usage:
#
#    $node->addPathToRoot(@nodes);
#

    my ($self, @nodes) = @_;

    push (@{$self->{$kPaths}}, \@nodes);

}

##################################################################
#
# PUBLIC ACCESSSOR METHODS
#
##################################################################

##################################################################
sub goid{
##################################################################
# This public method returns the goid associated with the node.
#
# Usage:
#
#    my $goid = $node->goid;

    return $_[0]->{$kGoid};

}

##################################################################
sub term{
##################################################################
# This public method returns the term associated with the node.
#
# Usage:
#
#    my $goid = $node->term;

    return $_[0]->{$kTerm};

}

##################################################################
sub childNodes{
##################################################################
# This public method returns an array of child nodes for the self
# node.
#
# Usage:
#
#    my @childNodes = $node->childNodes;

    return (values %{$_[0]->{$kChildren}});

}

##################################################################
sub parentNodes{
##################################################################
# This public method returns an array of parent nodes for the self
# node.
#
# Usage:
#
#    my @parentNodes = $node->parentNodes;

    return (values %{$_[0]->{$kParents}});

}

##################################################################
sub pathsToRoot{
##################################################################
# This public method returns an array of references to arrays, each of
# which contains the nodes in a path between the self node and the
# root.  The self node is not included in the paths, but the root node
# is.  The first node in each array is the most distant ancestor (the
# root), the last node is an immediate parent.  If there are no paths
# to the root (i.e. it is the root node) then an empty array will be
# returned.
#
# Usage:
#
#    my @pathsToRoot = $node->pathsToRoot;

    return (@{$_[0]->{$kPaths}});

}

##################################################################
sub pathsToAncestor{
##################################################################
# This public method returns an array of references to arrays, each of
# which contains the nodes in a path between the self node and the
# specified ancestor.  The self node is not included paths, but the
# specified ancestor node is.  The first node in each array is the
# specified ancestor, the last node is an immediate parent.  If there
# are no paths to the ancestor then an empty array will be returned.
#
# Usage:
#
#    my @pathsToAncestor = $node->pathsToAncestor($ancestorNode);

    my ($self, $ancestor) = @_;

    return () if (!$self->isADescendantOf($ancestor)); # NOTE early return

    my @paths;
    
    foreach my $path ($self->pathsToRoot){ # examine paths to root	

	foreach (my $j = 0; $j< @{$path}; $j++){

	    if ($path->[$j] == $ancestor){ # if it's the node we want

		# we want the array from this point to the end
		
		push (@paths, [@{$path}[$j..@{$path}-1]]); # array slice
		      
		last; # no need to look further

	    }

	}

    }

    # now we have to unique the paths, as there may be some redundancy
    # should check cookbook to see if there's a better way to do this    

    my (%duplicates, @uniquePaths);

    foreach (my $i = 0; $i < @paths - 1 ; $i++){

	next if exists $duplicates{$i};

      INNER:

	foreach (my $j = $i+1; $j < @paths; $j++){

	    next if exists $duplicates{$j};

	    # can't be the same if different sizes

	    next INNER if scalar @{$paths[$i]} != scalar @{$paths[$j]};

	    # now compare each member of the arrays

	    for (my $k = 0; $k < @{$paths[$i]}; $k++){

		# can't be the same if any two members are different

		next INNER if $paths[$i][$k] != $paths[$j][$k];

	    }

	    # if we get here, path j must be the same as i

	    $duplicates{$j} = undef; # so we'll eliminate it from future consideration

	}

    }

    for (my $i = 0; $i < @paths; $i++){

	next if exists $duplicates{$i};

	push (@uniquePaths, $paths[$i]);

    }    

    return @uniquePaths;

}

##################################################################
sub ancestors{
##################################################################
# This public method returns an array of unique GO::Nodes which
# are the unique ancestors that a node has.  These ancestors will be
# derived from the paths to the root node that have been added to the
# node.

    my $self = shift;

    if (!exists $self->{$kAncestors}){

	my %ancestors;
	
	foreach my $path ($self->pathsToRoot){
	    
	    foreach my $node (@{$path}){
		
		$ancestors{$node->goid} = $node;
		
	    }
	    
	}

	$self->{$kAncestors} = \%ancestors;

    }

    return (values %{$self->{$kAncestors}});

}

##################################################################
sub lengthOfLongestPathToRoot{
##################################################################
# This public method returns the length of the longest path to the
# root of the ontology from the node.  If the node is in fact the root,
# then a value of zero will be returned.
#
# Usage:
#
#    my $length = $node->lengthOfLongestPathToRoot;

    my $self = shift;

    my $maxLength = 0;

    foreach my $path ($self->pathsToRoot){

	$maxLength = scalar (@{$path}) if (scalar (@{$path}) > $maxLength);

    }

    return $maxLength;

}

##################################################################
sub lengthOfShortestPathToRoot{
##################################################################
# This public method returns the length of the shortest path to the
# root of the ontology from the node.  If the node is in fact the root,
# then a value of zero will be returned.
#
# Usage:
#
#    my $length = $node->lengthOfShortestPathToRoot;

    my $self = shift;

    my $minLength;

    foreach my $path ($self->pathsToRoot){

	$minLength = scalar (@{$path}) if (!defined $minLength || scalar (@{$path}) < $minLength);

    }

    return $minLength;

}

##################################################################
sub meanLengthOfPathsToRoot{
##################################################################
# This public method returns the mean length of all paths to the
# root node.  If the node is in fact the root, then a value of zero
# will be returned.
#
# Usage:
#
#    my $length = $node->meanLengthOfPathsToRoot;

    my $self = shift;

    my $total = 0;
    my $num   = 0;

    foreach my $path ($self->pathsToRoot){

	$total += scalar (@{$path});
	$num++;

    }

    my $average = 0;

    if ($num){

	$average = $total/$num;

    }

    return $average;

}
    

# Methods returning a boolean

##################################################################
sub isValid{
##################################################################
# This method can be used to check that a node has been constructed
# correctly.  It checks that it is a child of all its parents, and a parent
# of all of it's children.  In addition, it checks that parents exist as
# the most recent ancestors of the node in its paths to the root node,
# and vice versa.

    my $self = shift;

    my $isValid = 1; # assume there'll be no problems

    # check we're a child of each parent

    foreach my $parent ($self->parentNodes){

	$isValid = 0 unless $parent->isAParentOf($self);

    }

    # check we're a parent of each child

    foreach my $child ($self->childNodes){

	$isValid = 0 unless $child->isAChildOf($self);

    }

    # check that the most recent ancestor in each path is a parent

    foreach my $path ($self->pathsToRoot){

	$isValid = 0 unless $path->[-1]->isAParentOf($self);
	$isValid = 0 unless $self->isAChildOf($path->[-1]);

    }

    return $isValid;

}

##################################################################
sub isAParentOf{
##################################################################
# This public method returns a boolean to indicate whether a node
# has the supplied node as a child.
#
# Usage :
#
#    if ($node->isAParentOf($anotherNode)){
#
#          # blah
#
#    }

    my ($self, $child) = @_;

    return exists $self->{$kChildren}{$child->goid};

}

##################################################################
sub isAChildOf{
##################################################################
# This public method returns a boolean to indicate whether a node
# has the supplied node as a parent.
#
# Usage :
#
#    if ($node->isAChildOf($anotherNode)){
#
#          # blah
#
#    }

    my ($self, $parent) = @_;

    return exists $self->{$kParents}{$parent->goid};

}

##################################################################
sub isAnAncestorOf{
##################################################################
# This method returns a boolean to indicate whether a node is an
# ancestor of another.
#
# Usage:
#
#    if ($node->isAnAncestorOf($anotherNode)){
#
#            # blah
#
#    }

    my ($self, $descendant) = @_;

    return $descendant->isADescendantOf($self);

}

##################################################################
sub isADescendantOf{
##################################################################
# This method returns a boolean to indicate whether a node is a
# descendant of another.
#
# Usage:
#
#    if ($node->isADescendantOf($anotherNode)){
#
#            # blah
#
#    }

    my ($self, $ancestor) = @_;

    # make sure ancestors get stored in ourself, if not already

    $self->ancestors if (!exists $self->{$kAncestors});

    # then check if the possible ancestor is in there

    return (exists $self->{$kAncestors}{$ancestor->goid});

}

##################################################################
sub isLeaf{
##################################################################
# This method returns a boolean to indicate whether a node is a leaf
# in the ontology (i.e. it has no children).
#
# Usage:
#
#    if ($node->isLeaf){
#
#        # blah  
#
#    }

    return (!exists $_[0]->{$kChildren});

}

##################################################################
sub isRoot{
#####################################################################
# This method returns a boolean to indicate whether a node is the root
# in the ontology (i.e. it has no parents).
#
# Usage:
#
#    if ($node->isRoot){
#
#        # blah  
#
#    }

    return (!exists $_[0]->{$kParents});

}

=pod

=head1 Protected Methods

=cut

# need to make this code common to all objects, or to
# start using something like Params-Validate

############################################################################
sub _handleMissingArgument{
############################################################################
=pod

=head2 _handleMissingArgument

This protected method simply provides a simple way for concrete
subclasses to deal with missing arguments from method calls.  It will
die with an appropriate error message.

Usage:

    $self->_handleMissingArgument(argument=>'blah');

=cut
##############################################################################

    my ($self, %args) = @_;

    my $arg = $args{'argument'} || $self->_handleMissingArgument(argument=>'argument');

    my $receiver = (caller(1))[3];
    my $caller   = (caller(2))[3];

    die "The method $caller did not provide a value for the '$arg' argument for the $receiver method";

}

1; # To keep Perl happy


__END__

#####################################################################
#
#  POD Documentation from here on down
#
#####################################################################

=pod

=head1 Instance Constructor

=head2 new

This is the constructor for the Node object At a minimum, the
constructor expects, as named arguments, a GOID and a GO term, with
which to create the node object.

Usage:

    my $node = GO::Node->new(goid => $goid,
			     term => $term);

=head1 Instance Methods

=head2 addChildNodes

The public setter method allows a client to indicate that an array of
nodes are children of the 'self' node.  Only one node per child goid
will get stored.

Usage:

    $node->addChildNodes(@childNodes);

=head2 addParentNodes

The public setter method allows a client to indicate that an array of
nodes are parents of the 'self' node.  Only one node per parent goid
will get stored.

Usage:

    $node->addParentNodes(@parentNodes);

=head2 addPathToRoot

This public setter method expects an array of nodes, that indicates a
direct path to the root of the ontology.  The array should not contain
the self node, but should contain the root node.  The last entry in
the array is expected to be an immediate parent of the self node,
while the first entry is expected to be the root node itself.  This
method will NOT check to see if the supplied path has not already been
added.  It is the Node Factory's responsibility to only add a unique
path once.  Furthermore, it will not check whether there is
consistency between addedPaths and addedParents (this can be done
using the isValid method though).

Usage:

    $node->addPathToRoot(@nodes);

=head2 goid

This public method returns the goid associated with the node.

Usage:

    my $goid = $node->goid;

=head2 term

This public method returns the term associated with the node.

Usage:

    my $goid = $node->term;

=head2 childNodes

This public method returns an array of child nodes for the self node.

Usage:

    my @childNodes = $node->childNodes;

=head2 parentNodes

This public method returns an array of parent nodes for the self node.

Usage:

    my @parentNodes = $node->parentNodes;

=head2 pathsToRoot

This public method returns an array of references to arrays, each of
which contains the nodes in a path between the self node and the root.
The self node is not included in the paths, but the root node is.  The
first node in each array is the most distant ancestor (the root), the
last node is an immediate parent.  If there are no paths to the root
(i.e. it is the root node) then an empty array will be returned.

Usage:

    my @pathsToRoot = $node->pathsToRoot;

=head2 pathsToAncestor

This public method returns an array of references to arrays, each of
which contains the nodes in a path between the self node and the
specified ancestor.  The self node is not included paths, but the
specified ancestor node is.  The first node in each array is the
specified ancestor, the last node is an immediate parent.  If there
are no paths to the ancestor then an empty array will be returned.

Usage:

    my @pathsToAncestor = $node->pathsToAncestor($ancestorNode);

=head2 ancestors

This public method returns an array of unique GO::Nodes which are
the unique ancestors that a node has.  These ancestors will be derived
from the paths to the root node that have been added to the node.

Usage:

    my @ancestors = $node->ancestors;

=head2 lengthOfLongestPathToRoot

This public method returns the length of the longest path to the root
of the ontology from the node.  If the node is in fact the root, then
a value of zero will be returned.

Usage:

    my $length = $node->lengthOfLongestPathToRoot;

=head2 lengthOfShortestPathToRoot

This public method returns the length of the shortest path to the
root of the ontology from the node.  If the node is in fact the root,
then a value of zero will be returned.

Usage:

    my $length = $node->lengthOfShortestPathToRoot;

=head2 meanLengthOfPathsToRoot

This public method returns the mean length of all paths to the
root node.  If the node is in fact the root, then a value of zero
will be returned.

Usage:

    my $length = $node->meanLengthOfPathsToRoot;

=head2 isValid

This method can be used to check that a node has been constructed
correctly.  It checks that it is a child of all its parents, and a
parent of all of its children.  In addition, it checks that parents
exist as the most recent ancestors of the node in its paths to the
root node, and vice versa.  It returns a boolean.

Usage:

    if ($node->isValid){

	# do something

    }

=head2 isAParentOf

This public method returns a boolean to indicate whether a node has
the supplied node as a child.

Usage :

    if ($node->isAParentOf($anotherNode)){
    
	# blah

    }

=head2 isAChildOf

This public method returns a boolean to indicate whether a node
has the supplied node as a parent.

Usage :

    if ($node->isAChildOf($anotherNode)){
    
	# blah

    }

=head2 isAnAncestorOf

This method returns a boolean to indicate whether a node is an
ancestor of another.

Usage:

    if ($node->isAnAncestorOf($anotherNode)){

	# blah

    }

=head2 isADescendantOf

This method returns a boolean to indicate whether a node is a
descendant of another.

Usage:

    if ($node->isADescendantOf($anotherNode)){

	# blah

    }

=head2 isLeaf

This method returns a boolean to indicate whether a node is a leaf
in the ontology (i.e. it has no children).

Usage:

    if ($node->isLeaf){
    
	# blah  

    }

=head2 isRoot

This method returns a boolean to indicate whether a node is the root
in the ontology (i.e. it has no parents).

Usage:

    if ($node->isRoot){

        # blah  

    }

=head1 Authors

    Gavin Sherlock; sherlock@genome.stanford.edu

=cut
