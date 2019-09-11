use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;
use JSON 2 qw(encode_json);
use Facebook::OpenGraph;

subtest 'post movie with Non-Resumable Uploading API' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;

            ok delete $args{content}, 'content'; # too huge to compare, so just check if it's given
            is_deeply(
                \%args,
                +{
                    url     => 'https://graph-video.facebook.com/me/videos',
                    method  => 'POST',
                    headers => [
                        'Authorization'  => 'OAuth 12345qwerty',
                        'Content-Length' => 289105,
                        'Content-Type'   => 'multipart/form-data; boundary=xYzZY',
                    ],
                },
                'args'
            );

            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{
                    id => 111111111,
                }),
            );

        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        app_id       => 12345678,
        access_token => '12345qwerty',
    });
    my $response = $fb->publish(
        '/me/videos',
        +{
            source      => './t/resource/IMG_6753.MOV',
            title       => 'domo-kun',
            description => 'found it @ walmart'
        }
    );

    is_deeply $response, +{ id => 111111111 }, 'response';

};

subtest 'start uploading with Resumable Uploading API' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;

            # The document does not clearly state what Content-Type to be used
            # on upload_phase of "start" and "finish."
            # https://developers.facebook.com/docs/graph-api/resumable-upload-api/
            # However the example with curl uses -F instead of -d.
            ok $args{content}, 'content';
            ok $args{content} =~ m/Content-Disposition: form-data; name="upload_phase"/s, 'upload_phase';
            ok $args{content} =~ m/Content-Disposition: form-data; name="file_size"/s, 'file_size';
            delete $args{content};

            is_deeply(
                \%args,
                +{
                    url     => 'https://graph-video.facebook.com/me/videos',
                    method  => 'POST',
                    headers => [
                        'Authorization'  => 'OAuth 12345qwerty',
                        'Content-Length' => 151,
                        'Content-Type'   => 'multipart/form-data; boundary=xYzZY',
                    ],
                },
                'args'
            );

            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{
                    upload_session_id => "1564747013773438",
                    video_id          => "1564747010440105",
                    start_offset      => "0",
                    end_offset        => "52428800",
                }),
            );

        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        app_id       => 12345678,
        access_token => '12345qwerty',
    });
    my $response = $fb->publish(
        '/me/videos',
        +{
            upload_phase => 'start',
            file_size    => 288828,
        }
    );

    is_deeply $response,
              +{
                upload_session_id => "1564747013773438",
                video_id          => "1564747010440105",
                start_offset      => "0",
                end_offset        => "52428800",
              },
              'response';

};

subtest 'transfer chunked file content with Resumable' => sub {

    $Mock_furl_http->mock(
        request => sub {
            my ($mock, %args) = @_;

            ok $args{content}, 'content';
            ok $args{content} =~ m/Content-Disposition: form-data; name="upload_phase"/s, 'upload_phase';
            ok $args{content} =~ m/Content-Disposition: form-data; name="start_offset"/s, 'start_offset';
            ok $args{content} =~ m/Content-Disposition: form-data; name="upload_session_id"/s, 'upload_session_id';
            ok $args{content} =~ m/Content-Disposition: form-data; name="video_file_chunk"/s, 'video_file_chunk';
            delete $args{content};

            is_deeply(
                \%args,
                +{
                    url     => 'https://graph-video.facebook.com/me/videos',
                    method  => 'POST',
                    headers => [
                        'Authorization'  => 'OAuth 12345qwerty',
                        'Content-Length' => 289193, # Original size of 289105 + misc form data
                        'Content-Type'   => 'multipart/form-data; boundary=xYzZY',
                    ],
                },
                'args'
            );

            return (
                1,
                200,
                'OK',
                ['Content-Type' => 'text/javascript; charset=UTF-8'],
                encode_json(+{
                    start_offset => "52428800",
                    end_offset   => "104857601",
                }),
            );

        },
    );

    my $fb = Facebook::OpenGraph->new(+{
        app_id       => 12345678,
        access_token => '12345qwerty',
    });
    my $response = $fb->publish(
        '/me/videos',
        +{
            upload_phase      => 'transfer',
            start_offset      => 0,
            upload_session_id => 1564747013773438,
            video_file_chunk  => './t/resource/IMG_6753.MOV',
        }
    );

    is_deeply $response,
              +{
                start_offset => "52428800",
                end_offset   => "104857601",
              },
              'response';

};

done_testing;
