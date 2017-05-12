package IronMan::Schema::Result::FeedTagMap;
    
use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);

__PACKAGE__->table('feed_tag_map');
__PACKAGE__->add_columns(
    feed => {
        data_type => 'integer',
    },
    tag => {
        data_type => 'integer',
    }
    );

__PACKAGE__->set_primary_key(qw/feed tag/);

__PACKAGE__->belongs_to( feed => 'IronMan::Schema::Result::Feed' );
__PACKAGE__->belongs_to( tag  => 'IronMan::Schema::Result::Tag' );

1;
