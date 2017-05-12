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
    my $q = Fey::SQL->new_select();

    eval { $q->group_by() };
    like(
        $@, qr/0 parameters/,
        'at least one parameter is required for group_by()'
    );
}

{
    my $q = Fey::SQL->new_select();

    $q->group_by( $s->table('User')->column('user_id') );
    is(
        $q->group_by_clause($dbh), q{GROUP BY "User"."user_id"},
        'group_by() one column'
    );
}

{
    my $q = Fey::SQL->new_select();

    $q->group_by(
        $s->table('User')->column('user_id'),
        $s->table('User')->column('username')
    );
    is(
        $q->group_by_clause($dbh),
        q{GROUP BY "User"."user_id", "User"."username"},
        'group_by() two columns'
    );
}

{
    my $q = Fey::SQL->new_select();

    $q->group_by( $s->table('User')->column('user_id')
            ->alias( alias_name => 'alias_test' ) );

    is(
        $q->group_by_clause($dbh), q{GROUP BY "alias_test"},
        'group_by() column alias'
    );
}

{
    my $q = Fey::SQL->new_select();

    my $now = Fey::Literal::Function->new('NOW');
    $now->_make_alias();

    $q->group_by($now);

    like(
        $q->group_by_clause($dbh), qr/GROUP BY "FUNCTION\d+"/,
        'group_by() function'
    );
}

{
    my $q = Fey::SQL->new_select();

    my $now = Fey::Literal::Function->new('NOW');

    eval { $q->group_by($now) };
    like(
        $@, qr/\QParameter #1/,
        'cannot group by function with no alias'
    );
}

{
    my $q = Fey::SQL->new_select();

    my $term = Fey::Literal::Term->new(q{"Foo"::text});
    $q->group_by($term);

    is(
        $q->group_by_clause($dbh), q{GROUP BY "Foo"::text},
        'group_by() term'
    );
}

done_testing();
