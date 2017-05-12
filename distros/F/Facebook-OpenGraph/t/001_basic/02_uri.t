use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;

subtest 'beta' => sub {
    my $fb = Facebook::OpenGraph->new(+{
        is_beta => 1
    });

    subtest 'uri' => sub {
        my $uri = $fb->uri;
        is $uri->scheme, 'https', 'scheme';
        is $uri->host, 'graph.beta.facebook.com', 'host';
        is $uri->path, '/', 'path';
    };

    subtest 'uri w/ path' => sub {
        my $uri = $fb->uri('/foo');
        is $uri->path, '/foo', 'path';
    };

    subtest 'uri w/ path and query parameter' => sub {
        my $uri = $fb->uri('/foo/bar', +{howdy => 'yall'});
        is $uri->path, '/foo/bar', 'path';
        is_deeply +{$uri->query_form}, +{howdy => 'yall'}, 'query parameter';
    };
};

subtest 'production' => sub {
    my $fb = Facebook::OpenGraph->new;
    subtest 'uri' => sub {
        my $uri = $fb->uri;
        is $uri->scheme, 'https', 'scheme';
        is $uri->host, 'graph.facebook.com', 'production uri';
        is $uri->path, '/', 'path';
    };
    
    subtest 'uri w/ path' => sub {
        my $uri = $fb->uri('/foo');
        is $uri->path, '/foo', 'path';
    };

    subtest 'uri w/ path and query parameter' => sub {
        my $uri = $fb->uri('/foo/bar', +{howdy => 'yall'});
        is $uri->path, '/foo/bar', 'path';
        is_deeply +{$uri->query_form}, +{howdy => 'yall'}, 'query parameter';
    };
};

done_testing;
