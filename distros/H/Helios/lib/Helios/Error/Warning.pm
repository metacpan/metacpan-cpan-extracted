package Helios::Error::Warning;

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

Helios::Error::Warning -  exception class for Helios indicating a job was
successful but it encountered errors during processing

=head1 SYNOPSIS

	# in dodgy code:

	use Error qw(:try);

	sub dodgy {

		... dodgy stuff ...


		if ($success_but_a_bit_off) {
			throw Helios::Error::Warning("This job succeeded with errors");
		}
	}


	# in the caller of the dodgy code:

	use Error qw(:try);

	try {
		dodgy(@params);
	} catch Helios::Error::Warning with {
		my $e = shift;
		$self->logMsg( $e->text() );
		$self->jobCompleted($job);
	};

=head1 DESCRIPTION

Helios::Error::Warning can be used to identify errors that were not severe enough to cause a job 
to fail, but probably should be logged.  Normally this would mean simply logging the error, and 
calling the $job->completed() method as normal.

Compare this to Helios::Error::Fatal and FatalNoRetry, which imply errors that caused the job to 
fail completely.

=head1 SEE ALSO

L<Helios::Error::FatalNoRetry>, L<Helios::Error::Fatal>, L<Error>, L<Error::Simple>

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

