# -*- perl -*-

use strict;
use warnings;
use Test::More;

# From Hadoop 0.20.205.0ish cluster
my %attributes=(
    _test_namenodeinfo=> 't/data/ab.namenodeinfo',
    _test_jobtrackerinfo=> 't/data/ab.jobtrackerinfo',
    );

use Hadoop::Admin;
my $ha=new Hadoop::Admin(%attributes);

my @dn_live_list=$ha->datanode_live_list();
is($#dn_live_list, 450, "Parse Live List");

# From Hadoop 0.23.1ish cluster
%attributes=(
    _test_namenodeinfo=> 't/data/kr.namenodeinfo',
    );

$ha=new Hadoop::Admin(%attributes);

@dn_live_list=$ha->datanode_live_list();
is($#dn_live_list, 317, "Parse Live List");
done_testing();
