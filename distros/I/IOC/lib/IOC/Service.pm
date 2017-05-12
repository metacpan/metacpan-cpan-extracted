
package IOC::Service;

use strict;
use warnings;

our $VERSION = '0.08';

use Scalar::Util qw(blessed);

use IOC::Exceptions;

sub new {
    my ($_class, $name, $block) = @_;
    my $class = ref($_class) || $_class;
    my $service = {};
    bless($service, $class);
    $service->_init($name, $block);
    return $service;
}

sub _init {
    my ($self, $name, $block) = @_;
    (defined($name)) || throw IOC::InsufficientArguments "Service object cannot be created without a name";
    (defined($block) && ref($block) eq 'CODE')
        || throw IOC::InsufficientArguments "Service object cannot be created without CODE block";
    # set the defaults
    $self->{_instance} = undef;
    # assign constructor args    
    $self->{name} = $name;
    $self->{block} = $block;
    # container is optional
    $self->{container} = undef;    
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

sub setContainer {
    my ($self, $container) = @_;
    (blessed($container) && $container->isa('IOC::Container'))
        || throw IOC::InsufficientArguments "container argument is incorrect";
    $self->{container} = $container;
    $self;
}

sub removeContainer {
    my ($self) = @_;
    $self->{container} = undef;
    $self;
}

sub instance {
    my ($self) = @_;
    unless (defined $self->{_instance}) {
        (defined($self->{container}))
            || throw IOC::IllegalOperation "Cannot create a service instance without setting container";    
        my $instance = $self->{block}->($self->{container});
        $self->{_instance} = $instance unless defined $self->{_instance};
        (defined($self->{_instance})) 
            || throw IOC::InitializationError "Service creation block returned undefined value";
    }
    return $self->{_instance};
}

sub deferred {
    my ($self) = @_;
    return IOC::Service::Deferred->new($self);
}

sub DESTROY {
    my ($self) = @_;
    # remove the connnection to the instance
    # but do not attempt to DESTROY it, that
    # should be left up to the instance itself
    $self->{_instance} = undef if defined $self->{_instance};
    # remove the container instance as well
    # no need to DESTROY this either since 
    # not only could it still have other services
    # in it, but it it highly likely that the
    # call to DESTROY this object came from
    # its container anyway
    $self->{container} = undef if defined $self->{container};
}

package IOC::Service::Deferred;

use strict;
use warnings;

our $VERSION = '0.02';

use overload '%{}' => sub { 
                    return $_[0] if (caller)[0] eq 'IOC::Service::Deferred';
                    $_[0] = $_[0]->{service}->instance(); 
                    $_[0] 
              },
             '@{}' => sub { $_[0] = $_[0]->{service}->instance(); $_[0] },
             '${}' => sub { $_[0] = $_[0]->{service}->instance(); $_[0] },             
             '&{}' => sub { $_[0] = $_[0]->{service}->instance(); $_[0] },
              nomethod => sub {
                    $_[0] = $_[0]->{service}->instance();
                    return overload::StrVal($_[0]) if ($_[3] eq '""' && !overload::Method($_[0], $_[3]));
                    if (my $func = overload::Method($_[0], $_[3])) {
                        return $_[0]->$func($_[1], $_[2]);
                    }
                    throw IOC::MethodNotFound "Could not find a method for overloaded '$_[3]' operator";
              };             

use Scalar::Util qw(blessed);

sub new {
    my ($class, $service) = @_;
    (blessed($service) && $service->isa('IOC::Service')) 
        || throw IOC::InsufficientArguments "You can only defer an IOC::Service object";
    return bless { service => $service }, $class;
}

sub can { 
    $_[0] = $_[0]->{service}->instance();
    (shift)->can(shift);
}

sub isa { 
    $_[0] = $_[0]->{service}->instance();
    (shift)->isa(shift);
}

sub DESTROY { (shift)->{service} = undef }

sub AUTOLOAD {
    my ($subname) = our $AUTOLOAD =~ /([^:]+)$/;
    $_[0] = $_[0]->{service}->instance();
    my $func = $_[0]->can($subname);
    (ref($func) eq 'CODE') 
        || throw IOC::MethodNotFound "You cannot call '$subname'";
    goto &$func;
}

1;

__END__

=head1 NAME

IOC::Service - An IOC Service object

=head1 SYNOPSIS

  use IOC::Service;
  
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

=head1 DESCRIPTION

In this IOC framework, the IOC::Service object holds instances of components to be managed.

   +--------------+                 +-------------------------+
   | IOC::Service |---(instance)--->| <Your Component/Object> |
   +--------------+                 +-------------------------+ 
          |
  (parent_container)
          |
          V
 +------------------+                  
 |  IOC::Container  |
 +------------------+

=head1 METHODS

=over 4

=item B<new ($name, $block)>

Creates a service with a C<$name>, and uses the C<$block> argument to initialize the service on demand.

=item B<name>

Returns the name of the service instance.

=item B<setContainer ($container)>

Given a C<$container>, which is an instance of IOC::Container or a subclass of it, this method will associate the service instance with that container object.

=item B<removeContainer>

This will break the connection between a service and a container. This method is usually only called by the C<unregister> method in L<IOC::Container>.

=item B<instance>

This method returns the component held by the service object, the is basically the value returned by the C<$block> constructor argument.

=item B<deferred>

This method returns an IOC::Service::Deferred wrapper which will lazy load the service. This is used for handling circular dependencies, and rarely used directly.

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

