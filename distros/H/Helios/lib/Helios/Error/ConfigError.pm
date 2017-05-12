package Helios::Error::ConfigError;

use 5.008;
use strict;
use warnings;
use base qw(Helios::Error::BaseError);

our $VERSION = '2.82';

1;
__END__;

=head1 NAME

Helios::Error::ConfigError - exception class for Helios indicating a  
configuration error occurred

=head1 SYNOPSIS

 use Helios::Error::ConfigError;
 -OR-
 use Helios::Error;    # automatically uses ConfigError and other exceptions

=head1 DESCRIPTION

When the Helios::Config class or other configuration mechanisms encounter a 
problem with the Helios configuration, they will throw a ConfigError exception. 

=head1 SEE ALSO

L<Helios::Config>, L<Helios::Error>, 
L<Helios::Error::BaseError>, L<Error> 

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

