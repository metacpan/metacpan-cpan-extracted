use strict;
package Event::Stats;
use Carp;
use Event 0.53;
use base ('Exporter', 'DynaLoader');
our $VERSION = '1.02';
our @EXPORT_OK = qw(round_seconds idle_time total_time);

__PACKAGE__->bootstrap($VERSION);

sub enforce_max_callback_time {
    # a bit kludged
    if (@_) {
	my ($yes) = @_;
	$SIG{ALRM} = sub { Carp::confess("Event timed out") } if $yes;
	_enforce_max_callback_time($yes);
    } else {
	_enforcing_max_callback_time()
    }
}

1;
__END__

=head1 NAME

Event::Stats - Event loop statistics

=head1 SYNOPSIS

XXX

=head1 DESCRIPTION

Instrument the Event module in order to gather statistics.

=head1 API

=over 4

=item collect($yes)

Determines whether statistics are collected.  Arithmetically adds $yes
to the usage count.  Stats are enabled while the usage count is
positive.

=item $round_sec = round_seconds($sec)

Statistics are not collected in one second intervals.  This function
converts a *desired* time interval into an *available* time interval.
Units are in seconds.

=item $elapse = total_time($sec)

Due to long-running callbacks, measurement intervals may take longer
than expected.  This function returns the actual clock-time for a
given measurement interval.

=item ($rans, $dies, $elapse) = idle_time($sec)

=item ($runs, $dies, $elapse) = $watcher->stats($sec)

Return statistics for the last $sec seconds of operation.  Three
numbers are returned: the number of times the callback has been
invoked, the number of uncaught exceptions and the number of seconds
spent within the callback.  Also see L<NetServer::ProcessTop>.

=item enforce_max_callback_time($yes)

Useful for debugging. XXX

=back

=head1 SUPPORT

Please direct your insights and complaints to the perl-loop@perl.org
mailing list!

=head1 COPYRIGHT

Copyright © 1999, 2000 Joshua Nathaniel Pritikin.  All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
