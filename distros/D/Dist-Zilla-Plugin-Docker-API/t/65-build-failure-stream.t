#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use API::Docker::Error::Stream;
use Dist::Zilla::Plugin::Docker::API::Client;

# API::Docker 0.003 croaks on an errorDetail event before build_image's
# progress loop ever runs, so the build output that led up to the failure
# rides on the exception (`$err->events`) instead of through the loop. The
# client has to drain it from there, or a failed build logs nothing at all.

package Test::Images;
use Moo;
has error => (is => 'ro', required => 1);
sub build { die $_[0]->error }

package Test::Docker;
use Moo;
has images => (is => 'ro', required => 1);

package main;

my @events = (
    { stream => "Step 1/2 : FROM alpine:3\n" },
    { stream => " ---> 0123456789ab\n" },
    { stream => "Step 2/2 : RUN exit 7\n" },
    { errorDetail => { message => "building at STEP \"RUN exit 7\": exit status 7\n" },
      error       => "building at STEP \"RUN exit 7\": exit status 7\n" },
);

sub client_with {
    my ($error, %opt) = @_;
    my @log;
    my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
        logger       => sub { push @log, @_ },
        logger_fatal => sub { die "FATAL: @_\n" },
        docker       => Test::Docker->new(
            images => Test::Images->new(error => $error),
        ),
    );
    my $fatal = do {
        local $@;
        eval { $client->build_image(context_tar => 'tar bytes', tags => ['app:1.0'], %opt) };
        $@;
    };
    return (\@log, $fatal);
}

sub stream_error {
    return API::Docker::Error::Stream->new(
        message  => 'Docker API stream error (/build): building at STEP "RUN exit 7": exit status 7',
        events   => \@events,
        location => " at t/65-build-failure-stream.t line 0.\n",
    );
}

subtest 'verbose: every stream line before the failure is logged' => sub {
    my ($log, $fatal) = client_with(stream_error(), verbose => 1);
    is_deeply $log,
        ['Step 1/2 : FROM alpine:3', ' ---> 0123456789ab', 'Step 2/2 : RUN exit 7'],
        'the events carried by the exception were forwarded to the logger';
    like $fatal, qr/\AFATAL: Docker build failed: .*exit status 7/,
        'and the build is still fatal, with the engine reason';
    unlike $fatal, qr/Docker build error:/,
        'the errorDetail event is not forwarded as a second fatal';
};

subtest 'concise: only the step headers before the failure are logged' => sub {
    my ($log, $fatal) = client_with(stream_error(), verbose => 0);
    is_deeply $log, ['Step 1/2 : FROM alpine:3', 'Step 2/2 : RUN exit 7'],
        'the concise filter applies to the drained events too';
    like $fatal, qr/\AFATAL: Docker build failed: /, 'still fatal';
};

subtest 'a plain-string failure has no stream to drain' => sub {
    my ($log, $fatal) = client_with("connect: No such file or directory at x line 1.\n", verbose => 1);
    is_deeply $log, [], 'nothing logged, nothing to log';
    like $fatal, qr/\AFATAL: Docker build failed: connect: No such file/,
        'the plain croak is reported as before';
};

done_testing;
