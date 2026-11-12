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
use Clone qw{clone};

my $data = {
  'organization-name' => 'Company-X',
  'date-range' => {
    'start-datetime' => '2016-04-01T00:00:00Z',
    'end-datetime' => '2016-04-01T23:59:59Z',
  },
  'contact-info' => 'sts-reporting@company-x.example',
  'report-id' => '5065427c-23d3-47ca-b6e0-946ea0e8c4be',
  'policies' => [{
    'policy' => {
      'policy-type' => 'sts',
      'policy-string' => [ 'version: STSv1', 'mode: testing' ],
      'policy-domain' => 'company-y.example',
      'mx-host' => '*.mail.company-y.example',
    },
    'summary' => {
      'total-successful-session-count' => 5326,
      'total-failure-session-count' => 303,
    },
    'failure-details' => [{
      'result-type' => 'certificate-expired',
      'sending-mta-ip' => '198.51.100.62',
      'receiving-mx-hostname' => 'mx1.mail.company-y.example',
      'failed-session-count' => 100,
    }, {
      'result-type' => 'starttls-not-supported',
      'sending-mta-ip' => '198.51.100.63',
      'receiving-mx-hostname' => 'mx2.mail.company-y.example',
      'failed-session-count' => 203,
    }],
  }],
};

sub dies_with($change,$expected,$name) {
  my $broken = clone $data;
  $change->($broken);
  throws_ok( sub { Mail::TLSRPT::Report->new_from_data($broken) }, $expected, $name );
}

lives_ok( sub { Mail::TLSRPT::Report->new_from_data($data) }, 'unbroken report lives' );

dies_with( sub($d) { $d->{'date-range'}->{'start-datetime'} = 'yesterday-ish' },
  qr/^date-range\.start-datetime: could not parse date "yesterday-ish"/, 'bad date says which and what' );
dies_with( sub($d) { $d->{'date-range'}->{'start-datetime'} = { 'day' => 1 } },
  qr/^date-range\.start-datetime: not a string/, 'date not a string says so' );
foreach my $bad_date ( '2016', '1', '12:00', '2016-04-01', '2016-04-01T00:00:00', '2016-04-01T00:00:00 +1000',
    '2016-04-01T00:00:00+0000', '2016-04-01T00:00:00+24:00', '2016-04-01T00:00:00+10:60' ) {
  dies_with( sub($d) { $d->{'date-range'}->{'start-datetime'} = $bad_date },
    qr/^date-range\.start-datetime: could not parse date/, 'date "'.$bad_date.'" is not RFC 3339' );
}
foreach my $good_date ( '2016-04-01T10:00:00+10:00', '2016-04-01t00:00:00z', '2016-04-01 00:00:00.25Z' ) {
  my $good = clone $data;
  $good->{'date-range'}->{'start-datetime'} = $good_date;
  is( Mail::TLSRPT::Report->new_from_data($good)->start_datetime->epoch, 1459468800, 'date "'.$good_date.'" is RFC 3339' );
}
dies_with( sub($d) { delete $d->{'date-range'}->{'end-datetime'} },
  qr/^date-range\.end-datetime: missing/, 'missing date says which' );
dies_with( sub($d) { $d->{'date-range'} = 'today' },
  qr/^date-range: not an object/, 'date-range not an object' );
dies_with( sub($d) { $d->{policies} = {} },
  qr/^policies: not a list/, 'policies not a list' );
dies_with( sub($d) { $d->{policies}->[0]->{summary}->{'total-successful-session-count'} = 'lots' },
  qr/^policies\[0\]: .*"lots".*total_successful_session_count/, 'bad count says which policy' );
dies_with( sub($d) { $d->{policies}->[0]->{summary} = 'none' },
  qr/^policies\[0\]: summary: not an object/, 'summary not an object' );
dies_with( sub($d) { $d->{policies}->[0]->{'failure-details'} = 'none' },
  qr/^policies\[0\]: failure-details: not a list/, 'failure-details not a list' );
dies_with( sub($d) { delete $d->{policies}->[0]->{'failure-details'}->[1]->{'result-type'} },
  qr/^policies\[0\]: failure-details\[1\]: .*result_type/, 'missing result-type says which failure' );
dies_with( sub($d) { $d->{policies}->[0]->{'failure-details'}->[1] = 'oops' },
  qr/^policies\[0\]: failure-details\[1\]: Failure is not an object/, 'failure not an object' );
dies_with( sub($d) { $d->{policies}->[0]->{policy}->{'mx-host'} = [ {} ] },
  qr/^policies\[0\]: policy\.mx-host: not a list of strings/, 'mx-host list of non strings' );
dies_with( sub($d) { $d->{policies}->[0]->{'failure-details'}->[0]->{'sending-mta-ip'} = 'not-an-ip' },
  qr/^policies\[0\]: failure-details\[0\]: Value "not-an-ip" did not pass/, 'bad ip says what' );
throws_ok( sub { Mail::TLSRPT::Report->new_from_data([]) },
  qr/^Report is not an object/, 'report not an object' );

done_testing;
