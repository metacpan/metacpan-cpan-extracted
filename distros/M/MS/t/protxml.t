#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use MS::Reader::ProtXML;

chdir $FindBin::Bin;

require_ok ("MS::Reader::ProtXML");

# check that compressed and uncompressed FHs return identical results
my $fn = 'corpus/test.prot.xml.gz';

ok (my $p = MS::Reader::ProtXML->new($fn), "created parser object");

my $i = 0;
++$i while (my $s = $p->next_group);
ok ($i == 39, "next_group()");
    
done_testing();
