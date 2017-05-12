package Foorum::Controller::Site;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;
use Foorum::Formatter qw/filter_format/;

sub recent : Local {
    my ( $slef, $c, $recent_type ) = @_;

    my $rss = ( $c->req->path =~ /\/rss(\/|$)/ ) ? 1 : 0;   # /site/recent/rss

    my @extra_cols;
    if ( 'elite' eq $recent_type ) {
        @extra_cols = ( 'elite', 1 );
    } else {
        $recent_type = 'site';
    }

    my $page = get_page_from_url( $c->req->path );
    my $rows = ($rss) ? 10 : 20;
    my $rs   = $c->model('DBIC::Topic')->search(
        {   'forum.policy' => 'public',
            'me.status'    => { '!=', 'banned' },
            @extra_cols,
        },
        {   order_by => 'topic_id desc',
            prefetch => [ 'author', 'last_updator', 'forum' ],
            join     => [qw/forum/],
            rows     => $rows,
            page     => $page,
        }
    );

    $c->stash( { recent_type => $recent_type, } );

    my @topics = $rs->all;
    if ($rss) {
        foreach (@topics) {
            my $rs = $c->model('DBIC::Comment')->find(
                {   object_type => 'topic',
                    object_id   => $_->topic_id,
                },
                {   order_by => 'post_on',
                    rows     => 1,
                    page     => 1,
                    columns  => [ 'text', 'formatter' ],
                }
            );
            next unless ($rs);
            $_->{text} = $rs->text;

            # filter format by Foorum::Filter
            $_->{text} = $c->model('DBIC::FilterWord')
                ->convert_offensive_word( $_->{text} );
            $_->{text}
                = filter_format( $_->{text}, { format => $rs->formatter } );
        }
        $c->stash->{topics} = \@topics;

        $c->cache_page('600');
        $c->stash->{template} = 'site/recent.rss.html';
    } else {
        $c->cache_page('300');
        $c->stash(
            {   template => 'site/recent.html',
                pager    => $rs->pager,
                topics   => \@topics,
            }
        );
    }
}

sub online : Local {
    my ( $self, $c, undef, $forum_code ) = @_;

    $c->cache_page('60');

    my ( $results, $pager )
        = $c->model('DBIC::UserOnline')
        ->get_data( $c->sessionid, $forum_code );

    $c->stash(
        {   results  => $results,
            pager    => $pager,
            template => 'site/online.html',
        }
    );
}

sub members : Local {
    my ( $self, $c ) = @_;

    $c->cache_page('300');

    my $page = get_page_from_url( $c->req->path );
    my $rs   = $c->model('DBIC')->resultset('User')->search(
        undef,
        {   order_by => \'register_time DESC',
            columns  => [
                'user_id', 'username', 'nickname', 'register_time',
                'gender',  'status'
            ],
            page => $page,
            rows => 20,
        }
    );

    $c->stash(
        {   users    => [ $rs->all ],
            pager    => $rs->pager,
            template => 'site/user.html',
        }
    );
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
