use v5.36;
use Test::More;
no warnings 'experimental::builtin';
use builtin qw/true false is_bool created_as_number/;

plan skip_all => $@ if !eval { require FU::Pg; } && $@ =~ /Unable to load libpq/;
die $@ if $@;
plan skip_all => 'Please set FU_TEST_DB to a PostgreSQL connection string to run these tests' if !$ENV{FU_TEST_DB};

my $conn = FU::Pg->connect($ENV{FU_TEST_DB});
$conn->_debug_trace(0);

# TODO: Test behavior of magic bind params

sub v($type, $p_in, @args) {
    my $p_out = @args > 0 && defined $args[0] ? $args[0] : $p_in;
    my $s_in  = @args > 1 && defined $args[1] ? $args[1] : $p_in;
    my $s_out = @args > 2 && defined $args[2] ? $args[2] : $s_in;

    my $test = "$type $s_in" =~ s/\n/\\n/rg;
    utf8::encode($test);
    {
        my $res = $conn->q("SELECT \$1::$type", $s_in)->text_params->val;
        ok is_bool($res), "$test is bool" if $type eq 'bool';
        ok created_as_number($res), "$test is number" if $type =~ /^(int|float)\d/;
        is_deeply $res, $p_out, "$test text->bin";
    }
    {
        my $res = $conn->q("SELECT \$1::$type", $p_in)->text_results->val;
        is $res, $s_out, "$test bin->text";
    }
    {
        my $res = $conn->q("SELECT \$1::$type", $p_in)->val;
        is_deeply $res, $p_out, "$test bin->bin";
    }
}
sub f($type, $p_in) {
    my $test = "$type $p_in" =~ s/\n/\\n/rg;
    utf8::encode($test);
    ok !eval { $conn->q("SELECT \$1::$type", $p_in)->val; 1 }, "$test fail";
}

ok !defined $conn->q('SELECT pg_sleep(0)')->val; # void

v bool => true,  undef, 1, 't';
v bool => false, undef, 0, 'f';

v int2 => $_ for (1, -1, -32768, 32767, '12345', -12345, 123.0);
f int2 => $_ for (-32769, 32768, [], '', 'a', 1.5);
v int4 => $_ for (1, -1, -2147483648, 2147483647, 1234567890, -1234567890);
f int4 => $_ for (-2147483649, 2147483648, []);
v int8 => $_ for (1, -1, -9223372036854775808, 9223372036854775807, 1234567890123456789, -1234567890123456789, 1e10);
f int8 => $_ for ('aaa', '-9223372036854775809', '9223372036854775808', 1e20);

for my $t (qw/regproc oid xid cid regprocedure regoper regoperator regtype regconfig regdictionary regnamespace regrole regcollation/) {
    # These numbers must not refer to an existing thing in the database, otherwise the text format differs
    v $t, $_ for (1, 12345678, 4294967295);
    f $t, $_ for (-1, 4294967296);
}
v regtype => 17, undef, 'bytea'; # like this

v xid8 => 18446744073709551615;

v bytea => '', undef, '\x';
v bytea => 'hello', undef, '\x68656c6c6f';
v bytea => "\xaf\x90", undef, '\xaf90';
f bytea => "\x{1234}";

v '"char"' => $_ for (1, '1', 'a', 'A', '-');
v '"char"' => "\x84", undef, '\204';
f '"char"' => $_ for ('', 'ab', "\x{1234}");

for my $t (qw/name text bpchar varchar/) {
    v $t, $_ for ('', "\x{1234}", "hello, world");
}
f name => 'a'x64;
# These truncate rather than throw an error on conversion?
v 'char(3)' => 'abcd', 'abc', 'abcd', 'abc';
v 'varchar(3)' => 'abcd', 'abc', 'abcd', 'abc';

# TODO: xml; requires postgres to be built with support for it

v float4 => $_ for (0, 1234, 1.5);
f float4 => $_ for ('', 'a', '123g', []);
v float8 => $_ for (0, 1234, 1.5);
f float8 => $_ for ('', 'a', '123g', []);

# Limitation: There's no way to send a JSON 'null' or differentiate between that and SQL NULL.
v json => {}, undef, '{}';
# XXX: Huh, what's causing this "pretty" formatting?
v json => [1, undef, true, "hello"], undef, qq#[\n   1,\n   null,\n   true,\n   "hello"\n]#;
f json => \2;

v jsonb => {}, undef, '{}';
v jsonb => [1, undef, true, "hello"], undef, '[1, null, true, "hello"]';
f jsonb => \2;

v jsonpath => $_ for ('$."key"', '$."a[*]"?(@ > 2)');
f jsonpath => $_ for ('', 'hello world');

v inet => $_ for ('0.0.0.0', '0.0.0.0/12', '127.0.0.1', '192.168.0.0/16', '2001:4f8:3:ba::/64', '::ffff:1.2.3.0/120', '::');
v cidr => '0.0.0.0', '0.0.0.0/32', undef, '0.0.0.0/32';
v cidr => '::', '::/128', undef, '::/128';
f inet => $_ for ('', [], '0.0.0.0/a', '0.0.0.0/1a', '[::]', '0.0.0.0/33', '::/129', '/1', ':/1');

v uuid => 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
v uuid => '{A0EEBC99-9C0B4EF8BB6D6BB9BD38-0A11}', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '{A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11}', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
f uuid => 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a111';
f uuid => 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a1';
f uuid => 'a0egbc99-9c0b-4ef8-bb6d-6bb9bd380a11';

$conn->exec('SET timezone=utc');
v timestamptz => 0, undef, '1970-01-01 00:00:00+00';
v timestamptz => 1740133814.705915, undef, '2025-02-21 10:30:14.705915+00';
v timestamp => 0, undef, '1970-01-01 00:00:00';
v timestamp => 1740133814.705915, undef, '2025-02-21 10:30:14.705915';

v date => '1970-01-01';
v date => '1999-01-08';
v date => '2025-02-24';
f date => '';
f date => '2025-';
f date => '2025-02-';
f date => '1999-Jan-08';

v 'int[]', [], undef, '{}';
v 'int[]', [1], undef, '{1}';
v 'int[]', [1,-3,undef,3], undef, '{1,-3,NULL,3}';
v 'int[]', [[1],[2],[3]], undef, '{{1},{2},{3}}';
v 'int[]', [[1,-1],[2,-2],[undef,undef],[3,-3]], undef, '{{1,-1},{2,-2},{NULL,NULL},{3,-3}}';
v 'bool[]', [[[[true]]],[[[undef]]]], undef, '{{{{t}}},{{{NULL}}}}';
v 'text[]', ["\x{1234}"], undef, "{\x{1234}}";

f 'int[]', [[1],undef];
f 'int[]', [[1],[2,3]];
f 'int[]', [[]];
f 'oidvector', [undef];

# Example from https://www.postgresql.org/docs/17/arrays.html#ARRAYS-IO
# Lower bounds are discarded.
is_deeply $conn->q("SELECT '[1:1][-2:-1][3:5]={{{1,2,3},{4,5,6}}}'::int[]")->val, [[[1,2,3],[4,5,6]]];

is $conn->q('SELECT ($1::int2[])[2]', [1,2,3,4])->val, 2;
is $conn->q('SELECT ($1::int2vector)[1]', [1,2,3,4])->val, 2;
is $conn->q('SELECT ($1::oidvector)[1]', [1,2,3,4])->val, 2;

done_testing;
