use Test::Most tests => 6;

use HTTP::Caching;

$HTTP::Caching::DEBUG = 1; # so we get nice helpful messages back

use HTTP::Method;
use HTTP::Request;
use HTTP::Response;

use Readonly;

Readonly my $REUSE_NO_MATCH             => 0; # mismatch of headers etc
Readonly my $REUSE_IS_OK                => 1;
Readonly my $REUSE_IS_STALE             => 2;
Readonly my $REUSE_REVALIDATE           => 4;
Readonly my $REUSE_IS_STALE_OK          => $REUSE_IS_STALE | $REUSE_IS_OK;
Readonly my $REUSE_IS_STALE_REVALIDATE  => $REUSE_IS_STALE | $REUSE_REVALIDATE;

# minimal HTTP::Messages
# - Request: HEAD
#   Method is understood,
#   Method is safe
#   Method is cachable
# - Response: 100 Continue
#   Status Code is understood
#   Status Code is not be default cachable
#   Will fall through
my $rqst_minimal = HTTP::Request->new('HEAD', 'http://localhost/');
my $resp_minimal = HTTP::Response->new(100);

subtest "matching URI's" => sub {
    
    plan tests => 6;
    
    my $test;
    
    my $none_caching = HTTP::Caching->new(
        cache       => undef,
        cache_type  => undef,
        forwarder   => sub { },
    );
    
    
    my $rqst_identical  = $rqst_minimal->clone;
    my $resp_stored     = $resp_minimal->clone;
    my $rqst_associated = $rqst_minimal->clone;
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_identical,
            $resp_stored,
            $rqst_associated
        )
    }
        { carped => qr/NO REUSE: must successfully validated/ },
        "URI's are identical";
    ok ( ( defined $test and $test == $REUSE_IS_STALE_REVALIDATE ),
        "... and falls through" );
    
    my $rqst_normalized = $rqst_minimal->clone;
    $rqst_normalized->uri('http://LOCALHOST:80/');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_normalized,
            $resp_stored,
            $rqst_associated
        )
    }
        { carped => qr/NO REUSE: must successfully validated/ },
        "URI's do match";
    ok ( ( defined $test and $test == $REUSE_IS_STALE_REVALIDATE ),
        "... and falls through" );
    
    
    my $rqst_different = $rqst_minimal->clone;
    $rqst_different->uri('http://localhost:8080/');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_different,
            $resp_stored,
            $rqst_associated
        )
    }
        { carped => qr/NO REUSE: URI's do not match/ },
        "NO REUSE: URI's do not match";
    ok ( (defined $test and $test == $REUSE_NO_MATCH),
        "... and returns REUSE_NO_MATCH" );
    
};


subtest "matching Request Methods" => sub {
    
    plan tests => 6;
    
    my $test;
    
    my $none_caching = HTTP::Caching->new(
        cache       => undef,
        cache_type  => undef,
        forwarder   => sub { },
    );
    
    
    my $rqst_identical  = $rqst_minimal->clone;
    my $resp_stored     = $resp_minimal->clone;
    my $rqst_associated = $rqst_minimal->clone;
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_identical,
            $resp_stored,
            $rqst_associated
        )
    }
        { carped => qr/NO REUSE: must successfully validated/ },
        "Methods are identical";
    ok ( ( defined $test and $test == $REUSE_IS_STALE_REVALIDATE ),
        "... and falls through" );
    
    my $rqst_normalized = $rqst_minimal->clone;
    $rqst_normalized->method('head');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_normalized,
            $resp_stored,
            $rqst_associated
        )
    }
        { carped => qr/NO REUSE: Methods do not match/ },
        "NO REUSE: Methods are case-sensitive";
    ok ( (defined $test and $test == $REUSE_NO_MATCH),
        "... and returns REUSE_NO_MATCH" );
    
    
    my $rqst_different = $rqst_minimal->clone;
    $rqst_different->method('OPTIONS');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_different,
            $resp_stored,
            $rqst_associated
        )
    }
        { carped => qr/NO REUSE: Methods do not match/ },
        "NO REUSE: Methods do not match";
    ok ( (defined $test and $test == $REUSE_NO_MATCH),
        "... and returns REUSE_NO_MATCH" );
    
};


