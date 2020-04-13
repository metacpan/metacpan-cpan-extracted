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
use DateTime;
use JSON;

my $data;
my $json;

my $end_time = 1583282529;
my $start_time = $end_time - 86399;
my $args = {
  organization_name => 'my test org',
  start_datetime => DateTime->from_epoch( epoch=>$start_time ),
  end_datetime => $end_time,
  contact_info => 'test@example.com',
  report_id => 'test report 1',
};
my $wanted_string = 'Report-ID: <test report 1>
From: "my test org" <test@example.com>
Dates: 2020-03-03T00:42:10Z to 2020-03-04T00:42:09Z';
my $wanted_data = {
  'organization-name' => 'my test org',
  'contact-info' => 'test@example.com',
  'date-range' => {
  'end-datetime' => '2020-03-04T00:42:09Z',
  'start-datetime' => '2020-03-03T00:42:10Z'
  },
  'report-id' => 'test report 1'
};
my $wanted_json = '{"contact-info":"test@example.com","date-range":{"end-datetime":"2020-03-04T00:42:09Z","start-datetime":"2020-03-03T00:42:10Z"},"organization-name":"my test org","report-id":"test report 1"}';

my $j = JSON->new;

subtest 'create from new' => sub {

  my $tlsrpt;
  dies_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new }, 'no args dies' );
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new($args) }, 'all args lives' );

  is( $tlsrpt->organization_name, $args->{organization_name}, 'organization_name returned' );
  is( ref $tlsrpt->start_datetime, 'DateTime', 'Start DateTime object returned' );
  is( ref $tlsrpt->end_datetime, 'DateTime', 'End DateTime object returned' );
  is( $tlsrpt->contact_info, $args->{contact_info}, 'contact_info returned' );
  is( $tlsrpt->report_id, $args->{report_id}, 'report_id returned' );
  is_deeply( $tlsrpt->policies, [], 'policies return empty arrayref' );
  is( $tlsrpt->as_string, $wanted_string, 'as_string correct' );

  $data = $tlsrpt->as_struct;
  is( ref $data, 'HASH', 'as_struct return data' );
  is_deeply( $data, $wanted_data, 'as_struct returns expected data' );
  $json = $tlsrpt->as_json;
  lives_ok( sub{ $j->decode( $json ) }, 'as_json returns valid json' );
  is( $json, $wanted_json, 'as_json returns expected json' );
};

subtest 'create from generated data' => sub {
  my $tlsrpt;
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new_from_data( $data ) }, 'new_from_data lives' );

  is( $tlsrpt->organization_name, $args->{organization_name}, 'organization_name returned' );
  is( ref $tlsrpt->start_datetime, 'DateTime', 'Start DateTime object returned' );
  is( ref $tlsrpt->end_datetime, 'DateTime', 'End DateTime object returned' );
  is( $tlsrpt->contact_info, $args->{contact_info}, 'contact_info returned' );
  is( $tlsrpt->report_id, $args->{report_id}, 'report_id returned' );
  is_deeply( $tlsrpt->policies, [], 'policies return empty arrayref' );
  is( $tlsrpt->as_string, $wanted_string, 'as_string correct' );
};

subtest 'create from generated json' => sub {
  my $tlsrpt;
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new_from_json( $json ) }, 'new_from_json lives' );

  is( $tlsrpt->organization_name, $args->{organization_name}, 'organization_name returned' );
  is( ref $tlsrpt->start_datetime, 'DateTime', 'Start DateTime object returned' );
  is( ref $tlsrpt->end_datetime, 'DateTime', 'End DateTime object returned' );
  is( $tlsrpt->contact_info, $args->{contact_info}, 'contact_info returned' );
  is( $tlsrpt->report_id, $args->{report_id}, 'report_id returned' );
  is_deeply( $tlsrpt->policies, [], 'policies return empty arrayref' );
  is( $tlsrpt->as_string, $wanted_string, 'as_string correct' );
};

#my $tlsrpt = Mail::TLSRPT::Report->new;
#is ( ref $tlsrpt, 'Mail::TLSRPT::Report', 'Report object created' );

done_testing;
