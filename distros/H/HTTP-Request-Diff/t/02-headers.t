#!perl
use 5.020;
no warnings;
use Test2::V0;
use Data::Dumper;

use HTTP::Request;
use YAML 'Load';

use HTTP::Request::Diff;

# Our hacky data parser
my $tests = do { local($/); <DATA> };
my @tests = map {;
    my @pairs = /--- (\w+)\s+(.*?)\r?\n(?=---|\z)/msg
        or die "Bad line: $_";
    +{
        @pairs
    }
    } $tests =~ /(?:===\s+)(.*?)(?====|\z)/msg;

plan tests => 1 * @tests;

for my $block (@tests) {
    $block->{reference} =~ s!\r?\n!\r\n!sg;
    $block->{actual} =~ s!\r?\n!\r\n!sg;
    my $reference = $block->{reference};
    my ($name_v)  = $reference =~ m!^(.*?)$!;
    my $actual    = $block->{actual};
    my $result    = Load($block->{diff}) // [];

    for( $result->@* ) {
        $_->{actual} =~ s/\s+\z//
            if $_->{actual};
        $_->{reference} =~ s/\s+\z//
            if $_->{reference};
    }
    my $name      = $block->{name} // $name_v;

    my $todo;
    $todo = todo( $block->{todo})
        if $block->{todo};

    my @constructor;
    if( $block->{constructor} ) {
        @constructor = map { %$_ } @{ Load( $block->{constructor}) };
    }

    my @diff = HTTP::Request::Diff
                   ->new(reference => $reference, @constructor)
                   ->diff( $actual );
    is \@diff, $result, $name
        or diag Dumper \@diff;
};

done_testing();

__DATA__
===
--- reference
GET / HTTP/1.1
--- actual
GET /foo HTTP/1.1
--- diff
- kind: value
  type: uri.path
  reference: /
  actual: /foo

===
--- name
Header difference
--- reference
GET / HTTP/1.1
Foo: bar


--- actual
GET / HTTP/1.1
Foo: baz


--- diff
- kind: value
  type: headers.Foo
  reference: bar
  actual: baz

===
--- name
Skip Content-Length header
--- constructor
- skip_headers:
    - Content-Length
--- reference
POST / HTTP/1.1
Content-Length: 3

foo
--- actual
POST / HTTP/1.1
Content-Length: 11

hello world
--- diff
- kind: value
  type: request.content
  reference: foo
  actual: hello world

===
--- name
Ignore Accept-Encoding header differences if header is present
--- constructor
- ignore_headers:
    - Accept-Encoding
--- reference
GET / HTTP/1.1
Accept-Encoding: gzip, deflate


--- actual
GET / HTTP/1.1
Accept-Encoding: gzip


--- diff

===
--- name
Catch Accept-Encoding header differences if missing
--- constructor
- ignore_headers:
    - Accept-Encoding
--- reference
GET / HTTP/1.1
Accept-Encoding: gzip, deflate


--- actual
GET / HTTP/1.1


--- diff
- kind: missing
  type: headers.Accept-Encoding
  reference: gzip, deflate
  actual:

===
--- name
Ignore Transfer-Encoding: chunked delimiters
--- constructor
- ignore_headers:
    - Accept-Encoding
--- reference
GET / HTTP/1.1
Accept-Encoding: gzip, deflate


--- actual
GET / HTTP/1.1
Accept-Encoding: gzip


--- diff

===
--- name
Find difference in header order
--- constructor
- mode: strict
--- reference
GET / HTTP/1.1
Content-Length: 0
Accept-Encoding: gzip


--- actual
GET / HTTP/1.1
Accept-Encoding: gzip
Content-Length: 0


--- diff
- kind: missing
  type: request.header_order
  reference:
  - Content-Length
  - Accept-Encoding
  - ~
  actual:
  - ~
  - Accept-Encoding
  - Content-Length
===
--- name
Handle/ignore different form boundaries
--- constructor
- mode: semantic
--- reference
POST / HTTP/1.1
Content-Type: multipart/form-data; boundary=xyzzy
Content-Length: 300

--xyzzy
Content-Disposition: form-data; name="a"

b
--xyzzy
Content-Disposition: form-data; name="c"

d
--xyzzy--

--- actual
POST / HTTP/1.1
Content-Type: multipart/form-data; boundary=20230908
Content-Length: 300

--20230908
Content-Disposition: form-data; name="a"

b
--20230908
Content-Disposition: form-data; name="c"

d
--20230908--

--- diff

===
--- name
Handle different form values instead of "content" diff
--- reference
POST /
Content-Length: 123
Content-Type: multipart/form-data; boundary=xyzzy

--xyzzy
Content-Disposition: form-data; name="a"

b
--xyzzy
Content-Disposition: form-data; name="c"

d
--xyzzy--

--- actual
POST /
Content-Length: 123
Content-Type: multipart/form-data; boundary=xyzzy

--xyzzy
Content-Disposition: form-data; name="a"

b
--xyzzy
Content-Disposition: form-data; name="c"

e
--xyzzy--

--- diff
- kind: value
  type: form.c
  reference:
  - d
  actual:
  - e
