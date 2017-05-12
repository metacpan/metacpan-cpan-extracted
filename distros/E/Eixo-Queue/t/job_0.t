use strict;
use Test::More;
use_ok("Eixo::Queue::Job");
use_ok("Eixo::Queue::MongoDriver");

my $BD = 'bd_test_' . int(rand(10000));
my $D;


SKIP: {

	eval {         

		$D = Eixo::Queue::MongoDriver->new(
	
	                db=>$BD,
	
	                collection=>"jobs"
	
	        )->getPendingJob();
	};

	skip "NO MONGODB CONNECTION", 2 if($@ =~ /connect/i);

	my $job = Eixo::Queue::Job->new;
	
	ok($job->status eq $job->WAITING, "Job is waiting");
	
	$job = Eixo::Queue::Job->unserialize($job->serialize);
	
	$job->finished;
	
	ok($job->status eq $job->FINISHED, "Job is finished");

	eval{

		$D = Eixo::Queue::MongoDriver->new(
	
			db=>$BD,
	
			collection=>"jobs"
	
		);

		$job = Eixo::Queue::Job->new;

		$D->addJob($job);		

		my $job2 = $D->getJob($job->id);

		ok($job2 && ref($job2), "Job can be retrieved");

		ok($job2->status eq $job2->WAITING, "Job status is ok");

        $job2->setResult('result_1', 'a');
        $job2->setResult('result_temp', 'xxxx');
		$D->updateJob($job2);

        $job2->removeResult('result_temp');
		$job2->finished;
		$D->updateJob($job2);

		$job2 = $D->getJob($job->id);

		ok($job2->status eq $job2->FINISHED, "Job status is finished");
		ok($job2->results->{result_1} eq 'a', "Job result was set correctly");
		ok(!defined($job2->results->{result_temp}), "Temporaly result not exists at the end");
		
	};

	if($@){

		use Data::Dumper;
	
		print Dumper($@);
	}
};

	

	if($D){
	
		$D->getDb->drop;
	}

done_testing();
