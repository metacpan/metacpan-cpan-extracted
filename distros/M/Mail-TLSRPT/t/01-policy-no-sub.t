#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Mail::TLSRPT::Pragmas;
use Test::More;
use Test::Exception;
use Mail::TLSRPT;
use Mail::TLSRPT::Policy;
use Mail::TLSRPT::Report;
use DateTime;
use Clone qw{clone};

my $data;

my $args = {
  policy_type => 'no-policy-found',
  policy_string => [ 'one', 'two' ,'three' ],
  policy_domain => 'example.com',
  policy_mx_host => 'mx.example.com',
  total_successful_session_count => 10,
  total_failure_session_count => 2,
};
my $wanted_string = 'Policy:
 Type: no-policy-found
 String: one; two; three
 Domain: example.com
 MX-Host: mx.example.com
 Successful-Session-Count: 10
 Failure-Session-Count: 2';
my $wanted_data = {
  'policy' => {
    'mx-host' => 'mx.example.com',
    'policy-domain' => 'example.com',
    'policy-type' => 'no-policy-found',
    'policy-string' => [
      'one',
      'two',
      'three'
    ],
  },
  'summary' => {
    'total-failure-session-count' => 2,
    'total-successful-session-count' => 10
  },
};

subtest 'create from new' => sub {

  my $tlsrpt;
  dies_ok( sub { $tlsrpt = Mail::TLSRPT::Policy->new }, 'no args dies' );
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Policy->new($args) }, 'all args lives' );

  is( $tlsrpt->policy_type, $args->{policy_type}, 'policy_type returned' );
  is_deeply( $tlsrpt->policy_string, $args->{policy_string}, 'policy string returns correct arrayref' );
  is( $tlsrpt->policy_domain, $args->{policy_domain}, 'policy_domain returned' );
  is( $tlsrpt->policy_mx_host, $args->{policy_mx_host}, 'policy_mx_host returned' );
  is( $tlsrpt->total_successful_session_count, $args->{total_successful_session_count}, 'total_successful_session_count returned' );
  is( $tlsrpt->total_failure_session_count, $args->{total_failure_session_count}, 'total_failure_session_count returned' );
  is_deeply( $tlsrpt->failures, [], 'failures return empty arrayref' );
  is( $tlsrpt->as_string, $wanted_string, 'as_string correct' );

  $data = $tlsrpt->as_struct;
  is( ref $data, 'HASH', 'as_struct return data' );
  is_deeply( $data, $wanted_data, 'as_struct returns expected data' );

};

subtest 'create from generated data' => sub {

  my $tlsrpt;
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Policy->new_from_data($data) }, 'new_from_data lives' );

  is( $tlsrpt->policy_type, $args->{policy_type}, 'policy_type returned' );
  is_deeply( $tlsrpt->policy_string, $args->{policy_string}, 'policy string returns correct arrayref' );
  is( $tlsrpt->policy_domain, $args->{policy_domain}, 'policy_domain returned' );
  is( $tlsrpt->policy_mx_host, $args->{policy_mx_host}, 'policy_mx_host returned' );
  is( $tlsrpt->total_successful_session_count, $args->{total_successful_session_count}, 'total_successful_session_count returned' );
  is( $tlsrpt->total_failure_session_count, $args->{total_failure_session_count}, 'total_failure_session_count returned' );
  is_deeply( $tlsrpt->failures, [], 'failures return empty arrayref' );
  is( $tlsrpt->as_string, $wanted_string, 'as_string correct' );

};

