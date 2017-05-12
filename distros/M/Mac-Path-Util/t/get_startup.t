use Test::More tests => 2;

use Mac::Path::Util;

my $Startup = Mac::Path::Util::STARTUP;

my $util = Mac::Path::Util->new();
$util->use_carbon(0);
isa_ok( $util, 'Mac::Path::Util' );

my $startup = $util->_get_startup;
is( $startup, $Startup, "_get_startup returns right name [$startup]" );

$util->use_carbon(1);
$util->clear_startup;

$startup = $util->_get_startup;
diag( "\nThis test is just for fun\n",
       "You need Mac::Carbon to make it discover the true name\n",
	"I think your startup volume name is  [$startup]\n" );
