use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Mock::Furl;
use JSON 2 qw(decode_json encode_json);
use Facebook::OpenGraph;

subtest 'w/o token' => sub {

        my $fb = Facebook::OpenGraph->new;
        my $batch_queries = [
            +{method => 'GET', relative_url => 'zuck'},
            +{method => 'GET', relative_url => 'oklahomer.docs'},
        ];
        throws_ok sub { $fb->batch($batch_queries); }, qr/Top level access_token must be set/, 'exception';

};

subtest 'w/ valid token' => sub {

    my $zuck = +{
        link       => 'http://www.facebook.com/zuck',
        name       => 'Mark Zuckerberg',
        locale     => 'en_US',
        username   => 'zuck',
        id         => 4,
        first_name => 'Mark',
        last_name  => 'Zuckerberg',
        gender     => 'male',
    };
    my $oklahomer = +{
        link => 'http://www.facebook.com/oklahomer.docs',
        website => 'http://facebook-docs.oklahome.net/',
        release_date => '2011-02-24',
        name => 'Oklahomer',
        description => 'Facebook etc....',
        username => 'oklahomer.docs',
        talking_about_count => 10390,
        cover => {
            source => 'http://sphotos-g.ak.fbcdn.net/hphotos-ak-snc6/s720x720/283711_500726406609334_431792850_n.jpg',
            offset_y => 57,
            cover_id => '500726406609334',
        },
        is_published => 'true',
        category => 'Reference website',
        about => 'http://facebook-docs.oklahome.net/',
        id    => '204277149587596',
        likes => 10126,
    };

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            is_deeply(
                decode_json(delete $args{content}->{batch}),
                [
                    +{
                        method       => 'GET',
                        relative_url => 'zuck',
                    },
                    +{
                        method       => 'GET',
                        relative_url => 'oklahomer.docs',
                    },
                ],
                'batch'
            );
            is_deeply(
                \%args,
                +{
                    url     => 'https://graph.facebook.com/',
                    method  => 'POST',
                    headers => ['Authorization' => 'OAuth 123456789|XfSeFWB-0EQ0qyipMdmNpJEAuPk'],
                    content => +{
                        access_token => '123456789|XfSeFWB-0EQ0qyipMdmNpJEAuPk',
                    },
                },
                'args'
            );
    
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json([
                    +{
                        code => 200,
                        headers => [
                            +{
                                name  => "Access-Control-Allow-Origin",
                                value => "*"
                            },
                            +{
                                name  => "Cache-Control",
                                value => 'private, no-cache, no-store, must-revalidate'
                            },
                            +{
                                name  => "Connection",
                                value => "close"
                            },
                            +{
                                name => "Content-Type",
                                value => "text/javascript; charset=UTF-8"
                            },
                            +{
                                name => "ETag",
                                value => "539feb8a445c3d20a2ebacd02db380b27243b255"
                            },
                            +{
                                name => "Expires",
                                value => "Sat, 01 Jan 2000 00:00:00 GMT"
                            },
                            +{
                                name => "Pragma",
                                value => "no-cache"
                            }
                        ],
                        body => encode_json($zuck),
                    },
                    {
                        code => 200,
                        headers => [
                            +{
                                name => "Access-Control-Allow-Origin",
                                value => "*"
                            },
                            +{
                                name => "Cache-Control",
                                value => "private, no-cache, no-store, must-revalidate"
                            },
                            +{
                                name => "Connection",
                                value => "close"
                            },
                            +{
                                name => "Content-Type",
                                value => "text/javascript; charset=UTF-8"
                            },
                            +{
                                name => "ETag",
                                value => "2b6e34285cc05942f8ddd4f8abec7b66c6493184"
                            },
                            +{
                                name => "Expires",
                                value => "Sat, 01 Jan 2000 00:00:00 GMT"
                            },
                            +{
                                name => "Pragma",
                                value => "no-cache"
                            }
                        ],
                        body => encode_json($oklahomer),
                    }
                ]),
            );

        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        access_token => '123456789|XfSeFWB-0EQ0qyipMdmNpJEAuPk',
    });
    my $data_ref = $fb->batch([
        +{method => 'GET', relative_url => 'zuck'},
        +{method => 'GET', relative_url => 'oklahomer.docs'},
    ]);

    is_deeply(
        $data_ref,
        [
            $zuck,
            $oklahomer,
        ],
        'data',
    );
    
};

