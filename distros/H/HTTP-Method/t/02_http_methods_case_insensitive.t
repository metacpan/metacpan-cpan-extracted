use Test::Most tests => 9;

use HTTP::Method ':case-insensitive';

subtest 'HTTP::Method->CONNECT' => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new('connect');
    
    ok (HTTP::Method->CONNECT->is_connect,
        "CONNECT->is_connect");
    
    ok $mth eq "CONNECT",
        "Method->new(...) eq 'CONNECT'";
    
    ok $mth->is_connect,
        "... is_connect";
    
    is $mth->is_method_safe,            undef,
        "... is_method_safe             NO";
    
    is $mth->is_method_idempotent,      undef,
        "... is_method_idempotent       NO";
    
    is $mth->is_method_cachable,        undef,
        "... is_cachable                NO";
};

subtest 'HTTP::Method->DELETE'  => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new('delete');
    
    ok (HTTP::Method->DELETE->is_delete,
        "GET->is_delete");
    
    ok $mth eq "DELETE",
        "Method->new(...) eq 'DELETE'";
    
    ok $mth->is_delete,
        "... is_delete";
    
    is $mth->is_method_safe,            undef,
        "... is_method_safe             NO";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        undef,
        "... is_cachable                NO";
};

subtest 'HTTP::Method->GET'     => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new('get');
    
    ok (HTTP::Method->GET->is_get,
        "GET->is_get");
    
    ok $mth eq "GET",
        "Method->new(...) eq 'GET'";
    
    ok $mth->is_get,
        "... is_get";
    
    is $mth->is_method_safe,            1,
        "... is_method_safe             YES";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        1,
        "... is_cachable                YES";
};

subtest 'HTTP::Method->HEAD'    => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new('head');
    
    ok (HTTP::Method->HEAD->is_head,
        "HEAD->is_head");
    
    ok $mth eq "HEAD",
        "Method->new(...) eq 'HEAD'";
    
    ok $mth->is_head,
        "... is_head";
    
    is $mth->is_method_safe,            1,
        "... is_method_safe             YES";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        1,
        "... is_cachable                YES";
};

subtest 'HTTP::Method->OPTIONS' => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new('options');
    
    ok (HTTP::Method->OPTIONS->is_options,
        "OPTIONS->is_options");
    
    ok $mth eq "OPTIONS",
        "Method->new(...) eq 'OPTIONS'";
    
    ok $mth->is_options,
        "... is_options";
    
    is $mth->is_method_safe,            1,
        "... is_method_safe             YES";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        undef,
        "... is_cachable                NO";
};

subtest 'HTTP::Method->PATCH'   => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new('patch');
    
    ok (HTTP::Method->PATCH->is_patch,
        "PATCH->is_patch");
    
    ok $mth eq "PATCH",
        "Method->new(...) eq 'PATCH'";
    
    ok $mth->is_patch,
        "... is_patch";
    
    is $mth->is_method_safe,            undef,
        "... is_method_safe             NO";
    
    is $mth->is_method_idempotent,      undef,
        "... is_method_idempotent       NO";
    
    is $mth->is_method_cachable,        1,
        "... is_cachable                YES";
};

subtest 'HTTP::Method->POST'    => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new('post');
    
    ok (HTTP::Method->POST->is_post,
        "POST->is_post");
    
    ok $mth eq "POST",
        "Method->new(...) eq 'POST'";
    
    ok $mth->is_post,
        "... is_post";
    
    is $mth->is_method_safe,            undef,
        "... is_method_safe             NO";
    
    is $mth->is_method_idempotent,      undef,
        "... is_method_idempotent       NO";
    
    is $mth->is_method_cachable,        1,
        "... is_cachable                YES";
};

subtest 'HTTP::Method->PUT'     => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new('put');
    
    ok (HTTP::Method->PUT->is_put,
        "PUT->is_put");
    
    ok $mth eq "PUT",
        "Method->new(...) eq 'PUT'";
    
    ok $mth->is_put,
        "... is_put";
    
    is $mth->is_method_safe,            undef,
        "... is_method_safe             NO";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        undef,
        "... is_cachable                NO";
};

subtest 'HTTP::Method->TRACE'   => sub {
    plan tests => 6;
    
    my $mth = HTTP::Method->new('trace');
    
    ok (HTTP::Method->TRACE->is_trace,
        "TRACE->is_trace");
    
    ok $mth eq "TRACE",
        "Method->new(...) eq 'TRACE'";
    
    ok $mth->is_trace,
        "... is_trace";
    
    is $mth->is_method_safe,            1,
        "... is_method_safe             YES";
    
    is $mth->is_method_idempotent,      1,
        "... is_method_idempotent       YES";
    
    is $mth->is_method_cachable,        undef,
        "... is_cachable                NO";
};
