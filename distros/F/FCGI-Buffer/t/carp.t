#!perl -wT

# Check FCGI::Buffer traps if you give invalid values

use strict;
use warnings;
use Test::Most;

eval 'use Test::Carp';

if($@) {
	plan(skip_all => 'Test::Carp required for test');
} else {
	plan(tests => 7);
	use_ok('FCGI::Buffer');

	CARP: {
		# test save_to is not writable
		SKIP: {
			if($^O ne 'MSWin32') {
				sub test1 {
					my $b = new_ok('FCGI::Buffer');
					$b->init(save_to => { directory => '/' });

					ok($b->can_cache() == 1);

					print "Content-type: text/html; charset=ISO-8859-1\n\n",
						"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN>\n",
						"<HTML><HEAD><TITLE>test1</TITLE></HEAD>",
						"<BODY>",
						'<A HREF="/cgi-bin/test1.cgi?arg2=b">link</a>',
						"</BODY></HTML>\n";
				};

				does_carp_that_matches(\&test1, qr/isn't writeable/);
			} else {
				skip("It's tricky finding a directory that isn't writeable on Windows", 3);
			}
		}

		# test save_to is a directory
		sub test2 {
			my $b = new_ok('FCGI::Buffer');
			$b->init(save_to => { directory => 'Makefile.PL' });

			ok($b->can_cache() == 1);

			print "Content-type: text/html; charset=ISO-8859-1\n\n",
				"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN>\n",
				"<HTML><HEAD><TITLE>test2</TITLE></HEAD>",
				"<BODY>",
				'<A HREF="/cgi-bin/test2.cgi?arg2=b">link</a>',
				"</BODY></HTML>\n";
		}

		does_carp_that_matches(\&test2, qr/isn't a directory/);
	}
}
