#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

BEGIN {    
    use_ok('IOC::Service');   
    use_ok('IOC::Container');    
}

{ # create a package for a dummy service
    package Logger;
    sub new {
        my $class = shift;
        return bless {} => $class;
    }
}

# this function will test that
# we got a container in our 
# construction block
sub create_logger {
    my ($container) = @_;
    isa_ok($container, 'IOC::Container');
    return Logger->new();
}

can_ok("IOC::Service", 'new');

# check errors first

throws_ok {
    IOC::Service->new()
} "IOC::InsufficientArguments", '... a service must be created with a name';

throws_ok {
    IOC::Service->new("Fail")
} "IOC::InsufficientArguments", '... a service must be created with a CODE block';

throws_ok {
    IOC::Service->new("Fail", "Fail")
} "IOC::InsufficientArguments", '... a service must be created with a CODE block';

throws_ok {
    IOC::Service->new("Fail", [])
} "IOC::InsufficientArguments", '... a service must be created with a CODE block';

# create the service

my $service = IOC::Service->new('logger' => \&create_logger );
isa_ok($service, 'IOC::Service');

# check the interface

can_ok($service, 'setContainer');
can_ok($service, 'instance');

# check instance errors

throws_ok {
    $service->instance()
} "IOC::IllegalOperation", '... cannot create an instance without a container';

# check set Container errors

throws_ok {
    $service->setContainer()
} "IOC::InsufficientArguments", '... must have a container object to set the container';

throws_ok {
    $service->setContainer("Fail")
} "IOC::InsufficientArguments", '... must have a container object to set the container';

throws_ok {
    $service->setContainer([])
} "IOC::InsufficientArguments", '... must have a container object to set the container';

throws_ok {
    $service->setContainer(bless({}, "Fail"))
} "IOC::InsufficientArguments", '... must have a container object to set the container';

# create and set a container

my $container = IOC::Container->new();
isa_ok($container, 'IOC::Container');

lives_ok {
    $service->setContainer($container);
} '... set container successfully';

my $logger = $service->instance('logger');
isa_ok($logger, 'Logger');

my $logger2 = $service->instance('logger');
isa_ok($logger2, 'Logger');

is($logger, $logger2, '... each logger instance is the same');

# check init error in instance

throws_ok {
    IOC::Service->new('Fail' => sub { undef })->setContainer($container)->instance();
} "IOC::InitializationError", '... got the correct initilization error';
