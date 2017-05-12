#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;

BEGIN { 
    use_ok('IOC');
    
    use_ok('IOC::Exceptions');    
    use_ok('IOC::Interfaces'); 
    
    use_ok('IOC::Registry');
    
    use_ok('IOC::Container');
        use_ok('IOC::Container::MethodResolution');
    
    use_ok('IOC::Service');    
        use_ok('IOC::Service::ConstructorInjection'); 
        use_ok('IOC::Service::SetterInjection');   
        
        use_ok('IOC::Service::Literal');     
        
        use_ok('IOC::Service::Prototype'); 
            use_ok('IOC::Service::Prototype::ConstructorInjection'); 
            use_ok('IOC::Service::Prototype::SetterInjection');     
    
    use_ok('IOC::Proxy');
        use_ok('IOC::Proxy::Interfaces');	    
    
    # IOC::Visitor     
        use_ok('IOC::Visitor::ServiceLocator');
        use_ok('IOC::Visitor::SearchForService');   
        use_ok('IOC::Visitor::SearchForContainer');      
}

# test our simple example

{
    package FileLogger;
    sub new { 
        my ($class, $log_file) = @_;
        ($log_file eq 'logfile.log') || die "Got wrong log file";
        bless { log_file => $log_file } => $class; 
    }
    
    package Application;
    sub new { 
        my $class = shift;
        bless { logger => undef } => $class 
    }
    sub logger { 
        my ($self, $logger) = @_;
        (UNIVERSAL::isa($logger, 'FileLogger')) || die "Got wrong logger type";
        $self->{logger} = $logger;
    }
    sub run {}
}	

lives_ok {

    my $container = IOC::Container->new();
    $container->register(IOC::Service::Literal->new('log_file' => "logfile.log"));
    $container->register(IOC::Service->new('logger' => sub { 
        my $c = shift; 
        return FileLogger->new($c->get('log_file'));
    }));
    $container->register(IOC::Service->new('application' => sub {
        my $c = shift; 
        my $app = Application->new();
        $app->logger($c->get('logger'));
        return $app;
    }));
    
    $container->get('application')->run();
    
} '... our simple example ran successfully';

# and now test out our complex example

{
    package My::FileLogger;
    sub new { 
        my ($class, $log_file) = @_;
        (UNIVERSAL::isa($log_file, 'OPEN')) || die "Incorrect Log File";
        bless { log_file => $log_file } => $class; 
    }

    package My::FileManager;
    sub new { 
        my $class = shift;
        bless { } => $class 
    }
    sub openFile {
        my ($self, $name) = @_;
        return bless \$name, 'OPEN';
    }
    
    package My::DB;
    sub connect {
        my ($class, $dsn, $u, $p) = @_;
        (defined($dsn) && defined($u) && defined($p)) || die "Database not initialized";
        bless { dsn => $dsn, u => $u, p => $p } => $class;
    }
    
    package My::Application;
    sub new { 
        my ($class) = @_;
        bless { 
            logger   => undef,
            database => undef
        } => $class 
    }
    sub logger { 
        my ($self, $logger) = @_;
        (UNIVERSAL::isa($logger, 'My::FileLogger')) || die "Got wrong logger type";
        $self->{logger} = $logger;
    }
    sub db_connection { 
        my ($self, $database) = @_;
        (UNIVERSAL::isa($database, 'My::DB')) || die "Got wrong DB type";
        $self->{database} = $database;
    }    

    sub run {}
}

lives_ok {

    my $logging = IOC::Container->new('logging');
    $logging->register(IOC::Service->new('logger' => sub {
        my $c = shift;
        return My::FileLogger->new($c->find('/filesystem/filemanager')->openFile($c->get('log_file')));
    }));
    $logging->register(IOC::Service::Literal->new('log_file' => '/var/my_app.log'));
    
    my $database = IOC::Container->new('database');
    $database->register(IOC::Service->new('connection' => sub {
        my $c = shift;
        return My::DB->connect($c->get('dsn'), $c->get('username'), $c->get('password'));
    }));
    $database->register(IOC::Service::Literal->new('dsn'      => 'dbi:mysql:my_app'));
    $database->register(IOC::Service::Literal->new('username' => 'test'));
    $database->register(IOC::Service::Literal->new('password' => 'secret_test'));          
    
    my $file_system = IOC::Container->new('filesystem');
    $file_system->register(IOC::Service->new('filemanager' => sub { return My::FileManager->new() }));
            
    my $container = IOC::Container->new(); 
    $container->addSubContainers($file_system, $database, $logging);
    $container->register(IOC::Service->new('application' => sub {
        my $c = shift; 
        my $app = My::Application->new();
        $app->logger($c->find('/logging/logger'));
        $app->db_connection($c->find('/database/connection'));
        return $app;
    })); 
    
    $container->get('application')->run();
  
} '... our complex example ran successfully';