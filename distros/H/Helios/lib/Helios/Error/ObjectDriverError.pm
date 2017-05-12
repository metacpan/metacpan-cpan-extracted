package Helios::Error::ObjectDriverError;

use 5.008;
use strict;
use warnings;
use base 'Helios::Error::BaseError';

our $VERSION = '2.82';

1;
__END__

=head1 NAME

Helios::Error::ObjectDriveError - exception class for Helios indicating an  
object driver error occurred

=head1 SYNOPSIS

 use Helios::Error::ObjectDriverError;
 Helios::Error::ObjectDriverError->throw("An ObjectDriver error!");

=head1 DESCRIPTION

When the Helios::ObjectDriver class encounters a problem, it will throw a 
ObjectDriverError exception. 

=head1 SEE ALSO

L<Helios::ObjectDriver>, L<Helios::Error>, L<Helios::Error::BaseError>, L<Error> 

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-4 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut
