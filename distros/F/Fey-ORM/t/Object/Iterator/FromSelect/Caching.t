use strict;
use warnings;

use Test::More 0.88;

use Fey::Object::Iterator::FromSelect::Caching;

use lib 't/lib';

use Fey::ORM::Test::Iterator;
use Fey::Test;

Fey::ORM::Test::Iterator::run_shared_tests(
    'Fey::Object::Iterator::FromSelect::Caching');

my $dbh    = Fey::Test::SQLite->dbh();
my $schema = Fey::ORM::Test->schema();

{
    my $sql
        = Fey::SQL->new_select->select(
        $schema->table('User')->columns(qw( user_id username email )) )
        ->from( $schema->table('User') )
        ->order_by( $schema->table('User')->column('user_id') );

    my $iterator = Fey::Object::Iterator::FromSelect::Caching->new(
        classes => 'User',
        dbh     => $dbh,
        select  => $sql,
    );

    # Just empty the iterator
    while ( $iterator->next() ) { }

    # This means we can only get results from the cache.
    ## no critic (Variables::ProtectPrivateVars)
    no warnings 'redefine';
    local *Fey::Object::Iterator::FromSelect::_get_next_result = sub { };
    ## use critic

    $iterator->reset();

    my $user = $iterator->next();

    is(
        $iterator->index(), 1,
        'index() is 1 after reset and first row has been fetched'
    );

    is(
        $user->user_id(), 1,
        'user_id = 1'
    );
    is(
        $user->username(), 'autarch',
        'username = autarch'
    );
    is(
        $user->email(), 'autarch@example.com',
        'email = autarch@example.com'
    );

    $user = $iterator->next();

    is(
        $iterator->index(), 2,
        'index() is 2 after second row has been fetched'
    );

    is(
        $user->user_id(), 42,
        'user_id = 42'
    );
    is(
        $user->username(), 'bubba',
        'username = bubba'
    );
    is(
        $user->email(), 'bubba@example.com',
        'email = bubba@example.com'
    );

    $user = $iterator->next();

    is(
        $iterator->index(), 2,
        'index() is 2 after attempt to fetch another row'
    );
    is(
        $user, undef,
        '$user is undef when there are no more objects to fetch'
    );
}

done_testing();
