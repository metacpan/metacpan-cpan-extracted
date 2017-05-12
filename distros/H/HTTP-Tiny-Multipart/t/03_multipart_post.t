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
    my ($obj, $type, $url, $data) = $ua->post_multipart( 'http://perl-services.de', [ field1 => 'test' ] );
    is $type, 'POST';
    is $url,  'http://perl-services.de';

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
