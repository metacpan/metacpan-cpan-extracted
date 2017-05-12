
package IOC::Service::Parameterized;

use strict;
use warnings;

our $VERSION = '0.01';

use Scalar::Util qw(blessed);

use IOC::Exceptions;

use base 'IOC::Service::Prototype';

sub instance {
    my ($self, %params) = @_;
    (defined($self->{container}))
        || throw IOC::IllegalOperation "Cannot create a service instance without setting container";    
    # we need to be sure to not store this value
    # otherwise we will add a ref count to it 
    return $self->{block}->($self->{container}, %params);
}

sub deferred {
    throw IOC::IllegalOperation "Parameterized services cannot be deferred";
}

1;

__END__

=pod

=head1 NAME

IOC::Service::Parameterized - An IOC Service object which accepts a set of parameters for the instance

=head1 DESCRIPTION

This is just like IOC::Service::Prototype, expect that it will accepts a set of key/value parameters 
to the C<instance> method. It is used to support IOC::Service::Parameterized.

          +--------------+
          | IOC::Service |
          +--------------+
                 |
                 ^
                 |
  +-----------------------------+
  | IOC::Service::Parameterized |
  +-----------------------------+

=head1 CAVEAT

It does not make any sense to have ConstructorInjection or SetterInjection subclasses of this, so 
they will probably never get created (at least not by me). 

=head1 METHODS

=over 4

=item B<instance (%params)>

This method returns the literal value held by the service object based on the parameters.

=item B<setContainer ($c)>

This just makes sure that our service is always being added to IOC::Container::Parameterized 
container objects. Otherwise the parameterization wouldn't work.

=item B<deferred>

A parameterized service does not support being deferred.

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

