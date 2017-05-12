package Foorum::ResultSet::Comment;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

use Foorum::Utils qw/get_page_from_url encodeHTML/;
use Foorum::Formatter qw/filter_format/;
use Data::Page;
use List::MoreUtils qw/uniq first_index part/;
use List::Util qw/first/;
use Scalar::Util qw/blessed/;

sub get_comments_by_object {
    my ( $self, $info ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();
    my $config = $schema->config();

    my $object_type = $info->{object_type};
    my $object_id   = $info->{object_id};
    my $page        = $info->{page} || 1;
    my $rows        = $info->{rows} || $config->{per_page}->{topic} || 10;
    my $selected_comment_id = $info->{comment_id};

    # 'thread' or 'flat'
    my $view_mode = $info->{view_mode};

    #$view_mode ||= ($object_type eq 'topic') ? 'thread' : 'flat';
    $view_mode ||= 'thread';    # XXX? Temp

    my @comments
        = $self->get_all_comments_by_object( $object_type, $object_id );

    # we return the top_comment_id for "Reply Topic"
    my $top_comment_id = 0;
    $top_comment_id = $comments[0]->{comment_id} if ( $comments[0] );

    my $pager = Data::Page->new();
    $pager->current_page($page);
    $pager->entries_per_page($rows);

    if ( 'flat' eq $view_mode ) {

        # when url contains /comment_id=$comment_id/
        # we need show that page including $comment_id
        if ( scalar @comments > $rows and $selected_comment_id ) {
            my $first_index
                = first_index { $_->{comment_id} == $selected_comment_id }
            @comments;
            $page = int( $first_index / $rows ) + 1 if ($first_index);
            $pager->current_page($page);
        }
        $pager->total_entries( scalar @comments );
        if ( 'user_profile' eq $object_type ) {
            @comments = reverse(@comments);
        }
        @comments = splice( @comments, ( $page - 1 ) * $rows, $rows );
    } else {    # thread mode
                # top_comments: the top level comments
        my ( @top_comments, @result_comments );

        # for topic. reply_to == 0 means the topic comments
        #            reply_to == topic.comments[0].comment_id means top level.
        if ( 'topic' eq $object_type ) {
            ( my $top_comments ) = part {
                (          $_->{reply_to} == 0
                        or $_->{reply_to} == $comments[0]->{comment_id}
                    )
                    ? 0
                    : 1;
            }
            @comments;
            @top_comments = @$top_comments;
        } else {
            ( my $top_comments ) = part {
                $_->{reply_to} == 0 ? 0 : 1;
            }
            @comments;
            $top_comments ||= [];
            @top_comments = @$top_comments;
        }

        # when url contains /comment_id=$comment_id/
        # we need show that page including $comment_id
        if ( scalar @top_comments > $rows
            and $selected_comment_id ) {

            # need to find out the top comment's comment_id
            my $top_comment
                = first { $_->{comment_id} == $selected_comment_id }
            @comments;
            while (1) {
                my $reply_to = $top_comment->{reply_to};
                $selected_comment_id = $top_comment->{comment_id};
                last if ( $reply_to == 0 );
                last
                    if ( 'topic' eq $object_type
                    and $reply_to == $comments[0]->{comment_id} );
                $top_comment
                    = first { $_->{comment_id} == $reply_to } @comments;
            }
            my $first_index
                = first_index { $_->{comment_id} == $selected_comment_id }
            @top_comments;
            $page = int( $first_index / $rows ) + 1 if ($first_index);
            $pager->current_page($page);
        }

        # paged by top_comments
        $pager->total_entries( scalar @top_comments );
        if ( 'user_profile' eq $object_type ) {
            @top_comments = reverse(@top_comments);
        }
        @top_comments = splice( @top_comments, ( $page - 1 ) * $rows, $rows );

        foreach (@top_comments) {
            $_->{level} = 0;
            push @result_comments, $_;
            next
                if ( 'topic' eq $object_type
                and $_->{comment_id} == $comments[0]->{comment_id} );

            # get children, 10 lines below
            $self->get_children_comments( $_->{comment_id}, 1, \@comments,
                \@result_comments );
        }
        @comments = @result_comments;
    }

    @comments = $self->prepare_comments_for_view(@comments);

    return ( \@comments, $pager, $top_comment_id );
}

sub get_children_comments {
    my ( $self, $reply_to, $level, $comments, $result_comments ) = @_;

    my ( $tmp_comments, $left_comments ) = part {
        $_->{reply_to} == $reply_to ? 0 : 1;
    }
    @$comments;
    return unless ($tmp_comments);

    foreach (@$tmp_comments) {
        $_->{level} = $level;
        push @$result_comments, $_;
        $self->get_children_comments(
            $_->{comment_id}, $level + 1,
            $left_comments,   $result_comments
        );
    }
}

sub get_all_comments_by_object {
    my ( $self, $object_type, $object_id ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cache_key   = "comment|object_type=$object_type|object_id=$object_id";
    my $cache_value = $cache->get($cache_key);

    my @comments;
    if ($cache_value) {
        @comments = @{ $cache_value->{comments} };
    } else {
        my $it = $self->search(
            {   object_type => $object_type,
                object_id   => $object_id,
            },
            {   order_by => 'post_on',
                prefetch => ['upload'],
            }
        );

        while ( my $rec = $it->next ) {
            my $upload = ( $rec->upload ) ? $rec->upload : undef;
            $rec = $rec->{_column_data};    # for cache using
            $rec->{upload} = $upload->{_column_data} if ($upload);

            # filter format by Foorum::Filter
            $rec->{title} = $schema->resultset('FilterWord')
                ->convert_offensive_word( $rec->{title} );
            $rec->{text} = $schema->resultset('FilterWord')
                ->convert_offensive_word( $rec->{text} );
            $rec->{text} = filter_format( $rec->{text},
                { format => $rec->{formatter} } );

            push @comments, $rec;
        }
        $cache_value = { comments => \@comments };
        $cache->set( $cache_key, $cache_value, 3600 );    # 1 hour
    }

    return wantarray ? @comments : \@comments;
}

# add author and others
sub prepare_comments_for_view {
    my ( $self, @comments ) = @_;

    my $schema = $self->result_source->schema;

    my @all_user_ids;
    foreach (@comments) {
        push @all_user_ids, $_->{author_id};
    }
    if ( scalar @all_user_ids ) {
        @all_user_ids = uniq @all_user_ids;
        my $authors = $schema->resultset('User')
            ->get_multi( 'user_id', \@all_user_ids );
        foreach (@comments) {
            $_->{author} = $authors->{ $_->{author_id} };
        }
    }

    return wantarray ? @comments : \@comments;
}

sub get {
    my ( $self, $comment_id, $attrs ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $comment = $self->find( { comment_id => $comment_id, } );
    return unless ($comment);

    $comment = $comment->{_column_data};
    if ( $attrs->{with_text} ) {

        # filter format by Foorum::Filter
        $comment->{text} = $schema->resultset('FilterWord')
            ->convert_offensive_word( $comment->{text} );
        $comment->{text} = filter_format( $comment->{text},
            { format => $comment->{formatter} } );
    }

    return $comment;
}

sub create_comment {
    my ( $self, $info ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $object_type = $info->{object_type};
    my $object_id   = $info->{object_id};
    my $user_id     = $info->{user_id};
    my $post_ip     = $info->{post_ip};
    my $forum_id    = $info->{forum_id} || 0;
    my $reply_to    = $info->{reply_to} || 0;
    my $formatter   = $info->{formatter} || 'ubb';
    my $title       = $info->{title};
    my $text        = $info->{text} || '';
    my $lang        = $info->{lang} || 'en';

  # we don't use [% | html %] now because there is too many title around in TT
    $title = encodeHTML($title);

    my $comment = $self->create(
        {   object_type => $object_type,
            object_id   => $object_id,
            author_id   => $user_id,
            title       => $title,
            text        => $text,
            formatter   => $formatter,
            post_on     => time(),
            post_ip     => $post_ip,
            reply_to    => $reply_to,
            forum_id    => $forum_id,
            upload_id   => $info->{upload_id} || 0,
        }
    );

    my $cache_key = "comment|object_type=$object_type|object_id=$object_id";
    $cache->remove($cache_key);

    # update user stat
    my $user = $schema->resultset('User')->get( { user_id => $user_id } );
    $schema->resultset('User')->update_user(
        $user,
        {   replies => \'replies + 1',
            point   => \'point + 1',
        }
    );

    # Email Sent
    if ( 'user_profile' eq $object_type ) {
        my $rept
            = $schema->resultset('User')->get( { user_id => $object_id } );
        my $from = $schema->resultset('User')->get( { user_id => $user_id } );

        # Send Notification Email
        $schema->resultset('ScheduledEmail')->create_email(
            {   template => 'new_comment',
                to       => $rept->{email},
                lang     => $lang,
                stash    => {
                    rept    => $rept,
                    from    => $from,
                    comment => $comment,
                }
            }
        );
    } else {

        # Send Update Notification for Starred Item
        my $client = $schema->theschwartz();
        $client->insert( 'Foorum::TheSchwartz::Worker::SendStarredNofication',
            [ $object_type, $object_id, $user_id ] );
    }

    return $comment;
}

sub remove_by_object {
    my ( $self, $object_type, $object_id ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $comment_rs = $self->search(
        {   object_type => $object_type,
            object_id   => $object_id,
        }
    );
    my $delete_counts = 0;
    while ( my $comment = $comment_rs->next ) {
        $self->remove_one_item($comment);
        $delete_counts++;
    }

    my $cache_key = "comment|object_type=$object_type|object_id=$object_id";
    $cache->remove($cache_key);

    return $delete_counts;
}

sub remove_children {
    my ( $self, $comment ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    if ( blessed $comment ) {
        $comment = $comment->{_column_data};
    }

    my $comment_id  = $comment->{comment_id};
    my $object_type = $comment->{object_type};
    my $object_id   = $comment->{object_id};

    my @comments
        = $self->get_all_comments_by_object( $object_type, $object_id );
    my @result_comments;
    $self->get_children_comments( $comment_id, 1, \@comments,
        \@result_comments );

    my $delete_counts = 1;
    $self->remove_one_item($comment);
    foreach (@result_comments) {
        $self->remove_one_item($_);
        $delete_counts++;
    }

    my $cache_key = "comment|object_type=$object_type|object_id=$object_id";
    $cache->remove($cache_key);

    return $delete_counts;
}

sub remove_one_item {
    my ( $self, $comment ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    if ( blessed $comment ) {
        $comment = $comment->{_column_data};
    }

    if ( $comment->{upload_id} ) {
        $schema->resultset('Upload')
            ->remove_file_by_upload_id( $comment->{upload_id} );
    }
    $self->search( { comment_id => $comment->{comment_id} } )->delete;

    my $user = $schema->resultset('User')
        ->get( { user_id => $comment->{user_id} } );
    $schema->resultset('User')->update_user(
        $user,
        {   replies => \'replies - 1',
            point   => \'point - 1',
        }
    );

    return 1;
}

sub validate_params {
    my ( $self, $params ) = @_;

    my $schema = $self->result_source->schema;

    my $title = $params->{'title'};
    my $text  = $params->{'text'};
    unless ( $title and length($title) < 80 ) {
        return 'ERROR_TITLE_LENGTH';
    } else {
        my $bad_word = $schema->resultset('FilterWord')->has_bad_word($title);
        if ( '0' ne $bad_word ) {
            return "BAD_TITLE_$bad_word";
        }
    }
    unless ( length($text) ) {
        return 'ERROR_TEXT_REQUIRED';
    } else {
        my $bad_word = $schema->resultset('FilterWord')->has_bad_word($text);
        if ( '0' ne $bad_word ) {
            return "BAD_TEXT_$bad_word";
        }
    }

    return 0;
}

1;
__END__

=pod

=head1 NAME

Foorum::ResultSet::Comment - Foorum Comment System

=head1 SYNOPSIS

        # get comments
        my ($view_mode)  = ( $c->req->path =~ /\/view_mode=(thread|flat)(\/|$)/ );
        my ($comment_id) = ( $c->req->path =~ /\/comment_id=(\d+)(\/|$)/ );
        ( $c->stash->{comments}, $c->stash->{comments_pager} )
            = $c->model('DBIC::Comment')->get_comments_by_object(
            {   object_type => 'topic',
                object_id   => $topic_id,
                page        => $page,
                view_mode   => $view_mode,
                comment_id  => $comment_id,
            }
            );

=head1 FUNCTIONS

=over 4

=item get_comments_by_object

Usually it's used in Topic or User page, to show the comments up. opts:

    object_type => 'topic',     # or 'user_profile'
    object_type => $topic_id,   # or $user_id,
    page        => $page,       # show which page
    rows        => 20,          # optional, default as c.config.per_page.topic || 10;
    view_mode   => 'flat',      # flat or thread
    comment_id  => $comment_id, # for URL like /topic/$topic_id/comment_id=12/
                                # go comment_id=12's page

=item get_children_comments

That's mainly for thread mode. when comment_id=2's reply_to=1, that means comment_id=2 is the child of comment_id=1.
meanwhile comment_id=3's reply_to=2, when we get children of comment_id=1, that's included too.

For get_comment_by_object and remove_children using.

=item get_all_comments_by_object($object_type, $object_id)

just get the @comments from table. no other action. with upload and text filtered.

=item get($comment_id, $attrs)

get one comment. attrs:

    with_text => 1, # get the $comment->{text} filtered.

=item remove_by_object($object_type, $object_id)

remove all comments belong to one certain object.

=item remove_children($comment)

check the CONCEPT above.

=item remove_one_item($comment)

remove one comment with upload and others.

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
