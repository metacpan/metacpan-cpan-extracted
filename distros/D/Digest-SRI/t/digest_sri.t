#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module Digest::SRI.

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

use FindBin ();
use lib $FindBin::Bin;
use Digest_SRI_Testlib;
use File::Spec::Functions qw/catfile/;

my $HAVE_MD5; BEGIN { $HAVE_MD5 = eval { require Digest::MD5; 1 } }
use constant TESTCOUNT => 31 + ($HAVE_MD5 ? 3 : 0);  ## no critic (ProhibitConstantPragma)
use Test::More tests=>TESTCOUNT;

## no critic (RequireCarping)

BEGIN {
	diag "This is Perl $] at $^X on $^O";
	use_ok('Digest::SRI','sri','verify_sri')
		or BAIL_OUT("failed to use Digest::SRI");
}
is $Digest::SRI::VERSION, '0.02', 'Digest::SRI version matches tests';

my $fn = catfile($FindBin::Bin,'testfile.txt');

my $sri = Digest::SRI->new("SHA-256");
$sri->add("Foo Bar");
# echo -n "Foo Bar" | openssl dgst -sha256 -binary | openssl base64 -A
is $sri->clone->b64digest, 'VSgsGCBrm+uZmPXqoVuFyTiEY5ZWeK9SCeLMOj/1uUc', 'sha256 b64digest';

# echo -n "Foo Bar" | openssl dgst -sha256 -binary | perl -l -0777 -e 'print unpack("H*",scalar <>)'
is $sri->clone->hexdigest, '55282c18206b9beb9998f5eaa15b85c9388463965678af5209e2cc3a3ff5b947', 'sha256 hexdigest';
is $sri->clone->digest, pack('H*','55282c18206b9beb9998f5eaa15b85c9388463965678af5209e2cc3a3ff5b947'), 'sha256 digest';

is $sri->sri, 'sha256-VSgsGCBrm+uZmPXqoVuFyTiEY5ZWeK9SCeLMOj/1uUc=', 'sha256 sri';
ok +Digest::SRI->new("sha256-VSgsGCBrm+uZmPXqoVuFyTiEY5ZWeK9SCeLMOj/1uUc=")
	->add("Foo Bar")->verify, 'sha256 verify ok';
ok !Digest::SRI->new("sha256-VSgsGCBrm+uZmPXqoVuFyTiEY5ZWeK9SCeLMOja1uUc=")
	->add("Foo Bar")->verify, 'sha256 verify nok';
is +Digest::SRI->new(" ShA--256 ")->add("Blah")->reset->add("Foo Bar")->sri,
	'sha256-VSgsGCBrm+uZmPXqoVuFyTiEY5ZWeK9SCeLMOj/1uUc=', 'sha256 reset ok';
ok +Digest::SRI->new("sha256-VSgsGCBrm+uZmPXqoVuFyTiEY5ZWeK9SCeLMOj/1uUc=")
	->add("Foo")->clone->add(" Ba")->add_bits("01110010")->verify, 'sha256 clone verify ok';

# openssl dgst -sha256 -binary t/testfile.txt | openssl base64 -A
open my $fh, '<', $fn or die "$fn: $!";
binmode $fh;
is sri("SHA-256", $fh), 'sha256-3/1gIbsr1bCvZ2KQgJ7DpTGR3YHH9wpLKGiKNiGCmG8=', 'sri(sha256, fh)';
close $fh;
is sri("SHA-256", $fn), 'sha256-3/1gIbsr1bCvZ2KQgJ7DpTGR3YHH9wpLKGiKNiGCmG8=', 'sri(sha256, fn)';
is sri("SHA-256", \"Hello, World!"), 'sha256-3/1gIbsr1bCvZ2KQgJ7DpTGR3YHH9wpLKGiKNiGCmG8=', 'sri(sha256, string)';

ok  verify_sri('sha256-3/1gIbsr1bCvZ2KQgJ7DpTGR3YHH9wpLKGiKNiGCmG8', $fn), 'sri_verify() ok';
ok !verify_sri('sha256-3/1gIbsr1bCvZ2KQgJ7DpTGR3YHH9wpLKGiKNiGCmG9', $fn), 'sri_verify() nok';

