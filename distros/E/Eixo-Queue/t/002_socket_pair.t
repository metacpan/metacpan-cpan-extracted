use strict;
use t::test_base;

use Eixo::Queue::SocketPair;
use Eixo::Queue::Job;

eval{

	my $queue = Eixo::Queue::SocketPair->new(

		backend=>sub {

			my ($job) = @_;
	
			$job->setResult('sum', $job->args->{quantity} + 1);
			
		}
		

	);

	$queue->init;

	$SIG{PIPE} = sub {
	
		print "CAJO EN \n";

	};

	sleep(1);

	ok(kill(0, $queue->pid_c), 'Backend process has been started');

	my $job = Eixo::Queue::Job->new(

		args=>{

			quantity=>1

		}

	);


	my $ko = undef;

	for(1..1000){
	
		$job->args->{quantity} = $_;

		my $j2 = $queue->addAndWait($job);	

		$ko = 1 unless($j2->results->{sum} == $_ + 1);

		last if($ko);

	}

	ok(!$ko, 'Every job has been correctly undertaken');


};
if($@){
	print Dumper($@);
}

done_testing;

