package MToken::Server; # $Id: Server.pm 112 2021-10-11 11:53:20Z minus $
use strict;
use warnings FATAL => 'all';
use utf8;

=encoding utf-8

=head1 NAME

MToken::Server - MToken web-server class

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

    use MToken::Server;

=head1 DESCRIPTION

This module provides MToken web-server functionality

=head2 reload

The reload hook

=head2 startup

Mojo application startup method

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious>, L<MToken>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2021 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = "1.03";

use Mojo::Base 'Mojolicious';

use Mojo::File qw/path/;
use Mojo::Util qw/sha1_sum secure_compare/;

use CTK::Util qw/preparedir sharedir sharedstatedir/;
use CTK::ConfGenUtil;

use MToken::Const;

has 'documentroot';

# Mojo Routes (paths)
sub startup {
    my $self = shift; # app
    my $ctk = $self->can('ctk') ? $self->ctk() : $self->{ctk};

    # Set password
    my $username = value($ctk->conf("username") // "");
    my $secret = value($ctk->conf("password") // "");
    $self->secrets([$secret]) if length($secret);

    # Logging
    if ($ctk->debugmode) {
        $self->log->level("debug")->path($ctk->logfile())
    } elsif ($ctk->verbosemode()) {
        $self->log->level("info")->path($ctk->logfile())
    } else {
        $self->log->level("warn")->path($ctk->logfile())
    }
    #$self->log->debug("Startup!! =$$"); # $self->ctk->logdir()

    # Switch to installable home directory
    $self->home(Mojo::Home->new($ctk->datadir()));

    # Get DocumentRoot and replace as public-path
    my $documentroot = value($ctk->conf("documentroot")) || path(sharedir(), $ctk->prefix)->to_string();
    $self->documentroot($documentroot);
    $self->static->paths()->[0] = $documentroot; #unshift @{$static->paths}, '/home/sri/themes/blue/public';
    $self->static->paths()->[1] = $ctk->datadir();

    # Hooks
    $self->hook(before_dispatch => sub {
        my $c = shift;

        # Set Server header
        $c->res->headers->server(sprintf("%s/%s", PROJECTNAME, $self->VERSION));
        $c->app->log->debug("Start request dispatch");

        # Authentication
        my $need_auth = length($username) ? 1 : 0;
        if ($need_auth) {
            my $req_uri = $c->req->url->to_abs();
            my $ui_username = $req_uri->username() // "";
            my $ui_secret = sha1_sum($req_uri->password() // time());

            # Check username and password
            return 1 if length($secret)
                and secure_compare($username, $ui_username)
                and secure_compare($secret, $ui_secret);

            # Require authentication
            $c->res->headers->www_authenticate('Basic realm="MToken Strict Zone"');
            return $c->render(json => {
                message => "Authentication required!",
            }, status => 401);
        }

        return;
    });

    # Routes
    $self->routes->get('/')->to('alpha#root');
    $self->routes->get('/env')->to('alpha#env') if $ctk->debugmode();
    $self->routes->get('/mtoken')->to('alpha#info');
    $self->routes->get('/mtoken/:token' => [token => qr/[a-z][a-z0-9]+/])->to('alpha#list');
    $self->routes->get('/mtoken/:token/:tarball' =>
            [
                token => qr/[a-z][a-z0-9]+/,
                tarball => qr/C[0-9]{8}T[0-9]{6}\.tkn/,
            ]
        )->to('alpha#download_tarball');
    $self->routes->put('/mtoken/:token/:tarball' =>
            [
                token => qr/[a-z][a-z0-9]+/,
                tarball => qr/C[0-9]{8}T[0-9]{6}\.tkn/,
            ]
        )->to('alpha#upload_tarball');
    $self->routes->delete('/mtoken/:token/:tarball' =>
            [
                token => qr/[a-z][a-z0-9]+/,
                tarball => qr/C[0-9]{8}T[0-9]{6}\.tkn/,
            ]
        )->to('alpha#delete_tarball');

    # Delete std favicon file from static
    delete $self->static->extra->{'favicon.ico'};

    return 1;
}

# Reload hook
sub reload {
    my $self = shift;
    $self->log->warn("Request for reload $$"); # $self->ctk->logdir()
    return 1; # 1 - ok; 0 - error :(
}

1;

__END__
