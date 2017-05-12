use strict;
use warnings;

# OK gearmand v1.0.6
# OK Gearman::Server v1.130.2

use Test::More;
use Test::Exception;

use lib '.';
use t::Server ();

my $mn = "Gearman::Client";

use_ok($mn);

can_ok(
    $mn, qw/
        _get_js_sock
        _get_random_js_sock
        _get_task_from_args
        _job_server_status_command
        _option_request
        add_hook
        dispatch_background
        do_task
        get_job_server_clients
        get_job_server_jobs
        get_job_server_status
        get_status
        new_task_set
        run_hook
        /
);

subtest "new", sub {
    my $c = new_ok($mn);
    isa_ok($c, "Gearman::Objects");
    is($c->{backoff_max},           90, join "->", $mn, "{backoff_max}");
    is($c->{command_timeout},       30, join "->", $mn, "{command_timeout}");
    is($c->{exceptions},            0,  join "->", $mn, "{exceptions}");
    is($c->{js_count},              0,  "js_count");
    is(keys(%{ $c->{hooks} }),      0,  join "->", $mn, "{hooks}");
    is(keys(%{ $c->{sock_cache} }), 0,  join "->", $mn, "{sock_cache}");
};

subtest "new_task_set", sub {
    my $c  = new_ok($mn);
    my $h  = "new_task_set";
    my $cb = sub { pass("$h cb") };
    ok($c->add_hook($h, $cb), "add_hook($h, cb)");
    is($c->{hooks}->{$h}, $cb, "$h eq cb");
    isa_ok($c->new_task_set(), "Gearman::Taskset");
    ok($c->add_hook($h), "add_hook($h)");
    is($c->{hooks}->{$h}, undef, "no hook $h");
};

subtest "js socket", sub {
    my $gts = t::Server->new();
    $gts || plan skip_all => $t::Server::ERROR;

    my @job_servers = $gts->job_servers();
    @job_servers || plan skip_all => "no gearmand";

    my $gc = new_ok($mn, [job_servers => [@job_servers]]);
    foreach ($gc->job_servers()) {
        ok(my $s = $gc->_get_js_sock($_), "_get_js_sock($_)") || next;
        isa_ok($s, "IO::Socket::IP");
    }

    ok($gc->_get_random_js_sock());
};

done_testing();
