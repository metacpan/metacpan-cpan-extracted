# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as
# 'perl t/02-basic-tests-with-maypole.t'
use strict;
use warnings;

# 02-basic-tests-with-maypole
#
# 01 ran without any external dependencies to make sure the
# Authorization modules itself appears to be intact.
#
# These tests run with Maypole, but still simulate the Authentication
# module (see BeerDB.pm for this).

#########################

use Test::More tests => 23;
my $DEBUG = 0;
my $MPA = 'Maypole::Plugin::Authorization';

# First check that Maypole passes its most basic tests
# (borrowed from Maypole-2.09/t/01basics.t)

use lib 't'; # Where BeerDB.pm should live
BEGIN {
    require_ok( 'BeerDB' );
}
use Maypole::CLI qw(BeerDB);
use Maypole::Constants;
$ENV{MAYPOLE_TEMPLATES} = 't/templates';

isa_ok( (bless {}, 'BeerDB') , 'Maypole')
or diag("Maypole can't create a request object properly - rerun its tests");

# Run one Maypole test to be sure it is running
like(BeerDB->call_url("http://localhost/beerdb/"), qr/frontpage/,
     "Got frontpage, Maypole is running")
or diag("Maypole isn't working - please rerun its tests");

# And one to ensure it can access the test database
my $page = BeerDB->call_url("http://localhost/beerdb/brewery/view/1");
like($page,qr/St Peter/,'Found a brewery, Maypole seems to work')
or diag("Maypole isn't working - please rerun its tests");


# Now start tests of Maypole::Plugin::Authorization

{
  package BeerDB;	# our Maypole application/request class


# Test we can load the plugin and fixup the inheritance
main::use_ok($MPA);
push @BeerDB::ISA, $MPA;

# Set attributes in a fake request to let us run a quick confidence test
my $r = bless {}, 'BeerDB';
$r->model_class('BeerDB::Beer');
$r->action('list');
$r->user(BeerDB::Users->retrieve(1));
main::ok($r->authorize($r), 'isolated authorize handles basic case');

}

# Then run basic tests using Maypole::CLI

# Test authorize method
like(BeerDB->call_url('http://localhost/beerdb/beer/list'), qr/Organic Best/,
  'authorize handles authorized class+action');

like(BeerDB->call_url('http://localhost/beerdb/pub/list'), qr/no permission/,
  'authorize handles unauthorized class');

like(BeerDB->call_url('http://localhost/beerdb/beer/view/1'), qr/no permission/,
  'authorize handles unauthorized action');

# Test get_authorized_classes method
like(BeerDB->call_url('http://localhost/beerdb/beer/classes'),
  qr/ZZ BeerDB::Beer YY/,
  'get_authorized_classes handles basic case');

# Test get_authorized_methods method
like(BeerDB->call_url('http://localhost/beerdb/beer/methods'),
  qr/ZZ classes,list,methods YY/,
  'get_authorized_methods handles basic case');


# Now test various combinations of parameters

# Test get_authorized_classes method with explicit userid
like(BeerDB->call_url('http://localhost/beerdb/beer/classes'),
  qr/XX BeerDB::Beer WW classes/,
  'get_authorized_classes handles explicit userid');

like(BeerDB->call_url('http://localhost/beerdb/beer/classes'),
  qr/VV  UU classes/,
  'get_authorized_classes handles unauthorized user');

# Test get_authorized_methods method with explicit userid
like(BeerDB->call_url('http://localhost/beerdb/beer/methods'),
  qr/XX classes,list,methods WW methods/,
  'get_authorized_methods handles explicit userid');

like(BeerDB->call_url('http://localhost/beerdb/beer/methods'),
  qr/VV  UU methods/,
  'get_authorized_methods handles unauthorized user');

# Test get_authorized_methods method with explicit class
like(BeerDB->call_url('http://localhost/beerdb/beer/methods'),
  qr/TT classes,list,methods SS methods/,
  'get_authorized_methods handles explicit class');

like(BeerDB->call_url('http://localhost/beerdb/beer/methods'),
  qr/RR  QQ methods/,
  'get_authorized_methods handles unauthorized class');

# Test get_authorized_methods method with explicit userid and class
like(BeerDB->call_url('http://localhost/beerdb/beer/methods'),
  qr/PP classes,list,methods OO methods/,
  'get_authorized_methods handles explicit userid and class');

like(BeerDB->call_url('http://localhost/beerdb/beer/methods'),
  qr/NN  MM/,
  'get_authorized_methods handles unauthorized class no.2');

like(BeerDB->call_url('http://localhost/beerdb/beer/methods'),
  qr/LL  KK/,
  'get_authorized_methods handles unauthorized user no.2');


# Test missing implicit parameters

like(BeerDB->call_url('http://localhost/beerdb/style/classes'),
  qr/JJ  II classes/,
  'get_authorized_classes handles no user');

like(BeerDB->call_url('http://localhost/beerdb/style/methods'),
  qr/JJ  II methods/,
  'get_authorized_methods handles no user');

like(BeerDB->call_url('http://localhost/beerdb/methods'),
  qr/HH  GG methods/,
  'get_authorized_methods handles no model class');

