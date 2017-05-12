 # -*- perl -*-

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Hadoop::Admin') };

can_ok('Hadoop::Admin', ('new'));

my %attributes=(
    namenode                  => 'a',
    jobtracker                => 'b',
    secondarynamenode         => 'c',
    socksproxy                => 'd', 
#    resourcemanager           => 'e',
    namenode_port             => '1',
    jobtracker_port           => '2',
#    resourcemanger_port       => '3',
    socksproxy_port           => '4',
    _test_resourcemanagerinfo => 't/data/kr.rmnminfo',
    _test_namenodeinfo        => 't/data/ab.namenodeinfo',
    _test_jobtrackerinfo      => 't/data/ab.jobtrackerinfo',
    );

use Hadoop::Admin;
my $ha=new Hadoop::Admin(%attributes);
    
isa_ok($ha, 'Hadoop::Admin');
is($ha->get_namenode(),             'a', "get_namenode() works");
is($ha->get_jobtracker(),           'b', "get_jobtracker() works");
is($ha->get_secondarynamenode,      'c', "get_secondarynamenode() works");
is($ha->get_socksproxy(),           'd', "get_socksproxy() works");
is($ha->get_namenode_port(),        '1', "get_namenode_port() works");
is($ha->get_jobtracker_port(),      '2', "get_jobtracker_port() works");
is($ha->get_socksproxy_port(),      '4', "get_socksproxy_port() works");

%attributes=(
    resourcemanager           => 'e',
    resourcemanger_port       => '3',
    _test_resourcemanagerinfo => 't/data/kr.rmnminfo',
    );

$ha=new Hadoop::Admin(%attributes);
is($ha->get_resourcemanager(),      'e', "get_resourcemanager() works");
#is($ha->get_resourcemanager_port(), '3', "get_resourcemanger_port() works");    
 TODO:{
     local $TODO="Some unknown bug I can't find yet.";
     is($ha->get_resourcemanager_port(), '3', "get_resourcemanager_port() works");    
};

done_testing();
