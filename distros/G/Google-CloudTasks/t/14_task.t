use strict;
use warnings;
use utf8;

use lib qw/lib/;
use Test::More;
use Test::Exception;
use Test::Deep;
use Time::HiRes;
use MIME::Base64;
use Google::CloudTasks;

BEGIN {
    unless (defined $ENV{GOOGLE_APPLICATION_CREDENTIALS} && defined $ENV{PROJECT_ID} && defined $ENV{LOCATION_ID}) {
        Test::More::plan(skip_all => 'This test needs GOOGLE_APPLICATION_CREDENTIALS and PROJECT_ID and LOCATION_ID')
    }
}

my $client = Google::CloudTasks->client(
    credentials_path => $ENV{GOOGLE_APPLICATION_CREDENTIALS},
    is_debug => 0,
);
my $queue_id = sprintf('ct-queue-test-%f-%d', Time::HiRes::time(), int(rand(10000)));
$queue_id =~ s/\./-/g;
my $parent_of_queue = "projects/$ENV{PROJECT_ID}/locations/$ENV{LOCATION_ID}";
my $parent = "$parent_of_queue/queues/$queue_id";
my $queue = {
    name => $parent,
};
$client->create_queue($parent_of_queue, $queue);
$client->pause_queue($parent);

my $task_id_1 = sprintf('ct-task-test-1-%f-%d', Time::HiRes::time(), int(rand(10000)));
my $task_id_2 = sprintf('ct-task-test-2-%f-%d', Time::HiRes::time(), int(rand(10000)));
$task_id_1 =~ s/\./-/g;
$task_id_2 =~ s/\./-/g;
my $task_name_1 = "$parent/tasks/$task_id_1";
my $task_name_2 = "$parent/tasks/$task_id_2";

subtest 'create' => sub {
    my $body = encode_base64('{"name": "TaskTest"}');
    chomp($body);

    my @rets = ();
    lives_ok {
        for my $task_name ($task_name_1, $task_name_2) {
            my $task = +{
                name => $task_name,
                appEngineHttpRequest => {
                    relativeUri => '/path',
                    headers => {
                        'Content-Type' => 'application/json',
                    },
                    body => $body,
                },
            };
            push @rets, $client->create_task($parent, $task, {});
        }
    };
    is $rets[0]->{name}, $task_name_1;
    is $rets[1]->{name}, $task_name_2;
};

subtest 'get' => sub {
    my $ret;
    lives_ok {
        $ret = $client->get_task($task_name_1);
    };
    is $ret->{name}, $task_name_1;
};

subtest 'list' => sub {
    my $ret;
    lives_ok {
        $ret = $client->list_tasks($parent);
    };
    cmp_deeply $ret->{tasks}, supersetof(
        superhashof( +{ name => $task_name_1 }),
        superhashof( +{ name => $task_name_2 })
    );
};

subtest 'run' => sub {
    sleep 3;   # should wait a few seconds to use this API
    my $before = $client->get_task($task_name_1);
    my $ret;
    lives_ok {
        my $retry_count = 10;
        while (1) {
            eval {
                $ret = $client->run_task($task_name_1);
            };
            if ($@) {
                $retry_count--;
                if ($retry_count <= 0) {
                    die $@;
                }
                sleep 3;
            }
            else {
                last;
            }
        }
    };
    is $ret->{dispatchCount}, ($before->{dispatchCount} // 0) + 1;
};

subtest 'delete' => sub {
    my $ret;
    lives_ok {
        $ret = $client->delete_task($task_name_2);
    };
    is_deeply $ret, +{};
};

$client->delete_queue($parent);

done_testing;
