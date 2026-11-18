#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use JSON::MaybeXS qw( encode_json );
use MIME::Base64 qw( encode_base64 );

use Dist::Zilla::Plugin::Docker::API::Client;

# Below the seam: exercise remote_tag_exists / verify_auth_for_image_ref
# directly against fake docker->distribution / docker->system objects, the
# same way t/45-image-ref-tagging.t fakes docker->images. A Recorder-driven
# test cannot see any of this -- the Recorder replaces the whole client.

{
    package FakeDistribution;
    sub new {
        my ($class, %arg) = @_;
        return bless { calls => [], result => $arg{result} // 0 }, $class;
    }
    sub exists {
        my ($self, $image_ref, %opts) = @_;
        push @{ $self->{calls} }, { image_ref => $image_ref, %opts };
        return $self->{result};
    }
}

{
    package FakeSystem;
    sub new {
        my ($class, %arg) = @_;
        return bless { calls => [], result => $arg{result} }, $class;
    }
    sub auth {
        my ($self, %opts) = @_;
        push @{ $self->{calls} }, { %opts };
        return $self->{result};
    }
}

{
    package FakeDocker;
    sub new {
        my ($class, %arg) = @_;
        return bless { distribution => $arg{distribution}, system => $arg{system} }, $class;
    }
    sub distribution { $_[0]->{distribution} }
    sub system        { $_[0]->{system} }
}

my $tmp = Path::Tiny->tempdir;
my $cfg = $tmp->child('config.json');
$cfg->spew_utf8(encode_json({
    auths => {
        'ghcr.io' => { auth => encode_base64('getty:ghpat', '') },
    },
}));

sub client_for {
    my (%arg) = @_;
    my $distribution = FakeDistribution->new(result => $arg{exists_result});
    my $system        = FakeSystem->new(result => $arg{auth_result});
    my $docker = FakeDocker->new(distribution => $distribution, system => $system);
    my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
        docker             => $docker,
        logger             => sub { },
        logger_fatal       => sub { die $_[0] },
        docker_config_path => $cfg,
    );
    return ($client, $distribution, $system);
}

subtest 'remote_tag_exists omits the auth option entirely when none resolves' => sub {
    my ($client, $distribution) = client_for(exists_result => 0);

    my $result = $client->remote_tag_exists('unknown.example.com/foo:tag');

    is $result, 0, 'engine answer passed through';
    is scalar @{ $distribution->{calls} }, 1, 'distribution->exists called once';
    my $call = $distribution->{calls}[0];
    is $call->{image_ref}, 'unknown.example.com/foo:tag', 'image ref passed through';
    ok !exists $call->{auth},
        'no auth key at all -- an explicit auth => undef is not the same request';
};

subtest 'remote_tag_exists passes the resolved auth when one exists' => sub {
    my ($client, $distribution) = client_for(exists_result => 1);

    my $result = $client->remote_tag_exists('ghcr.io/getty/foo:v1');

    is $result, 1, 'truthy engine answer normalized to 1';
    my $call = $distribution->{calls}[0];
    ok exists $call->{auth}, 'auth key present for a registry with credentials';
    is $call->{auth}{username}, 'getty', 'resolved username carried through';
    is $call->{auth}{password}, 'ghpat', 'resolved password carried through';
};

subtest 'verify_auth_for_image_ref never calls system->auth without a credential' => sub {
    my ($client, undef, $system) = client_for();

    my $result = $client->verify_auth_for_image_ref('unknown.example.com/foo:tag');

    is $result, undef, 'no credential -> undef, not a croak';
    is scalar @{ $system->{calls} }, 0,
        'system->auth was never called -- it croaks on an empty AuthConfig';
};

subtest 'verify_auth_for_image_ref asks system->auth when a credential resolves' => sub {
    my ($client, undef, $system) = client_for(auth_result => { Status => 'Login Succeeded' });

    my $result = $client->verify_auth_for_image_ref('ghcr.io/getty/foo:v1');

    is_deeply $result, { Status => 'Login Succeeded' },
        'the engine answer is returned as-is';
    is scalar @{ $system->{calls} }, 1, 'system->auth called exactly once';
    my $call = $system->{calls}[0];
    is $call->{auth}{username}, 'getty', 'the resolved credential is what was sent';
    is $call->{auth}{password}, 'ghpat', 'the resolved credential is what was sent';
};

done_testing;
