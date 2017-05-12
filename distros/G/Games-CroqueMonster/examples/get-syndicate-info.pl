#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use lib '../lib' ;
use Games::CroqueMonster;

die "usage: $0 <syndicate name> [<api password>]\n" unless(@ARGV);
my $syndicate = shift(@ARGV);

my $cm = Games::CroqueMonster->new( );
my $syndicate_data = $cm->syndicate($syndicate);
print "Syndicate info: \n",Dumper($syndicate_data),"\n";
