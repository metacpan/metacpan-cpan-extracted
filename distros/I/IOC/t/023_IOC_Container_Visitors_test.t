#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 53;
use Test::Exception;

BEGIN { 
    use_ok('IOC::Container');  
    use_ok('IOC::Service');  
    use_ok('IOC::Visitor::ServiceLocator'); 
    use_ok('IOC::Visitor::SearchForService');   
    use_ok('IOC::Visitor::SearchForContainer');    
}

can_ok("IOC::Container", 'new');
can_ok("IOC::Visitor::ServiceLocator", 'new');

my $container = IOC::Container->new('root');
isa_ok($container, 'IOC::Container');

can_ok($container, 'accept');
can_ok($container, 'find');

my $test = IOC::Container->new('test')
                  ->register(
                    IOC::Service->new('test_service' => sub { "Test Service" } )
                    );

$container->addSubContainer($test);

{
    my $visitor = IOC::Visitor::ServiceLocator->new("/test/test_service");
    isa_ok($visitor, 'IOC::Visitor::ServiceLocator');
        
    my $service;    
    lives_ok {
            $service = $container->accept($visitor);
    } '... it worked';
    
    ok(defined($service), '... we got a service');
    is($service, 'Test Service', '... got our expected service');
}

$test->addSubContainer(
    IOC::Container->new('test_find')
                  ->register(
                    IOC::Service->new('test_find_service' => sub { "Test Find Service : " . (shift)->find('../test_service') } )
                    )
    );

{
    my $visitor = IOC::Visitor::ServiceLocator->new("/test/test_find/test_find_service");
    isa_ok($visitor, 'IOC::Visitor::ServiceLocator');
        
    my $service;    
    lives_ok {
            $service = $container->accept($visitor);
    } '... it worked';
    
    ok(defined($service), '... we got a service');
    is($service, 'Test Find Service : Test Service', '... got our expected service');
}

$container->register(
    IOC::Service->new('test_the_test_service' => sub { "Test The Test Service : " .(shift)->find('test/test_service') } )
    );
    
{
    my $visitor = IOC::Visitor::ServiceLocator->new("/test_the_test_service");
    isa_ok($visitor, 'IOC::Visitor::ServiceLocator');
        
    my $service;    
    lives_ok {
            $service = $container->accept($visitor);
    } '... it worked';
    
    ok(defined($service), '... we got a service');
    is($service, 'Test The Test Service : Test Service', '... got our expected service');
}  

$test->getSubContainer('test_find')->addSubContainer(
    IOC::Container->new('test_test_find')
                  ->register(
                    IOC::Service->new('test_test_find_service' => sub { "Test Find Service : " . (shift)->find('../../test_service') } )
                    )
    );

{
    my $visitor = IOC::Visitor::ServiceLocator->new("/test/test_find/test_test_find/test_test_find_service");
    isa_ok($visitor, 'IOC::Visitor::ServiceLocator');
        
    my $service;    
    lives_ok {
            $service = $container->accept($visitor);
    } '... it worked';
    
    ok(defined($service), '... we got a service');
    is($service, 'Test Find Service : Test Service', '... got our expected service');
}

# check for find errors

{
    my $visitor = IOC::Visitor::ServiceLocator->new("/test/test_it/Fail");
    isa_ok($visitor, 'IOC::Visitor::ServiceLocator');
    
    throws_ok {
        $container->accept($visitor);
    } "IOC::UnableToLocateService", '... got the error we expected';  
}

{
    my $visitor = IOC::Visitor::ServiceLocator->new("../test/Fail");
    isa_ok($visitor, 'IOC::Visitor::ServiceLocator');
    
    throws_ok {
        $container->accept($visitor);
    } "IOC::UnableToLocateService", '... got the error we expected';  
}

# check our errors

throws_ok {
    $container->find()
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->accept()
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->accept("Fail")
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->accept([])
} "IOC::InsufficientArguments", '... got the error we expected';

throws_ok {
    $container->accept(bless({}, 'Fail'))
} "IOC::InsufficientArguments", '... got the error we expected';

# visitor errors

throws_ok {
    IOC::Visitor::ServiceLocator->new()
} "IOC::InsufficientArguments", '... got the error we expected';

{

    my $visitor = IOC::Visitor::ServiceLocator->new("/dummy_path");
    isa_ok($visitor, 'IOC::Visitor::ServiceLocator');

    throws_ok {
        $visitor->visit()
    } "IOC::InsufficientArguments", '... got the error we expected';

    throws_ok {
        $visitor->visit("Fail")
    } "IOC::InsufficientArguments", '... got the error we expected';
    
    throws_ok {
        $visitor->visit([])
    } "IOC::InsufficientArguments", '... got the error we expected';
    
    throws_ok {
        $visitor->visit(bless({}, 'Fail'))
    } "IOC::InsufficientArguments", '... got the error we expected';            
}


throws_ok {
    IOC::Visitor::SearchForService->new()
} "IOC::InsufficientArguments", '... got the error we expected';

{

    my $visitor = IOC::Visitor::SearchForService->new("/dummy_path");
    isa_ok($visitor, 'IOC::Visitor::SearchForService');

    throws_ok {
        $visitor->visit()
    } "IOC::InsufficientArguments", '... got the error we expected';

    throws_ok {
        $visitor->visit("Fail")
    } "IOC::InsufficientArguments", '... got the error we expected';
    
    throws_ok {
        $visitor->visit([])
    } "IOC::InsufficientArguments", '... got the error we expected';
    
    throws_ok {
        $visitor->visit(bless({}, 'Fail'))
    } "IOC::InsufficientArguments", '... got the error we expected';            
}  

throws_ok {
    IOC::Visitor::SearchForContainer->new()
} "IOC::InsufficientArguments", '... got the error we expected';

{

    my $visitor = IOC::Visitor::SearchForContainer->new("/dummy_path");
    isa_ok($visitor, 'IOC::Visitor::SearchForContainer');

    throws_ok {
        $visitor->visit()
    } "IOC::InsufficientArguments", '... got the error we expected';

    throws_ok {
        $visitor->visit("Fail")
    } "IOC::InsufficientArguments", '... got the error we expected';
    
    throws_ok {
        $visitor->visit([])
    } "IOC::InsufficientArguments", '... got the error we expected';
    
    throws_ok {
        $visitor->visit(bless({}, 'Fail'))
    } "IOC::InsufficientArguments", '... got the error we expected';            
}