subtest 'check batch limit loop' => sub {
    my @profiles = (
        +{
            'link' => 'http://www.facebook.com/zuck',
            'name' => 'Mark Zuckerberg',
            'locale' => 'en_US',
            'username' => 'zuck',
            'last_name' => 'Zuckerberg',
            'id' => '4',
            'first_name' => 'Mark',
            'gender' => 'male'
        },
        +{
            'link' => 'http://www.facebook.com/oklahomer.docs',
            'website' => 'http://facebook-docs.oklahome.net/',
            'release_date' => '2011-02-24',
            'name' => 'Oklahomer',
            'description' => 'Support making the world more open and connected',
            'username' => 'oklahomer.docs',
            'talking_about_count' => 60,
            'cover' => +{
                'source' => 'http://sphotos-g.ak.fbcdn.net/hphotos-ak-snc6/s720x720/283711_500726406609334_431792850_n.jpg',
                'offset_y' => 57,
                'cover_id' => '500726406609334'
            },
            'is_published' => 'true',
            'were_here_count' => 0,
            'likes' => 1077,
            'id' => '204277149587596',
            'category' => 'Reference website',
            'about' => "Facebook技術者向けドキュメントの和訳/Tipsや、Facebook絡みのニュースを紹介しています。http://facebook-docs.oklahome.net/",
        },
        +{
            'quotes' => 'Life is tough, but so are we.',
            'link' => 'http://www.facebook.com/go.hagiwara',
            'sports' => [
                +{
                    'name' => 'Kendo',
                    'id' => '182697598412892'
                }
            ],
            'name' => "萩原 豪",
            'locale' => 'en_US',
            'favorite_athletes' => [
                +{
                    'name' => 'Bob Munden',
                    'id' => '163740905795'
                }
            ],
            'username' => 'go.hagiwara',
            'last_name' => "萩原",
            'inspirational_people' => [
                +{
                    'name' => 'Chris Ryan Books Fan Page',
                    'id' => '242519319104131'
                },
                +{
                    'name' => 'Tom Clancy',
                    'id' => '129687863720149'
                }
            ],
            'id' => '44007581',
            'gender' => 'male',
            'first_name' => "豪"
        },
        +{
            'link' => 'http://www.facebook.com/ChrisHughes',
            'name' => 'Chris Hughes',
            'locale' => 'en_US',
            'username' => 'ChrisHughes',
            'last_name' => 'Hughes',
            'id' => '5',
            'first_name' => 'Chris',
            'gender' => 'male'
        },
        +{
            'name' => 'Dustin Moskovitz',
            'locale' => 'en_US',
            'id' => '6',
            'gender' => 'male',
            'username' => 'moskov',
            'last_name' => 'Moskovitz',
            'first_name' => 'Dustin'
          },
        +{
            'website' => 'www.uco.edu www.twitter.com/UCOBronchos www.youtube.com/UCOBronchos',
            'mission' => 'The University of Central Oklahoma exists to help students learn by providing transformative education experiences to students so that they may become productive, creative, ethical and engaged citizens and leaders serving our global community. UCO contributes to the intellectual, cultural, economic and social advancement of the communities and individuals it serves.',
            'talking_about_count' => 244,
            'cover' => +{
                'source' => 'http://sphotos-b.ak.fbcdn.net/hphotos-ak-prn1/s720x720/150013_10151243228003995_1202542503_n.jpg',
                'offset_y' => 23,
                'cover_id' => '10151243228003995'
            },
            'founded' => '1890',
            'checkins' => 11464,
            'likes' => 22040,
            'id' => '19921173994',
            'category' => 'University',
            'about' => 'Make a smart investment in your future today by choosing to LIVE CENTRAL at the University of Central Oklahoma!  www.uco.edu twitter.com/UCOBronchos youtube.com/UCOBronchos',
            'link' => 'http://www.facebook.com/uco.bronchos',
            'parking' => +{
                'valet' => 0,
                'lot' => 1,
                'street' => 1
            },
                'location' => +{
                'country' => 'United States',
                'longitude' => '-97.471403630251',
                'zip' => '73034',
                'city' => 'Edmond',
                'latitude' => '35.656309529507',
                'street' => '100 N. University Dr.',
                'state' => 'OK'
            },
            'name' => 'The University of Central Oklahoma',
            'description' => "The University of Central Oklahoma prepares future leaders in an opportunity-rich environment, ideally located in the Oklahoma City metropolitan area. Central offers an innovative learning community where teaching comes first and students develop personal relationships with faculty and staff, like 2008 U.S. Professor of the Year, Dr. Wei Chen, who are committed to transforming lives. With 116 undergraduate majors and 55 graduate programs, Central is a smart investment for students dedicated to their future success. Notable academic programs include Forensic Science, Music Theatre, Mass Communications, Accounting, Jazz Studies and the Academy of Contemporary Music at UCO, located in downtown Oklahoma City\'s Bricktown district. Central\'s appealing 210-acre campus is on track to become a certified botanical garden, offering both a pleasing learning and living environment and a source of pride for students, employees and alumni. In fact, Central is ranked among the top universities nationally in residence life and as one of the top five universities to work for. Founded in 1890, Central is the state\'s first public institution of higher learning, and continues to cultivate creativity and innovation in every corner of campus, bringing to life its core values of Character, Community and Civility each day.",
            'phone' => '405-974-2000',
            'username' => 'uco.bronchos',
            'is_published' => 'true',
            'were_here_count' => 34415
        }
    );

    my $request_cnt = 0;
    my $start_cnt   = 0;
    my $fb = Facebook::OpenGraph->new(+{
        access_token => '123456789|XfSeFWB-0EQ0qyipMdmNpJEAuPk',
        batch_limit  => 2,
    });

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;
            $request_cnt++;
            my $end_cnt = $start_cnt + $fb->batch_limit - 1;
            my @profile_parts = @profiles[$start_cnt..$end_cnt];
            $start_cnt = $end_cnt + 1;
    
            my @returning_data;
            for my $profile (@profile_parts) {
                push @returning_data, +{
                    code => 200,
                    headers => [
                        +{
                            name  => "Access-Control-Allow-Origin",
                            value => "*"
                        },
                        +{
                            name  => "Cache-Control",
                            value => 'private, no-cache, no-store, must-revalidate'
                        },
                        +{
                            name  => "Connection",
                            value => "close"
                        },
                        +{
                            name => "Content-Type",
                            value => "text/javascript; charset=UTF-8"
                        },
                        +{
                            name => "ETag",
                            value => "539feb8a445c3d20a2ebacd02db380b27243b255"
                        },
                        +{
                            name => "Expires",
                            value => "Sat, 01 Jan 2000 00:00:00 GMT"
                        },
                        +{
                            name => "Pragma",
                            value => "no-cache"
                        }
                    ],
                    body => encode_json($profile),
                };
            }
    
            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(\@returning_data),
            );
        },
    );

    my $data_ref = $fb->batch([
        +{ method => 'GET', relative_url => 'zuck'           },
        +{ method => 'GET', relative_url => 'oklahomer.docs' },
        +{ method => 'GET', relative_url => 'go.hagiwara'    },
        +{ method => 'GET', relative_url => 'ChrisHughes'    },
        +{ method => 'GET', relative_url => 'moskov'         },
        +{ method => 'GET', relative_url => 'uco.bronchos'   },
    ]);

    is_deeply($data_ref, \@profiles, 'batch');

};

done_testing;
