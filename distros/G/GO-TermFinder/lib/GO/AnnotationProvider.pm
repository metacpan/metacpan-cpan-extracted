package GO::AnnotationProvider;

# File        : AnnotationProvider.pm
# Author      : Gavin Sherlock
# Date Begun  : September 26th 2002

# $Id: AnnotationProvider.pm,v 1.13 2006/07/27 23:59:48 sherlock Exp $

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

use strict;
use warnings;
use diagnostics;

use vars qw ($VERSION);

$VERSION = 0.12;

=pod

=head1 NAME

GO::AnnotationProvider - abstract base class defining interface for how Annotation information should be provided

=head1 DESCRIPTION

GO::AnnotationProvider is an interface that defines an API that
should be implemented by specific subclasses, which may read GO
annotation from databases, flatfiles, XML files etc.

GO (Gene Ontology) is a project of the Gene Ontology Consortium
(http://www.geneontology.org).  The GO project has 3 'aspects' :

    Biological Process
    Molecular Function
    Cellular Component

When a method requires the client to refer to an aspect, it is simply
by a shorthand, namely P, F and C, respectively.

In GO associations, annotated entities may be identified by many
different names.  Firstly, they should have a database identifier,
which should be unique for an entity.  Secondly, they should have a
standard name.  Standard names should be unique among standard names,
but it is possible that a standard name of one entity may be used as
an alias of another.  An entity may have many aliases, and an alias
may be used for many entities.  Hence, a name (drawn from databaseIds,
standard names, and aliases) may be ambiguous in the entity to which
it refers.  This is an important concept for clients of concrete
subclasses to take into consideration, so that unexpected results are
avoided.

=head1 TODO

Currently this interface dictates that clients can retrieve GOIDs that
have been used to annotated genes.  In future, this interface is
likely to change, such that instead of GOIDs, GO::Annotation objects
are instead returned, which will be richer in the terms of information
they can give about a given annotation.  Such objects would contain a
GO::AnnotatedGene object, one or more GO::Reference objects, and an
evidence code.  The retrieval of annotations for a given database id
could then be extended to allow filtering by evidence codes, to either
include or exclude certain codes.

This interface also currently only allows retrieval of GOIDs for
genes, in future, it will be extended such that the genes can be
retrieved by GOID.

=head1 Constructor

Because this is an abstract class, there is no constructor.  A
constructor must be implemented by concrete subclasses.

=head1 Public instance methods

All of these public instance methods must be implemented by concrete subclasses.

=head1 Some methods dealing with ambiguous names

Because there are many names by which an annotated entity may be
referred to, that are non-unique, this interface defines a set of
methods for determining whether a name is ambiguous, and to what
database identifiers such ambiguous names may refer.

Note, that the AnnotationProvider subclasses should now be case
insensitive, though there are some caveats.  For instance, you can use
'cdc6' to retrieve data for CDC6.  However, This if gene has been
referred to as abc1, and another referred to as ABC1, then these are
treated as different, and unambiguous.  However, the text 'Abc1' would
be considered ambiguous, because it could refer to either.  On the
other hand, if a single gene is referred to as XYZ1 and xyz1, and no
other genes have that name (in any casing), then Xyz1 would still be
considered unambiguous.

=cut

##############################################################################
sub nameIsAmbiguous{
##############################################################################
=pod

=head2 nameIsAmbiguous

NB: API change:

nameIsAmbiguous is now case insensitive - that is, if there is a name
that is used twice using different casing, that will be treated as
ambiguous.  Previous versions would have not treated these as
ambiguous.  In the case that a name is provided in a certain casing,
which was encountered only once, then it will be treated as
unambiguous.  This is the price of wanting a case insensitive
annotation provider...

Usage:

    if ($annotationProvider->nameIsAmbiguous($name)){

        do something useful....or not....

    }

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub databaseIdsForAmbiguousName{
############################################################################
=pod

=head2 databaseIdsForAmbiguousName

This public method returns an array of database identifiers for an
ambiguous name.  If the name is not ambiguous, an empty list will be
returned.

B: API change:

databaseIdsForAmbiguousName is now case insensitive - that is, if
there is a name that is used twice using different casing, that will
be treated as ambiguous.  Previous versions would have not treated
these as ambiguous.  However, if the name provided is of the exact
casing as a name that appeared only once with that exact casing, then
it is treated as unambiguous. This is the price of wanting a case
insensitive annotation provider...

Usage:

    my @databaseIds = $annotationProvider->databaseIdsForAmbiguousName($name);

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub ambiguousNames{
############################################################################
=pod

=head2 ambiguousNames

This method returns an array of names, which from the annotation source
have been deemed to be ambiguous.

Note - even though this is now case insensitive, if something is
called both BLAH1 and blah1, we would not deem either of these to be
ambiguous.  However, if it appeared as blah1 twice, referring to two
different genes, then blah1 would be ambiguous.

Usage:

    my @ambiguousNames = $annotationProvider->ambiguousNames;

=cut

    $_[0]->__complainStubMethod;

}

=pod

=head1 Methods for retrieving GO annotations for entities

=cut

############################################################################
sub goIdsByDatabaseId{
############################################################################
=pod

=head2 goIdsByDatabaseId

This public method returns a reference to an array of GOIDs that are
associated with the supplied databaseId for a specific aspect.  If no
annotations are associated with that databaseId in that aspect, then a
reference to an empty array will be returned.  If the databaseId is
not recognized, then undef will be returned.

Usage:

    my $goidsRef = $annotationProvider->goIdsByDatabaseId(databaseId=>$databaseId,
							  aspect=><P|F|C>);

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub goIdsByStandardName{
############################################################################
=pod

=head2 goIdsByStandardName

This public method returns a reference to an array of GOIDs that are
associated with the supplied standardName for a specific aspect.  If
no annotations are associated with the entity with that standard name
in that aspect, then a a reference to an empty list will be returned.
If the supplied name is not used as a standard name, then undef will
be returned.

Usage:

    my $goidsRef = $annotationProvider->goIdsByStandardName(standardName=>$databaseId,
							    aspect=><P|F|C>);

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub goIdsByName{
############################################################################
=pod

=head2 goIdsByName

This public method returns a reference to an array of GO IDs that are
associated with the supplied name for a specific aspect.  If there are
no GO associations for the entity corresponding to the supplied name
in the provided aspect, then a reference to an empty list will be
returned.  If the supplied name does not correspond to any entity,
then undef will be returned.  Because the name can be any of the
databaseId, the standard name, or any of the aliases, it is possible
that the name might be ambiguous.  Clients of this object should first
test whether the name they are using is ambiguous, using the
nameIsAmbiguous() method, and handle it accordingly.  If an ambiguous
name is supplied, then it will die.

NB: API change:

goIdsByName is now case insensitive - that is, if there is a name that
is used twice using different casing, that will be treated as
ambiguous.  Previous versions would have not treated these as
ambiguous.  This is the price of wanting a case insensitive annotation
provider.  In the event that a name is provided that is ambiguous
because of case, if it matches exactly the case of one of the possible
matches, it will be treated unambiguously.

Usage:

    my $goidsRef = $annotationProvider->goIdsByName(name=>$name,
						    aspect=><P|F|C>);

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

=pod

=head1 Methods for mapping different types of name to each other

=cut

############################################################################
sub standardNameByDatabaseId{
############################################################################
=pod

=head2 standardNameByDatabaseId

This method returns the standard name for a database id.

NB: API change

standardNameByDatabaseId is now case insensitive - that is, if there
is a databaseId that is used twice (or more) using different casing,
it will be treated as ambiguous.  Previous versions would have not
treated these as ambiguous.  This is the price of wanting a case
insensitive annotation provider.  In the event that a name is provided
that is ambiguous because of case, if it matches exactly the case of
one of the possible matches, it will be treated unambiguously.

Usage:

    my $standardName = $annotationProvider->standardNameByDatabaseId($databaseId);

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub databaseIdByStandardName{
############################################################################
=pod

=head2 databaseIdByStandardName

This method returns the database id for a standard name.

NB: API change

databaseIdByStandardName is now case insensitive - that is, if there
is a standard name that is used twice (or more) using different
casing, it will be treated as ambiguous.  Previous versions would have
not treated these as ambiguous.  This is the price of wanting a case
insensitive annotation provider.  In the event that a name is provided
that is ambiguous because of case, if it matches exactly the case of
one of the possible matches, it will be treated unambiguously.

Usage:

    my $databaseId = $annotationProvider->databaseIdByStandardName($standardName);

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub databaseIdByName{
############################################################################
=pod

=head2 databaseIdByName

This method returns the database id for any identifier for a gene (e.g.
by databaseId itself, by standard name, or by alias).  If the used
name is ambiguous, then the program will die.  Thus clients should
call the nameIsAmbiguous() method, prior to using this method.  If the
name does not map to any databaseId, then undef will be returned.

NB: API change

databaseIdByName is now case insensitive - that is, if there is a name
that is used twice using different casing, that will be treated as
ambiguous.  Previous versions would have not treated these as
ambiguous.  This is the price of wanting a case insensitive annotation
provider.  In the event that a name is provided that is ambiguous
because of case, if it matches exactly the case of one of the possible
matches, it will be treated unambiguously.

Usage:

    my $databaseId = $annotationProvider->databaseIdByName($name);

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub standardNameByName{
############################################################################
=pod

=head2 standardNameByName

This public method returns the standard name for the the gene
specified by the given name.  Because a name may be ambiguous, the
nameIsAmbiguous() method should be called first.  If an ambiguous name
is supplied, then it will die with an appropriate error message.  If
the name does not map to a standard name, then undef will be returned.

NB: API change

standardNameByName is now case insensitive - that is, if there is a
name that is used twice using different casing, that will be treated
as ambiguous.  Previous versions would have not treated these as
ambiguous.  This is the price of wanting a case insensitive annotation
provider.

Usage:

    my $standardName = $annotationProvider->standardNameByName($name);
 
=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

=pod

=head1  Other methods relating to names

=cut

##############################################################################
sub nameIsStandardName{
##############################################################################
=pod

=head2 nameIsStandardName

This method returns a boolean to indicate whether the supplied name is
used as a standard name.

NB : API change.

This is now case insensitive.  If you provide abC1, and ABc1 is a
standard name, then it will return true.

Usage :

    if ($annotationProvider->nameIsStandardName($name)){

	# do something

    }

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

##############################################################################
sub nameIsDatabaseId{
##############################################################################
=pod

=head2 nameIsDatabaseId

This method returns a boolean to indicate whether the supplied name is
used as a database id.

NB : API change.

This is now case insensitive.  If you provide abC1, and ABc1 is a
database id, then it will return true.

Usage :

    if ($annotationProvider->nameIsDatabaseId($name)){

	# do something

    }

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub nameIsAnnotated{
############################################################################
=pod

=head2 nameIsAnnotated

This method returns a boolean to indicate whether the supplied name has any 
annotations, either when considered as a databaseId, a standardName, or
an alias.  If an aspect is also supplied, then it indicates whether that
name has any annotations in that aspect only.

NB: API change.

This is now case insensitive.  If you provide abC1, and ABc1 has
annotation, then it will return true.

Usage :

    if ($annotationProvider->nameIsAnnotated(name => $name)){

	# blah

    }

or:

    if ($annotationProvider->nameIsAnnotated(name   => $name,
					   aspect => $aspect)){

	# blah

    }


=cut
##############################################################################

    $_[0]->__complainStubMethod;

}


=pod

=head1 Other public methods

=cut

############################################################################
sub databaseName{
############################################################################
=pod

=head2 databaseName

This method returns the name of the annotating authority of the annotations.

Usage :

    my $databaseName = $annotationProvider->databaseName;

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub numAnnotatedGenes{
############################################################################
=pod

=head2 numAnnotatedGenes

This method returns the number of entities in the annotation file that
have annotations in the supplied aspect.  If no aspect is provided,
then it will return the number of genes with an annotation in at least
one aspect of GO.

Usage:

    my $numAnnotatedGenes = $annotationProvider->numAnnotatedGenes;

    my $numAnnotatedGenes = $annotationProvider->numAnnotatedGenes($aspect);

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub allDatabaseIds{
############################################################################
=pod

=head2 allDatabaseIds

This public method returns an array of all the database identifiers

Usage:

    my @databaseIds = $annotationProvider->allDatabaseIds;

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
sub allStandardNames{
############################################################################
=pod


=head2 allStandardNames

This public method returns an array of all standard names.

Usage:

    my @standardNames = $annotationProvider->allStandardNames;

=cut
##############################################################################

    $_[0]->__complainStubMethod;

}

############################################################################
#
# PROTECTED METHODS
#
############################################################################

=pod

=head1 Protected Methods

=cut

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

############################################################################
#
# PRIVATE METHODS
#
############################################################################

############################################################################
sub __complainStubMethod{
############################################################################
# This method is called only if a stub method gets called, because a
# subclass failed to provide an implementation of one of the methods
# required by the interface.  It will cause a fatal error.

    my $self = shift;

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
