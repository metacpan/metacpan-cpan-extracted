#!perl
#
# This file is part of Jedi-Plugin-Auth
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use Test::Most 'die';
use HTTP::Request::Common;
use Plack::Test;
use Module::Runtime qw/use_module/;
use Carp;
use JSON;
use Jedi;
use Test::File::ShareDir -share =>
    { -dist => { 'Jedi-Plugin-Auth' => 'share' } };

my $jedi = Jedi->new;
$jedi->road( '/', 't::lib::Auth' );

test_psgi $jedi->start, sub {
    my $cb = shift;

    subtest "signin" => sub {
        {
            my $res  = $cb->( GET '/signin' );
            my $resp = decode_json( $res->content );
            is_deeply(
                $resp,
                { status => 'ko', missing => [qw/user password roles/] },
                'missing user, password, roles'
            );
        }

        {
            my $res  = $cb->( GET '/signin?user=test' );
            my $resp = decode_json( $res->content );
            is_deeply(
                $resp,
                { status => 'ko', missing => [qw/password roles/] },
                'missing password, roles'
            );
        }

        {
            my $res  = $cb->( GET '/signin?user=test&password=test' );
            my $resp = decode_json( $res->content );
            is_deeply(
                $resp,
                { status => 'ko', missing => [qw/roles/] },
                'missing roles'
            );
        }

        subtest "signin user" => sub {
            my $res
                = $cb->( GET
                    '/signin?user=test&password=test&roles=test,admin&info={"activated":"1"}'
                );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ok',   'status ok';
            is $resp->{user},   'test', 'user name ok';
            cmp_bag $resp->{roles}, [ 'test', 'admin' ], 'roles ok';
            like $resp->{uuid}, qr{^\w+\-\w+\-\w+\-\w+\-\w+$}x, 'uuid ok';
            is_deeply $resp->{info}, { activated => 1 }, 'info is ok';
        };

        subtest "signin again user" => sub {
            my $res
                = $cb->( GET
                    '/signin?user=test&password=test&roles=test,admin&info={"activated":"1"}'
                );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ko', 'status ko';
            like $resp->{error_msg}, qr{user is not uniq},
                'user already exists';
        };

        subtest "signin user2" => sub {
            my $res
                = $cb->( GET
                    '/signin?user=test2&password=test&roles=test&info={"activated":"0"}'
                );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ok',    'status ok';
            is $resp->{user},   'test2', 'user name ok';
            cmp_bag $resp->{roles}, ['test'], 'roles ok';
            like $resp->{uuid}, qr{^\w+\-\w+\-\w+\-\w+\-\w+$}x, 'uuid ok';
            is_deeply $resp->{info}, { activated => 0 }, 'info is ok';
        };

    };

    subtest "login" => sub {

        {
            my $res  = $cb->( GET '/login' );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ko', 'missing user';
        }

        {
            my $res  = $cb->( GET '/login?user=test' );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ko', 'missing password';
        }

        {
            # missing user
            my $res  = $cb->( GET '/login?user=test3&password=test3' );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ko', 'user unknown';
        }

        {
            # bad password
            my $res  = $cb->( GET '/login?user=test2&password=test2' );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ko', 'bad password';
        }

        my ( $cookie, $user_info );

        subtest "login user" => sub {
            my $res  = $cb->( GET '/login?user=test&password=test' );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ok',   'status ok';
            is $resp->{user},   'test', 'user name ok';
            cmp_bag $resp->{roles}, [ 'test', 'admin' ], 'roles ok';
            like $resp->{uuid}, qr{^\w+\-\w+\-\w+\-\w+\-\w+$}x, 'uuid ok';
            is_deeply $resp->{info}, { activated => 1 }, 'info is ok';
            $cookie    = $res->header('Set-Cookie')->as_string;
            $user_info = $resp;
            delete $user_info->{status};
        };

        subtest "session for user" => sub {
            my $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/auth_session',
                    HTTP::Headers->new( 'Cookie' => $cookie, )
                )
            );
            my $resp = decode_json( $res->content );
            is_deeply( $resp->{auth}, $user_info, 'user info ok in session' );
        };

        subtest "logout user" => sub {
            my $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/logout',
                    HTTP::Headers->new( 'Cookie' => $cookie, )
                )
            );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ok', 'status ok';
        };

        subtest "check logout" => sub {
            my $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/auth_session',
                    HTTP::Headers->new( 'Cookie' => $cookie, )
                )
            );
            my $resp = decode_json( $res->content );
            ok !exists $resp->{auth}, 'auth has been discarded';
        };
    };

    subtest "update user" => sub {
        {
            my $res  = $cb->( GET '/update' );
            my $resp = decode_json( $res->content );
            is_deeply $resp, { status => 'ko', missing => ['user'] },
                'missing user';
        }
        {
            my $res  = $cb->( GET '/update?user=test3' );
            my $resp = decode_json( $res->content );
            is_deeply $resp,
                { status => 'ko', error_msg => 'user not found' },
                'user not found';
        }
        {
            my $res  = $cb->( GET '/update?user=test&password=uptest' );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ok', 'update ok';
            $res  = $cb->( GET '/login?user=test&password=uptest' );
            $resp = decode_json( $res->content );
            is $resp->{status}, 'ok', 'password properly set';
        }
        {
            my $res = $cb->(
                GET '/update?user=test&info={"email":"me@celogeek.com"}' );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ok', 'update ok';
            is_deeply $resp->{info},
                { 'activated' => 1, email => 'me@celogeek.com' },
                'info properly updated';
        }
        {
            my $res
                = $cb->( GET '/update?user=test&info={"activated":null}' );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ok', 'update ok';
            is_deeply $resp->{info}, { email => 'me@celogeek.com' },
                'info deleted';
        }
        {
            my $res  = $cb->( GET '/update?user=test&roles=a,b,c' );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ok', 'update ok';
            is_deeply $resp->{roles}, [qw/a b c/], 'roles properly sets';
        }
        {
            my $res  = $cb->( GET '/update?user=test&roles=a,b' );
            my $resp = decode_json( $res->content );
            is $resp->{status}, 'ok', 'update ok';
            is_deeply $resp->{roles}, [qw/a b/], 'roles properly sets';
        }
    };

    subtest 'update user and check session' => sub {
        my $res    = $cb->( GET '/login?user=test&password=uptest' );
        my $cookie = $res->header('Set-Cookie')->as_string;
        $res = $cb->(
            HTTP::Request->new(
                'GET' =>
                    '/update?user=test&info={"email":"test@test.com"}&roles=a,x,y,z',
                HTTP::Headers->new( 'Cookie' => $cookie, )
            )
        );
        $res = $cb->(
            HTTP::Request->new(
                'GET' => '/auth_session',
                HTTP::Headers->new( 'Cookie' => $cookie, )
            )
        );
        my $session = decode_json( $res->content );
        is_deeply $session->{auth}{info}, { email => 'test@test.com' },
            'info ok';
        is_deeply $session->{auth}{roles}, [qw/a x y z/], 'roles ok';
    };

    subtest 'update user and log into another one' => sub {
        my $res    = $cb->( GET '/login?user=test&password=uptest' );
        my $cookie = $res->header('Set-Cookie')->as_string;
        $res = $cb->(
            HTTP::Request->new(
                'GET' => '/update?user=test2&info={"ok":1}&roles=a,b,c',
                HTTP::Headers->new( 'Cookie' => $cookie, )
            )
        );
        $res = $cb->(
            HTTP::Request->new(
                'GET' => '/auth_session',
                HTTP::Headers->new( 'Cookie' => $cookie, )
            )
        );
        my $session = decode_json( $res->content );
        is_deeply $session->{auth}{info}, { email => 'test@test.com' },
            'info ok';
        is_deeply $session->{auth}{roles}, [qw/a x y z/], 'roles ok';

        $res    = $cb->( GET '/login?user=test2&password=test' );
        $cookie = $res->header('Set-Cookie')->as_string;
        $res    = $cb->(
            HTTP::Request->new(
                'GET' => '/auth_session',
                HTTP::Headers->new( 'Cookie' => $cookie, )
            )
        );
        my $other_session = decode_json( $res->content );
        is_deeply $other_session->{auth}{info}, { activated => 0, ok => 1 },
            'info ok';
        is_deeply $other_session->{auth}{roles}, [qw/a b c/], 'roles ok';
    };

    subtest 'users with role' => sub {
        my $res   = $cb->( GET '/users_with_role' );
        my $users = decode_json( $res->content );
        is_deeply $users, [], 'role params missing';

        $res   = $cb->( GET '/users_with_role?role=admin' );
        $users = decode_json( $res->content );
        is_deeply $users, [], 'no admin';

        $res   = $cb->( GET '/users_with_role?role=a' );
        $users = decode_json( $res->content );
        is_deeply $users, [qw/test test2/], 'test and test2 has the role a';

        $res   = $cb->( GET '/users_with_role?role=b' );
        $users = decode_json( $res->content );
        is_deeply $users, [qw/test2/], 'test2 has the role b';

        $res   = $cb->( GET '/users_with_role?role=x' );
        $users = decode_json( $res->content );
        is_deeply $users, [qw/test/], 'test has the role x';

        $res   = $cb->( GET '/users_with_role?role=miss' );
        $users = decode_json( $res->content );
        is_deeply $users, [], 'no one has the role miss';

    };

    subtest "users count" => sub {
        my $res = $cb->( GET '/users_count' );
        is $res->content, 2, '2 users found';
    };

    subtest "users" => sub {
        my $res   = $cb->( GET '/users' );
        my $users = decode_json( $res->content );
        is @$users, 2, '2 users info';
        is_deeply [ map { $_->{user} } @$users ], [qw/test test2/],
            'test and test2 found';

        $res   = $cb->( GET '/users?users=a,b,c' );
        $users = decode_json( $res->content );
        is @$users, 0, 'no user a or b or c found';

        $res   = $cb->( GET '/users?users=test,a,b,c' );
        $users = decode_json( $res->content );
        is @$users, 1, 'test only was found';
        is_deeply [ map { $_->{user} } @$users ], [qw/test/], 'test found';
    };

    subtest "signout" => sub {
        my $res  = $cb->( GET '/signout' );
        my $resp = decode_json( $res->content );
        is_deeply $resp, { status => 'ko', missing => ['user'] },
            'missing user';

        $res  = $cb->( GET '/signout?user=test3' );
        $resp = decode_json( $res->content );
        is_deeply $resp, { status => 'ko', error_msg => 'user not found' },
            'test3 doesnt exists';

        $res  = $cb->( GET '/signout?user=test2' );
        $resp = decode_json( $res->content );
        is_deeply $resp, { status => 'ok' }, 'test2 destroy';

        $res = $cb->( GET '/users' );
        my $users = decode_json( $res->content );
        is @$users, 1, '1 user left';
        is_deeply [ map { $_->{user} } @$users ], [qw/test/],
            'test only was found';
    };

};
done_testing;
