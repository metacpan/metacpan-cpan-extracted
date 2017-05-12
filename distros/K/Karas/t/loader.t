use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'DBD::SQLite';
use Karas::Loader;

subtest 'x' => sub {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do(q{CREATE TABLE member (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(255) NOT NULL)});
    my $schema = Karas::Loader->load_schema(
        connect_info => [
            'dbi:PassThrough:', '', '', { pass_through_source => $dbh },
        ],
        namespace => 'MyApp::DB',
    );
    is_deeply($schema, {
        'member' => 'MyApp::DB::Row::Member',
    });
    is_deeply([MyApp::DB::Row::Member->primary_key], ['id']);
    is_deeply([MyApp::DB::Row::Member->table_name], ['member']);
    is_deeply([MyApp::DB::Row::Member->column_names], ['id', 'name']);
};

done_testing;

