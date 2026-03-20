package IO::K8s::Role::CertManaged;
# ABSTRACT: Role for cert-manager certificate and issuer management
our $VERSION = '1.009';
use Moo::Role;
use Carp qw(croak);

# --- Certificate methods ---

sub for_domains {
    my ($self, @domains) = @_;
    my $spec = $self->spec // {};
    my $existing = $spec->{dnsNames} // [];
    push @$existing, @domains;
    $spec->{dnsNames} = $existing;
    $self->spec($spec);
    return $self;
}

sub with_issuer {
    my ($self, $name, %opts) = @_;
    my $spec = $self->spec // {};
    $spec->{issuerRef} = {
        name  => $name,
        kind  => $opts{kind} // 'Issuer',
        $opts{group} ? (group => $opts{group}) : (group => 'cert-manager.io'),
    };
    $self->spec($spec);
    return $self;
}

sub store_in_secret {
    my ($self, $secret_name) = @_;
    my $spec = $self->spec // {};
    $spec->{secretName} = $secret_name;
    $self->spec($spec);
    return $self;
}

sub add_ip_san {
    my ($self, @ips) = @_;
    require IO::K8s::Types::Net;
    for my $ip (@ips) {
        croak "'$ip' is not a valid IP address"
            unless IO::K8s::Types::Net::IPAddress()->check($ip);
    }
    my $spec = $self->spec // {};
    my $existing = $spec->{ipAddresses} // [];
    push @$existing, @ips;
    $spec->{ipAddresses} = $existing;
    $self->spec($spec);
    return $self;
}

sub renew_before {
    my ($self, %opts) = @_;
    my $spec = $self->spec // {};
    if ($opts{days}) {
        $spec->{renewBefore} = ($opts{days} * 24) . 'h0m0s';
    } elsif ($opts{hours}) {
        $spec->{renewBefore} = $opts{hours} . 'h0m0s';
    }
    $self->spec($spec);
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

    my $spec = $self->spec // {};
    $spec->{acme} = {
        email  => $email,
        server => $server,
        privateKeySecretRef => { name => $opts{secret} // 'letsencrypt-account-key' },
    };
    $self->spec($spec);
    return $self;
}

sub self_signed {
    my ($self) = @_;
    my $spec = $self->spec // {};
    $spec->{selfSigned} = {};
    $self->spec($spec);
    return $self;
}

sub ca {
    my ($self, %opts) = @_;
    my $spec = $self->spec // {};
    $spec->{ca} = {
        secretName => $opts{secret} // croak('secret is required for ca'),
    };
    $self->spec($spec);
    return $self;
}

sub add_http01_solver {
    my ($self, %opts) = @_;
    my $spec = $self->spec // {};
    my $acme = $spec->{acme} //= {};
    my $solvers = $acme->{solvers} //= [];
    my $solver = { http01 => { ingress => {} } };
    $solver->{http01}{ingress}{class} = $opts{class} if $opts{class};
    push @$solvers, $solver;
    $self->spec($spec);
    return $self;
}

sub add_dns01_solver {
    my ($self, %opts) = @_;
    my $spec = $self->spec // {};
    my $acme = $spec->{acme} //= {};
    my $solvers = $acme->{solvers} //= [];
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
    push @$solvers, { dns01 => \%dns01 };
    $self->spec($spec);
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::CertManaged - Role for cert-manager certificate and issuer management

=head1 VERSION

version 1.009

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

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

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
