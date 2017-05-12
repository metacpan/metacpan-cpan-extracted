use Devel::DTrace::Provider;

my @probes;

for my $i (1..2000) {
    my $provider = Devel::DTrace::Provider->new('provider0', 'test1module');
    for my $j (1..25) {
        push @probes, "probe$i-$j";
    }
    for my $probe (@probes) {
        $provider->add_probe($probe, 'func', []);
    }
    printf STDERR "enabling %d probe provider...", scalar @probes;
    $provider->enable;
    print STDERR "done\n";
    $provider->disable;
    print STDERR "disabled\n"
}

