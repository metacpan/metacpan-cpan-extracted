package Foorum::Plugin::FoorumUtils;

use strict;
use warnings;
our $VERSION = '1.001000';

sub load_once {
    my ( $c, $url ) = @_;

    # do not load twice
    return
        if ($c->stash->{__load_once_in_tt}
        and $c->stash->{__load_once_in_tt}->{$url} );
    $c->stash->{__load_once_in_tt}->{$url} = 1;

    if ( $url =~ /\.js$/i ) {

        # jquery.js and jquery.ui.js
        if ( $url eq 'jquery.js' ) {
            return
                qq~<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>\n~;
        } elsif ( $url eq 'jquery.ui.js' ) {
            return
                qq~<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.1/jquery-ui.min.js"></script>\n~;
        } else {
            my $js_dir = $c->config->{dir}->{js};
            return
                qq~<script type="text/javascript" src="$js_dir/$url"></script>\n~;
        }
    } elsif ( $url =~ /\.css$/i ) {

        # jquery.ui.css
        if ( $url eq 'jquery.ui.css' ) {
            return
                qq~<link rel="stylesheet" type="text/css" media="screen" href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.1/themes/base/jquery-ui.css" />\n~;
        } else {
            my $static_dir = $c->config->{dir}->{static};
            return
                qq~<link rel="stylesheet" href="$static_dir/css/$url" type="text/css" />\n~;
        }
    }
}

sub user_online {
    my ( $c, $title ) = @_;

    my $path = $c->req->path;
    $path = ($path) ? substr( $path, 0, 255 ) : 'forum';    # varchar(255)
    $c->create_session_id_if_needed;    # must have a sessionid
    my $session_id = $c->sessionid;
    my $user_id = ( $c->user_exists ) ? $c->user->user_id : 0;

    # check if there is a rs
    my $online = $c->model('DBIC::UserOnline')
        ->find( { sessionid => $session_id, } );
    if ($online) {
        $online->update(
            {   user_id   => $user_id,
                path      => $path,
                title     => $title,
                last_time => time()
            }
        );
    } else {
        $c->model('DBIC::UserOnline')->create(
            {   sessionid  => $session_id,
                user_id    => $user_id,
                path       => $path,
                title      => $title,
                start_time => time(),
                last_time  => time()
            }
        );
    }

    return;
}

1;
__END__

=pod

=head1 NAME

Foorum::Plugin::FoorumUtils - pollute $c by Foorum

=head1 FUNCTIONS

=over 4

=item load_once

Multi-times [% c.load_once('jquery.js') %] would only write one script tag in TT.

It is a trick for INCLUDE tt.html may call the same script src many times.

so does css. [% c.load_once('default.css') %]

We insert before the 'jquery.js' with [% c.config.dir.js %] and the 'default.css' with [% c.config.dir.static %]/css

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
