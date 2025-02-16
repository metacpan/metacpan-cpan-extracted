package HTTP::SecureHeaders;
use strict;
use warnings;

use Carp ();
use Scalar::Util ();

our $VERSION = "0.02";

our %DEFAULT_HEADERS = (
    content_security_policy           => "default-src 'self' https:; font-src 'self' https: data:; img-src 'self' https: data:; object-src 'none'; script-src https:; style-src 'self' https: 'unsafe-inline'",
    strict_transport_security         => 'max-age=631138519',
    x_content_type_options            => 'nosniff',
    x_download_options                => 'noopen',
    x_frame_options                   => 'SAMEORIGIN',
    x_permitted_cross_domain_policies => 'none',
    x_xss_protection                  => '1; mode=block',
    referrer_policy                   => 'strict-origin-when-cross-origin',
);

our %HTTP_FIELD_MAP = (
    content_security_policy           => 'Content-Security-Policy',
    strict_transport_security         => 'Strict-Transport-Security',
    x_content_type_options            => 'X-Content-Type-Options',
    x_download_options                => 'X-Download-Options',
    x_frame_options                   => 'X-Frame-Options',
    x_permitted_cross_domain_policies => 'X-Permitted-Cross-Domain-Policies',
    x_xss_protection                  => 'X-XSS-Protection',
    referrer_policy                   => 'Referrer-Policy',
);

use constant OPT_OUT => \"";

sub new {
    my ($class, %args) = @_;

    my %fields = (%DEFAULT_HEADERS, %args);

    for my $field (keys %fields) {
        unless (exists $HTTP_FIELD_MAP{$field}) {
            Carp::croak sprintf('unknown HTTP field. %s', $field);
        }

        my $value = $fields{$field};
        my $checker = $class->can("check_$field");
        unless ($checker) {
            Carp::croak sprintf('cannot find check function. %s', "check_$field")
        }

        # undef value is available for optout from headers
        next unless defined $value;

        unless ($checker->($value)) {
            Carp::croak sprintf('invalid HTTP header value. %s:%s', $field, $value);
        }
    }

    bless \%fields, $class;
}

sub apply {
    my ($self, $headers) = @_;

    my @fields = keys %$self;
    for my $field (@fields) {
        $self->_apply($headers, $field);
    }
}

sub _apply {
    my ($self, $headers, $field) = @_;

    my $http_field = $HTTP_FIELD_MAP{$field};

    unless (Scalar::Util::blessed($headers)) {
        Carp::croak sprintf('headers must be HTTP::Headers or HasMethods["exists","get","set"]. %s', $headers);
    }

    if ($headers->isa('HTTP::Headers')) {
        if (defined $headers->header($http_field)) {
            if ($headers->header($http_field) eq OPT_OUT) {
                $headers->header($http_field, undef)
            }
        }
        else {
            $headers->header($http_field, $self->{$field})
        }
    }
    elsif ($headers->can('exists') && $headers->can('get') && $headers->can('set')) {
        if (defined $headers->get($http_field)) {
            if ($headers->get($http_field) eq OPT_OUT) {
                $headers->set($http_field, undef);
            }
        }
        elsif (!$headers->exists($http_field)) {
            $headers->set($http_field, $self->{$field})
        }
    }
    else {
        Carp::croak sprintf('unknown headers: %s', $headers);
    }
}

