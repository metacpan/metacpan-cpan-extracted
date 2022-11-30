#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Future::AsyncAwait::Metrics 0.01;

use v5.14;
use warnings;

use Metrics::Any 0.09 '$metrics',
   name_prefix => [ 'asyncawait' ],
   strict      => 1;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Future::AsyncAwait::Metrics> - report metrics from C<Future::AsyncAwait> to C<Metrics::Any>

=head1 SYNOPSIS

   use Future::AsyncAwait::Metrics;

   # Additional metrics will now be reported

=head1 DESCRIPTION

This module provides no functions or other import symbols. Instead, by simply
loading it somewhere in the program, additional metrics are created and
reported to L<Metrics::Any> about the operation of L<Future::AsyncAwait>.

=cut

=head1 METRICS

The following metrics are reported:

=head2 asyncawait_suspends

A counter of the number of times an C<async sub> has been suspended.

=head2 asyncawait_resumes

A counter of the number of times an C<async sub> has been resumed.

=head2 asyncawait_current_subs

A gauge giving the current count of C<async sub> instances currently
suspended.

=head2 asyncawait_states_created

A counter of the number of times that C<async sub> context storage has been
created. This may be less than C<asyncawait_suspends> because storage is
reused for multiple C<await> calls within any one function invocation.

=head2 asyncawait_states_destroyed

A counter giving the number of times that C<async sub> context storage has
been destroyed.

=head2 asyncawait_current_states

A gauge giving the current count of C<async sub> context storage instances.
This may be less than C<asyncawait_current_subs> because not all of them may
be currently suspended.

=cut

$metrics->make_counter( suspends =>
   description => "Count of the number of times an async sub has been suspended",
);

$metrics->make_counter( resumes =>
   description => "Count of the number of times an async sub has been resumed",
);

$metrics->make_gauge( current_subs =>
   description => "Current number of suspended async subs",
);

$metrics->make_counter( states_created =>
   description => "Count of the number of times async sub state storage has been created",
);
$metrics->make_counter( states_destroyed =>
   description => "Count of the number of times async sub state storage has been destroyed",
);
$metrics->make_gauge( current_states =>
   description => "Current number of async sub state storage instances",
);

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
