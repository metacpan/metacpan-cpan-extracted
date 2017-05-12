package Foorum::Controller::Poll;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Foorum::Utils qw/encodeHTML get_page_from_url/;

sub auto : Private {
    my ( $self, $c ) = @_;

    unless ( $c->config->{function_on}->{poll} ) {
        $c->forward( '/print_error', ['ERROR_PERMISSION_DENIED'] );
        return 0;
    }

    return 1;
}

sub create : Regex('^forum/(\w+)/poll/new$') {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};

    if (    $forum->{settings}->{can_post_polls}
        and $forum->{settings}->{can_post_polls} eq 'N' ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    $c->stash->{template} = 'poll/new.html';
    return unless ( $c->req->method eq 'POST' );

    # validation
    my $duration = $c->req->param('duration_day');
    $duration =~ s/\D+//isg;
    $duration ||= 7;    # default is 7 days
    my $multi = $c->req->param('multi');
    $multi = 0 if ( '1' ne $multi );    # 0 or 1

    my $now = time();
    $duration = $now + $duration * 86400;  # 86400 = 24 * 60 * 60, means 1 day

    # we prefer [% | html %] now because of my bad memory in TT html
    my $title = $c->req->param('title');
    $title = encodeHTML($title);

    # insert record into table
    my $poll = $c->model('DBIC::Poll')->create(
        {   forum_id  => $forum_id,
            author_id => $c->user->user_id,
            multi     => $multi,
            anonymous => 0,                   # disable it for this moment
            vote_no   => 0,
            time      => $now,
            duration  => $duration,
            title     => $title,
            hit       => 0,
        }
    );
    my $poll_id = $poll->poll_id;

    # get all options
    my $option_no = $c->req->param('option_number');
    $c->log->debug("option no: $option_no");
    foreach ( 1 .. $option_no ) {
        my $option_text = $c->req->param("option$_");
        next unless ($option_text);
        $c->model('DBIC::PollOption')->create(
            {   poll_id => $poll_id,
                text    => $option_text,
                vote_no => 0,
            }
        );
    }

    $c->res->redirect( $forum->{forum_url} . "/poll/$poll_id" );
}

sub poll : Regex('^forum/(\w+)/poll/(\d+)$') {
    my ( $self, $c ) = @_;

    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};
    my $poll_id    = $c->req->snippets->[1];

    my $poll = $c->model('DBIC::Poll')->find( { poll_id => $poll_id, },
        { prefetch => [ 'author', 'options' ], } );

    my $can_vote = 0;
    if ( time() < $poll->duration and $c->user_exists ) {
        my $is_voted = $c->model('DBIC::PollResult')->count(
            {   poll_id   => $poll_id,
                poster_id => $c->user->user_id,
            }
        );
        $can_vote = 1 unless ($is_voted);
    }

    # get comments
    my ($view_mode)  = ( $c->req->path =~ /\/view_mode=(thread|flat)(\/|$)/ );
    my ($comment_id) = ( $c->req->path =~ /\/comment_id=(\d+)(\/|$)/ );
    ( $c->stash->{comments}, $c->stash->{comments_pager} )
        = $c->model('DBIC::Comment')->get_comments_by_object(
        {   object_type => 'poll',
            object_id   => $poll_id,
            page        => get_page_from_url( $c->req->path ),
            view_mode   => $view_mode,
            comment_id  => $comment_id,
        }
        );

    # register hit
    $poll->{_column_data}->{hit} = $c->model('DBIC::Hit')
        ->register( 'poll', $poll->poll_id, $poll->hit );

    $c->stash(
        {   can_vote => $can_vote,
            poll     => $poll,
            template => 'poll/index.html',
        }
    );
}

sub view_polls : Regex('^forum/(\w+)/polls$') {
    my ( $self, $c ) = @_;

    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};
    my $page       = get_page_from_url( $c->req->path );

    # get all moderators
    $c->stash->{forum_roles}
        = $c->model('DBIC::UserForum')->get_forum_moderators($forum_id);

    my $rs = $c->model('DBIC::Poll')->search(
        { forum_id => $forum_id, },
        {   order_by => 'time desc',
            rows     => $c->config->{per_page}->{forum},
            page     => $page,
            prefetch => ['author'],
        }
    );

    $c->stash(
        {   polls    => [ $rs->all ],
            pager    => $rs->pager,
            template => 'poll/view_polls.html',
        }
    );
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
