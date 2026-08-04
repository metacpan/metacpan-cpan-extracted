use strict;
use warnings;
use Test::More;
use JSON::Schema::Fast;

use constant { T_STR => 8 };

# every matrix keyword parses into its present bit
{
    my $c = JSON::Schema::Fast->compile({
        type              => 'object',
        minProperties     => 1,
        properties        => { a => { type => 'string' } },
        patternProperties => { '^x' => { type => 'number' } },
        additionalProperties => 0,
        required          => ['a'],
        allOf             => [ { type => 'object' } ],
        anyOf             => [ { type => 'object' }, { type => 'array' } ],
        oneOf             => [ { type => 'object' } ],
        not               => { type => 'string' },
        if                => { type => 'object' },
        then              => { type => 'object' },
    });
    my $pr = $c->_dump_ir->{present};
    ok($pr->{$_}, "present: $_") for qw/
        type minProperties properties patternProperties additionalProperties
        required allOf anyOf oneOf not if
    /;
    is($c->_dump_ir->{addprops_false}, 1, 'additionalProperties:false flagged');
}

# out-of-matrix keyword recorded as unsupported (not silently dropped)
{
    my $c = JSON::Schema::Fast->compile({
        type => 'object',
        unevaluatedProperties => JSON::Schema::Fast->can('compile') ? 0 : 0,
    });
    ok($c->_unsupported >= 1, 'unevaluatedProperties counted as unsupported');
}

# benign annotations are NOT counted as unsupported
{
    my $c = JSON::Schema::Fast->compile({
        type        => 'string',
        title       => 'a name',
        description => 'whatever',
        default     => 'x',
        '$comment'  => 'note',
    });
    is($c->_unsupported, 0, 'annotations are not unsupported');
}

# JSON-text schema input is accepted and decoded
{
    my $c = JSON::Schema::Fast->compile('{"type":"string","minLength":2}');
    my $d = $c->_dump_ir;
    is($d->{type_mask}, T_STR, 'JSON-text schema parsed (type string)');
    ok($d->{present}{minLength}, 'JSON-text schema parsed (minLength)');
}

# boolean schemas
is(JSON::Schema::Fast->compile('true')->_dump_ir->{tag},  1, 'true schema -> TAG_TRUE');
is(JSON::Schema::Fast->compile('false')->_dump_ir->{tag}, 2, 'false schema -> TAG_FALSE');

done_testing;
