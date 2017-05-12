use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More;

use Fey::SQL::Pg;

my $s = Fey::Test->mock_test_schema();
my $dbh = Fey::Test->mock_dbh();

{
    my $delete = Fey::SQL::Pg->new_delete( auto_placeholders => 0 )->delete;
    $delete->from( $s->table('User') );
    ok(!$delete->returning_clause($dbh), 'has no RETURNING clause by default');
}

{
    my $delete = Fey::SQL::Pg->new_delete( auto_placeholders => 0 );
    $delete->from( $s->table('User') );
    $delete->returning( $s->table('User')->column('user_id'));
    is($delete->returning_clause($dbh), q{RETURNING "User"."user_id"},
       'can set RETURNING clause');
}

{
    my $delete = Fey::SQL::Pg->new_delete( auto_placeholders => 0 );
    $delete->from( $s->table('User') );
    $delete->returning( 'id' );
    is($delete->returning_clause($dbh), q{RETURNING 'id'},
       'can RETURN literal SQL');
}

{
    my $delete = Fey::SQL::Pg->new_delete( auto_placeholders => 0 );
    $delete->from( $s->table('User') );
    $delete->returning( $s->table('User')->column('user_id')->alias('id') );
    is($delete->returning_clause($dbh), q{RETURNING "User"."user_id" AS "id"},
       'can RETURN with column aliases');
}

done_testing;
