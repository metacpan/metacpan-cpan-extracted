#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Dist::Zilla::Plugin::Docker::API::Client;

# The engine's tag endpoint takes the repository and the tag as two separate
# parameters (POST /images/{name}/tag?repo=&tag=). Handing it a full image
# reference as `repo` and no `tag` makes the engine append its own default:
# podman turns `example/app:1.0` into `example/app:1.0:latest` and answers 500.
# The result was that every version tag silently failed while the build log
# still claimed the image had been tagged.

{
    package FakeImages;
    sub new {
        my ($class, %arg) = @_;
        return bless { calls => [], fail => $arg{fail} }, $class;
    }
    sub build {
        return [ { aux => { ID => 'sha256:abc123' } } ];
    }
    sub tag {
        my ($self, $name, %opts) = @_;
        push @{ $self->{calls} }, { name => $name, %opts };
        die "engine refused the reference\n" if $self->{fail};
        return 1;
    }
}

{
    package FakeDocker;
    sub new {
        my ($class, %arg) = @_;
        return bless { images => $arg{images} }, $class;
    }
    sub images { return $_[0]->{images} }
}

sub client_for {
    my (%arg) = @_;
    my $images = FakeImages->new(fail => $arg{fail});
    my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
        docker       => FakeDocker->new(images => $images),
        logger       => sub { push @{ $arg{log} }, $_[0] if $arg{log} },
        logger_fatal => sub { die $_[0] },
    );
    return ($client, $images);
}

subtest 'the tag is passed separately from the repository' => sub {
    my ($client, $images) = client_for();

    $client->build_image(
        context_tar => 'tarball',
        tags        => [ 'ghcr.io/example/app:latest', 'ghcr.io/example/app:1.0' ],
    );

    is scalar @{ $images->{calls} }, 1, 'one tag call for the second reference';
    my $call = $images->{calls}[0];
    is $call->{name}, 'sha256:abc123',          'tagged by image id';
    is $call->{repo}, 'ghcr.io/example/app',    'repo carries no tag component';
    is $call->{tag},  '1.0',                    'tag passed as its own parameter';
};

subtest 'a registry port is not mistaken for the tag separator' => sub {
    my ($client, $images) = client_for();

    $client->build_image(
        context_tar => 'tarball',
        tags        => [ 'first:latest', 'registry.example.com:5000/team/app:2.1' ],
    );

    my $call = $images->{calls}[0];
    is $call->{repo}, 'registry.example.com:5000/team/app', 'host:port stays in the repo';
    is $call->{tag},  '2.1',                                'only the trailing tag is split off';
};

subtest 'a reference without a tag sends no tag parameter' => sub {
    my ($client, $images) = client_for();

    $client->build_image(
        context_tar => 'tarball',
        tags        => [ 'first:latest', 'registry.example.com:5000/team/app' ],
    );

    my $call = $images->{calls}[0];
    is $call->{repo}, 'registry.example.com:5000/team/app', 'whole reference is the repo';
    ok !exists $call->{tag}, 'no tag parameter, so the engine keeps its own default';
};

# The second half of the same bug: the tag was recorded as processed whether
# or not the engine accepted it, so the plugin reported "Tagged: ..." for tags
# that do not exist. The warning scrolls past in a long build log; the success
# line is the one that gets read.
subtest 'a rejected tag is not reported as processed' => sub {
    my @log;
    my ($client, $images) = client_for(fail => 1, log => \@log);

    my $result = $client->build_image(
        context_tar => 'tarball',
        tags        => [ 'ghcr.io/example/app:latest', 'ghcr.io/example/app:1.0' ],
    );

    is_deeply $result->tags, [], 'the rejected tag is absent from the result';
    ok scalar(grep { /failed to tag/ } @log), 'the failure is logged';
};

done_testing;
