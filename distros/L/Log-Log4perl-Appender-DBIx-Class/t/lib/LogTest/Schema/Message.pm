package LogTest::Schema::Message;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw(PK::Auto InflateColumn::DateTime Core));
__PACKAGE__->table('messages');
__PACKAGE__->add_columns(
    id  => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        is_auto_increment => 1,
    },
    level => {
        data_type   => 'VARCHAR',
        is_nullable => 0,
        size        => 255
    },
    category => {
        data_type   => 'VARCHAR',
        is_nullable => 0,
        size        => 255
    },
    message => {
        data_type   => 'VARCHAR',
        is_nullable => 0,
        size        => 255
    },
    date_occurred => {
        data_type => 'DATETIME',
        is_nullable => 1
    }
);
__PACKAGE__->set_primary_key('id');

1;