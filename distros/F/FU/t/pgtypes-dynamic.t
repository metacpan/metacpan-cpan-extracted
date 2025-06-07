use v5.36;
use Test::More;
use FU::SQL;

plan skip_all => $@ if !eval { require FU::Pg; } && $@ =~ /Unable to load libpq/;
die $@ if $@;
plan skip_all => 'Please set FU_TEST_DB to a PostgreSQL connection string to run these tests' if !$ENV{FU_TEST_DB};

my $conn = FU::Pg->connect($ENV{FU_TEST_DB});
$conn->_debug_trace(0);


is_deeply $conn->Q('SELECT', 1, '::int')->param_types, [23];
is_deeply $conn->Q('SELECT 1', IN([1,2,3]))->param_types, [1007];
is $conn->Q('SELECT 1', IN([1,2,3]))->val, 1;

ok !eval { $conn->q('SELECT $1::aclitem', '')->exec; 1 };
like $@, qr/Unable to send type/;


subtest 'type overrides', sub {
    $conn->set_type(int4 => recv => 'bytea');
    is $conn->q('SELECT 5::int4')->val, "\0\0\0\5";
    is_deeply $conn->q('SELECT ARRAY[5::int4]')->val, ["\0\0\0\5"];

    $conn->set_type(int4 => send => 'bytea');
    is $conn->q('SELECT $1::int4', "\0\0\0\5")->val, 5;
    is_deeply $conn->q('SELECT $1::int4[]', ["\0\0\0\5"])->val, [5];

    $conn->set_type(int4 => 'int2');
    ok !eval { $conn->q('SELECT 5::int4')->val };
    like $@, qr/Error parsing value/;
    ok !eval { $conn->q('SELECT $1::int4', 5)->val };
    like $@, qr/insufficient data left in message/;

    $conn->set_type(int4 => undef);
    is $conn->q('SELECT 5::int4')->val, 5;

    ok !eval { $conn->set_type(int4 => 1007); };
    like $@, qr/Cannot set a type to array/;

    ok !eval { $conn->set_type(int4 => 1); };
    like $@, qr/No builtin type found/;
};


subtest 'type override callback', sub {
    $conn->set_type(text => recv => sub { length $_[0] });
    is $conn->q('SELECT $1', 'a')->val, 1;
    is $conn->q('SELECT $1', 'ab')->val, 2;
    is $conn->q('SELECT $1', 'abc')->val, 3;
    is $conn->q('SELECT $1', 'abcd')->val, 4;

    $conn->set_type(text => send => sub { 'l'.length $_[0] });
    is $conn->q('SELECT $1', 'a')->val, 'l1';
    is $conn->q('SELECT $1', 'ab')->val, 'l2';
    is $conn->q('SELECT $1', 'abc')->val, 'l3';
    is $conn->q('SELECT $1', 'abcd')->val, 'l4';
};


