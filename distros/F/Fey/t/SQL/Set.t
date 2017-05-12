use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::SQL;

my $s   = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();

for my $keyword (qw( UNION INTERSECT EXCEPT )) {
    my $new_method = "new_" . lc $keyword;
    my $method     = lc $keyword;

    {
        my $set_op = Fey::SQL->$new_method();

        eval { $set_op->$method() };
        like(
            $@, qr/0 parameters were passed .+ but 2 were expected/,
            "$method() without any parameters is an error"
        );

        eval { $set_op->$method( Fey::SQL->new_select ) };
        like(
            $@, qr/1 parameter .+ but 2 were expected/,
            "$method() with only one parameter is an error"
        );

    TODO: {
            local $TODO
                = 'MooseX::Params::Validate gets the method name wrong';
            eval { $set_op->$method() };
            like(
                $@, qr/0 parameters were passed to .+::$method/,
                "$method() error message has correct method name"
            );
        }
    }

    {
        my $set_op = Fey::SQL->$new_method();

        eval { $set_op->$method( 1, 2 ) };
        like(
            $@,
            qr/SetOperationArg' with value 1/,
            "$method() with a non-Select parameter is an error",
        );
    }

    {
        my $set_op = Fey::SQL->$new_method();

        my $sel1 = Fey::SQL->new_select->select(1)->from( $s->table('User') );
        my $sel2 = Fey::SQL->new_select->select(2)->from( $s->table('User') );

        $set_op->$method( $sel1, $sel2 );

        my $sql = qq{(SELECT 1 FROM "User") $keyword (SELECT 2 FROM "User")};
        is( $set_op->sql($dbh), $sql, "$method() with two tables" );

        my $sel3 = Fey::SQL->new_select->select(1)->from($set_op);
        $sql = qq{SELECT 1 FROM ( $sql ) AS "${keyword}0"};
        is( $sel3->sql($dbh), $sql, "$method() as subselect" );
    }

    {
        my $set_op = Fey::SQL->$new_method()->all();

        my $sel1 = Fey::SQL->new_select->select(1)->from( $s->table('User') );
        my $sel2 = Fey::SQL->new_select->select(2)->from( $s->table('User') );

        $set_op->$method( $sel1, $sel2 );

        my $sql = qq{(SELECT 1 FROM "User") };
        $sql .= qq{$keyword ALL (SELECT 2 FROM "User")};
        is( $set_op->sql($dbh), $sql, "$method()->all() with two tables" );

        my $sel3 = Fey::SQL->new_select->select(3)->from( $s->table('User') );

        eval { $set_op->$method($sel3) };
        is $@, '', 'no error from adding a single select when 2 are present';
    }

    {
        my $set_op = Fey::SQL->$new_method();

        my $user = $s->table('User');

        my $sel1 = Fey::SQL->new_select();
        $sel1->select( $user->column('user_id') )->from($user);

        my $sel2 = Fey::SQL->new_select();
        $sel2->select( $user->column('user_id') )->from($user);

        $set_op->$method( $sel1, $sel2 )
            ->order_by( $user->column('user_id') );

        my $sql = q{(SELECT "User"."user_id" FROM "User")};
        $sql = "$sql $keyword $sql";
        $sql .= q{ ORDER BY "User"."user_id"};

        is( $set_op->sql($dbh), $sql, "$method() with order by" );
    }

    {
        my $set_op = Fey::SQL->$new_method();

        my $sel1 = Fey::SQL->new_select->select(1)->from( $s->table('User') );
        my $sel2 = Fey::SQL->new_select->select(2)->from( $s->table('User') );
        my $sel3 = Fey::SQL->new_select->select(3)->from( $s->table('User') );

        $set_op->$method(
            $sel1,
            Fey::SQL->$new_method->$method( $sel2, $sel3 )
        );

        my $from = qq{FROM "User"};
        my $sql  = qq{(SELECT 1 $from) $keyword };
        $sql .= qq{((SELECT 2 $from) $keyword (SELECT 3 $from))};
        is( $set_op->sql($dbh), $sql, "$method() with sub-$method" );
    }

    {
        my $set_op1 = Fey::SQL->$new_method();

        my $sel1 = Fey::SQL->new_select->select(1)->from( $s->table('User') );
        my $sel2 = Fey::SQL->new_select->select(2)->from( $s->table('User') );
        my $sel3 = Fey::SQL->new_select->select(3)->from( $s->table('User') );

        $set_op1->$method( $sel1, $sel2 );

        my $set_op2 = $set_op1->clone();
        $set_op2->$method($sel3);

        is(
            $set_op1->sql($dbh),
            qq{(SELECT 1 FROM "User") $keyword (SELECT 2 FROM "User")},
            "original $method has two selects"
        );

        is(
            $set_op2->sql($dbh),
            qq{(SELECT 1 FROM "User") $keyword (SELECT 2 FROM "User") $keyword (SELECT 3 FROM "User")},
            "cloned $method has three selects"
        );
    }
}

done_testing();
