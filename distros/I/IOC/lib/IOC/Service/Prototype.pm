
package IOC::Service::Prototype;

use strict;
use warnings;

our $VERSION = '0.02';

use IOC::Exceptions;

use base 'IOC::Service';

sub instance {
    my ($self) = @_;
    (defined($self->{container}))
        || throw IOC::IllegalOperation "Cannot create a service instance without setting container";    
    # we need to be sure to not store this value
    # otherwise we will add a ref count to it 
    return $self->{block}->($self->{container});
}

1;

__END__

=head1 NAME

IOC::Service::Prototype - An IOC Service object which returns a prototype instance

=head1 SYNOPSIS

  use IOC::Service::Prototype;

=head1 DESCRIPTION

This class essentially can be used just like IOC::Service, the only difference is that it will return a new instance of the component each time rather than a singleton instance.

        +--------------+
        | IOC::Service |
        +--------------+
               |
               ^
               |
   +-------------------------+
   | IOC::Service::Prototype |
   +-------------------------+
   
=head2 A Note about Lifecycles   
   
One important distinction to make about this lifecycle as opposed to the singleton lifecycle is that we do not make any references to the component within the service, so you have total control over the scope of your component. This means that once the prototypical component you retrieved from a IOC::Service::Prototype container goes out of scope, it's C<DESTROY> method will be called (assuming all it's own references have been cleaned up). 
   
=head1 METHODS

=over 4

=item B<instance>

This is the only method this subclass overrides. It changes this behavior to return a new instance of the component each time, as opposed to the normal Singleton instance.

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

=item Prototype-style components are supported by the Spring Framework.

L<http://www.springframework.com>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

