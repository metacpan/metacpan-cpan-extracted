package GO::AnnotatedGene;


# File       : AnnotatedGene.pm
# Author     : Gavin Sherlock
# Date Begun : March 9th 2003

# $Id: AnnotatedGene.pm,v 1.2 2003/11/26 19:23:52 sherlock Exp $

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

=pod

=head1 NAME - I<will> provide an object to hold info about a gene with GO annotation

GO::AnnotatedGene

=head1 DESCRIPTION

The GO::AnnotatedGene package allows creation of objects that contains
the details of a gene as determined from a gene_associations file.
Typically these objects will contain the following information:

    Column  Cardinality   Contents          
    ------  -----------   -------------------------------------------------------------
        1       1         Database identifier of the annotated gene
        2       1         Standard name of the annotated gene
        9       0,1       Name of the product of the annotated gene
       10       0,n       Alias(es) of the annotated gene
       11       1         type of the annotated gene (one of gene, transcript, protein)


Further details can be found at:

http://www.geneontology.org/doc/GO.annotation.html#file

It is expected that AnnotatedGene objects will typically be created by
concrete subclasses of AnnotationProvider

=head1 TODO

A lot....

=cut

use vars qw ($PACKAGE $VERSION);

$PACKAGE = "GO::AnnotatedGene";
$VERSION = "0.11";

# CLASS Attributes
#
# These should be considered as constants, and are initialized here

my $kDatabaseId   = $PACKAGE.'::__databaseId';
my $kStandardName = $PACKAGE.'::__standardName';
my $kType         = $PACKAGE.'::__type';
my $kProductName  = $PACKAGE.'::__productName';
my $kAliases      = $PACKAGE.'::__aliases';

=pod

=head1 Constructor

=cut

############################################################################
sub new{
############################################################################
=pod

=head2 new

This is the constructor for a GO::AnnotatedGene object

It expects to receive the following named arguments:

    databaseId    : The databaseId of the annotated gene
    standardName  : The standardName of the annotated gene
    type          : The type of the annotated gene (one of gene, transcript, protein)

In addition, the following optional arguments may also be provided:

    productName   : The name of the product of the annotated gene
    aliases       : A reference to an array of aliases

Usage:

    my $annotatedGene = GO::AnnotatedGene->new(databaseId   => $databaseId,
                                               standardName => $standardName,
                                               type         => $type,
                                               productName  => $productName,
                                               aliases      => $aliases);

=cut

    my $self = {};

    my $class = shift;

    bless $self, $class;

    $self->__init(@_);

    return $self;

}

############################################################################
sub __init{
############################################################################
# This private method initializes the object, dependent on what arguments
# have been received.
#

    my ($self, %args) = @_;

    # check required arguments

    my $databaseId   = $args{'databaseId'}   || $self->_handleMissingArgument(argument => 'databaseId');
    my $standardName = $args{'standardName'} || $self->_handleMissingArgument(argument => 'standardName');
    my $type         = $args{'type'}         || $self->_handleMissingArgument(argument => 'type');

    # store them

    $self->{$kDatabaseId}   = $databaseId;
    $self->{$kStandardName} = $standardName;
    $self->{$kType}         = $type;
    
    # now check and store optional arguments

    if (exists ($args{'productName'}) && defined ($args{'productName'})){

	$self->{$kProductName} = $args{'productName'};

    }else{

	$self->{$kProductName} = undef;

    }

    if (exists ($args{'aliases'}) && defined ($args{'aliases'})){

	$self->{$kAliases} = $args{'aliases'};

    }else{

	$self->{$kAliases} = []; # default to an empty list

    }

}

=pod

=head1 Public Instance Methods

=cut

############################################################################
sub databaseId{
############################################################################
=pod

=head2 databaseId

This public instance method returns the databaseId.

Usage : 

    my $databaseId = $annotatedGene->databaseId;

=cut

    return $_[0]->{$kDatabaseId};

}

############################################################################
sub standardName{
############################################################################
=pod

=head2 standardName

This public instance method returns the standardName.

Usage:

    my $standardName = $annotatedGene->standardName;

=cut

    return $_[0]->{$kStandardName};

}

############################################################################
sub type{
############################################################################
=pod

=head2 type

This public instance method returns the type of the annotated gene.

Usage:

    my $type = $annotatedGene->type;

=cut

    return $_[0]->{$kType};

}

############################################################################
sub productName{
############################################################################
=pod


=head2 productName

This public instance method returns the product name of the annotated
gene, if one exists.  Otherwise it returns undef.

Usage:

    my $productName = $annotatedGene->productName;

=cut

    return $_[0]->{$kProductName};

}

############################################################################
sub aliases{
############################################################################
=pod

=head2 aliases

This public instance method returns an array of aliases for the
annotated gene.  If no aliases exist, then an empty array will be
returned.

Usage:

    my @aliases = $annotatedGene->aliases;

=cut

    return @{$_[0]->{$kAliases}};

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



1; # to keep Perl happy

=pod

=head1 AUTHOR

Gavin Sherlock, sherlock@genome.stanford.edu

=cut
