#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny;

use Langertha::Engine::Whisper;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my $whisper_testurl = 'http://test.url:12345/v1';
my $whisper = Langertha::Engine::Whisper->new(
  url => $whisper_testurl,
  transcription_model => 'model',
);
my $whisper_request = $whisper->transcription(path(__FILE__)->parent->child('data/testfile')->absolute, language => 'en');
is($whisper_request->uri, $whisper_testurl.'/audio/transcriptions', 'Whisper request uri is correct');
is($whisper_request->method, 'POST', 'Whisper request method is correct');
is($whisper_request->header('Content-Type'), 'multipart/form-data; boundary="XyXLaXyXngXyXerXyXthXyXaXyX"', 'Whisper request Content Type is correct');
my $content = "--XyXLaXyXngXyXerXyXthXyXaXyX
Content-Disposition: form-data; name=\"file\"; filename=\"testfile\"
Content-Type: application/octet-stream

testxxxx
--XyXLaXyXngXyXerXyXthXyXaXyX
Content-Disposition: form-data; name=\"language\"

en
--XyXLaXyXngXyXerXyXthXyXaXyX
Content-Disposition: form-data; name=\"model\"

model
--XyXLaXyXngXyXerXyXthXyXaXyX--
"; $content =~ s/\n/\r\n/g;
is($whisper_request->content, $content, 'Whisper request content is correct');

done_testing;
