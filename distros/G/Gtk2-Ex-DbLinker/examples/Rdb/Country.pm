package Rdb::Country;

use strict;

use base qw(Rdb::DB::Object::AutoBase1);

__PACKAGE__->meta->setup(
    table   => 'countries',

    columns => [
        countryid  => { type => 'serial' },
        country    => { type => 'text' },
        mainlangid => { type => 'integer' },
    ],

    primary_key_columns => [ 'countryid' ],
);

1;

