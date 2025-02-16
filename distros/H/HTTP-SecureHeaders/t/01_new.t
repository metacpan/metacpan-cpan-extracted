use Test2::V0;

use HTTP::SecureHeaders;

subtest 'no args' => sub {
    my $secure_headers = HTTP::SecureHeaders->new;
    isa_ok $secure_headers, 'HTTP::SecureHeaders';
};

subtest 'unknown field' => sub {
    local $@;
    eval {
        HTTP::SecureHeaders->new(hoge => 1)
    };
    like $@, qr/unknown HTTP field. hoge/;
};

subtest 'cannot find `hoge` check function' => sub {
    {
        package MySecureHeaders;
        use parent qw(HTTP::SecureHeaders);

        %HTTP::SecureHeaders::HTTP_FIELD_MAP = (
            %HTTP::SecureHeaders::HTTP_FIELD_MAP,
            hoge => 'Hoge',
        )
    }

    local $@;
    eval {
        MySecureHeaders->new(hoge => 1)
    };
    like $@, qr/cannot find check function. check_hoge/;
};

subtest 'find `hoge` check function' => sub {
    {
        package MySecureHeadersWithChecker;
        use parent qw(HTTP::SecureHeaders);

        %HTTP::SecureHeaders::HTTP_FIELD_MAP = (
            %HTTP::SecureHeaders::HTTP_FIELD_MAP,
            hoge => 'Hoge',
        );

        sub check_hoge { !!1 }
    }

    my $secure_headers = MySecureHeadersWithChecker->new(hoge => 1);
    isa_ok $secure_headers, 'MySecureHeadersWithChecker';
    isa_ok $secure_headers, 'HTTP::SecureHeaders';
    is $secure_headers->{hoge}, 1;
};


subtest 'undef value is available for optout from headers' => sub {
    my $secure_headers = HTTP::SecureHeaders->new(x_xss_protection => undef);
    isa_ok $secure_headers, 'HTTP::SecureHeaders';
    is $secure_headers->{x_xss_protection}, undef;
};

subtest '`hoge` is invalid http header value' => sub {
    local $@;
    eval {
        HTTP::SecureHeaders->new(x_xss_protection => 'hoge');
    };
    like $@, qr/invalid HTTP header value. x_xss_protection:hoge/;
};

subtest 'valid HTTP header value' => sub {
    my $secure_headers = HTTP::SecureHeaders->new(x_xss_protection => '0');
    isa_ok $secure_headers, 'HTTP::SecureHeaders';
    is $secure_headers->{x_xss_protection}, '0';
};

done_testing;
