
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Persistent_2.t'

#########################

use Test::More tests => 5;
BEGIN { use_ok('HTML::Persistent') };
my $want_cleanup = 1;                        # Cancel cleanup for port-mortem data inspection.

#########################

use File::Temp qw(tempdir);
my $dir;
if( $want_cleanup )
{
	$dir = tempdir( CLEANUP => $want_cleanup );
}
else
{
	$dir = '/tmp/test-html-persistent';
	system( "/bin/rm -rf '$dir'" );
	system( "mkdir '$dir'" );
	diag( "Data will be left behind in directory $dir" );
}

my $db = HTML::Persistent->new({ dir => $dir, max => 5000 });
isa_ok( $db, 'HTML::Persistent', 'Test database for node deletion' );

# ========================================================

# Very simple insert and delete

$db->{aaaa}->set_val( 1234 );
$db->{bbbb}->set_val( 4321 );
$db->{cccc}->set_val( 4321 );

# Key order is not guaranteed
is( join( ':', sort keys( %$db )), 'aaaa:bbbb:cccc', "Check keys of top level" );

$db->sync();

my $node1 = $db->{bbbb};
$node1->{x1}->set_val( 1 );
$node1->{x2}->set_val( 1 );
$node1->{x3}->set_val( 1 );
$node1->{x4}->set_val( 1 );
$db->sync();

# Key order is not guaranteed
is( join( ':', sort keys( %$node1 )), 'x1:x2:x3:x4', "Check keys of node" );
$db->sync();

delete $node1->{x2};

is( join( ':', sort keys( %$node1 )), 'x1:x3:x4', "Check single key can be deleted" );
$db->sync();
