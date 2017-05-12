package Foorum::Controller::Search;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;
use Foorum::Logger qw/error_log/;
use Data::Page;
use Foorum::Search;

sub begin : Private {
    my ( $self, $c ) = @_;

    $c->stash->{search} = new Foorum::Search;

    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'search/index.html';
}

# path $base/search/forum/($forum_id|$forum_code)
sub forum : Local {
    my ( $self, $c ) = @_;

    my ($forum_id) = ( $c->req->path =~ /forum\/(\w+)(\/|$)/ );
    if ($forum_id) {
        my $forum = $c->controller('Get')->forum( $c, $forum_id );
        $forum_id = $forum->{forum_id} if ($forum);
    }

    $c->stash->{template} = 'search/forum.html';

    my $params   = $c->req->params;
    my $title    = $params->{'title'};
    my $author   = $params->{'author'};
    my $date     = $params->{'date'};
    my $order_by = $params->{order_by};

    # date value would be 2, 7, 30, 999
    $date = 0
        if ($date
        and $date != 2
        and $date != 7
        and $date != 30
        and $date != 999 );
    return unless ( $title or $author or $date );

    my $author_id;
    if ($author) {
        my $user = $c->model('DBIC::User')->get( { username => $author } );
        return $c->stash->{error_author} = 'User not found' unless ($user);
        $author_id = $user->{user_id};
    }

    my $page     = get_page_from_url( $c->req->path );
    my $per_page = 20;
    my $scond    = {
        title     => $c->req->params->{'title'},
        date      => $date,
        author_id => $author_id,
        forum_id  => $forum_id,
        page      => $page,
        per_page  => $per_page,
        order_by  => $order_by,
    };
    my $ret = $c->stash->{search}->query( 'topic', $scond );
    my $err = $ret->{error};
    if ($err) {
        error_log( $c->model('DBIC'), 'fatal', $err );

        $c->detach( '/print_error',
            ['Search is not going well, we will fix it ASAP.'] );
    }

    my $topic_ids = $ret->{matches};
    my @topics;
    foreach my $topic_id (@$topic_ids) {
        my $topic = $c->model('DBIC')->resultset('Topic')
            ->get( $topic_id, { with_author => 1 } );
        push @topics, $topic;
    }
    $c->stash->{topics} = \@topics;

    # pager
    my $pager = $ret->{pager};    # from database
    unless ($pager) {
        $pager = Data::Page->new();
        $pager->total_entries( $ret->{total} );
        $pager->entries_per_page($per_page);
        $pager->current_page($page);
    }
    $c->stash( { pager => $pager } );

}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
