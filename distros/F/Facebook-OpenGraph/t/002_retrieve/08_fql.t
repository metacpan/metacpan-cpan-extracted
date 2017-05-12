use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use URI;
use JSON 2 qw/encode_json/;
use Facebook::OpenGraph;

subtest 'user' => sub {

    my $app_id = 127497087322461;
    my $datum_ref = +{
        display_name => 'app',
        icon_url => 'http://photos-c.ak.fbcdn.net/photos-ak-snc7/v43/45/'.$app_id.'/app_2_'.$app_id.'_1287.gif',
    };
    my $query = 'SELECT display_name, icon_url FROM application WHERE app_id = '.$app_id;

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            my $uri = URI->new;
            $uri->query_form(+{q => $query});
            is_deeply(
                \%args,
                +{
                    headers => [],
                    url     => 'https://graph.facebook.com/fql?'.$uri->query,
                    method  => 'GET',
                    content => '',
                },
                'args'
            );
    
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{
                    data => [
                        $datum_ref,
                    ],
                }),
            );
        },
    );

    my $fb = Facebook::OpenGraph->new;
    my $res = $fb->fql($query);
    
    is_deeply $res->{data}, [$datum_ref], 'data';
    
};

done_testing;
