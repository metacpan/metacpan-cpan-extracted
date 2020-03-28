use Test::More;
use Masscan::Scanner;
use Data::Dumper;

unless ($ENV{RELEASE_TESTING})
{
    plan(skip_all => 'Author tests not required for installation');
}

plan(tests => 12);

require_ok('Masscan::Scanner');

my $mas = Masscan::Scanner->new(hosts => ['minion001.averna.id.au', '127.0.0.1', '::1'], ports => ['80', '443'], arguments => ['--banners'], verbose => 1);
is(ref $mas, 'Masscan::Scanner', 'Load module');

ok($mas->add_argument('--rate 100000'), 'Add argument');

ok($mas->add_host('averna.id.au'), 'Add host');

ok($mas->add_host('10.0.0.0/24'), 'Add cidr');

ok($mas->add_host('duckduckgo.com'), 'Add domain name');

ok($mas->add_port('443'), 'Add port');

ok($mas->sudo(1), 'Enable sudo');

ok($mas->verbose(1), 'Enable verbose');

ok($mas->hosts(['amazon.com', 'duckduckgo.com', 'google.com']), 'Reset hosts');

ok($mas->scan, 'Run scan');

my $res = $mas->scan_results;
ok($res->{masscan}->{scan_stats}->{total_hosts} eq 3, 'Get scan results');
