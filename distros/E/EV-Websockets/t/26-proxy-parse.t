use strict;
use warnings;
use Test::More;
use EV::Websockets;

# Unit tests for the proxy env-var parser. Pure Perl, no network/event loop.

my $parse = \&EV::Websockets::Context::_parse_proxy;

is_deeply([$parse->("http://proxy.example:8080/")], ["proxy.example", 8080],
    "scheme + host + port");
is_deeply([$parse->("https://proxy.example:3128")], ["proxy.example", 3128],
    "https scheme + host + port");
is_deeply([$parse->("socks5://10.0.0.1:1080")], ["10.0.0.1", 1080],
    "non-http scheme accepted");
is_deeply([$parse->("proxy.example:9999")], ["proxy.example", 9999],
    "bare host:port (no scheme)");
is_deeply([$parse->("proxy.example")], ["proxy.example", 1080],
    "host with no port defaults to 1080");
is_deeply([$parse->("user:pass\@proxy.example:8080")], ["proxy.example", 8080],
    "userinfo stripped, host:port kept");
is_deeply([$parse->("http://user:pass\@proxy.example")], ["proxy.example", 1080],
    "scheme + userinfo + host, default port");
is_deeply([$parse->("[2001:db8::1]:8080")], ["2001:db8::1", 8080],
    "IPv6 bracket notation with non-default port (brackets stripped, port kept)");
is_deeply([$parse->("http://[2001:db8::1]:3128")], ["2001:db8::1", 3128],
    "scheme + IPv6 bracket + non-default port (port not clobbered by strip)");
is_deeply([$parse->("[::1]")], ["::1", 1080],
    "IPv6 bracket notation, default port (brackets stripped)");
is_deeply([$parse->("10.20.30.40")], ["10.20.30.40", 1080],
    "bare IPv4, default port");

is_deeply([$parse->("")], [], "empty string -> no match");
is_deeply([$parse->(undef)], [], "undef -> no match");

done_testing;
