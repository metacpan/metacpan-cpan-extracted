package Foorum::Controller::TopicAction;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';

sub lock_or_sticky_or_elite :
    Regex('^forum/(\w+)/topic/(\d+)/(un)?(sticky|elite|lock)$') {
    my ( $self, $c ) = @_;

    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};
    $forum_code = $forum->{forum_code};
    my $topic_id = $c->req->snippets->[1];
    my $is_un    = $c->req->snippets->[2];
    my $action   = $c->req->snippets->[3];

    my $topic = $c->controller('Get')
        ->topic( $c, $topic_id, { forum_id => $forum_id } );

    # check policy
    unless ( $c->model('Policy')->is_moderator( $c, $forum_id )
        or ( 'lock' eq $action and $topic->{author_id} == $c->user->user_id )
        ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    my $status = ($is_un) ? '0' : '1';

    my $update_col;
    if ( 'sticky' eq $action ) {
        $update_col = 'sticky';
    } elsif ( 'lock' eq $action ) {
        $update_col = 'closed';
    } elsif ( 'elite' eq $action ) {
        $update_col = 'elite';
    }

    $c->model('DBIC::Topic')
        ->update_topic( $topic_id, { $update_col => $status, } );

    $c->model('Log')->log_action(
        $c,
        {   action      => "$is_un$action",
            object_type => 'topic',
            object_id   => $topic_id,
            forum_id    => $forum_id,
            text        => $topic->{title}
        }
    );

    if ( 'elite' eq $action ) {

        # for point
        my $plus_point = ($is_un) ? '- 4' : '+ 4';
        my $user = $c->model('DBIC')->resultset('User')
            ->get( { user_id => $topic->{author_id} } );
        $c->model('DBIC')->resultset('User')->update_user(
            $user,
            {   point => \"point $plus_point",    #"
            }
        );
    }

    my $url = $c->req->referer || $forum->{forum_url};
    $c->res->redirect("$url?st=1");
}

sub ban_or_unban_topic : Regex('^forum/(\w+)/topic/(\d+)/(un)?ban$') {
    my ( $self, $c ) = @_;

    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};
    $forum_code = $forum->{forum_code};
    my $topic_id = $c->req->snippets->[1];
    my $is_un    = $c->req->snippets->[2];

    my $topic = $c->controller('Get')
        ->topic( $c, $topic_id, { forum_id => $forum_id } );

    # check policy
    unless ( $c->model('Policy')->is_moderator( $c, $forum_id ) ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    if ($is_un) {
        $c->model('DBIC::Topic')
            ->update_topic( $topic_id, { status => 'healthy' } );
    } else {
        $c->model('DBIC::Topic')
            ->update_topic( $topic_id, { status => 'banned' } );
    }

    my $url = $c->req->referer || $forum->{forum_url};
    $c->res->redirect("$url?st=1");
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
