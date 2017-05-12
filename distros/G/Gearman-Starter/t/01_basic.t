use strict;
use warnings;
use Test::More;
use Test::TCP;

use File::Spec;
use File::Which qw/which/;
use Gearman::Client;
use Gearman::Starter;
use Storable qw/nfreeze/;

plan skip_all => "No gearmand command" unless which('gearmand');

my $gearmand = Test::TCP->new(
    code => sub {
        my $port = shift;
        exec 'gearmand', '-p', $port, '-l', File::Spec->devnull;
        die "cannot execute gearmand: $!";
    },
);

my $server_str = '127.0.0.1:'.$gearmand->port;
my $gearman_starter = Gearman::Starter->new(
    server                 => $server_str,
    max_workers            => 3,
    max_requests_per_child => 10,
    module                 => 't::lib::Job',
);
isa_ok $gearman_starter, 'Gearman::Starter';
is_deeply [$gearman_starter->servers], [$server_str];

my $jobs = $gearman_starter->_load_jobs;
is_deeply [sort keys %$jobs], [qw/lazy_sum sum/];
isa_ok $jobs->{lazy_sum}, 'CODE';
isa_ok $jobs->{sum}     , 'CODE';

if ( !( my $pid = fork()) ) {
    # child
    if (defined $pid && $pid == 0) {
        $gearman_starter->run;
        exit;
    }
    else {
        die "fork failed: $!";
    }
}
else {
    # parent
    my $client = Gearman::Client->new;
    $client->job_servers($server_str);
    my $ret = $client->do_task(sum => nfreeze([1,2]));
    is $$ret, 3;
    my $TERMSIG = $^O eq 'MSWin32' ? 'KILL' : 'TERM';
    kill $TERMSIG, $pid;
    wait;
}

done_testing;
