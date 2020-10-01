#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Prelude;
use Test::More;
use Mail::BIMI;
use Mail::BIMI::Indicator;
use MIME::Base64;
my $bimi = Mail::BIMI->new;

subtest 'no location' => sub {
  my $indicator = Mail::BIMI::Indicator->new( bimi_object=>$bimi );
  is($indicator->data,'','No data');
  is_deeply($indicator->error_codes,['CODE_MISSING_LOCATION'],'Error codes');
};

subtest 'svg from file' => sub {
  my $bimi = Mail::BIMI->new;
  $bimi->options->svg_from_file('t/data/dummy1');
  my $indicator = Mail::BIMI::Indicator->new( bimi_object=>$bimi, uri => 'dummy' );
  is($indicator->data,"dummyfile1\n",'Data was read from file');
  is_deeply($indicator->error_codes,[],'No error codes');
};

subtest 'svg size (under)' => sub {
  my $xml = '<svg version="1.2" baseProfile="tiny-ps" xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><title>FM-Icon-RGB</title><g id="Artwork"><rect width="1024" height="1024" fill="#FFFFFF"/><path d="M120.16,512c0-216.4,175.43-391.84,391.84-391.84,136,0,255.71,69.34,326,174.53l77.19,15.21,9.58-73.06c-89-133.18-240.56-221-412.74-221C238,15.87,15.87,238,15.87,512A493.78,493.78,0,0,0,99.19,787.21l74.72,9.68L186,729.35A390,390,0,0,1,120.16,512Z" fill="#0067b9"/><path d="M926,238.64c-.41-.61-.83-1.2-1.24-1.8L838,294.69c.41.6.83,1.19,1.23,1.8A389.91,389.91,0,0,1,903.83,512c0,216.4-175.43,391.84-391.83,391.84-135.21,0-254.42-68.49-324.84-172.66-.41-.6-.79-1.22-1.19-1.83L99.19,787.21c.41.6.78,1.22,1.19,1.83C189.51,921.2,340.6,1008.13,512,1008.13c274,0,496.13-222.13,496.13-496.13A493.68,493.68,0,0,0,926,238.64Z" fill="#69b3e7"/><path d="M512,512,276.15,354.76V669.23h0l148.2-45.86Z" fill="#ffc107"/><path d="M276.15,669.24H731.27a16.58,16.58,0,0,0,16.58-16.59V354.76Z" fill="#333e48"/></g></svg>';
  my $bimi = Mail::BIMI->new;
  $bimi->options->svg_max_size(1027);
  my $indicator = Mail::BIMI::Indicator->new( bimi_object=>$bimi, uri => 'dummy',data => $xml );
  is($indicator->is_valid,1,'SVG is valid');
  is($indicator->data,$xml,'Data was returned');
  is_deeply($indicator->error_codes,[],'No error codes');
};

subtest 'svg size (over)' => sub {
  my $xml = '<svg version="1.2" baseProfile="tiny-ps" xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><title>FM-Icon-RGB</title><g id="Artwork"><rect width="1024" height="1024" fill="#FFFFFF"/><path d="M120.16,512c0-216.4,175.43-391.84,391.84-391.84,136,0,255.71,69.34,326,174.53l77.19,15.21,9.58-73.06c-89-133.18-240.56-221-412.74-221C238,15.87,15.87,238,15.87,512A493.78,493.78,0,0,0,99.19,787.21l74.72,9.68L186,729.35A390,390,0,0,1,120.16,512Z" fill="#0067b9"/><path d="M926,238.64c-.41-.61-.83-1.2-1.24-1.8L838,294.69c.41.6.83,1.19,1.23,1.8A389.91,389.91,0,0,1,903.83,512c0,216.4-175.43,391.84-391.83,391.84-135.21,0-254.42-68.49-324.84-172.66-.41-.6-.79-1.22-1.19-1.83L99.19,787.21c.41.6.78,1.22,1.19,1.83C189.51,921.2,340.6,1008.13,512,1008.13c274,0,496.13-222.13,496.13-496.13A493.68,493.68,0,0,0,926,238.64Z" fill="#69b3e7"/><path d="M512,512,276.15,354.76V669.23h0l148.2-45.86Z" fill="#ffc107"/><path d="M276.15,669.24H731.27a16.58,16.58,0,0,0,16.58-16.59V354.76Z" fill="#333e48"/></g></svg>';
  my $bimi = Mail::BIMI->new;
  $bimi->options->svg_max_size(1007);
  my $indicator = Mail::BIMI::Indicator->new( bimi_object=>$bimi, uri => 'dummy',data => $xml );
  is($indicator->is_valid,0,'SVG is not valid');
  is($indicator->data,$xml,'Data was returned');
  is_deeply($indicator->error_codes,['SVG_SIZE'],'Error codes');
};

