#!/usr/bin/perl

# $Id: batchGOView.pl,v 1.7 2009/10/29 18:31:01 sherlock Exp $

# Date   : 4th December 2003
# Author : Gavin Sherlock

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
use diagnostics;
use warnings;

use CGI qw/:all :html3/;

use IO::File;

=head1 NAME

batchGOView.pl - batch processor for creating visual output from GO::TermFinder

=head1 SYNOPSIS

batchGoView.pl will read through a number of files, each containing a
list of genes, and will create for each one an html page with a
GO::View, such that you can graphically browse the results.  You need
to provide a .conf file, and then a list of files for processing, each
of which contain a list of genes.  An example .conf file exists in
this directory - edit as appropriate.

Usage:

batchGOView.pl <.conf_file> <file1> <file2> <file3> ... <fileN>

The following usage should give you some output, using the example
files:

batchGOView.pl GoView.conf genes.txt genes2.txt

An html file, batchGOView.html will be created, that will allow you to
browse the results from all of the input lists of genes in a simple
format.  A frame on the left will have a list of the files that were
input, and the frame on the right will display the results for the
clicked on link.

=cut

use GO::TermFinder;
use GO::AnnotationProvider::AnnotationParser;
use GO::OntologyProvider::OboParser;
use GO::View;
use GO::TermFinderReport::Html;
use GO::Utils::File    qw (GenesFromFile);
use GO::Utils::General qw (CategorizeGenes);

$|=1;

##################################################################################
sub Usage{
###################################################################################


    print <<USAGE;

This program takes a list of files, each of which contain a list of
genes, with one gene per line.  It will findTerms for the lists of
genes in each of the GO aspects, and then generate an html page with a
GO::View graphic that summarize the result.

It will use the first supplied argument as the configuration file, and
all subsequent files as ones containing lists of genes.

Usage:

batchGOView.pl <.conf_file> <file1> <file2> <file3> ... <fileN>

e.g.

batchGOView.pl GoView.conf genes.txt genes2.txt

USAGE

    exit;

}

# we need at least 2 arguments, a .conf file, and a file of input
# genes to test

&Usage if (@ARGV < 2);

my $confFile = shift;

my $conf = &ReadConfFile($confFile);

# now set up the objects we need

my $ontology = GO::OntologyProvider::OboParser->new(ontologyFile => $conf->{'ontologyFile'},
						    aspect       => $conf->{'aspect'});

my $annotation = GO::AnnotationProvider::AnnotationParser->new(annotationFile=>$conf->{'annotationFile'});

my @additionalArgs;

my @population;

if (exists $conf->{'population'} && defined $conf->{'population'}){

    # they have defined an input file containing genes from which the
    # listed genes were sampled

    @population = GenesFromFile($conf->{'population'});

    push(@additionalArgs, ('population', \@population));

    $conf->{'totalNumGenes'} = scalar(@population);

}else{

    $conf->{'totalNumGenes'} ||= $annotation->numAnnotatedGenes;

    push(@additionalArgs, ('totalNumGenes', $conf->{'totalNumGenes'}));

}

my $termFinder = GO::TermFinder->new(annotationProvider=> $annotation,
				     ontologyProvider  => $ontology,
				     aspect            => $conf->{'aspect'},
				     @additionalArgs);

my $report  = GO::TermFinderReport::Html->new();

&GenerateFrameset;

# now open an html file that will have a list of links for all the results

my $htmlFile = $conf->{'outDir'}.'batchGOViewList.html';

my $listFh = IO::File->new($htmlFile, q{>} )|| die "Cannot make $htmlFile : $!";

# go through each file

foreach my $file (@ARGV){
   
    print "Analyzing $file\n";

    # get the genes in the file

    my @genes = GenesFromFile($file);

    # now find terms

    my @pvalues = $termFinder->findTerms(genes        => \@genes,
					 calculateFDR => $conf->{'calculateFDR'});

    # now we hand these off to the GO::View module, to create the image etc.

    my $goView = GO::View->new(-ontologyProvider   => $ontology,
			       -annotationProvider => $annotation,
			       -termFinder         => \@pvalues,
			       -aspect             => $conf->{'aspect'},
			       -configFile         => $confFile,
			       -imageDir           => $conf->{'outDir'},
			       -imageLabel         => "Batch GO::View",
			       -nodeUrl            => $conf->{'goidUrl'},
			       -geneUrl            => $conf->{'geneUrl'},
			       -pvalueCutOff       => $conf->{'pvalueCutOff'});

    # We now want to get the image and map that has hopefully been
    # created by the GO::View module, so we can print it to our html
    # page

    my $imageFile;

    if ($goView->graph) {
	
	$imageFile = $goView->showGraph;
	
    }
    
    my $htmlFile = &GenerateHTMLFile($file, $goView->imageMap, \@pvalues,
				     scalar($termFinder->genesDatabaseIds), "Terms for $file"); 

    print $listFh a({-href   => $htmlFile,
		     -target => 'result'}, $htmlFile), br;

}

