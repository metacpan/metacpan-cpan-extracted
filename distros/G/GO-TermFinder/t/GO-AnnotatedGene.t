#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Test;
BEGIN { plan tests => 17 };

# File       : GO-AnnotatedGene.t
# Author     : Gavin Sherlock
# Date Begun : March 9th 2002

# $Id: GO-AnnotatedGene.t,v 1.2 2007/03/18 01:37:14 sherlock Exp $

# This file forms a set of tests for the GO::AnnotatedGene class

use GO::AnnotatedGene;

my $databaseId   = "S0004660";
my $standardName = "AAC1";
my $type         = "gene";
my $productName  = "ADP/ATP translocator";
my @aliases      = ("YMRO56C");

my @methods      = qw (databaseId standardName type productName aliases);

my $annotatedGene = GO::AnnotatedGene->new(databaseId   => $databaseId,
					   standardName => $standardName,
					   type         => $type,
					   productName  => $productName,
					   aliases      => \@aliases);

# check object type

ok($annotatedGene->isa("GO::AnnotatedGene"));

# check the object returns a code reference when asked if it can do a
# method that should exist

foreach my $method (@methods){

    ok(ref($annotatedGene->can($method)), "CODE");

}

# check object attributes

ok($annotatedGene->databaseId,   $databaseId);

ok($annotatedGene->standardName, $standardName);

ok($annotatedGene->type,         $type);

ok($annotatedGene->productName,  $productName);

ok(($annotatedGene->aliases)[0], $aliases[0]);

ok(scalar($annotatedGene->aliases), scalar(@aliases));

# now test not passing in the optional arguments

$annotatedGene = GO::AnnotatedGene->new(databaseId   => $databaseId,
					standardName => $standardName,
					type         => $type);

ok($annotatedGene->productName, undef);

ok(scalar($annotatedGene->aliases), 0);

# now check that we throw an error with the appropriate message if we
# leave out a required argument

# leave out databaseId

eval {

    $annotatedGene = GO::AnnotatedGene->new(standardName => $standardName,
					    type         => $type);

};

ok($@ =~ /did not provide a value for the 'databaseId' argument/);

# leave out standardName

eval {

    $annotatedGene = GO::AnnotatedGene->new(databaseId   => $databaseId,
					    type         => $type);

};

ok($@ =~ /did not provide a value for the 'standardName' argument/);

# leave out type

eval {

    $annotatedGene = GO::AnnotatedGene->new(databaseId   => $databaseId,
					    standardName => $standardName);

};

ok($@ =~ /did not provide a value for the 'type' argument/);

