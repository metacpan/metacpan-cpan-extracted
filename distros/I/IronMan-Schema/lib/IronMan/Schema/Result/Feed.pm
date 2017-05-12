package IronMan::Schema::Result::Feed;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('feed');
__PACKAGE__->add_columns(
    id => {
        data_type => 'varchar',
        size => 255,
    },
    url => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    link => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    title => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    owner => {
        data_type => 'varchar',
        size => 255,
    },
    );
__PACKAGE__->set_primary_key(qw/id/);
__PACKAGE__->add_unique_constraint(url => ['url']);
__PACKAGE__->has_many('posts' => 'IronMan::Schema::Result::Post', 'feed_id');

__PACKAGE__->has_many('posts', 'IronMan::Schema::Result::Post', 'feed_id');

1;
