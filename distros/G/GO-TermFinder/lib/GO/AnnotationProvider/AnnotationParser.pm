package GO::AnnotationProvider::AnnotationParser;

# File       : AnnotationParser.pm
# Authors    : Elizabeth Boyle; Gavin Sherlock
# Date Begun : Summer 2001
# Rewritten  : September 25th 2002

# $Id: AnnotationParser.pm,v 1.35 2008/05/13 23:06:16 sherlock Exp $

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

GO::AnnotationProvider::AnnotationParser - parses a gene annotation file

=head1 SYNOPSIS

GO::AnnotationProvider::AnnotationParser - reads a Gene Ontology gene
associations file, and provides methods by which to retrieve the GO
annotations for the an annotated entity.  Note, it is case
insensitive, with some caveats - see documentation below.

    my $annotationParser = GO::AnnotationProvider::AnnotationParser->new(annotationFile => "data/gene_association.sgd");

    my $geneName = "AAT2";

    print "GO associations for gene: ", join (" ", $annotationParser->goIdsByName(name   => $geneName,
										  aspect => 'P')), "\n";

    print "Database ID for gene: ", $annotationParser->databaseIdByName($geneName), "\n";

    print "Database name: ", $annotationParser->databaseName(), "\n";

    print "Standard name for gene: ", $annotationParser->standardNameByName($geneName), "\n";

    my $i;

    my @geneNames = $annotationParser->allStandardNames();

    foreach $i (0..10) {

        print "$geneNames[$i]\n";

    }

=head1 DESCRIPTION

GO::AnnotationProvider::AnnotationParser is a concrete subclass of
GO::AnnotationProvider, and creates a data structure mapping gene
names to GO annotations by parsing a file of annotations provided by
the Gene Ontology Consortium.

This package provides object methods for retrieving GO annotations
that have been parsed from a 'gene associations' file, provided by
the gene ontology consortium.  The format for the file is:

Lines beginning with a '!' character are comment lines.

    Column  Cardinality   Contents          
    ------  -----------   -------------------------------------------------------------
        0       1         Database abbreviation for the source of annotation (e.g. SGD)
        1       1         Database identifier of the annotated entity
        2       1         Standard name of the annotated entity
        3       0,1       NOT (if a gene is specifically NOT annotated to the term)
        4       1         GOID of the annotation     
        5       1,n       Reference(s) for the annotation 
        6       1         Evidence code for the annotation
        7       0,n       With or From (a bit mysterious)
        8       1         Aspect of the Annotation (C, F, P)
        9       0,1       Name of the product being annotated
       10       0,n       Alias(es) of the annotated product
       11       1         type of annotated entity (one of gene, transcript, protein)
       12       1,2       taxonomic id of the organism encoding and/or using the product
       13       1         Date of annotation YYYYMMDD
       14       1         Assigned_by : The database which made the annotation

Columns are separated by tabs.  For those entries with a cardinality
greater than 1, multiple entries are pipe , |, delimited.

Further details can be found at:

http://www.geneontology.org/doc/GO.annotation.html#file

The following assumptions about the file are made (and should be true):

    1.  All aliases appear for all entries of a given annotated product
    2.  The database identifiers are unique, in that two different
        entities cannot have the same database id.

=head1 TODO

Also see the TODO list in the parent, GO::AnnotationProvider.

 1.  Add in methods that will allow retrieval of evidence codes with
     the annotations for a particular entity.

 2.  Add in methods that return all the annotated entities for a
     particular GOID.

 3.  Add in the ability to request only annotations either including
     or excluding particular evidence codes.  Such evidence codes
     could be provided as an anonymous array as the value of a named
     argument.

 4.  Same as number 3, except allow the retrieval of annotated
     entities for a particular GOID, based on inclusion or exclusion
     of certain evidence codes.

 These first four items will require a reworking of how data are
 stored on the backend, and thus the parsing code itself, though it
 should not affect any of the already existing API.

 5.  Instead of 'use'ing Storable, 'require' it instead, only at the
     point of use, which will mean that AnnotationParser can be
     happily used in the absence of Storable, just without those
     functions that need it.

 6.  Extend the ValidateFile class method to check that an entity
     should never be annotated to the same node twice, with the same
     evidence, with the same reference.

 7.  An additional checker, that uses an AnnotationProvider in
     conjunction with an OntologyProvider, would be useful, that
     checks that some of the annotations themselves are valid, ie
     that no entities are annotated to the 'unknown' node in a
     particular aspect, and also to another node within that same
     aspect.  Can annotations be redundant? ie, if an entity is
     annotated to a node, and an ancestor of the node, is that
     annotation redundant?  Does it depend on the evidence codes and
     references.  Or are such annotations reinforcing?  These things
     are useful to consider when formulating the confidence which can
     be attributed to an annotation.

=cut

use strict;
use warnings;
use diagnostics;

use Storable qw (nstore);
use IO::File;

use vars qw (@ISA $PACKAGE $VERSION);

use GO::AnnotationProvider;
@ISA = qw (GO::AnnotationProvider);

$PACKAGE = "GO::AnnotationProvider::AnnotationParser";
$VERSION = "0.15";

# CLASS Attributes
#
# These should be considered as constants, and are initialized here

my $DEBUG = 0;

# constants for instance attribute name


my $kDatabaseName           = $PACKAGE.'::__databaseName';           # stores the name of the annotating database
my $kFileName               = $PACKAGE.'::__fileName';               # stores the name of the file used to instantiate the object
my $kNameToIdMapInsensitive = $PACKAGE.'::__nameToIdMapInsensitive'; # stores a case insensitive map of all unambiguous names for a gene to the database id
my $kNameToIdMapSensitive   = $PACKAGE.'::__nameToIdMapSensitive';   # stores a case sensitive map of all names where a particular casing is unambiguous for a gene to the database id
my $kAmbiguousNames         = $PACKAGE.'::__ambiguousNames';         # stores the database id's for all ambiguous names
my $kIdToStandardName       = $PACKAGE.'::__idToStandardName';       # stores a map of database id's to standard names of all entities
my $kStandardNameToId       = $PACKAGE.'::__StandardNameToId';       # stores a map of standard names to their database id's
my $kUcIdToId               = $PACKAGE.'::__ucIdToId';               # stores a map of uppercased databaseIds to the databaseId
my $kUcStdNameToStdName     = $PACKAGE.'::__ucStdNameToStdName';     # stores a map of uppercased standard names to the standard name
my $kNameToCount            = $PACKAGE.'::__nameToCount';            # stores a case sensitive map of the number of times a name has been seen
my $kGoids                  = $PACKAGE.'::__goids';                  # stores all the goid annotations
my $kNumAnnotatedGenes      = $PACKAGE.'::__numAnnotatedGenes';      # stores number of genes with annotations, per aspect

