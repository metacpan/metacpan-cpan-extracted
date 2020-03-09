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
use MIME::Base64 qw{ decode_base64 };

sub read_file($file_name) {
  open my $fh, '<', $file_name;
  my @lines = <$fh>;
  close $fh;
  return join('',@lines);
}

sub read_file_gz($file_name) {
  open my $fh, '<', $file_name;
  my @lines = <$fh>;
  close $fh;
  return decode_base64 join('',@lines);
}

subtest 'create from json in file' => sub {
  my $tlsrpt;
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new_from_json( read_file('t/data/report.json')  ) }, 'new_from_json lives' );
  is( $tlsrpt->as_json, read_file('t/data/expected.json'), 'as_json output is as expected' );
};

subtest 'create from json in gz file' => sub {
  my $tlsrpt;
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new_from_json_gz( read_file_gz('t/data/report.json.gz.b64')  ) }, 'new_from_json lives' );
  is( $tlsrpt->as_json, read_file('t/data/expected.json'), 'as_json output is as expected' );
};

done_testing;

