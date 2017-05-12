#!perl
use strict;
use Test::More;
use Test::Exception;
use FindBin;

use File::Compare;
use File::Temp;
use File::Slurp;
use MIME::Base64 qw(encode_base64 decode_base64 encode_base64url decode_base64url);

use Data::Dumper;
use lib qw(lib/);

use Test::Differences;

use Email::Assets;

my @test_paths = map { $FindBin::Bin . '/'. $_ } qw(aa bb cc);
my $raw_image = read_file('t/aa/codeworks.jpg');
my $base_64_url_image = encode_base64url($raw_image);

my $assets = Email::Assets->new( base => [ @test_paths ] );

my $base64_url_asset = $assets->include_base64($base_64_url_image, 'codeworks.jpg', { url_encoding => 1 } );
is($base64_url_asset->mime_type, 'image/jpeg', 'detected mime type ok');
my $fh = File::Temp->new();
my $fname = $fh->filename;
print $fh decode_base64($base64_url_asset->file_as_base64);
close $fh;
ok(compare($fname, 't/aa/codeworks.jpg') == 0, 'file matches from base64 url data after decoding');

my $mime_part = $base64_url_asset->as_mime_part;
isa_ok($mime_part, 'MIME::Lite');
is($mime_part->attr("content-type"), 'image/jpeg', 'content type correct');

my $mime_body_string = $mime_part->body_as_string;

eq_or_diff($mime_body_string, $base64_url_asset->file_as_base64, "mime lite output matches");

$fh = File::Temp->new();
$fname = $fh->filename;
print $fh decode_base64($mime_body_string);
close $fh;
ok(compare($fname, 't/aa/codeworks.jpg') == 0, 'file matches from base64 url data after decoding');

done_testing();
