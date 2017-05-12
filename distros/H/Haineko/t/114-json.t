use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::JSON;
use Test::More;

my $modulename = 'Haineko::JSON';
my $pkgmethods = [ 'loadfile', 'dumpfile', 'loadjson', 'dumpjson' ];
my $objmethods = [];

can_ok $modulename, @$pkgmethods;

my $f = './eg/email-01.json';
my $j = undef;
my $d = undef;

$d = $modulename->loadfile( $f );
isa_ok $d, 'HASH';
is $d->{'ehlo'}, '[127.0.0.1]';
is $d->{'header'}->{'replyto'}, 'straycats@cat-ml.example.org';

$d = $modulename->loadfile;
is $d, undef;

$j = '{ "neko": [ "kijitora", "mikeneko" ], "home": "Kyoto" }';
$d = $modulename->loadjson( $j );
isa_ok $d, 'HASH';
isa_ok $d->{'neko'}, 'ARRAY';
is $d->{'home'}, 'Kyoto';

$j = $modulename->dumpjson( $d );
ok length $j;

$d = $modulename->loadjson( $j );
isa_ok $d, 'HASH';
isa_ok $d->{'neko'}, 'ARRAY';
is $d->{'home'}, 'Kyoto';

$d = $modulename->loadjson;
is $d, undef;

done_testing;
__END__
