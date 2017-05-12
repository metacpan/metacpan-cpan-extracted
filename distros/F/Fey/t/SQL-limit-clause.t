use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::Literal;
use Fey::SQL;

my $s   = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    eval { $q->limit() };
    like(
        $@, qr/0 parameters/,
        'at least one parameter is required for limit()'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    $q->limit(10);

    is(
        $q->limit_clause($dbh), 'LIMIT 10',
        'simple limit clause'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    $q->limit( 10, 20 );

    is(
        $q->limit_clause($dbh), 'LIMIT 10 OFFSET 20',
        'limit clause with offset'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    $q->limit( undef, 20 );

    is(
        $q->limit_clause($dbh), 'OFFSET 20',
        'limit clause with offset'
    );
}

done_testing();
