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

eval {
  require Prometheus::Tiny::Shared;
  Prometheus::Tiny::Shared->VERSION(0.011) || die;;
};
plan( skip_all => "Prometheus::Tiny::Shared 0.011 not found" ) if $@;

my $json = '
  {
     "organization-name": "Company-X",
     "date-range": {
       "start-datetime": "2016-04-01T00:00:00Z",
       "end-datetime": "2016-04-01T23:59:59Z"
     },
     "contact-info": "sts-reporting@company-x.example",
     "report-id": "5065427c-23d3-47ca-b6e0-946ea0e8c4be",
     "policies": [{
       "policy": {
         "policy-type": "sts",
         "policy-string": ["version: STSv1","mode: testing",
               "mx: *.mail.company-y.example","max_age: 86400"],
         "policy-domain": "company-y.example",
         "mx-host": "*.mail.company-y.example"
       },
       "summary": {
         "total-successful-session-count": 5326,
         "total-failure-session-count": 303
       },
       "failure-details": [{
         "result-type": "certificate-expired",
         "sending-mta-ip": "2001:db8:abcd:0012::1",
         "receiving-mx-hostname": "mx1.mail.company-y.example",
         "failed-session-count": 100
       }, {
         "result-type": "starttls-not-supported",
         "sending-mta-ip": "2001:db8:abcd:0013::1",
         "receiving-mx-hostname": "mx2.mail.company-y.example",
         "receiving-ip": "203.0.113.56",
         "failed-session-count": 200,
         "additional-information": "https://reports.company-x.example/report_info?id=5065427c-23d3#StarttlsNotSupported"
       }, {
         "result-type": "validation-failure",
         "sending-mta-ip": "198.51.100.62",
         "receiving-ip": "203.0.113.58",
         "receiving-mx-hostname": "mx-backup.mail.company-y.example",
         "failed-session-count": 3,
         "failure-reason-code": "X509_V_ERR_PROXY_PATH_LENGTH_EXCEEDED"
       }]
     }]
   }
';
my $expected_metrics = '# HELP tlsrpt_failures_total TLSRPT failures
# TYPE tlsrpt_failures_total counter
tlsrpt_failures_total{organization_name="Company-X",policy_domain="company-y.example",policy_mx_host="*.mail.company-y.example",policy_type="sts",receiving_ip="",receiving_mx_helo="",receiving_mx_hostname="mx1.mail.company-y.example",result_type="certificate-expired",sending_mta_ip="3"} 100
tlsrpt_failures_total{organization_name="Company-X",policy_domain="company-y.example",policy_mx_host="*.mail.company-y.example",policy_type="sts",receiving_ip="203.0.113.56",receiving_mx_helo="",receiving_mx_hostname="mx2.mail.company-y.example",result_type="starttls-not-supported",sending_mta_ip="3"} 200
tlsrpt_failures_total{organization_name="Company-X",policy_domain="company-y.example",policy_mx_host="*.mail.company-y.example",policy_type="sts",receiving_ip="203.0.113.58",receiving_mx_helo="",receiving_mx_hostname="mx-backup.mail.company-y.example",result_type="validation-failure",sending_mta_ip="3"} 3
# HELP tlsrpt_reports_processed_total TLSRPT reports processed
# TYPE tlsrpt_reports_processed_total counter
tlsrpt_reports_processed_total{organization_name="Company-X",policies="1"} 1
# HELP tlsrpt_sessions_total TLSRPT tls sessions
# TYPE tlsrpt_sessions_total counter
tlsrpt_sessions_total{organization_name="Company-X",policy_domain="company-y.example",policy_mx_host="*.mail.company-y.example",policy_type="sts",result="failure"} 303
tlsrpt_sessions_total{organization_name="Company-X",policy_domain="company-y.example",policy_mx_host="*.mail.company-y.example",policy_type="sts",result="successful"} 5326
';

subtest 'create from example json' => sub {
  my $tlsrpt;
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new_from_json( $json ) }, 'new_from_json lives' );
  my $prometheus = Prometheus::Tiny::Shared->new;
  $tlsrpt->process_prometheus($prometheus);
  is($prometheus->format, $expected_metrics, 'metrics output is as expected' );
};

done_testing;


