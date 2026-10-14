package ForgeOps::Tracker::DeliveryStatus;

use strict;
use warnings;

# What became of one delivery attempt. A bare true/false could not tell "the server will never take
# this payload" apart from "try again later", so a batch a plan or a validation rule refused was
# re-sent at every flush for as long as the process lived. Ported from
# gems/forge_ops_tracker/lib/forge_ops_tracker/delivery_status.rb.
#
# Client's own deliver* methods still answer 1 or 0 (1 only for DELIVERED); the status of the attempt
# behind that answer is Client->last_status.
use constant {
    DELIVERED => 'delivered',    # any 2xx
    REJECTED  => 'rejected',     # a 4xx other than 408 and 429: the same payload can only fail again
    FAILED    => 'failed',       # a network error, a timeout, a 5xx, a 408 or a 429: worth another attempt
};

# After this many flushes in a row that failed for now, a batch is dropped rather than kept for yet
# another attempt, so an outage can never pin the same data in memory for the life of the process.
use constant MAX_FAILED_FLUSHES => 5;

# HTTP::Tiny reports a network error or a timeout as its own 599, which lands in FAILED like any 5xx.
sub for_code {
    my ($code) = @_;
    return FAILED unless defined $code && $code =~ /\A\d+\z/;
    return DELIVERED if $code >= 200 && $code < 300;
    return REJECTED if $code >= 400 && $code < 500 && $code != 408 && $code != 429;
    return FAILED;
}

# Reads whatever a deliver callback handed back. A status passes through; anything else is read the
# way the old boolean contract was (true delivered, false failed for now), so a callback that still
# answers 1 or 0 keeps working.
sub from {
    my ($result) = @_;
    if (defined $result && !ref($result)) {
        return $result if $result eq DELIVERED || $result eq REJECTED || $result eq FAILED;
    }
    return $result ? DELIVERED : FAILED;
}

# The status behind a client's 1/0 answer: its own last_status when it has one (a test double, or a
# client written against the old contract, may not), otherwise failed for now.
sub of_client {
    my ($client, $delivered) = @_;
    return DELIVERED if $delivered;
    my $status = eval { $client->can('last_status') ? $client->last_status : undef };
    return (defined $status && $status eq REJECTED) ? REJECTED : FAILED;
}

# settle(\$failed_flushes, $status): decides whether the batch a flush just sent is done with.
# Returns (1) for a delivered batch, (1, $why) for one to drop ($why is what to log), and (0) for
# one to keep for the next flush. $failed_flushes is the caller's own threads::shared counter of
# flushes in a row that failed, and the caller holds its lock: a flush can run on the background
# thread or on the main one.
sub settle {
    my ($failed_flushes, $status) = @_;

    if ($status eq DELIVERED) {
        ${$failed_flushes} = 0;
        return (1);
    }
    if ($status eq REJECTED) {
        ${$failed_flushes} = 0;
        return (1, 'the server rejected them and will not accept a retry');
    }

    ${$failed_flushes}++;
    return (0) if ${$failed_flushes} < MAX_FAILED_FLUSHES;
    ${$failed_flushes} = 0;
    return (1, MAX_FAILED_FLUSHES . ' flushes in a row failed');
}

1;
