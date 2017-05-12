
package IOC::Service::SetterInjection;

use strict;
use warnings;

our $VERSION = '0.06';

use IOC::Exceptions;

use base 'IOC::Service';

sub new {
    my ($_class, $name, $component_class, $component_constructor, $setter_parameters) = @_;
    my $class = ref($_class) || $_class;
    my $service = {};
    bless($service, $class);
    $service->_init($name, $component_class, $component_constructor, $setter_parameters);
    return $service;
}

sub _init {
    my ($self, $name, $component_class, $component_constructor, $setter_parameters) = @_;
    (defined($component_class) && defined($component_constructor))
        || throw IOC::InsufficientArguments "You must provide a class and a constructor method";
    (defined($setter_parameters) && ref($setter_parameters) eq 'ARRAY')
        || throw IOC::InsufficientArguments "You must provide a set of setter parameters";    
    $self->{component_class} = $component_class;
    $self->{component_constructor} = $component_constructor;
    $self->{setter_parameters} = $setter_parameters;    
    $self->SUPER::_init(
        $name,
        sub {
            my $c = shift;
            # check if there is an entry in the 
            # symbol table for this class already
            # (meaning it has been loaded) and if 
            # not, then require it            
            eval { 
                no strict 'refs';
                # check for the symbol table itself ...
                (keys %{"${component_class}::"} || 
                    # and then to be sure, lets look for  
                    # either the VERSION or the ISA variables
                    (defined ${"${component_class}::VERSION"} 
                        || defined @{"${component_class}::ISA"})) ? 1 : 0;
            } || eval "use $component_class";
            # throw our exception if the class fails to load
            throw IOC::ClassLoadingError "The class '$component_class' could not be loaded" => $@ if $@;
            # check to see if the specified 
            # constructor is there
            my $constructor = $component_class->can($component_constructor);
            # if it is not, then throw our exception
            (defined($constructor)) 
                || throw IOC::ConstructorNotFound "The constructor '$component_constructor' could not be found for class '$component_class'";
            # now create our instance
            my $instance = $component_class->$constructor();
            # now take care of the parameters
            foreach my $setter_param (@{$setter_parameters}) {
                my ($setter_key, $setter_value) = %{$setter_param};
                my $setter_method = $instance->can($setter_key);
                (defined($setter_method))
                    || throw IOC::MethodNotFound "Could not resolve setter method '$setter_key'";
                if ($setter_value =~ /\//) {
                    $instance->$setter_method($c->find($setter_value));
                }
                else {
                    $instance->$setter_method($c->get($setter_value));
                }
            }                
            return $instance;            
        }
        );
}

1;

__END__

=head1 NAME

IOC::Service::SetterInjection - An IOC Service object which uses Setter Injection

=head1 SYNOPSIS

  use IOC::Service::SetterInjection;
  
  my $service = IOC::Service::SetterInjection->new('logger' => (
                    'FileLogger', 'new', [
                        # fetch a component from another container
                        { setLogFileHandle => '/filesystem/log_file_handle' },
                        # fetch a component from our own container
                        { setLogFileFormat => 'log_file_format' }
                    ]));

=head1 DESCRIPTION

In this IOC framework, the IOC::Service::SetterInjection object holds instances of components to be managed.

          +--------------+
          | IOC::Service |
          +--------------+
                 |
                 ^
                 |
   +-------------------------------+
   | IOC::Service::SetterInjection |
   +-------------------------------+

=head1 METHODS

=over 4

=item B<new ($name, $component_class, $component_constructor, $setter_parameters)>

Creates a service with a C<$name>, and uses the C<$component_class> and C<$component_constructor> string arguments to initialize the service on demand. 

If the C<$component_class> and C<$component_constructor> arguments are not defined, an B<IOC::InsufficientArguments> exception will be thrown. 

Upon request of the component managed by this service, an attempt will be made to load the C<$component_class>. If that loading fails, an B<IOC::ClassLoadingError> exception will be thrown with the details of the underlying error. If the C<$component_class> loads successfully, then it will be inspected for an available C<$component_constructor> method. If the C<$component_constructor> method is not found, an B<IOC::ConstructorNotFound> exception will be thrown. If the C<$component_constructor> method is found, then it will be called.

Once a valid instance has been created, then the C<$setter_parameter> array ref is looped through. Each parameter is then a hash ref, the key being the setter method name and the value being the name of a Service (available through C<get> or C<find>). It is then checked if the setter method is available, if not a B<IOC::MethodNotFound> exception is thrown. It if is found, then it is called and passed the value of the resolved service name.

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

=item Setter Injection in the PicoContainer is explained on this page

L<http://docs.codehaus.org/display/PICO/Setter+Injection>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

