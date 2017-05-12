# -*- perl -*-

use strict;
use warnings;
use Test::More;

my %attributes=(
    _test_resourcemanagerinfo=> 't/data/kr.rmnminfo',
    );

use Hadoop::Admin;
my $ha=new Hadoop::Admin(%attributes);

my @nm_live_list=$ha->nodemanager_live_list();
is($#nm_live_list, 313, "Parse Live List");

done_testing();