subtest 'mx-host as a list' => sub {

  my $tlsrpt;
  my $new_data = clone $data;
  $new_data->{policy}->{'mx-host'} = [ 'mx1.example.com', '*.example.net' ];
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Policy->new_from_data($new_data) }, 'new_from_data lives' );
  is( $tlsrpt->policy_mx_host, 'mx1.example.com *.example.net', 'policy_mx_host returned joined' );
  is_deeply( $tlsrpt->policy_mx_hosts, [ 'mx1.example.com', '*.example.net' ], 'policy_mx_hosts returned' );
  is_deeply( $tlsrpt->as_struct->{policy}->{'mx-host'}, [ 'mx1.example.com', '*.example.net' ], 'as_struct keeps the list' );

  $new_data->{policy}->{'mx-host'} = [ 'mx1.example.com', { 'bad' => 1 } ];
  dies_ok( sub { $tlsrpt = Mail::TLSRPT::Policy->new_from_data($new_data) }, 'list with a non string dies' );

  $tlsrpt = Mail::TLSRPT::Policy->new_from_data({ $new_data->%*, policy => { $new_data->{policy}->%*, 'mx-host' => [ 'mx1.example.com' ] } });
  $tlsrpt->policy_mx_host('mx2.example.com mx3.example.com');
  is_deeply( $tlsrpt->as_struct->{policy}->{'mx-host'}, [ 'mx2.example.com', 'mx3.example.com' ], 'as_struct follows policy_mx_host when set' );

  $new_data->{policy}->{'mx-host'} = [];
  $tlsrpt = Mail::TLSRPT::Policy->new_from_data($new_data);
  is_deeply( $tlsrpt->as_struct->{policy}->{'mx-host'}, [], 'as_struct keeps an empty list' );

  $new_data->{policy}->{'mx-host'} = [ '', 'mx one.example.com' ];
  $tlsrpt = Mail::TLSRPT::Policy->new_from_data($new_data);
  is_deeply( $tlsrpt->as_struct->{policy}->{'mx-host'}, [ '', 'mx one.example.com' ], 'as_struct keeps a list exactly' );

  my $new_args = clone $args;
  delete $new_args->{policy_mx_host};
  $new_args->{policy_mx_hosts} = [ 'mx1.example.com', '*.example.net' ];
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Policy->new($new_args) }, 'new with policy_mx_hosts lives' );
  is( $tlsrpt->policy_mx_host, 'mx1.example.com *.example.net', 'policy_mx_host returned joined' );
  is_deeply( $tlsrpt->as_struct->{policy}->{'mx-host'}, [ 'mx1.example.com', '*.example.net' ], 'as_struct gives the list' );
  $new_args->{policy_mx_host} = 'mx.example.com';
  dies_ok( sub { Mail::TLSRPT::Policy->new($new_args) }, 'new with both dies' );

  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Policy->new_from_data($data) }, 'new_from_data with a string lives' );
  is_deeply( $tlsrpt->policy_mx_hosts, [ 'mx.example.com' ], 'policy_mx_hosts returned from a string' );
  is( $tlsrpt->as_struct->{policy}->{'mx-host'}, 'mx.example.com', 'as_struct keeps the string' );

};

subtest 'policy_mode' => sub {

  my $new_args = clone $args;
  $new_args->{policy_type} = 'sts';
  $new_args->{policy_string} = [ 'version: STSv1', 'mode: testing', 'mx: *.example.com', 'max_age: 86400' ];
  is( Mail::TLSRPT::Policy->new($new_args)->policy_mode, 'testing', 'mode from sts policy' );

  $new_args->{policy_string} = [ "version: STSv1\nmode:enforce\nmx: *.example.com\nmax_age: 86400" ];
  is( Mail::TLSRPT::Policy->new($new_args)->policy_mode, 'enforce', 'mode from sts policy in a single string' );

  $new_args->{policy_string} = [ 'version: STSv1', 'max_age: 86400' ];
  is( Mail::TLSRPT::Policy->new($new_args)->policy_mode, undef, 'no mode in sts policy' );

  $new_args->{policy_string} = [ undef, 'mode: testing' ];
  is( Mail::TLSRPT::Policy->new($new_args)->policy_mode, 'testing', 'a null line is skipped' );
  like( Mail::TLSRPT::Policy->new($new_args)->as_string, qr/String: ; mode: testing/, 'and shown empty in as_string' );
  my $report = Mail::TLSRPT::Report->new(
    organization_name => 'Company-X',
    start_datetime => DateTime->from_epoch( epoch => 0 ),
    end_datetime => DateTime->from_epoch( epoch => 0 ),
    report_id => 'report',
    policies => [ Mail::TLSRPT::Policy->new($new_args) ],
  );
  like( $report->as_csv({}), qr/,"; mode: testing",/, 'and in as_csv' );

  $new_args->{policy_type} = 'STS';
  is( Mail::TLSRPT::Policy->new($new_args)->policy_mode, undef, 'policy type is case-sensitive, as in is_known_policy_type' );

  $new_args->{policy_type} = 'tlsa';
  $new_args->{policy_string} = [ 'mode: testing' ];
  is( Mail::TLSRPT::Policy->new($new_args)->policy_mode, undef, 'no mode for tlsa policy' );

};

subtest 'policy_type enumeration check' => sub {

  foreach my $allowed_type (qw{tlsa sts no-policy-found}) {
    my $tlsrpt;
    my $new_args = clone $args;
    $args->{policy_type} = $allowed_type;
    lives_ok( sub { $tlsrpt = Mail::TLSRPT::Policy->new($args) }, 'policy_type '.$allowed_type.' lives' );
    is( $tlsrpt->policy_type, $allowed_type, 'policy_type '.$allowed_type.' returned' );
    ok( $tlsrpt->is_known_policy_type, 'policy_type '.$allowed_type.' is known' );
  }

  foreach my $unknown_type (qw{tlsb mta-sts no-policy-found-foobar random}) {
    my $tlsrpt;
    my $new_args = clone $args;
    $args->{policy_type} = $unknown_type;
    lives_ok( sub { $tlsrpt = Mail::TLSRPT::Policy->new($args) }, 'policy_type '.$unknown_type.' lives' );
    is( $tlsrpt->policy_type, $unknown_type, 'policy_type '.$unknown_type.' returned' );
    ok( ! $tlsrpt->is_known_policy_type, 'policy_type '.$unknown_type.' is not known' );
  }

  is_deeply( [ Mail::TLSRPT::Policy->known_policy_types ], [ qw{ tlsa sts no-policy-found } ], 'known_policy_types returns the RFC 8460 list' );

};

done_testing;

