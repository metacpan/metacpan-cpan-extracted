use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }

# without coerce: JSON types are strict
{
    my $v = JSON::Schema::Fast->compile({ type => 'integer' });
    ok(!$v->is_valid(J('"5"')), 'string "5" is not an integer without coerce');
}

# with coerce: numeric strings satisfy number/integer, and numeric keywords apply
{
    my $v = JSON::Schema::Fast->compile({ type => 'integer', minimum => 10 }, coerce => 1);
    ok(!$v->is_valid(J('"5"')),  'coerced "5" fails minimum 10');
    ok( $v->is_valid(J('"20"')), 'coerced "20" passes minimum 10');
    ok(!$v->is_valid(J('"5.5"')),'coerced "5.5" is not an integer');
}
{
    my $v = JSON::Schema::Fast->compile({ type => 'number' }, coerce => 1);
    ok( $v->is_valid(J('"5.5"')), 'coerced "5.5" is a number');
    ok(!$v->is_valid(J('"abc"')), 'non-numeric string still fails');
}

# boolean coercion
{
    my $v = JSON::Schema::Fast->compile({ type => 'boolean' }, coerce => 1);
    ok( $v->is_valid(J('"true"')),  '"true" coerces to boolean');
    ok( $v->is_valid(J('"false"')), '"false" coerces to boolean');
    ok(!$v->is_valid(J('"1"')),     '"1" does not coerce to boolean');
}

# enum and const compare in the coerced domain: a string standing in for
# a number or a boolean must match a numeric or boolean entry, or a query
# parameter passes `type: integer` and then fails `enum: [0, 1]` on the
# string it still is (found by openapi-served query params, which always
# arrive as strings)
{
    my $v = JSON::Schema::Fast->compile(
        { type => 'integer', enum => [0, 1] }, coerce => 1);
    ok( $v->is_valid(J('"1"')), 'coerced "1" matches enum [0, 1]');
    ok( $v->is_valid(J('"0"')), 'coerced "0" matches enum [0, 1]');
    ok(!$v->is_valid(J('"2"')), 'coerced "2" still fails the enum');
    ok( $v->is_valid(J('1')),   'a native 1 still matches');
}
{
    my $v = JSON::Schema::Fast->compile(
        { type => 'integer', const => 7 }, coerce => 1);
    ok( $v->is_valid(J('"7"')), 'coerced "7" matches const 7');
    ok(!$v->is_valid(J('"8"')), 'coerced "8" does not');
}
{
    # the schema itself decoded from JSON, so the enum entry is a real
    # JSON boolean
    my $v = JSON::Schema::Fast->compile(
        J('{"type":"boolean","enum":[true]}'), coerce => 1);
    ok( $v->is_valid(J('"true"')),  'coerced "true" matches enum [true]');
    ok(!$v->is_valid(J('"false"')), 'coerced "false" does not');
}
{
    # enum entries that are strings still compare as strings
    my $v = JSON::Schema::Fast->compile(
        { type => 'string', enum => [ '1', '2' ] }, coerce => 1);
    ok( $v->is_valid(J('"1"')), 'string enums are untouched');
}
{
    # without coerce the strict comparison stands
    my $v = JSON::Schema::Fast->compile({ type => 'integer', enum => [0, 1] });
    ok(!$v->is_valid(J('"1"')), 'no coerce: "1" still fails enum [0, 1]');
}

# coerce never changes the caller's value (Perl may cache a numeric slot on the
# SV via SvNV, which is harmless - the string value is preserved)
{
    my $v = JSON::Schema::Fast->compile({ type => 'integer' }, coerce => 1);
    my $data = "42";
    $v->is_valid($data);
    is($data, "42", 'caller data value unchanged (still the string "42")');
}

done_testing;
