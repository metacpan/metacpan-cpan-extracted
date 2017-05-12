#!/usr/bin/perl
use Gearman::Client;
use JSON;
use Data::Dumper;
use Storable qw(nfreeze thaw);


my $client = Gearman::Client->new();
$client->job_servers('localhost:9955');

my %result;
my $taskset = $client->new_task_set;
for(1..100){
    my $n = $_;
    $taskset->add_task('TestWorker::slowreverse', "PING",
    {	
		on_complete => sub{
			my $resstr = ${$_[0]};
			print "$n ECHO: ";
			print ($resstr);
			print "\n";
		},
                on_fail=>sub{die "FAIL";}
	}
    ); 
}
$taskset->wait;