my $kAmbiguousNamesSensitive = $PACKAGE.'::__ambiguousNamesSensitive'; # names (case sensitive) that are ambiguous

my $kTotalNumAnnotatedGenes = $PACKAGE.'::__totalNumAnnotatedGenes'; # total number of annotated genes

# constants to describe what is in which column in the annotation file

my $kDatabaseNameColumn = 0;
my $kDatabaseIdColumn   = 1;
my $kStandardNameColumn = 2;
my $kNotColumn          = 3;
my $kGoidColumn         = 4;
my $kReferenceColumn    = 5;
my $kEvidenceColumn     = 6;
my $kWithColumn         = 7;
my $kAspectColumn       = 8;
my $kNameColumn         = 9;
my $kAliasesColumn      = 10;
my $kEntityTypeColumn   = 11;
my $kTaxonomicIDColumn  = 12;
my $kDateColumn         = 13;
my $kAssignedByColumn   = 14;

# the following hash of anonymous arrays indicates for each column
# what the maximum and minimum number of entries per column can be.
# If no maximum is indicated, then the maximum is equal to the
# minimum, and exactly that number of entries must exist.

my %kColumnsToCardinality = ($kDatabaseNameColumn => [1     ],
			     $kDatabaseIdColumn   => [1     ],
			     $kStandardNameColumn => [1     ],
			     $kNotColumn          => [0,   1],
			     $kGoidColumn         => [1     ],
			     $kReferenceColumn    => [1, "n"],
			     $kEvidenceColumn     => [1     ],
			     $kWithColumn         => [0, "n"],
			     $kAspectColumn       => [1     ],
			     $kNameColumn         => [0,   1],
			     $kAliasesColumn      => [0, "n"],
			     $kEntityTypeColumn   => [1     ],
			     $kTaxonomicIDColumn  => [1,   2],
			     $kDateColumn         => [1     ],
			     $kAssignedByColumn   => [1     ]);

my $kNumColumnsInFile = scalar keys %kColumnsToCardinality;

=pod

=head1 Class Methods

=cut

############################################################################
sub Usage{
############################################################################
=pod

=head2 Usage

This class method simply prints out a usage statement, along with an
error message, if one was passed in.

Usage :

    GO::AnnotationProvider::AnnotationParser->Usage();

=cut

    my ($class, $message) = @_;

    defined $message && print $message."\n\n";

    print 'The constructor expects one of two arguments, either a
\'annotationFile\' argument, or and \'objectFile\' argument.  When
instantiated with an annotationFile argument, it expects it to
correspond to an annotation file created by one of the GO consortium
members, according to their file format.  When instantiated with an
objectFile argument, it expects to open a previously created
annotationParser object that has been serialized to disk (see the
serializeToDisk method).

Usage:

    my $annotationParser = '.$PACKAGE.'->new(annotationFile => $file);

    my $annotationParser = '.$PACKAGE.'->new(objectFile => $file);
';

}

############################################################################
sub ValidateFile{
############################################################################
=pod

=head2 ValidateFile

This class method reads an annotation file, and returns a reference to
an array of errors that are present within the file.  The errors are
simply strings, each beginning with "Line $lineNo : " where $lineNo is
the number of the line in the file where the error was found.

Usage:

    my $errorsRef = GO::AnnotationProvider::AnnotationParser->ValidateFile(annotationFile => $file);

=cut

    my ($class, %args) = @_;
    
    my $file = $args{'annotationFile'} || $class->_handleMissingArgument(argument => 'annotationFile');
    
    my $annotationsFh = IO::File->new($file, q{<} )|| die "$PACKAGE cannot open $file : $!";

    my (@errors, @line);

    my ($databaseId, $standardName, $aliases);
    my (%idToName, %idToAliases);

    my $lineNo = 0;
    
    while (<$annotationsFh>){
	
	++$lineNo;
	
	next if $_ =~ m/^!/; # skip comment lines
	
	chomp;

	next unless $_; # skip an empty line, if there is one
	
	@line = split("\t", $_, -1);
	
	if (scalar @line != $kNumColumnsInFile){ # doesn't have the correct number of columns
	    
	    push (@errors, "Line $lineNo has ". scalar @line. "columns, instead of $kNumColumnsInFile.");
	    
	}
	
	$class->__CheckCardinalityOfColumns(\@errors, \@line, $lineNo);
	
	# now want to deal with sanity checks...
	
	($databaseId, $standardName, $aliases) = @line[$kDatabaseIdColumn, $kStandardNameColumn, $kAliasesColumn];
	
	next if ($databaseId eq ""); # will have given incorrect cardinality, but nothing more we can do with it

	if (!exists $idToName{$databaseId}){

	    $idToName{$databaseId} = $standardName;

	}elsif ($idToName{$databaseId} ne $standardName){

	    push (@errors, "Line $lineNo : $databaseId has more than one standard name : $idToName{$databaseId} and $standardName.");

	}

	if (!exists $idToAliases{$databaseId}){

	    $idToAliases{$databaseId} = $aliases;

	}elsif($idToAliases{$databaseId} ne $aliases){

	    push (@errors, "Line $lineNo : $databaseId has more than one collections of aliases : $idToAliases{$databaseId} and $aliases.");

	}   

    }
    
    $annotationsFh->close || die "$PACKAGE cannot close $file : $!";
    
    return \@errors;

}

