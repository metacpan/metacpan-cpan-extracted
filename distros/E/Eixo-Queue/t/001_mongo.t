use strict;
use t::test_base;

use Eixo::Queue::MongoDriver;
use Eixo::Queue::Job;
use utf8;

my $BD = 'bd_test_' . int(rand(10000));
my $D;

SKIP: {
    eval {
        
        $D = Eixo::Queue::MongoDriver->new(

            host => $ENV{MONGO_HOST},
    
            db=>$BD,
    
            collection=>"jobs"
    
        )->getPendingJob();
    };

    skip "NO MONGODB CONNECTION", 2 if($@ =~ /connect/i);


    eval{
    
        $D = Eixo::Queue::MongoDriver->new(

            host => $ENV{MONGO_HOST} || 'localhost',
    
            db=>$BD,
    
            collection=>"jobs"
    
        );

    
        my $queue = TestQueue->new(
    
            db=>$BD,

            host => $ENV{MONGO_HOST} || 'localhost',
    
            collection=>"jobs"
    
        );
    
        $queue->init;
    
        my $j;

        my $utf8_string = '¡utf8 is not so hard 😌 !';
    
        $queue->add(
    
            $j = Eixo::Queue::Job->new(
    
                id=>Eixo::Queue::Job::ID,

                args => { hola => $utf8_string}
    
            )
    
        );
    
        my $j2;
    
        ok($j2 = $D->getPendingJob(), 'Job has been enqueued');
    
        ok($j2 && $j2->id eq $j->id, 'Pending job seems correct');
    
        $D->updateJob(
    
            $j2->finished
    
        );
    
        ok(!$D->getPendingJob(), 'There are no more pending jobs');
    
        ok($D->getJob($j2->id), 'The job is still collectable');

        binmode(STDOUT, ":utf8");
        print $j->args->{hola}."\n";
    
    };
    if($@){
        print Dumper($@);
    }
    
    if($D){
    
        $D->getDb->drop;
    }
};

done_testing;

package TestQueue;

use strict;
use parent qw(Eixo::Queue::Mongo);

