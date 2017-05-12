#!/usr/bin/perl -w

#
# Copyright (C) 2007-2008 Alex Linke <alinke@lingua-systems.com>
# Copyright (C) 2009-2016 Lingua-Systems Software GmbH
# Copyright (C) 2016 Netzum Sorglos, Lingua-Systems Software GmbH
#

use strict;
use warnings;

require 5.008;

use XML::LibXML;
use Data::Dumper;
use Getopt::Long;

my $VERSION = '0.6';

my %tables;

# set default options
my %opt = (
    output  => "tables.dump",
    verbose => 0,
);

# parse commandline options
show_help(1)
  unless GetOptions(
    "output|o=s" => \$opt{output},
    "verbose|v"  => \$opt{verbose},
    "help|h"     => \$opt{help}
  );
show_help(1) if scalar(@ARGV) == 0;    # No XML file(s) given
show_help(0) if $opt{help};

my $xmlparser = new XML::LibXML();

# Set parser options
$xmlparser->pedantic_parser(1);
$xmlparser->validation(1);
$xmlparser->expand_entities(1);
$xmlparser->keep_blanks(1);
$xmlparser->line_numbers(1);

# Treat everything else in @ARGV as a filename
foreach my $file (@ARGV) {
    print "Parsing $file..." if $opt{verbose};

    my %counts = ( rules => 0, contexts => 0 );

    my $ds;

    my $doc = $xmlparser->parse_file($file)
      or die "Error parsing $file: $!\n";

    # Retrieve meta-documentation from XML document first
    foreach my $meta (qw/name desc reverse/) {
        my @nodes = $doc->findnodes("/translit/$meta");

        die "#/translit/$meta != 1" if ( scalar(@nodes) != 1 );

        $ds->{$meta} = $nodes[0]->to_literal();
    }

    # Perform some basic meta data checks
    die "Name undefined.\n"          unless $ds->{name};
    die "Description undefined.\n"   unless $ds->{desc};
    die "Reversibility undefined.\n" unless $ds->{reverse};

    # Check <reverse> tag contains valid data.
    # TODO: move this to the DTD
    die "Reversibility: '$ds->{reverse}' -- Should be 'true' or 'false'.\n"
      unless $ds->{reverse} =~ /^(true|false)$/;

    # Set the table's identifier
    $ds->{id} = lc( $ds->{name} );
    $ds->{id} =~ s/\s/_/g;

    # Retrieve all rules, extract their data and store it to an appropriate
    # data structure
    foreach my $rule ( $doc->findnodes("/translit/rules/rule") ) {
        my @nodes;
        my $rule_ds;

        # Retrieve "from" and "to" literals
        foreach my $n (qw/from to/) {
            @nodes = $rule->findnodes("./$n");

            die "#/translit/rules/rules/$n != 1 "
              . "(at line "
              . $rule->line_number() . ")\n"
              if ( scalar(@nodes) != 1 );

            $rule_ds->{$n} = $nodes[0]->to_literal();
        }

        # Retrieve rule's "context"
        @nodes = $rule->findnodes("./context");

        die "#/translit/rules/rule/context > 1 "
          . "(at line "
          . $rule->line_number() . ")\n"
          if ( scalar(@nodes) > 1 );

        # Process rule's "context" if necessary
        if ( scalar(@nodes) ) {
            foreach my $context (qw/before after/) {
                @nodes = $rule->findnodes("./context/$context");

                die "#/translit/rules/rule/context/$context > 1 "
                  . "(at line "
                  . $rule->line_number() . ")\n"
                  if ( scalar(@nodes) > 1 );

                # Copy the context to the rule's data structure
                if ( scalar(@nodes) ) {
                    $rule_ds->{context}->{$context} = $nodes[0]->to_literal();
                }
            }

            $counts{contexts}++;
        }

        $counts{rules}++;

        die $rule_ds->{name} . ": from==to -> " . $rule_ds->{from} . "\n"
          if ( $rule_ds->{from} eq $rule_ds->{to} );

        push @{ $ds->{rules} }, $rule_ds;
    }

    # Copy transliteration structure over to the final hash
    $tables{ $ds->{id} } = $ds;

    print " ($ds->{id}: rules=$counts{rules}, contexts=$counts{contexts})\n"
      if $opt{verbose};

    undef($ds);    # free memory
}

# Configure Data::Dumper
my $dumper = new Data::Dumper( [ \%tables ], [qw/*tables/] );
$dumper->Purity(0);
$dumper->Useqq(1);
$dumper->Indent(1);

# Dump the table(s) to disk
open FH, ">$opt{output}" or die "$opt{output}: $!\n";
print FH $dumper->Dump();
close(FH);

print scalar( keys(%tables) ),
  " transliteration table(s) dumped to $opt{output}.\n"
  if $opt{verbose};

sub show_help {
    my $retval = shift();

    print STDERR
      "xml2dump v$VERSION -- Copyright 2007-2008 by Alex Linke ",
      "<alinke\@lingua-systems.com>\n\n",
      "usage: $0  [-v -h]  -o FILE  XML-FILE(s)\n\n",
      "\t--output  -o  FILE     set output file (default: transtbl.dump)\n",
      "\t--verbose -v           be verbose\n",
      "\t--help    -h           show this help\n";

    exit($retval);
}

# vim: set ft=perl sw=4 sts=4 ts=4 ai et:
