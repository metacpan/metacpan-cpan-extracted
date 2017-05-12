package Foorum::Controller::Topic;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Foorum::Utils qw/encodeHTML get_page_from_url generate_random_word/;
use Foorum::XUtils qw/theschwartz/;
use List::MoreUtils qw/firstidx/;

sub topic : Regex('^forum/(\w+)/(topic/)?(\d+)$') {
    my ( $self, $c ) = @_;

    my $forum_code = $c->req->snippets->[0];
    my $topic_id   = $c->req->snippets->[2];

    # get the forum information
    my $forum = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id = $forum->{forum_id};

    my $page = get_page_from_url( $c->req->path );
    $page = 1 unless ( $page and $page =~ /^\d+$/ );
    my $rss
        = ( $c->req->path =~ /\/rss(\/|$)/ ) ? 1 : 0; # /forum/ForumName/1/rss

    my $format = $c->req->param('format');
    if ( $format and 'pdf' eq $format ) {
        unless ( $c->config->{function_on}->{topic_pdf} ) {
            $c->detach( '/print_error', ['Function Disabled'] );
        }

        # Build PDF in backend
        my $random_word = generate_random_word(6);
        my $client      = theschwartz();
        $client->insert(
            'Foorum::TheSchwartz::Worker::Topic_ViewAsPDF',
            [ $forum_id, $topic_id, $random_word ]
        );

        my $url = $c->req->base
            . "upload/pdf/$forum_id-$topic_id-$random_word.pdf";
        $c->stash(
            {   download_url => $url,
                template     => 'topic/pdf_download.html',
            }
        );

        return 1;
    }

    # get the topic
    my $topic = $c->controller('Get')
        ->topic( $c, $topic_id, { forum_id => $forum_id } );

    if ($rss) {
        my @comments = $c->model('DBIC::Comment')
            ->get_all_comments_by_object( 'topic', $topic_id );

        # get last 20 items
        @comments = reverse(@comments);
        @comments = splice( @comments, 0, 20 );

        $c->stash(
            {   comments => \@comments,
                template => 'topic/topic.rss.html'
            }
        );
    } else {
        $topic->{hit} = $c->model('DBIC::Hit')
            ->register( 'topic', $topic_id, $topic->{hit} );
        if ( $c->user_exists ) {
            my $query = {
                user_id     => $c->user->user_id,
                object_type => 'topic',
                object_id   => $topic_id,
            };

            # 'star' status
            $c->stash->{is_starred} = $c->model('DBIC::Star')->count($query);

            # 'share' status
            $c->stash->{is_shared}
                = $c->model('DBIC')->resultset('Share')->count($query);

            # 'visit'
            $c->model('DBIC::Visit')
                ->make_visited( 'topic', $topic_id, $c->user->user_id );
        }

        # get comments
        my ($view_mode)
            = ( $c->req->path =~ /\/view_mode=(thread|flat)(\/|$)/ );
        my ($comment_id) = ( $c->req->path =~ /\/comment_id=(\d+)(\/|$)/ );
        (   $c->stash->{comments},
            $c->stash->{comments_pager},
            $c->stash->{top_comment_id}
            )
            = $c->model('DBIC::Comment')->get_comments_by_object(
            {   object_type => 'topic',
                object_id   => $topic_id,
                page        => $page,
                view_mode   => $view_mode,
                comment_id  => $comment_id,
            }
            );

        # print or normal show
        if ( $c->req->path =~ /\/print(\/|$)/ ) {
            $c->stash->{template} = 'topic/print.html';
        } else {

            # previous / next topic
            my @topic_ids
                = $c->model('DBIC::Topic')->get_topic_id_list($forum_id);
            my $place = firstidx { $_ == $topic_id } @topic_ids;
            if ( $place > 0 and $topic_ids[ $place - 1 ] ) {
                $c->stash->{previous_topic_id} = $topic_ids[ $place - 1 ];
            }
            if ( $place < $#topic_ids and $topic_ids[ $place + 1 ] ) {
                $c->stash->{next_topic_id} = $topic_ids[ $place + 1 ];
            }

            $c->stash->{whos_view_this_page} = 1;
            $c->stash->{template}            = 'topic/index.html';
        }
    }
}

sub create : Regex('^forum/(\w+)/topic/new$') {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    # check policy
    if ( $c->user->{status} eq 'banned' or $c->user->{status} eq 'blocked' ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};

    if (    $forum->{settings}->{can_post_threads}
        and $forum->{settings}->{can_post_threads} eq 'N' ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    $c->stash(
        {   template => 'comment/new.html',
            mode     => 'topic',
            action   => 'create',
        }
    );

    return unless ( $c->req->method eq 'POST' );

    # execute validation.
    $c->controller('Comment')->validate_params($c);

    my $upload    = $c->req->upload('upload');
    my $upload_id = 0;
    if ($upload) {
        $upload_id
            = $c->model('DBIC::Upload')
            ->add_file( $upload,
            { forum_id => $forum_id, user_id => $c->user->user_id } );
        unless ( $upload_id =~ /^\d+$/ ) {
            return $c->set_invalid_form( upload => $upload_id );
        }
    }

    my $title     = $c->req->param('title');
    my $formatter = $c->req->param('formatter');
    my $text      = $c->req->param('text');

    # only admin has HTML rights
    if ( 'html' eq $formatter ) {
        my $is_admin = $c->model('Policy')->is_admin( $c, 'site' );
        $formatter = 'plain' unless ($is_admin);
    }

    # create record
    my $topic_title = encodeHTML($title);
    my $topic       = $c->model('DBIC::Topic')->create_topic(
        {   forum_id         => $forum_id,
            title            => $topic_title,
            author_id        => $c->user->user_id,
            last_updator_id  => $c->user->user_id,
            last_update_date => time(),
            hit              => 0,
        }
    );

    # clear visit
    $c->model('DBIC::Visit')
        ->make_un_visited( 'topic', $topic->topic_id, $c->user->user_id );

    my $comment = $c->model('DBIC::Comment')->create_comment(
        {   object_type => 'topic',
            object_id   => $topic->topic_id,
            forum_id    => $forum_id,
            upload_id   => $upload_id,
            title       => $title,
            text        => $text,
            formatter   => $formatter,
            user_id     => $c->user->user_id,
            post_ip     => $c->req->address,
            lang        => $c->stash->{lang},
        }
    );

    $c->res->redirect( $forum->{forum_url} . '/topic/' . $topic->topic_id );
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
