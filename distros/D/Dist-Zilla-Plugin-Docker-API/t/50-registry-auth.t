use strict;
use warnings;
use Test::More;
use Path::Tiny;
use JSON::MaybeXS qw( encode_json );
use MIME::Base64 qw( encode_base64 );

use Dist::Zilla::Plugin::Docker::API::Client;

my $tmp = Path::Tiny->tempdir;
my $cfg = $tmp->child('config.json');

my %auths = (
    'https://index.docker.io/v1/' => {
        auth => encode_base64('raudssus:hubsecret', ''),
    },
    'ghcr.io' => {
        auth => encode_base64('getty:ghpat', ''),
    },
    'lab.example.com:5000' => {
        auth => encode_base64('user:port-secret', ''),
    },
    'identity.example.com' => {
        identitytoken => 'token-xyz',
    },
);

$cfg->spew_utf8(encode_json({ auths => \%auths }));

my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
    logger             => sub { },
    logger_fatal       => sub { die @_ },
    docker_config_path => $cfg,
);

# Registry detection
is $client->_registry_for_image_ref('raudssus/karr:user'),
    'https://index.docker.io/v1/', 'implicit Docker Hub';
is $client->_registry_for_image_ref('nginx:latest'),
    'https://index.docker.io/v1/', 'single-segment image is Docker Hub';
is $client->_registry_for_image_ref('ghcr.io/getty/foo:v1'),
    'ghcr.io', 'ghcr.io registry detected';
is $client->_registry_for_image_ref('lab.example.com:5000/foo/bar:tag'),
    'lab.example.com:5000', 'host:port registry detected';
is $client->_registry_for_image_ref('localhost/foo:tag'),
    'localhost', 'localhost registry detected';
is $client->_registry_for_image_ref('ghcr.io/getty/foo@sha256:deadbeef'),
    'ghcr.io', 'digest suffix stripped';

# Auth lookup
my $hub = $client->auth_for_image_ref('raudssus/karr:user');
is $hub->{username}, 'raudssus', 'docker hub username decoded';
is $hub->{password}, 'hubsecret', 'docker hub password decoded';
is $hub->{serveraddress}, 'https://index.docker.io/v1/',
    'docker hub serveraddress set';

my $ghcr = $client->auth_for_image_ref('ghcr.io/getty/foo:v1');
is $ghcr->{username}, 'getty', 'ghcr username';
is $ghcr->{password}, 'ghpat', 'ghcr password';

my $port = $client->auth_for_image_ref('lab.example.com:5000/foo/bar:tag');
is $port->{username}, 'user', 'host:port username';
is $port->{password}, 'port-secret', 'host:port password';

my $ident = $client->auth_for_image_ref('identity.example.com/foo:tag');
is $ident->{identitytoken}, 'token-xyz', 'identitytoken passed through';
ok !exists $ident->{password}, 'no password set for identitytoken auth';

my $missing = $client->auth_for_image_ref('unknown.example.com/foo:tag');
is $missing, undef, 'unknown registry yields undef auth';

# Missing config file is non-fatal
my $no_cfg_client = Dist::Zilla::Plugin::Docker::API::Client->new(
    logger             => sub { },
    logger_fatal       => sub { die @_ },
    docker_config_path => $tmp->child('does-not-exist.json'),
);
is $no_cfg_client->auth_for_image_ref('raudssus/karr:user'), undef,
    'missing config is non-fatal';

done_testing;
