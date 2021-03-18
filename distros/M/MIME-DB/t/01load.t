use strict;
use Test::More;

require_ok 'MIME::DB';

ok(MIME::DB->can('data'), 'has a data method');

isa_ok(MIME::DB->data, 'HASH', 'data method returns a HASH reference');

done_testing()