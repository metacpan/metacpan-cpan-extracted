=head1 url.t

test our url verification functions

=cut

$::verbose=0;

BEGIN {print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;}

sub nogo {print "not "; }
sub ok {my $t=shift; print "ok $t\n";}

use WWW::Link_Controller::URL;

$WWW::Link_Controller::URL::no_warn=1;;

$loaded = 1;
ok(1);
nogo if WWW::Link_Controller::URL::verify_url
	('+++:bad_url');
ok(2);
nogo if WWW::Link_Controller::URL::verify_url
	('+ftp:bad_again');
ok(3);
nogo if WWW::Link_Controller::URL::verify_url
	('http://www.complete.garbage/this
is_not_valid_at_all');
ok(4);
nogo if WWW::Link_Controller::URL::verify_url
	('http://www.complete.garbage/this is_also_not_valid');
ok(5);
nogo if WWW::Link_Controller::URL::verify_url
	('unknown:illegal_char_>_in_url');
ok(6);
nogo if WWW::Link_Controller::URL::verify_url
	('fla~s:illegal_char_in_scheme');
ok(7);
nogo unless WWW::Link_Controller::URL::verify_url
	('ftp://scotclimb.org.uk/hi');
ok(8);
nogo unless WWW::Link_Controller::URL::verify_url
	('http://scotclimb.org.uk/ho.html');
ok(9);

#examples straight from RFC 2396
nogo unless WWW::Link_Controller::URL::verify_url
  ('ftp://ftp.is.co.za/rfc/rfc1808.txt');
ok(10);
nogo unless WWW::Link_Controller::URL::verify_url
  ('gopher://spinaltap.micro.umn.edu/00/Weather/California/Los%20Angeles');
nogo unless WWW::Link_Controller::URL::verify_url
  ('http://www.math.uio.no/faq/compression-faq/part1.html');
ok(11);
nogo unless WWW::Link_Controller::URL::verify_url
  ('mailto:mduerst@ifi.unizh.ch');
ok(12);
nogo unless WWW::Link_Controller::URL::verify_url
  ('news:comp.infosystems.www.servers.unix');
ok(13);
nogo unless WWW::Link_Controller::URL::verify_url
  ('telnet://melvyl.ucop.edu/');
ok(14);

nogo unless WWW::Link_Controller::URL::fixup_link_url
  ('http://scotclimb.org.uk', 'http://example.com')
  eq 'http://scotclimb.org.uk';
ok(15);
nogo unless WWW::Link_Controller::URL::fixup_link_url
  ('fred.html', 'http://example.com')
  eq 'http://example.com/fred.html';
ok(16);


nogo unless WWW::Link_Controller::URL::untaint_url
  ('http://example.com') eq 'http://example.com';
ok(17);
nogo if WWW::Link_Controller::URL::untaint_url
  ('bad
url');
ok(18);
