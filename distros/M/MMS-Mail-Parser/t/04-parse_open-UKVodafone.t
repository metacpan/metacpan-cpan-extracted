#!perl -T

use Test::More tests => 4;
use MMS::Mail::Parser;

my $parser;
my $mmsparser;
my $message;
my $parsed;

SKIP: {

  eval {
    require MMS::Mail::Provider::UKVodafone;
  };

  skip "MMS::Mail::Provider::UKVodafone not installed", 4 if $@;

  $parser = new MIME::Parser;
  $mmsparser = MMS::Mail::Parser->new(mimeparser=>$parser);
  $message = $mmsparser->parse_open('t/msgs/UKVodafone');
  isa_ok($message, 'MMS::Mail::Message');
  is($message->is_valid,1);
  $parsed = $mmsparser->provider_parse;
  isa_ok($parsed, 'MMS::Mail::Message::Parsed');
  is($parsed->is_valid,1);

}
