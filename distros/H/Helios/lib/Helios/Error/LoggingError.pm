package Helios::Error::LoggingError;

use 5.008;
use strict;
use warnings;
use base qw(Helios::Error::BaseError);

our $VERSION = '2.82';

1;
__END__;

=head1 NAME

Helios::Error::LoggingError - exception class for Helios indicating an error 
occurred in the logging subsystem

=head1 SYNOPSIS

 use Helios::Error::LoggingError;

 =head1 DESCRIPTION

Helios::Error::LoggingError exceptions indicate a problem with the Helios 
logging subsystem.  They are designed to be thrown by Helios::Logger 
subclasses like Helios::Logger::Internal, HeliosX::Logger::Syslog, etc.

=head1 SEE ALSO

L<Helios::Service>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-12 Andrew Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

