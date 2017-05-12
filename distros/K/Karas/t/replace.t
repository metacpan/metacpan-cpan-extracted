use strict;
use warnings;
use utf8;
use Test::More;
use DBI;
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

subtest 'sqlite' => sub {
    my $dbh = create_dbh();
    $dbh->do(q{CREATE TABLE member (id INTEGER NOT NULL PRIMARY KEY, email VARCHAR(255) NOT NULL, name VARCHAR(255) NOT NULL, UNIQUE (email))});

    my $db = create_karas($dbh);
    {
        $db->replace(
            member => {
                email => 'foo@example.com',
                name => 'John',
            },
        );
        my ($member) = $db->search('member' => { email => 'foo@example.com' });
        is($member->id, 1);
        is($member->name, 'John');
    }
    {
        $db->replace(
            member => {
                email => 'foo@example.com',
                name => 'Ben',
            },
        );
        my ($member) = $db->search('member' => { email => 'foo@example.com' });
        is($member->id, 2);
        is($member->name, 'Ben');
    }
};

done_testing;

