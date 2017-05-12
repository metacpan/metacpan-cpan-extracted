use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::Literal;

{
    my $dbh = Fey::Test->mock_dbh();

    my $num = Fey::Literal::Number->new(1237);
    is( $num->sql_with_alias($dbh), '1237', 'number sql_with_alias is 1237' );
    is( $num->sql_or_alias($dbh),   '1237', 'number sql_or_alias is 1237' );
    is(
        $num->sql($dbh), '1237',
        'number sql is 1237'
    );

    my $term = Fey::Literal::Term->new('1237.0');
    is(
        $term->sql_or_alias($dbh), '1237.0',
        'term sql_or_alias is 1237.0'
    );
    is(
        $term->sql_with_alias($dbh), '1237.0 AS "TERM0"',
        'term sql_with_alias is 1237.0 AS TERM0'
    );
    is(
        $term->sql_or_alias($dbh), '"TERM0"',
        'term sql_or_alias (after _with_alias) is TERM0'
    );
    is(
        $term->sql($dbh), '1237.0',
        'term sql is 1237.0'
    );

    $term = Fey::Literal::Term->new(q{"Foo"::text});
    is(
        $term->sql_or_alias($dbh),
        q{"Foo"::text}, 'term sql_with_alias is "Foo"::text'
    );
    is(
        $term->sql_or_alias($dbh),
        q{"Foo"::text}, 'term sql_or_alias is "Foo"::text'
    );
    is(
        $term->sql($dbh),
        q{"Foo"::text}, 'term sql is "Foo"::text'
    );

    my $string = Fey::Literal::String->new('Foo');
    is(
        $string->sql_with_alias($dbh), q{'Foo'},
        "string sql_with_alias is 'Foo'"
    );
    is(
        $string->sql_or_alias($dbh), q{'Foo'},
        "string sql_or_alias is 'Foo'"
    );
    is( $string->sql($dbh), q{'Foo'}, "string sql is 'Foo'" );

    $term = Fey::Literal::Term->new( $string, '::text' );
    is(
        $term->sql_or_alias($dbh), q{'Foo'::text},
        "complex term sql_or_alias"
    );
    is(
        $term->sql_with_alias($dbh), q{'Foo'::text AS "TERM1"},
        "complex term sql_with_alias"
    );
    is( $term->sql($dbh), q{'Foo'::text}, "complex term sql" );

    $string = Fey::Literal::String->new("Weren't");
    is(
        $string->sql_or_alias($dbh),
        q{'Weren''t'}, "string formatted is 'Weren''t'"
    );

    my $null = Fey::Literal::Null->new();
    is( $null->sql_with_alias($dbh), 'NULL', 'null sql_with_alias' );
    is( $null->sql_or_alias($dbh),   'NULL', 'null sql_or_alias' );
    is( $null->sql($dbh),            'NULL', 'null sql' );
}

