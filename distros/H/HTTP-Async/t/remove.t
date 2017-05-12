use strict;
use warnings;

use Test::More tests => 21;

use Data::Dumper;

use HTTP::Request;
use HTTP::Async;

## Set up - create an Async object with ten items in its queue

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

# To ensure that remove and remove_all work on all three states, we need to
# have items in all three states when we call them.
#
# The three states are: to_send, in_progress, and to_return.
#
# We can create them by adding items which will run quickly, items which will
# trickle data slowly, and items which are not running.
#
# XXX we currently only test in_progress and to_return as items are hard to
# keep in the to_send queue, HTTP::Async is too good at moving them into the
# to_progress queue!
{
    my $s        = TestServer->new();
    my $url_root = $s->started_ok("starting a test server");

    my $q = HTTP::Async->new;

    is $q->total_count, 0, "total_count starts at zero";

    my %type_to_id = populate_queues($q, $url_root);

    ## Remove - test remove() to remove a single item

    for my $type (sort keys %type_to_id) {
        my $id = $type_to_id{$type};
        ok $q->remove($id), "removed '$type' item with id '$id'";
    }

    ok !$q->remove(123456), "removal of bad id '123456' returns false";

    is $q->total_count, 0, "total_count is now zero";
}

{
    my $s        = TestServer->new();
    my $url_root = $s->started_ok("starting a test server");

    my $q = HTTP::Async->new;

    is $q->total_count, 0, "total_count starts at zero";

    my %type_to_id = populate_queues($q, $url_root);

    ## Remove All - test remove_all() removes all queued items

    ok $q->remove_all, "removed all items";

    ok !$q->remove_all, "remove_all() on empty queue returns false";

    is $q->total_count, 0, "total_count is now zero";
}

##############################################################################

sub populate_queues {
    my $q = shift;
    my $url_root = shift;

    my %type_to_id;

    # fast / to_return
    {
        my $url = "$url_root?trickle=1";
        my $req = HTTP::Request->new('GET', $url);
        ok $type_to_id{'fast'} = $q->add($req), "added fast / to_return item";

        for (1 .. 10) {
            $q->poke;
            last if $q->to_return_count;
            sleep 1;
        }

        if (!$q->to_return_count) {
            diag Dumper $q;
        }

        is $q->to_return_count, 1, "to_return_count is one";
    }

    # slow / in_progress
    {
        my $url = "$url_root?trickle=1000";
        my $req = HTTP::Request->new('GET', $url);
        ok $type_to_id{'slow'} = $q->add($req), "added slow / in_progress item";
        $q->poke;
        is $q->in_progress_count, 1, "in_progress_count is one";
    }

    is $q->total_count, 2, "total_count is now two";

    return %type_to_id;
}
