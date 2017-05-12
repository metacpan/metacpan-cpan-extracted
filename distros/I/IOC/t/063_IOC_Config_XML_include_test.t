#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

BEGIN {
    use_ok('IOC::Config::XML');
}


## include tests

{
    my $conf = IOC::Config::XML->new();
    isa_ok($conf, 'IOC::Config::XML');
            
    $conf->read('t/confs/063a_IOC_Config_XML_include_test.xml');
    
    my $r = IOC::Registry->new();
    isa_ok($r, 'IOC::Registry');
    
    is_deeply([ $r->getRegisteredContainerList() ], [ 'test' ], '... got the container list');
    
    my $test = $r->getRegisteredContainer('test');
    isa_ok($test, 'IOC::Container');
    
    is($test->name(), 'test', '... got the right name');

#    is_deeply([ $test->getServiceList() ], [ 'test' ], '... got the right service name list');
}