use strict;
use warnings;
use Test::More;
use Dist::Zilla::Plugin::Docker::API::Result;

subtest 'basic result' => sub {
    my $result = Dist::Zilla::Plugin::Docker::API::Result->new(
        image_id => 'sha256:abc123',
        tags     => ['ghcr.io/example/my-app:latest'],
        pushed   => ['ghcr.io/example/my-app:latest'],
    );

    is($result->image_id, 'sha256:abc123');
    is_deeply($result->tags, ['ghcr.io/example/my-app:latest']);
    is_deeply($result->pushed, ['ghcr.io/example/my-app:latest']);
    is($result->digest, undef);
    is_deeply($result->warnings, []);
};

subtest 'result with digest' => sub {
    my $result = Dist::Zilla::Plugin::Docker::API::Result->new(
        image_id => 'sha256:abc123',
        tags     => ['ghcr.io/example/my-app:v1.0'],
        pushed   => ['ghcr.io/example/my-app:v1.0'],
        digest   => 'sha256:def456...',
        warnings => ['some warning'],
    );

    is($result->digest, 'sha256:def456...');
    is_deeply($result->warnings, ['some warning']);
};

done_testing;