# Gearman Perl front end
# Copyright (C) 2013 Data Differential, http://datadifferential.com/
# Copyright (C) 2009-2010 Dennis Schoen
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.9 or,
# at your option, any later version of Perl 5 you may have available.

package Gearman::XS::Task;

use strict;
use warnings;

our $VERSION= '0.15';

use Gearman::XS;

1;
__END__

=head1 NAME

Gearman::XS::Task - Perl task for gearman using libgearman

=head1 DESCRIPTION

Gearman::XS::Task is a task class for the Gearman distributed job system
using libgearman.

=head1 METHODS

=head2 $task->job_handle()

Get job handle for a task.

=head2 $task->data()

Get data being returned for a task.

=head2 $task->data_size()

Get data size being returned for a task.

=head2 $task->function_name()

Get function name associated with a task.

=head2 $task->numerator()

Get the numerator of percentage complete for a task.

=head2 $task->denominator()

Get the denominator of percentage complete for a task.

=head2 $task->unique()

Get unique identifier for a task.

=head2 $task->is_known()

Get status on whether a task is known or not. Returns 1 if known, empty string
if not.

=head2 $task->is_running()

Get status on whether a task is running or not. Returns 1 if running, empty
string if not.

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
