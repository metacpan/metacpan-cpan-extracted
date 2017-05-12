use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;

subtest 'beta' => sub {
    my $fb = Facebook::OpenGraph->new(+{
        is_beta => 1,
    });
    
    subtest 'video_uri' => sub {
        my $uri = $fb->video_uri;
        is $uri->scheme, 'https', 'scheme';
        is $uri->host, 'graph-video.beta.facebook.com', 'host';
        is $uri->path, '/', 'path';
    };
    
    subtest 'video_uri w/ path' => sub {
        my $uri = $fb->video_uri('/bar');
        is $uri->path, '/bar', 'path';
    };

    subtest 'video_uri w/ path and query parameter' => sub {
        my $uri = $fb->video_uri('/foo/bar', +{ howdy => 'yall' });
        is $uri->path, '/foo/bar', 'path';
        is_deeply +{$uri->query_form}, +{howdy => 'yall'}, 'query parameter';
    };
};

subtest 'production' => sub {
    my $fb = Facebook::OpenGraph->new;

    subtest 'video_uri' => sub {
        my $uri = $fb->video_uri;
        is $uri->scheme, 'https', 'scheme';
        is $uri->host, 'graph-video.facebook.com', 'production uri for video post';
        is $uri->path, '/', 'path';
    };
    
    subtest 'video_uri w/ path' => sub {
        my $uri = $fb->video_uri('/bar');
        is $uri->path, '/bar', 'path';
    };

    subtest 'video_uri w/ path and query parameter' => sub {
        my $uri = $fb->video_uri('/foo/bar', +{ howdy => 'yall' });
        is $uri->path, '/foo/bar', 'path';
        is_deeply +{$uri->query_form}, +{howdy => 'yall'}, 'query parameter';
    };
};

done_testing;
