#!/usr/bin/env perl
# A kubeconfig that names its certificates relatively - "certificate-authority:
# ca.crt", the shape of a kubeconfig checked in next to its certs - used to be
# read against the process working directory: it worked when you happened to
# start from the right place and broke from anywhere else. kubectl resolves
# those references against the directory of the kubeconfig file that defines
# the entry, and so does this module now.
#
# With several files merged that directory belongs to the entry, not to the
# configuration, which is what the two-directory cases below are about: both
# kubeconfigs here say "ca.crt" and mean a different file.
#
# HOME and KUBECONFIG are localised for the whole run, so nothing reads the
# real ~/.kube/config; every path in play lives under one temporary directory.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd qw(getcwd);
use Path::Tiny qw(path);
use YAML::XS ();

use_ok('Kubernetes::REST::Kubeconfig');

my $tmpdir = tempdir(CLEANUP => 1);
local $ENV{HOME} = $tmpdir;
delete local $ENV{KUBECONFIG};

# Two kubeconfigs in two directories, plus a third directory to run from that
# is neither of them, and a shared one to reach with "..".
make_path("$tmpdir/$_") for qw(a a/certs b shared elsewhere);

sub write_file {
    my ($path, $content) = @_;
    path($path)->spew($content);
    return $path;
}

# A wrongly resolved path names a file that is not there, and reading it would
# abort the run instead of reporting which case broke.
sub content_of {
    my $path = shift;
    return "(nothing at $path)" unless defined $path and -f $path;
    return path($path)->slurp;
}

# Cert material, one set per directory. The contents differ so a wrongly
# resolved path cannot accidentally pass for the right one.
write_file("$tmpdir/a/ca.crt",            "-----BEGIN CERTIFICATE-----\nA-CA\n");
write_file("$tmpdir/a/client.crt",        "-----BEGIN CERTIFICATE-----\nA-CERT\n");
write_file("$tmpdir/a/certs/client.key",  "-----BEGIN RSA PRIVATE KEY-----\nA-KEY\n");
write_file("$tmpdir/b/ca.crt",            "-----BEGIN CERTIFICATE-----\nB-CA\n");
write_file("$tmpdir/b/client.crt",        "-----BEGIN CERTIFICATE-----\nB-CERT\n");
write_file("$tmpdir/b/client.key",        "-----BEGIN RSA PRIVATE KEY-----\nB-KEY\n");
write_file("$tmpdir/shared/ca.crt",       "-----BEGIN CERTIFICATE-----\nSHARED-CA\n");

# Both files say "ca.crt" and "client.crt" and mean their own directory.
my $config_a = "$tmpdir/a/config";
YAML::XS::DumpFile($config_a, {
    apiVersion => 'v1',
    kind => 'Config',
    'current-context' => 'a-ctx',
    clusters => [
        {
            name => 'a-cluster',
            cluster => {
                server => 'https://a.k8s.test:6443',
                'certificate-authority' => 'ca.crt',
            },
        },
        {
            name => 'shared-ca-cluster',
            cluster => {
                server => 'https://shared.k8s.test:6443',
                'certificate-authority' => '../shared/ca.crt',
            },
        },
        {
            name => 'absolute-cluster',
            cluster => {
                server => 'https://absolute.k8s.test:6443',
                'certificate-authority' => "$tmpdir/a/ca.crt",
            },
        },
        {
            name => 'inline-cluster',
            cluster => {
                server => 'https://inline.k8s.test:6443',
                'certificate-authority-data' => 'SU5MSU5FLUNB',
            },
        },
    ],
    contexts => [
        { name => 'a-ctx', context => { cluster => 'a-cluster', user => 'a-user' } },
        { name => 'inline-ctx', context => { cluster => 'inline-cluster', user => 'a-user' } },
    ],
    users => [
        {
            name => 'a-user',
            user => {
                'client-certificate' => 'client.crt',
                'client-key' => 'certs/client.key',
            },
        },
        {
            name => 'absolute-user',
            user => {
                'client-certificate' => "$tmpdir/a/client.crt",
                'client-key' => "$tmpdir/a/certs/client.key",
            },
        },
        {
            name => 'exec-user',
            user => {
                exec => {
                    apiVersion => 'client.authentication.k8s.io/v1',
                    command => './credential-plugin',
                },
            },
        },
    ],
});

my $config_b = "$tmpdir/b/config";
YAML::XS::DumpFile($config_b, {
    apiVersion => 'v1',
    kind => 'Config',
    'current-context' => 'b-ctx',
    clusters => [{
        name => 'b-cluster',
        cluster => {
            server => 'https://b.k8s.test:6443',
            'certificate-authority' => 'ca.crt',
        },
    }],
    contexts => [{ name => 'b-ctx', context => { cluster => 'b-cluster', user => 'b-user' } }],
    users => [{
        name => 'b-user',
        user => {
            'client-certificate' => 'client.crt',
            'client-key' => 'client.key',
        },
    }],
});

# Nothing in this file may depend on where it is run from, so every case starts
# somewhere that is not the directory of the kubeconfig it reads.
my $start = getcwd;
chdir "$tmpdir/elsewhere" or die "Cannot chdir to $tmpdir/elsewhere: $!";
END { chdir $start if $start }

subtest 'a relative CA resolves against the directory of its kubeconfig' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_a);
    my $ca = $kc->cluster('a-cluster')->{'certificate-authority'};
    is $ca, "$tmpdir/a/ca.crt", 'joined onto the directory of the file that named it';
    ok path($ca)->is_absolute, 'and absolute, not relative to anything';
    is content_of($ca), "-----BEGIN CERTIFICATE-----\nA-CA\n",
        'it points at the CA that lives next to that kubeconfig';
};

