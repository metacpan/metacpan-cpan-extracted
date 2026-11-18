#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use API::Docker::Error::Stream;

use Dist::Zilla::Plugin::Docker::API::Client;

# push_image is above the seam: it calls $self->docker->images->push
# directly, so the Recorder fake (which replaces the whole client) cannot
# see any of this -- Client.pm has to be instantiated directly with a fake
# docker object, the same way t/45-image-ref-tagging.t and
# t/65-build-failure-stream.t fake docker->images/docker->images->build.
#
# API::Docker 0.004 croaks on a push failure instead of handing back an
# ARRAY of event hashes with an errorDetail entry. Against a real Docker
# daemon the croak is an API::Docker::Error::Stream (->events, the raw
# stream); on Podman it can be a plain error with no ->events at all.
# push_image is expected to catch either shape in its eval and report it
# through logger_fatal -- that catch, added when the old array-scan went
# dead, had no test before this one.

{
    package FakeImages;
    sub new {
        my ($class, %arg) = @_;
        return bless { calls => [], error => $arg{error}, result => $arg{result} // [] }, $class;
    }
    sub push {
        my ($self, $image_ref, %opts) = @_;
        push @{ $self->{calls} }, { image_ref => $image_ref, %opts };
        die $self->{error} if $self->{error};
        return $self->{result};
    }
}

{
    package FakeDocker;
    sub new {
        my ($class, %arg) = @_;
        return bless { images => $arg{images} }, $class;
    }
    sub images { $_[0]->{images} }
}

sub client_for {
    my (%arg) = @_;
    my @fatal;
    my $images = FakeImages->new(error => $arg{error}, result => $arg{result});
    my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
        docker       => FakeDocker->new(images => $images),
        logger       => sub { },
        # Collect rather than die: push_image is expected to catch the
        # croak from docker->images->push itself, so a die here would mask
        # whether that inner catch actually ran.
        logger_fatal => sub { push @fatal, join(' ', @_) },
    );
    return ($client, $images, \@fatal);
}

subtest 'a stream error with ->events reports the errorDetail message' => sub {
    my $err = API::Docker::Error::Stream->new(
        message => 'Docker API stream error (/images/app/push): denied: requested access to the resource is denied',
        events  => [
            { status => 'Pushing' },
            { errorDetail => { message => 'denied: requested access to the resource is denied' },
              error       => 'denied: requested access to the resource is denied' },
        ],
    );
    my ($client, $images, $fatal) = client_for(error => $err);

    $client->push_image(image_ref => 'ghcr.io/example/app:1.0', auth => undef);

    is scalar @$fatal, 1, 'logger_fatal was called exactly once';
    is $fatal->[0], 'Push error: denied: requested access to the resource is denied',
        'the errorDetail message was pulled out of ->events, not the stream error itself';
    is scalar @{ $images->{calls} }, 1, 'the push call reached the fake docker client';
};

subtest 'a plain exception without ->events falls back to the exception text' => sub {
    my ($client, $images, $fatal) = client_for(error => "engine unreachable: connection refused\n");

    $client->push_image(image_ref => 'ghcr.io/example/app:1.0', auth => undef);

    is scalar @$fatal, 1, 'logger_fatal was called exactly once';
    like $fatal->[0], qr/\APush error: engine unreachable: connection refused/,
        'the exception itself is reported when there is no ->events to extract from';
};

subtest 'a successful push does not call logger_fatal' => sub {
    my ($client, $images, $fatal) = client_for(result => []);

    $client->push_image(image_ref => 'ghcr.io/example/app:1.0', auth => undef);

    is scalar @$fatal, 0, 'no fatal on a clean push';
    is scalar @{ $images->{calls} }, 1, 'the push call still reached the fake';
};

done_testing;
