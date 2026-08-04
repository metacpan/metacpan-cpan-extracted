use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }

my $schema = {
    type       => 'object',
    required   => ['a'],
    properties => {
        a => { type => 'integer', default => 5 },
        b => { type => 'string' },
    },
};

# without apply_defaults: a missing required property fails
{
    my $v = JSON::Schema::Fast->compile($schema);
    ok(!$v->is_valid(J('{}')), 'missing required a fails without apply_defaults');
}

# with apply_defaults: the default satisfies required (working copy)
{
    my $v = JSON::Schema::Fast->compile($schema, apply_defaults => 1);
    ok( $v->is_valid(J('{}')),        'default fills missing required a');
    ok( $v->is_valid(J('{"b":"x"}')), 'default fills a alongside present b');
    ok(!$v->is_valid(J('{"a":"x"}')), 'present-but-wrong a is not overridden');
}

{
    my $v = JSON::Schema::Fast->compile($schema, apply_defaults => 1);
    my $data = J('{}');
    $v->is_valid($data);
    is_deeply($data, { a => 5 }, 'caller data not mutated by apply_defaults');
}

# nested defaults apply at each level
{
    my $v = JSON::Schema::Fast->compile({
        type => 'object',
        properties => {
            inner => {
                type => 'object', required => ['x'],
                properties => { x => { type => 'integer', default => 1 } },
            },
        },
    }, apply_defaults => 1);
    ok( $v->is_valid(J('{"inner":{}}')), 'nested default fills inner.x');
}

done_testing;
