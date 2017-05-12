package My::Schema::Result::Another;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('Another');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        size              => 10,
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    num => {
        data_type   => 'numeric',
        size        => 10,
        is_nullable => 1
    },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( 'get_Basic', 'My::Schema::Result::Basic',
    'another_id' );

1;
