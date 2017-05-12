#!perl -w

# Check FCGI::Buffer honours the Etag header when requested

use strict;
use warnings;
use Test::Most;
use Capture::Tiny ':all';
use DateTime;
# use Test::NoWarnings;	# HTML::Clean has them

BEGIN {
	use_ok('FCGI::Buffer');
}

ETAG: {
	delete $ENV{'REMOTE_ADDR'};
	delete $ENV{'HTTP_USER_AGENT'};
	delete $ENV{'NO_CACHE'};
	delete $ENV{'NO_STORE'};
	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';

	my $test_count = 21;

	SKIP: {
		eval {
			require CHI;

			CHI->import();
		};

		SKIP: {
			$test_count = 23;
			if($@) {
				diag ('CHI required to test');
				skip 'CHI required to test', 22;
			}

			sub test1 {
				my $b = new_ok('FCGI::Buffer');

				ok($b->can_cache() == 1);
				ok($b->is_cached() == 0);
				my $hash = {};
				my $c = CHI->new(driver => 'Memory', datastore => $hash);

				$b->init({ cache => $c, cache_key => 'foo' });

				print "Content-type: text/html; charset=ISO-8859-1\n\n";
				print "<HTML><BODY>   Hello World</BODY></HTML>\n";
				ok($b->is_cached() == 0);
			}

			my ($stdout, $stderr) = capture { test1() };

			ok($stderr eq '');

			my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

			ok($headers !~ /^Content-Encoding: gzip/m);
			ok($headers =~ /^ETag: "/m);

			ok($headers =~ /^ETag:\s+(.+)/m);
			my $etag = $1;
			ok(defined($etag));
			$etag =~ s/\r//;

			ok($headers =~ /^Content-Length:\s+(\d+)/m);
			my $length = $1;
			ok(defined($length));

			ok($body =~ /^<HTML><BODY>   Hello World<\/BODY><\/HTML>/m);
			ok(length($body) eq $length);

			$ENV{'HTTP_IF_NONE_MATCH'} = $etag;
			($stdout, $stderr) = capture { test1() };

			ok($stderr eq '');

			($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

			ok($body eq '');
			ok($headers =~ /^Status: 304 Not Modified/mi);
			ok($headers =~ /^ETag:\s+(.+)/m);
			ok($1 eq $etag);
		}
	}
	done_testing($test_count);
}
