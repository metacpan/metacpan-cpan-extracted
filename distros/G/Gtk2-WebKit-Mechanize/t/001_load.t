use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;

BEGIN { use_ok('Gtk2::WebKit::Mechanize'); }

my $mech = Gtk2::WebKit::Mechanize->new();
isa_ok($mech, 'Gtk2::WebKit::Mechanize');

$mech->get('http://www.google.com');
like($mech->title, qr/Google/);
