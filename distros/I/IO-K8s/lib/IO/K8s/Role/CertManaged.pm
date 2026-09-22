package IO::K8s::Role::CertManaged;
# ABSTRACT: Role for cert-manager certificate and issuer management
our $VERSION = '1.108';
use Carp qw(croak);
# Imports above `use Moo::Role` on purpose: Role::Tiny treats subs already in
# the package as not-methods, so their names stay off every consumer. A `use`
# below that line composes its exports onto all shipped classes (k118).
use Moo::Role;

# The fluent setters below build the spec through IO::K8s::Role::SpecBuilder
# rather than by hand, so that role is a hard dependency of this one (k103).
# IO::K8s::Role::APIObject composes SpecBuilder for every top-level Kind, so
# these are satisfied for anything built with IO::K8s::APIObject; a class
# that composes this role without them now fails at composition time,
# naming the missing method, instead of at the first setter call.
requires qw( spec_push spec_set );

# --- Certificate methods ---


sub for_domains {
    my ($self, @domains) = @_;
    $self->spec_push('dnsNames', @domains);
    return $self;
}


sub with_issuer {
    my ($self, $name, %opts) = @_;
    $self->spec_set('issuerRef', {
        name  => $name,
        kind  => $opts{kind} // 'Issuer',
        group => $opts{group} || 'cert-manager.io',
    });
    return $self;
}


sub store_in_secret {
    my ($self, $secret_name) = @_;
    $self->spec_set('secretName', $secret_name);
    return $self;
}


sub add_ip_san {
    my ($self, @ips) = @_;
    require IO::K8s::Types::Net;
    for my $ip (@ips) {
        croak "'$ip' is not a valid IP address"
            unless IO::K8s::Types::Net::IPAddress()->check($ip);
    }
    $self->spec_push('ipAddresses', @ips);
    return $self;
}


sub renew_before {
    my ($self, %opts) = @_;
    if ($opts{days}) {
        $self->spec_set('renewBefore', ($opts{days} * 24) . 'h0m0s');
    } elsif ($opts{hours}) {
        $self->spec_set('renewBefore', $opts{hours} . 'h0m0s');
    }
    return $self;
}

# --- Issuer/ClusterIssuer methods ---


sub letsencrypt {
    my ($self, %opts) = @_;
    my $email = $opts{email} or croak 'email is required for letsencrypt';
    my $production = $opts{production} // 0;
    my $server = $production
        ? 'https://acme-v02.api.letsencrypt.org/directory'
        : 'https://acme-staging-v02.api.letsencrypt.org/directory';
    $self->spec_set('acme', {
        email  => $email,
        server => $server,
        privateKeySecretRef => { name => $opts{secret} // 'letsencrypt-account-key' },
    });
    return $self;
}


sub self_signed {
    my ($self) = @_;
    $self->spec_set('selfSigned', {});
    return $self;
}


sub ca {
    my ($self, %opts) = @_;
    $self->spec_set('ca', {
        secretName => $opts{secret} // croak('secret is required for ca'),
    });
    return $self;
}


sub add_http01_solver {
    my ($self, %opts) = @_;
    my $solver = { http01 => { ingress => {} } };
    $solver->{http01}{ingress}{class} = $opts{class} if $opts{class};
    $self->spec_push('acme.solvers', $solver);
    return $self;
}


sub add_dns01_solver {
    my ($self, %opts) = @_;
    my %dns01;
    if ($opts{provider} eq 'cloudflare') {
        $dns01{cloudflare} = {
            $opts{secret} ? (apiTokenSecretRef => { name => $opts{secret}, key => $opts{key} // 'api-token' }) : (),
        };
    } elsif ($opts{provider} eq 'route53') {
        $dns01{route53} = {
            $opts{region} ? (region => $opts{region}) : (),
        };
    } else {
        $dns01{$opts{provider}} = {};
    }
    $self->spec_push('acme.solvers', { dns01 => \%dns01 });
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::CertManaged - Role for cert-manager certificate and issuer management

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    package My::Certificate;
    use IO::K8s::APIObject
        api_version     => 'cert-manager.io/v1',
        resource_plural => 'certificates';
    with 'IO::K8s::Role::CertManaged';

    package main;
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);
    my $cert = $k8s->new_object('Certificate',
        metadata => { name => 'example', namespace => 'default' },
    );
    $cert->for_domains('example.com', '*.example.com')
         ->with_issuer('letsencrypt-prod', kind => 'ClusterIssuer')
         ->store_in_secret('example-tls');

=head1 DESCRIPTION

This role provides the fluent certificate and issuer builders documented
in the README's cert-manager section. Methods on the top half
(C<for_domains>, C<with_issuer>, C<store_in_secret>, C<add_ip_san>,
C<renew_before>) operate on C<Certificate> CRDs; methods on the bottom
half (C<letsencrypt>, C<self_signed>, C<ca>, C<add_http01_solver>,
C<add_dns01_solver>) operate on C<Issuer> / C<ClusterIssuer> CRDs. They
are defined on the same role because the underlying spec shape overlaps
and the consumer's CRD classes typically declare both.

The two halves can be composed on the same class or split across two --
the role does not enforce separation. Each setter returns C<$self>, so
the chain reads top-to-bottom in declaration order regardless of which
half each call belongs to.

Validation is performed up-front: C<add_ip_san> croaks on a non-IP value,
C<letsencrypt> croaks if C<email> is missing, and C<ca> croaks if
C<secret> is missing. Croak rather than silent skip -- the consumer
should not ship a manifest that the cluster will reject.

=head2 for_domains

    $cert->for_domains(@domains);

Adds C<@domains> to the certificate's C<spec.dnsNames> array. Existing
entries are preserved; duplicates are not deduplicated. This is the
caller-facing way to populate the SAN list for a Certificate CRD -- the
common name (CN) is taken from the first entry by cert-manager.
Returns C<$self> for chaining.

    $cert->for_domains('example.com', '*.example.com');

=head2 with_issuer

    $cert->with_issuer($name, kind => 'Issuer', group => 'cert-manager.io');

Sets C<spec.issuerRef> to point at the named issuer. C<kind> defaults to
C<Issuer> and C<group> to C<cert-manager.io>; pass C<kind =E<gt>
'ClusterIssuer'> for cluster-scoped issuers. Returns C<$self> for chaining.

    $cert->with_issuer('letsencrypt-prod', kind => 'ClusterIssuer');

=head2 store_in_secret

    $cert->store_in_secret($secret_name);

Sets C<spec.secretName> to the Kubernetes Secret name cert-manager should
write the issued certificate into. Returns C<$self> for chaining.

    $cert->store_in_secret('example-tls');

=head2 add_ip_san

    $cert->add_ip_san(@ips);

Adds C<@ips> to the certificate's C<spec.ipAddresses> array after
validating each one through L<IO::K8s::Types::Net/IPAddress>. Croaks if any
value is not a valid IPv4 or IPv6 address. Duplicates are not deduplicated.
Returns C<$self> for chaining.

    $cert->add_ip_san('10.0.0.1', '192.168.1.1');

=head2 renew_before

    $cert->renew_before(days => $n);
    $cert->renew_before(hours => $n);

Sets C<spec.renewBefore> from either C<days> or C<hours>. The value is
formatted as a Go duration string C<"<n>h0m0s"> -- the wire format
cert-manager accepts. Pass exactly one of the two keys; if both are given
C<days> wins. Returns C<$self> for chaining.

=head2 letsencrypt

    $issuer->letsencrypt(email => $addr, production => 1, secret => 'le-account');

Configures C<spec.acme> to obtain certificates from Let's Encrypt. The
C<email> option is mandatory and croaks if missing; C<production =E<gt> 1>
selects the production ACME directory and C<0> (the default) selects the
staging directory. C<secret> names the Secret that holds the ACME account
private key (defaults to C<letsencrypt-account-key>). Returns C<$self> for
chaining.

    $issuer->letsencrypt(email => 'ops@example.com', production => 1);

=head2 self_signed

    $issuer->self_signed;

Configures C<spec.selfSigned> as an empty hash -- cert-manager's signal
that the issuer issues certificates from itself. This is the issuer-side
counterpart of the self-signed CA bootstrapping flow. Returns C<$self>
for chaining.

=head2 ca

    $issuer->ca(secret => 'my-ca-key');

Configures C<spec.ca> with the Secret name holding the CA private key and
certificate. C<secret> is required and croaks if missing. Returns C<$self>
for chaining.

    $issuer->ca(secret => 'internal-ca');

=head2 add_http01_solver

    $issuer->add_http01_solver(class => 'nginx');

Appends an HTTP-01 challenge solver to C<spec.acme.solvers>. The solver
configures cert-manager to satisfy ACME challenges via an Ingress; pass
C<class =E<gt> $name> to write that exact C<ingress.class> value. Without
C<class>, this method emits an empty C<ingress> block and does not choose an
Ingress class. Returns C<$self> for chaining.

    $issuer->add_http01_solver(class => 'nginx');

=head2 add_dns01_solver

    $issuer->add_dns01_solver(provider => 'cloudflare', secret => 'cf-token', key => 'api-token');
    $issuer->add_dns01_solver(provider => 'route53', region => 'us-east-1');
    $issuer->add_dns01_solver(provider => 'acme-dns');

Appends a DNS-01 challenge solver to C<spec.acme.solvers>. The
C<provider> option selects the underlying solver block -- C<cloudflare>
and C<route53> get the matching cloud-specific shape; any other provider
name is written as a bare C<< { provider =E<gt> {} } >> block, leaving
the details for the consumer to fill in. C<secret> / C<key> are
Cloudflare-specific (the Kubernetes Secret holding the API token and the
key inside that Secret, defaulting to C<api-token>); C<region> is
Route53-specific. Returns C<$self> for chaining.

=head1 SEE ALSO

L<IO::K8s::CertManager>, L<IO::K8s::Types::Net>, L<IO::K8s::APIObject>

=cut

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
