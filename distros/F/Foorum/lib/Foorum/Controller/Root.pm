package Foorum::Controller::Root;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Time::HiRes qw( gettimeofday tv_interval );
use URI::Escape;

__PACKAGE__->config->{namespace} = '';

sub begin : Private {
    my ( $self, $c ) = @_;

    $c->stash->{start_t0} = [gettimeofday];
}

sub auto : Private {
    my ( $self, $c ) = @_;

    # in case (begin : Private) is overrided
    $c->stash->{start_t0} = [gettimeofday] unless ( $c->stash->{start_t0} );

    # internationalization
    $c->stash->{lang} = $c->req->cookie('lang')->value
        if ( $c->req->cookie('lang') );
    $c->stash->{lang} ||= $c->user->lang if ( $c->user_exists );
    $c->stash->{lang} ||= $c->config->{default_lang};
    if ( my $lang = $c->req->param('lang') ) {
        $lang =~ s/\W+//isg;
        if ( length($lang) == 2 ) {
            $c->res->cookies->{lang} = { value => $lang };
            $c->stash->{lang} = $lang;
        }
    }
    $c->languages( [ $c->stash->{lang} ] );

    my $path = $c->req->path;

    # global settings
    $c->stash->{is_rss_template} = ( $path =~ /\/rss(\/|$)/ ) ? 1 : 0;

    # for maintain, but admin can login and do something
    if (    $c->config->{function_on}->{maintain}
        and $path !~ /^(admin|login)\// ) {
        $c->stash->{template}
            = 'lang/' . $c->stash->{lang} . '/site/maintain.html';
        $c->stash->{simple_wrapper} = 1;
        return 0;
    }

    return 1;
}

sub default :Path {
    my ( $self, $c ) = @_;

    # 404
    $c->res->status(404);
    $c->detach( '/print_error', ['ERROR_404'] );
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->forward( 'Foorum::Controller::Forum', 'board' );
}

sub end : ActionClass('+Foorum::Action::PathLogger') {
    my ( $self, $c ) = @_;

    # check $c->error;
    $c->forward( $c->view('TT') ) if ( $c->model('Log')->check_c_error($c) );

    return 1 if ( $c->res->body );

    if ( $c->res->location ) {
        if ( $c->stash->{is_rss_template} ) {    # No redirection for RSS.
            $c->stash->{error}->{msg}
                = 'Permission Denied to ' . $c->req->base . $c->req->path;
            $c->stash->{template} = 'simple/error.html';    # print_error
            $c->res->location(undef);                       # reset
        } else {

            # for login using!
            if ( $c->res->location =~ /^\/login/ ) {
                my $location = '/login?referer=/' . $c->req->path;
                $location .= '?' . uri_escape( $c->req->uri->query )
                    if ( $c->req->uri->query );
                $c->res->location($location);
            }
            return 1;
        }
    }

    if ( $c->stash->{is_rss_template} ) {
        $c->stash->{no_wrapper} = 1;

        #$c->res->content_type('application/rss+xml');
        $c->res->content_type('text/xml');

        # if it's not a RSS template, go error
        if ( $c->stash->{template} !~ /rss/ ) {
            $c->stash->{error}->{msg} = 'Service is not available now.';
            $c->stash->{template} = 'simple/error.html';
        }
    } elsif ( $c->stash->{template} =~ /^simple\// ) {
        $c->stash->{simple_wrapper} = 1;
    } else {

        # get whos view this page?
        if ( $c->stash->{whos_view_this_page} ) {
            my $results = $c->model('DBIC::UserOnline')
                ->whos_view_this_page( $c->sessionid, $c->req->path );
            $c->stash->{whos_view_this_page} = $results;
        }
        $c->stash->{elapsed_time}
            = tv_interval( $c->stash->{start_t0}, [gettimeofday] );
    }

    # new message
    if (    not $c->stash->{no_wrapper}
        and $c->user_exists
        and $c->req->path !~ /^message(\/|$)/ ) {
        $c->stash->{message_unread} = $c->model('DBIC::Message')
            ->get_unread_cnt( $c->user->{user_id} );
    }
    $c->forward( $c->view('TT') );

    # check TT error.
    $c->forward( $c->view('TT') ) if ( $c->model('Log')->check_c_error($c) );
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
