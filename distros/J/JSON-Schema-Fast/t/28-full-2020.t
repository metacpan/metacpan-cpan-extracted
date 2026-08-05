use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }
sub V { JSON::Schema::Fast->compile($_[0]) }

# --- $id base scopes + $anchor ------------------------------------------------
{
    my $v = V({
        '$id'   => 'https://ex/root',
        '$defs' => { pos => { '$anchor' => 'positive', type => 'integer', minimum => 1 } },
        '$ref'  => '#positive',
    });
    ok( $v->is_valid(J('3')),  '$anchor ref resolves');
    ok(!$v->is_valid(J('0')),  'and enforces the target (minimum)');
    ok(!$v->is_valid(J('"x"')),'and the target type');
}

# --- remote documents via a resolver ------------------------------------------
{
    my %docs = (
        'https://ex/name' => { type => 'string', minLength => 1 },
    );
    my $v = JSON::Schema::Fast->compile(
        { type => 'object', properties => { name => { '$ref' => 'https://ex/name' } } },
        resolver => sub { $docs{ $_[0] } },
    );
    ok( $v->is_valid(J('{"name":"ada"}')), 'remote $ref resolves via resolver');
    ok(!$v->is_valid(J('{"name":""}')),    'and enforces the remote schema');
}

# --- unevaluatedProperties ----------------------------------------------------
{
    my $v = V({
        type => 'object',
        properties => { foo => { type => 'string' } },
        allOf => [ { properties => { bar => { type => 'string' } } } ],
        unevaluatedProperties => 0,
    });
    ok( $v->is_valid(J('{"foo":"a","bar":"b"}')), 'foo + allOf bar are evaluated');
    ok(!$v->is_valid(J('{"foo":"a","baz":"c"}')), 'baz is unevaluated -> rejected');
}
# cousins are isolated: unevaluatedProperties in one allOf branch cannot see a
# sibling branch's properties
{
    my $v = V({ allOf => [ { properties => { foo => {} } }, { unevaluatedProperties => 0 } ] });
    ok(!$v->is_valid(J('{"foo":1}')), 'cousin unevaluatedProperties does not see sibling foo');
}

# --- unevaluatedItems ---------------------------------------------------------
{
    my $v = V({ prefixItems => [ { type => 'integer' } ], unevaluatedItems => { type => 'string' } });
    ok( $v->is_valid(J('[1,"a","b"]')), 'prefix int then unevaluated strings');
    ok(!$v->is_valid(J('[1,2]')),       'unevaluated non-string rejected');
}

# --- $dynamicRef extension pattern (bookend) ---------------------------------
{
    my $v = V({
        '$id' => 'https://ex/list',
        type => 'array',
        items => { '$dynamicRef' => '#T' },
        '$defs' => { T => { '$dynamicAnchor' => 'T' } },   # default: anything
    });
    ok($v->is_valid(J('[1,"x",true]')), 'dynamicRef with only the default anchor accepts anything');
}

# --- $vocabulary: a metaschema without validation vocab makes minimum a no-op -
{
    my %meta = (
        'https://ex/meta-noval' => {
            '$vocabulary' => {
                'https://json-schema.org/draft/2020-12/vocab/applicator' => JSON::Schema::Fast->can('compile') ? \1 : 1,
            },
        },
    );
    $meta{'https://ex/meta-noval'}{'$vocabulary'}{'https://json-schema.org/draft/2020-12/vocab/applicator'} = 1;
    my $v = JSON::Schema::Fast->compile(
        { '$schema' => 'https://ex/meta-noval', properties => { n => { minimum => 10 } } },
        resolver => sub { $meta{ $_[0] } },
    );
    ok($v->is_valid(J('{"n":1}')), 'minimum is not asserted when validation vocab is off');
}

done_testing;
