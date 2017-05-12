package Helios::Error;

use 5.008;
use strict;
use warnings;

use Helios::Error::BaseError;

use Helios::Error::Warning;
use Helios::Error::Fatal;
use Helios::Error::FatalNoRetry;

use Helios::Error::DatabaseError;
use Helios::Error::InvalidArg;
use Helios::Error::LoggingError;
use Helios::Error::ConfigError;
use Helios::Error::JobTypeError;
use Helios::Error::ObjectDriverError;

our $VERSION = '2.82';

# FILE CHANGE HISTORY
# 2011-12-18: Added new Helios::Error::BaseError and LoggingError classes.
# 2012-07-28: Added new Helios::Error::ConfigError class.
# [LH] [2014-10-10]: Added JobTypeError and ObjectDriverError classes.  Added 
# '5.008', 'strict' and 'warnings' pragmas for Kwalitee ratings.

1;

__END__;

=head1 NAME

Helios::Error - a convenience class to import all Helios::Error exception classes

=head1 SYNOPSIS

	use Helios::Error;

=head1 DESCRIPTION

Use the above single line in your code instead of:

	use Helios::Error::BaseError;
	use Helios::Error::Warning;
	use Helios::Error::Fatal;
	use Helios::Error::FatalNoRetry;
	use Helios::Error::DatabaseError;
	use Helios::Error::InvalidArg;
	use Helios::Error::LoggingError;

That way all the base Helios exceptions can be loaded by one line.

=head1 SEE ALSO

L<Helios::Error::Fatal>, L<Helios::Error::Warning>, L<Error>, L<Error::Simple>

=head1 AUTHOR

Andrew Johnson, E<lt>ajohnson@ittoolbox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-8 by CEB Toolbox, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

