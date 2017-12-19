package Finance::BitFlip;

our $DATE = '2017-12-17'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Digest::SHA qw(hmac_sha512_hex);
use Time::HiRes qw(time);

my $url_prefix = "https://api.bitflip.cc/method/";

sub new {
    my ($class, %args) = @_;

    my $self = {};
    if (my $key = delete $args{key}) {
        $self->{key} = $key;
    }
    if (my $secret = delete $args{secret}) {
        $self->{secret} = $secret;
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

sub get_request {
    my ($self, $method_args) = @_;

    log_trace("API GET request: %s(%s)", $method_args);

    my $url = "$url_prefix$method_args";
    my $res = $self->{_http}->get($url);
    die "Can't retrieve $url: $res->{status} - $res->{reason}"
        unless $res->{success};
    my $decoded;
    eval { $decoded = $self->{_json}->decode($res->{content}) };
    die "Can't decode response from $url: $@" if $@;

    log_trace("API GET response: %s", $decoded);

    die "API response not an array: $decoded" unless ref $decoded eq 'ARRAY';
    die "API response is not success: $decoded->[0] - $decoded->[1]" if defined $decoded->[0];
    $decoded;
}

sub post_request {
    my ($self, $method, %args) = @_;

    $self->{key} or die "Please supply API key in new()";
    $self->{secret} or die "Please supply API secret in new()";

    my $time = time();
    my $form = {
        %args,
        # ms after 2015-01-01
        nonce => int(1000 * (time() - 1_420_045_200)),
    };

    log_trace("API POST request: %s", $form);

    my $encoded_form = $self->{_json}->encode($form);

    my $options = {
        headers => {
            "X-API-Token" => $self->{key},
            "X-API-Sign" => hmac_sha512_hex($encoded_form, $self->{secret}),

            # XXX why do i have to do this manually?
            "Content-Length" => length($encoded_form),
            "Content-Type" => "application/json",
        },
        content => $encoded_form,
    };

    my $url = "$url_prefix$method";
    my $res = $self->{_http}->post($url, $options);
    die "Can't retrieve $url: $res->{status} - $res->{reason}"
        unless $res->{success};
    my $decoded;
    eval { $decoded = $self->{_json}->decode($res->{content}) };
    die "Can't decode response from $url: $@" if $@;

    log_trace("API POST response: %s", $decoded);

    die "API response not an array: $decoded" unless ref $decoded eq 'ARRAY';
    die "API response is not success: $decoded->[0] - $decoded->[1]" if defined $decoded->[0];
    $decoded;
}

1;
# ABSTRACT: Trade with bitflip.li using Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::BitFlip - Trade with bitflip.li using Perl

=head1 VERSION

This document describes version 0.001 of Finance::BitFlip (from Perl distribution Finance-BitFlip), released on 2017-12-17.

=head1 SYNOPSIS

 use Finance::BitFlip;

You don't need API key (token) & secret if you are only accessing public
methods.

 my $bitflip = Finance::BitFlip->new(
     key    => 'Your API key (token)',
     secret => 'Your API secret',
 );

 my $res = $bitflip->get_request("server.getTime");
 # sample response: [undef, 1513509630600]

 my $res = $bitflip->post_request("market.getUserTrades", pair=>"xrb:usd");

=head1 DESCRIPTION

L<https://bitflip.li> is a Russian cryptocurrency exchange.

=head1 METHODS

=head2 new(%args)

Constructor. Known arguments:

=over

=item key

=item secret

=back

=head2 get_request($method) => array

=head2 post_request($method, %args) => array

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-BitFlip>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-BitFlip>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-BitFlip>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

API documentation, L<https://bitflip.li/apidoc>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
