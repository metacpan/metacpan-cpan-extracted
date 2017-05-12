#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Test;
BEGIN { plan tests => 68 };

# File       : GO-AnnotationProvider-AnnotationParser.t
# Author     : Gavin Sherlock
# Date Begun : March 9th 2002

# $Id: GO-AnnotationProvider-AnnotationParser.t,v 1.4 2007/03/18 01:37:14 sherlock Exp $

# This file forms a set of tests for the
# GO::AnnotationProvider::AnnotationParser class

use GO::AnnotationProvider::AnnotationParser;

# 'make test' command will be run from one directory up

my $associationsFile = "t/gene_association.sgd";

my @methods = qw (nameIsAmbiguous databaseIdsForAmbiguousName
		  ambiguousNames goIdsByDatabaseId goIdsByStandardName
		  goIdsByName standardNameByDatabaseId
		  databaseIdByStandardName databaseIdByName
		  standardNameByName nameIsStandardName
		  nameIsDatabaseId nameIsAnnotated databaseName
		  numAnnotatedGenes allDatabaseIds allStandardNames
		  file serializeToDisk);

my $annotations = GO::AnnotationProvider::AnnotationParser->new(annotationFile => $associationsFile);

# check we're the right kind of object

ok($annotations->isa("GO::AnnotationProvider::AnnotationParser"));

ok($annotations->isa("GO::AnnotationProvider"));

# check the object returns a code reference when asked it it can do a
# method that should exist

foreach my $method (@methods){

    ok(ref($annotations->can($method)), "CODE");

}

# now we want to check some of the attributes

ok($annotations->file, $associationsFile);

ok(scalar($annotations->allDatabaseIds), 6470); # this number has been checked

ok(scalar($annotations->allDatabaseIds), scalar($annotations->allStandardNames));

ok(scalar($annotations->allDatabaseIds), $annotations->numAnnotatedGenes);

# now lets check actin (ACT1, S000001855) - should be annotated directly to the following 8 components

my %components = ("GO:0000123" => undef,
		  "GO:0000142" => undef,
		  "GO:0000812" => undef,
		  "GO:0005884" => undef,
		  "GO:0030479" => undef, 
		  "GO:0030482" => undef,
		  "GO:0031011" => undef,
		  "GO:0043189" => undef);

# NOTE - should think about changing API of goIdsByDatabaseId to
# return an array, rather than a reference to one....

my $goidsRef = $annotations->goIdsByDatabaseId(databaseId => "S000001855",
					       aspect     => 'C');

ok(scalar(@{$goidsRef}), scalar keys %components);

foreach my $goid (@{$goidsRef}){

    ok(exists($components{$goid})); # should be in the ones we know

}

# now look at TUB1 functions - should be annotated to a single node

my %functions = ("GO:0005200" => undef);

$goidsRef = $annotations->goIdsByDatabaseId(databaseId => "S000004550",
					    aspect     => 'F');

ok(scalar(@{$goidsRef}), scalar keys %functions);

ok(exists($functions{$goidsRef->[0]}));

# now check processes for CDC8 - should be annotated to 7 nodes

my %processes = ("GO:0006227" => undef,
		 "GO:0006233" => undef,
		 "GO:0006235" => undef,
		 "GO:0006261" => undef,
		 "GO:0006276" => undef,
		 "GO:0006280" => undef,
		 "GO:0006281" => undef);

$goidsRef = $annotations->goIdsByDatabaseId(databaseId => "S000003818",
					    aspect     => 'P');

ok(scalar(@{$goidsRef}), scalar keys %processes);

foreach my $goid (@{$goidsRef}){

    ok(exists($processes{$goid})); # should be in the ones we know

}

# now check that all databaseIds are databaseIds

my @databaseIds = $annotations->allDatabaseIds;

my $isDatabaseId = 0;

foreach my $databaseId (@databaseIds){

    $isDatabaseId += $annotations->nameIsDatabaseId($databaseId);

}

