#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 27;
use Test::Exception;

use Fey;
use Fey::DBIManager;

BEGIN {
    use_ok('FeyX::Active::Schema');
    use_ok('FeyX::Active::Table');
}

unlink 'test_db' if -e 'test_db';

my $schema = FeyX::Active::Schema->new( name => 'Testing' );
isa_ok($schema, 'FeyX::Active::Schema');
isa_ok($schema, 'Fey::Schema');

isa_ok($schema->dbi_manager, 'Fey::DBIManager');

lives_ok {
    $schema->dbi_manager->add_source( dsn => 'dbi:SQLite:dbname=test_db' );
} '... created the new source okay';

isa_ok($schema->dbi_manager->default_source, 'Fey::DBIManager::Source');

my $dbh = $schema->dbi_manager->default_source->dbh;
isa_ok($dbh, 'DBI::db');

$dbh->do(q[
    CREATE TABLE Person (
        first_name varchar,
        last_name varchar
    );
]);

# ...

my $Person = FeyX::Active::Table->new(name => 'Person');
isa_ok($Person, 'FeyX::Active::Table');
isa_ok($Person, 'Fey::Table');

$Person->add_column( Fey::Column->new( name => 'first_name', type => 'varchar' ) );
$Person->add_column( Fey::Column->new( name => 'last_name',  type => 'varchar' ) );

$schema->add_table($Person);

my @people = (
    {
        first_name  => 'Homer',
        last_name   => 'Simpson',
    },
    {
        first_name  => 'Marge',
        last_name   => 'Simpson',
    },
    {
        first_name  => 'Bart',
        last_name   => 'Simpson',
    }
);

foreach my $person (@people) {
    my $insert = $Person->insert( %$person );
    isa_ok($insert, 'FeyX::Active::SQL::Insert');
    $insert->execute;
    # This API makes for some odd code, ex:
    #
    #   $Person->insert( %$person )->execute
    #
}

# +-----------------------------+
# | first_name   | last_name    |
# +-----------------------------+
# | Homer       | Simpson       |
# +-----------------------------+
# | Marge       | Simpson       |
# +-----------------------------+
# | Bart        | Simpson       |
# +-----------------------------+


{
    my $select = $Person->select;
    isa_ok($select, 'FeyX::Active::SQL::Select');
    {
        my $sth = $select->execute;

        is_deeply(
            $sth->fetchall_arrayref,
            [
                [ 'Homer', 'Simpson' ],
                [ 'Marge', 'Simpson' ],
                [ 'Bart', 'Simpson'  ],
            ],
            '... got the right values'
        );
    }

    $select->where( $Person->column('first_name'), '==', 'Homer');
    {
        my $sth = $select->execute;
        {
            my ($first_name, $last_name) = $sth->fetchrow;
            is($first_name, 'Homer', '... got the right value');
            is($last_name, 'Simpson', '... got the right value');
        }
    }
}

{

    my $select = $Person->select( $Person->column('last_name') )
                        ->where( $Person->column('first_name'), '==', 'Homer');
    isa_ok($select, 'FeyX::Active::SQL::Select');
    {
        my $sth = $select->execute;
        {
            my ($last_name) = $sth->fetchrow;
            is($last_name, 'Simpson', '... got the right value');
        }
    }

}

{
    my $delete = $Person->delete->where( $Person->column('first_name'), '==', 'Homer');
    isa_ok($delete, 'FeyX::Active::SQL::Delete');
    {
        my $sth = $delete->execute;
    }

    # +-----------------------------+
    # | first_name   | last_name    |
    # +-----------------------------+
    # | Marge        | Simpson      |
    # +-----------------------------+
    # | Bart         | Simpson      |
    # +-----------------------------+

    my $select = $Person->select;
    isa_ok($select, 'FeyX::Active::SQL::Select');
    {
        my $sth = $select->execute;

        is_deeply(
            $sth->fetchall_arrayref,
            [
                [ 'Marge', 'Simpson' ],
                [ 'Bart', 'Simpson'  ],
            ],
            '... got the right values'
        );
    }

    $select->where( $Person->column('first_name'), '==', 'Homer');
    {
        my $sth = $select->execute;
        {
            ok(!$sth->fetchrow, '... nothing no row amymore');
        }
    }
}


{
     my $update = $Person->update(
         $Person->column('first_name') => 'Homer',
         $Person->column('last_name')  => 'Simpson',
     )->where(
         $Person->column('first_name'), '!=', 'Marge'
     );
     isa_ok($update, 'FeyX::Active::SQL::Update');
     {
         my $sth = $update->execute;
     }

     # +-----------------------------+
     # | first_name   | last_name    |
     # +-----------------------------+
     # | Marge        | Simpson      |
     # +-----------------------------+
     # | Homer        | Simpson      |
     # +-----------------------------+

     my $select = $Person->select;
     isa_ok($select, 'FeyX::Active::SQL::Select');
     {
         my $sth = $select->execute;

         is_deeply(
             $sth->fetchall_arrayref,
             [
                 [ 'Marge', 'Simpson' ],
                 [ 'Homer', 'Simpson' ],
             ],
             '... got the right values'
         );
     }

     {
         is_deeply(
             $Person->select->execute->fetchall_arrayref,
             [
                 [ 'Marge', 'Simpson' ],
                 [ 'Homer', 'Simpson' ],
             ],
             '... got the right values in one chained call'
         );
     }
}