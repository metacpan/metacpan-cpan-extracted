package IronMan::Schema::Result::Post;

use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('posts');
__PACKAGE__->add_columns(
    post_id => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    # FK to Feed
    feed_id => {
        data_type => 'varchar',
        size => 255,
    },
    url => {
        data_type => 'varchar',
        size => 1024,
    },
    title => {
        data_type => 'varchar',
        size => 1024,
    },
    posted_on => {
        data_type => 'datetime',
    },
    ## arbitrary size!
    ## HTMLTruncate plugin to plagger truns to 300 at the moment
    summary => {
        data_type => 'text',
        is_nullable => 1,
    },
    body => {
        data_type => 'text',
    }, 
    summary_filtered => {
        data_type => 'text',
        is_nullable => 1,
    },
    body_filtered => {
        data_type => 'text',
        is_nullable => 1,
    },
    author => {
        data_type => 'varchar',
        size => 1024,
    },
    tags => {
        data_type => 'varchar',
        size => 1024,
    },
    );

__PACKAGE__->set_primary_key('post_id');
__PACKAGE__->add_unique_constraint('url' => ['url']);

__PACKAGE__->belongs_to('feed', 'IronMan::Schema::Result::Feed', 'feed_id');

__PACKAGE__->inflate_column('tags', {
        'inflate' => sub { return [split(/,/,$_[0])] },
        'deflate' => sub { return join(',', @{$_[0]}) },
    });

sub next_post {
    my $self = shift;
    
    my $dt_parser = $self->result_source->storage->datetime_parser;
    
    return $self->result_source->resultset->search({
	   'posted_on' => { '<' => $dt_parser->format_datetime($self->posted_on) },
	},{
	    'order_by' => \'posted_on DESC',
	    'rows'    => 1,
    })->first;
}

sub prev_post {
    my $self = shift;
    
    my $dt_parser = $self->result_source->storage->datetime_parser;
    
    return $self->result_source->resultset->search({
	   'posted_on' => { '>' => $dt_parser->format_datetime($self->posted_on) },
	},{
	    'order_by' => \'posted_on ASC',
	    'rows'    => 1,
    })->first;
}

1;
