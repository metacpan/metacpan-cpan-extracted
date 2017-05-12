use strict;
use warnings;
use HTTP::StreamParser::Request;
use Test::More tests => 8;
use feature qw(say);

my $CRLF = "\x0d\x0a";
my $p = HTTP::StreamParser::Request->new;
my @req;
my $body = '';
my %hdr;
$hdr{'Host'} = 'localhost';
$hdr{'Content-Length'} = 15;
$hdr{'Accept-Encoding'} = '*';
$p->subscribe_to_event(
	http_method => sub {
		my $method = $_[1];
		is($method, 'GET', 'correct method');
		push @req, $method;
	},
	http_uri => sub {
		my $uri = $_[1];
		is($uri, '/', 'correct URI');
		push @req, $uri;
	},
	http_header => sub {
		my ($k, $v) = @_[1,2];
		ok(exists $hdr{$k}, 'have this header (' . $k . ')');
		is($v, $hdr{$k}, 'header matches');
		push @req, [ $k => $v ];
	},
	http_body_chunk => sub {
		my ($txt) = $_[1];
		$body .= $txt;
	},
);
$p->parse($_) for split /(.{8})/, join $CRLF, split /\n/, <<'EOF';
GET / HTTP/1.1
Host: localhost
Content-Length: 15
Accept-Encoding: *

This is text...
EOF
done_testing();
