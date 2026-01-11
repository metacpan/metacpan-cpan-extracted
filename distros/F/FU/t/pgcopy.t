use v5.36;
use Test::More;

plan skip_all => $@ if !eval { require FU::Pg; } && $@ =~ /Unable to load libpq/;
die $@ if $@;
plan skip_all => 'Please set FU_TEST_DB to a PostgreSQL connection string to run these tests' if !$ENV{FU_TEST_DB};

my $conn = FU::Pg->connect($ENV{FU_TEST_DB});
$conn->_debug_trace(0);

ok !eval { $conn->copy('SELECT 1') };
like $@, qr/unexpected status code/;

ok !eval { $conn->copy('COPX') };
like $@, qr/syntax error/;

$conn->exec('CREATE TEMPORARY TABLE fupg_copy_test (v int)');

is $conn->status, 'idle';
{
    my $c = $conn->copy('COPY (SELECT 1) TO STDOUT');
    is $conn->status, 'active';
    $c->close;
}
is $conn->status, 'idle';
$conn->copy('COPY (SELECT 1) TO STDOUT');
is $conn->status, 'idle';

{
    my $c = $conn->copy('COPY fupg_copy_test FROM STDIN');
    is $conn->status, 'active';
    $c->close;
}
is $conn->status, 'idle';
$conn->copy('COPY fupg_copy_test FROM STDIN');
is $conn->status, 'idle';

{
    my $c = $conn->copy('COPY fupg_copy_test FROM STDIN');
    ok !$c->is_binary;
    ok !eval { $c->{read} };
    $c->write("1");
    $c->write("\n2\n3\n");
    $c->close;
    ok !eval { $c->read };
    ok !eval { $c->write('') };
    $c->close;
}
is $conn->status, 'idle';

{
    my $c = $conn->copy('COPY (SELECT * FROM fupg_copy_test ORDER BY v) TO STDOUT');
    ok !$c->is_binary;
    ok !eval { $c->write('') };
    is $c->read, "1\n";
    is $c->read, "2\n";
    is $c->read, "3\n";
    is $c->read, undef;
    $c->close;
    ok !eval { $c->read };
    ok !eval { $c->write('') };
    $c->close;
}
is $conn->status, 'idle';

my $bin = '';
{
    my $c = $conn->copy('COPY fupg_copy_test TO STDOUT (FORMAT binary)');
    ok $c->is_binary;
    while (my $d = $c->read) {
        $bin .= $d;
    }
    $c->close;
}
is $conn->status, 'idle';

{
    my $txn = $conn->txn;
    my $c = $txn->copy('COPY fupg_copy_test FROM STDIN (FORMAT binary)');
    is $txn->status, 'active';
    ok $c->is_binary;
    $c->write($bin);
    $c->close;

    is $txn->sql('SELECT sum(v) FROM fupg_copy_test')->val, 1+1+2+2+3+3;
    $txn->rollback;
}
is $conn->sql('SELECT sum(v) FROM fupg_copy_test')->val, 1+2+3;

done_testing;
