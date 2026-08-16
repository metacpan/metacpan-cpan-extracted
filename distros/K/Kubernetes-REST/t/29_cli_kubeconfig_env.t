#!/usr/bin/env perl
# The CLI's --kubeconfig option used to default to "$ENV{HOME}/.kube/config" and
# always pass that value to Kubernetes::REST::Kubeconfig, so Kubeconfig's own
# $ENV{KUBECONFIG} default was unreachable and anyone juggling clusters through
# KUBECONFIG was silently pointed at the wrong one. The precedence has to be
# --kubeconfig, then $ENV{KUBECONFIG}, then ~/.kube/config.
#
# Every case below localises both HOME and KUBECONFIG and points HOME at a
# temporary directory, so nothing here reads or writes the real home of whoever
# runs the suite.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use YAML::XS ();

use Kubernetes::REST::CLI;
use Kubernetes::REST::CLI::Watch;

my $tmpdir = tempdir(CLEANUP => 1);

# One kubeconfig per source of the path, each naming a different server, so the
# endpoint of the built client says which file was read.
sub write_kubeconfig {
    my ($path, $endpoint) = @_;
    YAML::XS::DumpFile($path, {
        apiVersion => 'v1',
        kind => 'Config',
        'current-context' => 'test',
        clusters => [{
            name => 'test-cluster',
            cluster => {
                server => $endpoint,
                'insecure-skip-tls-verify' => 1,
            },
        }],
        contexts => [{
            name => 'test',
            context => { cluster => 'test-cluster', user => 'test-user' },
        }],
        users => [{ name => 'test-user', user => { token => 'test-token' } }],
    });
    return $path;
}

my $explicit_file = write_kubeconfig("$tmpdir/explicit.yaml", 'https://explicit.k8s.test:6443');
my $env_file      = write_kubeconfig("$tmpdir/from-env.yaml", 'https://from-env.k8s.test:6443');

# A fake home, so the "no option, no environment" case still stays in the
# temporary directory instead of reaching for the real ~/.kube/config.
my $fake_home = "$tmpdir/home";
make_path("$fake_home/.kube");
write_kubeconfig("$fake_home/.kube/config", 'https://home-default.k8s.test:6443');

# Both CLI entry points consume Kubernetes::REST::CLI::Role::Connection, and the
# precedence lives in the role, so both have to show it.
my %consumer = (
    'Kubernetes::REST::CLI'        => 'kube_client',
    'Kubernetes::REST::CLI::Watch' => 'kube_watch',
);

for my $class (sort keys %consumer) {
    my $tool = $consumer{$class};

    subtest "$tool - explicit --kubeconfig wins over KUBECONFIG" => sub {
        local $ENV{HOME} = $fake_home;
        local $ENV{KUBECONFIG} = $env_file;

        my $cli = $class->new(kubeconfig => $explicit_file);
        is $cli->kubeconfig, $explicit_file, 'option keeps the value it was given';
        is $cli->api->server->endpoint, 'https://explicit.k8s.test:6443',
            'client built from the explicitly named kubeconfig';
    };

    subtest "$tool - KUBECONFIG wins over the home default" => sub {
        local $ENV{HOME} = $fake_home;
        local $ENV{KUBECONFIG} = $env_file;

        my $cli = $class->new;
        ok !defined $cli->kubeconfig,
            'unset option stays undef instead of defaulting to a home path';
        is $cli->api->server->endpoint, 'https://from-env.k8s.test:6443',
            'client built from $ENV{KUBECONFIG}';
    };

    subtest "$tool - home default without option or KUBECONFIG" => sub {
        local $ENV{HOME} = $fake_home;
        delete local $ENV{KUBECONFIG};

        my $cli = $class->new;
        is $cli->api->server->endpoint, 'https://home-default.k8s.test:6443',
            'client built from ~/.kube/config';
    };

    subtest "$tool - KUBECONFIG is not consulted once the option is given" => sub {
        local $ENV{HOME} = $fake_home;
        local $ENV{KUBECONFIG} = "$tmpdir/does-not-exist.yaml";

        my $cli = $class->new(kubeconfig => $explicit_file);
        is $cli->api->server->endpoint, 'https://explicit.k8s.test:6443',
            'a bogus KUBECONFIG cannot break an explicit --kubeconfig';
    };
}

subtest 'the option is still a documented --kubeconfig=PATH' => sub {
    for my $class (sort keys %consumer) {
        my %options = $class->_options_data;
        my $spec = $options{kubeconfig};
        ok $spec, "$class still declares a kubeconfig option";
        is $spec->{format}, 's', "$class kubeconfig still takes a string argument";
        like $spec->{doc}, qr/KUBECONFIG/,
            "$class --help names KUBECONFIG, since there is no default to show";
    }
};

done_testing;