############################################################################
sub __CheckCardinalityOfColumns{
############################################################################
# This method checks the cardinality of each column on a line
#
# Usage:
#
#    $class->__CheckCardinalityOfColumns(\@errors, \@line, $lineNo);
    
    my ($class, $errorsRef, $lineRef, $lineNo) = @_;
    
    my ($cardinality, $min, $max);
    
    foreach my $column (sort {$a<=>$b} keys %kColumnsToCardinality){
	
	($min, $max) = @{$kColumnsToCardinality{$column}}[0,1];
	
	$cardinality = $class->__GetCardinality($lineRef->[$column], $errorsRef, $lineNo);
	
	if (!defined $max){ # must have a defined number of entries

	    if ($cardinality != $min){
		
		push (@{$errorsRef}, "Line $lineNo : column $column has a cardinality of $cardinality, instead of $min.");
		
	    }
	    
	}else{ # there's a range of allowed number of entries
	    
	    if ($cardinality < $min){ # check if less than minimum
		
		push (@{$errorsRef}, "Line $lineNo : column $column has a cardinality of $cardinality, which is less than the required $min.");
		
	    }elsif ($kColumnsToCardinality{$column}->[1] ne 'n' &&
		    $cardinality > $max){ # check if more than maximum
		
		push (@{$errorsRef}, "Line $lineNo : column $column has a cardinality of $cardinality, which is more than the allowed $max.");
		
	    }
	    
	}
	
    }

}

############################################################################
sub __GetCardinality{
############################################################################
# This private method returns an integer that indicates the
# cardinality of a text string, where multiple entries are assumed to
# be seperated by the pipe character (|).  In addition, it checks
# whether there are null or whitespace only entries.
#
# Usage:
#
#    my $cardinality = $class->__GetCardinality($string);

    my ($class, $string, $errorsRef, $lineNo) = @_;

    my $cardinality;

    if (!defined $string || $string eq ""){

	$cardinality = 0;

    }else{

	my @entries = split(/\|/, $string, -1);

	foreach my $entry (@entries){

	    if (!defined $entry){

		push (@{$errorsRef}, "Line $lineNo : There is an undefined value in the string $string.");

	    }elsif ($entry =~ /^\s+$/){

		push (@{$errorsRef}, "Line $lineNo : There is a white-space only value in the string $string.");

	    }

	}

	$cardinality = scalar @entries;

    }

    return $cardinality;

}

############################################################################
#
# Constructor, and initialization methods.
#
# All initialization methods are private, except, of course, for the
# new() method.
#
############################################################################

############################################################################
sub new{
############################################################################
=pod

=head1 Constructor

=head2 new

This is the constructor for an AnnotationParser object.

The constructor expects one of two arguments, either a
'annotationFile' argument, or and 'objectFile' argument.  When
instantiated with an annotationFile argument, it expects it to
correspond to an annotation file created by one of the GO consortium
members, according to their file format.  When instantiated with an
objectFile argument, it expects to open a previously created
annotationParser object that has been serialized to disk (see the
serializeToDisk method).

Usage:

    my $annotationParser = GO::AnnotationProvider::AnnotationParser->new(annotationFile => $file);

    my $annotationParser = GO::AnnotationProvider::AnnotationParser->new(objectFile => $file);

=cut


    my ($class, %args) = @_;

    my $self;

    if (exists($args{'annotationFile'})){

	$self = {};

	bless $self, $class;

	$self->__init($args{'annotationFile'});

    }elsif (exists($args{'objectFile'})){

	$self = Storable::retrieve($args{'objectFile'}) || die "Could not instantiate $PACKAGE object from objectFile : $!";

	$self->__setFile($args{'objectFile'});

    }else{

	$class->Usage("An annotationFile or objectFile argument must be provided.");
	die;

    }

    # now, we have to make some alteration to some hashes to support
    # our API for case insensitivity.  The API says that if a name is
    # supplied that would otherwise be ambiguous, but has a unique
    # casing, then we will accept it as that unique cased version.
    # Thus, we need to make sure that our $kNameToIdMapSensitive hash
    # only tracks those names that were unique in a particular case

    foreach my $name (keys %{$self->{$kNameToCount}}){

	# go through the has that has a count of each name

	if ($self->{$kNameToCount}{$name} > 1 || exists $self->{$kNameToIdMapInsensitive}{uc($name)}){

	    # if it was seen more than once, or is known to be unique
	    # in a case insensitive fashion, then delete it.  This
	    # will leave just those that are unique in a case
	    # sensitive fashion

	    delete $self->{$kNameToIdMapSensitive}{$name};

	}

    }

    return ($self);

}

############################################################################
sub __init{
############################################################################
# This private method initializes the object by reading in the data
# from the annotation file.
#
# Usage :
#
#    $self->__init($file);
#

    my ($self, $file) = @_;

    $self->__setFile($file);

    my $annotationsFh = IO::File->new($file, q{<} )|| die "$PACKAGE cannot open $file : $!";

    # now read through annotations file

    my (@line, $databaseId, $goid, $aspect, $standardName, $aliases);
    
    while (<$annotationsFh>){

	next if $_ =~ m/^!/; # skip commented lines

	chomp;

	next unless $_; # skip an empty line, if there is one

	@line = split("\t", $_, -1);

	next if $line[$kNotColumn] eq 'NOT'; # skip annotations NOT to a GOID

	($databaseId, $goid, $aspect) = @line[$kDatabaseIdColumn, $kGoidColumn, $kAspectColumn];
	($standardName, $aliases)     = @line[$kStandardNameColumn, $kAliasesColumn];

	if ($databaseId eq ""){

	    print "On line $. there is a missing databaseId, so it will be ignored.\n";
	    next;

	}

	# record the source of the annotation
	
	$self->{$kDatabaseName} = $line[$kDatabaseNameColumn] if (!exists($self->{$kDatabaseName}));

	# now map the standard name and all aliases to the database id
	    
	$self->__mapNamesToDatabaseId($databaseId, $standardName, $aliases);

	# and store the GOID
	
	$self->__storeGOID($databaseId, $goid, $aspect);

    }

    $annotationsFh->close || die "AnnotationParser can't close $file: $!";

    # now count up how many annotated things we have

    foreach my $databaseId (keys %{$self->{$kGoids}}){

	$self->{$kTotalNumAnnotatedGenes}++;

	foreach my $aspect (keys %{$self->{$kGoids}{$databaseId}}){

	    $self->{$kNumAnnotatedGenes}{$aspect}++;

	}

    }

}

