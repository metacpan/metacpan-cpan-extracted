#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Mail::TLSRPT::Pragmas;
use Test::More;
use Test::Exception;
use Mail::TLSRPT;
use Mail::TLSRPT::Failure;
use Clone qw{clone};
use Net::IP;

my $data;

my $args = {
  result_type => 'starttls-not-supported',
  sending_mta_ip => '1.2.3.4',
  receiving_mx_hostname => 'mx.example.com',
  receiving_mx_helo => 'mx1.example.com',
  receiving_ip => '5.6.7.8',
  failed_session_count => 10,
  additional_information => 'foo bar baz',
  failure_reason_code => 'one two three',
};
my $wanted_string = ' Failure:
  Result-Type: starttls-not-supported
  Sending-MTA-IP: 1.2.3.4
  Receiving-MX-Hostname: mx.example.com (5.6.7.8)
  Receiving-MX-HELO: mx1.example.com
  Failed-Session-Count: 10
  Additional-Information: foo bar baz
  Failure-Reason-Code: one two three';
my $wanted_data = {
  'sending-mta-ip' => '1.2.3.4',
  'result-type' => 'starttls-not-supported',
  'failed-session-count' => 10,
  'failure-reason-code' => 'one two three',
  'additional-information' => 'foo bar baz',
  'receiving-mx-helo' => 'mx1.example.com',
  'receiving-ip' => '5.6.7.8',
  'receiving-mx-hostname' => 'mx.example.com'
};

subtest 'create from new' => sub {

  my $tlsrpt;
  dies_ok( sub { $tlsrpt = Mail::TLSRPT::Failure->new }, 'no args dies' );
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Failure->new($args) }, 'all args lives' );

  is( $tlsrpt->result_type, $args->{result_type}, 'result_type returned' );
  is( $tlsrpt->sending_mta_ip->ip, $args->{sending_mta_ip}, 'sending_mta_ip returned' );
  is( $tlsrpt->receiving_mx_hostname, $args->{receiving_mx_hostname}, 'receiving_mx_hostname returned' );
  is( $tlsrpt->receiving_ip->ip, '5.6.7.8', 'receiving_ip returned' );
  is( $tlsrpt->receiving_mx_helo, $args->{receiving_mx_helo}, 'receiving_mx_helo returned' );
  is( $tlsrpt->failed_session_count, $args->{failed_session_count}, 'failed_session_count returned' );
  is( $tlsrpt->additional_information, $args->{additional_information}, 'additional_information returned' );
  is( $tlsrpt->failure_reason_code, $args->{failure_reason_code}, 'failure_reason_code returned' );
  is( $tlsrpt->as_string, $wanted_string, 'as_string correct' );

  $data = $tlsrpt->as_struct;
  is( ref $data, 'HASH', 'as_struct return data' );
  is_deeply( $data, $wanted_data, 'as_struct returns expected data' );

};

subtest 'create from generated data' => sub {

  my $tlsrpt;
  #  $data->{sending_mta_ip} = Net::IP->new($data->{sending_mta_ip});
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Failure->new_from_data($data) }, 'new_from_data lives' );

  is( $tlsrpt->result_type, $args->{result_type}, 'result_type returned' );
  is( $tlsrpt->sending_mta_ip->ip, $args->{sending_mta_ip}, 'sending_mta_ip returned' );
  is( $tlsrpt->receiving_mx_hostname, $args->{receiving_mx_hostname}, 'receiving_mx_hostname returned' );
  is( $tlsrpt->receiving_ip->ip, '5.6.7.8', 'receiving_ip returned' );
  is( $tlsrpt->receiving_mx_helo, $args->{receiving_mx_helo}, 'receiving_mx_helo returned' );
  is( $tlsrpt->failed_session_count, $args->{failed_session_count}, 'failed_session_count returned' );
  is( $tlsrpt->additional_information, $args->{additional_information}, 'additional_information returned' );
  is( $tlsrpt->failure_reason_code, $args->{failure_reason_code}, 'failure_reason_code returned' );
  is( $tlsrpt->as_string, $wanted_string, 'as_string correct' );

};

subtest 'Net::IP coersion' => sub {

  my $new_args = clone $args;
  my $tlsrpt;

  $new_args->{sending_mta_ip} = Net::IP->new('10.2.3.4');
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Failure->new($new_args) }, 'Passing Net::IP object lives' );
  is( $tlsrpt->sending_mta_ip->ip, '10.2.3.4', 'sending_mta_ip returned' );

  $new_args->{sending_mta_ip} = '11.2.3.4';
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Failure->new($new_args) }, 'Passing IP as string lives' );
  is( $tlsrpt->sending_mta_ip->ip, '11.2.3.4', 'sending_mta_ip returned' );

};

subtest 'result_type enumeration check' => sub {

  foreach my $allowed_type (qw{starttls-not-supported certificate-host-mismatch certificate-expired certificate-not-trusted validation-failure tlsa-invalid dnssec-invalid dane-required sts-policy-fetch-error sts-policy-invalid sts-webpki-invalid}) {
    my $tlsrpt;
    my $new_args = clone $args;
    $args->{result_type} = $allowed_type;
    lives_ok( sub { $tlsrpt = Mail::TLSRPT::Failure->new($args) }, 'result_type '.$allowed_type.' lives' );
    is( $tlsrpt->result_type, $allowed_type, 'result_type '.$allowed_type.' returned' );
  }

  foreach my $disallowed_type (qw{bad-certificate mta-sts-failed no-policy-found-foobar random}) {
    my $tlsrpt;
    my $new_args = clone $args;
    $args->{result_type} = $disallowed_type;
    dies_ok( sub { $tlsrpt = Mail::TLSRPT::Failure->new($args) }, 'result_type '.$disallowed_type.' dies' );
  }

};

done_testing;


