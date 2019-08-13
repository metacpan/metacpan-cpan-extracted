use Test::More;

use DBI;
use strict;
use FindBin;
use Geoffrey;
use warnings;
use File::Spec;
use Data::Dumper;
use Test::Exception;

require_ok('FindBin');
use_ok 'FindBin';

eval "use File::Temp qw/ tempdir /";
plan skip_all => "File::Temp required" if $@;

require_ok('Geoffrey::Converter::SQLite');
use_ok 'Geoffrey::Converter::SQLite';

my $converter = Geoffrey::Converter::SQLite->new();

my $dbh = DBI->connect("dbi:SQLite:database=.tmp.sqlite");
my $object = new_ok('Geoffrey' => [dbh => $dbh]) or plan skip_all => "";

$object->writer->inc_changelog_count;

throws_ok { $object->writer->sequences('main'); }
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Drop non existing index';

my $tables = [{
        author  => 'Mario Zieschang',
        entries => [{name => 'geoffrey_changelogs', action => 'table.add',}],
        id      => '1-1-maz'
    },
    {author => 'Mario Zieschang', entries => [{name => 'client', action => 'table.add',}], id => '1-2-maz'},
    {
        author  => 'Mario Zieschang',
        entries => [{name => 'sqlite_sequence', action => 'table.add',}],
        id      => '1-3-maz'
    },
    {author => 'Mario Zieschang', entries => [{name => 'company', action => 'table.add',}], id => '1-4-maz'},
    {author => 'Mario Zieschang', entries => [{name => 'user',    action => 'table.add',}], id => '1-5-maz'},
    {author => 'Mario Zieschang', entries => [{name => 'player',  action => 'table.add',}], id => '1-6-maz'},
    {author => 'Mario Zieschang', entries => [{name => 'team',    action => 'table.add',}], id => '1-7-maz'},
    {
        author  => 'Mario Zieschang',
        entries => [{name => 'match_player', action => 'table.add',}],
        id      => '1-8-maz'
    },
    {
        author  => 'Mario Zieschang',
        entries => [{name => 'match_team', action => 'table.add',}],
        id      => '1-9-maz',
    }

];

is(
    Data::Dumper->new($object->writer->tables('main'))->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new($tables)->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'List sequence test'
);