ok($isDatabaseId, scalar(@databaseIds));

# now do the same for standard names

my @standardNames = $annotations->allStandardNames;

my $isStandardName = 0;

foreach my $standardName (@standardNames){

    $isStandardName += $annotations->nameIsStandardName($standardName);

}

ok($isStandardName, scalar(@standardNames));

# now check the ambiguous names

my @ambiguousNames = $annotations->ambiguousNames;

my $isAmbiguousName = 0;

foreach my $ambiguousName (@ambiguousNames){

    $isAmbiguousName += $annotations->nameIsAmbiguous($ambiguousName);

}

ok($isAmbiguousName, scalar(@ambiguousNames));

# now check some specific data

ok($annotations->nameIsDatabaseId("S000003818"));

ok($annotations->nameIsStandardName("ACT1"));

ok($annotations->nameIsAmbiguous("HAP1"));

ok(scalar($annotations->databaseIdsForAmbiguousName("HAP1")), 2);

# now we're going to do a set of tests with our fake file

my $fakeFile = "t/gene_association.test";

my $fakeAnnotations = GO::AnnotationProvider::AnnotationParser->new(annotationFile => $fakeFile);

# ALIAS1 is deliberately ambiguous

ok($fakeAnnotations->nameIsAmbiguous("ALIAS1"));

# now check its database ids

my %expectedIds = (DBID1 => undef,
		   DBID2 => undef,
		   DBID3 => undef);

# note, because it is case-insensitive, we'll use a different case

my @ids = $fakeAnnotations->databaseIdsForAmbiguousName("aLiAs1");

ok(scalar(@ids) == scalar(keys %expectedIds));

foreach my $id (@ids){

    ok(exists $expectedIds{$id});

}

# now check the sole goid for DBID1

ok($fakeAnnotations->goIdsByDatabaseId(databaseId => 'DBID1',
				       aspect     => 'C')->[0], 'GO:0005743');

# and now for dbid1

ok($fakeAnnotations->goIdsByDatabaseId(databaseId => 'dbid1',
				       aspect     => 'C')->[0], 'GO:1005743');


# now, dbid1 and DBID1 should not be ambiguous, if I use them
# with their correct casing

ok(!$fakeAnnotations->nameIsAmbiguous('DBID1'));

ok(!$fakeAnnotations->nameIsAmbiguous('dbid1'));

# but with mixed casing, it should be ambiguous

ok($fakeAnnotations->nameIsAmbiguous('DbId1'));

# now look at GENE4 - in any casing, it should be unambiguous

ok(!$fakeAnnotations->nameIsAmbiguous('GENE4'));

ok(!$fakeAnnotations->nameIsAmbiguous('gene4'));

ok(!$fakeAnnotations->nameIsAmbiguous('Gene4'));

# now look at GENE5 - three different casings should be unambiguous,
# but anything else should be ambiguous

ok(!$fakeAnnotations->nameIsAmbiguous('GENE5'));

ok(!$fakeAnnotations->nameIsAmbiguous('gene5'));

ok(!$fakeAnnotations->nameIsAmbiguous('Gene5'));

ok($fakeAnnotations->nameIsAmbiguous('GeNe5'));

=pod

=head1 Modifications

CVS info is listed here:

 # $Author: sherlock $
 # $Date: 2007/03/18 01:37:14 $
 # $Log: GO-AnnotationProvider-AnnotationParser.t,v $
 # Revision 1.4  2007/03/18 01:37:14  sherlock
 # various updates to the tests
 #
 # Revision 1.3  2003/11/26 18:48:56  sherlock
 # finished adding various tests that deal with case sensitivity issues
 # and ambiguity of gene names.  All tests appear to pass, finally!
 #
 # Revision 1.2  2003/11/22 00:07:01  sherlock
 # started adding tests to deal with a fake annotation file, and check
 # that the case insensitive stuff works.
 #
 # 

=cut
