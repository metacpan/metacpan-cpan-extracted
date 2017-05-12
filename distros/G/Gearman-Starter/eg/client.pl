use strict;
use warnings;
use 5.10.1;
use Gearman::Client;
use Storable qw/nfreeze/;

my $cmd = shift || 'sum';

my $client = Gearman::Client->new();
$client->job_servers('127.0.0.1');
say ${ $client->do_task($cmd => nfreeze([1,2])) };

