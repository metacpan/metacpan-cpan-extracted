#!/usr/bin/env perl

# Set LIVE_TEST_JENKINS_URL if you want to run these tests against a live jenkins server.
# Set LIVE_TEST_JENKINS_API_KEY and LIVE_TEST_JENKINS_API_PASS if your server requires authentication.

use strict;
use warnings;

use Test2::V0 -target => 'Jenkins::API';
use HTTP::Status qw(HTTP_CREATED HTTP_UNAUTHORIZED);

my $expected_base_url = 'http://jenkins:8080';

my $jenkins = $CLASS->new(base_url => $expected_base_url);

my $mocked_response_code;
my $mocked_client = Test2::Mock->new(
  class => 'REST::Client',
  override => [
    POST => sub {
      cmp_ok $_[0]->getHost, 'eq', $expected_base_url, 'host configured';
      cmp_ok $_[1], 'eq', '/job/Test-Project/buildWithParameters?Parameter=Value', 'query path';
      return;
    },
    responseCode => sub {
      return $mocked_response_code 
    },
    responseHeader => sub {
      my $location = URI->new($_[0]->getHost);
      $location->path_segments(qw(queue item 123456), '');
      return $location->as_string;
    }
  ]
);

$mocked_response_code = HTTP_UNAUTHORIZED;
ok
  not($jenkins->trigger_build_with_parameters('Test-Project', { Parameter => 'Value' })),
  'fail to trigger build with parameters';

$mocked_response_code = HTTP_CREATED;
ok
  $jenkins->trigger_build_with_parameters('Test-Project', { Parameter => 'Value' }),
  'build with parameters successfully triggered';
cmp_ok
  $jenkins->response_header('Location'),
  'eq',
  "$expected_base_url/queue/item/123456/",
  'validate location value';

done_testing;

