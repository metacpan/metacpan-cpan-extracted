#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 61;
use Test::Exception;

BEGIN { 
    use_ok('IOC::Registry');  
    use_ok('IOC::Service');   
    use_ok('IOC::Container');  
}

can_ok("IOC::Registry", 'new');

my $reg = IOC::Registry->new();
isa_ok($reg, 'IOC::Registry');
isa_ok($reg, 'Class::StrongSingleton');

is($reg, IOC::Registry->new(), '... this really is a singleton');

my $test1 = IOC::Container->new('test 1');
isa_ok($test1, 'IOC::Container');
my $test2 = IOC::Container->new('test 2');
isa_ok($test2, 'IOC::Container');
my $test3 = IOC::Container->new('test 3');
isa_ok($test3, 'IOC::Container');

my $test_sub_2_2;

lives_ok {

    $test1->addSubContainers(
        IOC::Container->new('sub test 1.1')
            ->register(IOC::Service->new('test service 1.1-1' => sub { '1.1-1' }))
            ->register(IOC::Service->new('test service 1.1-2' => sub { '1.1-2' })),
        IOC::Container->new('sub test 1.2')
            ->register(IOC::Service->new('test service 1.2-1' => sub { '1.2-1' }))
            ->register(IOC::Service->new('test service 1.2-2' => sub { '1.2-2' }))        
            ->addSubContainers(
                IOC::Container->new('sub test 1.2.1')
                    ->register(IOC::Service->new('test service 1.2.1-1' => sub { '1.2.1-1' })),
                IOC::Container->new('sub test 1.2.2')
                    ->register(IOC::Service->new('test service 1.2.2-1' => sub { '1.2.2-1' }))
                    ->register(IOC::Service->new('test service 1.2.2-2' => sub { '1.2.2-2' }))
                )
        );
        
    # this is embedded in $test2
    $test_sub_2_2 = IOC::Container->new('sub test 2.2')
                        ->register(IOC::Service->new('test service 2.2-1' => sub { '2.2-1' }))
                        ->register(IOC::Service->new('test service 2.2-2' => sub { '2.2-2' }));        
    
    $test2->addSubContainers(
        IOC::Container->new('sub test 2.1')
            ->register(IOC::Service->new('test service 2.1-1' => sub { '2.1-1' }))
            ->addSubContainers(
                IOC::Container->new('sub test 2.1.1')
                    ->register(IOC::Service->new('test service 2.1.1-1' => sub { '2.1.1-1' })),
                IOC::Container->new('sub test 2.1.2')
                    ->register(IOC::Service->new('test service 2.1.2-1' => sub { '2.1.2-1' }))
                    ->register(IOC::Service->new('test service 2.1.2-2' => sub { '2.1.2-2' }))
                ),      
        $test_sub_2_2
        );
    
    $test3->register(IOC::Service->new('test service 3-1' => sub { '3-1' }))
          ->register(IOC::Service->new('test service 3-2' => sub { '3-2' }));
      
} '... created our hierarchy successfully';
                          
$reg->registerContainer($test1);
$reg->registerContainer($test2);
$reg->registerContainer($test3);                                              

is($test1, $reg->getRegisteredContainer('test 1'), '... got the right container');
is($test2, $reg->getRegisteredContainer('test 2'), '... got the right container');
is($test3, $reg->getRegisteredContainer('test 3'), '... got the right container');
 
is_deeply(
    [ sort $reg->getRegisteredContainerList() ],
    [ 'test 1', 'test 2', 'test 3' ],
    '... got the list of containers we expected');
 
{
    my $service = $reg->searchForService('test service 2.1.2-2');                                                                  
    ok(defined($service), '... we found the service');
    is($service, '2.1.2-2', '... and the service is what we expected');                                                                            
}

{
    my $service = $reg->searchForService('test service 2.1.5-2');
    ok(!defined($service), '... we did not find the service');
}
                                                                                                
{
    my $container = $reg->searchForContainer('sub test 2.2');                                                                  
    ok(defined($container), '... we found the container');
    isa_ok($container, 'IOC::Container');
    is($container, $test_sub_2_2, '... and it is the container we expected');
}
   
{
    my $container = $reg->searchForContainer('sub test 2.2-Nothing');                                                                  
    ok(!defined($container), '... we did not find the container');
}

