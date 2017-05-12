#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

BEGIN { 
    use_ok('IOC::Container::MethodResolution');  
    use_ok('IOC::Service');  
}

can_ok("IOC::Container::MethodResolution", 'new');

my $container = IOC::Container::MethodResolution->new('MyMethodResolutionTest');
isa_ok($container, 'IOC::Container::MethodResolution');
isa_ok($container, 'IOC::Container');

can_ok($container, 'register');
$container->register(IOC::Service->new('log' => sub { 'Log' }));

can_ok($container, 'name');
is($container->name(), 'MyMethodResolutionTest', '... the name is as we expect it to be');

my $value;
lives_ok {
    $value = $container->log();
} '... the method resolved correctly';

is($value, 'Log', '... and the value is as we expected');

throws_ok {
    $container->Fail();
} "IOC::NotFound", '... the service must exists or we get an exception';

my $value2;
lives_ok {
    $value2 = $container->root()->log();
} '... the method resolved correctly';

is($value2, 'Log', '... and the value is as we expected');

my $sub_container = IOC::Container::MethodResolution->new('sub');
isa_ok($sub_container, 'IOC::Container::MethodResolution');
isa_ok($sub_container, 'IOC::Container');

$sub_container->register(IOC::Service->new('log' => sub { 'Log' }));

$container->addSubContainer($sub_container);

my $value3;
lives_ok {
    $value3 = $container->sub()->log();
} '... the method resolved correctly';

is($value3, 'Log', '... and the value is as we expected');