# echo -n "Blah" | openssl dgst -sha384 -binary | openssl base64 -A
is +Digest::SRI->new("SHA384")->add("Blah")->sri,
	'sha384-zP2sHO3j9I53y0i1OU+Czoz/Lc3z8domMeqO7DNirK6JxGMn15bJJxF+ZovsYBlA', 'sha384 sri';
ok +Digest::SRI->new('sha384-zP2sHO3j9I53y0i1OU+Czoz/Lc3z8domMeqO7DNirK6JxGMn15bJJxF+ZovsYBlA')
	->add("Blah")->verify, 'sha384 verify ok';
ok !Digest::SRI->new('sha384-zP2sHO3j9I53y0i1OU+Czoz/Lc3z8dmMeqO7DNirK6JxGMn15bJJxF+ZovsYBlA')
	->add("Blah")->verify, 'sha384 verify nok';

# openssl dgst -sha512 -binary t/testfile.txt | openssl base64 -A
open $fh, '<', $fn or die "$fn: $!";
binmode $fh;
is +Digest::SRI->new("sha512")->addfile($fh)->sri,
	'sha512-N015SpXNz9izWZMYX++bo2jxYNja9DLQi6nx7R5avmzGkpHg+i/gAGpSVw7xjBne9OYXwzzlLvCm5fvjGMsDhw==', 'sha512 sri';
close $fh;
ok +Digest::SRI->new('sha512-N015SpXNz9izWZMYX++bo2jxYNja9DLQi6nx7R5avmzGkpHg+i/gAGpSVw7xjBne9OYXwzzlLvCm5fvjGMsDhw==')
	->addfilename($fn)->verify, 'sha512 verify ok';

# echo -n "Perl" | openssl dgst -sha512 -binary | openssl base64 -A
is +Digest::SRI->new->add("Perl")->sri,
	'sha512-hHYEAHP6SF4pIKJCM7KOHY1YlZijmHXII/Z1bPhlC66rXY8FNa0+3AmYgfw+DQHaWWIKRuNEdx8jYLXFlMzc6A==', 'default algo sri';
is sri(\"Perl"), 'sha512-hHYEAHP6SF4pIKJCM7KOHY1YlZijmHXII/Z1bPhlC66rXY8FNa0+3AmYgfw+DQHaWWIKRuNEdx8jYLXFlMzc6A==', 'sri() default algo';

like exception { Digest::SRI::new(bless {}, "Foo") },
	qr/\bbad argument to new\b/, 'new bad arg 1';
like exception { Digest::SRI::new(\"Foo") },
	qr/\bbad argument to new\b/, 'new bad arg 2';
like exception { Digest::SRI->new("foo") },
	qr/\bunknown\/unsupported algorithm 'foo'/, 'new bad algo';
like exception { Digest::SRI->new->addfilename("this_file_shouldnt_exist") },
	qr/\bcouldn't open this_file_shouldnt_exist:/, 'addfilename fail';
like exception { sri(1,2,3) }, qr/\btoo many arguments to sri\b/, 'sri() bad arg count 1';
like exception { sri() }, qr/\bnot enough arguments to sri\b/, 'sri() bad arg count 2';
like exception { sri([]) }, qr/\bcan't handle reference to ARRAY\b/, 'sri() bad arg 1';
like exception { sri(bless {},"Foo") }, qr/\bcan't handle reference to Foo\b/, 'sri() bad arg 2';
like exception { verify_sri(1) }, qr/\bexpected two arguments to verify_sri\b/, 'verify_sri() bad args';

if ( $HAVE_MD5 ) {
	# echo -n "quz" | openssl dgst -md5 -binary | openssl base64 -A
	is +Digest::SRI->new("MD5")->add("quz")->sri, 'md5-Vo892IWSpo75lFmlSRARzQ==', 'md5 sri';
	ok +Digest::SRI->new('md5-Vo892IWSpo75lFmlSRARzQ')->add("quz")->verify, 'md5 verify ok';
	ok !Digest::SRI->new('md5-Vo892IWSpo75lFmlSRARzQa=')->add("quz")->verify, 'md5 verify nok';
}

if (my $cnt = grep {!$_} Test::More->builder->summary)
	{ BAIL_OUT("$cnt tests failed") }
done_testing(TESTCOUNT);
