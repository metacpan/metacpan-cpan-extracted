#!/usr/bin/perl

use Test::More;
plan tests => 9;

use_ok('Geo::PostalCode::NoDB');

use File::Spec;
use File::Basename;
use LWP::Simple;
use Archive::Extract;
use File::Slurp;
use Digest::MD5 'md5_hex';

my $dest_file =
  File::Spec->catfile( dirname(__FILE__), '..', 'data', 'csvfile.zip' );

ok( -w dirname($dest_file), "\$dest_file: $dest_file is writable?" );

my $resp = getstore( 'http://damog.net/files/misc/zipcodes-csv-10-Aug-2004.zip',
    $dest_file );

ok( defined $resp, 'response code defined');
cmp_ok($resp, '>=', 200, 'response code >= 200');
cmp_ok($resp, '<', 300, 'response code < 300');

my $ae = Archive::Extract->new(archive => $dest_file);
ok( defined $ae, 'Archive::Extract defined');

my $extracted = $ae->extract( to => dirname( $dest_file ));
ok( defined $ae, 'extracted properly');

my $csvfile = File::Spec->catfile( dirname($dest_file), 'zipcodes-csv-10-Aug-2004', 'zipcode.csv');

ok( -f $csvfile and -r $csvfile, "\$csvfile: $csvfile is there and is readable");

my $csvdata = read_file( $csvfile );

is(md5_hex($csvdata), '47fe3bad88ba20c65bdbd6b895c2dac3', 'Data inside the file needs to be what I expect');
