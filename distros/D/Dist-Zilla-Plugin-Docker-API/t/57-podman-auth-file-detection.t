use strict;
use warnings;
use Test::More;
use Path::Tiny;
use JSON::MaybeXS qw( encode_json );
use MIME::Base64 qw( encode_base64 );

use Dist::Zilla::Plugin::Docker::API::Client;

# Below the seam: auth_for_image_ref's ordered auth_file_candidates
# discovery (karr #13) is exercised by instantiating the client directly
# and pointing auth_file_candidates at fixtures, the same way t/50 and t/56
# build the client directly. A Recorder-driven test cannot see any of this
# -- the Recorder replaces the whole client class.

my $tmp = Path::Tiny->tempdir;

sub write_auth_file {
    my ($name, %auths) = @_;
    my $file = $tmp->child($name);
    $file->parent->mkpath;
    $file->spew_utf8(encode_json({ auths => \%auths }));
    return $file;
}

subtest 'precedence at collision: the earlier candidate wins' => sub {
    my $first = write_auth_file('collision-first.json',
        'ghcr.io' => { auth => encode_base64('first-user:first-pass', '') },
    );
    my $second = write_auth_file('collision-second.json',
        'ghcr.io' => { auth => encode_base64('second-user:second-pass', '') },
    );

    my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
        logger               => sub { },
        logger_fatal         => sub { die $_[0] },
        auth_file_candidates => [ $first, $second ],
    );

    my $auth = $client->auth_for_image_ref('ghcr.io/getty/foo:v1');
    is $auth->{username}, 'first-user',
        'earlier file in the list wins when both have an entry for the registry';
    is $auth->{password}, 'first-pass',
        'the earlier credential is used, not the later one';
};

subtest 'fall-through: the first file lacks an entry, the second has it' => sub {
    my $first = write_auth_file('fallthrough-first.json',
        'quay.io' => { auth => encode_base64('unrelated:secret', '') },
    );
    my $second = write_auth_file('fallthrough-second.json',
        'ghcr.io' => { auth => encode_base64('fallthrough-user:fallthrough-pass', '') },
    );

    my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
        logger               => sub { },
        logger_fatal         => sub { die $_[0] },
        auth_file_candidates => [ $first, $second ],
    );

    my $auth = $client->auth_for_image_ref('ghcr.io/getty/foo:v1');
    ok defined $auth, 'discovery falls through to the second candidate';
    is $auth->{username}, 'fallthrough-user',
        'credential comes from the file that actually carries the registry';
    is $auth->{password}, 'fallthrough-pass',
        'password carried from the fall-through file';
};

subtest "podman's auth.json format is read, including base64 decoding" => sub {
    # Same {"auths":{...}} shape as docker's config.json, but at a podman-
    # style path ($XDG_RUNTIME_DIR/containers/auth.json), to prove the
    # format -- not just docker_config_path's config.json -- is understood.
    my $podman_auth = write_auth_file('containers/auth.json',
        'ghcr.io' => { auth => encode_base64('podman-user:podman-pass', '') },
    );

    my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
        logger               => sub { },
        logger_fatal         => sub { die $_[0] },
        auth_file_candidates => [ $podman_auth ],
    );

    my $auth = $client->auth_for_image_ref('ghcr.io/getty/foo:v1');
    is $auth->{username}, 'podman-user',
        "podman's auth.json is parsed the same as docker's config.json";
    is $auth->{password}, 'podman-pass',
        'base64 auth field decoded into username/password from auth.json';
};

subtest 'a broken first file is skipped with a warning, not fatal' => sub {
    my $broken = $tmp->child('broken.json');
    $broken->spew_utf8('{ this is not valid json');
    my $valid = write_auth_file('broken-fallback.json',
        'ghcr.io' => { auth => encode_base64('recovered-user:recovered-pass', '') },
    );

    my @warnings;
    my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
        logger               => sub { push @warnings, $_[0] },
        logger_fatal         => sub { die $_[0] },
        auth_file_candidates => [ $broken, $valid ],
    );

    my $auth = $client->auth_for_image_ref('ghcr.io/getty/foo:v1');
    is $auth->{username}, 'recovered-user',
        'an unparseable first file does not abort discovery -- the next candidate wins';
    is $auth->{password}, 'recovered-pass',
        'credential resolved from the valid file behind the broken one';
    is scalar(@warnings), 1, 'exactly one warning logged for the unparseable file';
    like $warnings[0], qr/cannot parse/i, 'the warning names the parse failure';
};

subtest 'a missing first file is skipped silently, not fatal' => sub {
    my $missing = $tmp->child('does-not-exist.json');
    my $valid = write_auth_file('missing-fallback.json',
        'ghcr.io' => { auth => encode_base64('present-user:present-pass', '') },
    );

    my @warnings;
    my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
        logger               => sub { push @warnings, $_[0] },
        logger_fatal         => sub { die $_[0] },
        auth_file_candidates => [ $missing, $valid ],
    );

    my $auth = $client->auth_for_image_ref('ghcr.io/getty/foo:v1');
    is $auth->{username}, 'present-user',
        'a non-existent candidate at the front of the list is skipped';
    is $auth->{password}, 'present-pass',
        'credential resolved from the existing file behind the missing one';
    is scalar(@warnings), 0,
        'no warning logged for a merely-missing file -- only a parse failure warns';
};

done_testing;
