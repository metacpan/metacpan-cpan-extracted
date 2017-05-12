use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use Test::Exception;
use JSON 2 qw(encode_json);
use Facebook::OpenGraph;

subtest 'w/o appsecret_proof' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            is $args{appsecret_proof}, undef, 'appsecret_proof not given';
    
            return (
                1,
                400,
                'Bad Request',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{
                    error => +{
                        code          => 100,
                        type          => 'GraphMethodException',
                        message       => 'API calls from the server require an appsecret_proof argument',
                        error_subcode => '',
                    },
                }),
            );

        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        access_token        => 'qwerty',
        use_appsecret_proof => 0,
    });

    throws_ok(
        sub {
            my $user = $fb->get('/me');
        },
        qr/100:- GraphMethodException:API calls from the server require an appsecret_proof argument/,
        'appsecret_proof is required',
    );

};

subtest 'w/ appsecret_proof' => sub {
    
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
            my ($self, %args) = @_;
            my $uri  = $args{url};
            my $query_ref = +{$uri->query_form};
            is $query_ref->{appsecret_proof}, '94a4877c83fbc2e1a0b182b3927a1f90dbf3f6e0e35513448a50c72aa49a12f4', 'appsecret_proof';
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json($datum_ref),
            );
        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        access_token        => 'qwerty',
        use_appsecret_proof => 1,
        secret              => 'TheKingHasEarsShapedLikeADonkey',
    });
    my $user = $fb->get('/me');
    
    is_deeply $datum_ref, $user, 'datum';
};


done_testing;
