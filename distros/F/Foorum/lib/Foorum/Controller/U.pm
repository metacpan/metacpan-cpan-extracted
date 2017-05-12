package Foorum::Controller::U;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;

sub user_profile : LocalRegex('^(\w+)$') {
    my ( $self, $c ) = @_;

    my $username = $c->req->snippets->[0];
    my $user = $c->controller('Get')->user( $c, $username );

    # recent topics
    if ( $user->{threads} ) {
        my $rs = $c->model('DBIC::Topic')->search(
            {   author_id   => $user->{user_id},
                'me.status' => { '!=', 'banned' },
            },
            {   order_by => \'last_update_date DESC',      #'
                prefetch => [ 'last_updator', 'forum' ],
                join     => [qw/forum/],
                rows     => 5,
                page     => 1,
            }
        );
        $c->stash->{recent_topics} = [ $rs->all ];
    }

    # shared items
    {
        my $rs = $c->model('DBIC::Share')->search(
            { user_id => $user->{user_id}, },
            {   order_by => \'time DESC',    #'
                rows     => 5,
                page     => 1,
            }
        );
        my @objects = $rs->all;
        my @shared_items;
        foreach my $rec (@objects) {
            my $object = $c->model('Object')->get_object_by_type_id(
                $c,
                {   object_type => $rec->object_type,
                    object_id   => $rec->object_id,
                }
            );
            next unless ($object);
            push @shared_items, $object;
        }
        $c->stash->{shared_items} = \@shared_items;
    }

    # get comments
    my ($view_mode)  = ( $c->req->path =~ /\/view_mode=(thread|flat)(\/|$)/ );
    my ($comment_id) = ( $c->req->path =~ /\/comment_id=(\d+)(\/|$)/ );
    ( $c->stash->{comments}, $c->stash->{comments_pager} )
        = $c->model('DBIC::Comment')->get_comments_by_object(
        {   object_type => 'user_profile',
            object_id   => $user->{user_id},
            page        => get_page_from_url( $c->req->path ),
            view_mode   => $view_mode,
            comment_id  => $comment_id,
        }
        );

    # get user settings
    $user->{settings} = $c->model('DBIC::User')->get_user_settings($user);

    $c->stash->{whos_view_this_page} = 1;
    $c->stash->{template}            = 'u/profile.html';
}

sub shared : LocalRegex('^(\w+)/shared$') {
    my ( $self, $c ) = @_;

    my $username = $c->req->snippets->[0];
    my $user = $c->controller('Get')->user( $c, $username );

    my $page = get_page_from_url( $c->req->path );
    my $rs   = $c->model('DBIC::Share')->search(
        { user_id => $user->{user_id}, },
        {   order_by => \'time DESC',    #'
            rows     => 20,
            page     => $page,
        }
    );

    my @objects = $rs->all;

    my @shared_items;
    foreach my $rec (@objects) {
        my $object = $c->model('Object')->get_object_by_type_id(
            $c,
            {   object_type => $rec->object_type,
                object_id   => $rec->object_id,
            }
        );
        next unless ($object);
        if ( $c->user_exists ) {

            # shared
            if ( $c->user->{user_id} == $user->{user_id} ) {
                $object->{is_shared} = 1;
            } else {
                $object->{is_shared} = $c->model('DBIC::Share')->count(
                    {   user_id     => $c->user->{user_id},
                        object_type => $rec->object_type,
                        object_id   => $rec->object_id,
                    }
                );
            }
        }

        push @shared_items, $object;
    }

    $c->stash(
        {   template     => 'u/shared.html',
            shared_items => \@shared_items,
            pager        => $rs->pager,
        }
    );
}

sub topics : LocalRegex('^(\w+)/topics$') {
    my ( $self, $c ) = @_;

    my $username = $c->req->snippets->[0];
    my $user = $c->controller('Get')->user( $c, $username );

    my $page = get_page_from_url( $c->req->path );
    my $rs   = $c->model('DBIC::Topic')->search(
        {   author_id   => $user->{user_id},
            'me.status' => { '!=', 'banned' },
        },
        {   order_by => \'last_update_date DESC',
            prefetch => [ 'last_updator', 'forum' ],
            join     => [qw/forum/],
            rows     => 20,
            page     => $page,
        }
    );

    $c->stash(
        {   template    => 'site/recent.html',
            topics      => [ $rs->all ],
            pager       => $rs->pager,
            recent_type => 'my',
        }
    );
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
