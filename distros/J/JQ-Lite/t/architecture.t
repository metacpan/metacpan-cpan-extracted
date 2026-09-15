use strict;
use warnings;

use Test::More;
use JSON::PP qw(encode_json);

use lib 'lib';
use JQ::Lite;
use JQ::Lite::AST ();
use JQ::Lite::Evaluator ();
use JQ::Lite::Parser ();
use JQ::Lite::Runtime ();
use JQ::Lite::Tokenizer ();

my $tokens = JQ::Lite::Tokenizer::tokenize('.users | map(.name | length) | .[]');
is_deeply(
    [ map { $_->{type} } @{$tokens} ],
    [qw(FILTER PIPE FILTER PIPE FILTER EOF)],
    'tokenizer exposes top-level pipeline boundaries',
);
is(
    $tokens->[2]{value},
    ' map(.name | length) ',
    'tokenizer keeps a nested pipeline inside its filter token',
);

my $ast = JQ::Lite::Parser::parse_ast('.users[] | .name');
isa_ok($ast, 'JQ::Lite::AST::Pipeline');
is($ast->type, 'Pipeline', 'pipeline has an explicit node type');
my @filters = $ast->filters;
is(scalar @filters, 2, 'parser creates one AST filter per pipeline stage');
isa_ok($filters[0], 'JQ::Lite::AST::Filter');
is_deeply(
    [ map { $_->source } @filters ],
    [qw(users[] name)],
    'AST retains the compatibility-normalized filter representation',
);

my $jq = JQ::Lite->new;
my $runtime = JQ::Lite::Runtime->new(owner => $jq);
my $evaluator = JQ::Lite::Evaluator->new(runtime => $runtime);
my $data = $runtime->decode_input('{"users":[{"name":"Ada"},{"name":"Grace"}]}');
is_deeply(
    [ $evaluator->evaluate($ast, $data) ],
    [qw(Ada Grace)],
    'runtime and evaluator execute a representative traversal pipeline',
);

my @cases = (
    [ '{"items":[1,2,3]}', '.items | map(. + 1)', [ [2, 3, 4] ] ],
    [ '{"a":true}', 'if .a then "yes" else "no" end', ['yes'] ],
    [ '[3,1,2]', 'sort | .[]', [1, 2, 3] ],
    [ '{"name":"Ada"}', '{name, size: (.name | length)}',
        [ { name => 'Ada', size => 3 } ] ],
);

for my $case (@cases) {
    my ($json, $query, $expected) = @{$case};
    is_deeply(
        [ $jq->run_query($json, $query) ],
        $expected,
        "public execution preserves behavior for $query",
    );
}

done_testing;
