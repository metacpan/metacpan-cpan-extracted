#!/usr/bin/perl

use strict;
use warnings;

use File::Slurp;

#######################
# TESTING starts here #
#######################
use Test::More tests => 1;

my $POD_in = read_file( 't/backslashQ.pod' ) ;
my $POD_res_namedtoc = read_file( 't/backslashQ_pod.html' ) ;

use EBook::MOBI;
my $obj = EBook::MOBI->new();
$obj->reset();
$obj->add_toc_once();
$obj->add_content(data => $POD_in);
$obj->make();
my $res = $obj->print_mhtml(1);

is("$res", "$POD_res_namedtoc", 'backslash Q');

########
# done #
########
1;

