use Test::Most tests => 9;

use HTTP::Method;

subtest 'HTTP::Method->CONNECT' => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new(uc 'connect');
    
    ok (HTTP::Method->CONNECT->is_CONNECT,
        "CONNECT->is_CONNECT");
    
    ok $mth eq "CONNECT",
        "Method->new(...) eq 'CONNECT'";
    
    ok $mth->is_CONNECT,
        "... is_CONNECT";
    
    is $mth->is_method_safe,            undef,
        "... is_method_safe             NO";
    
    is $mth->is_method_idempotent,      undef,
        "... is_method_idempotent       NO";
    
    is $mth->is_method_cachable,        undef,
        "... is_cachable                NO";
};

subtest 'HTTP::Method->DELETE'  => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new(uc 'delete');
    
    ok (HTTP::Method->DELETE->is_DELETE,
        "GET->is_DELETE");
    
    ok $mth eq "DELETE",
        "Method->new(...) eq 'DELETE'";
    
    ok $mth->is_DELETE,
        "... is_DELETE";
    
    is $mth->is_method_safe,            undef,
        "... is_method_safe             NO";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        undef,
        "... is_cachable                NO";
};

subtest 'HTTP::Method->GET'     => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new(uc 'get');
    
    ok (HTTP::Method->GET->is_GET,
        "GET->is_GET");
    
    ok $mth eq "GET",
        "Method->new(...) eq 'GET'";
    
    ok $mth->is_GET,
        "... is_GET";
    
    is $mth->is_method_safe,            1,
        "... is_method_safe             YES";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        1,
        "... is_cachable                YES";
};

subtest 'HTTP::Method->HEAD'    => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new(uc 'head');
    
    ok (HTTP::Method->HEAD->is_HEAD,
        "HEAD->is_HEAD");
    
    ok $mth eq "HEAD",
        "Method->new(...) eq 'HEAD'";
    
    ok $mth->is_HEAD,
        "... is_HEAD";
    
    is $mth->is_method_safe,            1,
        "... is_method_safe             YES";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        1,
        "... is_cachable                YES";
};

subtest 'HTTP::Method->OPTIONS' => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new(uc 'options');
    
    ok (HTTP::Method->OPTIONS->is_OPTIONS,
        "OPTIONS->is_OPTIONS");
    
    ok $mth eq "OPTIONS",
        "Method->new(...) eq 'OPTIONS'";
    
    ok $mth->is_OPTIONS,
        "... is_OPTIONS";
    
    is $mth->is_method_safe,            1,
        "... is_method_safe             YES";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        undef,
        "... is_cachable                NO";
};

subtest 'HTTP::Method->PATCH'   => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new(uc 'patch');
    
    ok (HTTP::Method->PATCH->is_PATCH,
        "PATCH->is_PATCH");
    
    ok $mth eq "PATCH",
        "Method->new(...) eq 'PATCH'";
    
    ok $mth->is_PATCH,
        "... is_PATCH";
    
    is $mth->is_method_safe,            undef,
        "... is_method_safe             NO";
    
    is $mth->is_method_idempotent,      undef,
        "... is_method_idempotent       NO";
    
    is $mth->is_method_cachable,        1,
        "... is_cachable                YES";
};

subtest 'HTTP::Method->POST'    => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new(uc 'post');
    
    ok (HTTP::Method->POST->is_POST,
        "POST->is_POST");
    
    ok $mth eq "POST",
        "Method->new(...) eq 'POST'";
    
    ok $mth->is_POST,
        "... is_POST";
    
    is $mth->is_method_safe,            undef,
        "... is_method_safe             NO";
    
    is $mth->is_method_idempotent,      undef,
        "... is_method_idempotent       NO";
    
    is $mth->is_method_cachable,        1,
        "... is_cachable                YES";
};

subtest 'HTTP::Method->PUT'     => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new(uc 'put');
    
    ok (HTTP::Method->PUT->is_PUT,
        "PUT->is_PUT");
    
    ok $mth eq "PUT",
        "Method->new(...) eq 'PUT'";
    
    ok $mth->is_PUT,
        "... is_PUT";
    
    is $mth->is_method_safe,            undef,
        "... is_method_safe             NO";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        undef,
        "... is_cachable                NO";
};

subtest 'HTTP::Method->TRACE'   => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new(uc 'trace');
    
    ok (HTTP::Method->TRACE->is_TRACE,
        "TRACE->is_TRACE");
    
    ok $mth eq "TRACE",
        "Method->new(...) eq 'TRACE'";
    
    ok $mth->is_TRACE,
        "... is_TRACE";
    
    is $mth->is_method_safe,            1,
        "... is_method_safe             YES";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        undef,
        "... is_cachable                NO";
};
