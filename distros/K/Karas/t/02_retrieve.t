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

subtest 'run' => sub {
    my $dbh = create_dbh();
    $dbh->do(q{CREATE TABLE member (id INTEGER PRIMARY KEY, name)});

    my $db = create_karas($dbh);
    $db->insert(member => {id => 1, name => 'John'});
    $db->insert(member => {id => 2, name => 'Ben'});
    $db->insert(member => {id => 3, name => 'Dan'});
    is($db->retrieve('member' => 2)->name, 'Ben');
};

subtest 'multi pk' => sub {
    my $dbh = create_dbh();
    $dbh->do(q{CREATE TABLE tag_entry (tag_id, entry_id, updated_at, PRIMARY KEY (tag_id, entry_id))});

    my $db = create_karas($dbh);
    $db->insert(tag_entry => {tag_id => 3, entry_id => 4, updated_at => 555});
    $db->insert(tag_entry => {tag_id => 4, entry_id => 5, updated_at => 556});
    $db->insert(tag_entry => {tag_id => 5, entry_id => 6, updated_at => 557});
    is($db->retrieve('tag_entry', {tag_id => 3, entry_id => 4})->updated_at, '555');
    is($db->retrieve('tag_entry', {tag_id => 4, entry_id => 5})->updated_at, '556');
    is($db->retrieve('tag_entry', {tag_id => 5, entry_id => 6})->updated_at, '557');
};

done_testing;

