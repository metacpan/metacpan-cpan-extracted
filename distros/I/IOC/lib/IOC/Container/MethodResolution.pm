
package IOC::Container::MethodResolution;

use strict;
use warnings;

our $VERSION = '0.02';

use IOC::Exceptions;

use base 'IOC::Container';

our $AUTOLOAD;

sub AUTOLOAD {
    my ($self) = @_;
    my $name = (split '::', $AUTOLOAD)[-1];
    if ($name eq 'root') {
        return $self->findRootContainer();
    }
    elsif ($self->hasService($name)) {
        return $self->get($name);
    }
    elsif ($self->hasSubContainer($name)) {
        return $self->getSubContainer($name);
    }
    throw IOC::NotFound "Could not find either a service or a sub-container named '$name'";
}

1;

__END__

=head1 NAME

IOC::Container::MethodResolution - An IOC Container object which support method resolution of services

=head1 SYNOPSIS

  use IOC::Container;
  
  my $container = IOC::Container->new();
  $container->register(IOC::Service::Literal->new('log_file' => "logfile.log"));
  $container->register(IOC::Service->new('logger' => sub { 
      my $c = shift; 
      return FileLogger->new($c->log_file());
  }));
  $container->register(IOC::Service->new('application' => sub {
      my $c = shift; 
      my $app = Application->new();
      $app->logger($c->logger());
      return $app;
  }));

  $container->application()->run();     
  
  # or a more complex example
  # utilizing a tree-like structure
  # of services

  my $logging = IOC::Container->new('logging');
  $logging->register(IOC::Service->new('logger' => sub {
      my $c = shift;
      return My::FileLogger->new($c->root()->filesystem()->filemanager()->openFile($c->log_file()));
  }));
  $logging->register(IOC::Service::Literal->new('log_file' => '/var/my_app.log')); 
  
  my $database = IOC::Container->new('database');
  $database->register(IOC::Service->new('connection' => sub {
      my $c = shift;
      return My::DB->connect($c->dsn(), $c->username(), $c->password());
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
      $app->logger($c->root()->logging()->logger());
      $app->db_connection($c->root()->database()->connection());
      return $app;
  })); 
  
  $container->application()->run();          

=head1 DESCRIPTION

In this IOC framework, the IOC::Container::MethodResolution object holds instances of keyed IOC::Service objects which can be called as methods.

            +----------------+
            | IOC::Container |
            +----------------+
                    |
                    ^
                    |
   +----------------------------------+
   | IOC::Container::MethodResolution |
   +----------------------------------+

=head1 METHODS

There are no new methods for this subclass, but when a service is registered, the name of the service becomes a valid method for this particular container instance.

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

