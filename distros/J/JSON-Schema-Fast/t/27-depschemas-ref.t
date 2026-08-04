use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }
sub V { JSON::Schema::Fast->compile($_[0]) }

# dependentSchemas: when the trigger property is present, its subschema must
# validate against the whole object.
{
    my $v = V({
        type => 'object',
        dependentSchemas => {
            credit_card => { required => ['billing_address'] },
        },
    });
    ok( $v->is_valid(J('{"name":"a"}')),                       'no trigger -> inactive');
    ok( $v->is_valid(J('{"credit_card":1,"billing_address":"x"}')), 'trigger + requirement met');
    ok(!$v->is_valid(J('{"credit_card":1}')),                 'trigger without requirement fails');
}

# $ref pointers are percent-decoded then JSON-Pointer unescaped, matching the
# $defs key.
{
    my $v = V({
        '$defs' => { 'pct%field' => { type => 'integer' } },
        '$ref'  => '#/$defs/pct%25field',
    });
    ok( $v->is_valid(J('5')),   'percent-encoded $ref resolves');
    ok(!$v->is_valid(J('"x"')), 'and enforces the target schema');
}
{
    my $v = V({
        '$defs' => { 'a/b' => { type => 'string' } },
        '$ref'  => '#/$defs/a~1b',           # ~1 -> '/'
    });
    ok( $v->is_valid(J('"x"')), 'tilde-escaped $ref resolves');
    ok(!$v->is_valid(J('5')),   'and enforces the target schema');
}

done_testing;
