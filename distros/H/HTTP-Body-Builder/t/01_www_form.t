use strict;
use warnings;
use utf8;
use Test::More;

use HTTP::Body::Builder::UrlEncoded;

subtest 'simple' => sub {
    my $builder = HTTP::Body::Builder::UrlEncoded->new();
    $builder->add_content('x' => 'y');
    $builder->add_content('foo' => 'bar');
    is $builder->as_string, 'x=y&foo=bar';
};

subtest 'binary' => sub {
    my $builder = HTTP::Body::Builder::UrlEncoded->new();
    $builder->add_content('x' => "y\0");
    is $builder->as_string, 'x=y%00';
};

subtest 'file' => sub {
    my $builder = HTTP::Body::Builder::UrlEncoded->new();
    eval {
        $builder->add_file('foo' => "t/dat/foo");
    };
    ok $@;
};

subtest 'constructor' => sub {
    my $builder = HTTP::Body::Builder::UrlEncoded->new(
        content => {'foo' => 42, 'bar' => 'hello', 'baz' => [ 1, 2 ]});
    $builder->add_content('x' => 'y');
    # We need to use like instead of looking at the whole string because we
    # just use keys to iterate of the hash passed to the constructor.
    like $builder->as_string, qr/foo=42/;
    like $builder->as_string, qr/bar=hello/;
    like $builder->as_string, qr/baz=1/;
    like $builder->as_string, qr/baz=2/;
    like $builder->as_string, qr/x=y/;
};

done_testing;

