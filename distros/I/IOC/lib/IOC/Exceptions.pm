
package IOC::Exceptions;

use strict;
use warnings;

our $VERSION = '0.07';

use Class::Throwable qw(
        IOC::NotFound
        IOC::ServiceNotFound
        IOC::ServiceAlreadyExists
        IOC::UnableToLocateService
        IOC::ContainerNotFound
        IOC::ContainerAlreadyExists
        IOC::IllegalOperation
        IOC::InsufficientArguments
        IOC::InitializationError
        IOC::ClassLoadingError
        IOC::ConstructorNotFound
        IOC::MethodNotFound
        IOC::OperationFailed
        IOC::ConfigurationError
        );

$Class::Throwable::DEFAULT_VERBOSITY = 2;

1;

__END__

=head1 NAME

IOC::Exceptions - Exception objects for the IOC Framework

=head1 SYNOPSIS

  use IOC::Exceptions;

=head1 DESCRIPTION

This module creates a number of exception classes which are used in other parts of the IOC framework.

=head1 EXCEPTIONS

=over 4

=item B<IOC::ServiceNotFound>

=item B<IOC::ServiceAlreadyExists>

=item B<IOC::ContainerNotFound>

=item B<IOC::ContainerAlreadyExists>

=item B<IOC::NotFound>

=item B<IOC::InsufficientArguments>

=item B<IOC::IllegalOperation>

=item B<IOC::InitializationError>

=item B<IOC::ClassLoadingError>

=item B<IOC::ConstructorNotFound>

=item B<IOC::MethodNotFound>

=item B<IOC::OperationFailed>

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

=item L<Class::Throwable>

The exceptions are generated inline and all inherit from by another module I wrote called L<Class::Throwable>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

