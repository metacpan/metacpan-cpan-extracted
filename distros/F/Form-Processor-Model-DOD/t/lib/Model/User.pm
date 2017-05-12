package Model::User;
use strict;
use warnings;

use base qw( Data::ObjectDriver::BaseObject );

use Data::ObjectDriver::Driver::DBI;

__PACKAGE__->install_properties({
    columns => [ 'id', 'name', 'married_on', 'state', 'favorite_number' ],
    datasource => 'user',
    primary_key => 'id',
    column_defs => { 
        married_on => 'date'
    },
    driver => Data::ObjectDriver::Driver::DBI->new(
        dsn      => 'dbi:SQLite:dbname=testdb.db',
    ),
});

1;
