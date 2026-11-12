#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Mail::TLSRPT::Pragmas;
use Test::More;
use Test::Exception;
use Mail::TLSRPT;
use Mail::TLSRPT::Report;
use Prometheus::Tiny;

my $json = '{
  "organization-name": "Company-X",
  "date-range": {
    "start-datetime": "2016-04-01T00:00:00Z",
    "end-datetime": "2016-04-01T23:59:59Z"
  },
  "report-id": "5065427c-23d3-47ca-b6e0-946ea0e8c4be",
  "policies": [{
    "policy": {
      "policy-type": "sts",
      "policy-string": ["version: STSv1","mode: enforce","mx: *.mail.company-y.example","max_age: 86400"],
      "policy-domain": "company-y.example",
      "mx-host": "*.mail.company-y.example"
    },
    "summary": {
      "total-successful-session-count": 0,
      "total-failure-session-count": 12
    },
    "failure-details": [{
      "result-type": "sts-policy-fetch-error",
      "failed-session-count": 12
    }]
  }]
}';

my $wanted_string = 'Report-ID: <5065427c-23d3-47ca-b6e0-946ea0e8c4be>
From: "Company-X"
Dates: 2016-04-01T00:00:00Z to 2016-04-01T23:59:59Z
Policy:
 Type: sts
 String: version: STSv1; mode: enforce; mx: *.mail.company-y.example; max_age: 86400
 Domain: company-y.example
 MX-Host: *.mail.company-y.example
 Successful-Session-Count: 0
 Failure-Session-Count: 12
 Failure:
  Result-Type: sts-policy-fetch-error
  Failed-Session-Count: 12';

subtest 'policy fetch failure without contact-info' => sub {
  my $tlsrpt;
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new_from_json($json) }, 'new_from_json lives' );
  is( $tlsrpt->contact_info, undef, 'contact_info is undef' );
  my $failure = $tlsrpt->policies->[0]->failures->[0];
  is( $failure->sending_mta_ip, undef, 'sending_mta_ip is undef' );
  is( $failure->receiving_mx_hostname, undef, 'receiving_mx_hostname is undef' );
  is( $tlsrpt->as_string, $wanted_string, 'as_string correct' );
  my $struct = $tlsrpt->as_struct;
  ok( ! exists $struct->{'contact-info'}, 'as_struct has no contact-info' );
  is_deeply( $failure->as_struct, { 'result-type' => 'sts-policy-fetch-error', 'failed-session-count' => 12 }, 'failure as_struct has only what was given' );
  lives_ok( sub { $tlsrpt->as_csv({ add_header => 1 }) }, 'as_csv lives' );
  my $prometheus = Prometheus::Tiny->new;
  lives_ok( sub { $tlsrpt->process_prometheus($prometheus) }, 'process_prometheus lives' );
  like( $prometheus->format, qr/^tlsrpt_failures_total\{organization_name="Company-X",policy_domain="company-y.example",policy_mx_host="\*.mail.company-y.example",policy_type="sts",receiving_ip="",receiving_mx_helo="",receiving_mx_hostname="",result_type="sts-policy-fetch-error",sending_mta_ip=""\} 12$/m, 'prometheus labels are empty' );
};

subtest 'failure with a receiving IP but no MX' => sub {
  my $failure = Mail::TLSRPT::Failure->new_from_data({ 'result-type' => 'starttls-not-supported', 'receiving-ip' => '192.0.2.1', 'failed-session-count' => 1 });
  is( $failure->as_string, " Failure:\n  Result-Type: starttls-not-supported\n  Receiving-IP: 192.0.2.1\n  Failed-Session-Count: 1", 'as_string names the IP' );
  is_deeply( $failure->as_struct, { 'result-type' => 'starttls-not-supported', 'receiving-ip' => '192.0.2.1', 'failed-session-count' => 1 }, 'as_struct has only what was given' );
};

done_testing;
