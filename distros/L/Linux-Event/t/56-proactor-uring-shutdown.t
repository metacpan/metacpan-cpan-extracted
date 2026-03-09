use v5.36;
use Test2::V0;
use Socket qw(AF_UNIX PF_UNSPEC SOCK_STREAM SHUT_RD SHUT_WR SHUT_RDWR);

use lib 'lib';

BEGIN {
    eval { require IO::Uring; 1 } or plan skip_all => 'IO::Uring is not installed';
}

use Linux::Event::Clock;
use Linux::Event::Proactor;

subtest 'uring shutdown read write both' => sub {
    my $clock = Linux::Event::Clock->new(clock => 'monotonic');
    my $loop  = Linux::Event::Proactor->new(backend => 'uring', clock => $clock);

    for my $how ('read', 'write', 'both', SHUT_RD, SHUT_WR, SHUT_RDWR) {
        socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair failed: $!";

        my $seen = 0;
        my $op = $loop->shutdown(
            fh => $a,
            how => $how,
            on_complete => sub ($op, $result, $ctx) {
                $seen++;
                is $op->kind, 'shutdown', 'kind is shutdown';
                is $result, {}, 'shutdown result shape';
            },
        );

        ok $op->is_pending, 'shutdown pending before run';

        my $guard = 1000;
        while ($op->is_pending && $guard--) {
            $loop->run_once;
        }

        ok !$op->is_pending, 'shutdown completed';
        ok $op->success, 'shutdown succeeded';
        is $seen, 1, 'callback ran once';
    }
};

done_testing;
