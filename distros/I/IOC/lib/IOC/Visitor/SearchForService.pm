
package IOC::Visitor::SearchForService;

use strict;
use warnings;

our $VERSION = '0.03';

use Scalar::Util qw(blessed);

use IOC::Interfaces;
use IOC::Exceptions;

use base 'IOC::Visitor';

sub new {
    my ($_class, $service_name) = @_;
    ($service_name) 
        || throw IOC::InsufficientArguments "You must provide a name of a service to find";
    my $class = ref($_class) || $_class;
    my $visitor = {
        service_to_find => $service_name
        };
    bless($visitor, $class);
    return $visitor;
}

sub visit {
    my ($self, $container) = @_;
    (blessed($container) && $container->isa('IOC::Container'))
        || throw IOC::InsufficientArguments "You must provide an IOC::Container object to search";
    my $service_to_find = $self->{service_to_find};
    return $self->_recursiveSearch($container, $service_to_find);
}

sub _recursiveSearch {
    my ($self, $container, $service_to_find) = @_;
    # look through all the current services
    return $container->get($service_to_find) if $container->hasService($service_to_find);
    # if we have sub-containers, ...
    if ($container->hasSubContainers()) {
        # then loop through all the sub-containers
        foreach my $sub_container ($container->getAllSubContainers()) {
            my $service = $self->_recursiveSearch($sub_container, $service_to_find);
            return $service if defined $service;
        }
    }
    return undef;
}

1;

__END__

=head1 NAME

IOC::Visitor::SearchForService - Visitor for searching a IOC::Container hierarchy

=head1 SYNOPSIS

  use IOC::Visitor::SearchForService;

=head1 DESCRIPTION

This is a IOC::Visitor object used for searching a IOC::Container hierarchy.

          +------------------+
          | <<IOC::Visitor>> |
          +------------------+
                   |
                   ^
                   |
   +--------------------------------+
   | IOC::Visitor::SearchForService |
   +--------------------------------+

=head1 METHODS

=over 4

=item B<new ($name)>

Creates a new instance which will search for a Service at a given C<$name>. If no C<$name> is given, than an B<IOC::InsufficientArguments> exception is thrown. 

=item B<visit ($container)>

Given a C<$container>, the invocant will attempt to locate the service with the C<$name> (given to the constuctor) from within the C<$container>'s hierarchy.

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

