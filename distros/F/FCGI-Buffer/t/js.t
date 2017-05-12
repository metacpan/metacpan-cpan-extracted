#!perl -w

# Test if FCGI::Buffer adds Content-Length and Etag headers, also simple
# check that optimise_content and gzips does something.

# TODO: check optimise_content and gzips do the *right* thing
# TODO: check ETags are correct

use strict;
use warnings;

use Test::Most tests => 14;
use Capture::Tiny ':all';
# use Test::NoWarnings;	# HTML::Clean has them

BEGIN {
	use_ok('FCGI::Buffer');
}

OUTPUT: {
	sub writer {
		my $b = new_ok('FCGI::Buffer');

		ok($b->can_cache() == 1);
		ok($b->is_cached() == 0);

		$b->init({optimise_content => 2});

		print "Content-type: text/html; charset=ISO=8859-1\n\n";

		print "<HTML><BODY>\n";
		print "document.write(\"1\");\n";
		print "document.write(\"2\");\n";
		print "<script type=\"text/javascript\">\n";
		print "var i = 1;\n";
		print "document.write(\"foo\");\n";
		print "document.write(\"bar\");\n";
		print "var j = 1;\n";
		print "document.write(\"a\");\n";
		print "document.write(\"b\");\n";
		print "</script>\n";
		print "Hello World!\n";
		print "<script type=\"text/javascript\">\n";
		print "document.write(\"a\");\n";
		print "document.write(\"b\");\n";
		print "</script>\n";
		print "<script type=\"text/javascript\">\n";
		print "document.write(\"fred\");\n";
		print "var k = 1;\n";
		print "document.write(\"wilma\");\n";
		print "</script>\n";
		print "</body>\n";
		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY>   Hello World</BODY></HTML>\n";

		ok($b->is_cached() == 0);
	}

	delete $ENV{'HTTP_ACCEPT_ENCODING'};
	delete $ENV{'SERVER_PROTOCOL'};

	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';
	$ENV{'QUERY_STRING'} = 'FCGI::Buffer=testing';

	my ($stdout, $stderr) = capture { writer() };

	ok($stderr eq '');
	if($stderr ne '') {
		diag($stderr);
	}
	ok($stdout =~ /^Content-Length:\s+(\d+)+/m);
	my $length = $1;

	my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok(defined($headers));
	ok(defined($body));
	ok(length($body) eq $length);

	ok($stdout =~ /document\.write\("a"\+"b"\);/m);
	ok($stdout =~ /document\.write\("foo"\+"bar"\);/m);
	ok($stdout !~ /document\.write\("1"\+"2"\);/m);
	ok($stdout !~ /document\.write\("fred"\+"wilma"\);/m);
}
