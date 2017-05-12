package Foorum::ResultSet::Topic;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

sub get {
    my ( $self, $topic_id, $attrs ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cache_key   = "topic|topic_id=$topic_id";
    my $cache_value = $cache->get($cache_key);

    my $topic;
    if ( $cache_value and $cache_value->{val} ) {
        $topic = $cache_value->{val};
    } else {
        $topic = $self->find( { topic_id => $topic_id } );
        return unless ($topic);
        $topic = $topic->{_column_data};    # for cache
        $cache->set( $cache_key, { val => $topic, 1 => 2 }, 7200 );
    }

    if ( $attrs->{with_author} ) {
        $topic->{author} = $schema->resultset('User')
            ->get( { user_id => $topic->{author_id} } );
    }

    return $topic;
}

sub get_topic_id_list {
    my ( $self, $forum_id ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cache_key = "topic|get_topic_id_list|forum_id=$forum_id";
    my $cache_val = $cache->get($cache_key);

    if ( defined $cache_val and ref $cache_val eq 'ARRAY' ) {
        return wantarray ? @$cache_val : $cache_val;
    }

    # get from db and set cache
    my @all = $self->search(
        {   forum_id    => $forum_id,
            'me.status' => { '!=', 'banned' },
        },
        {   order_by => \'sticky DESC, last_update_date DESC',    #'
            columns  => ['topic_id'],
        }
    )->all;

    my @topic_ids = map { $_->topic_id } @all;
    $cache->set( $cache_key, \@topic_ids, 1800 );
    return wantarray ? @topic_ids : \@topic_ids;
}

sub create_topic {
    my ( $self, $create ) = @_;

    my $schema = $self->result_source->schema;

    $create->{post_on} = time() unless ( $create->{post_on} );
    $create->{last_update_date} = time()
        unless ( $create->{last_update_date} );
    my $topic = $self->create($create);

    # star it by default
    $schema->resultset('Star')->create(
        {   user_id     => $create->{author_id},
            object_type => 'topic',
            object_id   => $topic->topic_id,
            time        => time(),
        }
    );

    # update forum
    $schema->resultset('Forum')->update_forum(
        $topic->forum_id,
        {   total_topics => \'total_topics + 1',    #'
            last_post_id => $topic->topic_id,
        }
    );

    # update user stat
    my $user = $schema->resultset('User')
        ->get( { user_id => $create->{author_id} } );
    $schema->resultset('User')->update_user(
        $user,
        {   threads => \'threads + 1',
            point   => \'point + 2',
        }
    );

    return $topic;
}

sub update_topic {
    my ( $self, $topic_id, $update ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    $self->search( { topic_id => $topic_id } )->update($update);

    $cache->remove("topic|topic_id=$topic_id");
}

sub remove {
    my ( $self, $topic_id, $info ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $topic = $self->get($topic_id);

    return 0 unless ($topic);

    # delete topic
    $self->search( { topic_id => $topic_id } )->delete;
    $cache->remove("topic|topic_id=$topic_id");

    # delete comments with upload
    my $total_replies = $schema->resultset('Comment')
        ->remove_by_object( 'topic', $topic_id );

    # since one comment is topic indeed. so total_replies = delete_counts - 1
    $total_replies-- if ( $total_replies > 0 );

    # delete star/share
    $schema->resultset('Star')->search(
        {   object_type => 'topic',
            object_id   => $topic_id,
        }
    )->delete;
    $schema->resultset('Share')->search(
        {   object_type => 'topic',
            object_id   => $topic_id,
        }
    )->delete;

    my $forum_id = $topic->{forum_id};

    # log action
    my $user_id = $info->{operator_id} || 0;
    $schema->resultset('LogAction')->create(
        {   user_id     => $user_id,
            action      => 'delete',
            object_type => 'topic',
            object_id   => $topic_id,
            time        => time(),
            text        => $info->{log_text} || '',
            forum_id    => $forum_id,
        }
    );

    $schema->resultset('Forum')->recount_forum($forum_id);

    # update user stat
    my $user = $schema->resultset('User')
        ->get( { user_id => $topic->{author_id} } );
    my $remove_point = ( $topic->{elite} ) ? 6 : 2;
    $schema->resultset('User')->update_user(
        $user,
        {   threads => \'threads - 1',              #'
            point   => \"point - $remove_point",    #"
        }
    );

    return 1;
}

sub move {
    my ( $self, $topic_id, $to_fid ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $topic = $self->get($topic_id);
    return 0 unless $topic;
    return 0 if $topic->{forum_id} == $to_fid;

    # update topic table
    $self->update_topic( $topic_id, { forum_id => $to_fid } );

    # forum related
    my $old_forum_id = $topic->{forum_id};
    $schema->resultset('Forum')->recount_forum($old_forum_id);
    $schema->resultset('Forum')->recount_forum($to_fid);
    $cache->remove("topic|get_topic_id_list|forum_id=$old_forum_id");
    $cache->remove("topic|get_topic_id_list|forum_id=$to_fid");

    return 1;
}

1;