subtest 'client certificate and key are resolved the same way' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_a);
    my $user = $kc->user('a-user');
    is $user->{'client-certificate'}, "$tmpdir/a/client.crt", 'client-certificate';
    is $user->{'client-key'}, "$tmpdir/a/certs/client.key",
        'client-key, including a subdirectory of its own';
    ok -f $user->{'client-key'}, 'and the resolved key really is there';
};

subtest 'a reference reaching out of the directory works' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_a);
    my $ca = $kc->cluster('shared-ca-cluster')->{'certificate-authority'};
    ok -f $ca, '"../shared/ca.crt" resolves to a file that exists';
    is content_of($ca), "-----BEGIN CERTIFICATE-----\nSHARED-CA\n",
        'namely the one in the directory beside the kubeconfig directory';
};

subtest 'absolute references are passed through untouched' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_a);
    is $kc->cluster('absolute-cluster')->{'certificate-authority'}, "$tmpdir/a/ca.crt",
        'cluster CA is the string the file contained';
    my $user = $kc->user('absolute-user');
    is $user->{'client-certificate'}, "$tmpdir/a/client.crt", 'client-certificate unchanged';
    is $user->{'client-key'}, "$tmpdir/a/certs/client.key", 'client-key unchanged';
};

subtest 'inline data and an exec command are left alone' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_a);
    is $kc->cluster('inline-cluster')->{'certificate-authority-data'}, 'SU5MSU5FLUNB',
        'base64 certificate-authority-data names no file and is not touched';
    is $kc->user('exec-user')->{exec}{command}, './credential-plugin',
        'an exec plugin command is a PATH lookup, not a file reference';

    my $api = $kc->api('inline-ctx');
    ok $api->server->ssl_ca_pem, 'inline CA still arrives as in-memory PEM';
    ok !$api->server->ssl_ca_file, 'and not as a file path';
};

subtest 'api() hands the resolved paths to the server' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_a);
    my $api = $kc->api;
    is $api->server->ssl_ca_file, "$tmpdir/a/ca.crt", 'ssl_ca_file';
    is $api->server->ssl_cert_file, "$tmpdir/a/client.crt", 'ssl_cert_file';
    is $api->server->ssl_key_file, "$tmpdir/a/certs/client.key", 'ssl_key_file';
    ok -f $api->server->ssl_ca_file, 'every one of them exists from here';
};

subtest 'each merged entry gets the directory of its own file' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => [$config_a, $config_b]);

    # Both files literally say "ca.crt". The string is the same, the file is not.
    is $kc->cluster('a-cluster')->{'certificate-authority'}, "$tmpdir/a/ca.crt",
        'the cluster from the first file resolves against the first directory';
    is $kc->cluster('b-cluster')->{'certificate-authority'}, "$tmpdir/b/ca.crt",
        'the cluster from the second file resolves against the second';
    is $kc->user('a-user')->{'client-certificate'}, "$tmpdir/a/client.crt", 'user from a';
    is $kc->user('b-user')->{'client-certificate'}, "$tmpdir/b/client.crt", 'user from b';

    is content_of($kc->cluster('b-cluster')->{'certificate-authority'}),
        "-----BEGIN CERTIFICATE-----\nB-CA\n",
        'the second directory really is the one that gets read';
};

subtest 'the current context does not decide the directory' => sub {
    # current-context comes from the first file, the b-ctx entries from the
    # second: the merged configuration has no single directory to be relative
    # to, which is exactly why the origin has to be per entry.
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => [$config_a, $config_b]);
    is $kc->current_context_name, 'a-ctx', 'current-context comes from the first file';

    my $api = $kc->api('b-ctx');
    is $api->server->endpoint, 'https://b.k8s.test:6443', 'the client is the one from b';
    is $api->server->ssl_ca_file, "$tmpdir/b/ca.crt",
        'and its CA is b/ca.crt, not the a/ca.crt of the current context';
    is $api->server->ssl_cert_file, "$tmpdir/b/client.crt", 'same for the client cert';
    is $api->server->ssl_key_file, "$tmpdir/b/client.key", 'same for the client key';
};

subtest 'the working directory does not enter into it' => sub {
    # The proof: the same kubeconfig read from three different places has to
    # produce the same paths, and none of them may be relative to the place.
    my @seen;
    for my $where ("$tmpdir/elsewhere", "$tmpdir/b", $tmpdir) {
        chdir $where or die "Cannot chdir to $where: $!";
        my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_a);
        push @seen, $kc->cluster('a-cluster')->{'certificate-authority'};
    }
    chdir "$tmpdir/elsewhere" or die "Cannot chdir back: $!";

    is_deeply \@seen, [("$tmpdir/a/ca.crt") x 3],
        'read from three working directories, resolved to one file';
};

subtest 'a relatively named kubeconfig still yields absolute references' => sub {
    # The kubeconfig itself is found relative to the working directory (that is
    # the KUBECONFIG list rule), but what it names must not stay tied to it.
    chdir "$tmpdir/a" or die "Cannot chdir to $tmpdir/a: $!";
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => 'config');
    my $ca = $kc->cluster('a-cluster')->{'certificate-authority'};
    my $api = $kc->api;

    chdir "$tmpdir/elsewhere" or die "Cannot chdir back: $!";

    is $ca, "$tmpdir/a/ca.crt", 'the reference was made absolute while reading';
    ok -f $api->server->ssl_ca_file,
        'so the built client can still find its CA after a chdir';
    ok -f $api->server->ssl_key_file, 'and its key';
};

done_testing;
