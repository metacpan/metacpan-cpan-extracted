=head1 NAME

37_negative_retry_delay.t - HAC-045: a negative RETRY_DELAY reached
sleep() as-is, producing "sleep() with negative argument" on every
retry - same class of missing-validation gap as HAC-044 (negative retry
count), just in the delay rather than the count.

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use HTTP::API::Client;
use FakeUA;

{
    local $ENV{RETRY_FAIL_RESPONSE} = 1;
    local $ENV{RETRY_DELAY}         = -5;

    my $api = HTTP::API::Client->new;
    $api->ua( FakeUA->new(500) );

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    $api->get("http://x/");

    ok !( grep { /negative argument/ } @warnings ),
        "a negative RETRY_DELAY no longer produces a 'negative argument' warning";
}

done_testing;
