use strict;
use warnings;

use Storable;
use Test::More;
use Test::Exception;

plan tests => 33;

use_ok("Gearman::Client");
use_ok("Gearman::Taskset");
use_ok("Gearman::Util");

my $mn = "Gearman::Task";
use_ok($mn);

can_ok(
    $mn, qw/
        add_hook
        complete
        data
        exception
        fail
        final_fail
        func handle hash
        is_finished
        mode
        pack_submit_packet
        run_hook
        set_on_post_hooks
        status
        taskset
        timeout
        warning
        wipe
        /
);

my ($f, $arg) = qw/
    foo
    bar
    /;

my %opt = (
    uniq         => rand(10),
    on_complete  => 1,
    on_fail      => 2,
    on_exception => 3,
    on_retry     => undef,
    on_status    => 4,
    retry_count  => 6,
    try_timeout  => 7,
    background   => 1,
    timeout      => int(rand(10)),
);

throws_ok { $mn->new($f, \$arg, { $f => 1 }) } qr/Unknown option/,
    "caught unknown option exception";

my $t = new_ok($mn, [$f, \$arg, {%opt}]);

is($t->func, $f, "func");

is(${ $t->{argref} }, $arg, "argref");

foreach (keys %opt) {
    is($t->can($_) ? $t->$_ : $t->{$_}, $opt{$_}, $_);
}

is($t->{$_}, 0, $_) for qw/
    is_finished
    retries_done
    /;

subtest "priority mode", sub {
    plan tests => 21;

    foreach my $p (qw/low normal high/) {
        my $s = sprintf("submit_job%s", $p eq "normal" ? '' : '_' . $p);
        my $t = new_ok($mn, [$f, undef, { priority => $p }]);

        is($t->_priority(), $p, "$p priority");

        is($t->mode(), $s, "mode of task in $p prioirty");

        $t = new_ok($mn, [$f, undef, { background => 1, priority => $p }]);
        is(
            $t->mode(),
            join('_', $s, "bg"),
            "mode of background task in $p prioirty"
        );
    } ## end foreach my $p (qw/low normal high/)

    {
        my $s = "submit_job";
        my $t = new_ok($mn, [$f, undef]);
        is($t->mode(), $s, "mode of task without explicit priority");

        $s .= "_high";
        $t = new_ok($mn, [$f, undef, { high_priority => 1 }]);
        is($t->mode(), $s, "mode of task with high_priority=1");

        $t = new_ok($mn, [$f, undef, { background => 1, high_priority => 1 }]);
        is(
            $t->mode(),
            join('_', $s, "bg"),
            "mode of background task with high_prioirty=1"
        );
    }
};

my @h = qw/
    on_post_hooks
    on_complete
    on_fail
    on_retry
    on_status
    hooks
    /;

subtest "wipe", sub {
    plan tests => scalar(@h);

    $t->{$_} = 1 for @h;

    $t->wipe();

    is($t->{$_}, undef, $_) for @h;
};

subtest "hook", sub {
    plan tests => 4;

    my $cb = sub { 2 * shift };
    ok($t->add_hook($f, $cb));
    is($t->{hooks}->{$f}, $cb);
    $t->run_hook($f, 2);
    ok($t->add_hook($f));
    is($t->{hooks}->{$f}, undef);
};

subtest "taskset", sub {
    plan tests => 9;

    is($t->taskset, undef, "taskset");
    throws_ok { $t->taskset($f) } qr/not an instance of Gearman::Taskset/,
        "caught taskset($f) exception";

    my $c = new_ok("Gearman::Client");
    my $ts = new_ok("Gearman::Taskset", [$c]);
    ok($t->taskset($ts));
    is($t->taskset(), $ts);
    is($t->hash(),    $t->hash());

    $t->{uniq} = '-';
    is($t->taskset(), $ts);
    is($t->hash(),    $t->hash());
};

subtest "fail", sub {
    plan tests => 2 * scalar(@h) - 1;

    $t->{is_finished} = 1;
    is($t->fail(), undef);

    $t->{is_finished}  = undef;
    $t->{on_retry}     = sub { is(shift, $t->{retry_count}, "on_retry") };
    $t->{retries_done} = 0;
    $t->{retry_count}  = 1;
    $t->fail($f);
    is($t->{retries_done}, $t->{retry_count}, "retries_done = retry_count");

    $t->{is_finished} = undef;
    $t->{on_fail} = sub { is(shift, $f, "on_fail") };
    $t->final_fail($f);
    is($t->{is_finished}, $f);

    is($t->{$_}, undef, $_) for @h;
};

subtest "exception", sub {
    plan tests => 2;

    my $exc = Storable::freeze(\$f);
    $t->{on_exception} = sub { is(shift, $f) };
    is($t->exception(\$exc), undef);
};

subtest "complete", sub {
    plan tests => 2;

    $t->{is_finished} = undef;
    $t->{on_complete} = sub { is(shift, $f) };
    $t->complete($f);
    is($t->{is_finished}, "complete");
};

subtest "status", sub {
    plan tests => 3;

    $t->{is_finished} = undef;
    $t->{on_status}   = sub {
        is(shift, $f,   "func");
        is(shift, $arg, "arg");
    };
    ok $t->status($f, $arg), "status";
};

subtest "data", sub {
    plan tests => 2;

    $t->{is_finished} = undef;
    $t->{on_data} = sub { is(shift, $f, "func") };
    ok $t->data($f), "data";
};

subtest "warning", sub {
    plan tests => 2;

    $t->{is_finished} = undef;
    $t->{on_warning} = sub { is(shift, $f, "func") };
    ok $t->warning($f), "warning";
};

subtest "handle", sub {
    plan tests => 2;

    ok($t->handle($f));
    is($t->{handle}, $f);
};

subtest "pack_submit_packet", sub {
    plan tests => 5;
    my $c = new_ok("Gearman::Client");
    my $v = Gearman::Util::pack_req_command($t->mode,
        join("\0", $t->func, $t->{uniq}, ${ $t->{argref} }));

    is $t->pack_submit_packet($c), $v;
    is $t->pack_submit_packet(), $v;

    my $v = Gearman::Util::pack_req_command($t->mode,
        join("\0", $t->func, '', ''));
    ${ $t->{argref} } = undef;
    $t->{uniq} = undef;
    is $t->pack_submit_packet($c), $v;
    is $t->pack_submit_packet(), $v;
};

done_testing();