# refs https://w3c.github.io/webappsec-csp/#csp-header
{
    my $directive_map = {
        # TODO implements directive_value checker
        'child-src'       => sub { 1 }, # serialized-source-list
        'connect-src'     => sub { 1 }, # serialized-source-list
        'default-src'     => sub { 1 }, # serialized-source-list
        'font-src'        => sub { 1 }, # serialized-source-list
        'frame-src'       => sub { 1 }, # serialized-source-list
        'img-src'         => sub { 1 }, # serialized-source-list
        'manifest-src'    => sub { 1 }, # serialized-source-list
        'media-src'       => sub { 1 }, # serialized-source-list
        'object-src'      => sub { 1 }, # serialized-source-list
        'prefetch-src'    => sub { 1 }, # serialized-source-list
        'script-src'      => sub { 1 }, # serialized-source-list
        'script-src-elem' => sub { 1 }, # serialized-source-list
        'script-src-attr' => sub { 1 }, # serialized-source-list
        'style-src'       => sub { 1 }, # serialized-source-list
        'style-src-elem'  => sub { 1 }, # serialized-source-list
        'style-src-attr'  => sub { 1 }, # serialized-source-list
        'webrtc'          => sub { $_[0] eq "'allow'" or $_[0] eq "'block'" },
        'worker-src'      => sub { 1 }, # serialized-source-list
        'base-uri'        => sub { 1 }, # serialized-source-list
        'sandbox'         => sub { 1 }, # "" / token *( required-ascii-whitespace token ),
        'form-action'     => sub { 1 }, # serialized-source-list
        'frame-ancestors' => sub { 1 }, # ancestor-source-list
        'navigate-to'     => sub { 1 }, # serialized-source-list
        'report-uri'      => sub { 1 }, # uri-reference *( required-ascii-whitespace uri-reference )
        'report-to'       => sub { 1 }, # token
    };

    sub check_content_security_policy {
        # serialized-directive *( optional-ascii-whitespace ";" [ optional-ascii-whitespace serialized-directive ] )

        # serialized-directive = directive-name [ required-ascii-whitespace directive-value ]
        # directive-name       = 1*( ALPHA / DIGIT / "-" )
        # directive-value      = *( required-ascii-whitespace / ( %x21-%x2B / %x2D-%x3A / %x3C-%x7E ) )
        #                        ; Directive values may contain whitespace and VCHAR characters,
        #                        ; excluding ";" and ",". The second half of the definition
        #                        ; above represents all VCHAR characters (%x21-%x7E)
        #                        ; without ";" and "," (%x3B and %x2C respectively)

        my @directives = split ';', $_[0];
        for my $directive (@directives) {
            my ($name, $value) = $directive =~ m!\s?([A-Za-z0-9\-]+)\s([^\s;,][^;,]+)!;
            unless ($name && $value) {
                return !!0
            }
            my $checker = $directive_map->{$name};
            unless ($checker) {
                return !!0
            }
            unless ($checker->($value)) {
                return !!0
            }
        }
        return !!1;
    }
}


# refs https://datatracker.ietf.org/doc/html/rfc6797
# refs https://www.chromium.org/hsts/
sub check_strict_transport_security {
    $_[0] =~ m!\Amax-age=(?:[0-9]+)(?:\s?;\s?includeSubDomains)?(?:\s?;\s?preload)?\z!
}

# refs http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
sub check_x_content_type_options {
    $_[0] eq 'nosniff'
}

# refs http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
sub check_x_download_options {
    $_[0] eq 'noopen'
}

# refs https://www.rfc-editor.org/rfc/rfc7034#section-2
sub check_x_frame_options {
    $_[0] eq 'SAMEORIGIN' or
    $_[0] eq 'DENY'
    # ALLOW-FROM # deprecated
}

# refs https://www.adobe.com/devnet-docs/acrobatetk/tools/AppSec/CrossDomain_PolicyFile_Specification.pdf
sub check_x_permitted_cross_domain_policies {
    $_[0] =~ m!\A(?:none|master-only|by-content-type|by-ftp-filename|all)\z!
}

# refs https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection
sub check_x_xss_protection {
    $_[0] eq '0' or
    $_[0] eq '1' or
    $_[0] eq '1; mode=block'

    # `report=<report-uri>` directive not recommend
}

