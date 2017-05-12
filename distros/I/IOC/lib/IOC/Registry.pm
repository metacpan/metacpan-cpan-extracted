
package IOC::Registry;

use strict;
use warnings;

our $VERSION = '0.05';

use Scalar::Util qw(blessed);

use IOC::Exceptions;
use IOC::Interfaces;

use IOC::Visitor::SearchForService;
use IOC::Visitor::SearchForContainer;

use base 'Class::StrongSingleton';

sub new {
    my ($_class) = @_;
    my $class = ref($_class) || $_class;
    my $registry = {
        containers => {},
        service_aliases => {}
        };
    bless($registry, $class);
    $registry->_init();
    return $registry;
}

# add and remove containers

sub registerContainer {
    my ($self, $container) = @_;
    (blessed($container) && $container->isa('IOC::Container'))
        || throw IOC::InsufficientArguments "You must supply a valid IOC::Container object";
    my $name = $container->name();
    (!exists ${$self->{containers}}{$name})
        || throw IOC::ContainerAlreadyExists "Duplicate Container '$name'";
    $self->{containers}->{$name} = $container;
}

sub unregisterContainer {
    my ($self, $container_or_name) = @_;
    (defined($container_or_name)) || throw IOC::InsufficientArguments "You must supply a name or a container";    
    my $name;
    if (ref($container_or_name)) {
        (blessed($container_or_name) && $container_or_name->isa('IOC::Container'))
            || throw IOC::InsufficientArguments "You must supply a valid IOC::Container object";
        $name = $container_or_name->name();
    }
    else {
        $name = $container_or_name;
    }
    (exists ${$self->{containers}}{$name})
        || throw IOC::ContainerNotFound "Cannot unregister a container we do not have";
    my $container = $self->{containers}->{$name};
    delete $self->{containers}->{$name};    
    return $container;
}

# fetching the containers

sub getRegisteredContainer {
    my ($self, $name) = @_;
    (defined($name)) || throw IOC::InsufficientArguments "You must supply a name of a container";
    (exists ${$self->{containers}}{$name}) 
        || throw IOC::ContainerNotFound "There is no container by the name '${name}'";     
    return $self->{containers}->{$name};
}

sub getRegisteredContainerList {
    my ($self) = @_;
    return keys %{$self->{containers}};
}

sub hasRegisteredContainer {
    my ($self, $name) = @_;
    (defined($name)) || throw IOC::InsufficientArguments "You must supply a name of a container";
    return (exists ${$self->{containers}}{$name}) ? 1 : 0;
}

# aliasing

sub aliasService {
    my ($self, $real_path, $alias_path) = @_;
    (defined($alias_path) && defined($real_path)) 
        || throw IOC::InsufficientArguments "You must supply a alias path and a real path";
    $self->{service_aliases}->{$alias_path} = $real_path;
}

# locate Service by path

sub locateService {
    my ($self, $path, @extra_args) = @_;
    (defined($path)) || throw IOC::InsufficientArguments "You must supply a path to a service";
    # if the service has been aliased, get the real path ...
    $path = $self->{service_aliases}->{$path} if exists ${$self->{service_aliases}}{$path};
    # and go about your normal business ...
    my @path = grep { $_ } split /\// => $path;
    my $registered_container_name = shift @path;
    (exists ${$self->{containers}}{$registered_container_name}) 
        || throw IOC::ContainerNotFound "There is no registered container found at '$registered_container_name' for the path '${path}'"; 
    my $service;
    eval {
        $service = $self->{containers}->{$registered_container_name}->find((join "/" => @path), \@extra_args);
    };
    throw IOC::ServiceNotFound "There is no service found at the path '${path}'" => $@ if $@;    
    return $service;
}

sub locateContainer {
    my ($self, $path) = @_;
    (defined($path)) || throw IOC::InsufficientArguments "You must supply a path to a container";    
    my @path = grep { $_ } split /\// => $path;
    my $registered_container_name = shift @path;
    (exists ${$self->{containers}}{$registered_container_name}) 
        || throw IOC::ContainerNotFound "There is no container found at the path '${path}'"; 
    my $current = $self->{containers}->{$registered_container_name};
    eval {
        $current = $current->getSubContainer(shift @path) while @path;
    };
    throw IOC::ContainerNotFound "There is no container found at the path '${path}'" => $@ if $@;
    # otherwise ...
    return $current;
}

# searching for containers

