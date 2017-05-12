use Test::More qw<no_plan>;
use strict;
use warnings;
use JavaScript::HashRef::Decode qw<decode_js>;

# This uses the JavaScript::HashRef::Decode **EXTERNAL INTERFACE**

is_deeply(decode_js('{}'), {}, 'empty hashref');

is_deeply(
    decode_js('{k:"v",y:undefined}'),
    { k => 'v', y => undef },
    'simple hashref (dquote)'
);

is_deeply(
    decode_js("{k:'v',y:undefined}"),
    { k => 'v', y => undef },
    'simple hashref (squote)'
);

is_deeply(
    decode_js('{k:[1,undefined,3],y:{k:"v",y:123}}'),
    { k => [ 1, undef, 3 ], y => { k => 'v', y => 123 } },
    'complex hashref'
);
