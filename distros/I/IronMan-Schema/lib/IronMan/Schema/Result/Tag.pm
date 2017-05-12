package IronMan::Schema::Result::Tag;
use strict;
use warnings;
use base qw/DBIx::Class/;
    
__PACKAGE__->load_components(qw/Core/);

__PACKAGE__->table('tag');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    name => {
        data_type => 'varchar',
        size => 1024,
    },
    );
__PACKAGE__->set_primary_key(qw/id/);
    
__PACKAGE__->has_many( feed_tag_map => 'IronMan::Schema::Result::FeedTagMap', 'tag' );
__PACKAGE__->many_to_many( feeds => feed_tag_map => 'feed' );
    
1;
