#
# This file is part of Jedi-Plugin-Auth
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::Auth;
use Jedi::App;
use Jedi::Plugin::Session;
use Jedi::Plugin::Auth;
use JSON;

sub jedi_app {
    my ($app) = @_;

    $app->get(
        '/signin',
        sub {
            my ( $app, $request, $response ) = @_;
            my $res = $app->jedi_auth_signin(
                user     => $request->params->{user},
                password => $request->params->{password},
                roles    => [ split /,/x, $request->params->{roles} // '' ],
                info => decode_json( $request->params->{info} // "{}" ),
            );
            $response->status(200);
            $response->body( encode_json($res) );
        }
    );

    $app->get(
        '/login',
        sub {
            my ( $app, $request, $response ) = @_;
            my $res = $app->jedi_auth_login(
                $request,
                user     => $request->params->{user},
                password => $request->params->{password},
            );
            $response->status(200);
            $response->body( encode_json($res) );
        }
    );

    $app->get(
        '/logout',
        sub {
            my ( $app, $request, $response ) = @_;
            my $res = $app->jedi_auth_logout( $request, );
            $response->status(200);
            $response->body( encode_json($res) );
        }
    );

    $app->get(
        '/auth_session',
        sub {
            my ( $app, $request, $response ) = @_;
            $response->status(200);
            $response->body( encode_json( $request->session_get // {} ) );
        }
    );

    $app->get(
        '/update',
        sub {
            my ( $app, $request, $response ) = @_;
            my $res = $app->jedi_auth_update(
                $request,
                user     => $request->params->{user},
                password => $request->params->{password},
                roles    => [ split /,/x, $request->params->{roles} // '' ],
                info => decode_json( $request->params->{info} // "{}" ),
            );
            $response->status(200);
            $response->body( encode_json($res) );
        }
    );

    $app->get(
        '/users_with_role',
        sub {
            my ( $app, $request, $response ) = @_;
            my $users
                = $app->jedi_auth_users_with_role( $request->params->{role} );
            $response->status(200);
            $response->body( encode_json($users) );
        }
    );

    $app->get(
        '/users_count',
        sub {
            my ( $app, $request, $response ) = @_;
            my $count = $app->jedi_auth_users_count;
            $response->status(200);
            $response->body($count);
        }
    );

    $app->get(
        '/users',
        sub {
            my ( $app, $request, $response ) = @_;
            my $users = $app->jedi_auth_users( split /,/x,
                $request->params->{users} // '' );
            $response->status(200);
            $response->body( encode_json($users) );
        }
    );

    $app->get(
        '/signout',
        sub {
            my ( $app, $request, $response ) = @_;
            my $users = $app->jedi_auth_signout( $request->params->{user} );
            $response->status(200);
            $response->body( encode_json($users) );
        }
    );

}

1;
