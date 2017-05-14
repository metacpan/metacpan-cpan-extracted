#!/usr/bin/env perl

#
# Brett D. Estrade <estrabd@mailcan.com>
#
# PFA to NFA driver
#
# $Revision: 1.1 $ $Date: 2006/02/23 05:11:01 $ $Author: estrabd $

$^W++;
$|++;

use strict;
use Data::Dumper;
use lib qw(../);
use PFA;
use Data::Dumper;

my $pfa1 = PFA->new();
$pfa1->load_file('../input/pfa.2');

my $pfa2 = PFA->new();
$pfa2->load_file('../input/pfa.3');

#print $pfa1->info();
#print "\n%%%%%%%%%%%%%\n\n";
#print $pfa2->info();

$pfa2->interleave_pfa($pfa1);
$pfa2->number_nodes();
print $pfa2->info();
