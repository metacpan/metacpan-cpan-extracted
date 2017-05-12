#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use lib '../lib' ;
use Games::CroqueMonster;

my $cm = Games::CroqueMonster->new( );
my $data = $cm->items();
print "Items: \n",Dumper($data),"\n";
