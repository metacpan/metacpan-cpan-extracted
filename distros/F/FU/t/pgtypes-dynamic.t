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
like $@, qr/Unable to send or receive/;

{
    my $txn = $conn->txn;

    is $txn->Q('SELECT 1', IN([1,2,3]))->val, 1;

    $txn->exec(<<~_);
        CREATE TYPE fupg_test_enum AS ENUM('a', 'b', 'ccccccccccccccccccc');
        CREATE DOMAIN fupg_test_domain AS fupg_test_enum CHECK(value IN('a','b'));
        CREATE TYPE fupg_test_record AS (
            a int,
            aenum fupg_test_enum[],
            domain fupg_test_domain
        );
    _
    is $txn->q("SELECT 'a'::fupg_test_enum")->val, 'a';
    is $txn->q('SELECT $1::fupg_test_enum', 'ccccccccccccccccccc')->val, 'ccccccccccccccccccc';

    is_deeply $txn->q("SELECT '{a,b,null}'::fupg_test_enum[]")->val, ['a','b',undef];
    is $txn->q('SELECT $1::fupg_test_enum[]', ['a','b',undef])->text_results->val, '{a,b,NULL}';

    is $txn->q("SELECT 'a'::fupg_test_domain")->val, 'a';
    is $txn->q('SELECT $1::fupg_test_domain', 'b')->val, 'b';

    is_deeply $txn->q("SELECT '{a,b,null}'::fupg_test_domain[]")->val, ['a','b',undef];
    is $txn->q('SELECT $1::fupg_test_domain[]', ['a','b',undef])->text_results->val, '{a,b,NULL}';

    my $val = { a => undef, aenum => ['a','b'], domain => 'a' };
    is_deeply $txn->q("SELECT '(,\"{a,b}\",a)'::fupg_test_record")->val, $val;
    is $txn->q('SELECT $1::fupg_test_record', $val)->text_results->val, '(,"{a,b}",a)';

    $txn->exec(<<~_);
        CREATE TEMPORARY TABLE fupg_test_table (
            rec fupg_test_record,
            dom fupg_test_domain
        );
    _

    is_deeply $txn->q(q{SELECT '{"(\"(2,{},b)\",)","(\"(,,)\",b)"}'::fupg_test_table[]})->val, [
        { rec => { a => 2, aenum => [], domain => 'b' }, dom => undef },
        { rec => { a => undef, aenum => undef, domain => undef }, dom => 'b' },
    ];

    is $txn->q('SELECT $1::fupg_test_table[]', [
        { rec => { a => 2, aenum => [], domain => 'b' }, dom => undef },
        { rec => {}, dom => 'b', extra => 1 },
    ])->text_results->val, '{"(\"(2,{},b)\",)","(\"(,,)\",b)"}';
}

done_testing;