subtest 'custom types', sub {
    my $txn = $conn->txn;

    is $txn->Q('SELECT 1', IN([1,2,3]))->val, 1;

    $txn->exec(<<~_);
        CREATE TYPE fupg_test_enum AS ENUM('aa', 'bb', 'ccccccccccccccccccc');
        CREATE DOMAIN fupg_test_domain AS fupg_test_enum CHECK(value IN('aa','bb'));
        CREATE TYPE fupg_test_record AS (
            a int,
            aenum fupg_test_enum[],
            domain fupg_test_domain
        );
    _
    is $txn->q("SELECT 'aa'::fupg_test_enum")->val, 'aa';
    is $txn->q('SELECT $1::fupg_test_enum', 'ccccccccccccccccccc')->val, 'ccccccccccccccccccc';

    is_deeply $txn->q("SELECT '{aa,bb,null}'::fupg_test_enum[]")->val, ['aa','bb',undef];
    is $txn->q('SELECT $1::fupg_test_enum[]', ['aa','bb',undef])->text_results->val, '{aa,bb,NULL}';

    is $txn->q("SELECT 'aa'::fupg_test_domain")->val, 'aa';
    is $txn->q('SELECT $1::fupg_test_domain', 'bb')->val, 'bb';

    is_deeply $txn->q("SELECT '{aa,bb,null}'::fupg_test_domain[]")->val, ['aa','bb',undef];
    is $txn->q('SELECT $1::fupg_test_domain[]', ['aa','bb',undef])->text_results->val, '{aa,bb,NULL}';

    my $val = { a => undef, aenum => ['aa','bb'], domain => 'aa' };
    is_deeply $txn->q("SELECT '(,\"{aa,bb}\",aa)'::fupg_test_record")->val, $val;
    is $txn->q('SELECT $1::fupg_test_record', $val)->text_results->val, '(,"{aa,bb}",aa)';

    $txn->exec(<<~_);
        CREATE TEMPORARY TABLE fupg_test_table (
            rec fupg_test_record,
            dom fupg_test_domain
        );
    _

    $val = $txn->q(q{SELECT '{"(\"(2,{},bb)\",)","(\"(,,)\",bb)"}'::fupg_test_table[]})->val;
    is_deeply $val, [
        { rec => { a => 2, aenum => [], domain => 'bb' }, dom => undef },
        { rec => { a => undef, aenum => undef, domain => undef }, dom => 'bb' },
    ];
    $val->[0] = 0;
    $val->[1]{rec}{a} = 0;
    $val->[1]{rec} = 0;
    $val->[1]{dom} = 0;

    is $txn->q('SELECT $1::fupg_test_table[]', [
        { rec => { a => 2, aenum => [], domain => 'bb' }, dom => undef },
        { rec => {}, dom => 'bb', extra => 1 },
    ])->text_results->val, '{"(\"(2,{},bb)\",)","(\"(,,)\",bb)"}';

    # Wonky Postgres behavior: selecting a domain directly actually returns the
    # underlying type, but going through an array does work.
    $conn->set_type(fupg_test_domain => 21);
    is_deeply $txn->q("SELECT ARRAY['aa'::fupg_test_domain]")->val, [0x6161];

    # Bind param type doesn't match column type, argh.
    is $txn->q('SELECT $1::fupg_test_domain', 0x6161)->val, 'aa';

    # Same for selecting from a table :(
    $txn->exec("INSERT INTO fupg_test_table VALUES (NULL, 'bb')");
    is $txn->q("SELECT dom FROM fupg_test_table")->val, 'bb';
    $conn->set_type(fupg_test_enum => 21);
    is $txn->q("SELECT dom FROM fupg_test_table")->val, 0x6262;
};


subtest 'identifier quoting', sub {
    my $txn = $conn->txn;
    $txn->exec('CREATE TEMPORARY TABLE fupg_test_tbl ("desc" int, ok int, "hello world" int)');
    ok $txn->Q('INSERT INTO fupg_test_tbl', VALUES {desc => 5, ok => 10, 'hello world', 15})->exec;
    is $txn->Q('SELECT', IDENT 'hello world', 'FROM fupg_test_tbl')->val, 15;
};


subtest 'vndbid', sub {
    plan skip_all => 'type not loaded in the database' if !$conn->q("SELECT 1 FROM pg_type WHERE typname = 'vndbtag'")->val;

    for my $t (qw/a zz xxx/) {
        is $conn->q('SELECT $1::vndbtag', $t)->val, $t;
        is $conn->q('SELECT $1::vndbtag', $t)->text_params->val, $t;
        is $conn->q('SELECT $1::vndbtag', $t)->text_results->val, $t;
    }
    ok !eval { $conn->q('SELECT $1::vndbtag', '')->val };
    ok !eval { $conn->q('SELECT $1::vndbtag', 'abcd')->val };

    for my $t (qw/a123 zz992883231 xxx18388123/) {
        is $conn->q('SELECT $1::vndbid', $t)->val, $t;
        is $conn->q('SELECT $1::vndbid', $t)->text_params->val, $t;
        is $conn->q('SELECT $1::vndbid', $t)->text_results->val, $t;
    }
    ok !eval { $conn->q('SELECT $1::vndbid', '')->val };
    ok !eval { $conn->q('SELECT $1::vndbid', 'ab')->val };
    ok !eval { $conn->q('SELECT $1::vndbid', 'ab1219229999999999')->val };
};

done_testing;
