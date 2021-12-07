use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('IURL::XS'); };

can_ok('IURL::XS', 'parse_url', 'split_url_path', 'parse_url_query');

subtest 'parse_url with minimal url' => sub {
    my $r = IURL::XS::parse_url('http://example.com');
    ok $r, 'minimal HTTP URL parsed ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/port query path fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
};

subtest 'parse_url with path (/)' => sub {
    my $r = IURL::XS::parse_url('http://example.com/');
    ok $r, 'parse_url with path (/) ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/port query path fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
};

subtest 'parse_url with path' => sub {
    my $r = IURL::XS::parse_url('http://example.com/path');
    ok $r, 'parse_url with path only ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/port query fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    is $r->{path}, 'path', 'url path is expected';
};

subtest 'parse_url with port' => sub {
    my $r = IURL::XS::parse_url('http://example.com:80');
    ok $r, 'parse_url with port only ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/path query fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    cmp_ok $r->{port}, '==', 80, 'http port is expected';
};

subtest 'parse_url with query' => sub {
    my $r = IURL::XS::parse_url('http://example.com?query=only');
    ok $r, 'parse_url with query only ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/port path fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    is $r->{query}, 'query=only', 'url query is expected';
};

subtest 'parse_url with fragment' => sub {
    my $r = IURL::XS::parse_url('http://example.com#frag=f1');
    ok $r, 'parse_url with fragment only ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/port path query/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    is $r->{fragment}, 'frag=f1', 'url fragment is expected';
};

subtest 'parse_url with credentials' => sub {
    my $r = IURL::XS::parse_url('http://u:p@example.com');
    ok $r, 'parse_url with credentials ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    # ok !$r->{$_}, "no $_" for qw/port path query/;
    # is $r->{scheme}, 'http', 'url scheme is http';
    # is $r->{host}, 'example.com', 'url host is example.com';
    # is $r->{fragment}, 'frag=f1', 'url fragment is expected';
};

subtest 'parse_url with port and path' => sub {
    my $r = IURL::XS::parse_url('http://example.com:8080/port/and/path');
    ok $r, 'parse_url with with port and path ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/query fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    cmp_ok $r->{port}, '==', 8080, 'port is expected';
    is $r->{path}, 'port/and/path', 'url path is expected';
};

subtest 'parse_url with port and query' => sub {
    my $r = IURL::XS::parse_url('http://example.com:8080?query=portANDquery');
    ok $r, 'parse_url with port and query ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/path fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    cmp_ok $r->{port}, '==', 8080, 'port is expected';
    is $r->{query}, 'query=portANDquery', 'url query is expected';
};

subtest 'parse_url with port and fragment' => sub {
    my $r = IURL::XS::parse_url('http://example.com:8080#f1');
    ok $r, 'parse_url with port and fragment ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/path query/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    cmp_ok $r->{port}, '==', 8080, 'port is expected';
    is $r->{fragment}, 'f1', 'url fragment is expected';
};

subtest 'parse_url with port and credentials' => sub {
    my $r = IURL::XS::parse_url('http://u:p@example.com:8080');
    ok $r, 'parse_url with port and credentials ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/path query fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    cmp_ok $r->{port}, '==', 8080, 'port is expected';
};

subtest 'parse_url with path and query' => sub {
    my $r = IURL::XS::parse_url('http://example.com/path/and/query?q=yes');
    ok $r, 'parse_url path and query ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    is $r->{path}, 'path/and/query', 'url path is expected';
    is $r->{query}, 'q=yes', 'url query is expected';
};

subtest 'parse_url with path and fragment' => sub {
    my $r = IURL::XS::parse_url('http://example.com/path/and#fragment');
    ok $r, 'parse_url with path and fragment ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/query/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    is $r->{path}, 'path/and', 'url path is expected';
    is $r->{fragment}, 'fragment', 'url fragment is expected';
};

subtest 'parse_url with query and fragment' => sub {
    my $r = IURL::XS::parse_url('http://example.com?q=yes#f1');
    ok $r, 'parse_url with query and fragment ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/path/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    is $r->{query}, 'q=yes', 'url query is expected';
    is $r->{fragment}, 'f1', 'url fragment is expected';
};

subtest 'parse_url with query and credentials' => sub {
    my $r = IURL::XS::parse_url('http://u:p@example.com?q=yes');
    ok $r, 'parse_url with query and credentials ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/path fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    is $r->{query}, 'q=yes', 'url query is expected';
};

subtest 'parse_url with empty credentials' => sub {
    my $r = IURL::XS::parse_url('http://:@example.com');
    ok $r, 'parse_url with empty credentials ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/path query fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
};

subtest 'parse_url with empty credentials and port' => sub {
    my $r = IURL::XS::parse_url('http://:@example.com:89');
    ok $r, 'parse_url with empty credentials and port ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok !$r->{$_}, "no $_" for qw/path query fragment/;
    is $r->{scheme}, 'http', 'url scheme is http';
    is $r->{host}, 'example.com', 'url host is example.com';
    cmp_ok $r->{port}, '==', 89, 'port is expected';
};

subtest 'parse_url with full url' => sub {
    my $r = IURL::XS::parse_url('https://jack:password@localhost:8989/path/to/test?query=yes&q=jack#fragment1');
    ok $r, 'parse_url with full url ok';
    my $expected_url_fields = [sort qw/scheme host port path query fragment/];
    is_deeply [sort keys %$r], $expected_url_fields, 'parsed url fields expected';
    ok $r->{$_}, "no $_" for qw/path query fragment/;
    is $r->{scheme}, 'https', 'url scheme is http';
    is $r->{host}, 'localhost', 'url host is example.com';
    cmp_ok $r->{port}, '==', 8989, 'port is expected';
    is $r->{path}, 'path/to/test', 'url path is expected';
    is $r->{query}, 'query=yes&q=jack', 'url query is expected';
    is $r->{fragment}, 'fragment1', 'url fragment is expected';
};

done_testing;
