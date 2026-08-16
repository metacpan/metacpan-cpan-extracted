#!/usr/bin/env perl
# A bearer token that comes from a file gets rotated under a running process:
# the kubelet replaces a projected service account token long before it
# expires. A client that read the file once at startup goes on sending the old
# one and collects 401s while a valid token sits in the file next to it.
#
# Kubernetes::REST::AuthTokenFile re-reads instead, and the trigger is the file
# itself rather than a timer. The measurement is a stat: device and inode, size
# and modification time. Inode is the one that matters here, because the
# kubelet does not overwrite the file - it writes a new timestamped directory
# and swaps the "..data" symlink onto it, which the last subtest reproduces
# with the mtimes forced equal so that nothing but the inode can give it away.
#
# Nothing here depends on mtime granularity: every case either changes the
# size, sets the mtime explicitly, or swaps in a different inode.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Config ();
use Path::Tiny qw(path);
use YAML::XS ();

use_ok('Kubernetes::REST::AuthTokenFile');
use_ok('Kubernetes::REST::Kubeconfig');

my $tmpdir = tempdir(CLEANUP => 1);
local $ENV{HOME} = $tmpdir;
delete local $ENV{KUBECONFIG};

# One kubeconfig, one user, reading whatever token file a case points it at.
sub write_kubeconfig {
    my ($path, $token_file) = @_;
    YAML::XS::DumpFile($path, {
        apiVersion => 'v1',
        kind => 'Config',
        'current-context' => 'ctx',
        clusters => [{
            name => 'cluster',
            cluster => {
                server => 'https://cluster.k8s.test:6443',
                'insecure-skip-tls-verify' => 1,
            },
        }],
        contexts => [{ name => 'ctx', context => { cluster => 'cluster', user => 'user' } }],
        users => [{ name => 'user', user => { tokenFile => $token_file } }],
    });
    return $path;
}

sub bearer_of {
    my $api = shift;
    return $api->prepare_request('GET', '/api/v1/namespaces')->headers->{Authorization};
}

my $case = 0;
sub case_dir {
    my $dir = "$tmpdir/case" . ++$case;
    make_path($dir);
    return $dir;
}

subtest 'a rotated token is picked up on the next request' => sub {
    my $dir = case_dir();
    my $token_file = "$dir/token";
    path($token_file)->spew_raw("token-first\n");
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => write_kubeconfig("$dir/kubeconfig", $token_file),
    );

    my $api = $kc->api;
    is bearer_of($api), 'Bearer token-first', 'the first request carries the first token';

    # Rotation: new content, different length, so this cannot be an artefact of
    # mtime resolution.
    path($token_file)->spew_raw("token-after-rotation\n");

    is bearer_of($api), 'Bearer token-after-rotation',
        'the next request carries the new one, on the same client';
    is $api->credentials->token, 'token-after-rotation', 'and so does the token itself';
};

subtest 'an unchanged file is not read again' => sub {
    my $dir = case_dir();
    my $token_file = "$dir/token";
    path($token_file)->spew_raw("steady-token\n");

    my $reads = 0;
    my $read = \&Kubernetes::REST::AuthTokenFile::_read_file;
    no warnings 'redefine';
    local *Kubernetes::REST::AuthTokenFile::_read_file = sub {
        $reads++;
        return $read->(@_);
    };
    use warnings 'redefine';

    my $auth = Kubernetes::REST::AuthTokenFile->new(file => $token_file);
    is $reads, 1, 'built: the file was read once';

    is $auth->token, 'steady-token', 'and that is the token';
    $auth->token for 1 .. 7;
    is $reads, 1, 'eight calls later it has still only been read once';

    path($token_file)->spew_raw("moved-on\n");
    is $auth->token, 'moved-on', 'a changed file is read';
    is $reads, 2, 'exactly once more';

    $auth->token for 1 .. 3;
    is $reads, 2, 'and not again while it stays put';
};

subtest 'refresh => 0 reads once and never looks again' => sub {
    my $dir = case_dir();
    my $token_file = "$dir/token";
    path($token_file)->spew_raw("frozen-token\n");

    my $auth = Kubernetes::REST::AuthTokenFile->new(file => $token_file, refresh => 0);
    is $auth->token, 'frozen-token', 'the token as it was at construction';

    path($token_file)->spew_raw("changed-underneath\n");
    is $auth->token, 'frozen-token', 'a changed file changes nothing';

    unlink $token_file;
    is $auth->token, 'frozen-token', 'and neither does the file going away';
};

subtest 'refresh_token_files reaches the clients a kubeconfig builds' => sub {
    my $dir = case_dir();
    my $token_file = "$dir/token";
    path($token_file)->spew_raw("before\n");
    my $config = write_kubeconfig("$dir/kubeconfig", $token_file);

    my $refreshing = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config)->api;
    my $fixed = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => $config,
        refresh_token_files => 0,
    )->api;

    is bearer_of($refreshing), 'Bearer before', 'both start at the same token';
    is bearer_of($fixed), 'Bearer before', '...';

    path($token_file)->spew_raw("after\n");

    is bearer_of($refreshing), 'Bearer after', 'the default client follows the file';
    is bearer_of($fixed), 'Bearer before', 'the one built with refresh_token_files => 0 does not';
};

subtest 'the last good token survives a file that goes away' => sub {
    my $dir = case_dir();
    my $token_file = "$dir/token";
    path($token_file)->spew_raw("last-good\n");
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => write_kubeconfig("$dir/kubeconfig", $token_file),
    );
    my $api = $kc->api;
    is bearer_of($api), 'Bearer last-good', 'read while it was there';

    # A rotation can take the file away for a moment. Dying on a race that
    # resolves itself would be worse than a token a second old.
    unlink $token_file or die "Cannot unlink $token_file: $!";
    lives_ok { bearer_of($api) } 'a vanished file does not kill the client';
    is bearer_of($api), 'Bearer last-good', 'it keeps the token it had';

    # Same for a file that is there but momentarily holds nothing.
    path($token_file)->spew_raw('');
    is $api->credentials->token, 'last-good', 'an empty file is not an empty token either';
    path($token_file)->spew_raw("  \n\n");
    is $api->credentials->token, 'last-good', 'nor is one holding only whitespace';

    # ... and the recovery.
    path($token_file)->spew_raw("recovered-token\n");
    is bearer_of($api), 'Bearer recovered-token', 'and it recovers when the file comes back';
};

subtest 'the first read is still fatal' => sub {
    my $dir = case_dir();

    throws_ok { Kubernetes::REST::AuthTokenFile->new(file => "$dir/never-there") }
        qr/Cannot read the token file/,
        'a missing file cannot be papered over: there is nothing to fall back on';

    path("$dir/empty")->spew_raw("\n \n");
    throws_ok { Kubernetes::REST::AuthTokenFile->new(file => "$dir/empty") }
        qr/holds no token/,
        'neither can an empty one';

    throws_ok {
        Kubernetes::REST::AuthTokenFile->new(
            file => "$dir/never-there",
            description => "tokenFile of user 'someone'",
        );
    } qr/tokenFile of user 'someone'/, 'the description is what names it in the error';
};

subtest 'both token files go through the same credentials' => sub {
    # api() builds one of these for a user's tokenFile, _in_cluster_api for the
    # service account token, and both do it through this one helper - which is
    # also where the refresh_token_files switch is applied.
    my $dir = case_dir();
    my $token_file = "$dir/token";
    path($token_file)->spew_raw("shared-path\n");

    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => write_kubeconfig("$dir/kubeconfig", $token_file),
    );
    my $auth = $kc->_token_file_credential($token_file, 'service account token');
    isa_ok $auth, 'Kubernetes::REST::AuthTokenFile';
    is $auth->token, 'shared-path', 'reads the file it was given';
    is $auth->refresh, 1, 'refreshing by default';
    is $auth->description, 'service account token', 'named for its error messages';

    my $fixed = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => "$dir/kubeconfig",
        refresh_token_files => 0,
    )->_token_file_credential($token_file, 'service account token');
    is $fixed->refresh, 0, 'and it carries refresh_token_files through';

    # The user's tokenFile arrives as one of these as well.
    isa_ok $kc->api->credentials, 'Kubernetes::REST::AuthTokenFile';
};

subtest 'the kubelet swaps a symlink, and that counts as a change' => sub {
    plan skip_all => 'no symlinks on this platform' unless $Config::Config{d_symlink};

    # What a mounted service account token really looks like:
    #   token   -> ..data/token
    #   ..data  -> ..2026_01_01_00_00_00.111111111
    # A rotation writes a new timestamped directory and renames a new ..data
    # symlink over the old one. The path then resolves to a different file -
    # the old inode is never touched.
    my $dir = case_dir();
    make_path("$dir/..2026_01_01_00_00_00.111111111");
    make_path("$dir/..2026_01_01_01_00_00.222222222");

    # Same length, and the same modification time forced onto both, so the only
    # thing that can tell them apart is the inode.
    path("$dir/..2026_01_01_00_00_00.111111111/token")->spew_raw("token-aaaaaaaa\n");
    path("$dir/..2026_01_01_01_00_00.222222222/token")->spew_raw("token-bbbbbbbb\n");
    utime 1_000_000_000, 1_000_000_000,
        "$dir/..2026_01_01_00_00_00.111111111/token",
        "$dir/..2026_01_01_01_00_00.222222222/token";

    symlink '..2026_01_01_00_00_00.111111111', "$dir/..data" or die "symlink: $!";
    symlink '..data/token', "$dir/token" or die "symlink: $!";

    my $auth = Kubernetes::REST::AuthTokenFile->new(file => "$dir/token");
    is $auth->token, 'token-aaaaaaaa', 'the mounted token, through two symlinks';

    my @before = stat "$dir/token";
    symlink '..2026_01_01_01_00_00.222222222', "$dir/..data_tmp" or die "symlink: $!";
    rename "$dir/..data_tmp", "$dir/..data" or die "rename: $!";
    my @after = stat "$dir/token";

    is $after[7], $before[7], 'the swap left the size identical';
    is $after[9], $before[9], 'and the modification time identical';
    isnt $after[1], $before[1], 'only the inode is different';

    is $auth->token, 'token-bbbbbbbb', 'and the swap is seen for what it is';
};

subtest 'what the fingerprint cannot see' => sub {
    # Documented in Kubernetes::REST::AuthTokenFile: an in-place rewrite that
    # keeps the inode, the exact size and the modification time is invisible
    # without reading the file on every call, which is what the stat is there
    # to avoid. Nothing Kubernetes does looks like this - it is here so that
    # the boundary is a decision on record rather than a surprise.
    my $dir = case_dir();
    my $token_file = "$dir/token";
    path($token_file)->spew_raw("token-11111111\n");
    # Pinned to a whole second before the first read, because the fingerprint
    # is taken with sub-second resolution and utime only sets whole seconds -
    # otherwise the restored mtime would itself be the difference.
    utime 1_000_000_000, 1_000_000_000, $token_file or die "Cannot utime: $!";
    my @before = stat $token_file;

    my $auth = Kubernetes::REST::AuthTokenFile->new(file => $token_file);
    is $auth->token, 'token-11111111', 'the token as first read';

    # Rewritten in place: same inode, same length, mtime put back.
    open my $fh, '+<', $token_file or die "Cannot open $token_file: $!";
    print $fh "token-22222222\n";
    close $fh;
    utime 1_000_000_000, 1_000_000_000, $token_file or die "Cannot utime: $!";

    my @after = stat $token_file;
    is $after[1], $before[1], 'same inode';
    is $after[7], $before[7], 'same size';
    is $after[9], $before[9], 'same modification time';

    is $auth->token, 'token-11111111',
        'so the change goes unnoticed - the documented blind spot';
};

done_testing;
