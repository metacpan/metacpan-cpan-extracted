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

# coerce never changes the caller's value (Perl may cache a numeric slot on the
# SV via SvNV, which is harmless - the string value is preserved)
{
    my $v = JSON::Schema::Fast->compile({ type => 'integer' }, coerce => 1);
    my $data = "42";
    $v->is_valid($data);
    is($data, "42", 'caller data value unchanged (still the string "42")');
}

done_testing;
