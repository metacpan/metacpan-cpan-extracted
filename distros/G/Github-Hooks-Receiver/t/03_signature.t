use strict;
use warnings;
use utf8;

use Test::More 0.98;
use Plack::Test;
use HTTP::Request::Common;

use Github::Hooks::Receiver;
use Github::Hooks::Receiver::Declare;

subtest 'oop interface' => sub {
    my $counter;

    my $receiver = Github::Hooks::Receiver->new(secret => 'secret1234');

    $receiver->on(sub {
        $counter++;
    });

    $receiver->on(hoge => sub {
        $counter++;
    });

    my $app = $receiver->to_app;

    test_psgi $app => sub {
        my $cb  = shift;

        my $req = POST '/', [
            payload => '{"hoge":"fuga"}',
        ], 'X-GitHub-Event' => 'hoge', 'X-Hub-Signature' => 'sha1=3dff16c4e20f299484409ebc093e983286f5d0c3';

        my $res = $cb->($req);
        is $res->content, 'OK';
        is $counter, 2;

        $req = POST '/', [
            payload => '{"hoge":"fuga"}',
        ], 'X-GitHub-Event' => 'hoge';

        $res = $cb->($req);
        is $res->content, 'Forbidden';
        is $counter, 2;

        $req = POST '/', [
            payload => '{"hoge":"fuga"}',
        ], 'X-GitHub-Event' => 'hoge', 'X-Hub-Signature' => 'invalid signature';

        $res = $cb->($req);
        is $res->content, 'Forbidden';
        is $counter, 2;
    };
};

subtest 'dsl interface' => sub {
    my $counter;

    my $receiver = receiver {
        secret 'secret1234';
        on sub {
            $counter++;
        };

        on hoge => sub {
            $counter++;
        };
    };

    my $app = $receiver->to_app;

    test_psgi $app => sub {
        my $cb  = shift;

        my $req = POST '/', [
            payload => '{"hoge":"fuga"}',
        ], 'X-GitHub-Event' => 'hoge', 'X-Hub-Signature' => 'sha1=3dff16c4e20f299484409ebc093e983286f5d0c3';

        my $res = $cb->($req);
        is $res->content, 'OK';
        is $counter, 2;

        $req = POST '/', [
            payload => '{"hoge":"fuga"}',
        ], 'X-GitHub-Event' => 'hoge';

        $res = $cb->($req);
        is $res->content, 'Forbidden';
        is $counter, 2;

        $req = POST '/', [
            payload => '{"hoge":"fuga"}',
        ], 'X-GitHub-Event' => 'hoge', 'X-Hub-Signature' => 'invalid signature';

        $res = $cb->($req);
        is $res->content, 'Forbidden';
        is $counter, 2;
    };
};

done_testing;
