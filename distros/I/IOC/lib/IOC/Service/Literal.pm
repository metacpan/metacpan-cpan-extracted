
package IOC::Service::Literal;

use strict;
use warnings;

our $VERSION = '0.01';

use Scalar::Util qw(blessed);

use IOC::Exceptions;

use base 'IOC::Service';

sub new {
    my ($_class, $name, $literal) = @_;
    my $class = ref($_class) || $_class;
    my $service = {};
    bless($service, $class);
    $service->_init($name, $literal);
    return $service;
}

sub _init {
    my ($self, $name, $literal) = @_;
    (defined($name)) || throw IOC::InsufficientArguments "Service object cannot be created without a name";
    (defined($literal))
        || throw IOC::InsufficientArguments "Service::Literal object cannot be created without value";
    # set the defaults
    $self->{_instance} = $literal;
    # assign constructor args    
    $self->{name} = $name;
    # No block in this one
    ## $self->{block} = undef;
    # No container in this one either
    ## $self->{container} = undef;    
}

sub instance { (shift)->{_instance} }

# no-ops
sub setContainer    { () }
sub removeContainer { () }
sub DESTROY         { () }

1;

__END__

=head1 NAME

IOC::Service::Literal - An IOC Service object whose component is a literal value

=head1 SYNOPSIS

  use IOC::Service::Literal;
  
  my $container = IOC::Container->new();
  # use a literal here for our log_file 
  $container->register(IOC::Service::Literal->new('log_file' => "logfile.log" ));
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

In this IOC framework, the IOC::Service::Literal object holds a literal value which does not need to be initialized. This IOC::Service subclass is specifically optimized to handle values which need no initialization, like literal values, such as numbers and strings. It is sometimes useful for these types of values to be included in your configuration, this helps reduce the overhead for them.

        +--------------+
        | IOC::Service |
        +--------------+
              |
              ^
              |
   +-----------------------+                 +-----------------+
   | IOC::Service::Literal |---(instance)--->| <Literal Value> |
   +-----------------------+                 +-----------------+ 

=head1 METHODS

=over 4

=item B<new ($name, $literal)>

Creates a service with a C<$name>, and uses the C<$literal> value which need not be initialized.

=item B<name>

Returns the name of the service instance.

=item B<setContainer ($container)>

This is a no-op method, since the service is not initialized, then it does not need an instance of the container.

=item B<removeContainer>

This is a no-op method, see C<setContainer> above.

=item B<instance>

This method returns the literal value held by the service object.

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

