#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 37;
use Test::Exception;

BEGIN { 
    use_ok('IOC::Container');  
    use_ok('IOC::Service');  
}

can_ok("IOC::Container", 'new');

my $container = IOC::Container->new();
isa_ok($container, 'IOC::Container');

can_ok($container, 'setParentContainer');
can_ok($container, 'getParentContainer');
can_ok($container, 'isRootContainer');

can_ok($container, 'addSubContainer');
can_ok($container, 'addSubContainers');
can_ok($container, 'hasSubContainers');
can_ok($container, 'getSubContainerList');
can_ok($container, 'getSubContainer');
can_ok($container, 'getAllSubContainers');

# create some sub-containers

my $sub_container_1 = IOC::Container->new("sub 1");
isa_ok($sub_container_1, 'IOC::Container');

my $sub_container_2 = IOC::Container->new("sub 2");
isa_ok($sub_container_2, 'IOC::Container');

my $sub_container_3 = IOC::Container->new("sub 3");
isa_ok($sub_container_3, 'IOC::Container');

my $sub_container_4 = IOC::Container->new("sub 4");
isa_ok($sub_container_4, 'IOC::Container');

ok(!$container->hasSubContainers(), '... we do not have any subcontainers');
$container->addSubContainer($sub_container_1);
ok($container->hasSubContainers(), '... we do have subcontainers now');

is($sub_container_1, $container->getSubContainer('sub 1'), '... this is our first sub container');

$container->addSubContainers(
    $sub_container_2,
    $sub_container_3,
    $sub_container_4        
    );

is($sub_container_2, $container->getSubContainer('sub 2'), '... this is our second sub container');
is($sub_container_3, $container->getSubContainer('sub 3'), '... this is our third sub container');
is($sub_container_4, $container->getSubContainer('sub 4'), '... this is our fourth sub container');

is_deeply(
    [ sort ($sub_container_1, $sub_container_2, $sub_container_3, $sub_container_4) ],
    [ sort $container->getAllSubContainers() ]
    , '... we have the same sub_containers');
    
is_deeply(
    [ 'sub 1', 'sub 2', 'sub 3', 'sub 4' ],
    [ sort $container->getSubContainerList() ]
    , '... we have the same sub_container names');       
    
# now lets take care of some errors

throws_ok {
    $container->setParentContainer()
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->setParentContainer("Fail")
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->setParentContainer([])
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->setParentContainer(bless({}, "Fail"))
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->addSubContainer()
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->addSubContainer("Fail")
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->addSubContainer([])
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->addSubContainer(bless({}, "Fail"))
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->addSubContainer(IOC::Container->new('sub 1'))
} "IOC::ContainerAlreadyExists", '... got the error we expected';

throws_ok {
    $container->addSubContainers()
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->getSubContainer()
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->getSubContainer("Fail")
} "IOC::ContainerNotFound", '... got the error we expected';
