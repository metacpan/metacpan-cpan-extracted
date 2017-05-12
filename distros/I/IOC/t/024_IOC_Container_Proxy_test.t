#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 27;
use Test::Exception;

BEGIN { 
    use_ok('IOC::Container');  
    use_ok('IOC::Service');  
    use_ok('IOC::Proxy');
}

{
    package Test::Proxy::One;
    
    sub new { bless {} => $_[0] }
    sub test_proxy_one { return 'test_proxy_one' }    
    
    package Test::Proxy::Two;

    sub new { bless {} => $_[0] }
    sub test_proxy_two { return 'test_proxy_two' }    
}

my $container = IOC::Container->new('Test');
isa_ok($container, 'IOC::Container');

lives_ok {
    $container->register(IOC::Service->new('proxy_one' => sub { Test::Proxy::One->new() }));
} '... registered the first service ok';

my $unproxy_one = $container->get('proxy_one');
isa_ok($unproxy_one, 'Test::Proxy::One');
ok(!UNIVERSAL::isa($unproxy_one, 'Test::Proxy::One::_::Proxy'), '... we are not proxied yet');

is($unproxy_one->test_proxy_one(), 'test_proxy_one', '... got the result we expected');

my @one_method_calls;
my $proxy_one_server = IOC::Proxy->new({
                            on_method_call => sub { push @one_method_calls => \@_ } 
                        });
isa_ok($proxy_one_server, 'IOC::Proxy');                        

lives_ok {
    $container->addProxy('proxy_one' => $proxy_one_server);
} '... added proxy to the first service ok';       

my $proxy_one = $container->get('proxy_one');
isa_ok($unproxy_one, 'Test::Proxy::One::_::Proxy');
isa_ok($unproxy_one, 'Test::Proxy::One');

is($proxy_one->test_proxy_one(), 'test_proxy_one', '... got the result we expected');             

is_deeply(\@one_method_calls, [
            [ $proxy_one_server, 'test_proxy_one', 'Test::Proxy::One::test_proxy_one', [ $proxy_one ]]
            ], '... got the method calls we expected');
        

my $proxy_temp = $container->get('proxy_one');
# check to make sure we are not getting double proxied
ok(!UNIVERSAL::isa($unproxy_one, 'Test::Proxy::One::_::Proxy::_::Proxy'), '... we are not being double proxied');

my @two_method_calls;
my $proxy_two_server = IOC::Proxy->new({
                    on_method_call => sub { push @two_method_calls => \@_ } 
                    });
isa_ok($proxy_two_server, 'IOC::Proxy');

lives_ok {
    $container->registerWithProxy(
                IOC::Service->new('proxy_two' => sub { Test::Proxy::Two->new() }),
                $proxy_two_server
                );
} '... registered the second service ok';    

my $proxy_two = $container->get('proxy_two');
isa_ok($proxy_two, 'Test::Proxy::Two::_::Proxy');
isa_ok($proxy_two, 'Test::Proxy::Two');

is($proxy_two->test_proxy_two(), 'test_proxy_two', '... got the result we expected');  

is_deeply(\@two_method_calls, [
            [ $proxy_two_server, 'test_proxy_two', 'Test::Proxy::Two::test_proxy_two', [ $proxy_two ]]
            ], '... got the method calls we expected');   
            
# now check some errors

throws_ok {
    $container->addProxy();
} 'IOC::InsufficientArguments', '... got the error we expected';

throws_ok {
    $container->addProxy('Fail');
} 'IOC::InsufficientArguments', '... got the error we expected';

throws_ok {
    $container->addProxy('Fail', 'Fail');
} 'IOC::InsufficientArguments', '... got the error we expected';

throws_ok {
    $container->addProxy('Fail', []);
} 'IOC::InsufficientArguments', '... got the error we expected';

throws_ok {
    $container->addProxy('Fail', bless({}, 'Fail'));
} 'IOC::InsufficientArguments', '... got the error we expected';

throws_ok {
    $container->addProxy('Fail', IOC::Proxy->new());
} 'IOC::ServiceNotFound', '... got the error we expected';
