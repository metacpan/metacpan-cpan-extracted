package Foorum::ResultSet::UserOnline;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

sub get_data {
    my ( $self, $sid, $forum_code, $attr ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    $attr->{page} = 1 unless ( $attr->{page} );
    $attr->{order_by} = \'last_time DESC' unless ( $attr->{order_by} );

    my @extra_cols;
    if ($forum_code) {
        @extra_cols = (
            -or => [
                'path' => { 'like', "forum/$forum_code/%" },
                'path' => { 'like', "forum/$forum_code" },
            ]
        );
    }

    # get the last 15 minites' data
    # 15 * 60 = 900
    my $last_15_min = time() - 900;
    my $rs          = $schema->resultset('UserOnline')->search(
        {   last_time => { '>', $last_15_min },
            @extra_cols,
        },
        {   order_by => $attr->{order_by},
            rows     => 20,
            page     => $attr->{page},
        }
    );
    my @onlines = $rs->all;

    @onlines = &_handler_onlines( $self, $sid, @onlines );

    return wantarray ? ( \@onlines, $rs->pager ) : \@onlines;
}

sub whos_view_this_page {
    my ( $self, $sid, $path ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    # get the last 15 minites' data
    # 15 * 60 = 900
    my $last_15_min = time() - 900;
    my @onlines     = $schema->resultset('UserOnline')->search(
        {   last_time => { '>', $last_15_min },
            path      => $path,
        },
        {   order_by => \'last_time DESC',
            rows     => 20,
            page     => 1,
        }
    )->all;

    @onlines = &_handler_onlines( $self, $sid, @onlines );

    return wantarray ? @onlines : \@onlines;
}

sub _handler_onlines {
    my ( $self, $sid, @onlines ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $has_me = 0;    # damn it, we query it *before* the path is updated.
    my @results;
    foreach my $online (@onlines) {
        if ( not $has_me and $online->sessionid eq $sid ) {
            $has_me = 1;
        }
        my $user;
        if ( $online->user_id ) {
            $user = $schema->resultset('User')
                ->get( { user_id => $online->user_id } );
        }
        $online->{user} = $user;
        push @results, $online;
    }

    # if it's not in @onlines
    unless ($has_me) {
        push @results, 'SELF';    # let TT2 handle this.
    }

    return wantarray ? @results : \@results;
}
