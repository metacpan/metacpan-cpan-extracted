use strict;
use warnings;
use Test::More;
use EV::Kafka;

plan tests => 5;

# CRC32C standard test vectors
is EV::Kafka::_crc32c(''),          0,          'crc32c empty';
is EV::Kafka::_crc32c('123456789'), 0xE3069283, 'crc32c "123456789"';

# deterministic
is EV::Kafka::_crc32c('hello'), EV::Kafka::_crc32c('hello'), 'deterministic';

# different inputs produce different CRCs
isnt EV::Kafka::_crc32c('a'), EV::Kafka::_crc32c('b'), 'different inputs differ';

# binary data
ok defined EV::Kafka::_crc32c("\x00\xff\x80"), 'binary data ok';
