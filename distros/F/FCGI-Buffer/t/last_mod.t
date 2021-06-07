#!perl -w

# Check FCGI::Buffer correctly sets the Last-Modified header when requested

# Running like this will test this script works without some modules installed
#	perl -MTest::Without::Module=CHI -w -Iblib/lib t/last_mod.t
#	perl -MTest::Without::Module=DateTime::Format::HTTP -w -Iblib/lib t/last_mod.t

use strict;
use warnings;
use Test::Most;
use Capture::Tiny ':all';
use DateTime;
use HTTP::Date;
# use Test::NoWarnings;	# HTML::Clean has them
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('FCGI::Buffer');
}

my $hash = {};
my $test_run = 0;

sub writer {
	my $b = new_ok('FCGI::Buffer');

	ok($b->can_cache() == 1);
	ok($b->is_cached() == 0);

	my $c = CHI->new(driver => 'Memory', datastore => $hash);

	$b->init({cache => $c, cache_key => 'foo', logger => MyLogger->new()});
	ok($b->is_cached() == ($test_run >= 1));
	$test_run++;

	unless($b->is_cached()) {
		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY>   Hello World</BODY></HTML>\n";
	}

}

LAST_MODIFIED: {
	delete $ENV{'REMOTE_ADDR'};
	delete $ENV{'HTTP_USER_AGENT'};
	delete $ENV{'NO_CACHE'};
	delete $ENV{'NO_STORE'};
	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';

	my $test_count = 35;

	SKIP: {
		eval {
			require CHI;

			CHI->import();
		};

		SKIP: {
			$test_count = 38;
			if($@) {
				diag('CHI required to test');
				skip 'CHI required to test', 37;
			}

			my ($stdout, $stderr) = capture { writer() };

			ok($stderr eq '');
			ok($stdout !~ /^Content-Encoding: gzip/m);

			my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

			ok($headers =~ /^ETag: "/m);
			ok($headers =~ /^Last-Modified:\s+(.+)/m);
			my $date = $1;
			ok(defined($date));

			ok($headers =~ /^Content-Length:\s+(\d+)/m);
			my $length = $1;
			ok(defined($length));

			ok($body =~ /^<HTML><BODY>   Hello World<\/BODY><\/HTML>/m);

			ok(length($body) eq $length);

			eval {
				require DateTime::Format::HTTP;

				DateTime::Format::HTTP->import();
			};

			# This would be nice, but it doesn't work
			# if($@) {
				# skip 'DateTime::Format::HTTP required to test everything', 1;
			# } else {
				# my $dt = DateTime::Format::HTTP->parse_datetime($date);
				# ok($dt <= DateTime->now());
			# }

			SKIP: {
				skip 'DateTime::Format::HTTP required to test everything', 1 if $@;

				my $dt = DateTime::Format::HTTP->parse_datetime($date);
				ok($dt <= DateTime->now());
			}

			$ENV{'HTTP_IF_MODIFIED_SINCE'} = 'Mon, 13 Jul 2015 15:09:08 GMT';
			($stdout, $stderr) = capture { writer() };

			ok($stderr eq '');
			($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
			ok($headers !~ /^Status: 304 Not Modified/mi);
			ok($headers =~ /^Last-Modified:\s+(.+)/m);
			$date = $1;
			ok(defined($date));

			ok($body ne '');

			$ENV{'HTTP_IF_MODIFIED_SINCE'} = $date;
			($stdout, $stderr) = capture { writer() };

			ok($stderr eq '');
			($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
			if($headers !~ /^Status: 304 Not Modified/mi) {
				diag("Last-Modified was set to '$date'");
			}
			ok($headers =~ /^Status: 304 Not Modified/mi);
			ok($body eq '');

			$ENV{'TZ'} = 'Europe/Berlin';	# RT 110011
			($stdout, $stderr) = capture { writer() };

			ok($stderr eq '');
			($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
			if($headers !~ /^Status: 304 Not Modified/mi) {
				diag("Last-Modified was set to '$date'");
			}
			ok($headers =~ /^Status: 304 Not Modified/mi);
			ok($body eq '');
		}
	}
	done_testing($test_count);
}