############################################################################
sub __setFile{
############################################################################
# This method sets the name of the file used for construction.
# 
# Usage:
#
#    $self->__setFile($file);
#

    my ($self, $file) = @_;

    $self->{$kFileName} = $file;

}

############################################################################
sub __mapNamesToDatabaseId{
############################################################################
# This private method maps all names and aliases to the databaseId of
# an entity.  It also maps the databaseId to itself, to facilitate a
# single way of mapping any identifier to the database id.
#
# This mapping is done so that it can be queried in a case insensitive
# fashion, and thus allow clients to be able to retrieve annotations
# without necessarily knowing the correct casing of any particular
# identifier.
#
# We have to keep the following considerations in mind:
#
# 1. Any identifier may be non-unique with respect to casing, that is,
#    it is possible that there is ABC1 and abc1
#
# 2. We want to be able to returns names and identifiers in their correct
#    casing, irrespective of the casing that is provided in the query
#
# 3. In the situation when a name that is ambiguous when considered case
#    insensitively is provided, we should check to see whether that casing
#    corresponds to a know correct casing, and assume that that is the one 
#    that they meant.
#
# Usage :
#
#    $self->__mapNamesToDatabaseId($databaseId, $standardName, $aliases);
#
# where $aliases is a pipe-delimited list of aliases

    my ($self, $databaseId, $standardName, $aliases) = @_;

    if (exists $self->{$kIdToStandardName}{$databaseId}){ # we've already seen this databaseId

	if ($self->{$kIdToStandardName}{$databaseId} ne $standardName){

	    # there is a problem in the file - there should only be
	    # one standard name for a given database id, so we'll die
	    # here

	    die "databaseId $databaseId maps to more than one standard name : $self->{$kIdToStandardName}{$databaseId} ; $standardName\n";

	}else{

	    # we can simply return, as we've already processed
	    # information for this databaseId

	    return;

	}

    }

    # we haven't see this databaseId before, so process the data

    my @aliases = split(/\|/, $aliases);

    my %seen; # sometimes an alias will be the same as the standard name

    foreach my $name ($databaseId, $standardName, @aliases){

        # here, we simply store, in case sensitive fashion, a mapping
        # of the name to databaseId.  Later, this map will be
        # modified, so it only contains those names where the case
        # sensitive version is unique.  We need this map to fulfill
        # the API requirements that if databaseIdByName() is called
        # with a name that is ambiguous, but the casing is unique,
        # then it will correctly determine the casing match

	$self->{$kNameToIdMapSensitive}{$name} = $databaseId;

	my $ucName = uc($name); # cache uppercased version for efficiency

	# occasionally, a standard name is also listed in the aliases,
	# so we will skip the name if we've already seen it.

	# note that for now, we are doing this case sensitively - it
	# is possible that a gene is referred to by the same name
	# twice but with different casing - however, if those are the
	# only times that those particular versions are seen, then
	# they will still be treated unambiguously.

	next if exists ($seen{$name});

	# let's keep a count of every time a name with the same casing
	# is seen, across all genes

	$self->{$kNameToCount}{$name}++;

	# now we have to deal with the name, depending on whether we
	# newly determine it is ambiguous, whether we already know
	# that name is ambiguous, or whether (so far) the name appears
	# to be unique

	# for something to be newly ambiguous, the case insensitive
	# version of its name must have been seen associated with some
	# other database id already.

	# if the case insensitive version of the name has already been
	# seen with the same database id, it is still not ambiguous

	if (exists $self->{$kNameToIdMapInsensitive}{$ucName} && $self->{$kNameToIdMapInsensitive}{$ucName} ne $databaseId){

	    # so record what it maps to

	    # current databaseId

	    push (@{$self->{$kAmbiguousNames}{$ucName}}, $databaseId);
	    
	    # and previously seen databaseId

	    push (@{$self->{$kAmbiguousNames}{$ucName}}, $self->{$kNameToIdMapInsensitive}{$ucName});

	    # and now delete the previously seen databaseId from the unambiguous mapping

	    delete $self->{$kNameToIdMapInsensitive}{$ucName};

	}elsif (exists $self->{$kAmbiguousNames}{$ucName}){ # we already know it's ambiguous

	    # so add in this new databaseId

	    push (@{$self->{$kAmbiguousNames}{$ucName}}, $databaseId);

	}else{ # otherwise simply map it unambiguously for now, as we haven't see the name before

	    $self->{$kNameToIdMapInsensitive}{$ucName} = $databaseId;

	}

	$seen{$name} = undef; # remember that we've seen the name for this row

    }

    # now we need to record some useful mappings

    # map databaseId and standardName to each other - these should
    # always be unique when treated case sensitively

    $self->{$kIdToStandardName}{$databaseId}   = $standardName; # record the standard name for the database id
    $self->{$kStandardNameToId}{$standardName} = $databaseId;   # also make the reverse look up

    # Now map upper cased versions of the databaseId and name to their original form
    # These are not guaranteed to be unique, so we use arrays instead

    push (@{$self->{$kUcIdToId}{uc($databaseId)}},             $databaseId);
    push (@{$self->{$kUcStdNameToStdName}{uc($standardName)}}, $standardName);

}

############################################################################
sub __storeGOID{
############################################################################
# This private method stores a GOID for a given databaseId, on a per
# aspect basis, in a hash.
#
# Usage:
#
#    $self->__storeGOID($databaseId, $goid, $aspect);
#

    my ($self, $databaseId, $goid, $aspect) = @_;

    $self->{$kGoids}{$databaseId}{$aspect}{$goid} = undef;

}

