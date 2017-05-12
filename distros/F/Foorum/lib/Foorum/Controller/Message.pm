package Foorum::Controller::Message;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;

sub auto : Private {
    my ( $self, $c ) = @_;

    unless ( $c->user_exists ) {
        $c->res->redirect('/login');
        return 0;
    }

    return 1;
}

sub default : Local {
    my ( $self, $c ) = @_;

    $c->forward('inbox');
}

sub compose : Local {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'message/compose.html';

    return unless ( $c->req->method eq 'POST' );

    # cann't compose to yourself
    my $to = $c->req->param('to');
    if ( $to eq $c->user->username ) {
        $c->set_invalid_form( to => 'USER_THESAME' );
        return;
    }

    # execute validation.
    $c->form(
        to    => [ qw/NOT_BLANK ASCII/, [qw/LENGTH 4 20/] ],
        title => [ qw/NOT_BLANK/,       [qw/LENGTH 1 80/] ],
        text  => [qw/NOT_BLANK/],
    );

    return if ( $c->form->has_error );

    # check user exist
    my $rept = $c->model('DBIC::User')->get( { username => $to } );
    unless ($rept) {
        $c->set_invalid_form( to => 'USER_NONEXIST' );
        return;
    }

    my $message = $c->model('DBIC')->resultset('Message')->create(
        {   from_id     => $c->user->user_id,
            to_id       => $rept->{user_id},
            title       => $c->req->param('title'),
            text        => $c->req->param('text'),
            post_on     => time(),
            post_ip     => $c->req->address,
            from_status => 'open',
            to_status   => 'open',
        }
    );

    # add unread
    $c->model('DBIC')->resultset('MessageUnread')->create(
        {   message_id => $message->message_id,
            user_id    => $rept->{user_id},
        }
    );
    $c->cache->remove(
        'global|message_unread_cnt|user_id=' . $rept->{user_id} );

    # Send Notification Email
    $c->model('DBIC::ScheduledEmail')->create_email(
        {   template => 'new_message',
            to       => $rept->{email},
            lang     => $c->stash->{lang},
            stash    => {
                rept    => $rept,
                from    => $c->user,
                message => $message,
            }
        }
    );

    $c->res->redirect('/message/outbox');
}

sub inbox : Local {
    my ( $self, $c ) = @_;

    my $page = get_page_from_url( $c->req->path );
    my $it   = $c->model('DBIC')->resultset('Message')->search(
        {   to_id     => $c->user->user_id,
            to_status => 'open',
        },
        {   columns  => [ 'message_id', 'title', 'post_on', ],
            prefetch => ['sender'],
            order_by => \'post_on DESC',
            rows => $c->config->{per_page}->{message},
            page => $page,
        }
    );
    my @messages = $it->all;
    $c->stash->{messages} = \@messages;
    $c->stash->{pager}    = $it->pager;

    my @all_message_ids;
    push @all_message_ids, $_->message_id foreach (@messages);
    $c->stash->{unread}
        = $c->model('DBIC::Message')
        ->are_messages_unread( $c->user->user_id, \@all_message_ids )
        if ( scalar @all_message_ids );

    $c->stash->{template} = 'message/inbox.html';
}

sub outbox : Local {
    my ( $self, $c ) = @_;

    my $page = get_page_from_url( $c->req->path );
    my $it   = $c->model('DBIC')->resultset('Message')->search(
        {   from_id     => $c->user->user_id,
            from_status => 'open',
        },
        {   columns  => [ 'message_id', 'title', 'post_on', ],
            prefetch => ['recipient'],
            order_by => \'post_on DESC',
            rows => $c->config->{per_page}->{message},
            page => $page,
        }
    );
    my @messages = $it->all;
    $c->stash->{messages} = \@messages;
    $c->stash->{pager}    = $it->pager;

    $c->stash->{template} = 'message/outbox.html';
}

sub message : LocalRegex('^(\d+)$') {
    my ( $self, $c ) = @_;

    my $message_id = $c->req->snippets->[0];

    my $message
        = $c->model('DBIC')->resultset('Message')
        ->find( { message_id => $message_id, },
        { prefetch => [ 'sender', 'recipient' ], } );
    $c->stash->{message} = $message;

    # permission check
    if (    $c->user->{user_id} != $message->from_id
        and $c->user->{user_id} != $message->to_id ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    # mark as read
    $c->model('DBIC')->resultset('MessageUnread')->search(
        {   message_id => $message_id,
            user_id    => $c->user->user_id,
        }
    )->delete;
    $c->cache->remove(
        'global|message_unread_cnt|user_id=' . $c->user->{user_id} );

    $c->stash->{template} = 'message/message.html';
}

sub delete : LocalRegex('^(\d+)/delete$') {
    my ( $self, $c ) = @_;

    my $message_id = $c->req->snippets->[0];

    my $message = $c->model('DBIC')->resultset('Message')
        ->find( { message_id => $message_id, } );

    # permission check
    if (    $c->user->{user_id} != $message->from_id
        and $c->user->{user_id} != $message->to_id ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    # mark as read
    $c->model('DBIC')->resultset('MessageUnread')->search(
        {   message_id => $message_id,
            user_id    => $c->user->user_id,
        }
    )->delete;
    $c->cache->remove(
        'global|message_unread_cnt|user_id=' . $c->user->{user_id} );

    # both inbox and outbox.
    # we set 'from_status' as 'deleted' when from_id delete it
    # we set 'to_status' as 'deleted' when to_id delete it
    # if both 'from_status' and 'to_status' eq 'deleted', we remove it from db
    if ( $c->user->user_id == $message->from_id ) {    # outbox
        if ( $message->to_status eq 'deleted' ) {
            $c->model('DBIC::Message')->remove_from_db($message_id);
        } else {
            $message->update( { from_status => 'deleted' } );
        }
        $c->res->redirect('/message/outbox');
    } elsif ( $c->user->user_id == $message->to_id ) {    # inbox
        if ( $message->from_status eq 'deleted' ) {
            $c->model('DBIC::Message')->remove_from_db($message_id);
        } else {
            $message->update( { to_status => 'deleted' } );
        }
        $c->res->redirect('/message/inbox');
    }
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
