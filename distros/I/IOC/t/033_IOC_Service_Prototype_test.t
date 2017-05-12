#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

BEGIN {    
    use_ok('IOC::Service::Prototype');   
    use_ok('IOC::Container');    
}

{ # create a package for a dummy service
    package Logger;
    sub new {
        my $class = shift;
        return bless {} => $class;
    }
    
    our $DESTROYED_Loggers = 0;
    sub DESTROY {
       $DESTROYED_Loggers++;
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

can_ok("IOC::Service::Prototype", 'new');

# create the service

my $service = IOC::Service::Prototype->new('logger' => \&create_logger );
isa_ok($service, 'IOC::Service::Prototype');
isa_ok($service, 'IOC::Service');

# check the interface

can_ok($service, 'instance');

# check instance errors

throws_ok {
    $service->instance()
} "IOC::IllegalOperation", '... cannot create an instance without a container';

# create and set a container

my $container = IOC::Container->new();
isa_ok($container, 'IOC::Container');

lives_ok {
    $service->setContainer($container);
} '... set container successfully';

{
    my $logger = $service->instance('logger');
    isa_ok($logger, 'Logger');
    
    {
        my $logger2 = $service->instance('logger');
        isa_ok($logger2, 'Logger');
        
        isnt($logger, $logger2, '... each logger instance is the same');
    }
    
    cmp_ok($Logger::DESTROYED_Loggers, '==', 1, '... one logger has been destoryed');
}

cmp_ok($Logger::DESTROYED_Loggers, '==', 2, '... two loggers were destoryed');
