use Devel::DTrace::Provider;

my $providers = 100000;
my $firings = 100000;

for (1..$providers) {
    my $provider = Devel::DTrace::Provider->new('provider0', 'test1module');
    my $probe = $provider->add_probe('test', 'func', ['string', 'integer']);
    my $probes = $provider->enable;
    for (1..$firings) {
        $probe->fire('foo', 42);
    }
    $provider->disable;
}
