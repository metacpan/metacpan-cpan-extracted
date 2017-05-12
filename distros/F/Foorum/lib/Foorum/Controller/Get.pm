package Foorum::Controller::Get;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';

# Module Idea:
# we can't use /print_error in Model/Topic.pm like.
# so we move it here. Controller based.

sub forum : Private {
    my ( $self, $c, $forum_code, $attr ) = @_;

    my $forum = $c->model('DBIC::Forum')->get( $forum_code, $attr );

    # print error if the forum_id is non-exist
    $c->detach( '/print_error', ['Non-existent forum'] ) unless ($forum);
    $c->detach( '/print_error', ['Status: Banned'] )
        if ( $forum->{status} eq 'banned'
        and not $c->model('Policy')->is_moderator( $c, $forum->{forum_id} ) );

    my $forum_id = $forum->{forum_id};
    $c->stash->{forum} = $forum;

    # check policy
    if (    $c->user_exists
        and $c->model('Policy')->is_blocked( $c, $forum_id ) ) {
        $c->detach( '/print_error', ['ERROR_USER_BLOCKED'] );
    }
    if ( $forum->{policy} eq 'private' ) {
        unless ( $c->user_exists ) {
            $c->res->redirect('/login');
            $c->detach('/end');    # guess we'd better use Chained
        }

        unless ( $c->model('Policy')->is_user( $c, $forum_id ) ) {
            if ( $c->model('Policy')->is_pending( $c, $forum_id ) ) {
                $c->detach( '/print_error', ['ERROR_USER_PENDING'] );
            } elsif ( $c->model('Policy')->is_rejected( $c, $forum_id ) ) {
                $c->detach( '/print_error', ['ERROR_USER_REJECTED'] );
            } else {
                $c->detach('/forum/join');
            }
        }
    }

    return $forum;
}

sub topic : Private {
    my ( $self, $c, $topic_id, $attrs ) = @_;

    my $topic = $c->model('DBIC::Topic')->get( $topic_id, $attrs );

    # print error if the topic is non-existent
    $c->detach( '/print_error', ['Non-existent topic'] ) unless ($topic);

    # check forum_id
    if ( $attrs->{forum_id} and $attrs->{forum_id} != $topic->{forum_id} ) {
        $c->detach( '/print_error', ['Non-existent topic'] );
    }

    my $forum_id = $topic->{forum_id};
    $c->detach( '/print_error', ['Status: Banned'] )
        if ( $topic->{status} eq 'banned'
        and not $c->model('Policy')->is_moderator( $c, $forum_id ) );

    $c->stash->{topic} = $topic;
    return $topic;
}

sub user : Private {
    my ( $self, $c, $user_sig ) = @_;

    my $user;
    if ( $user_sig =~ /^\d+$/ ) {    # that's user_id
        $user = $c->model('DBIC::User')->get( { user_id => $user_sig } );
    } else {
        $user = $c->model('DBIC::User')->get( { username => $user_sig } );
    }

    $c->detach( '/print_error', ['ERROR_USER_NON_EXSIT'] ) unless ($user);

    if (   $user->{status} eq 'banned'
        or $user->{status} eq 'blocked'
        or $user->{status} eq 'terminated' ) {
        $c->detach( '/print_error', ['ERROR_ACCOUNT_CLOSED_STATUS'] );
    }

    $c->stash->{user} = $user;
    return $user;
}

sub comment : Private {
    my ( $self, $c, $comment_id, $attrs ) = @_;

    my $comment = $c->model('DBIC::Comment')->get( $comment_id, $attrs );

    # print error if the comment is non-exist
    $c->detach( '/print_error', ['Non-existent comment'] ) unless ($comment);

    if (    $attrs->{object_type}
        and $comment->{object_type} != $attrs->{object_type} ) {
        $c->detach( '/print_error', ['Non-existent comment'] );
    }
    if (    $attrs->{object_id}
        and $comment->{object_id} != $attrs->{object_id} ) {
        $c->detach( '/print_error', ['Non-existent comment'] );
    }

    if ( $attrs->{with_author} ) {
        $comment->{author} = $c->model('DBIC::User')
            ->get( { user_id => $comment->{author_id} } );
    }

    $c->stash->{comment} = $comment;
    return $comment;
}

1;
__END__

=head1 NAME

Foorum::Controller::Get

=head1 DESCRIPTION

Usually we write something like follows:

  my $user = $c->model('DBIC::User')->get( { username => $username } );
  $c->detach( '/print_error', ['ERROR_USER_NON_EXSIT'] ) unless ($user);
  if ( $user->{status} eq 'banned' or $user->{status} eq 'blocked' ) {
      $c->detach( '/print_error', ['ERROR_ACCOUNT_CLOSED_STATUS'] );
  }

It's pretty trival to write it everywhere, and we can't put '/print_error' into Model/User.pm since we do not need to raise error every time. so I put it into Controller/Get.pm

so does forum, topic.

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