subtest 'svg invalid for profile' => sub {
  my $xml = '<svg baseProfile="tiny-ps" style="foo" xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><title>FM-Icon-RGB</title><g id="Artwork"><rect width="1024" height="1024" fill="#FFFFFF"/><path d="M120.16,512c0-216.4,175.43-391.84,391.84-391.84,136,0,255.71,69.34,326,174.53l77.19,15.21,9.58-73.06c-89-133.18-240.56-221-412.74-221C238,15.87,15.87,238,15.87,512A493.78,493.78,0,0,0,99.19,787.21l74.72,9.68L186,729.35A390,390,0,0,1,120.16,512Z" fill="#0067b9"/><path d="M926,238.64c-.41-.61-.83-1.2-1.24-1.8L838,294.69c.41.6.83,1.19,1.23,1.8A389.91,389.91,0,0,1,903.83,512c0,216.4-175.43,391.84-391.83,391.84-135.21,0-254.42-68.49-324.84-172.66-.41-.6-.79-1.22-1.19-1.83L99.19,787.21c.41.6.78,1.22,1.19,1.83C189.51,921.2,340.6,1008.13,512,1008.13c274,0,496.13-222.13,496.13-496.13A493.68,493.68,0,0,0,926,238.64Z" fill="#69b3e7"/><path d="M512,512,276.15,354.76V669.23h0l148.2-45.86Z" fill="#ffc107"/><path d="M276.15,669.24H731.27a16.58,16.58,0,0,0,16.58-16.59V354.76Z" fill="#333e48"/></g></svg>';
  my $indicator = Mail::BIMI::Indicator->new( bimi_object=>$bimi, uri => 'dummy',data => $xml );
  is($indicator->is_valid,0,'SVG is not valid');
  is($indicator->data,$xml,'Data was returned');
  is_deeply($indicator->error_codes,['SVG_VALIDATION_ERROR'],'Error codes');
};

subtest 'svg invalid for profile (no validation)' => sub {
  my $xml = '<svg baseProfile="tiny-ps" style="foo" xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><title>FM-Icon-RGB</title><g id="Artwork"><rect width="1024" height="1024" fill="#FFFFFF"/><path d="M120.16,512c0-216.4,175.43-391.84,391.84-391.84,136,0,255.71,69.34,326,174.53l77.19,15.21,9.58-73.06c-89-133.18-240.56-221-412.74-221C238,15.87,15.87,238,15.87,512A493.78,493.78,0,0,0,99.19,787.21l74.72,9.68L186,729.35A390,390,0,0,1,120.16,512Z" fill="#0067b9"/><path d="M926,238.64c-.41-.61-.83-1.2-1.24-1.8L838,294.69c.41.6.83,1.19,1.23,1.8A389.91,389.91,0,0,1,903.83,512c0,216.4-175.43,391.84-391.83,391.84-135.21,0-254.42-68.49-324.84-172.66-.41-.6-.79-1.22-1.19-1.83L99.19,787.21c.41.6.78,1.22,1.19,1.83C189.51,921.2,340.6,1008.13,512,1008.13c274,0,496.13-222.13,496.13-496.13A493.68,493.68,0,0,0,926,238.64Z" fill="#69b3e7"/><path d="M512,512,276.15,354.76V669.23h0l148.2-45.86Z" fill="#ffc107"/><path d="M276.15,669.24H731.27a16.58,16.58,0,0,0,16.58-16.59V354.76Z" fill="#333e48"/></g></svg>';
  my $bimi = Mail::BIMI->new;
  $bimi->options->no_validate_svg(1);
  my $indicator = Mail::BIMI::Indicator->new( bimi_object=>$bimi, uri => 'dummy',data => $xml );
  is($indicator->is_valid,1,'SVG is reported valid');
  is($indicator->data,$xml,'Data was returned');
  is_deeply($indicator->error_codes,[],'No error codes');
};

