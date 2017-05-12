package Rdb::Langue;

use strict;

use base qw(Rdb::DB::Object::AutoBase1);

__PACKAGE__->meta->setup(
    table   => 'langues',

    columns => [
        langid => { type => 'serial' },
        langue => { type => 'text' },
    ],

    primary_key_columns => [ 'langid' ],
);

1;

