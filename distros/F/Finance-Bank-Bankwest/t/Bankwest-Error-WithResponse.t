use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Exception;

use HTTP::Response ();
use Scalar::Util 'refaddr';

use MooseX::Declare;
class t::WithResponseConsumer
    with Finance::Bank::Bankwest::Error::WithResponse
{
}

test 'fail with no arguments' => sub {
    throws_ok(
        sub { t::WithResponseConsumer->new },
        qr/response/,
        'must not instantiate without an HTTP::Response',
    );
};

test 'succeed with single argument' => sub {
    my $r = HTTP::Response->new;
    my $c = t::WithResponseConsumer->new($r);
    is refaddr $r, refaddr $c->response,
        'response should return the right response';
};

run_me;
done_testing;
