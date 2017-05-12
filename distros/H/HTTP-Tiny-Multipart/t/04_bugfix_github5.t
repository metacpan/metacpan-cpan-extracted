#!perl

use strict;
use warnings;

use HTTP::Tiny;
use HTTP::Tiny::Multipart;

use Test::More;

{
  no warnings 'redefine';
  *HTTP::Tiny::request = sub { return @_ };
}

my $ua = HTTP::Tiny->new;

{
    my $orig_url = 'http://perl-services.de';

    $orig_url =~ s/(http:)/https:/g;

    my ($obj, $type, $url, $data) = $ua->post_multipart(
        $orig_url,
        [ field1 => 'test' ],
        {
            headers => {
                'Content-Type' => 'multipart/form-data; encoding utf-8',
            },
        },
    );

    is $type, 'POST';
    is $url,  'https://perl-services.de';

    ok $data->{content};
    my ($boundary) = split /\x0d/, $data->{content};

    like $boundary, qr/\A-+\w+\z/;

    my ($plain_boundary) = $boundary =~ m{\A-+(\w+)};

    is_deeply $data, {
        headers => {
            'content-type' => "multipart/form-data; boundary=" . $plain_boundary . '; encoding utf-8',
        },
        content => "$boundary\x0d\x0aContent-Disposition: form-data; name=\"field1\"\x0d\x0a\x0d\x0atest\x0d\x0a$boundary--\x0d\x0a",
    };
}

{
    my $orig_url = 'http://perl-services.de';

    $orig_url =~ s/(http:)/https:/g;

    my ($obj, $type, $url, $data) = $ua->post_multipart(
        $orig_url,
        [ field1 => 'test' ],
    );

    is $type, 'POST';
    is $url,  'https://perl-services.de';

    ok $data->{content};
    my ($boundary) = split /\x0d/, $data->{content};

    like $boundary, qr/\A-+\w+\z/;

    my ($plain_boundary) = $boundary =~ m{\A-+(\w+)};

    is_deeply $data, {
        headers => {
            'content-type' => "multipart/form-data; boundary=" . $plain_boundary,
        },
        content => "$boundary\x0d\x0aContent-Disposition: form-data; name=\"field1\"\x0d\x0a\x0d\x0atest\x0d\x0a$boundary--\x0d\x0a",
    };
}

done_testing();
