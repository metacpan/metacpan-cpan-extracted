use Test::More qw/ no_plan /;
use Devel::DTrace::Provider;

SKIP: {
    skip unless Devel::DTrace::Provider::DTRACE_AVAILABLE();
 
    my $provider = Devel::DTrace::Provider->new('provider0', 'test1module');
    my $probe = $provider->add_probe('test', 'func', ['string', 'integer']);
    ok(my $probes = $provider->enable, 'Generate provider DOF');
    is(scalar keys %$probes, 1);
    ok($probes->{test});
    ok($probe->fire('foo', 42));
    ok($probes->{test}->fire('foo', 13));
    $provider->disable;

    my $probe2 = $provider->add_probe('test2', 'func', ['string', 'integer']);
    ok($probes = $provider->enable, 'Generate provider DOF');
    is(scalar keys %$probes, 2);
    ok($probes->{test});
    ok($probes->{test2});
    ok($probe->fire('foo', 42));
    ok($probes->{test}->fire('foo', 13));
    ok($probe2->fire('foo', 42));
    ok($probes->{test2}->fire('foo', 13));
    $provider->disable;

    $provider->remove_probe($probe);
    ok($probes = $provider->enable, 'Generate provider DOF');
    is(scalar keys %$probes, 1);
    ok($probes->{test2});
    $provider->disable;

    eval {
        $provider->remove_probe($probe);
    };
    like($@, qr/provider0:test1module:func:test/);
}
