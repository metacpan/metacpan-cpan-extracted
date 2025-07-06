use v5.36;
use Test::More;
no warnings 'experimental::builtin';
use builtin qw/true false is_bool created_as_number/;
use Config;

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
    my $oid;
    utf8::encode($test);
    {
        my $st = $conn->q("SELECT \$1::$type", $s_in)->text_params;
        $oid = $st->param_types->[0];
        my $array = $st->flat;
        my $res = $array->[0];
        ok is_bool($res), "$test is bool" if $type eq 'bool';
        ok created_as_number($res), "$test is number" if $type =~ /^(int|float)\d/;
        is_deeply $res, $p_out, "$test text->bin";
        $array->[0] = 0; # Must be writable
    }
    {
        my $res = $conn->q("SELECT \$1::$type", $p_in)->text_results->val;
        is $res, $s_out, "$test bin->text";
    }
    {
        my $res = $conn->q("SELECT \$1::$type", $p_in)->val;
        is_deeply $res, $p_out, "$test bin->bin";
    }
    {
        my $bin = $conn->perl2bin($oid, $p_in);
        ok defined $bin;
        if ($type !~ /\(/) {
            is_deeply $conn->bin2perl($oid, $bin), $p_out;
            is $conn->bin2text($oid, $bin), $s_out;
            is $conn->text2bin($oid, $s_out), $bin if $type ne 'jsonb'; # jsonb pretty-prints for some reason
        }
    }
}
sub f($type, $p_in) {
    my $test = "$type $p_in" =~ s/\n/\\n/rg;
    utf8::encode($test);
    ok !eval { $conn->q("SELECT \$1::$type", $p_in)->val; 1 }, "$test fail";
}

{ # void
    my $array = $conn->q('SELECT pg_sleep(0)')->flat;
    ok !defined $array->[0];
    $array->[0] = 0;
}

v bool => true,  true, 1, 't';
v bool => \1,    true, 1, 't';
v bool => 1,     true, 1, 't';
v bool => 't',   true, 1, 't';
v bool => false, false, 0, 'f';
v bool => \0,    false, 0, 'f';
v bool => 0,     false, 0, 'f';
v bool => '',    false, 0, 'f';
v bool => 'f',   false, 0, 'f';
f bool => 2;
f bool => [];

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

$conn->set_type(bytea => '$hex');
v bytea => '', undef, '\x';
v bytea => '68656c6c6f', undef, '\x68656c6c6f';
v bytea => "af90", undef, '\xaf90';
f bytea => 'a';
f bytea => 'a f';

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

v date => 0, undef, '1970-01-01';
v date => 915753600, undef, '1999-01-08';
v date => 1740355200, undef, '2025-02-24';
f date => '';
f date => '1970-01-01';

$conn->set_type(date => '$date_str');
v date => '1970-01-01';
v date => '1999-01-08';
v date => '2025-02-24';
f date => '';
f date => '2025-';
f date => '2025-02-';
f date => '1999-Jan-08';

v time => 0, undef, '00:00:00';
v time => 60.123456, undef, '00:01:00.123456';
v time => 3600 * 13 + 43 * 60 + 19 + 0.987654, undef, '13:43:19.987654';
f time => '';
f time => -1;
f time => 86400.1;

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

is_deeply [$conn->bin2text(
    16, $conn->perl2bin(16, 1),
    25, 'Hello',
    1007, $conn->perl2bin(1007, [-3,1,undef])
)], ['t', 'Hello', '{-3,1,NULL}'];

{
    my($b,$s,$a) = $conn->text2bin(16, 't', 25, 'Hello', 1007, '{-3,1,NULL}');
    is $conn->bin2perl(16, $b), 1;
    is $conn->bin2perl(25, $s), 'Hello';
    is_deeply $conn->bin2perl(1007, $a), [-3,1,undef];
}

{
    my $v = $conn->q("SELECT '{t,f,NULL}'::bool[]")->val;
    is_deeply $v, [true, false, undef];
    $_ = 0 for @$v;
}

done_testing;
