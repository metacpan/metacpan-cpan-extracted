use Test::Most;

BEGIN {
    unless ($ENV{LIVE_TEST_JENKINS_URL})
    {
        # NOTE: the test server needs to have a project named Test-Project on it to pass.
        plan skip_all => "Set LIVE_TEST_JENKINS_URL if you want to run these tests against a live jenkins server.\
 Set LIVE_TEST_JENKINS_API_KEY and LIVE_TEST_JENKINS_API_PASS if your server requires authentication.";
    }
}
bail_on_fail;
use Jenkins::API;
my $url = $ENV{LIVE_TEST_JENKINS_URL};
my $apiKey = $ENV{LIVE_TEST_JENKINS_API_KEY};
my $apiPass = $ENV{LIVE_TEST_JENKINS_API_PASS};

my $api = Jenkins::API->new(base_url => $url,
							api_key => $apiKey,
							api_pass => $apiPass);

my $v = $api->check_jenkins_url;
ok $v, 'Jenkins running on ' . $url;
explain $v;

my $status = $api->current_status;
ok ((grep { $_ eq 'Test-Project' } map { $_->{name} } @{$status->{jobs}}),
    'Ensure we found the Test-Project');
note 'This is the current status returned by the API';
explain($status);

note 'This is a more refined query of the API';
$status = $api->current_status({ extra_params => { tree => 'jobs[name,color]' }});
explain $status;
ok grep { $_ eq 'Test-Project' } map { $_->{name} } @{$status->{jobs}};

$status = $api->current_status({ path_parts => [qw/job Test-Project/], extra_params => { depth => 1 }});
note 'Querying job Test-Project with depth => 1';
explain $status;

my $build_status = $api->build_queue;
note 'Build queue';
explain $build_status;
$build_status = $api->build_queue({ extra_params => { depth => 1 }});;
note 'With depth => 1';
explain $build_status;

my $statistics = $api->load_statistics;
is $api->response_code, '200';
ok $api->response_content;
explain $api->project_config('Test-Project');

my $job_info = $api->get_job_details('Test-Project');
note 'get_job_details';
explain $job_info;

my $job_info2 = $api->get_job_details('Test-Project', { extra_params => { tree => 'healthReport' } });
explain $job_info2;

note 'Load statistics';
explain $statistics;


my $view = $api->view_status('Test');
explain $view;
my $view_list = $api->current_status({ extra_params => { tree => 'views[name]' }});
explain $view_list;
my @views = grep { $_ ne 'All' } map { $_->{name} } @{$view_list->{views}};
for my $view (@views)
{
    my $view_jobs = $api->view_status($view, { extra_params => { tree => 'jobs[name,color]' }});
    explain $view_jobs;
}

my $response = $api->general_call(
    ['job', 'Test', 'api', 'json'], 
    {
        method => 'GET',
        extra_params => { tree => 'color,description' },
        decode_json => 1,
        expected_response_code => 200,
    });
note 'General call';
explain $response;

done_testing;