subtest "matching Nominated Headers in 'Vary'" => sub {
    
    plan tests => 12;
    
    my $test;
    
    my $none_caching = HTTP::Caching->new(
        cache       => undef,
        cache_type  => undef,
        forwarder   => sub { },
    );
    
        warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_minimal,
            $resp_minimal,
            $rqst_minimal
        )
    }
        { carped => qr/NO REUSE: must successfully validated/ },
        "No 'Vary'";
    ok ( ( defined $test and $test == $REUSE_IS_STALE_REVALIDATE ),
        "... and falls through" );
    
    my $resp_vary = $resp_minimal->clone;
    $resp_vary->header('Vary' => 'FOO');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_minimal,
            $resp_vary,
            $rqst_minimal,
        )
    }
        { carped => qr/NO REUSE: must successfully validated/ },
        "'Nominated Headers are not present in either request";
    ok ( ( defined $test and $test == $REUSE_IS_STALE_REVALIDATE ),
        "... and falls through" );
    
    
    my $rqst_foo_bar = $rqst_minimal->clone;
    $rqst_foo_bar->header('FOO' => 'bar');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_minimal,
            $resp_vary,
            $rqst_foo_bar
        )
    }
        { carped => qr/NO REUSE: Nominated headers in 'Vary' do not match/ },
        "NO REUSE: Nominated Headers are not both in each request";
    ok ( (defined $test and $test == $REUSE_NO_MATCH),
        "... and returns REUSE_NO_MATCH" );
    
    
    my $rqst_foo_baz = $rqst_minimal->clone;
    $rqst_foo_baz->header('FOO' => 'baz');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_foo_baz,
            $resp_vary,
            $rqst_foo_bar
        )
    }
        { carped => qr/NO REUSE: Nominated headers in 'Vary' do not match/ },
        "NO REUSE: Nominated Headers do not have the same value";
    ok ( (defined $test and $test == $REUSE_NO_MATCH),
        "... and returns REUSE_NO_MATCH" );
   
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_foo_bar,
            $resp_vary,
            $rqst_foo_bar
        )
    }
        { carped => qr/NO REUSE: must successfully validated/ },
        "Nominated Headers are the same";
    ok ( ( defined $test and $test == $REUSE_IS_STALE_REVALIDATE ),
        "... and falls through" );
    
    my $resp_star = $resp_minimal->clone;
    $resp_star->header('Vary' => '*');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_foo_bar,
            $resp_star,
            $rqst_foo_bar
        )
    }
        { carped => qr/NO REUSE: 'Vary' equals '*'/ },
        "NO REUSE: 'Vary' equals '*'";
    ok ( (defined $test and $test == $REUSE_NO_MATCH),
        "... and returns REUSE_NO_MATCH" );
    
};


subtest "matching no-cache request" => sub {
    
    plan tests => 4;
    
    my $test;
    
    my $none_caching = HTTP::Caching->new(
        cache       => undef,
        cache_type  => undef,
        forwarder   => sub { },
    );
    
    
    my $rqst_cache_control = $rqst_minimal->clone;
    $rqst_cache_control->header('cache-control' => 'no-cache');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_cache_control,
            $resp_minimal,
            $rqst_minimal
        )
    }
        { carped => qr/NO REUSE: 'no-cache' appears in request/ },
        "NO REUSE: 'no-cache' appears in request cache directives";
    ok ( (defined $test and $test == $REUSE_REVALIDATE),
        "... and returns REUSE_REVALIDATE" );
    
    my $rqst_pragma = $rqst_minimal->clone;
    $rqst_pragma->header('Pragma' => 'no-cache');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_pragma,
            $resp_minimal,
            $rqst_minimal
        )
    }
        { carped => qr/NO REUSE: Pragma: 'no-cache' appears in request/ },
        "NO REUSE: Pragma: 'no-cache' appears in request";
    ok ( (defined $test and $test == $REUSE_REVALIDATE),
        "... and returns REUSE_REVALIDATE" );
    
};


subtest "matching no-cache response" => sub {
    
    plan tests => 2;
    
    my $test;
    
    my $none_caching = HTTP::Caching->new(
        cache       => undef,
        cache_type  => undef,
        forwarder   => sub { },
    );
    
    
    my $resp_cache_control = $resp_minimal->clone;
    $resp_cache_control->header('cache-control' => 'no-cache');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_minimal,
            $resp_cache_control,
            $rqst_minimal
        )
    }
        { carped => qr/NO REUSE: 'no-cache' appears in response/ },
        "NO REUSE: 'no-cache' appears in response cache directives";
    ok ( (defined $test and $test == $REUSE_REVALIDATE),
        "... and returns REUSE_REVALIDATE" );
    
};


subtest "is fresh" => sub {
    
    plan tests => 6;
    
    my $test;
    
    my $none_caching = HTTP::Caching->new(
        cache       => undef,
        cache_type  => undef,
        forwarder   => sub { },
    );
    
    
    my $resp_max_age = $resp_minimal->clone;
    $resp_max_age->header('Cache-Control' => 'max-age= 1');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_minimal,
            $resp_max_age,
            $rqst_minimal
        )
    }
        { carped => qr/DO REUSE: Response is fresh/ },
        "DO REUSE: Response is fresh: max-age=1";
    ok ( (defined $test and $test == $REUSE_IS_OK),
        "... and returns REUSE_IS_OK" );
    
    
    my $resp_expires = $resp_minimal->clone;
    $resp_expires->header('Expires' => 'Thu, 31 Dec 2099 23:59:59');
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_minimal,
            $resp_expires,
            $rqst_minimal
        )
    }
        { carped => qr/DO REUSE: Response is fresh/ },
        "DO REUSE: Response is fresh: Expires end of the century";
    ok ( (defined $test and $test == $REUSE_IS_OK),
        "... and returns REUSE_IS_OK" );
    
    
    my $resp_not_fresh = $resp_minimal->clone;
    $resp_not_fresh->header('Expires' => 'Thu, 01 Jan 1970 01:01:00');
    #
    # XXX don't ask, but 00:00:00, begining of epoch, does not work
    
    warning_like {
        $test = $none_caching->_may_reuse_from_cache(
            $rqst_minimal,
            $resp_not_fresh,
            $rqst_minimal
        )
    }
        { carped => qr/NO REUSE: must successfully validated/ },
        "NO REUSE: Response is fresh: Expires loooooong ago";
    ok ( ( defined $test and $test == $REUSE_IS_STALE_REVALIDATE ),
        "... and falls through" );
    
};






