use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use JSON 2 qw(encode_json);
use Facebook::OpenGraph;
eval "use YAML qw(LoadFile)";
plan skip_all => "YAML is not installed." if $@;
    
subtest 'field expansion' => sub {

    my $val = +{
        email   => 'foo_bar_buzz@tfbnw.net',
        name    => 'Linda Amdgjheicghf Laustein',
        id      => '12345678',
        albums  => +{
            data => [
                +{
                    created_time  => '2012-11-20T10:35:36+0000',
                    name          => 'test album',
                    id            => '111111111111111',
                    photos        => +{
                        data => [
                            +{
                                created_time => '2012-11-20T10:35:41+0000',
                                name         => 'abc',
                                id           => 123456,
                                picture      => 'http://photos-a.ak.fbcdn.net/hphotos-ak-ash4/123456_s.jpg',
                                tags         => +{
                                    paging => +{
                                        next => 'https://graph.facebook.com/12345678/tags?limit=2&offset=2',
                                    },
                                    data   => [
                                        +{
                                            y            => '50.42735042735',
                                            created_time => '2012-11-20T10:36:55+0000',
                                            name         => '100004657083353',
                                            x            => '74.137931034483'
                                        },
                                        +{
                                            y            => '33.333333333333',
                                            created_time => '2012-11-20T10:36:37+0000',
                                            name         => '100004691462769',
                                            x            => '47.931034482759'
                                        },
                                    ],
                                },
                            },
                            +{
                                created_time => '2012-11-20T10:35:41+0000',
                                name         => 'def',
                                id           => 23456,
                                picture      => 'http://photos-h.ak.fbcdn.net/hphotos-ak-prn1/23456_s.jpg',
                                tags         => +{
                                    paging => +{
                                        next => 'https://graph.facebook.com/12345678/tags?limit=2&offset=2'
                                    },
                                    data   => [
                                        +{
                                            y            => '37.142857142857',
                                            created_time => '2012-11-20T10:36:50+0000',
                                            name         => '100004657083353',
                                            x            => '44.137931034483'
                                        },
                                    ],
                                },
                            },
                            +{
                                created_time => '2012-11-20T10:35:41+0000',
                                id           => 34567,
                                picture      => 'http://photos-g.ak.fbcdn.net/hphotos-ak-ash3/34567_s.jpg'
                            },
                        ],
                    },
                },
            ],
        }
    };

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;

            delete $args{url}; # tested in t/001_basic/07_field_expansion.t

            is_deeply(
                \%args,
                +{
                    headers => ['Authorization' => 'OAuth qwerty'],
                    content => '',
                    method  => 'GET',
                },
                'args'
            );
    
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json($val),
            );
        },
    );
    
    my $fb = Facebook::OpenGraph->new(+{
        access_token => 'qwerty',
    });
    my $fields = LoadFile('t/resource/fields.yaml');
    my $user   = $fb->fetch('me',  +{fields => $fields});

    is_deeply $user, $val, 'user';

};

subtest 'w/ other params' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            my $uri   = $args{url};
            my %query = $uri->query_form;
            is $query{locale}, 'ja_JP', 'locale';
            ok $query{fields}, 'fields';
    
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json({data => 'dummy'}),
            );
        },
    );

    my $fb     = Facebook::OpenGraph->new;
    my $fields = LoadFile('t/resource/fields.yaml');
    my $user   = $fb->fetch('/me', +{fields => $fields, locale => 'ja_JP'});

};

done_testing;