{
    my $s   = Fey::Test->mock_test_schema();
    my $dbh = Fey::Test->mock_dbh();

    my $now = Fey::Literal::Function->new('NOW');
    is(
        $now->sql_with_alias($dbh), q{NOW() AS "FUNCTION0"},
        'NOW function sql_with_alias'
    );
    is(
        $now->sql_with_alias($dbh), q{NOW() AS "FUNCTION0"},
        'NOW function sql_with_alias - second time'
    );
    is(
        $now->sql_or_alias($dbh), q{"FUNCTION0"},
        'NOW function sql_or_alias - with alias'
    );
    is(
        $now->sql($dbh), 'NOW()',
        'NOW function sql - with alias'
    );

    my $now_with_alias
        = Fey::Literal::Function->new('NOW')->alias('rightnow');

    is(
        $now_with_alias->sql_with_alias($dbh), q{NOW() AS "rightnow"},
        'aliased NOW function sql_with_alias'
    );
    is(
        $now_with_alias->sql_with_alias($dbh), q{NOW() AS "rightnow"},
        'aliased NOW function sql_with_alias - second time'
    );
    is(
        $now_with_alias->sql_or_alias($dbh), q{"rightnow"},
        'aliased NOW function sql_or_alias - with alias'
    );
    is(
        $now_with_alias->sql($dbh), 'NOW()',
        'aliased NOW function sql'
    );

    my $now2 = Fey::Literal::Function->new('NOW');
    is(
        $now2->sql_or_alias($dbh), q{NOW()},
        'NOW function sql_or_alias - no alias'
    );
    is(
        $now2->sql($dbh), q{NOW()},
        'NOW function sql - no alias'
    );

    my $avg = Fey::Literal::Function->new(
        'AVG',
        $s->table('User')->column('user_id')
    );

    is(
        $avg->sql_or_alias($dbh), q{AVG("User"."user_id")},
        'AVG function formatted'
    );

    my $substr = Fey::Literal::Function->new(
        'SUBSTR',
        $s->table('User')->column('user_id'),
        5, 2
    );
    is(
        $substr->sql_or_alias($dbh), q{SUBSTR("User"."user_id", 5, 2)},
        'SUBSTR function formatted'
    );

    my $ifnull = Fey::Literal::Function->new(
        'IFNULL',
        $s->table('User')->column('user_id'),
        $s->table('User')->column('username'),
    );
    is(
        $ifnull->sql_or_alias($dbh),
        q{IFNULL("User"."user_id", "User"."username")},
        'IFNULL function formatted'
    );

    my $concat = Fey::Literal::Function->new(
        'CONCAT',
        $s->table('User')->column('user_id'),
        Fey::Literal::String->new(' '),
        $s->table('User')->column('username'),
    );
    is(
        $concat->sql_or_alias($dbh),
        q{CONCAT("User"."user_id", ' ', "User"."username")},
        'CONCAT function formatted'
    );

    my $ifnull2 = Fey::Literal::Function->new(
        'IFNULL',
        $s->table('User')->column('user_id'),
        $concat,
    );
    is(
        $ifnull2->sql_or_alias($dbh),
        q{IFNULL("User"."user_id", CONCAT("User"."user_id", ' ', "User"."username"))},
        'IFNULL(..., CONCAT) function formatted'
    );

    my $avg2 = Fey::Literal::Function->new(
        'AVG',
        $s->table('User')->column('user_id')->alias( alias_name => 'uid' )
    );
    is(
        $avg2->sql_or_alias($dbh), q{AVG("uid")},
        'AVG() with column alias as argument'
    );
}

{
    my $dbh = Fey::Test->mock_dbh();

    my $now = Fey::Literal::Function->new('NOW');
    $now->_make_alias();

    like(
        $now->sql_or_alias($dbh), qr/FUNCTION\d+/,
        'NOW function formatted for compare when it has an alias returns alias'
    );
}

{

    package Str;

    use overload q{""} => sub { ${ $_[0] } };

    sub new {
        my $str = $_[1];
        return bless \$str, __PACKAGE__;
    }
}

{
    my $s   = Fey::Test->mock_test_schema();
    my $dbh = Fey::Test->mock_dbh();

    my $term = Fey::Literal::Term->new(
        'THING ',
        Str->new('OTHER '),
        $s->table('User')->column('user_id'),
    );

    is(
        $term->sql_or_alias($dbh), q{THING OTHER "User"."user_id"},
        'Term does not try to call sql_or_alias on objects which do not have this method'
    );
}

{
    my $dbh = Fey::Test->mock_dbh();

    my $term = Fey::Literal::Term->new('1237.0');
    $term->set_can_have_alias(0);

    is(
        $term->sql_or_alias($dbh), '1237.0',
        'term sql_or_alias is 1237.0'
    );
    is(
        $term->sql_with_alias($dbh), '1237.0',
        'term sql_with_alias is 1237.0'
    );
    is(
        $term->sql_or_alias($dbh), '1237.0',
        'term sql_or_alias (after _with_alias) is 1237.0'
    );
    is(
        $term->sql($dbh), '1237.0',
        'term sql is 1237.0'
    );

    eval { $term->set_alias_name('FOO') };
    like(
        $@, qr/\QThis term cannot have an alias/,
        'set_alias_name dies when can_have_alias is false'
    );
}

done_testing();
