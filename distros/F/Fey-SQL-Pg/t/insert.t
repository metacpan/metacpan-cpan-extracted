use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More;

use Fey::SQL::Pg;

my $s = Fey::Test->mock_test_schema();
my $dbh = Fey::Test->mock_dbh();

{
    my $insert = Fey::SQL::Pg->new_insert( auto_placeholders => 0 )->insert;
    $insert->into( $s->table('User') );
    ok(!$insert->returning_clause($dbh), 'has no RETURNING clause by default');
}

{
    my $insert = Fey::SQL::Pg->new_insert( auto_placeholders => 0 );
    $insert->into( $s->table('User') );
    $insert->returning( $s->table('User')->column('user_id'));
    is($insert->returning_clause($dbh), q{RETURNING "User"."user_id"},
       'can set RETURNING clause');
}

{
    my $insert = Fey::SQL::Pg->new_insert( auto_placeholders => 0 );
    $insert->into( $s->table('User') );
    $insert->returning( 'id' );
    is($insert->returning_clause($dbh), q{RETURNING 'id'},
       'can RETURN literal SQL');
}

{
    my $insert = Fey::SQL::Pg->new_insert( auto_placeholders => 0 );
    $insert->into( $s->table('User') );
    $insert->returning( $s->table('User')->column('user_id')->alias('id') );
    is($insert->returning_clause($dbh), q{RETURNING "User"."user_id" AS "id"},
       'can RETURN with column aliases');
}

done_testing;
