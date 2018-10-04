use strict;
use warnings;

use Test::More;
plan tests => 44;

use lib 't/lib';
use HTTP::XSHeaders;
use MyTestUtils;

my $h = HTTP::XSHeaders->new;

my @methods = qw<
    clone clear init_header header_field_names
    push_header header remove_header remove_content_headers
    as_string_without_sort as_string scan
>;

my %croak_msg = (
    scan => qr{^Usage: HTTP::XSHeaders::scan},
);

foreach my $method (@methods) {
    # checking for failed values
    my $method_cb = HTTP::XSHeaders->can($method);
    eval { $method_cb->(undef); 1; }
    or do {
        my $error = $@ || 'Zombie error';
        like(
            $error,
            $croak_msg{$method} || qr{is not an instance of HTTP::XSHeaders},
            "$method(undef) croaks with message",
        );
    };

    eval { $method_cb->("str"); 1; }
    or do {
        my $error = $@ || 'Zombie error';
        like(
            $error,
            $croak_msg{$method} || qr{is not an instance of HTTP::XSHeaders},
            "$method(\"str\") croaks with message",
        );
    };
}

isa_ok( $h->clone, 'HTTP::XSHeaders' );

is( $h->clear(), undef, 'clear()' );

is( $h->init_header("kEy1", "value1"), undef, 'initialize first key' );
is( $h->init_header("kEy2", "value2"), undef, 'initialize second key' );
is( $h->header_field_names, 2, 'got two headers' );
is_deeply( [$h->header_field_names], ['Key1', 'Key2'], 'header_field_names' );

is( $h->push_header("kEy1", "value3"), undef, 'push_header method with two args' );

is( $h->header("key0"), undef, 'header method with arg' );
is( $h->header("key0", "value"), undef, 'header method with two args' );
is( $h->header("key0"), "value", 'getting header value for key' );

is_deeply( [$h->remove_header("Key9")], [], 'remove_header method with key and single value' );
is_deeply( [$h->remove_header("Key1")], [qw<value1 value3>], 'remove header with multiple values' );

$h->header("Expires", "never");
$h->header("Last_Modified", "yesterday");
$h->header("Content-Test", "works");

is( $h->remove_content_headers()->as_string(), <<'EOS', 'remove_content_headers->as_string' );
Expires: never
Last-Modified: yesterday
Content-Test: works
EOS

$h->header("AAA_header", "bilbo");

is( $h->as_string_without_sort(), <<'EOS', 'as_string_without_sort method' );
Key2: value2
Key0: value
Aaa-Header: bilbo
EOS

is( $h->as_string(), <<'EOS', 'as_string method' );
Aaa-Header: bilbo
Key0: value
Key2: value2
EOS

# test invalid call to scan
like(
    MyTestUtils::_try(sub { $h->scan() }),
    qr/Usage: HTTP::XSHeaders::scan/,
    'scan() without arguments',
);

like(
    MyTestUtils::_try(sub { $h->scan(undef) }),
    qr/Second argument must be a CODE reference/,
    'scan() without coderef',
);

is(
    $h->scan(sub {1} ),
    undef,
    'scan() with coderef',
);

like(
    MyTestUtils::_try(sub { HTTP::XSHeaders::init_header() }),
    qr/Usage: HTTP::XSHeaders::init_header/,
    'HTTP::XSHeaders::init_header()'
    );

like(
    MyTestUtils::_try(sub { $h->init_header() }),
    qr/init_header needs two arguments/,
    'init_header()'
);

like(
    MyTestUtils::_try(sub { $h->init_header(undef) }),
    qr/init_header needs two arguments/,
    'init_header(undef)'
);

like(
    MyTestUtils::_try(sub { $h->init_header(undef, undef) }),
    qr/init_header not called with a first string argument/,
    'init_header(undef, undef)'
);

done_testing;
