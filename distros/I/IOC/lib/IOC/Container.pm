
package IOC::Container;

use strict;
use warnings;

our $VERSION = '0.14';

use Scalar::Util qw(blessed);

use IOC::Interfaces;
use IOC::Exceptions;

use IOC::Visitor::ServiceLocator;

use base 'IOC::Visitable';

sub new {
    my ($_class, $name) = @_;
    my $class = ref($_class) || $_class;
    my $container = {};
    bless($container, $class);
    $container->_init($name);
    return $container;
}

sub _init {
    my ($self, $name) = @_;
    $self->{services} = {};
    $self->{service_locks} = {};
    $self->{proxies} = {};
    $self->{sub_containers} = {};
    $self->{parent_container} = undef;
    $self->{name} = $name || 'default';
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

# parent containers 

sub setParentContainer {
    my ($self, $parent_container) = @_;
    (blessed($parent_container) && $parent_container->isa('IOC::Container'))
        || throw IOC::InsufficientArguments "You must provide an IOC::Container object as a parent container";    
    $self->{parent_container} = $parent_container;
}

sub getParentContainer {
    my ($self) = @_;
    return $self->{parent_container};
}

sub isRootContainer {
    my ($self) = @_;
    return defined($self->{parent_container}) ? 0 : 1;
}

sub findRootContainer {
    my ($self) = @_;
    return $self if $self->isRootContainer();
    my $current = $self;
    $current = $current->getParentContainer() until $current->isRootContainer();
    return $current;
}

# sub containers

sub addSubContainer {
    my ($self, $container) = @_;
    (blessed($container) && $container->isa('IOC::Container'))
        || throw IOC::InsufficientArguments "You must provide an IOC::Container object as a sub-container";
    my $name = $container->name();
    (!exists ${$self->{sub_containers}}{$name}) 
        || throw IOC::ContainerAlreadyExists "Duplicate Sub-Container Name '${name}' in container '" . $self->{name} . "'";     
    $self->{sub_containers}->{$name} = $container;
    $container->setParentContainer($self);
    $self;
}

sub addSubContainers {
    my ($self, @containers) = @_;
    (@containers) || throw IOC::InsufficientArguments "You must provide at least one IOC::Container to add";
    $self->addSubContainer($_) foreach @containers;
    $self;
}

sub hasSubContainer {
    my ($self, $name) = @_;
    (defined($name)) || throw IOC::InsufficientArguments "You must supply a name of a sub-container";
    return (exists ${$self->{sub_containers}}{$name}) ? 1 : 0;
}

sub hasSubContainers {
    my ($self) = @_;
    return scalar(keys(%{$self->{sub_containers}})) ? 1 : 0;
}

sub getSubContainerList {
    my ($self) = @_;
    return keys %{$self->{sub_containers}};
}

sub getSubContainer {
    my ($self, $name) = @_;
    (defined($name)) || throw IOC::InsufficientArguments "You must supply a name of a sub-container";
    (exists ${$self->{sub_containers}}{$name}) 
        || throw IOC::ContainerNotFound "There is no subcontainer by the name '${name}' in container '" . $self->{name} . "'";     
    return $self->{sub_containers}->{$name};
}

sub getAllSubContainers {
    my ($self) = @_;
    return values %{$self->{sub_containers}};
}

sub accept {
    my ($self, $visitor) = @_;
    (blessed($visitor) && $visitor->isa('IOC::Visitor'))
        || throw IOC::InsufficientArguments "You must pass an IOC::Visitor object to the visit method";
    return $visitor->visit($self);
}

# services

sub register {
    my ($self, $service) = @_;
    (blessed($service) && $service->isa('IOC::Service'))
        || throw IOC::InsufficientArguments "You must provide a valid IOC::Service object to register";
    my $name = $service->name();
    (!exists ${$self->{services}}{$name}) 
        || throw IOC::ServiceAlreadyExists "Duplicate Service Name '${name}'"; 
    $service->setContainer($self);
    $self->{services}->{$name} = $service;
    $self;
}

sub unregister {
    my ($self, $name) = @_;
    (defined($name)) || throw IOC::InsufficientArguments "You must provide a service name to unregister";
    (exists ${$self->{services}}{$name}) 
        || throw IOC::ServiceNotFound "Unknown Service '${name}'"; 
    my $service = $self->{services}->{$name};
    $service->removeContainer();    
    delete $self->{services}->{$name};
    return $service;
}

sub registerWithProxy {
    my ($self, $service, $proxy) = @_;
    $self->register($service);
    $self->addProxy($service->name(), $proxy);
    $self;
}

sub addProxy {
    my ($self, $name, $proxy) = @_;
    (defined($name)) || throw IOC::InsufficientArguments "You must provide a valid service name";    
    (blessed($proxy) && $proxy->isa('IOC::Proxy'))
        || throw IOC::InsufficientArguments "You must provide a valid IOC::Proxy object to register";    
    (exists ${$self->{services}}{$name}) 
        || throw IOC::ServiceNotFound "Unknown Service '${name}'";    
    $self->{proxies}->{$name} = $proxy;
    $self;
}

sub get {
    my ($self, $name, %params) = @_;
    (defined($name)) || throw IOC::InsufficientArguments "You must provide a name of the service";
    (exists ${$self->{services}}{$name}) 
        || throw IOC::ServiceNotFound "Unknown Service '${name}'";
    # a literal object can have no dependencies, 
    # and therefore can have no circular refs, so
    # we can optimize their usage there as well
    return $self->{services}->{$name}->instance() 
        if $self->{services}->{$name}->isa('IOC::Service::Literal');
    if ($self->_isServiceLocked($name)) {
        # NOTE:
        # if the service is parameterized
        # then we cannot defer it - SL
        ($self->{services}->{$name}->isa('IOC::Service::Parameterized')) 
            && throw IOC::IllegalOperation "The service '$name' is locked, cannot defer a parameterized instance";
        # otherwise ...    
        return $self->{services}->{$name}->deferred();
    }
    $self->_lockService($name);   
    my $instance = $self->{services}->{$name}->instance(%params);
    $self->_unlockService($name);      
    if (blessed($instance) && ref($instance) !~ /\:\:\_\:\:Proxy$/) {
        return $self->{proxies}->{$name}->wrap($instance) if exists ${$self->{proxies}}{$name};
    }
    return $instance;
}

sub find {
    my ($self, $path, $extra_args) = @_;
    (defined($path)) 
        || throw IOC::InsufficientArguments "You must provide a path of find a service";
    return $self->accept(IOC::Visitor::ServiceLocator->new($path, $extra_args));    
}

sub hasService {
    my ($self, $name) = @_;
    (defined($name)) || throw IOC::InsufficientArguments "You must provide a name of the service";
    return (exists ${$self->{services}}{$name}) ? 1 : 0;
}

sub getServiceList {
    my ($self) = @_;
    return keys %{$self->{services}};
}

sub DESTROY {
    my ($self) = @_;
    # this will not DESTROY all the
    # sub-containers it holds, since
    # a sub-container might be still
    # refered to elsewhere.
    $self->{sub_containers} = undef;
    # and the same with the parent
    $self->{parent_container} = undef;
    # this will DESTROY all the
    # services it holds, since
    # a service can only have one
    # container, then this is okay
    # to do that, otherwise we would
    # need to deal with that.
    foreach my $service (values %{$self->{services}}) {
        defined $service && $service->DESTROY;
    } 
}

# private methods

sub _lockService {
    my ($self, $name) = @_;   
    $self->{lock_level}++;
    $self->{service_locks}->{$name} = $self->{lock_level}; 
#     use Data::Dumper;
#     print "locking '$name' -> our locks are: " . Dumper($self->{service_locks});         
}

sub _unlockService {
    my ($self, $name) = @_;
    $self->{lock_level}--;
    delete $self->{service_locks}->{$name};
}

sub _isServiceLocked {
    my ($self, $name) = @_;       
    return (exists ${$self->{service_locks}}{$name});
}

1;

__END__

=head1 NAME

IOC::Container - An IOC Container object

=head1 SYNOPSIS

  use IOC::Container;
  
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
  
  
  # or a more complex example
  # utilizing a tree-like structure
  # of services

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

=head1 DESCRIPTION

In this IOC framework, the IOC::Container object holds instances of IOC::Service objects keyed by strings. It can also have sub-containers, which are instances of IOC::Container objects also keyed by string.

                    +------------------+
                    |  IOC::Container  |
                    +---------+--------+
                              |
           +------------------+-----------------+
           |                  |                 |
   (*sub-containers)     (*proxies)        (*services)
           |                  |                 |
           V                  V                 V
 +------------------+  +--------------+  +--------------+
 |  IOC::Container  |  |  IOC::Proxy  |  | IOC::Service |
 +------------------+  +--------------+  +--------------+
                                                |
                                            (instance)
                                                |
                                                V
                                    +-------------------------+                                                
                                    | <Your Component/Object> |
                                    +-------------------------+

=head1 METHODS

=over 4

=item B<new ($container_name)>

A container can be named with the optional C<$container_name> argument, otherwise the container will have the name 'default'. 

=item B<name>

This will return the name of the container.

=back

=head2 Service Methods

=over 4

=item B<register ($service)>

Given a C<$service>, this will register the C<$service> as part of this container. The value returned by the C<name> method of the C<$service> object is as the key where this service is stored. This also will call C<setContainer> on the C<$service> and pass in it's own instance.

If C<$service> is not an instance of IOC::Service, or a subclass of it, an B<IOC::InsufficientArguments> exception will be thrown.

If the name of C<$service> already exists, then a B<IOC::ServiceAlreadyExists> exception is thrown.

=item B<unregister ($name)>

Given a C<$name> this will remove the service from the container. If there is no service by that C<$name>, then a B<IOC::ServiceNotFound> exception is thrown.

=item B<registerWithProxy ($service, $proxy)>

Same as C<register> but also registers a C<$proxy> object to wrap the C<$service> object with.

=item B<addProxy ($name, $proxy)>

Adds a C<$proxy> object to wrap the service at C<$name>.

=item B<get ($name)>

Given a C<$name> this will return the service instance that name corresponds to, if C<$name> is not defined, an exception is thrown.

If there is no service by that C<$name>, then a B<IOC::ServiceNotFound> exception is thrown.

B<NOTE:> If the requested service is currently locked (meaning it is being created), then a deferred service stub is returned. This will allow for cyclical dependencies to work. 

=item B<find ($path)>

Given a C<$path> to a service, this method will attempt to locate that service. It utilizes the L<IOC::Visitor::ServiceLocator> to do this. 

=item B<hasService ($name)>

=item B<getServiceList>

Returns a list of all the named services available.

=back

=head2 Parent Container Methods

=over 4

=item B<getParentContainer>

Get the parent container associated with this instance. If there is no container, undef is returned.

=item B<setParentContainer ($container)>

Given a C<$container>, this will associate it as the invocant's parent. If the C<$container> is not an instance of IOC::Container (or a subclass of it), an B<IOC::InsufficientArguments> exception will be thrown.

=item B<isRootContainer>

If the invocant does not have a parent, then it is considered a root container and this method will return true (C<1>), otherwise it will return false (C<0>).

=item B<findRootContainer>

This will climb back up the container hierarchy and find the root of the container tree.

=back

=head2 Sub-Container Methods

=over 4

=item B<addSubContainer ($container)>

Adds a C<$container> to it's keyed list of sub-containers. This has the effect of making the invocant the parent of C<$container>. If C<$container> is not a IOC::Container object (or a subclass of it), then an B<IOC::InsufficientArguments> exception is thrown. If the name of C<$container> is a duplicate of one already stored, then a B<IOC::ContainerAlreadyExists> exception is thrown.

=item B<addSubContainers (@container)>

This just loops calling C<addSubContainer> on each of the items in C<@containers>.

=item B<hasSubContainer ($name)>

=item B<hasSubContainers>

This will return true (C<1>) if the invocant has sub-containers, and false (C<0>) otherwise.

=item B<getSubContainerList>

This will return a list of strings which the sub-containers are keyed by.

=item B<getSubContainer ($name)>

This will return the sub-container associated with C<$name>. If C<$name> is undefined an B<IOC::InsufficientArguments> exception will be thrown. If no sub-container exists by that C<$name>, then an B<IOC::ContainerNotFound> exception will be thrown.

=item B<getAllSubContainers>

This will return a list of the actual sub-containers stored. This will be in the same order as the list returned by C<getSubContainerList>.

=item B<accept ($visitor)>

This method is part of the I<IOC::Visitable> interface. It accepts only C<$visitor> objects which implement the I<IOC::Visitor> interface. 

=back

=head1 TO DO

=over 4

=item Work on the documentation

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, see the CODE COVERAGE section of L<IOC> for more information.

=head1 SEE ALSO

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

