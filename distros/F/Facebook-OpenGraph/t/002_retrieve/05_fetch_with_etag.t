use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use Facebook::OpenGraph;
use JSON 2 qw(encode_json);

subtest 'etag' => sub {

    # beware of double quotation mark
    my $etag = '"539feb8aee5c3d20a2ebacd02db380b27243b255"';

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            is_deeply(
                \%args,
                +{
                    headers => ['IF-None-Match' => $etag],
                    method  => 'GET',
                    content => '',
                    url     => 'https://graph.facebook.com/zuck',
                },
                'args'
            );
    
            # Returns status:304 w/ empty content when object is not modified
            return ( 
                1,
                304,
                'Not Modified',
                ['Content-Type' => 'text/javascript; charset=UTF-8'], # text/javascript
                '',
            );
        },
    );

    my $fb = Facebook::OpenGraph->new;
    my $user = $fb->fetch_with_etag('zuck', +{}, $etag);

    is $user, undef, 'not modified';

};

subtest 'modified or invalid etag' => sub {

    my $datum_ref = +{
        id         => 4,
        name       => 'Mark Zuckerberg',
        locale     => 'en_US',
        last_name  => 'Zuckerberg',
        username   => 'zuck',
        first_name => 'Mark',
        gender     => 'male',
        link       => 'http://www.facebook.com/zuck',
    };
    my $etag = '539feb8aee5c3d20a2ebacd02db380b27243b255';

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            is_deeply(
                \%args,
                +{
                    headers => ['IF-None-Match' => $etag],
                    method  => 'GET',
                    content => '',
                    url     => 'https://graph.facebook.com/zuck',
                },
                'args'
            );
    
            # Return values with status:200 when Open Graph object is modified
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
    my $user = $fb->fetch_with_etag('zuck', +{}, $etag);

    is_deeply $user, $datum_ref, 'datum';

};

done_testing;
