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

throws_ok { JSON::Slurper->new(encoder => 1) } qr/encoder must be an object that can encode and decode/, 'new passed int throws';
throws_ok { JSON::Slurper->new(encoder => 'string') } qr/encoder must be an object that can encode and decode/,
  'new passed string throws';
throws_ok { JSON::Slurper->new(encoder => undef) } qr/encoder must be an object that can encode and decode/,
  'new passed undef throws';
throws_ok { JSON::Slurper->new(encoder => []) } qr/encoder must be an object that can encode and decode/,
  'new passed array ref throws';
throws_ok { JSON::Slurper->new(encoder => {}) } qr/encoder must be an object that can encode and decode/,
  'new passed hash ref throws';

throws_ok { JSON::Slurper->new(encoder => TestEncoder->new) } qr/encoder must be an object that can encode and decode/,
  'new passed object that can only encode throws';
throws_ok { JSON::Slurper->new(encoder => TestDecoder->new) } qr/encoder must be an object that can encode and decode/,
  'new passed object that can only decode throws';
lives_ok { JSON::Slurper->new(encoder => TestEncoderAndDecoder->new) } 'new passed object that can encode and decode lives';

lives_ok { JSON::Slurper->new(auto_ext => 1) } 'new passed auto_ext lives';
lives_ok { JSON::Slurper->new(encoder => TestEncoderAndDecoder->new, auto_ext => 1) } 'new passed encoder and auto_ext lives';

throws_ok { JSON::Slurper->new(encoder => TestEncoderAndDecoder->new, extra => 1) }
qr/invalid constructor arguments provided: extra/, 'new passed encoder/decoder and uknown extra arg throws';

done_testing;
