use Test::More;
use Data::Dumper;

unless ($ENV{RELEASE_TESTING})
{
    plan(skip_all => 'Author tests not required for installation');
}

plan(tests => 12);

require_ok('Masscan::Scanner');

my $mas = Masscan::Scanner->new(hosts => ['127.0.0.1'], ports => ['22'], arguments => ['--banners']);
is(ref $mas, 'Masscan::Scanner', 'Load module');

ok($mas->add_argument('--rate 100000'), 'Add argument');

ok($mas->add_host('::1'), 'Add host');

ok($mas->add_host('10.0.0.0/24'), 'Add cidr');

ok($mas->add_host('duckduckgo.com'), 'Add domain name');

ok($mas->add_port('443'), 'Add port');

ok($mas->sudo(1), 'Enable sudo');

ok($mas->verbose(1), 'Enable verbose');

ok($mas->hosts(['127.0.0.1', '::1', 'duckduckgo.com']), 'Reset hosts');

ok($mas->scan, 'Run scan');

my $res = $mas->scan_results;
ok($res->{masscan}->{scan_stats}->{total_hosts} eq 3, 'Get scan results');
