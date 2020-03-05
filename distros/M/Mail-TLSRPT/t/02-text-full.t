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
my $expected_string = 'Report-ID: <5065427c-23d3-47ca-b6e0-946ea0e8c4be>
From: "Company-X" <sts-reporting@company-x.example>
Dates: 2016-04-01T00:00:00Z to 2016-04-01T23:59:59Z
Policy:
 Type: sts
 String: version: STSv1; mode: testing; mx: *.mail.company-y.example; max_age: 86400
 Domain: company-y.example
 MX-Host: *.mail.company-y.example
 Successful-Session-Count: 5326
 Failure-Session-Count: 303
 Failure:
  Result-Type: certificate-expired
  Sending-MTA-IP: 2001:0db8:abcd:0012:0000:0000:0000:0001
  Receiving-MX-Hostname: mx1.mail.company-y.example
  Failed-Session-Count: 100
 Failure:
  Result-Type: starttls-not-supported
  Sending-MTA-IP: 2001:0db8:abcd:0013:0000:0000:0000:0001
  Receiving-MX-Hostname: mx2.mail.company-y.example (203.0.113.56)
  Failed-Session-Count: 200
  Additional-Information: https://reports.company-x.example/report_info?id=5065427c-23d3#StarttlsNotSupported
 Failure:
  Result-Type: validation-failure
  Sending-MTA-IP: 198.51.100.62
  Receiving-MX-Hostname: mx-backup.mail.company-y.example (203.0.113.58)
  Failed-Session-Count: 3
  Failure-Reason-Code: X509_V_ERR_PROXY_PATH_LENGTH_EXCEEDED';

subtest 'create from example json' => sub {
  my $tlsrpt;
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new_from_json( $json ) }, 'new_from_json lives' );
  is( $tlsrpt->as_string, $expected_string, 'as_string output is as expected' );
};

done_testing;

