use strict;
use warnings;
use Test::More;
use JSON::Schema::Fast;

use constant { T_INT => 32, H_PROPS => 1 << 20 };

# same-document $ref resolves to the $defs node
{
    my $c = JSON::Schema::Fast->compile({
        '$defs' => { Foo => { type => 'integer' } },
        '$ref'  => '#/$defs/Foo',
    });
    my $d = $c->_dump_ir;
    ok($d->{present}{'$ref'},   'root carries $ref');
    is($d->{ref_resolved}, 1,   '$ref resolved same-document');
    is($d->{ref_target}{type_mask}, T_INT, '$ref points at the integer $defs node');
}

# remote $ref croaks (not a silent no-op)
{
    eval { JSON::Schema::Fast->compile({ '$ref' => 'https://example/x#/a' }) };
    like($@, qr/remote \$ref not supported/, 'remote $ref croaks');
}

# unresolved local $ref croaks, naming the pointer
{
    eval { JSON::Schema::Fast->compile({ '$ref' => '#/$defs/Nope' }) };
    like($@, qr{unresolved \$ref '#/\$defs/Nope'}, 'unresolved local $ref croaks with the pointer');
}

# recursive schema compiles without hanging and resolves the back-reference
{
    my $c = JSON::Schema::Fast->compile({
        '$defs' => {
            Node => {
                type       => 'object',
                properties => { next => { '$ref' => '#/$defs/Node' } },
            },
        },
        '$ref' => '#/$defs/Node',
    });
    my $d = $c->_dump_ir;
    is($d->{ref_resolved}, 1, 'recursive $ref resolved');
    ok($d->{ref_target}{present} & H_PROPS, 'recursive target is the object node');
}

done_testing;