{
    my $service = $reg->locateService('test 2/sub test 2.1/sub test 2.1.2/test service 2.1.2-2');                                                                  
    ok(defined($service), '... we found the service');
    is($service, '2.1.2-2', '... and the service is what we expected');                                                                            
}

{
    my $container = $reg->locateContainer('test 2/sub test 2.2');                                                                  
    ok(defined($container), '... we found the container');
    isa_ok($container, 'IOC::Container');
    is($container, $test_sub_2_2, '... and it is the container we expected');                                                                            
}

my $unreg_test2;

ok($reg->hasRegisteredContainer('test 2'), '... we have this container');

lives_ok {
    $unreg_test2 = $reg->unregisterContainer($test2);
} '... unregistered the container successfully';

ok(defined($unreg_test2), '... got the unregistered container');
isa_ok($unreg_test2, 'IOC::Container');
is($unreg_test2, $test2, '... and it is test2');

ok(!$reg->hasRegisteredContainer('test 2'), '... we no longer have this container');

throws_ok {
    $reg->getRegisteredContainer("test 2")
} "IOC::ContainerNotFound", '... got an error';

is_deeply(
    [ sort $reg->getRegisteredContainerList() ],
    [ 'test 1', 'test 3' ],
    '... got the list of containers we expected');

my $unreg_test3;

ok($reg->hasRegisteredContainer('test 3'), '... we have this container');

lives_ok {
    $unreg_test3 = $reg->unregisterContainer('test 3');
} '... unregistered the container successfully';

ok(defined($unreg_test3), '... got the unregistered container');
isa_ok($unreg_test3, 'IOC::Container');
is($unreg_test3, $test3, '... and it is test3');

ok(!$reg->hasRegisteredContainer('test 3'), '... we no longer have this container');

throws_ok {
    $reg->getRegisteredContainer("test 3")
} "IOC::ContainerNotFound", '... got an error';
    
is_deeply(
    [ $reg->getRegisteredContainerList() ],
    [ 'test 1' ],
    '... got the list of containers we expected');    

# check some errors

# hasRegisteredContainer

throws_ok {
    $reg->hasRegisteredContainer()
} "IOC::InsufficientArguments", '... got an error';

# getRegisteredContainer

throws_ok {
    $reg->getRegisteredContainer()
} "IOC::InsufficientArguments", '... got an error';

throws_ok {
    $reg->getRegisteredContainer("Fail")
} "IOC::ContainerNotFound", '... got an error';

# registerContainer

throws_ok {
    $reg->registerContainer()
} "IOC::InsufficientArguments", '... got an error';

throws_ok {
    $reg->registerContainer("Fail")
} "IOC::InsufficientArguments", '... got an error';

throws_ok {
    $reg->registerContainer([])
} "IOC::InsufficientArguments", '... got an error';

throws_ok {
    $reg->registerContainer(bless {} => "Fail")
} "IOC::InsufficientArguments", '... got an error';

throws_ok {
    $reg->registerContainer(IOC::Container->new('test 1'))
} "IOC::ContainerAlreadyExists", '... got an error';

# unregisterContainer

throws_ok {
    $reg->unregisterContainer("Fail")
} "IOC::ContainerNotFound", '... got an error';

throws_ok {
    $reg->unregisterContainer()
} "IOC::InsufficientArguments", '... got an error';

throws_ok {
    $reg->unregisterContainer([])
} "IOC::InsufficientArguments", '... got an error';

throws_ok {
    $reg->unregisterContainer(bless {} => "Fail")
} "IOC::InsufficientArguments", '... got an error';

# locateService

throws_ok {
    $reg->locateService()
} "IOC::InsufficientArguments", '... got an error';

throws_ok {
    $reg->locateService("Fail/Fail")
} "IOC::ContainerNotFound", '... got an error';

throws_ok {
    $reg->locateService("test 1/Fail")
} "IOC::ServiceNotFound", '... got an error';

# locateContainer 

throws_ok {
    $reg->locateContainer()
} "IOC::InsufficientArguments", '... got an error';

throws_ok {
    $reg->locateContainer("Fail/Fail")
} "IOC::ContainerNotFound", '... got an error';

throws_ok {
    $reg->locateContainer("test 1/Fail")
} "IOC::ContainerNotFound", '... got an error';

# just call destroy

$reg->DESTROY();