=pod

=head1 Public instance methods

=head1 Some methods dealing with ambiguous names

Because there are many names by which an annotated entity may be
referred to, that are non-unique, there exist a set of methods for
determining whether a name is ambiguous, and to what database
identifiers such ambiguous names may refer.

Note, that the AnnotationParser is now case insensitive, but with some
caveats.  For instance, you can use 'cdc6' to retrieve data for CDC6.
However, This if gene has been referred to as abc1, and another
referred to as ABC1, then these are treated as different, and
unambiguous.  However, the text 'Abc1' would be considered ambiguous,
because it could refer to either.  On the other hand, if a single gene
is referred to as XYZ1 and xyz1, and no other genes have that name (in
any casing), then Xyz1 would still be considered unambiguous.

=cut

##############################################################################
sub nameIsAmbiguous{
##############################################################################

=pod

=head2 nameIsAmbiguous

This public method returns a boolean to indicate whether a name is
ambiguous, i.e. whether the name might map to more than one entity (and
therefore more than one databaseId).  

NB: API change:

nameIsAmbiguous is now case insensitive - that is, if there is a name
that is used twice using different casing, that will be treated as
ambiguous.  Previous versions would have not treated these as
ambiguous.  In the case that a name is provided in a certain casing,
which was encountered only once, then it will be treated as
unambiguous.  This is the price of wanting a case insensitive
annotation parser...

Usage:

    if ($annotationParser->nameIsAmbiguous($name)){

        do something useful....or not....

    }

=cut

    my ($self, $name) = @_;

    die "You must supply a name to nameIsAmbiguous" if !defined ($name);

    # a name might appear in the hash of ambiguous names - however,
    # it is possible that the provided name matches the case of one of
    # the provided versions exactly, and thus may not be ambiguous

    # of course, it is also possible that there were actually more than
    # one copy of that alias, with exactly the same casing, which would 
    # be ambiguous

    # thus, we need to find out whether the provided name matches the case
    # of a something exactly, which refers to only one entity

    # a name being ambiguous boils down to whether it has been seen
    # more than once in that exact case, or in the case that it has
    # not been seen at all in that exact case, whether it is ambiguous
    # in upper case form.

    my $isAmbiguous;

    if (!exists $self->{$kNameToCount}{$name}){

	# we haven't seen this casing at all, so see if it's ambiguous
	# in the uppercased version

	$isAmbiguous = exists $self->{$kAmbiguousNames}{uc($name)};
	
    }elsif ($self->{$kNameToCount}{$name} > 1){

	# we've seen this exact casing more than once, so it has to be
	# ambiguous

	$isAmbiguous = 1;

    }else{

	# it must only have ever been seen once in this exact casing, 
	# so it's unambiguous

	$isAmbiguous = 0;

    }

    return $isAmbiguous;

}

############################################################################
sub databaseIdsForAmbiguousName{
############################################################################
=pod

=head2 databaseIdsForAmbiguousName

This public method returns an array of database identifiers for an
ambiguous name.  If the name is not ambiguous, an empty list will be
returned.

NB: API change:

databaseIdsForAmbiguousName is now case insensitive - that is, if
there is a name that is used twice using different casing, that will
be treated as ambiguous.  Previous versions would have not treated
these as ambiguous.  However, if the name provided is of the exact
casing as a name that appeared only once with that exact casing, then
it is treated as unambiguous. This is the price of wanting a case
insensitive annotation parser...

Usage:

    my @databaseIds = $annotationParser->databaseIdsForAmbiguousName($name);

=cut

    my ($self, $name) = @_;

    die "You must supply a name to databaseIdsForAmbiguousName" if !defined ($name);
    
    if ($self->nameIsAmbiguous($name)){
	
	return @{$self->{$kAmbiguousNames}{uc($name)}};

    }else{

	return ();

    }

}

############################################################################
sub ambiguousNames{
############################################################################
=pod

=head2 ambiguousNames

This method returns an array of names, which from the annotation file
have been deemed to be ambiguous.

Note - even though we have made the annotation parser case
insensitive, if something appeared in the annotations file as BLAH1
and blah1, we would not deem either of these to be ambiguous.
However, if it appeared as blah1 twice, referring to two different
genes, then blah1 would be ambiguous.

Usage:

    my @ambiguousNames = $annotationParser->ambiguousNames();

=cut

    my $self = shift;

    # we can simply generate a list of case-sensitive names that have
    # appeared more than once - we'll cache them so they don't have to
    # be recalculated in the event that they're asked for again

    if (!exists ($self->{$kAmbiguousNamesSensitive})){

	my @names;

	foreach my $name (keys %{$self->{$kNameToCount}}){

	    push(@names, $name) if ($self->{$kNameToCount}{$name} > 1);

	}

	$self->{$kAmbiguousNamesSensitive} = \@names;

    }

    return @{$self->{$kAmbiguousNamesSensitive}};

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
not recognized, then undef will be returned. In the case that a
databaseId is ambiguous (for instance the same databaseId exists but
with different casings) then if the supplied database id matches the
exact case of one of those supplied, then that is the one it will be
treated as.  In the case where the databaseId matches none of the
possibilities by case, then a fatal error will occur, because the
provided databaseId was ambiguous.

Usage:

    my $goidsRef = $annotationParser->goIdsByDatabaseId(databaseId => $databaseId,
							aspect     => <P|F|C>);

=cut

    my ($self, %args) = @_;

    my $aspect     = $args{'aspect'}     || $self->_handleMissingArgument(argument => 'aspect');
    my $databaseId = $args{'databaseId'} || $self->_handleMissingArgument(argument => 'databaseId');

    my $mappedId; # will store the id as listed in the annotations file

    if (exists $self->{$kUcIdToId}{uc($databaseId)}){ # we recognize it

	if (scalar (@{$self->{$kUcIdToId}{uc($databaseId)}}) == 1){

	    # it's unambiguous

	    $mappedId = $self->{$kUcIdToId}{uc($databaseId)}[0];

	}else{

	    # it may be ambiguous, but we'll check to see if the provided one
	    # is of exactly the correct case

	    foreach my $id (@{$self->{$kUcIdToId}{uc($databaseId)}}){
		
		if ($databaseId eq $id){ # we have a match

		    $mappedId = $id;
		    last;

		}

	    }

	    if (!defined $mappedId){

		# we got no perfect match, so it's ambiguous, and we die

		die "$databaseId is ambiguous as a databaseId, and could be used to refer to one of:\n\n".
		    join("\n", @{$self->{$kUcIdToId}{uc($databaseId)}});

	    }

	}

    }else{ # we don't recognize it
	
	return ; # note return here

    }

    # if we get here, then we have a recognized, and unambiguous database id 

    return  $self->_goIdsByMappedDatabaseId(databaseId => $mappedId,
					    aspect     => $aspect);

}

