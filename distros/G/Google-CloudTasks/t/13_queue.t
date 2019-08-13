use strict;
use warnings;
use utf8;

use lib qw/lib/;
use Test::More;
use Test::Exception;
use Test::Deep;
use Time::HiRes;
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
my $parent = "projects/$ENV{PROJECT_ID}/locations/$ENV{LOCATION_ID}";

my $queue_id = sprintf('ct-queue-test-%f-%d', Time::HiRes::time(), int(rand(10000)));
$queue_id =~ s/\./-/g;
my $queue_name = "$parent/queues/$queue_id";

subtest 'create' => sub {
    my $queue = {
        name => $queue_name,
    };

    my $ret;
    lives_ok {
        $ret = $client->create_queue($parent, $queue);
    };

    is $ret->{name}, $queue_name;
};

subtest 'get' => sub {
    my $ret;
    lives_ok {
        $ret = $client->get_queue($queue_name);
    };
    is $ret->{name}, $queue_name;
};

subtest 'list' => sub {
    my $ret;
    lives_ok {
        $ret = $client->list_queues($parent);
    };
    cmp_deeply $ret->{queues}, supersetof(
        superhashof(
            +{
                name => $queue_name,
            }
        )
    );
};

subtest 'patch' => sub {
    my $queue = $client->get_queue($queue_name);
    my $current = $queue->{retryConfig}{maxAttempts};
    $queue->{retryConfig}{maxAttempts} *= 2;
    my $ret;
    lives_ok {
        $ret = $client->patch_queue($queue_name, $queue, { updateMask => 'retryConfig.maxAttempts' });
    };
    is $ret->{retryConfig}{maxAttempts}, $current * 2;
};

subtest 'pause' => sub {
    my $ret;
    lives_ok {
        $ret = $client->pause_queue($queue_name);
    };
    is $ret->{state}, 'PAUSED';
};

subtest 'resume' => sub {
    my $ret;
    lives_ok {
        $ret = $client->resume_queue($queue_name);
    };
    is $ret->{state}, 'RUNNING';
};

subtest 'purge' => sub {
    my $ret;
    lives_ok {
        $ret = $client->purge_queue($queue_name);
    };
    ok exists $ret->{purgeTime};
};

subtest 'iam_policy' => sub {
    my $etag;

    subtest 'get_iam_policy' => sub {
        my $ret;
        lives_ok {
            $ret = $client->get_iam_policy_queue($queue_name);
        };
        $etag = $ret->{etag};
        ok $etag;
    };

    SKIP: {
        my $service_account = $ENV{CT_TEST_SERVICE_ACCOUNT}
            or skip "This test requires CT_TEST_SERVICE_ACCOUNT environment variable", 1;
        subtest 'set_iam_policy' => sub {
            my $policy = {
                bindings => [
                    +{
                        role => 'roles/viewer',
                        members => [
                            "serviceAccount:$service_account",
                        ],
                    }
                ],
                etag => $etag,
            };
            my $ret;
            lives_ok {
                $ret = $client->set_iam_policy_queue($queue_name, $policy);
            };
            $etag = $ret->{etag};
            ok $etag;
            is_deeply $ret->{bindings}, $policy->{bindings} or diag explain $ret;
        };
    }
};

subtest 'delete' => sub {
    my $ret;
    lives_ok {
        $ret = $client->delete_queue($queue_name);
    };
    is_deeply $ret, +{};
};

done_testing;
