#!/usr/bin/perl

# Program: nodetool_parser.pl
# Purpose: parse command line arguments like Cassandra nodetool to build a mock object for testing
# Author: James Briggs
# Env: Perl5
# Date: 2014 09 25

use strict;
use diagnostics;

use Getopt::ApacheCommonsCLI qw(GetOptionsApacheCommonsCLI OPT_PREC_UNIQUE OPT_PREC_LEFT_TO_RIGHT OPT_PREC_RIGHT_TO_LEFT);

use Data::Dumper;

   my $DEBUG = 1;

  # input spec format is: "longest-option|(short-option)(:[fios])"

   my @spec = ("include-all-sstables|a",
               "column-family|cf:s",
               "compact|c",
               "in-dc|dc:s",
               "host|h:s",
               "hosts|in-host:s",
               "ignore|i",
               "local|in-local",
               "no-snapshot|ns",
               "parallel|par",
               "partitioner-range|pr",
               "port|p:i",
               "resolve-ip|r",
               "skip-corrupted|s",
               "tag|t:s",
               "tokens|T",
               "username|u:s",
               "password|pw:s",
               "start-token|st:s",
               "end-token|et:s",
   );

   my %opts; # output hash with tokenized long options and args

#   my %ambiguous = ( 'cf'  => 'column-family',
#                     'dc'  => 'in-dc',
#                     'et'  => 'end-token',
#                     'par' => 'parallel',
#                     'pr'  => 'partitioner-range',
#                     'pw'  => 'password',
#                     'st'  => 'start-token',
#   );       

   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, { DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 1, } , \&do_err) ||
      warn "$0: parsing error. see \$opts{__errors__} for a list, ";

   print Dumper(\%opts) if $DEBUG;

sub do_err {
   my ($option, $value) = @_;

   if (not defined $value or $value eq '') {
      print "Missing argument for option:$option\n";
   }
   else {
      print "Incorrect value, precedence or duplicate option for option:$option:$value\n";
   }

   return 0;
}