############################################################################
sub _goIdsByMappedDatabaseId{
############################################################################
# This protected method returns a reference to an array of GOIDs that
# are associated with the supplied databaseId for a specific aspect.
# If no annotations are associated with that databaseId in that
# aspect, then a reference to an empty array will be returned.  If the
# databaseId is not recognized, then undef will be returned.  The
# supplied databaseId must NOT be ambiguous, i.e. it must be a real
# databaseId known to exist.  If it is possibly ambiguous, use the
# goIdsByDatabaseId method instead.
#
# Usage:
#
#    my $goidsRef = $annotationParser->_goIdsByMappedDatabaseId(databaseId => $databaseId,
#							        aspect     => <P|F|C>);


    my ($self, %args) = @_;

    my $aspect     = $args{'aspect'}     || $self->_handleMissingArgument(argument => 'aspect');
    my $mappedId   = $args{'databaseId'} || $self->_handleMissingArgument(argument => 'databaseId');

    if (exists $self->{$kGoids}{$mappedId}{$aspect}){ # it has annotations

	return [keys %{$self->{$kGoids}{$mappedId}{$aspect}}];

    }else{ # it has no annotations
	    
	return []; # reference to empty array

    }

}

############################################################################
sub goIdsByStandardName{
############################################################################
=pod

=head2 goIdsByStandardName

This public method returns a reference to an array of GOIDs that are
associated with the supplied standardName for a specific aspect.  If
no annotations are associated with the entity with that standard name
in that aspect, then a reference to an empty list will be returned.
If the supplied name is not used as a standard name, then undef will
be returned.  In the case that the supplied standardName is ambiguous
(for instance the same standardName exists but with different casings)
then if the supplied standardName matches the exact case of one of
those supplied, then that is the one it will be treated as.  In the
case where the standardName matches none of the possibilities by case,
then a fatal error will occur, because the provided standardName was
ambiguous.

Usage:

    my $goidsRef = $annotationParser->goIdsByStandardName(standardName =>$standardName,
                                                          aspect       =><P|F|C>);

=cut

    my ($self, %args) = @_;

    my $aspect       = $args{'aspect'}       || $self->_handleMissingArgument(argument => 'aspect');
    my $standardName = $args{'standardName'} || $self->_handleMissingArgument(argument => 'standardName');

    # now we have to determine if the standardName is ambiguous or not

    # first, return if there is no standard name for the supplied string

    return undef if !exists $self->{$kUcStdNameToStdName}{uc($standardName)};

    # now see if we have 1 or more mappings

    my $mappedName;

    if (scalar @{$self->{$kUcStdNameToStdName}{uc($standardName)}} == 1){

	# we have a single mapping

	$mappedName = $self->{$kUcStdNameToStdName}{uc($standardName)}[0];

    }else{

	# there's more than one, so see if the case matched exactly

	foreach my $name (@{$self->{$kUcStdNameToStdName}{uc($standardName)}}){

	    if ($name eq $standardName){

		$mappedName = $name;
		last;

	    }

	}

	if (!defined $mappedName){

	    # we got no perfect match, so it's ambiguous, and we die

	    die "$standardName is ambiguous as a standardName, and could be used to refer to one of:\n\n".
		    join("\n", @{$self->{$kUcStdNameToStdName}{uc($standardName)}});

	}

    }

    # now we're here, we know we have a mapped standard name, which
    # must thus map to a databaseId

    my $databaseId = $self->_databaseIdByMappedStandardName($mappedName);

    return $self->_goIdsByMappedDatabaseId(databaseId => $databaseId,
					   aspect     => $aspect);

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
parser.  In the event that a name is provided that is ambiguous
because of case, if it matches exactly the case of one of the possible
matches, it will be treated unambiguously.

Usage:

    my $goidsRef = $annotationParser->goIdsByName(name   => $name,
						  aspect => <P|F|C>);

=cut

    my ($self, %args) = @_;

    my $aspect = $args{'aspect'} || $self->_handleMissingArgument(argument => 'aspect');
    my $name   = $args{'name'}   || $self->_handleMissingArgument(argument => 'name');

    die "You have supplied an ambiguous name to goIdsByName" if ($self->nameIsAmbiguous($name));

    # if we get here, the name is not ambiguous, so it's safe to call
    # databaseIdByName

    my $databaseId = $self->databaseIdByName($name);

    return undef if !defined $databaseId; # there is no such name

    # we should have a databaseId in the correct casing now

    return $self->_goIdsByMappedDatabaseId(databaseId => $databaseId,
					   aspect     => $aspect);

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
insensitive annotation parser.  In the event that a name is provided
that is ambiguous because of case, if it matches exactly the case of
one of the possible matches, it will be treated unambiguously.

Usage:

    my $standardName = $annotationParser->standardNameByDatabaseId($databaseId);

=cut

    my ($self, $databaseId) = @_;

    die "You must supply a databaseId to standardNameByDatabaseId" if !defined ($databaseId);

    # first return if there is no databaseId for the supplied string

    return undef if (!exists $self->{$kUcIdToId}{uc($databaseId)});

    # now, check whether it's ambiguous as a databaseId

    my $mappedId;

    if (scalar(@{$self->{$kUcIdToId}{uc($databaseId)}}) == 1){

	# we have a single mapping

	$mappedId = $self->{$kUcIdToId}{uc($databaseId)}[0];

    }else{

	# there's more than one, so see if the provided case matches
	# exactly one of them

	foreach my $id (@{$self->{$kUcIdToId}{uc($databaseId)}}){

	    if ($databaseId eq $id){

		$mappedId = $id;
		last;

	    }

	}

	if (!defined $mappedId){

	    # we got no perfect match, so it's ambiguous, and we die

	    die "$databaseId is ambiguous as a databaseId, and could be used to refer to one of:\n\n".
		join("\n", @{$self->{$kUcIdToId}{uc($databaseId)}});

	}

    }


    return ($self->{$kIdToStandardName}{$mappedId});

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
insensitive annotation parser.  In the event that a name is provided
that is ambiguous because of case, if it matches exactly the case of
one of the possible matches, it will be treated unambiguously.

Usage:

    my $databaseId = $annotationParser->databaseIdByStandardName($standardName);

=cut

    my ($self, $standardName) = @_;

    die "You must supply a standardName to databaseIdByStandardName" if !defined ($standardName);

    # first return if there is no standard name for the supplied string

    return undef if (!exists $self->{$kUcStdNameToStdName}{uc($standardName)});

    # now see if it's ambiguous or not

    my $mappedStandardName;

    if (scalar(@{$self->{$kUcStdNameToStdName}{uc($standardName)}}) == 1){

	# it's not ambiguous

	$mappedStandardName = $self->{$kUcStdNameToStdName}{uc($standardName)}[0];

    }else{

	# there's more than one, so see if the supplied name matches
	# the case of one of them exactly

	foreach my $name (@{$self->{$kUcStdNameToStdName}{uc($standardName)}}){

	    if ($standardName eq $name){

		$mappedStandardName = $name;
		last;

	    }

	}

	if (!defined $mappedStandardName){

	    die "$standardName is ambiguous as a standard name, and could be used to refer to one of:\n\n".
		join("\n", @{$self->{$kUcStdNameToStdName}{uc($standardName)}});

	}

    }	

    return ($self->{$kStandardNameToId}{$standardName});

}

############################################################################
sub _databaseIdByMappedStandardName{
############################################################################
# This protected method returns the database id for a standard name that is
# guaranteed to be non-ambiguous, and in the correct casing
#
# Usage:
#
#    my $databaseId = $annotationParser->_databaseIdByMappedStandardName($standardName);
#

    my ($self, $standardName) = @_;

    die "You must supply a standardName to _databaseIdByMappedStandardName" if !defined ($standardName);

    return ($self->{$kStandardNameToId}{$standardName});

}

############################################################################
sub databaseIdByName{
############################################################################
=pod

=head2 databaseIdByName

This method returns the database id for any identifier for a gene
(e.g. by databaseId itself, by standard name, or by alias).  If the
used name is ambiguous, then the program will die.  Thus clients
should call the nameIsAmbiguous() method, prior to using this method.
If the name does not map to any databaseId, then undef will be
returned.

NB: API change

databaseIdByName is now case insensitive - that is, if there is a name
that is used twice using different casing, that will be treated as
ambiguous.  Previous versions would have not treated these as
ambiguous.  This is the price of wanting a case insensitive annotation
parser.  In the event that a name is provided that is ambiguous
because of case, if it matches exactly the case of one of the possible
matches, it will be treated unambiguously.

Usage:

    my $databaseId = $annotationParser->databaseIdByName($name);

=cut

    my ($self, $name) = @_;

    die "You must supply a name to databaseIdByName" if !defined ($name);

    die "You have supplied an ambiguous name to databaseIdByName" if ($self->nameIsAmbiguous($name));

    # give them the case insensitive unique map, or if there is none,
    # then the case sensitive version

    my $databaseId = $self->{$kNameToIdMapInsensitive}{uc($name)} || $self->{$kNameToIdMapSensitive}{$name};

    return $databaseId;

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
parser.

Usage:

    my $standardName = $annotationParser->standardNameByName($name);

=cut

    my ($self, $name) = @_;

    die "You must supply a name to standardNameByName" if !defined ($name);

    die "You have supplied an ambiguous name to standardNameByName" if ($self->nameIsAmbiguous($name));

    my $databaseId = $self->databaseIdByName($name);

    if (defined $databaseId){

	return $self->{$kIdToStandardName}{$databaseId};

    }else{

	return undef;
	
    }

}

=pod

=head1 Other methods relating to names

=cut

############################################################################
sub nameIsStandardName{
############################################################################
=pod

=head2 nameIsStandardName

This method returns a boolean to indicate whether the supplied name is
used as a standard name.

NB : API change.

This is now case insensitive.  If you provide abC1, and ABc1 is a
standard name, then it will return true.

Usage :

    if ($annotationParser->nameIsStandardName($name)){

	# do something

    }

=cut

    my ($self, $name) = @_;

    die "You must supply a name to nameIsStandardName" if !defined($name);

    return exists ($self->{$kUcStdNameToStdName}{uc($name)});

}

