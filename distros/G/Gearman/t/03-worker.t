use strict;
use warnings;

# OK gearmand v1.0.6
# OK Gearman::Server v1.130.2

use Net::EmptyPort qw/ empty_port /;
use Test::More;
use Test::Timer;
use Test::Exception;

use lib '.';
use t::Server ();

my $mn = "Gearman::Worker";
use_ok($mn);

can_ok(
    $mn, qw/
        _get_js_sock
        _job_request
        _on_connect
        _register_all
        _set_ability
        _uncache_sock
        job_servers
        register_function
        reset_abilities
        send_work_complete
        send_work_data
        send_work_exception
        send_work_fail
        send_work_status
        send_work_warning
        unregister_function
        work
        /
);

subtest "new", sub {
    plan tests => 8;

    my $w = new_ok($mn);
    isa_ok($w, 'Gearman::Objects');

    is(ref($w->{$_}), "HASH", "$_ is a hash ref") for qw/
        last_connect_fail
        down_since
        can
        timeouts
        /;
    ok($w->{client_id} =~ /^\p{Lowercase}+$/, "client_id");

SKIP: {
        $ENV{AUTHOR_TESTING}
            || skip 'GEARMAN_WORKER_USE_STDIO without $ENV{AUTHOR_TESTING}', 1;

        $ENV{GEARMAN_WORKER_USE_STDIO} = 1;
        throws_ok {
            $mn->new(debug => 1);
        }
        qr/Unable to initialize connection to gearmand/,
            "GEARMAN_WORKER_USE_STDIO env";
        undef($ENV{GEARMAN_WORKER_USE_STDIO});
    } ## end SKIP:
};

subtest "register_function", sub {
    plan tests => 8;

    my $w = new_ok($mn);
    my ($tn, $to) = qw/foo 2/;
    my $cb = sub {1};

    is $w->register_function($tn => $cb), 0, "register_function($tn)";

    time_ok(
        sub {
            $w->register_function($tn, $to, $cb);
        },
        $to,
        "register_function($to, cb)"
    );

SKIP: {
        my $gts = t::Server->new();
        $gts || skip $t::Server::ERROR, 5;

        my @js = $gts->job_servers(int(rand(2) + 2));
        @js || skip "couldn't start ", $gts->bin(), 5;

        ok $w->job_servers(@js), "set job servers";
        ok $w->register_function($tn, $to, $cb), "register_function";
        is $w->{can}{$tn}, $cb, "can $tn";

        ok $w->unregister_function($tn), "unregister_function";
        is $w->{can}{$tn}, undef, "can not $tn";
    } ## end SKIP:
};

subtest "reset_abilities", sub {
    plan tests => 4;

    my $w = new_ok($mn);
    $w->{can}->{x}      = 1;
    $w->{timeouts}->{x} = 1;

    ok($w->reset_abilities());

    is(keys %{ $w->{can} },      0);
    is(keys %{ $w->{timeouts} }, 0);
};

subtest "work", sub {
    plan tests => 3;
    my $gts = t::Server->new();
SKIP: {
        $gts || skip $t::Server::ERROR, 3;
        my $job_server = $gts->job_servers();
        $job_server || skip "couldn't start ", $gts->bin(), 3;

        my $w = new_ok($mn, [job_servers => $job_server]);
        time_ok(
            sub {
                $w->work(stop_if => sub { pass "work stop if"; });
            },
            12,
            "stop if timeout"
        );
    } ## end SKIP:
};

subtest "_get_js_sock", sub {
    plan tests => 8;

    my $w = new_ok($mn);

    is($w->_get_js_sock(), undef, "_get_js_sock() returns undef");

    $w->{parent_pipe} = rand(10);
    my $js = { host => "127.0.0.1", port => empty_port() };

    is($w->_get_js_sock($js), $w->{parent_pipe}, "parent_pipe");

    delete $w->{parent_pipe};
    is($w->_get_js_sock($js), undef, "_get_js_sock(...) undef");

    my $gts = t::Server->new();
SKIP: {
        $gts || skip $t::Server::ERROR, 4;

        my @job_servers = $gts->job_servers();
        @job_servers || skip "couldn't start ", $gts->bin(), 4;

        ok($w->job_servers(@job_servers));

        $js = $w->job_servers()->[0];
        my $js_str = $w->_js_str($js);
        $w->{last_connect_fail}{$js_str} = 1;
        $w->{down_since}{$js_str}        = 1;

        isa_ok($w->_get_js_sock($js, on_connect => sub {1}), "IO::Socket::IP");
        is($w->{last_connect_fail}{$js_str}, undef);
        is($w->{down_since}{$js_str},        undef);
    } ## end SKIP:
};

subtest "_on_connect-_set_ability", sub {
    my $w = new_ok($mn);
    my $m = "foo";

    is($w->_on_connect(), undef);

    is($w->_set_ability(), 0);
    is($w->_set_ability(undef, $m), 0);
    is($w->_set_ability(undef, $m, 2), 0);
};

done_testing();