subtest 'gzip' => sub {
  my $gzipped = decode_base64('H4sICJvDu14AA0ZNX0JJTUkuc3ZnAH1TS2/bMAy+71cY3lWiRVLPIQmQFug2oAWKHXrYLXXdxJjX
FKlRd/9+lO0ky2U2RJEyHx8/you3923xuHlr7g/757ZrlmXfvvwpi4/f3cvbstz1/euXqhqGAQaG
/WFbkTGmkqCyGNqnfrcs0ZAti13Tbnf90Xpvm+Fq/7EsTWGKfDSKcrXo275rVjd3+nu9f9E/vl4t
qulosS3ap2W5PvTD/vBLPA9N3f+vhIDtluXnm/Epq9XiddPvCklxh2QAvXJItdGEHqzC4MCy5oQQ
rZq2o4XslVHkHARUPgGLA3kJseC4CwEwKXRAqBK4qAOD8bWOSSMzYNRkDTiviVBbJAg2q9fEMUfF
MMuzLbjWNjGEqObNjG9KuVKIQUp1UjyQFPTxFqNXgQSXW3MyKq/8ojr3+fNEhzE+PKYLOpI0I9XB
21qDRQ1eVmSNQHlZEfE2CjxKFnyqxQe8OCgcOwfKWlxzTJBQzduEIBnOjiPTamRaT0xfUHyykEca
ZSjOgiXtI9ikmez4MRB4PyPUEFIGlxFi1iLf/svPDFK4y05HpJGvUeA5AUZyrlgmI4M0JgKOKI96
TcFKAzZ5MWRclL/P1rSNE/LThPxpQicmz4T79MhNuCA8F8qLgmRyiqXZ4B+8XC3inenQRmHeyl3w
5zTPzzWayzRz+BhnvwWWjsJGOHbS9Cjne5B1nWV6mEqdszJzY2POWm1lyV+7+vQXs32LV/EDAAA=');
  my $uncompressed = '<svg baseProfile="tiny" xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><title>FM-Icon-RGB</title><g id="Artwork"><rect width="1024" height="1024" fill="#FFFFFF"/><path d="M120.16,512c0-216.4,175.43-391.84,391.84-391.84,136,0,255.71,69.34,326,174.53l77.19,15.21,9.58-73.06c-89-133.18-240.56-221-412.74-221C238,15.87,15.87,238,15.87,512A493.78,493.78,0,0,0,99.19,787.21l74.72,9.68L186,729.35A390,390,0,0,1,120.16,512Z" fill="#0067b9"/><path d="M926,238.64c-.41-.61-.83-1.2-1.24-1.8L838,294.69c.41.6.83,1.19,1.23,1.8A389.91,389.91,0,0,1,903.83,512c0,216.4-175.43,391.84-391.83,391.84-135.21,0-254.42-68.49-324.84-172.66-.41-.6-.79-1.22-1.19-1.83L99.19,787.21c.41.6.78,1.22,1.19,1.83C189.51,921.2,340.6,1008.13,512,1008.13c274,0,496.13-222.13,496.13-496.13A493.68,493.68,0,0,0,926,238.64Z" fill="#69b3e7"/><path d="M512,512,276.15,354.76V669.23h0l148.2-45.86Z" fill="#ffc107"/><path d="M276.15,669.24H731.27a16.58,16.58,0,0,0,16.58-16.59V354.76Z" fill="#333e48"/></g></svg>
';
  my $indicator = Mail::BIMI::Indicator->new( bimi_object=>$bimi, uri => 'test1', data=>$gzipped );
  is($indicator->data_uncompressed, $uncompressed, 'Uncompressed data returned when requesetd (data_uncompressed)');
  is($indicator->data_maybe_compressed, $gzipped, 'Compressed data returned when data gzipped (data_maybe_compressed)');
  is($indicator->data, $gzipped, 'Compressed data returned when data gzipped (data)');
  is_deeply($indicator->error_codes,[],'No error codes');
  is(ref $indicator->data_xml,'XML::LibXML::Document','XML document returned (data_xml)');
};

subtest 'bad gzip' => sub {
  my $gzipped = decode_base64('H4sICJvDu14AA/bMAy+71cY3lWiRVLPIQmQFug2oAWKHXrYLXXdxJjX
iFKlRd/9+lO0ky2U2RJEyHx8/you3923xuHlr7g/757ZrlmXfvvwpi4/f3cvbstz1/euXqhqGAQaG
/WFbkTGmkqCyGNqnfrcs0ZAti13Tbnf90Xpvm+Fq/7EsTWGKfDSKcrXo275rVjd3+nu9f9E/vl4t
qulosS3ap2W5PvTD/vBLPA9N3f+vhIDtluXnm/Epq9XiddPvCklxh2QAvXJItdGEHqzC4MCy5oQQ
rZq2o4XslVHkHARUPgGLA3kJseC4CwEwKXRAqBK4qAOD8bWOSSMzYNRkDTiviVBbJAg2q9fEMUfF');
  my $indicator = Mail::BIMI::Indicator->new( bimi_object=>$bimi, uri => 'test1', data=>$gzipped );
  is($indicator->data_uncompressed, '', 'No uncompressed data returned when input is bad requested (data_uncompressed)');
  is_deeply($indicator->error_codes,['SVG_UNZIP_ERROR'],'Error codes');
  is($indicator->data_xml,undef,'No XML returned (data_xml)');
};

subtest 'bad xm;' => sub {
  my $bad_xml = '<xml><foo <bar>';
  my $indicator = Mail::BIMI::Indicator->new( bimi_object=>$bimi, uri => 'test1', data=>$bad_xml );
  is($indicator->data,$bad_xml,'Data set ok');
  is($indicator->data_xml,undef,'No XML returned (data_xml)');
  is_deeply($indicator->error_codes,['SVG_INVALID_XML'],'Error codes');
};

done_testing;