sub searchForContainer {
    my ($self, $container_to_find) = @_;
    my $container_found;
    foreach my $container (values %{$self->{containers}}) {
        $container_found = $container->accept(IOC::Visitor::SearchForContainer->new($container_to_find));
        last if defined $container_found;
    }
    return $container_found;
}

sub searchForService {
    my ($self, $service_to_find) = @_;
    my $service;
    foreach my $container (values %{$self->{containers}}) {
        $service = $container->accept(IOC::Visitor::SearchForService->new($service_to_find));
        last if $service;
    }
    return $service;
}

sub DESTROY {
    my ($self) = @_;
    # get rid of all our containers
    foreach my $container (values %{$self->{containers}}) {
        defined $container && $container->DESTROY;
    }     
    # let the Singleton do its work
    $self->SUPER::DESTROY();
}

1;

__END__

=head1 NAME

IOC::Registry - Registry singleton for the IOC Framework

=head1 SYNOPSIS

  use IOC::Registry;

  my $container = IOC::Container->new('database');
  my $other_container = IOC::Container->new('logging');
  # ... bunch of IOC::Container creation code omitted
  
  # create a registry singleton
  my $reg = IOC::Registry->new();
  $reg->registerContainer($container);
  $reg->registerContainer($other_container);
  
  # ... somewhere later in your program
  
  my $reg = IOC::Registry->instance(); # get the singleton
  
  # and try and find a service
  my $service = $reg->searchForService('laundry') || die "Could not find the laundry service";
  
  my $database = $reg->getRegisteredContainer('database');
  
  # get a list of container names
  my @container_names = $reg->getRegisteredContainerList();
  
  # and you can unregister containers too
  my $unregistered_container = $reg->unregisterContainer($container);

=head1 DESCRIPTION

This is a singleton object which is meant to be used as a global registry for all your IoC needs. 

=head1 METHODS

=over 4

=item B<new>

Creates a new singleton instance of the Registry, the same singleton will be returned each time C<new> is called after the first one. 

=back

=head2 Container Registration Methods

=over 4

=item B<registerContainer ($container)>

This method will add a C<$container> to the registry, where it can be accessed by it's name.

=item B<unregisterContainer ($container|$name)>

This method accepts either the C<$container> instance itself, or the C<$name> of the container and removes said container from the registry.

=item B<hasRegisteredContainer ($name)>

This will return true (C<1>) if a container by that C<$name> exists within the registry, and false (C<0>) otherwise.

=item B<getRegisteredContainer ($name)>

This will retrieve a registered container by C<$name> from the registry. If C<$name> is not defined, then an B<IOC::InsufficientArguments> exception will be thrown. If no container is found with C<$name>, then an B<IOC::ContainerNotFound> exception will be thrown.

=item B<getRegisteredContainerList>

This will return the list of string names of all the registered containers.

=back

=head2 Aliasing Methods

=over 4

=item B<aliasService ($real_path, $alias_path)>

This allows you to alias a path to a real service (C<$real_path>) to be accessible from a different path (C<$alias_path>). Basically, it is sometimes useful for the same service to be found at two different paths, especially when re-useing and combining IOC configurations for different frameworks.

The aliases set by this method will only affect the services retrieved through the C<locateService> method. The aliases do not have any meaning outside of the IOC::Registry. 

B<NOTE:>
There is no easy way to validate that the C<$real_path> is actually a valid path, so we make the assumption that you know what you are doing. 

=back

=head2 Search Methods

=over 4

=item B<locateService ($path)>

Given a C<$path> to a service, this will locate the service and return it. If C<$path> is not specificed an B<IOC::InsufficientArguments> exception will be thrown.

=item B<searchForService ($name)>

Given a C<$name> for a service, this will attempt to locate the service within the entire heirarchy and return it. If the service is not found, then this method will return C<undef>. If C<$name> is not specificed an B<IOC::InsufficientArguments> exception will be thrown.

=item B<locateContainer ($path)>

Given a C<$path> to a container, this will locate the container and return it. If C<$path> is not specificed an B<IOC::InsufficientArguments> exception will be thrown.

=item B<searchForContainer ($name)>

Given a C<$name> for a container, this will attempt to locate the container within the entire heirarchy and return it. If the container is not found, then this method will return C<undef>. If C<$name> is not specificed an B<IOC::InsufficientArguments> exception will be thrown.

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

=over 4

=item L<Class::StrongSingleton>

This is a subclass of Class::StrongSingleton, if you want to know about how the singleton-ness is handled, check there.

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

