#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

BEGIN {    
    use_ok('IOC::Service::Prototype::SetterInjection');   
    use_ok('IOC::Container');    
}

{ # create a package for a dummy service
    package Logger;
    sub new {
        my ($class) = @_;
        return bless {} => $class;
    }
    
    sub setLogFileHandle { 
        my ($self, $file_handle) = @_;
        Test::More::is($file_handle, 'LogFileHandle', '... got the right log file handle'); 
    }
    
    sub setLogFileFormat { 
        my ($self, $file_format) = @_;
        Test::More::is($file_format, 'LogFileFormat', '... got the right log file format'); 
    }
}

can_ok("IOC::Service::Prototype::SetterInjection", 'new');

my $container = IOC::Container->new();
isa_ok($container, 'IOC::Container');

$container->register(IOC::Service->new('log_file_handle' => sub { 'LogFileHandle' }));
$container->register(IOC::Service->new('log_file_format' => sub { 'LogFileFormat' }));

my $service = IOC::Service::Prototype::SetterInjection->new('logger' => 
                                        ('Logger', 'new', [
                                            { setLogFileHandle => 'log_file_handle' },
                                            { setLogFileFormat => 'log_file_format' }
                                        ]));
isa_ok($service, 'IOC::Service::Prototype::SetterInjection');
isa_ok($service, 'IOC::Service::SetterInjection');
isa_ok($service, 'IOC::Service::Prototype');
isa_ok($service, 'IOC::Service');

$service->setContainer($container);
                              
can_ok($service, 'instance');                                                  

my $instance = $service->instance();                                        
isa_ok($instance, 'Logger');

my $instance2 = $service->instance();                                        
isa_ok($instance2, 'Logger');

isnt($instance, $instance2, '... these are not the same instances');
