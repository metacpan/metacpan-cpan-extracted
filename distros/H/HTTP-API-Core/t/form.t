use strict;
use warnings;
use utf8;
use Test::More;

use HTTP::API::Core::Form qw(form_urlencode);

is form_urlencode({ b => 2, a => 1 }), 'a=1&b=2',
    'orders keys deterministically';
is form_urlencode({ q => 'a b+c' }), 'q=a+b%2Bc',
    'uses plus for spaces and percent-encodes reserved characters';
is form_urlencode({ punctuation => '*~' }), 'punctuation=*%7E',
    'uses the form-urlencoded percent-encode set';
is form_urlencode({ name => "é😀" }), 'name=%C3%A9%F0%9F%98%80',
    'percent-encodes UTF-8 bytes';
is form_urlencode({ empty => undef }), 'empty=',
    'encodes undefined values as empty strings';
is form_urlencode({ tag => ['one', 'two'] }), 'tag=one&tag=two',
    'encodes array values as repeated parameters';

eval { form_urlencode([]) };
like $@, qr/form parameters must be a hash reference/,
    'rejects non-hash parameters';

eval { form_urlencode({ nested => { x => 1 } }) };
like $@, qr/form parameter values must be scalars/,
    'rejects nested reference values';

eval { form_urlencode({ mixed => ['ok', { x => 1 }] }) };
like $@, qr/form parameter array values must contain only scalars/,
    'rejects reference values nested inside arrays';

is form_urlencode({ tag => ['one', undef, 'two'] }), 'tag=one&tag=&tag=two',
    'preserves undefined array values as empty form values';

done_testing;
