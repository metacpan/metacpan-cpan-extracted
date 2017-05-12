
package IOC::Visitor::SearchForContainer;

use strict;
use warnings;

our $VERSION = '0.03';

use Scalar::Util qw(blessed);

use IOC::Interfaces;
use IOC::Exceptions;

use base 'IOC::Visitor';

sub new {
    my ($_class, $container_name) = @_;
    ($container_name) 
        || throw IOC::InsufficientArguments "You must provide a name of a container to find";
    my $class = ref($_class) || $_class;
    my $visitor = {
        container_to_find => $container_name
        };
    bless($visitor, $class);
    return $visitor;
}

sub visit {
    my ($self, $container) = @_;
    (blessed($container) && $container->isa('IOC::Container'))
        || throw IOC::InsufficientArguments "You must provide an IOC::Container object to search";
    my $container_to_find = $self->{container_to_find};
    return $self->_recursiveSearch($container, $container_to_find);
}

sub _recursiveSearch {
    my ($self, $container, $container_to_find) = @_;
    # if we have it stored, then return it
    return $container->getSubContainer($container_to_find)
        if $container->hasSubContainer($container_to_find);    
    # otherwise, loop through all the sub-containers
    # sort the names too, which will make sure the
    # search will roughly take the same amount of time
    # each time we do it, otherwise we are at the 
    # mercy of the hash ordering 
    foreach my $sub_container_name (sort $container->getSubContainerList()) {
        # otherwise we need to search the next level
        my $sub_container = $container->getSubContainer($sub_container_name);
        $self->_recursiveSearch($sub_container, $container_to_find) 
            if $sub_container->hasSubContainers();
    }
    return undef;
}

1;

__END__

=head1 NAME

IOC::Visitor::SearchForContainer - Visitor for searching a IOC::Container hierarchy

=head1 SYNOPSIS

  use IOC::Visitor::SearchForContainer;

=head1 DESCRIPTION

This is a IOC::Visitor object used for searching a IOC::Container hierarchy

          +------------------+
          | <<IOC::Visitor>> |
          +------------------+
                    |
                    ^
                    |
   +----------------------------------+
   | IOC::Visitor::SearchForContainer |
   +----------------------------------+

=head1 METHODS

=over 4

=item B<new ($name)>

Creates a new instance which will search for a Container at a given C<$name>. If no C<$name> is given, than an B<IOC::InsufficientArguments> exception is thrown. 

=item B<visit ($container)>

Given a C<$container>, the invocant will attempt to locate the container with the C<$name> (given to the constuctor) from within the C<$container>'s hierarchy.

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

