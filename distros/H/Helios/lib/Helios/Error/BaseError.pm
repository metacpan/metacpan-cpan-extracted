package Helios::Error::BaseError;

use 5.008;
use strict;
use warnings;
use base qw(Error::Simple);

our $VERSION = '2.82';

1;
__END__


=head1 NAME

Helios::Error::BaseError - base exception class for Helios services

=head1 SYNOPSIS

 use Helios::Error::BaseError;
 -OR-
 use Helios::Error;    # automatically loads and imports this and other exceptions

=head1 DESCRIPTION

Helios::Error::BaseError is the base class for all the exception classes in 
the Helios::Error hierarchy.

You can distinguish between Helios errors and other exceptions attempting to 
catch Helios::Error::BaseError rather than each specific class in the 
Helios::Error hierarchy.

Helios::Error::BaseError is actually a subclass of Error::Simple from the 
Error CPAN distribution.  You can use the try/catch features of the Error 
module, the Perl built-in eval syntax, or another module with exception 
handling features to utilize Helios::Error::BaseError and its subclasses.

=head1 SEE ALSO

L<Helios::Error>, L<Error>, L<Error::Simple>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Andrew Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut


