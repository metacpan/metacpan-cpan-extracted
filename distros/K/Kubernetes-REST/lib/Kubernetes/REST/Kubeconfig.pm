package Kubernetes::REST::Kubeconfig;
# ABSTRACT: Parse kubeconfig files and create Kubernetes::REST instances
our $VERSION = '1.103';
use Moo;
use Carp qw(croak);
use YAML::XS ();
use Path::Tiny qw(path);
use MIME::Base64 qw(decode_base64);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use namespace::clean;


has kubeconfig_path => (
    is => 'ro',
    default => sub { $ENV{KUBECONFIG} // "$ENV{HOME}/.kube/config" },
);


has context_name => (
    is => 'ro',
    predicate => 1,
);


has _config => (
    is => 'lazy',
    builder => sub {
        my $self = shift;
        my $path = $self->kubeconfig_path;
        return undef unless -f $path;
        return YAML::XS::LoadFile($path);
    },
);

sub current_context_name {
    my $self = shift;
    return $self->context_name if $self->has_context_name;
    return $self->_config->{'current-context'};
}


sub contexts {
    my $self = shift;
    my $config = $self->_config
        or croak "Kubeconfig not found: " . $self->kubeconfig_path;
    return [ map { $_->{name} } @{$config->{contexts} // []} ];
}


sub _find_by_name {
    my ($self, $list, $name) = @_;
    for my $item (@{$list // []}) {
        return $item if $item->{name} eq $name;
    }
    return undef;
}

sub context {
    my ($self, $name) = @_;
    $name //= $self->current_context_name;
    my $ctx = $self->_find_by_name($self->_config->{contexts}, $name)
        or croak "Context not found: $name";
    return $ctx->{context};
}

sub cluster {
    my ($self, $name) = @_;
    my $cluster = $self->_find_by_name($self->_config->{clusters}, $name)
        or croak "Cluster not found: $name";
    return $cluster->{cluster};
}

sub user {
    my ($self, $name) = @_;
    my $user = $self->_find_by_name($self->_config->{users}, $name)
        or croak "User not found: $name";
    return $user->{user};
}

sub _resolve_cert {
    my ($self, $hash, $key) = @_;

    my $data_key = "${key}-data";
    if (my $data = $hash->{$data_key}) {
        return (pem => decode_base64($data));
    }

    if (my $file = $hash->{$key}) {
        return (file => $file);
    }

    return ();
}

sub api {
    my ($self, $context_name) = @_;


    # If no kubeconfig, try in-cluster
    unless ($self->_config) {
        return $self->_in_cluster_api
            // croak "Kubeconfig not found: " . $self->kubeconfig_path
                   . " and not running in-cluster";
    }

    $context_name //= $self->current_context_name;
    my $ctx = $self->context($context_name);
    my $cluster = $self->cluster($ctx->{cluster});
    my $user = $self->user($ctx->{user});

    # Build server config
    my %server = (
        endpoint => $cluster->{server},
    );

    if (my %ca = $self->_resolve_cert($cluster, 'certificate-authority')) {
        $server{ $ca{pem} ? 'ssl_ca_pem' : 'ssl_ca_file' } = $ca{pem} // $ca{file};
    }

    if ($cluster->{'insecure-skip-tls-verify'}) {
        $server{ssl_verify_server} = 0;
    } else {
        $server{ssl_verify_server} = 1;
    }

    if (my %cert = $self->_resolve_cert($user, 'client-certificate')) {
        $server{ $cert{pem} ? 'ssl_cert_pem' : 'ssl_cert_file' } = $cert{pem} // $cert{file};
    }

    if (my %key = $self->_resolve_cert($user, 'client-key')) {
        $server{ $key{pem} ? 'ssl_key_pem' : 'ssl_key_file' } = $key{pem} // $key{file};
    }

    # Build credentials
    my $credentials;
    if (my $token = $user->{token}) {
        $credentials = Kubernetes::REST::AuthToken->new(token => $token);
    } elsif (my $exec = $user->{exec}) {
        $credentials = $self->_exec_credential($exec);
    } else {
        # No token auth, might be using client certs only
        $credentials = Kubernetes::REST::AuthToken->new(token => '');
    }

    return Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(%server),
        credentials => $credentials,
    );
}

sub _exec_credential {
    my ($self, $exec) = @_;

    my $cmd = $exec->{command};
    my @args = @{$exec->{args} // []};

    # Set up environment
    local %ENV = %ENV;
    for my $env (@{$exec->{env} // []}) {
        $ENV{$env->{name}} = $env->{value};
    }

    my $output = `$cmd @args`;
    croak "exec credential command failed: $cmd" if $?;

    my $cred = YAML::XS::Load($output);
    my $token = $cred->{status}{token}
        or croak "exec credential did not return token";

    return Kubernetes::REST::AuthToken->new(token => $token);
}

my $SA_TOKEN = '/var/run/secrets/kubernetes.io/serviceaccount/token';
my $SA_CA    = '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt';

sub _in_cluster_api {
    my ($self) = @_;
    return undef unless -f $SA_TOKEN;

    my $host = $ENV{KUBERNETES_SERVICE_HOST} // 'kubernetes.default.svc';
    my $port = $ENV{KUBERNETES_SERVICE_PORT} // '443';
    open my $fh, '<', $SA_TOKEN or croak "Cannot read $SA_TOKEN: $!";
    my $token = do { local $/; <$fh> };
    chomp $token;

    return Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(
            endpoint          => "https://$host:$port",
            ssl_ca_file       => $SA_CA,
            ssl_verify_server => 1,
        ),
        credentials => Kubernetes::REST::AuthToken->new(token => $token),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Kubeconfig - Parse kubeconfig files and create Kubernetes::REST instances

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    use Kubernetes::REST::Kubeconfig;

    # Use default kubeconfig and current context
    my $kc = Kubernetes::REST::Kubeconfig->new;
    my $api = $kc->api;

    # Specify kubeconfig and context
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => '/path/to/kubeconfig',
        context_name => 'my-cluster',
    );

    # List available contexts
    my $contexts = $kc->contexts;

    # Get API for specific context
    my $api = $kc->api('production');

    # Inside a Kubernetes pod: no kubeconfig needed, auto-detects service account
    my $api = Kubernetes::REST::Kubeconfig->new->api;

=head1 DESCRIPTION

Parses Kubernetes kubeconfig files (typically C<~/.kube/config>) and creates configured L<Kubernetes::REST> instances.

When no kubeconfig file is found, automatically falls back to in-cluster
authentication using the pod's service account token.

Supports:

=over 4

=item * Multiple clusters and contexts

=item * Token authentication

=item * Client certificate authentication

=item * Inline certificate data (base64 encoded)

=item * External certificate files

=item * Exec-based credential plugins

=item * In-cluster service account auto-detection

=back

=head2 kubeconfig_path

Path to the kubeconfig file. Defaults to C<~/.kube/config>.

=head2 context_name

Optional. The context name to use. If not specified, uses the current-context from the kubeconfig.

=head2 current_context_name

    my $name = $kc->current_context_name;

Returns the current context name (either from C<context_name> attribute or from the kubeconfig's C<current-context>).

=head2 contexts

    my $contexts = $kc->contexts;

Returns an arrayref of all available context names from the kubeconfig.

=head2 api

    my $api = $kc->api;
    my $api = $kc->api('production');

Create a L<Kubernetes::REST> instance configured from the kubeconfig. If C<$context_name> is provided, uses that context; otherwise uses the current context.

Falls back to in-cluster service account authentication when no kubeconfig
file is found and the pod has a mounted token at
C</var/run/secrets/kubernetes.io/serviceaccount/token>.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::Server> - Server configuration

=item * L<Kubernetes::REST::AuthToken> - Authentication credentials

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
