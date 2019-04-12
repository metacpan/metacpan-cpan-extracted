use warnings;
use strict;

use JavaScript::V8;
use Test::More tests => 3;

my $context = JavaScript::V8::Context->new;
$context->bind(my_object => {
    method => sub {
        return $_[0];
    }
});
is $context->eval('my_object.method(42)'), 42;

$context->bind_ro(x => 2);
is $context->eval('x = 3'), 3;
is $context->eval('x'), 2;
