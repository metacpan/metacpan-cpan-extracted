#!perl -w

# Tests for the regular expressions used by optimise_content: they mustn't
# change the meaning of the page, and must run in linear time on hostile input

use strict;
use warnings;
use Test::Most tests => 10;
use Capture::Tiny ':all';
use Test::NoWarnings;

BEGIN {
	use_ok('FCGI::Buffer');
}

delete @ENV{qw(
	HTTP_ACCEPT_ENCODING HTTP_TE SERVER_PROTOCOL HTTP_RANGE HTTP_USER_AGENT
	REMOTE_ADDR HTTP_IF_NONE_MATCH HTTP_IF_MODIFIED_SINCE HTTP_COOKIE
	REQUEST_URI QUERY_STRING
)};
$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'SCRIPT_NAME'} = '/cgi-bin/page.fcgi';

# Send some HTML through FCGI::Buffer, returning the body and stderr
sub optimise {
	my ($html, $level) = @_;

	my ($stdout, $stderr) = capture {
		my $b = FCGI::Buffer->new();
		$b->init({ optimise_content => $level || 1, generate_etag => 0 });
		print "Content-type: text/html\n\n", $html;
	};
	my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	return ($body, $stderr);
}

# Run some code, failing rather than hanging if it takes too long
sub within {
	my ($seconds, $code) = @_;

	my $rc = eval {
		local $SIG{ALRM} = sub { die "timeout\n" };
		alarm($seconds);
		$code->();
		alarm(0);
		1;
	};
	alarm(0);
	return $rc;
}

subtest 'script tags' => sub {
	my ($body, $stderr) = optimise('<html><body><script src="a.js"></script><!-- note --></body></html>', 2);
	is($stderr, '', 'no errors');
	unlike($body, qr/note/, 'the text of an HTML comment after an external script is not shown');
};

subtest 'document.write is only merged within one script' => sub {
	my $html = '<html><body>' .
		'<script type="text/javascript">document.write(x)</script><p>hi</p>' .
		'<script type="text/javascript">foo();document.write(y)</script>' .
		'</body></html>';
	my ($body, $stderr) = optimise($html, 2);
	is($stderr, '', 'no errors');
	unlike($body, qr/foo\(\+y\)/, 'calls in different scripts are not merged');
	like($body, qr/foo\(\);\s*document\.write\(y\)/, 'the second script is intact');
	like($body, qr/<script type="text\/javascript">/, 'the type attribute is not changed');

	($body) = optimise('<html><body><script type="text/javascript">var a=1;document.write("a"); document.write(f(2))</script></body></html>', 2);
	like($body, qr/document\.write\("a"\+f\(2\)\)/, 'calls in the same script are merged');
};

subtest 'whitespace around newlines' => sub {
	my ($body) = optimise("<html><body><script>x = 1\n+ 2;</script>\n   \n  <p>a</p>  \r\n</body></html>");
	like($body, qr/x = 1\n\+ 2;/, 'a + at the start of a line is kept');
	unlike($body, qr/[ \t\r]\n|\n[ \t]/, 'whitespace around newlines is removed');
};

subtest 'spaces between inline tags are kept' => sub {
	my ($body) = optimise('<html><body><p>Hello <b>world</b> <i>!</i></p></body></html>');
	like($body, qr/Hello <b>/, 'the space before a tag is not removed');
};

subtest 'links' => sub {
	my ($body) = optimise("<html><body><p>a\n   <a href=\"x\">x</a>\n</p></body></html>");
	like($body, qr/a <a href="x">x<\/a>/, 'whitespace before a link is collapsed');

	($body) = optimise('<html><body><p>a <a href="x" class="c">x</a> b <a href="y">y</a></p></body></html>');
	like($body, qr/<a href="x" class="c">x<\/a>/, 'link with other attributes is intact');
	like($body, qr/<a href="y">y<\/a>/, 'and so is the next one');
};

subtest 'hostile input runs in linear time' => sub {
	my $n = 50_000;

	# Smokers can be very slow and very busy
	my $limit = $ENV{'AUTOMATED_TESTING'} ? 60 : 10;

	foreach my $test(
		[ 'unterminated links', '<html><body>' . (' <a href="x' x $n) . '</body></html>' ],
		[ 'long run of spaces', '<html><head></head>' . (' ' x ($n * 4)) . "x</head> <body>\n</body></html>" ],
		[ 'long run of spaces without a newline', '<html><body>' . (' ' x ($n * 4)) . "x\n</body></html>" ],
		[ 'long run of spaces before tags', '<html><body>' . (' ' x ($n * 4)) . "x<div><p></p><hr></div></body></html>" ],
		[ 'unterminated titles', '<html><head>' . ('<title>a' x $n) . '</head></html>' ],
	) {
		my ($name, $html) = @{$test};
		my $b = FCGI::Buffer->new();
		my $ok = within($limit, sub {
			$b->{body} = $html;
			$b->_optimise_content();
		});
		ok($ok, $name);
		capture { undef $b };
	}

	foreach my $test(
		[ 'unterminated <pre>', '<html><body>' . ('<pre>' x $n) . '</body></html>' ],
		[ 'unterminated <pre> and <textarea>', '<html><body>' . ('<pre><textarea>' x $n) . '</body></html>' ],
		[ 'terminated <pre>', '<html><body>' . ('<pre> </pre>' x $n) . '</body></html>' ],
	) {
		my ($name, $html) = @{$test};
		my $b = FCGI::Buffer->new();
		my $ok = within($limit, sub {
			$b->{body} = $html;
			$b->_restore_preformatted($b->_protect_preformatted());
		});
		ok($ok, $name);
		is($b->{body}, $html, "$name: is put back as it was");
		capture { undef $b };
	}
};

subtest 'Range' => sub {
	my $html = '<html><body>' . join('', 'a'..'z') . "</body></html>\n";

	foreach my $test(
		[ 'bytes=0-9', substr($html, 0, 10), 'a range starting at 0 includes both ends' ],
		[ 'bytes=12-14', 'abc', 'a range includes its last byte' ],
		[ 'bytes=12-', substr($html, 12), 'an open ended range' ],
	) {
		my ($range, $expect, $name) = @{$test};
		local $ENV{'HTTP_RANGE'} = $range;
		my ($stdout) = capture {
			my $b = FCGI::Buffer->new();
			$b->init({ optimise_content => 0, generate_etag => 0 });
			print "Content-type: text/plain\n\n", $html;
		};
		my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
		is($body, $expect, $name);
		like($headers, qr/^Status: 206/m, "$range: 206 status");
	}

	foreach my $range('bytes=0-5,10-20', 'bytes=9-3') {
		local $ENV{'HTTP_RANGE'} = $range;
		my ($stdout) = capture {
			my $b = FCGI::Buffer->new();
			$b->init({ optimise_content => 0, generate_etag => 0 });
			print "Content-type: text/plain\n\n", $html;
		};
		my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
		is($body, $html, "$range: unsupported range sends the whole page");
	}
};

subtest 'Accept-Encoding with spaces before commas' => sub {
	local $ENV{'HTTP_ACCEPT_ENCODING'} = 'identity , gzip';
	my ($stdout) = capture {
		my $b = FCGI::Buffer->new();
		$b->init({ optimise_content => 0, generate_etag => 0 });
		print "Content-type: text/html\n\n", '<html><body>' . ('x' x 100) . "</body></html>\n";
	};
	like($stdout, qr/^Content-Encoding: gzip/m, 'gzip is found');
};
