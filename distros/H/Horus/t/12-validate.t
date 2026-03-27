use 5.008003;
use strict;
use warnings;
use Test::More tests => 10;
use Horus qw(:all);

# Valid UUIDs
ok(uuid_validate(uuid_v4()), 'v4 is valid');
ok(uuid_validate(uuid_v1()), 'v1 is valid');
ok(uuid_validate(uuid_v7()), 'v7 is valid');
ok(uuid_validate(uuid_nil()), 'nil is valid');
ok(uuid_validate(uuid_max()), 'max is valid');

# Invalid strings
ok(!uuid_validate(''), 'empty string is invalid');
ok(!uuid_validate('not-a-uuid'), 'random string is invalid');
ok(!uuid_validate('00000000-0000-0000-0000-00000000000'), 'too short is invalid');
ok(!uuid_validate('00000000-0000-0000-0000-0000000000000'), 'too long is invalid');
ok(!uuid_validate('zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz'), 'non-hex is invalid');