$listFh->close;

sub GenerateHTMLFile{

    my ($file, $map, $pvaluesRef, $numGenes, $title) = @_;

    # work out name of html file
    
    my $htmlFile = $file;

    # delete anything up to and including the last slash

    $htmlFile =~ s/.*\///;

    # delete anything following the last period

    $htmlFile =~ s/\..*//;

    # now add an html suffix

    $htmlFile .= ".html";

    my $fullHtmlFile = $conf->{'outDir'}.$htmlFile;

    my $htmlFh = IO::File->new($fullHtmlFile, q{>} )|| die "Cannot make $fullHtmlFile : $!";

    print $htmlFh start_html(-title=>$title);

    print $htmlFh center(h2($title)), hr;

    print $htmlFh $map if defined $map;

    my $numRows = $report->print(pvalues      => $pvaluesRef,
				 aspect       => $conf->{'aspect'},
				 numGenes     => $numGenes,
				 totalNum     => $conf->{'totalNumGenes'},
				 fh           => $htmlFh,
				 pvalueCutOff => $conf->{'pvalueCutOff'},
				 geneUrl      => $conf->{'geneUrl'},
				 goidUrl      => $conf->{'goidUrl'});

    if ($numRows == 0){

	print $htmlFh h4(font({-color=>'red'}),
			 center("There were no GO nodes exceeding the p-value cutoff of $conf->{'pvalueCutOff'} for the genes in $file."));

    }

    print $htmlFh end_html;

    $htmlFh->close;

    return ($htmlFile);

}

sub ReadConfFile{

    my $confFile = shift;

    my %conf;

    my $confFh = IO::File->new($confFile, q{<} )|| die "cannot open $confFile : $!";

    while (<$confFh>){

	next if /^\#/; # skip comment lines

	chomp;

	next if /^\s*$/; # skip blank lines, or those without content

	next unless /(.+) = (.+)/;

	my ($param, $value) = ($1, $2);

	$value =~ s/\s$//;

	$conf{$param} = $value;

    }

    $confFh->close;

    if (!exists $conf{'annotationFile'} || !defined $conf{'annotationFile'}){

	die "Your conf file must specify an annotation file entry.";

    }elsif (!exists $conf{'ontologyFile'} || !defined $conf{'ontologyFile'}){

	die "Your conf file must specify an ontology file entry.";

    }elsif (!exists $conf{'aspect'} || !defined $conf{'aspect'}){

	die "Your conf file must specify an aspect entry.";

    }

    if (!exists $conf{'totalNumGenes'} || !defined $conf{'totalNumGenes'}){

	$conf{'totalNumGenes'} = ""; # simply make it the empty string for now

    }

    if (!exists $conf{'outDir'} || !defined $conf{'outDir'}){

	$conf{'outDir'} = ""; # set to empty string for now

    }

    $conf{'geneUrl'} ||= "";
    $conf{'goidUrl'} ||= "";

    $conf{'pvalueCutOff'} ||= 1;

    $conf{'calculateFDR'} ||= 0;

    # now make sure that file paths are treated relative to the conf file

    my $confDir = "./"; # default

    if ($confFile =~ /(.+)\//){

	$confDir = $1."/"; # adjust if necessary

    }

    foreach my $file ($conf{'annotationFile'}, $conf{'ontologyFile'}, $conf{'outDir'}){

	# $file is an alias for the hash entry

	if ($file !~ /^\//){ # if it's not an absolute path

	    $file = $confDir.$file; # add the confDir on the front

	}

    }

    # return a reference to the hash

    return \%conf;

}

sub GenerateFrameset{

# start an index file that a user can use to browse the output data,
# using frames

    my $framesFile = $conf->{'outDir'}."batchGOView.html";

    my $framesFh = IO::File->new($framesFile, q{>} )|| die "Cannot create $framesFile : $!";

    print $framesFh frameset({-cols         => "100, *",
			      -marginheight => '0',
			      -marginwidth  => '0',
			      -frameborder  => '1',
			      -border       => '1'},
			  
			     frame({'-name'       => "list",
				    -src          => "batchGOViewList.html",
				    -marginwidth  => 0,
				    -marginheight => 0,
				    -border       => 1}),
		   
			     frame({'-name'       =>'result',
				    -marginwidth  => 0,
				    -marginheight => 0,
				    -border       => 1}));

    $framesFh->close;

    return;

}

=pod

=head1 AUTHOR

Gavin Sherlock

sherlock@genome.stanford.edu

=cut
