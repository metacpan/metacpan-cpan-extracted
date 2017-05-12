#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;
use Test::Exception;

BEGIN { 
    use_ok('IOC::Registry');  
    use_ok('IOC::Service');   
    use_ok('IOC::Container');  
}

can_ok("IOC::Registry", 'new');

{

    {
        package My::Test::Service;
        
        sub new { bless {} }
    }

    my $r = IOC::Registry->new();
    isa_ok($r, 'IOC::Registry');
    
    my $c = IOC::Container->new('One');
    isa_ok($c, 'IOC::Container');
    
    $c->register(IOC::Service->new('ServiceOne' => sub { My::Test::Service->new() }));
    $r->registerContainer($c);

    $r->aliasService('One/ServiceOne' => 'Two/ServiceTwo');

    my $service1;
    lives_ok {
        $service1 = $r->locateService('One/ServiceOne');
    } '... got the service ok';
    ok(defined($service1), '... got the service');
    isa_ok($service1, 'My::Test::Service');

    my $service2;
    lives_ok {
        $service2 = $r->locateService('Two/ServiceTwo');
    } '... got the service ok';
    ok(defined($service2), '... got the service');
    isa_ok($service2, 'My::Test::Service');    

    is($service1, $service2, '... these are the same objects');
}


throws_ok {
    IOC::Registry->new()->aliasService()
} 'IOC::InsufficientArguments', '... got the right error';

throws_ok {
    IOC::Registry->new()->aliasService('One')
} 'IOC::InsufficientArguments', '... got the right error';
