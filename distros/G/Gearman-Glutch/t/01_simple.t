use strict;
use warnings;
use utf8;
use lib 'lib';
use Test::More;
use Gearman::Glutch;
use Test::TCP;
use Gearman::Client;
use Storable;

my $tcp = Test::TCP->new(code => sub {
    my $port = shift;
    my $glutch = Gearman::Glutch->new(port => $port, max_workers => 1);
    $glutch->register_function('add', sub {
        my $job = shift;
        my ($a, $b) = split /,/, $job->arg;
        return $a + $b;
    });
    $glutch->run;
});

my $client = Gearman::Client->new();
$client->job_servers('127.0.0.1:' . $tcp->port);
my $ret = $client->do_task('add', "2,3");
is(ref($ret), 'SCALAR');
is($$ret, "5");

undef $tcp;

done_testing;
