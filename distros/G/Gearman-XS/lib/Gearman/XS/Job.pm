# Gearman Perl front end
# Copyright (C) 2013 Data Differential, http://datadifferential.com/
# Copyright (C) 2009-2010 Dennis Schoen
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.9 or,
# at your option, any later version of Perl 5 you may have available.

package Gearman::XS::Job;

use strict;
use warnings;

our $VERSION= '0.15';

use Gearman::XS;

1;
__END__

=head1 NAME

Gearman::XS::Job - Perl job for gearman using libgearman

=head1 DESCRIPTION

Gearman::XS::Job is a job class for the Gearman distributed job system
using libgearman.

=head1 METHODS

=head2 $job->workload()

Get the workload for a job.

=head2 $job->handle()

Get job handle.

=head2 $job->function_name()

Get the function name associated with a job.

=head2 $job->unique()

Get the unique ID associated with a job.

=head2 $job->send_status($numerator, $denominator)

Send status information for a running job. Returns a standard gearman return
value.

=head2 $job->send_data($data)

Send data for a running job. Returns a standard gearman return value.

=head2 $job->send_fail()

Send fail status for a job. Returns a standard gearman return value.

=head2 $job->send_complete($result)

Send result and complete status for a job. Returns a standard gearman return
value.

=head2 $job->send_warning($warning)

Send warning for a running job. Returns a standard gearman return value.

=head1 BUGS

Any in libgearman plus many others of my own.

=head1 COPYRIGHT

Copyright (C) 2013 Data Differential, ala Brian Aker, http://datadifferential.com/
Copyright (C) 2009-2010 Dennis Schoen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Brian Aker <brian@tangent.org>

=cut
