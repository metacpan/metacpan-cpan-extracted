package Foorum::Controller::Admin::Forum;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';

sub auto : Private {
    my ( $self, $c ) = @_;

    # only administrator is allowed. site moderator is not allowed here
    unless ( $c->model('Policy')->is_admin( $c, 'site' ) ) {
        $c->forward( '/print_error', ['ERROR_PERMISSION_DENIED'] );
        return 0;
    }
    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;

    my @forums = $c->model('DBIC')->resultset('Forum')
        ->search( {}, { order_by => 'forum_id', } )->all;

    $c->stash->{forums}   = \@forums;
    $c->stash->{template} = 'admin/forum/index.html';
}

sub remove : Local {
    my ( $self, $c ) = @_;

    my $forum_id = $c->req->param('forum_id');

    # get the forum information
    # my $forum = $c->model('DBIC::Forum')->get($forum_code);

    $c->model('DBIC::Forum')->remove_forum($forum_id);
    $c->stash->{st} = 1;
}

sub merge_forums : Local {
    my ( $self, $c ) = @_;

    my $from_id = $c->req->param('from_id');
    my $to_id   = $c->req->param('to_id');

    $c->stash->{template} = 'admin/forum/merge_forums.html';
    return unless ( $from_id and $to_id );

    my $message = $c->model('DBIC::Forum')
        ->merge_forums( { from_id => $from_id, to_id => $to_id } );
    $c->stash->{st} = ($message) ? 1 : 301;
}

sub rebuild_forums : Local {
    my ( $self, $c ) = @_;

    my $rs
        = $c->model('DBIC::Forum')->search( {}, { columns => ['forum_id'] } );
    while ( my $r = $rs->next ) {
        $c->model('DBIC::Forum')->recount_forum( $r->forum_id );
    }
    $c->stash->{st} = 1;
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
