#!perl
#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use Test::Most 'die';
use HTTP::Request::Common;
use Plack::Test;
use Jedi;

{
    my $jedi = Jedi->new();
    $jedi->road( '/', 't::lib::advanced' );

    test_psgi $jedi->start, sub {
        my $cb = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code,    200,             'status root is correct';
            is $res->content, 'Hello World !', '... and content is correct';
        }
        {
            my $res = $cb->( GET '/test/me/hello_aaa_world' );
            is $res->code,    200,   'status regexp is correct';
            is $res->content, 'aaa', '... and content is correct';
        }
        {
            my $res = $cb->( GET '/test/me/hello_aaaa_world' );
            is $res->code,    200,        'status regexp is correct';
            is $res->content, 'aaa,aaaa', '... and content is correct';
        }
    };
}

{
    my $bad_method = Jedi->new();
    eval { $bad_method->road( '/', 't::lib::BadRoute::BadMethod' ) };
    like $@, qr{method invalid : only support GET/POST/PUT/DELETE !},
        'method invalid';
}
{
    my $bad_method = Jedi->new();
    eval { $bad_method->road( '/', 't::lib::BadRoute::BadPath' ) };
    like $@, qr{path invalid !}, 'path invalid';
}
{
    my $bad_method = Jedi->new();
    eval { $bad_method->road( '/', 't::lib::BadRoute::BadSub' ) };
    like $@, qr{sub invalid !}, 'sub invalid';
}

{
    my $bad_method = Jedi->new();
    eval { $bad_method->road( '/', 't::lib::BadRoute::BadMissing' ) };
    like $@, qr{sub invalid !}, 'sub invalid';
}

{
    my $jedi = Jedi->new();
    $jedi->road( '/', 't::lib::missing' );

    test_psgi $jedi->start, sub {
        my $cb = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code,    200,             'route is correct';
            is $res->content, 'hello world !', '... and content also';
        }
        for my $p (
            qw{
            /test
            /test/me
            /test/me?a=1
            }
            )
        {
            my $r = $p;
            $r =~ s/\?.*//;
            $r .= '/';

            {
                my $res = $cb->( GET $p);
                is $res->code, 200, 'missing status is correct';
                is $res->content, 'missing : ' . $r,
                    '... and also the content';
            }

            {
                my $res = $cb->( HTTP::Request->new( 'UNK', $p ) );
                is $res->code, 200, 'missing status is correct';
                is $res->content, 'missing : ' . $r,
                    '... and also the content';
            }

        }
    };
}

{
    my $jedi = Jedi->new;
    $jedi->road( '/', 't::lib::stop' );
    test_psgi $jedi->start, sub {
        my ($cb) = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code,    302, 'route is correct';
            is $res->content, '',  '... and no body set';
            is $res->header('Location'), 'http://blog.celogeek.com',
                '... and redirect init';
        }
        }
}

{
    my $jedi = Jedi->new;
    $jedi->road( '/', 't::lib::othermethod' );
    test_psgi $jedi->start, sub {
        my ($cb) = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code,    200,   'route is correct';
            is $res->content, 'GET', '... and no body set';
        }
        {
            my $res = $cb->( POST '/' );
            is $res->code,    200,    'route is correct';
            is $res->content, 'POST', '... and no body set';
        }
        {
            my $res = $cb->( PUT '/' );
            is $res->code,    200,   'route is correct';
            is $res->content, 'PUT', '... and no body set';
        }
        {
            my $res = $cb->( HTTP::Request->new( 'DELETE', '/' ) );
            is $res->code,    200,      'route is correct';
            is $res->content, 'DELETE', '... and no body set';
        }
        }

}

{
    my $jedi = Jedi->new;
    $jedi->road( '/', 't::lib::multipleheaders' );
    test_psgi $jedi->start, sub {
        my ($cb) = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code,    200,  'route is correct';
            is $res->content, 'OK', '... and body set';
            my @h = $res->header('test');
            is_deeply \@h, [ 1, 2 ], '... and headers is correct';
        }
        }
}

{
    my $jedi = Jedi->new;
    $jedi->road( '/', 't::lib::err404' );
    test_psgi $jedi->start, sub {
        my ($cb) = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code,    404,      'route is correct';
            is $res->content, 'err404', '... and body set';
        }
        }
}

{
    my $jedi = Jedi->new;
    $jedi->road( '/', 't::lib::config' );
    test_psgi $jedi->start, sub {
        my ($cb) = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code,    200,      'route is correct';
            is $res->content, 'noconf', '... and body set';
        }
    };

    $jedi->config->{myconf} = 'ok';
    test_psgi $jedi->start, sub {
        my ($cb) = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code,    200,  'route is correct';
            is $res->content, 'ok', '... and body set';
        }
    };

}

{
    my $jedi = Jedi->new( config => { myconf => 'ok again' } );
    $jedi->road( '/', 't::lib::config' );
    test_psgi $jedi->start, sub {
        my ($cb) = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code,    200,        'route is correct';
            is $res->content, 'ok again', '... and body set';
        }
    };
}

{
    my $jedi = Jedi->new();
    $jedi->road( '/', 't::lib::hostip' );
    test_psgi $jedi->start, sub {
        my ($cb) = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code, 200, 'route is correct';
            is $res->content, $jedi->host_ip, '... and body set';
        }
    };
}

done_testing;
