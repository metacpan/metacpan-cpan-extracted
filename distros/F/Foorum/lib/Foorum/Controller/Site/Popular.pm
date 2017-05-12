package Foorum::Controller::Site::Popular;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;
use Foorum::Formatter qw/filter_format/;

sub default : Private {
    my ( $self, $c, undef, undef, $type ) = @_;

    my $rss = ( $c->req->path =~ /\/rss(\/|$)/ ) ? 1 : 0;   # /site/recent/rss

    unless ( $type
        and grep { $type eq $_ } ( 'weekly', 'monthly', 'yesterday', 'all' ) )
    {
        $type = 'today';                                    # default
    }
    $c->stash->{type} = $type;

    my $page = get_page_from_url( $c->req->path );
    my $rows = ($rss) ? 10 : 20;

    my $hit_rs = $c->model('DBIC')->resultset('Hit')->search(
        undef,
        {   rows     => $rows,
            page     => $page,
            order_by => \"hit_${type} DESC, hit_id DESC",
        }
    );

    my @objects;
    my %forum_policy;
    while ( my $rec = $hit_rs->next ) {
        my $object = $c->model('Object')->get_object_by_type_id(
            $c,
            {   object_type => $rec->object_type,
                object_id   => $rec->object_id,
            }
        );
        next unless ($object);

        # protect from private forum
        my $forum_id = $object->{forum_id};
        unless ( exists $forum_policy{$forum_id} ) {
            my $forum = $c->model('DBIC::Forum')->get($forum_id);
            $forum_policy{$forum_id}
                = ($forum) ? $forum->{policy} : 'private';
        }
        next if ( $forum_policy{$forum_id} ne 'public' );

        $object->{hit_rs} = $rec;
        push @objects, $object;
    }

    if ($rss) {
        foreach (@objects) {
            my $rs = $c->model('DBIC::Comment')->find(
                {   object_type => $_->{object_type},
                    object_id   => $_->{object_id},
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
        $c->stash->{objects} = \@objects;

        $c->cache_page('600');
        $c->stash->{template} = 'site/popular.rss.html';
    } else {
        $c->cache_page('300');
        $c->stash(
            {   template => 'site/popular.html',
                pager    => $hit_rs->pager,
                objects  => \@objects,
            }
        );
    }
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
