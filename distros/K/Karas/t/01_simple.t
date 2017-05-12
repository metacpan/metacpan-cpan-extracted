use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'DBD::SQLite';
use Karas;
use Karas::Loader;

sub create_karas($) {
    my $dbh = shift;
    my $db = Karas::Loader->load(
        connect_info => [
            'dbi:PassThrough:', '', '', {
            pass_through_source => $dbh
        }],
    );
    return $db;
}

sub create_dbh {
    my $dbh = DBI->connect(
        'dbi:SQLite::memory:', '', '', {
        RaiseError => 1,
        PrintError => 0,
    });
    return $dbh;
}

subtest 'update from row object.' => sub {
    my $dbh = create_dbh();
    $dbh->do(q{CREATE TABLE foo (id integer not null primary key, name varchar(255))});

    my $db = create_karas($dbh);
    my $row = $db->insert(foo => {id => 1, name => 'John'});
    is($row->name(), 'John');
    $row->name('Ben');
    is($row->name(), 'Ben');
    $db->update($row);
    my $new = $db->refetch($row);
    is($new->name(), 'Ben');
};

subtest 'count' => sub {
    my $dbh = create_dbh();
    $dbh->do(q{CREATE TABLE foo (id integer not null, name varchar(255))});

    my $db = create_karas($dbh);
    $db->insert(foo => {id => 1, name => 'John'});
    $db->insert(foo => {id => 2, name => 'John'});
    $db->insert(foo => {id => 3, name => 'John'});
    $db->insert(foo => {id => 4, name => 'Ben'});
    is($db->count('foo'), 4);
    is($db->count('foo' => {name => 'John'}), 3);
    is($db->count('foo' => {name => 'Ben'}), 1);
};

done_testing;

