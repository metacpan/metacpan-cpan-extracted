package Foorum::ResultSet::Forum;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';
use Foorum::Formatter qw/filter_format/;

sub get {
    my ( $self, $forum_code ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    # if $forum_code is all numberic, that's forum_id
    # or else, it's forum_code

    my $forum;    # return value
    my $forum_id = 0;
    if ( $forum_code =~ /^\d+$/ ) {
        $forum_id = $forum_code;
    } else {
        my $mem_key = 'global|forum_code_to_id';
        my $mem_val = $cache->get($mem_key);
        if ( $mem_val and $mem_val->{$forum_code} ) {
            $forum_id = $mem_val->{$forum_code};
        } else {
            $forum = $self->search( { forum_code => $forum_code } )->first;
            return unless $forum;
            $forum_id = $forum->forum_id;
            $mem_val->{$forum_code} = $forum_id;
            $cache->set( $mem_key, $mem_val, 36000 );    # 10 hours

            # set cache
            $forum = $forum->{_column_data};             # hash for cache
            $forum->{settings} = $schema->resultset('ForumSettings')
                ->get_basic( $forum->{forum_id} );
            $forum->{forum_url} = $self->get_forum_url($forum);
            $cache->set( "forum|forum_id=$forum_id",
                { val => $forum, 1 => 2 }, 7200 );
        }
    }

    return unless ($forum_id);

    unless ($forum) {    # do not get from convert forum_code to forum_id
        my $cache_key = "forum|forum_id=$forum_id";
        my $cache_val = $cache->get($cache_key);

        if ( $cache_val and $cache_val->{val} ) {
            $forum = $cache_val->{val};
        } else {
            $forum = $self->find( { forum_id => $forum_id } );
            return unless ($forum);

            # set cache
            $forum = $forum->{_column_data};    # hash for cache
            $forum->{settings} = $schema->resultset('ForumSettings')
                ->get_basic( $forum->{forum_id} );
            $forum->{forum_url} = $self->get_forum_url($forum);
            $cache->set( "forum|forum_id=$forum_id",
                { val => $forum, 1 => 2 }, 7200 );
        }
    }

    return $forum;
}

sub get_forum_url {
    my ( $self, $forum ) = @_;

    my $forum_url = '/forum/' . $forum->{forum_code};

    return $forum_url;
}

sub update_forum {
    my ( $self, $forum_id, $update ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    $self->search( { forum_id => $forum_id } )->update($update);

    $cache->remove("forum|forum_id=$forum_id");

    if ( $update->{forum_code} ) {
        my $mem_key = 'global|forum_code_to_id';
        my $mem_val = $cache->get($mem_key);
        $mem_val->{ $update->{forum_code} } = $forum_id;
        $cache->set( $mem_key, $mem_val, 36000 );    # 10 hours
    }
}

sub remove_forum {
    my ( $self, $forum_id ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    $self->search( { forum_id => $forum_id, } )->delete;
    $schema->resultset('LogAction')->search( { forum_id => $forum_id } )
        ->delete;

    # remove user_forum
    $schema->resultset('UserForum')->search( { forum_id => $forum_id } )
        ->delete;

    # get all topic_ids
    my @topic_ids;
    my $tp_rs = $schema->resultset('Topic')
        ->search( { forum_id => $forum_id, }, { columns => ['topic_id'], } );
    while ( my $r = $tp_rs->next ) {
        push @topic_ids, $r->topic_id;
    }
    $schema->resultset('Topic')->search( { forum_id => $forum_id, } )->delete;

    # get all poll_ids
    my @poll_ids;
    my $pl_rs = $schema->resultset('Poll')
        ->search( { forum_id => $forum_id, }, { columns => ['poll_id'], } );
    while ( my $r = $pl_rs->next ) {
        push @poll_ids, $r->poll_id;
    }
    $schema->resultset('Poll')->search( { forum_id => $forum_id, } )->delete;
    if ( scalar @poll_ids ) {
        $schema->resultset('PollOption')
            ->search( { poll_id => { 'IN', \@poll_ids }, } )->delete;
        $schema->resultset('PollResult')
            ->search( { poll_id => { 'IN', \@poll_ids }, } )->delete;
    }

    # comment and star/share
    if ( scalar @topic_ids ) {
        $schema->resultset('Comment')->search(
            {   object_type => 'topic',
                object_id   => { 'IN', \@topic_ids },
            }
        )->delete;
        $schema->resultset('Star')->search(
            {   object_type => 'topic',
                object_id   => { 'IN', \@topic_ids },
            }
        )->delete;
        $schema->resultset('Share')->search(
            {   object_type => 'topic',
                object_id   => { 'IN', \@topic_ids },
            }
        )->delete;
    }
    if ( scalar @poll_ids ) {
        $schema->resultset('Comment')->search(
            {   object_type => 'poll',
                object_id   => { 'IN', \@poll_ids },
            }
        )->delete;
        $schema->resultset('Star')->search(
            {   object_type => 'poll',
                object_id   => { 'IN', \@poll_ids },
            }
        )->delete;
        $schema->resultset('Share')->search(
            {   object_type => 'poll',
                object_id   => { 'IN', \@poll_ids },
            }
        )->delete;
    }

    # for upload
    $schema->resultset('Upload')->remove_for_forum($forum_id);
}

sub merge_forums {
    my ( $self, $info ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $from_id = $info->{from_id} or return 0;
    my $to_id   = $info->{to_id}   or return 0;

    my $old_forum = $self->find( { forum_id => $from_id } );
    return unless ($old_forum);
    my $new_forum = $self->find( { forum_id => $to_id } );
    return unless ($new_forum);
    $self->search( { forum_id => $from_id } )->delete;

    # remove user_forum
    $schema->resultset('UserForum')->search( { forum_id => $from_id } )
        ->delete;

    # topics
    $schema->resultset('Topic')->search( { forum_id => $from_id, } )
        ->update( { forum_id => $to_id, } );

    # FIXME!!!
    # need delete all topic_id cache object
    # $c->cache->remove("topic|topic_id=$topic_id");

    # polls
    $schema->resultset('Poll')->search( { forum_id => $from_id, } )
        ->update( { forum_id => $to_id, } );

    # comment
    $schema->resultset('Comment')->search( { forum_id => $from_id, } )
        ->update( { forum_id => $to_id, } );

    # for upload
    $schema->resultset('Upload')->change_for_forum($info);

    # update members
    if ( $new_forum->policy eq 'private' ) {
        my $total_members = $old_forum->total_members;
        $self->search( { forum_id => $to_id, } )->update(
            {   'total_members', \"total_members + $total_members"    #"
            }
        );
    }
    $self->recount_forum($to_id);

    return 1;
}

sub get_announcement {
    my ( $self, $forum ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $forum_id = $forum->{forum_id};

    my $memkey = "forum|announcement|forum_id=$forum_id";
    my $memval = $cache->get($memkey);
    if ( $memval and $memval->{value} ) {
        $memval = $memval->{value};
    } else {
        my $rs           = $schema->resultset('Comment');
        my $announcement = $rs->find(
            {   object_type => 'announcement',
                object_id   => $forum_id,
            },
            { columns => [ 'title', 'text', 'formatter' ], }
        );

        # filter format by Foorum::Filter
        if ($announcement) {
            $announcement = $announcement->{_column_data};
            $announcement->{text} = filter_format( $announcement->{text},
                { format => $announcement->{formatter} } );
        }
        $memval = $announcement;
        $cache->set( $memkey, { value => $memval, 1 => 2 } );
    }

    return $memval;
}

sub validate_forum_code {
    my ( $self, $forum_code ) = @_;

    return 'LENGTH'
        if ( length($forum_code) < 6 or length($forum_code) > 20 );

    for ($forum_code) {
        return 'HAS_BLANK' if (/\s/);
        return 'REGEX' unless (/[A-Za-z]+/s);
        return 'REGEX' unless (/^[A-Za-z0-9\_]+$/s);
    }

    my $schema = $self->result_source->schema;

    # forum_code_reserved
    my @reserved
        = $schema->resultset('FilterWord')->get_data('forum_code_reserved');
    return 'HAS_RESERVED' if ( grep { lc($forum_code) eq lc($_) } @reserved );

    # unique
    my $cnt = $self->count( { forum_code => $forum_code } );
    return 'DBIC_UNIQUE' if ($cnt);

    return;
}

sub recount_forum {
    my ( $self, $forum_id ) = @_;

    my $schema = $self->result_source->schema;

    # total_topics, total_replies
    my $rs = $schema->resultset('Topic')->search(
        { forum_id => $forum_id },
        {   select => [ { count => '*' }, { sum => 'total_replies' } ],
            as => [ 'sum_topics', 'sum_replies' ]
        }
    )->first;
    my $total_topics  = $rs->get_column('sum_topics');
    my $total_replies = $rs->get_column('sum_replies');

    # last_post_id
    my $lastest
        = $schema->resultset('Topic')->search( { forum_id => $forum_id },
        { order_by => \'last_update_date DESC', columns => ['topic_id'] } )
        ->first;    #'
    my $last_post_id = $lastest ? $lastest->topic_id : 0;

    $self->search( { forum_id => $forum_id } )->update(
        {   total_topics  => $total_topics,
            total_replies => $total_replies,
            last_post_id  => $last_post_id,
        }
    );
}

1;
__END__

=pod

=head1 NAME

Foorum::ResultSet::Forum - Forum object

=head1 FUNCTION

=over 4

=item get

  $schema->resultset('Forum')->get( $forum_id );
  $c->model('DBIC::User')->get( $forum_id );
  $c->model('DBIC::User')->get( $forum_code );

get() do not query database directly, it try to get from cache, if not exists, get from database and set a cache. (we may call it $forum_obj below)

  {
    forum_id   => 1,
    forum_code => 'FoorumTest',
    # other columns in database
    forum_url  => '/forum/ForumTest',
    settings   => {
        can_post_threads => 'Y',
        can_post_replies => 'N',
        can_post_polls   => 'Y'
    }
  }

I<settings> in the hash is from L<Foorum::ResultSet::ForumSettings> get_basic.

return $HASHREF

=item update_forum($forum_id, $update)

  $schema->resultset('Forum')->update_forum( $forum_id, { last_post_id => $topic_id } );
  $c->model('DBIC::Forum')->update_forum( $forum_id, { total_members => $members } );

inside, it calls search( { forum_id => $forum_id } )->update($update) and remove cache in B<get>

=item remove_forum($forum_id)

  $schema->resultset('Forum')->remove_forum( $forum_id );

delete all things belong to $forum, BE CAREFUL, it's un-recoverable.

=item merge_forums($info)

  $schema->resultset('Forum')->merge_forums( { from => $old_forum_id, to => $new_forum_id } );

move things belong to $old_forum_id to $new_fourm_id

=item validate_forum_code($forum_code)

  $schema->resultset('Forum')->validate_forum_code( $forum_code );
  $c->model('DBIC::Forum')->validate_forum_code( $forum_code );

validate $forum_code, return nothing means OK while return $str is an error_code like 'LENGTH', 'HAS_RESERVED' and others.

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
