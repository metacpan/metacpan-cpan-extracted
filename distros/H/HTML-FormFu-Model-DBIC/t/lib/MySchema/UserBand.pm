package MySchema::UserBand;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);

__PACKAGE__->table("user_band");

__PACKAGE__->add_columns(
    user => {
        data_type   => "INTEGER",
        is_nullable => 0,
    },
    band => {
        data_type   => "INTEGER",
        is_nullable => 0,
    },
    rating => {
        data_type => "INTEGER",
        is_nullable => 1,
    }
);

__PACKAGE__->set_primary_key( "user", "band" );

__PACKAGE__->belongs_to( "user", "MySchema::User" );

__PACKAGE__->belongs_to( "band", "MySchema::Band" );

1;

