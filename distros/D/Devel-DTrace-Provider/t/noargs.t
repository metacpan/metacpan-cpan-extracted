use Test::More qw/ no_plan /;
use Devel::DTrace::Provider;

my $provider = Devel::DTrace::Provider->new('provider0', 'test1module');
my $probe = $provider->add_probe('test', 'func', []);
ok(my $probes = $provider->enable, 'Generate provider DOF');
