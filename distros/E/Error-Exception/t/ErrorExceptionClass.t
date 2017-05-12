use Test::Unit::HarnessUnit;
use lib qw(t/tlib);

my $r = Test::Unit::HarnessUnit->new();

$r->start( 'Error::Exception::Test::Class' );