$tables = [

    {
        'author'  => 'Mario Zieschang',
        'entries' => [{
                'columns' => [
                    {'length' => 128, 'name' => 'author',   'not_null' => 'NOT NULL', 'type' => 'VARCHAR'},
                    {'length' => 255, 'name' => 'filename', 'not_null' => 'NOT NULL', 'type' => 'VARCHAR'},
                    {'name'   => 'flag', 'not_null' => 'NOT NULL',      type => 'DATETIME'},
                    {'length' => 32,     'name'     => 'orderexecuted', type => 'VARCHAR'},
                    {'length' => 64, 'name' => 'md5sum', 'not_null' => 'NOT NULL', 'type' => 'VARCHAR'},
                    {'length' => 255, name => 'description', type => 'VARCHAR'},
                    {'length' => 128, name => 'comment',     type => 'VARCHAR'},
                    {
                        'length'   => 16,
                        'name'     => 'changelog_table',
                        'not_null' => 'NOT NULL',
                        'type'     => 'VARCHAR'
                    }
                ],
                name   => 'geoffrey_changelogs',
                action => 'table.add',
            }
        ],
        'id' => $object->writer->changelog_count . '-1-maz'
    },
    {
        'author'  => 'Mario Zieschang',
        'entries' => [{
                'columns' => [{
                        'name'        => 'id',
                        'not_null'    => 'NOT NULL',
                        'primary_key' => 'PRIMARY KEY',
                        'type'        => 'INTEGER'
                    },
                    {name => 'active', 'type'     => 'BOOL'},
                    {name => 'name',   'not_null' => 'NOT NULL', type => 'VARCHAR'},
                    {name => 'flag',   'not_null' => 'NOT NULL', type => 'DATETIME'}
                ],
                name   => 'client',
                action => 'table.add',
            }
        ],
        'id' => $object->writer->changelog_count . '-2-maz'
    },
    {
        'author'  => 'Mario Zieschang',
        'entries' => [{'columns' => [], name => 'sqlite_sequence', action => 'table.add',}],
        'id'      => $object->writer->changelog_count . '-3-maz'
    },
    {
        'author'  => 'Mario Zieschang',
        'entries' => [{
                'columns' => [{
                        'name'        => 'id',
                        'not_null'    => 'NOT NULL',
                        'primary_key' => 'PRIMARY KEY',
                        'type'        => 'INTEGER'
                    },
                    {name => 'active', 'type'     => 'BOOL'},
                    {name => 'name',   'not_null' => 'NOT NULL', type => 'VARCHAR'},
                    {name => 'flag',   'not_null' => 'NOT NULL', type => 'DATETIME'},
                    {name => 'client', 'not_null' => 'NOT NULL', type => 'INTEGER'}
                ],
                name   => 'company',
                action => 'table.add',
            }
        ],
        'id' => $object->writer->changelog_count . '-4-maz'
    },
    {
        'author'  => 'Mario Zieschang',
        'entries' => [{
                'columns' => [{
                        'name'        => 'id',
                        'not_null'    => 'NOT NULL',
                        'primary_key' => 'PRIMARY KEY',
                        'type'        => 'INTEGER'
                    },
                    {name => 'active', 'type'     => 'BOOL'},
                    {name => 'name',   'not_null' => 'NOT NULL', type => 'VARCHAR'},
                    {name => 'flag',   'not_null' => 'NOT NULL', type => 'DATETIME'},
                    {name => 'client', 'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {'length' => 255, 'name' => 'mail', 'not_null' => 'NOT NULL', 'type' => 'VARCHAR'},
                    {name => 'last_login', type => 'DATETIME'},
                    {name => 'locale',     type => 'CHAR'},
                    {'length' => 255, 'name' => 'salt', 'not_null' => 'NOT NULL', 'type' => 'VARCHAR'},
                    {'length' => 255, 'name' => 'pass', 'not_null' => 'NOT NULL', 'type' => 'VARCHAR'}
                ],
                name   => 'user',
                action => 'table.add',
            }
        ],
        'id' => $object->writer->changelog_count . '-5-maz'
    },
    {
        'author'  => 'Mario Zieschang',
        'entries' => [{
                'columns' => [{
                        'name'        => 'id',
                        'not_null'    => 'NOT NULL',
                        'primary_key' => 'PRIMARY KEY',
                        'type'        => 'INTEGER'
                    },
                    {name => 'active',  'type'     => 'BOOL'},
                    {name => 'name',    'not_null' => 'NOT NULL', type => 'VARCHAR'},
                    {name => 'flag',    'not_null' => 'NOT NULL', type => 'DATETIME'},
                    {name => 'client',  'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'company', 'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {'length' => 255, 'name' => 'surname', 'not_null' => 'NOT NULL', 'type' => 'VARCHAR'}
                ],
                name   => 'player',
                action => 'table.add',
            }
        ],
        'id' => $object->writer->changelog_count . '-6-maz'
    },
    {
        'author'  => 'Mario Zieschang',
        'entries' => [{
                'columns' => [{
                        'name'        => 'id',
                        'not_null'    => 'NOT NULL',
                        'primary_key' => 'PRIMARY KEY',
                        'type'        => 'INTEGER'
                    },
                    {name => 'active',  'type'     => 'BOOL'},
                    {name => 'name',    'not_null' => 'NOT NULL', type => 'VARCHAR'},
                    {name => 'flag',    'not_null' => 'NOT NULL', type => 'DATETIME'},
                    {name => 'client',  'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'company', 'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'player1', 'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'player2', 'not_null' => 'NOT NULL', type => 'INTEGER'}
                ],
                name   => 'team',
                action => 'table.add',
            }
        ],
        'id' => $object->writer->changelog_count . '-7-maz'
    },
    {
        'author'  => 'Mario Zieschang',
        'entries' => [{
                'columns' => [{
                        'name'        => 'id',
                        'not_null'    => 'NOT NULL',
                        'primary_key' => 'PRIMARY KEY',
                        'type'        => 'INTEGER'
                    },
                    {name => 'active',      'type'     => 'BOOL'},
                    {name => 'name',        'not_null' => 'NOT NULL', type => 'VARCHAR'},
                    {name => 'flag',        'not_null' => 'NOT NULL', type => 'DATETIME'},
                    {name => 'client',      'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'company',     'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'player1',     'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'player2',     'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'player1_ht1', 'type'     => 'INTEGER'},
                    {name => 'player1_ht2', 'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'player2_ht1', 'type'     => 'INTEGER'},
                    {name => 'player2_ht2', 'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'duration',    'type'     => 'INTEGER'}
                ],
                name   => 'match_player',
                action => 'table.add',
            }
        ],
        'id' => $object->writer->changelog_count . '-8-maz'
    },
    {
        'author'  => 'Mario Zieschang',
        'entries' => [{
                'columns' => [{
                        'name'        => 'id',
                        'not_null'    => 'NOT NULL',
                        'primary_key' => 'PRIMARY KEY',
                        'type'        => 'INTEGER'
                    },
                    {name => 'active',    'type'     => 'BOOL'},
                    {name => 'name',      'not_null' => 'NOT NULL', type => 'VARCHAR'},
                    {name => 'flag',      'not_null' => 'NOT NULL', type => 'DATETIME'},
                    {name => 'client',    'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'company',   'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'team1',     'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'team2',     'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'team1_ht1', 'type'     => 'INTEGER'},
                    {name => 'team1_ht2', 'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'team2_ht1', 'type'     => 'INTEGER'},
                    {name => 'team2_ht2', 'not_null' => 'NOT NULL', type => 'INTEGER'},
                    {name => 'duration',  'type'     => 'INTEGER'}
                ],
                name   => 'match_team',
                action => 'table.add',
            }
        ],
        'id' => $object->writer->changelog_count . '-9-maz'
    }

];

$tables = ();
my $primary_keys = [];
$object->writer->inc_changelog_count;
throws_ok { $object->writer->primaries('main'); }
'Geoffrey::Exception::NotSupportedException::ConverterType', 'List primary keys not supported';
$object->writer->inc_changelog_count;
throws_ok { $object->writer->uniques('main'); }
'Geoffrey::Exception::NotSupportedException::ConverterType', 'List uniques not supported';
$object->writer->inc_changelog_count;
throws_ok { $object->writer->foreigns('main'); }
'Geoffrey::Exception::NotSupportedException::ConverterType', 'List foreign keys not supported';

$object->writer->inc_changelog_count;
is(
    Data::Dumper->new($object->writer->indexes('main', 1))->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)
        ->Dump,
    Data::Dumper->new([{
                'author'  => 'Mario Zieschang',
                'entries' => [{'columns' => ['id'], name => 'index_test', 'table' => 'match_team'}],
                'id'      => $object->writer->changelog_count . '-1-maz'
            }]
    )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'List sequence test'
);

$object->writer->inc_changelog_count;
is(
    Data::Dumper->new($object->writer->views('main', 1))->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new([{
                'author'  => 'Mario Zieschang',
                'entries' => [{
                        name => 'view_client',
                        'sql' =>
                            'CREATE VIEW view_client AS SELECT "user".guest, "user".pass, "user".salt, "user".locale, "user".last_login, "user".mail, "user".client, "user".flag, "user".active, "user".name, company.name AS company, client.id FROM client, company, "user" WHERE client.id = company.id AND company.id = "user".id AND "user".id = client.id'
                    }
                ],
                'id' => $object->writer->changelog_count . '-1-maz'
            }]
    )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'List sequence test'
);
$object->writer->inc_changelog_count;
throws_ok { $object->writer->functions('main'); }
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Throw list functions';

$object->writer->inc_changelog_count;
throws_ok { $object->writer->triggers('main'); }
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Throw list triggers';

SKIP: {
    eval "use File::Tempdir";
    skip 'File::Tempdir needed', 2 if $@;
    my $tmpdir = File::Tempdir->new()->name;
    ok($object->writer->run($tmpdir, 'main', 1), 'List sequence test');
    ok($object->write($tmpdir, 'main', 1), 'List sequence test');
}

done_testing();