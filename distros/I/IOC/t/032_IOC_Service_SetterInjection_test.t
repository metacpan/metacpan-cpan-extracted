#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 37;
use Test::Exception;

BEGIN {    
    use_ok('IOC::Service::SetterInjection');   
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

can_ok("IOC::Service::SetterInjection", 'new');

{
    my $container = IOC::Container->new();
    isa_ok($container, 'IOC::Container');
    
    $container->register(IOC::Service->new('log_file_handle' => sub { 'LogFileHandle' }));
    $container->register(IOC::Service->new('log_file_format' => sub { 'LogFileFormat' }));
    
    my $service = IOC::Service::SetterInjection->new('logger' => 
                                            ('Logger', 'new', [
                                                { setLogFileHandle => 'log_file_handle' },
                                                { setLogFileFormat => 'log_file_format' }
                                            ]));
    isa_ok($service, 'IOC::Service::SetterInjection');
    isa_ok($service, 'IOC::Service');
    
    $service->setContainer($container);
                                
    can_ok($service, 'instance');                                                  
    
    my $instance = $service->instance();                                        
    isa_ok($instance, 'Logger');
}

{ # check getting service from the root

    my $log_file_container = IOC::Container->new('LogFile');
    isa_ok($log_file_container, 'IOC::Container');
    
    $log_file_container->register(IOC::Service->new('handle' => sub { 'LogFileHandle' }));
    $log_file_container->register(IOC::Service->new('format' => sub { 'LogFileFormat' }));
    
    my $service = IOC::Service::SetterInjection->new('logger' => 
                                            ('Logger', 'new', [
                                                { setLogFileHandle => '/LogFile/handle' },
                                                { setLogFileFormat => '/LogFile/format' }
                                            ]));
    isa_ok($service, 'IOC::Service::SetterInjection');
    isa_ok($service, 'IOC::Service');
    
    my $logging_container = IOC::Container->new('Logging');
    $service->setContainer($logging_container); 
    
    my $container = IOC::Container->new('root');
    $container->addSubContainer($logging_container);
    $container->addSubContainer($log_file_container);    
                                                         
    can_ok($service, 'instance');                                                  
    
    my $instance = $service->instance();                                        
    isa_ok($instance, 'Logger');
}

{ # check getting service from the a sub container

    my $log_file_container = IOC::Container->new('LogFile');
    isa_ok($log_file_container, 'IOC::Container');
    
    $log_file_container->register(IOC::Service->new('handle' => sub { 'LogFileHandle' }));
    $log_file_container->register(IOC::Service->new('format' => sub { 'LogFileFormat' }));
    
    my $service = IOC::Service::SetterInjection->new('logger' => 
                                            ('Logger', 'new', [
                                                { setLogFileHandle => 'LogFile/handle' },
                                                { setLogFileFormat => 'LogFile/format' }
                                            ]));
    isa_ok($service, 'IOC::Service::SetterInjection');
    isa_ok($service, 'IOC::Service');
    
    my $logging_container = IOC::Container->new('Logging');
    $service->setContainer($logging_container); 
    
    $logging_container->addSubContainer($log_file_container);
                                                         
    can_ok($service, 'instance');                                                  
    
    my $instance = $service->instance();                                        
    isa_ok($instance, 'Logger');
}

{ # load a service class

    my $container = IOC::Container->new('ClassLoading');
    isa_ok($container, 'IOC::Container');
    
    my $service = IOC::Service::SetterInjection->new('container' => ('IOC::Container::MethodResolution', 'new' => []));
    isa_ok($service, 'IOC::Service::SetterInjection');
    isa_ok($service, 'IOC::Service');
    
    $container->register($service);
    
    my $instance;
    lives_ok {
        $instance = $service->instance();
    } '... and the service loads correctly';
    isa_ok($instance, 'IOC::Container::MethodResolution');
}


# check some errors now
{
    my $container = IOC::Container->new();

    throws_ok {
        IOC::Service::SetterInjection->new('file');
    } "IOC::InsufficientArguments", '... cannot create a setter injection without a component class';
    
    throws_ok {
        IOC::Service::SetterInjection->new('file' => ("Fail"));
    } "IOC::InsufficientArguments", '... cannot create a setter injection without a component class constructor';
    
    throws_ok {
        IOC::Service::SetterInjection->new('file' => ("Fail", 'new'));
    } "IOC::InsufficientArguments", '... cannot create a setter injection without a setter parameter list';
    
    throws_ok {
        IOC::Service::SetterInjection->new('file' => ("Fail", 'new', "Fail"));
    } "IOC::InsufficientArguments", '... cannot create a setter injection without an array ref as setter parameter list';
    
    throws_ok {
        IOC::Service::SetterInjection->new('file' => ("Fail", 'new', {}));
    } "IOC::InsufficientArguments", '... cannot create a setter injection without an array ref as setter parameter list';
    
    throws_ok {
        IOC::Service::SetterInjection->new('file2' => ("Fail", 'new', []))->setContainer($container)->instance;
    } "IOC::ClassLoadingError", '... cannot create a setter injection with a bad object';
    
    throws_ok {
        IOC::Service::SetterInjection->new('file3' => ("Logger", 'notNew', []))->setContainer($container)->instance;
    } "IOC::ConstructorNotFound", '... cannot create a setter injection with a bad constructor';
    
    throws_ok {
        IOC::Service::SetterInjection->new('file4' => ("Logger", 'new', [ { noMethod => 'nuttin' } ]))->setContainer($container)->instance;
    } "IOC::MethodNotFound", '... cannot create a setter injection with a bad setter methods';

}
