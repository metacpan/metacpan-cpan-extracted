#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Dist::Zilla::Plugin::Docker::API::Client;

my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
    logger       => sub { },
    logger_fatal => sub { die @_ },
);

# Lines that should be recognised as step headers.
my @headers = (
    'Step 1/18 : FROM ubuntu:22.04',
    'Step 12/12 : CMD ["app"]',
    '#5 [4/12] RUN apt-get update',
    '#7 [builder 3/8] COPY . .',
    '#23 [stage-2 1/4] WORKDIR /app',
    # Podman classic builder: uppercase STEP, colon attached to the count.
    # Captured from a live rootless Podman 5.4.2 build stream.
    'STEP 1/2: FROM docker.io/library/perl:5.42',
    'STEP 2/2: RUN exit 7',
);

# Lines that should be skipped (everything else from the build output).
my @noise = (
    ' ---> Running in 9c1f9e2d6f0a',
    ' ---> a3b1c5d7e2f4',
    'Removing intermediate container 9c1f9e2d6f0a',
    'Successfully built a3b1c5d7e2f4',
    'Successfully tagged myapp:latest',
    '+ apt-get update',
    'Get:1 http://archive.ubuntu.com/ubuntu jammy InRelease [270 kB]',
    'Reading package lists...',
    '#5 0.234 Hit:1 http://deb.debian.org/debian bookworm InRelease',
    'Sending build context to Docker daemon  2.048kB',
    # Podman classic builder noise, from the same live stream.
    'COMMIT',
    '--> 5dd8b58474ea',
    'marker-step-two',
    'Successfully built 5dd8b58474ea',
    '',
);

for my $line (@headers) {
    ok($client->_is_build_step_header($line), "header: $line");
}

for my $line (@noise) {
    ok(!$client->_is_build_step_header($line), "noise: $line");
}

# Regression: stream chunks from the Docker daemon arrive with trailing
# newlines, and the Dist::Zilla logger adds its own. _extract_build_lines
# must emit chomped lines so we don't get double-newlines in the output.
{
    my $buf = '';
    my @lines = $client->_extract_build_lines(\$buf, "Step 1/3 : FROM scratch\n", 1);
    is_deeply(\@lines, ['Step 1/3 : FROM scratch'], 'verbose: trailing \n stripped');
    is($buf, '', 'verbose: buffer drained');
}

# Multiple lines arriving in a single chunk must each be emitted chomped.
{
    my $buf = '';
    my @lines = $client->_extract_build_lines(
        \$buf,
        "Step 1/3 : FROM scratch\n ---> abc123\nStep 2/3 : ENV X=Y\n",
        1,
    );
    is_deeply(
        \@lines,
        ['Step 1/3 : FROM scratch', ' ---> abc123', 'Step 2/3 : ENV X=Y'],
        'verbose: multi-line chunk split into chomped lines',
    );
}

# Partial line buffered until the closing newline arrives.
{
    my $buf = '';
    my @first = $client->_extract_build_lines(\$buf, "Step 1/3 : FROM ", 1);
    is_deeply(\@first, [], 'verbose: incomplete line withheld');
    is($buf, 'Step 1/3 : FROM ', 'verbose: partial chunk buffered');

    my @second = $client->_extract_build_lines(\$buf, "scratch\n", 1);
    is_deeply(\@second, ['Step 1/3 : FROM scratch'], 'verbose: line emitted once newline arrives');
}

# Concise mode: only step headers survive, and they're chomped.
{
    my $buf = '';
    my @lines = $client->_extract_build_lines(
        \$buf,
        "Step 1/3 : FROM scratch\n ---> abc123\nRemoving intermediate container\nStep 2/3 : ENV X=Y\n",
        0,
    );
    is_deeply(
        \@lines,
        ['Step 1/3 : FROM scratch', 'Step 2/3 : ENV X=Y'],
        'concise: only headers, chomped',
    );
}

done_testing;
