#!perl
#
# This file is part of Jedi-Plugin-Session
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
use Jedi;
use Test::File::ShareDir -share =>
    { -dist => { 'Jedi-Plugin-Session' => 'share' } };

my @tests;

BEGIN {
    push @tests, qw/t::lib::session/;
    if ( eval { use_module('Redis')->new; 1 } ) {
        push @tests, qw/t::lib::session_redis/;
    }
    else {
        diag "Redis not found, skipping redis tests";
    }
    push @tests, qw/t::lib::session_sqlite/;
}

for my $test (@tests) {
    note "Testing $test";

    my $jedi
        = Jedi->new(
        config => { $test => { session => { expiration => '2 seconds', } } }
        );
    $jedi->road( '/'    => $test );
    $jedi->road( '/sub' => $test );

    test_psgi $jedi->start, sub {
        my $cb = shift;
        {
            my $res = $cb->( GET '/uuid' );
            is $res->code, 200, 'status ok';
            my $cookie = $res->headers->header('set-cookie');
            like $cookie, qr{jedi_session=.{12};}, 'cookie ok';
            is length( $res->content ), 27, '... and also the content';
        }
        {
            my $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/uuid',
                    HTTP::Headers->new(
                        'Cookie' => 'jedi_session=123456789012;'
                    )
                )
            );
            my $content = $res->content;
            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/uuid',
                    HTTP::Headers->new(
                        'Cookie' => 'jedi_session=123456789012;'
                    )
                )
            );
            is $res->content, $content, 'content still the same';
            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/uuid',
                    HTTP::Headers->new(
                        'Cookie' => 'jedi_session=123456789013;'
                    )
                )
            );
            ok $res->content ne $content,
                'content change with another session';

            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/uuid',
                    HTTP::Headers->new(
                        'Cookie'          => 'jedi_session=123456789012;',
                        'X_FORWARDED_FOR' => '11.0.0.1',
                    )
                )
            );
            ok $res->content ne $content, 'content change with different ip';
            $content = $res->content;

            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/uuid',
                    HTTP::Headers->new(
                        'Cookie'          => 'jedi_session=123456789012;',
                        'X_FORWARDED_FOR' => '11.0.0.1',
                    )
                )
            );
            is $res->content, $content, 'uuid is the same for the same ip';
        }

        {
            my $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/set',
                    HTTP::Headers->new(
                        'Cookie' => 'jedi_session=123456789014;'
                    )
                )
            );
            is $res->content, 'ko', 'nothing to set';

            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/set?k=a',
                    HTTP::Headers->new(
                        'Cookie' => 'jedi_session=123456789014;'
                    )
                )
            );
            is $res->content, 'ok', 'value set to undef';

            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/set?k=a&v=1',
                    HTTP::Headers->new(
                        'Cookie' => 'jedi_session=123456789014;'
                    )
                )
            );
            is $res->content, 'ok', 'value set to 1';

            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/set?k=a&v=2',
                    HTTP::Headers->new(
                        'Cookie' => 'jedi_session=123456789014;'
                    )
                )
            );
            is $res->content, 'ok', 'value set to 2';

            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/sub/set?k=a&v=3',
                    HTTP::Headers->new(
                        'Cookie' => 'jedi_session=123456789014;'
                    )
                )
            );
            is $res->content, 'ok', 'sub value set to 3';

            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/get?k=a',
                    HTTP::Headers->new(
                        'Cookie' => 'jedi_session=123456789014;'
                    )
                )
            );
            is $res->content, '2', 'value get is 2';

            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/sub/get?k=a',
                    HTTP::Headers->new(
                        'Cookie' => 'jedi_session=123456789014;'
                    )
                )
            );
            is $res->content, '3', 'value get is 3';

            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/get?k=a',
                    HTTP::Headers->new(
                        'Cookie'          => 'jedi_session=123456789014;',
                        'X_FORWARDED_FOR' => '11.0.0.1',
                    )
                )
            );
            is $res->content, 'undef', 'another user, same session, diff ip';

            diag "Expiration $test : Waiting 3 s ...";
            sleep(3);
            $res = $cb->(
                HTTP::Request->new(
                    'GET' => '/sub/get?k=a',
                    HTTP::Headers->new(
                        'Cookie' => 'jedi_session=123456789014;'
                    )
                )
            );
            is $res->content, 'undef', 'value has expired';

        }
    };

}
done_testing;