############################################################################
sub nameIsDatabaseId{
############################################################################
=pod

=head2 nameIsDatabaseId

This method returns a boolean to indicate whether the supplied name is
used as a database id.

NB : API change.

This is now case insensitive.  If you provide abC1, and ABc1 is a
database id, then it will return true.

Usage :

    if ($annotationParser->nameIsDatabaseId($name)){

	# do something

    }

=cut


    my ($self, $databaseId) = @_;

    die "You must supply a potential databaseId to nameIsDatabaseId" if !defined($databaseId);

    return exists ($self->{$kUcIdToId}{uc($databaseId)});

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

    if ($annotationParser->nameIsAnnotated(name => $name)){

	# blah

    }

or:

    if ($annotationParser->nameIsAnnotated(name   => $name,
					   aspect => $aspect)){

	# blah

    }


=cut

    my ($self, %args) = @_;

    my $name = $args{'name'} || die "You must supply a name to nameIsAnnotated";
    
    my $aspect = $args{'aspect'};

    my $isAnnotated = 0;

    my $ucName = uc($name);

    if (!defined ($aspect)){ # if there's no aspect

	$isAnnotated = (exists ($self->{$kNameToIdMapInsensitive}{$ucName}) || exists ($self->{$kAmbiguousNames}{$ucName}));
	
    }else{

	if ($self->nameIsDatabaseId($name) && @{$self->goIdsByDatabaseId(databaseId => $name,
									 aspect     => $aspect)}){

	    $isAnnotated = 1;

	}elsif ($self->nameIsStandardName($name) && @{$self->goIdsByStandardName(standardName => $name,
										 aspect       => $aspect)}){

	    $isAnnotated = 1;

	}elsif (!$self->nameIsAmbiguous($name)){

	    my $goidsRef = $self->goIdsByName(name   => $name,
					      aspect => $aspect);

	    if (defined $goidsRef && @{$goidsRef}){

		$isAnnotated = 1;

	    }

	}else { # MUST be an ambiguous name, that's not used as a standard name
	
	    foreach my $databaseId ($self->databaseIdsForAmbiguousName($name)){

		if (@{$self->goIdsByDatabaseId(databaseId => $name,
					       aspect     => $aspect)}){

		    $isAnnotated = 1;
		    last; # as soon as we know, we can finish

		}

	    }

	}

    }

    return $isAnnotated;

}

=pod

=head1 Other public methods

=cut

############################################################################
sub databaseName{
############################################################################
=pod

=head2 databaseName

This method returns the name of the annotating authority from the file
that was supplied to the constructor.

Usage :

    my $databaseName = $annotationParser->databaseName();

=cut

    my $self = shift;

    return $self->{$kDatabaseName};

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

    my $numAnnotatedGenes = $annotationParser->numAnnotatedGenes();

    my $numAnnotatedGenes = $annotationParser->numAnnotatedGenes($aspect);

=cut

    my ($self, $aspect) = @_;

    if (defined ($aspect)){

	return $self->{$kNumAnnotatedGenes}{$aspect};

    }else{

	return $self->{$kTotalNumAnnotatedGenes};

    }

}

############################################################################
sub allDatabaseIds{
############################################################################
=pod

=head2 allDatabaseIds

This public method returns an array of all the database identifiers

Usage:

    my @databaseIds = $annotationParser->allDatabaseIds();

=cut

    my $self = shift;

    return keys (%{$self->{$kIdToStandardName}});

}

############################################################################
sub allStandardNames{
############################################################################
=pod

=head2 allStandardNames

This public method returns an array of all standard names.

Usage:

    my @standardNames = $annotationParser->allStandardNames();

=cut

    my $self = shift;

    return keys(%{$self->{$kStandardNameToId}});

}

=pod

=head1 Methods to do with files

=cut

############################################################################
sub file{
############################################################################
=pod

=head2 file

This method returns the name of the file that was used to instantiate
the object.

Usage:

    my $file = $annotationParser->file;

=cut

    return $_[0]->{$kFileName};

}

############################################################################
sub serializeToDisk{
############################################################################
=pod

=head2 serializeToDisk

This public method saves the current state of the Annotation Parser
Object to a file, using the Storable package.  The data are saved in
network order for portability, just in case.  The name of the object
file is returned.  By default, the name of the original file will be
used to make the name of the object file (including the full path from
where the file came), or the client can instead supply their own
filename.

Usage:

    my $fileName = $annotationParser->serializeToDisk;

    my $fileName = $annotationParser->serializeToDisk(filename => $filename);

=cut

    my ($self, %args) = @_;

    my $fileName;

    if (exists ($args{'filename'})){ # they supply their own filename

	$fileName = $args{'filename'};

    }else{ # we build a name from the file used to instantiate ourselves

	$fileName = $self->file;
	
	if ($fileName !~ /\.obj$/){ # if we weren't instantiated from an object
	    
	    $fileName .= ".obj"; # add a .obj suffix to the name
	    
	}

    }

    nstore ($self, $fileName) || die "$PACKAGE could not serialize itself to $fileName : $!";

    return ($fileName);

}

1; # to keep perl happy

############################################################################
#               MORE P O D   D O C U M E N T A T I O N                     #
############################################################################

=pod

=head1 Modifications

CVS info is listed here:

 # $Author: sherlock $
 # $Date: 2008/05/13 23:06:16 $
 # $Log: AnnotationParser.pm,v $
 # Revision 1.35  2008/05/13 23:06:16  sherlock
 # updated to fix bug with querying with a name that was unambiguous when
 # taking its casing into account.
 #
 # Revision 1.34  2007/03/18 03:09:05  sherlock
 # couple of PerlCritic suggested improvements, and an extra check to
 # make sure that the cardinality between standard names and database ids
 # is 1:1
 #
 # Revision 1.33  2006/07/28 00:02:14  sherlock
 # fixed a couple of typos
 #
 # Revision 1.32  2004/07/28 17:12:10  sherlock
 # bumped version
 #
 # Revision 1.31  2004/07/28 17:03:49  sherlock
 # fixed bugs when calling goidsByDatabaseId instead of goIdsByDatabaseId
 # on lines 1592 and 1617 - thanks to lfriedl@cs.umass.edu for spotting this.
 #
 # Revision 1.30  2003/11/26 18:44:28  sherlock
 # finished making all the changes that were required to make it case
 # insensitive, and modified POD accordingly.  It appears to all work as
 # expected...
 #
 # Revision 1.29  2003/11/22 00:05:05  sherlock
 # made a very large number of changes to make much of it
 # case-insensitive, such that using CDC6 or cdc6 amounts to the same
 # query, as long as both versions of that name don't exist in the
 # annotations file.  Still needs a little work to allow names that are
 # potentially ambiguous to be not ambiguous, if their casing matches
 # exactly one form of the name that has been seen.  Have started to
 # update test suite to check all the case insensitive stuff, but is not
 # yet finished.
 #
 #

=head1 AUTHORS

Elizabeth Boyle, ell@mit.edu

Gavin Sherlock,  sherlock@genome.stanford.edu

=cut
