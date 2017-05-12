
package IOC::Visitor::ServiceLocator;

use strict;
use warnings;

our $VERSION = '0.02';

use Scalar::Util qw(blessed);

use IOC::Interfaces;
use IOC::Exceptions;

use base 'IOC::Visitor';

sub new {
    my ($_class, $path, $extra_args) = @_;
    ($path) 
        || throw IOC::InsufficientArguments "You must provide an path to locate a container";
    my $class = ref($_class) || $_class;
    my $visitor = {
        path => $path,
        extra_args => $extra_args
    };
    bless($visitor, $class);
    return $visitor;
}

sub visit {
    my ($self, $container) = @_;
    (blessed($container) && $container->isa('IOC::Container'))
        || throw IOC::InsufficientArguments "You must provide an IOC::Container object as a sub-container";
    my $service;
    my @extra_args = (defined $self->{extra_args} ? @{$self->{extra_args}} : ());
    my @path = grep { $_ } split /\// => $self->{path};
    my $service_name = pop @path;
    if ($self->{path} =~ /^\//) {
        # start at the root
        my $current = $container->findRootContainer();
        foreach my $container_name (@path) {
            eval { 
                $current = $current->getSubContainer($container_name);
            };
            throw IOC::UnableToLocateService "Could not locate the service at path '" . $self->{path} . "' failed at '$container_name'", $@ if $@;
        }
        $service = $current->get($service_name, @extra_args);
    }
    else {
        my $current = $container;
        foreach my $container_name (@path) {
            if ($container_name eq '..') {
                $current = $current->getParentContainer();            
            }
            else {
                eval {
                    $current = $current->getSubContainer($container_name);
                };
                throw IOC::UnableToLocateService "Could not locate the service at path '" . $self->{path} . "' failed at '$container_name'", $@ if $@;                
            }
        }
        $service = $current->get($service_name, @extra_args);         
    }
    return $service;
}

1;

__END__

=head1 NAME

IOC::Visitor::ServiceLocator - Service locator Visitor for the IOC::Container hierarchies

=head1 SYNOPSIS

  use IOC::Visitor::ServiceLocator;

  # given a $container, ...

  # find services within $container
  my $visitor = IOC::Visitor::ServiceLocator->new('connection');

  # find services relative to $container
  my $visitor = IOC::Visitor::ServiceLocator->new('../connection');
  
  # find services from $container's root  
  my $visitor = IOC::Visitor::ServiceLocator->new('/database/connection');
  
  $container->accept($visitor);

=head1 DESCRIPTION

This is a IOC::Visitor object, used by the IOC::Container's C<find> method to locate a service using a path syntax.

        +------------------+
        | <<IOC::Visitor>> |
        +------------------+
                 |
                 ^
                 |
   +------------------------------+
   | IOC::Visitor::ServiceLocator |
   +------------------------------+

=head1 METHODS

=over 4

=item B<new ($path)>

Creates a new instance which will find Services at a given C<$path>. If no C<$path> is given, than an B<IOC::InsufficientArguments> exception is thrown. 

=item B<visit ($container)>

Given a C<$container>, the invocant will attempt to locate the service at the C<$path> (given to the constuctor) from within the C<$container>.

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

