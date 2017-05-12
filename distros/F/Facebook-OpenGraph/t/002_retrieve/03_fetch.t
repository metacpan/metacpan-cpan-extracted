use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Mock::Furl;
use Facebook::OpenGraph;
use JSON 2 qw(encode_json);

subtest 'user' => sub {

    my $datum_ref = +{
        name       => 'Mark Zuckerberg', # full name
        id         => 4, # id 1-3 were test users
        locale     => 'en_US', # string containing the ISO Language Code and ISO Country Code
        last_name  => 'Zuckerberg',
        username   => 'zuck',
        first_name => 'Mark',
        gender     => 'male', # male or female. no other "politically correct" value :-(
        link       => 'http://www.facebook.com/zuck',
    };

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            is_deeply(
                \%args,
                +{
                    headers => [],
                    url     => 'https://graph.facebook.com/zuck',
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
                encode_json($datum_ref),
            );
        },
    );

    my $fb = Facebook::OpenGraph->new;
    my $user = $fb->fetch('zuck');

    is_deeply $datum_ref, $user, 'datum';

};

subtest 'with fields' => sub {
                
    my $datum_ref = +{
        id      => 4, # id is always returned even if it's not specified in fields parameter
        picture => +{ # returns is_silhouette and url after October 2012 Breaking Changes
            data => +{
                is_silhouette => 'false',
                url           => 'http://profile.ak.fbcdn.net/hprofile-ak-prn1/157340_4_3955636_q.jpg',
            },
        },
    };
    
    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;

            is_deeply(
                \%args,
                +{
                    headers => [],
                    url     => 'https://graph.facebook.com/zuck?fields=picture',
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
                encode_json($datum_ref),
            );
        },
    );
        
    my $fb   = Facebook::OpenGraph->new;
    my $user = $fb->fetch('zuck', +{fields => 'picture'});

    is_deeply $datum_ref, $user, 'datum';

};

subtest 'not found' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            return (
                1,
                404,
                'Not Found',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{
                    error => +{
                        code    => 803,
                        type    => 'OAuthException',
                        message => '(#803) Some of the aliases you requested do not exist: hhhhhhhhhhsssssssss',
                        error_subcode => '',
                    },
                }),
            );

        },
    );
        
    my $fb = Facebook::OpenGraph->new;
    throws_ok(
        sub {
            my $user = $fb->fetch('hhhhhhhhhhsssssssss');
        },
        qr/803:- OAuthException:\(#803\) Some of the aliases you requested do not exist: hhhhhhhhhhsssssssss/,
        'user not found',
    );

};

done_testing;
