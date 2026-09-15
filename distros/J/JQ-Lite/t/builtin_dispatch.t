use strict;
use warnings;

use Test::More;

use lib 'lib';
use JQ::Lite;
use JQ::Lite::Builtin ();

my @names = JQ::Lite::Builtin->registered_names;
my %registered = map { $_ => 1 } @names;
ok($registered{keys}, 'object built-in is registered');
ok($registered{flatten}, 'array built-in is registered');
ok($registered{upper}, 'string built-in is registered');
ok($registered{floor}, 'math built-in is registered');
ok($registered{sum}, 'aggregate built-in is registered');
ok($registered{'@base64'}, 'encoding built-in is registered');
ok($registered{type}, 'type built-in is registered');

my $jq = JQ::Lite->new;
my ($matched, $outputs) = JQ::Lite::Builtin->dispatch($jq, 'upper', ['mixed']);
ok($matched, 'exact-name dispatch reports a match');
is_deeply($outputs, ['MIXED'], 'exact-name dispatch invokes its category handler');

($matched, $outputs) = JQ::Lite::Builtin->dispatch($jq, 'clamp(2, 4)', [1, 3, 5]);
ok($matched, 'parameterized-call dispatch reports a match');
is_deeply($outputs, [2, 3, 4], 'parameterized dispatch passes parsed arguments');

($matched, $outputs) = JQ::Lite::Builtin->dispatch($jq, 'not_a_builtin', [1]);
ok(!$matched, 'unknown filters remain available to language dispatch');
is_deeply($outputs, [], 'unknown dispatch returns no outputs');

is_deeply(
    [ $jq->run_query('[1,5,3]', 'reverse | clamp(2, 4)') ],
    [[3, 4, 2]],
    'public query execution composes category built-ins',
);

done_testing;
