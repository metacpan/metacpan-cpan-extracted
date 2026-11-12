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
use IO::Compress::Gzip qw{ gzip };

my $json = qq'{
  "organization-name": "Soci\xc3\xa9t\xc3\xa9 X",
  "date-range": {
    "start-datetime": "2016-04-01T00:00:00Z",
    "end-datetime": "2016-04-01T23:59:59Z"
  },
  "contact-info": "sts-reporting\@company-x.example",
  "report-id": "5065427c-23d3-47ca-b6e0-946ea0e8c4be",
  "policies": []
}';

subtest 'utf8 json' => sub {
  my $tlsrpt;
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new_from_json($json) }, 'new_from_json lives' );
  is( $tlsrpt->organization_name, "Soci\x{e9}t\x{e9} X", 'organization_name decoded as UTF-8' );
};

subtest 'utf8 json round trip' => sub {
  my $tlsrpt = Mail::TLSRPT::Report->new_from_json($json);
  my $again;
  lives_ok( sub { $again = Mail::TLSRPT::Report->new_from_json( $tlsrpt->as_json ) }, 'as_json output is read back' );
  is( $again->organization_name, "Soci\x{e9}t\x{e9} X", 'with the same organization_name' );
  ok( ! utf8::is_utf8( $tlsrpt->as_json ), 'as_json returns bytes' );
};

subtest 'utf8 json in gz' => sub {
  my $tlsrpt;
  gzip( \$json, \my $gz );
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new_from_json_gz($gz) }, 'new_from_json_gz lives' );
  is( $tlsrpt->organization_name, "Soci\x{e9}t\x{e9} X", 'organization_name decoded as UTF-8' );
};

done_testing;