# refs https://w3c.github.io/webappsec-referrer-policy/#referrer-policy-header
{
    my $referrer_policy_values = {
        'strict-origin-when-cross-origin' => 1,
        'no-referrer'                     => 1,
        'no-referrer-when-downgrade'      => 1,
        'same-origin'                     => 1,
        'origin'                          => 1,
        'strict-origin'                   => 1,
        'origin-when-cross-origin'        => 1,
        'unsafe-url'                      => 1,
    };

    # empty string cannot pass.
    sub check_referrer_policy {
        exists $referrer_policy_values->{$_[0]}
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

HTTP::SecureHeaders - manage security headers with many safe defaults

=head1 SYNOPSIS

    use HTTP::SecureHeaders;
    use Plack::Util;

    my $secure_headers = HTTP::SecureHeaders->new(
        'content_security_policy' => "default-src 'self' https:",
    );

    my $data = [];
    my $headers = Plack::Util::headers($data);

    $secure_headers->apply($headers);

    $data
    # =>
    #    'Content-Security-Policy'           => "default-src 'self' https:",
    #    'Strict-Transport-Security'         => 'max-age=631138519',
    #    'X-Content-Type-Options'            => 'nosniff',
    #    'X-Download-Options'                => 'noopen',
    #    'X-Frame-Options'                   => 'SAMEORIGIN',
    #    'X-Permitted-Cross-Domain-Policies' => 'none',
    #    'X-XSS-Protection'                  => '1; mode=block',
    #    'Referrer-Policy'                   => 'strict-origin-when-cross-origin',

=head1 DESCRIPTION

HTTP::SecureHeaders manages HTTP headers to protect against XSS attacks, insecure connections, content type sniffing, etc.

B<NOTE>: To protect against these attacks, sanitization of user input values and other protections are also required.

=head1 METHODS

=head2 HTTP::SecureHeaders->new(%args)

Create an object that is a collection of secure headers that you wish to apply to the HTTP Header. Following headers are available and these values are the default values, refer to the following sites L<https://github.com/github/secure_headers#default-values>.

    my $secure_headers = HTTP::SecureHeaders->new(
        content_security_policy           => default-src 'self' https:; font-src 'self' https: data:; img-src 'self' https: data:; object-src 'none'; script-src https:; style-src 'self' https: 'unsafe-inline',
        strict_transport_security         => 'max-age=631138519',
        x_content_type_options            => 'nosniff',
        x_download_options                => 'noopen',
        x_frame_options                   => 'SAMEORIGIN',
        x_permitted_cross_domain_policies => 'none',
        x_xss_protection                  => '1; mode=block',
        referrer_policy                   => 'strict-origin-when-cross-origin',
    );

=head2 $self->apply($headers)

Apply the HTTP headers set in HTTP::SecureHeaders to $headers.
$headers must be HTTP::Headers or Plack::Util::headers ( HasMethods['exists', 'get', 'set'] ).

B<NOTE>: HTTP header already set in $headers are not applied:

    my $secure_headers = HTTP::SecureHeaders->new(
        'x_frame_options' => 'SAMEORIGIN',
    );

    my $res = Plack::Response->new;
    $res->header('X-Frame-Options', 'DENY');

    $secure_headers->apply($res->headers);
    $res->header('X-Frame-Options') # => DENY / NOT SAMEORIGIN!


=head2 NOTE

=head3 Remove unnecessary HTTP header

For unnecessary HTTP header, use undef in the constructor.

    my $secure_headers = HTTP::SecureHeaders->new(
        content_security_policy => undef,
    )

    my $res = Plack::Response->new;
    $secure_headers->apply($res->headers);
    $res->header('Content-Security-Policy'); # => undef

For temporarily unnecessary HTTP header, use OPT_OUT:

    my $secure_headers = HTTP::SecureHeaders->new();

    my $res = Plack::Response->new;
    $res->header('Content-Security-Policy', HTTP::SecureHeaders::OPT_OUT);

    $secure_headers->apply($res->headers);
    $res->header('Content-Security-Policy'); # => undef

B<NOTE>: If you use undef instead of OPT_OUT, HTTP::Headers cannot remove them.

    my $secure_headers = HTTP::SecureHeaders->new();

    my $res = Plack::Response->new;
    $res->header('Content-Security-Policy', undef); # use undef instead of OPT_OUT

    $secure_headers->apply($res->headers);
    $res->header('Content-Security-Policy'); # => SAMEORIGIN / NO!!!


=head1 SEE ALSO

=over 4

=item L<Plack::Middleware::SecureHeaders>

=item L<https://github.com/github/secure_headers>

=item L<https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html>

=back

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

