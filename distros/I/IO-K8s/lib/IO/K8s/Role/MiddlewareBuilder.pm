package IO::K8s::Role::MiddlewareBuilder;
# ABSTRACT: Role for building Traefik middleware configuration
our $VERSION = '1.108';
use Moo::Role;

# The fluent setters below build the spec through IO::K8s::Role::SpecBuilder
# rather than by hand, so that role is a hard dependency of this one (k103).
# IO::K8s::Role::APIObject composes SpecBuilder for every top-level Kind, so
# these are satisfied for anything built with IO::K8s::APIObject; a class
# that composes this role without them now fails at composition time,
# naming the missing method, instead of at the first setter call.
requires qw( spec_hash spec_set );


sub rate_limit {
    my ($self, %opts) = @_;
    $self->spec_set('rateLimit', {
        $opts{average} ? (average => $opts{average}) : (),
        $opts{burst}   ? (burst   => $opts{burst})   : (),
        $opts{period}  ? (period  => $opts{period})  : (),
    });
    return $self;
}


sub basic_auth {
    my ($self, %opts) = @_;
    $self->spec_set('basicAuth', {
        $opts{secret} ? (secret => $opts{secret}) : (),
        $opts{realm}  ? (realm  => $opts{realm})  : (),
    });
    return $self;
}


sub strip_prefix {
    my ($self, @prefixes) = @_;
    $self->spec_set('stripPrefix', { prefixes => \@prefixes });
    return $self;
}


sub redirect_https {
    my ($self) = @_;
    $self->spec_set('redirectScheme', { scheme => 'https', permanent => 1 });
    return $self;
}


sub add_request_header {
    my ($self, $key, $value) = @_;
    # Header names may legally contain dots; write into the map directly.
    $self->spec_hash('headers.customRequestHeaders')->{$key} = $value;
    return $self;
}


sub add_response_header {
    my ($self, $key, $value) = @_;
    $self->spec_hash('headers.customResponseHeaders')->{$key} = $value;
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::MiddlewareBuilder - Role for building Traefik middleware configuration

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    package My::TraefikMiddleware;
    use IO::K8s::APIObject
        api_version     => 'traefik.io/v1alpha1',
        resource_plural => 'middlewares';
    with 'IO::K8s::Role::MiddlewareBuilder';

    package main;
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
    my $mw = $k8s->new_object('Middleware',
        metadata => { name => 'api-limits', namespace => 'default' },
    );
    $mw->rate_limit(average => 100, burst => 200)
       ->strip_prefix('/api')
       ->redirect_https;

=head1 DESCRIPTION

This role provides the fluent Traefik B<HTTP> middleware builders
documented in the README's Traefik section. Each method writes the
corresponding block under the C<spec> key Traefik's C<Middleware> CRD
expects, so the chain mirrors what a user would compose in YAML.

It applies to the HTTP C<Middleware> kind only. Traefik's TCP middleware
is a different, much smaller schema and honours none of these blocks, so
it has a role of its own -- L<IO::K8s::Role::MiddlewareTCPBuilder>, which
L<IO::K8s::Traefik::V1alpha1::MiddlewareTCP> composes.

Each setter either replaces or extends its target block:

=over

=item * C<rate_limit>, C<basic_auth>, C<strip_prefix>, C<redirect_https>
overwrite the corresponding C<spec> key each time.

=item * C<add_request_header> / C<add_response_header> accumulate entries
under the same C<headers> parent block -- chained calls on the same parent
append rather than replace.

=back

Apply this role to any class whose C<spec> field is the Traefik
Middleware wire schema. The bundled Traefik CRD
L<IO::K8s::Traefik::V1alpha1::Middleware> is the obvious target, but the
role composes on custom CRD classes too.

=head2 rate_limit

    $mw->rate_limit(average => $n, burst => $n, period => $duration);

Configures the Traefik rateLimit middleware. C<average> is the allowed
average request rate and C<burst> the maximum instantaneous queue depth;
C<period> is the averaging window and is optional. Only values Perl treats as
true appear in the resulting C<spec.rateLimit> hash, so an empty call or
falsey values such as C<0> and C<''> write C<< {} >> rather than a populated
block. Returns C<$self> for chaining.

    $mw->rate_limit(average => 100, burst => 200, period => '1s');

=head2 basic_auth

    $mw->basic_auth(secret => $name, realm => $string);

Configures the Traefik basicAuth middleware. C<secret> is the name of a
Kubernetes Secret containing the htpasswd file; C<realm> is the
authentication realm shown to the user (optional). Returns C<$self> for
chaining.

    $mw->basic_auth(secret => 'admins', realm => 'Admin Area');

=head2 strip_prefix

    $mw->strip_prefix(@prefixes);

Configures the Traefik stripPrefix middleware to remove each prefix in
C<@prefixes> from incoming request paths. The prefixes are written as a
single C<< { prefixes =E<gt> [...] } >> block, replacing any prior
stripPrefix block. Pass an empty list to emit an empty
C<stripPrefix.prefixes> array. Returns C<$self> for chaining.

    $mw->strip_prefix('/api', '/v1');

=head2 redirect_https

    $mw->redirect_https;

Configures the Traefik redirectScheme middleware to issue a permanent 301
redirect from the current listener to C<https>. The wire block is
C<< { scheme =E<gt> 'https', permanent =E<gt> 1 } >>. Returns C<$self> for
chaining.

=head2 add_request_header

    $mw->add_request_header($key, $value);

Adds a header that Traefik will inject into every request as it forwards
to the upstream backend. Writes the
C<spec.headers.customRequestHeaders.$key = $value> shape. If the same
C<$key> is added twice the last value wins. Returns C<$self> for chaining.

    $mw->add_request_header('X-Forwarded-User', 'anonymous');

=head2 add_response_header

    $mw->add_response_header($key, $value);

Adds a header that Traefik will inject into every response as it returns
to the client. Writes the
C<spec.headers.customResponseHeaders.$key = $value> shape. If the same
C<$key> is added twice the last value wins. Returns C<$self> for chaining.

    $mw->add_response_header('X-Frame-Options', 'DENY');

=head1 SEE ALSO

L<IO::K8s::Traefik>, L<IO::K8s::Role::MiddlewareTCPBuilder>,
L<IO::K8s::Role::SpecBuilder>, L<IO::K8s::APIObject>

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
