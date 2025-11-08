use strict;
use warnings;

use Test::More;
use JSON::PP ();

use lib 'lib';
use JQ::Lite;

my $jq = JQ::Lite->new;

my $fixture = '{"name":"Alice","age":30,"nested":{"flag":true}}';

sub run {
    my ($input, $filter) = @_;
    my @out = $jq->run_query($input, $filter);
    return \@out;
}

is_deeply(run($fixture, '.name | @json'), ['"Alice"'], '@json wraps string values in quotes');
is_deeply(run($fixture, '.age | @json'), ['30'], '@json renders numbers without extra quoting');
is_deeply(run($fixture, '.nested | @json'), ['{"flag":true}'], '@json encodes objects as compact JSON strings');
is_deeply(run($fixture, '.nested.flag | @json'), ['true'], '@json preserves boolean literals');
is_deeply(run('null', '@json'), ['null'], '@json emits null literal for null values');
is_deeply(run($fixture, '. | {raw: (.name | @json)}'), [{ raw => '"Alice"' }], '@json output embeds inside object constructors');
is_deeply(run($fixture, '.nested | [@json, tojson]'), [[ '{"flag":true}', '{"flag":true}' ]], '@json matches tojson output');
is_deeply(run('{"values":[1,2]}', '.values[] | @json | tonumber'), [1,2], '@json integrates with downstream filters');
is_deeply(run('[{"k":1},{"k":2}]', 'map(@json)'), [[ '{"k":1}', '{"k":2}' ]], '@json maps across arrays');
is_deeply(run('"raw"', '@json'), ['"raw"'], '@json handles top-level scalar inputs');

plan tests => 10;

