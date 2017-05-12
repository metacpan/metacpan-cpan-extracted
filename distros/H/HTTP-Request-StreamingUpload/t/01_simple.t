use strict;
use warnings;
use Test::More tests => 34;

use HTTP::Request::StreamingUpload;

my $makefile = do {
    open my $fh, '<', 'Makefile.PL';
    local $/;
    <$fh>;
};

do {
    my $req = HTTP::Request::StreamingUpload->new;
    isa_ok $req, 'HTTP::Request';
};

do {
    my $req = HTTP::Request::StreamingUpload->new(
        PUT => 'http://localhost/',
    );
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'PUT', 'method';
    is $req->uri, 'http://localhost/', 'uri';
};

do {
    my $req = HTTP::Request::StreamingUpload->new(
        PUT => 'http://localhost/',
        path => 'Makefile.PL',
    );
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'PUT', 'method';
    is $req->uri, 'http://localhost/', 'uri';
    isa_ok $req->content, 'CODE';
    isa_ok $req->content_ref, 'REF';

    is(HTTP::Request::StreamingUpload->slurp($req), $makefile, 'slurp');
};

do {
    open my $fh, '<', 'Makefile.PL';

    my $req = HTTP::Request::StreamingUpload->new(
        PUT => 'http://localhost/',
        fh  => $fh,
    );
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'PUT', 'method';
    is $req->uri, 'http://localhost/', 'uri';
    isa_ok $req->content, 'CODE';
    isa_ok $req->content_ref, 'REF';

    is(HTTP::Request::StreamingUpload->slurp($req), $makefile, 'slurp');
};

do {
    my @chunk = qw( foo bar baz );
    push @chunk, '', 0, '', 'hoge', undef;
    my $req = HTTP::Request::StreamingUpload->new(
        PUT => 'http://localhost/',
        callback  => sub { shift @chunk },
    );
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'PUT', 'method';
    is $req->uri, 'http://localhost/', 'uri';
    isa_ok $req->content, 'CODE';
    isa_ok $req->content_ref, 'REF';

    is(HTTP::Request::StreamingUpload->slurp($req), 'foobarbaz0hoge', 'slurp');
};


do {
    my $req = HTTP::Request::StreamingUpload->new(
        PUT => 'http://localhost/',
        content => 'dummy',
    );
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'PUT', 'method';
    is $req->uri, 'http://localhost/', 'uri';
    is $req->content, 'dummy';
    isa_ok $req->content_ref, 'SCALAR';

    is(HTTP::Request::StreamingUpload->slurp($req), 'dummy', 'slurp');
};

do {
    open my $fh, '<', 'Makefile.PL';

    my $req = HTTP::Request::StreamingUpload->new(
        PUT => 'http://localhost/',
        fh  => $fh,
        chunk_size => 10,
    );
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'PUT', 'method';
    is $req->uri, 'http://localhost/', 'uri';
    isa_ok $req->content, 'CODE';
    isa_ok $req->content_ref, 'REF';

    is($req->content->(), 'use inc::M', 'fetch chunk');
};
