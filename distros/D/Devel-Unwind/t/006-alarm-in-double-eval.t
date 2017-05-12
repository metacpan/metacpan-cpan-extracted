use strict;
use warnings;

use Test::More;
use Devel::Unwind;
use Time::HiRes qw(alarm sleep);

$SIG{ALRM} = sub {
    unwind FOO;
};

eval {
    mark FOO {
        eval { #[A]
            eval {
                alarm 0.2;
                sleep 0.5;
                fail "In 1st eval after sleep";
                1;
            } or do {
                fail "In do block of 1st eval after sleep";
            };
        } or do {
            fail "This do block should never be executed"; # [B]
        };
        fail "After eval but still inside mark block";
    };
    die "die after hitting resuming at mark"; # [C]
    1;
} or do {
    like($@, qr/^die after hitting resuming at mark/);
};
done_testing;

# Before I added code to cleanup the context stack after resuming execution
# the my custom return op I noted the following:
#
# Execution jumps from [C] to [A] I believe this means we need to at least
# pop the context blocks we've jumped past, [B] is gettings its cx->blk_eval.retop
# from the eval context of [A]
