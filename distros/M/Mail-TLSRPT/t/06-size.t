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

sub read_file($file_name) {
  open my $fh, '<', $file_name;
  my @lines = <$fh>;
  close $fh;
  return join('',@lines);
}

my $json = read_file('t/data/report.json');
gzip( \$json, \my $gz );

subtest 'max_size' => sub {
  my $size = length $json;
  lives_ok( sub { Mail::TLSRPT::Report->new_from_json($json, { max_size => $size }) }, 'json at max_size lives' );
  throws_ok( sub { Mail::TLSRPT::Report->new_from_json($json, { max_size => $size - 1 }) }, qr/larger than/, 'json over max_size dies' );
  lives_ok( sub { Mail::TLSRPT::Report->new_from_json_gz($gz, { max_size => $size }) }, 'gzip at max_size lives' );
  throws_ok( sub { Mail::TLSRPT::Report->new_from_json_gz($gz, { max_size => $size - 1 }) }, qr/larger than/, 'gzip over max_size dies' );
  throws_ok( sub { Mail::TLSRPT::Report->new_from_json($gz, { max_size => $size - 1 }) }, qr/larger than/, 'detected gzip over max_size dies' );
};

subtest 'default max_size' => sub {
  my $big = ' ' x ( 10 * 1024 * 1024 ) . $json;
  gzip( \$big, \my $big_gz );
  throws_ok( sub { Mail::TLSRPT::Report->new_from_json_gz($big_gz) }, qr/larger than 10485760 bytes/, 'gzip over 10MB dies' );
};

subtest 'corrupt gzip' => sub {
  my $corrupt = substr( $gz, 0, 20 ) . ( "\0" x 20 );
  throws_ok( sub { Mail::TLSRPT::Report->new_from_json_gz($corrupt) }, qr/Could not gunzip report/, 'corrupt gzip dies with the gunzip error' );
};

subtest 'bad gzip trailer' => sub {
  my $bad_crc = $gz;
  substr( $bad_crc, -8, 4 ) = "\0\0\0\0";
  throws_ok( sub { Mail::TLSRPT::Report->new_from_json_gz($bad_crc) }, qr/Could not gunzip report/, 'a bad CRC dies with the gunzip error' );
};

subtest 'gzip in several members' => sub {
  my ( $first, $second ) = ( substr( $json, 0, 100 ), substr( $json, 100 ) );
  gzip( \$first, \my $first_gz );
  gzip( \$second, \my $second_gz );
  my $tlsrpt;
  lives_ok( sub { $tlsrpt = Mail::TLSRPT::Report->new_from_json_gz( $first_gz . $second_gz ) }, 'gzip in two members lives' );
  is( $tlsrpt->report_id, Mail::TLSRPT::Report->new_from_json($json)->report_id, 'and reads both' );
  lives_ok( sub { Mail::TLSRPT::Report->new_from_json_gz( $first_gz . $second_gz . "\n" ) }, 'and what follows the last is ignored' );
};

subtest 'bytes after the gzip' => sub {
  foreach my $tail ( "\n", "\r\n", "\0" x 512, 'garbage' ) {
    ( my $name = $tail ) =~ s/([^ -~])/sprintf('\\x%02x',ord $1)/ge;
    lives_ok( sub { Mail::TLSRPT::Report->new_from_json( $gz . $tail ) }, 'gzip followed by "' . substr( $name, 0, 20 ) . '" lives' );
  }
};

subtest 'not gzipped' => sub {
  lives_ok( sub { Mail::TLSRPT::Report->new_from_json_gz($json) }, 'new_from_json_gz reads JSON that is not gzipped' );
};

subtest 'gzip inside gzip' => sub {
  gzip( \$gz, \my $double_gz );
  throws_ok( sub { Mail::TLSRPT::Report->new_from_json_gz($double_gz) }, qr/gzipped twice/, 'gzip inside gzip dies' );
};

done_testing;
