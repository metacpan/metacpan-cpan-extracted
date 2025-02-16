package HTTPSecureHeadersTestApply;

use Test2::V0;

use HTTP::SecureHeaders;

our $CREATE_HEADERS;

our $DATA_HEADERS = sub {
    my ($headers) = @_;

    my %data = %$headers;
    return \%data;
};

our $GET_HEADERS = sub {
    my ($headers, $key) = @_;

    if ($headers->can('get')) {
        $headers->get($key)
    }
    elsif ($headers->can('header')) {
        $headers->header($key)
    }
};

sub create_headers { $CREATE_HEADERS->(@_) }
sub data_headers { $DATA_HEADERS->(@_) }
sub get_headers { $GET_HEADERS->(@_) }


sub main {
    subtest 'Default case' => sub {
        my $secure_headers = HTTP::SecureHeaders->new;
        my $headers = create_headers;

        $secure_headers->apply($headers);

        is data_headers($headers), {
            'Content-Security-Policy'           => "default-src 'self' https:; font-src 'self' https: data:; img-src 'self' https: data:; object-src 'none'; script-src https:; style-src 'self' https: 'unsafe-inline'",
            'Strict-Transport-Security'         => 'max-age=631138519',
            'X-Content-Type-Options'            => 'nosniff',
            'X-Download-Options'                => 'noopen',
            'X-Frame-Options'                   => 'SAMEORIGIN',
            'X-Permitted-Cross-Domain-Policies' => 'none',
            'X-XSS-Protection'                  => '1; mode=block',
            'Referrer-Policy'                   => 'strict-origin-when-cross-origin',
        };
    };

    subtest 'Customize HTTP::SecureHeaders' => sub {
        my $secure_headers = HTTP::SecureHeaders->new(
            content_security_policy           => "default-src 'self'",
            strict_transport_security         => 'max-age=631138519; includeSubDomains',
            x_content_type_options            => 'nosniff',
            x_download_options                => 'noopen',
            x_frame_options                   => 'DENY',
            x_permitted_cross_domain_policies => 'none',
            x_xss_protection                  => '1',
            referrer_policy                   => 'no-referrer',
        );

        my $headers = create_headers;

        $secure_headers->apply($headers);

        is data_headers($headers), {
            'Content-Security-Policy'           => "default-src 'self'",
            'Strict-Transport-Security'         => 'max-age=631138519; includeSubDomains',
            'X-Content-Type-Options'            => 'nosniff',
            'X-Download-Options'                => 'noopen',
            'X-Frame-Options'                   => 'DENY',
            'X-Permitted-Cross-Domain-Policies' => 'none',
            'X-XSS-Protection'                  => '1',
            'Referrer-Policy'                   => 'no-referrer',
        };
    };

    subtest 'HTTP header already set in $headers are not applied' => sub {
        my $secure_headers = HTTP::SecureHeaders->new(
            'x_frame_options' => 'SAMEORIGIN',
        );

        my $headers = create_headers(
            'X-Frame-Options' => 'DENY',
        );

        $secure_headers->apply($headers);
        is get_headers($headers, 'X-Frame-Options'), 'DENY';
    };

    subtest 'For unnecessary HTTP header, use undef in the constructor.' => sub {
        my $secure_headers = HTTP::SecureHeaders->new(
            content_security_policy => undef,
        );

        my $headers = create_headers;

        $secure_headers->apply($headers);
        is get_headers($headers, 'Content-Security-Policy'), undef;
    };

    subtest 'For temporarily unnecessary HTTP header, use OPT_OUT' => sub {
        my $secure_headers = HTTP::SecureHeaders->new;

        my $headers = create_headers(
            'Content-Security-Policy' => HTTP::SecureHeaders::OPT_OUT,
        );

        $secure_headers->apply($headers);
        is get_headers($headers, 'Content-Security-Policy'), undef;
    };

    subtest '(NOT Recommend usage) For temporarily unnecessary HTTP header, If use `undef`...' => sub {
        my $secure_headers = HTTP::SecureHeaders->new();

        my $headers = create_headers(
            'X-Frame-Options' => undef,
        );

        $secure_headers->apply($headers);

        if ($headers->can('exists')) {
            is get_headers($headers, 'X-Frame-Options'), undef,
                'When headers has `exists` method, then remove HTTP header';
        }
        else {
            is get_headers($headers, 'X-Frame-Options'), 'SAMEORIGIN',
                'When headers isa HTTP::Headers, then CANNOT remove HTTP header';
        }
    };
};

1;
