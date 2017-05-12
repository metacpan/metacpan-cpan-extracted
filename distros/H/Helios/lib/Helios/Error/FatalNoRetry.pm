package Helios::Error::FatalNoRetry;

use 5.008;
use strict;
use warnings;
use base qw(Helios::Error::BaseError);

our $VERSION = '2.82';

# 2011-12-18:  Changed base class from Error::Simple to Helios::Error::BaseError.
# [LH] [2014-10-10]: Added 5.008, strict, and warnings pragmas for Kwalitee 
# ratings.

1;
__END__;

=head1 NAME

Helios::Error::FatalNoRetry - fatal exception class for Helios indicating a 
job failed and the error was so serious the job should not be reattempted.

=head1 SYNOPSIS

	# in dodgy code:

	use Error qw(:try);

	sub dodgy {

		if ($something_bad) {
			throw Helios::Error::Fatal("Ah! Thats not gone well at all!");
		}
	}


	# in the caller of the dodgy code:

	use Error qw(:try);

	try {
		dodgy(@params);
	} catch Helios::Error::FatalNoRetry with {
		my $e = shift;
		$self->logMsg( $e->text() );
		$self->failedJob( $job, $e->text() );
	};

=head1 DESCRIPTION

Helios::Error::FatalNoRetry can be used to identify errors that cause a job not only to fail but 
to not be re-attempted by the job processing system.  This implies an error that should be logged 
and the Schwartz job in question should be marked as permanently failed (with the 
Helios::Worker->failedJobPermanent() method).

Compare this to Helios::Error::Fatal, which implies a similar circumstance except the 
error isn't severe enough to prevent the system from re-attempting later.


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
