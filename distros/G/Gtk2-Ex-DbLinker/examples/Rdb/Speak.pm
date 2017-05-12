package Rdb::Speak;

use strict;

use base qw(Rdb::DB::Object::AutoBase1);

__PACKAGE__->meta->setup(
    table   => 'speaks',

    columns => [
        speaksid  => { type => 'serial' },
        countryid => { type => 'integer', not_null => 1 },
        langid    => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns => [ 'speaksid' ],
);

1;

