package Finance::GDAX::Lite;

our $DATE = '2018-06-11'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Digest::SHA qw(hmac_sha256_base64);
use MIME::Base64 qw(decode_base64);
use Time::HiRes qw(time);

my $url_prefix = "https://api.gdax.com";

sub new {
    my ($class, %args) = @_;

    my $self = {};
    if (my $key = delete $args{key}) {
        $self->{key} = $key;
    }
    if (my $secret = delete $args{secret}) {
        $self->{secret} = $secret;
    }
    if (my $passphrase = delete $args{passphrase}) {
        $self->{passphrase} = $passphrase;
    }
    if (keys %args) {
        die "Unknown argument(s): ".join(", ", sort keys %args);
    }

    require HTTP::Tiny;
    $self->{_http} = HTTP::Tiny->new;

    require JSON::XS;
    $self->{_json} = JSON::XS->new;

    require URI::Encode;
    $self->{_urienc} = URI::Encode->new;

    bless $self, $class;
}

sub _get_json {
    my ($self, $url) = @_;

    log_trace("JSON API request: %s", $url);

    my $res = $self->{_http}->get($url);
    die "Can't retrieve $url: $res->{status} - $res->{reason}"
        unless $res->{success};
    my $decoded;
    eval { $decoded = $self->{_json}->decode($res->{content}) };
    die "Can't decode response from $url: $@" if $@;

    log_trace("JSON API response: %s", $decoded);

    $decoded;
}

sub _request {
    my ($self, $is_private, $method, $request_path, $params) = @_;

    $params //= {};

    if ($is_private) {
        $self->{key} or die "Please supply API key in new()";
        $self->{secret} or die "Please supply API secret in new()";
        $self->{passphrase} or die "Please supply API passphrase in new()";
    }

    my $time = $ENV{FINANCE_GDAX_LITE_DEBUG_TIME} // sprintf "%.3f", time();
    log_trace("API %s request [%s]: %s %s %s",
              $is_private ? "private" : "public",
              $time, $method, $request_path, $params);

    my $url = "$url_prefix$request_path";

    my $body;
    my $encoded_body = '';
    if ($method eq 'POST') {
        $body = $encoded_body = $self->{_json}->encode($params);
    } else {
        if (keys %$params) {
            my $qs = '?' . join(
                "&",
                map { $self->{_urienc}->encode($_ // ''). "=" .
                          $self->{_urienc}->encode($params->{$_} // '') }
                    sort keys(%$params),
            );
            $url .= $qs;
            $encoded_body = $qs;
        }
    }

    my $signature;
    if ($is_private) {
        my $what = $time . $method . $request_path . $encoded_body;
        $signature = hmac_sha256_base64($what, decode_base64($self->{secret}));
        while (length($signature) % 4) { $signature .= '=' }
    }

    my $options = {
        headers => {
            ("CB-ACCESS-KEY"  => $self->{key}) x !!$is_private,
            ("CB-ACCESS-SIGN" => $signature  ) x !!$is_private,
            ("CB-ACCESS-TIMESTAMP" => $time  ) x !!$is_private,
            ("CB-ACCESS-PASSPHRASE" => $self->{passphrase}) x !!$is_private,,
            "Content-Type"   => "application/json",
            "Accept"         => "application/json",
        },
        (content => $body) x !!defined($body),
    };

    my $res = $self->{_http}->request($method, $url, $options);

    if ($res->{headers}{'content-type'} =~ m!application/json!) {
        $res->{content} = $self->{_json}->decode($res->{content});
    }

    log_trace("API response [%s]: %s", $time, $res->{content});

    my $reason = $res->{reason};
    if ($res->{status} != 200 &&
            ref($res->{content}) eq 'HASH' && $res->{content}{message}) {
        $reason .= ": $res->{content}{message}";
    }
    [$res->{status}, $reason, $res->{content}];
}

sub public_request {
    my $self = shift;
    $self->_request(0, @_);
}

sub private_request {
    my $self = shift;
    $self->_request(1, @_);
}

1;
# ABSTRACT: Client API library for GDAX (lite edition)

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::GDAX::Lite - Client API library for GDAX (lite edition)

=head1 VERSION

This document describes version 0.002 of Finance::GDAX::Lite (from Perl distribution Finance-GDAX-Lite), released on 2018-06-11.

=head1 SYNOPSIS

 use Finance::GDAX::Lite;

 my $gdax = Finance::GDAX::Lite->new(
     key        => 'Your API key',
     secret     => 'Your API secret',
     passphrase => 'Your API passphrase',
 );

 my $res = $gdax->public_request(GET => "/products");
 # [
 #   200,
 #   "OK",
 #   [
 #     {
 #       base_currency => "BCH",
 #       base_max_size => 200,
 #       ...
 #     },
 #     ...
 #   ]
 # ]

 my $res = $gdax->private_request(GET => "/coinbase-accounts");
 # [
 #   200,
 #   "OK",
 #   [
 #     {
 #       active => 1,
 #       balance => "0.00",
 #       currency => "USD",
 #       name => "USD wallet",
 #       ...
 #     },
 #     ...
 #   ]
 # ]

 my $res = $gdax->private_request(POST => "/reports", {
     type => "fills",
     start_date => "2018-02-01T00:00:00.000Z",
     end_date   => "2018-02-01T00:00:00.000Z",
 });

=head1 DESCRIPTION

L<https://gdax.com> is a US cryptocurrency exchange. This module provides a Perl
wrapper for GDAX's API. This module is an alternative to L<Finance::GDAX::API>
and is more lightweight/barebones (no entity objects, Moose, etc). Please peruse
the GDAX API reference to see which API endpoints are available.

=head1 METHODS

=head2 new

Usage: new(%args)

Constructor. Known arguments:

=over

=item * key

=item * secret

=item * passphrase

=back

=head2 public_request

Usage: public_request($method, $request_path [, \%params ]) => [$status_code, $message, $content]

Will send HTTP request and decode the JSON body for you.

=head2 private_request

Usage: public_request($method, $request_path [, \%params ]) => [$status_code, $message, $content]

Will send and sign HTTP request and decode the JSON body for you.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-GDAX-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-GDAX-Lite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-GDAX-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

GDAX API Reference, L<https://docs.gdax.com/>

L<Finance::GDAX::API>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
