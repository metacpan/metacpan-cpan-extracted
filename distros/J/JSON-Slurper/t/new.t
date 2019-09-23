use strict;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestEncoder;
use TestDecoder;
use TestEncoderAndDecoder;
use JSON::Slurper;

lives_ok { JSON::Slurper->new } 'new with no arguments lives';

throws_ok { JSON::Slurper->new(1) } qr/encoder must be an object that can encode and decode/, 'new passed int throws';
throws_ok { JSON::Slurper->new('string') } qr/encoder must be an object that can encode and decode/,
  'new passed string throws';
throws_ok { JSON::Slurper->new(undef) } qr/encoder must be an object that can encode and decode/,
  'new passed undef throws';
throws_ok { JSON::Slurper->new([]) } qr/encoder must be an object that can encode and decode/,
  'new passed array ref throws';
throws_ok { JSON::Slurper->new({}) } qr/encoder must be an object that can encode and decode/,
  'new passed hash ref throws';

throws_ok { JSON::Slurper->new(TestEncoder->new) } qr/encoder must be an object that can encode and decode/,
  'new passed object that can only encode throws';
throws_ok { JSON::Slurper->new(TestDecoder->new) } qr/encoder must be an object that can encode and decode/,
  'new passed object that can only decode throws';
lives_ok { JSON::Slurper->new(TestEncoderAndDecoder->new) } 'new passed object that can encode and decode lives';

throws_ok { JSON::Slurper->new(TestEncoderAndDecoder->new, 1) }
qr/JSON::Slurper only accepts one argument for its constructor/, 'new passed encoder/decoder and int throws';
throws_ok { JSON::Slurper->new(TestEncoderAndDecoder->new, TestEncoderAndDecoder->new) }
qr/JSON::Slurper only accepts one argument for its constructor/, 'new passed two encoder/decoders throws';
throws_ok { JSON::Slurper->new(1, TestEncoderAndDecoder->new) }
qr/JSON::Slurper only accepts one argument for its constructor/, 'new passed int and encoder/decoder throws';
throws_ok { JSON::Slurper->new(TestEncoderAndDecoder->new, TestEncoderAndDecoder->new, TestEncoderAndDecoder->new) }
qr/JSON::Slurper only accepts one argument for its constructor/, 'new passed three encoder/decoders throws';

ok 1;

done_testing;
