package GO::OntologyProvider;

# File         : OntologyProvider.pm
# Author       : Gavin Sherlock
# Date Begun   : September 23rd 2002

# $Id: OntologyProvider.pm,v 1.7 2004/05/05 22:12:33 sherlock Exp $

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

GO::OntologyProvider - abstract base class providing API for the provision on Gene Ontology information

=head1 DESCRIPTION

GO::OntologyProvider is an abstract class that defines an
interface that should be implemented by specific subclasses, which may
read ontology information from databases, flatfiles, XML files etc.

All of the methods return either one or many GO::Node(s), and any
concrete subclass is expected to fully flesh out the such Node objects
with all the parents, children and paths to the root, such that any
node should return a true value when the isValid method is invoked on
it.

=head1 Constructor

Because this is an abstract class, there is no constructor.  A
constructor must be implemented by concrete subclasses.

=head1 Public instance methods

All of these public instance methods must be implemented by concrete
subclasses.

=cut

use strict;
use warnings;
use diagnostics;

use vars qw ($VERSION);

$VERSION = 0.12;

############################################################################
sub allNodes{
############################################################################
=pod

=head2 allNodes

This method returns an array of all the GO::Nodes that have been
created.

Usage:

    my @nodes = $ontologyProvider->allNodes;

=cut
############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub rootNode{
############################################################################
=pod

=head2 rootNode

This method returns the root node in the ontology.

Usage:

	my $rootNode = $ontologyProvider->rootNode;

=cut
############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub nodeFromId{
############################################################################
=pod

=head2 nodeFromId

This method returns a GO::Node corresponding to the provided
GOID, should one exist.  Otherwise it returns undef.

Usage:

	my $node = $ontologyProvider->nodeFromId("GO:0003673");

=cut
############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub numNodes{
############################################################################
=pod

=head2 numNodes

This method returns the number of nodes that exist within the
ontology.

Usage:

	my $numNodes = $ontologyProvider->numNodes;

=cut

############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub __complainStubMethod{
############################################################################

    my ($self) = @_;

    my $subroutine = (caller(1))[3];

    $subroutine =~ s/.+:://;

    my $package = ref $self;

    die "The package $package has not implemented the required method $subroutine().\n";

}

1; # to keep Perl happy

=pod

=head1 AUTHOR

Gavin Sherlock,  sherlock@genome.stanford.edu

=cut
