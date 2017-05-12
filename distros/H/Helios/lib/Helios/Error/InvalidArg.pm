package Helios::Error::InvalidArg;

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

Helios::Error::InvalidArg - exception class for Helios indicating a job's 
args are invalid

=head1 SYNOPSIS

 use Helios::Error::InvalidArg;
 -OR-
 use Helios::Error;    # automatically uses InvalidArgXML and other exceptions

=head1 DESCRIPTION

If a Helios function encounters a problem with job arguments (either submitting or parsing the 
XML of), it should throw an InvalidArg error to indicate that the job can't be processed further 
(or most probably, since the arguments are invalid, at all).

=head1 SEE ALSO

L<Helios::Error::FatalNoRetry>, L<Helios::Error::Warning>, L<Error>, L<Error::Simple>

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

