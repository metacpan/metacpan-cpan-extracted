#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

BEGIN {    
    use_ok('IOC::Service::Prototype::ConstructorInjection');   
    use_ok('IOC::Container');    
}

{ # create a package for a dummy service
    package Logger;
    sub new {
        my ($class, $file, $format_string) = @_;
        return bless {
            file          => $file,
            format_string => $format_string 
            } => $class;
    }
    
    package File;
    sub new { 
        my $class = shift;
        bless {} => $class;
    }
}

can_ok("IOC::Service::Prototype::ConstructorInjection", 'new');

my $service = IOC::Service::Prototype::ConstructorInjection->new('logger' => 
                                ('Logger', 'new' => [ 
                                    IOC::Service::Prototype::ConstructorInjection->ComponentParameter('file'),
                                    "Log %d %s"
                                ]));
isa_ok($service, 'IOC::Service::Prototype::ConstructorInjection');
isa_ok($service, 'IOC::Service::ConstructorInjection');
isa_ok($service, 'IOC::Service::Prototype');
isa_ok($service, 'IOC::Service');

my $service2 = IOC::Service::Prototype::ConstructorInjection->new('file' => ('File', 'new', []));
isa_ok($service2, 'IOC::Service::Prototype::ConstructorInjection');
isa_ok($service2, 'IOC::Service::ConstructorInjection');
isa_ok($service2, 'IOC::Service::Prototype');
isa_ok($service2, 'IOC::Service');

my $container = IOC::Container->new();
isa_ok($container, 'IOC::Container');

$container->register($service);
$container->register($service2);

can_ok($service, 'instance');

my $logger = $service->instance();
isa_ok($logger, 'Logger');
isa_ok($logger->{file}, 'File');

my $logger2 = $service->instance();
isa_ok($logger2, 'Logger');
isa_ok($logger2->{file}, 'File');

isnt($logger, $logger2, '... these are prototypes, not constructors');
isnt($logger->{file}, $logger2->{file}, '... these are prototypes, not constructors');
