#! perl -T

use Test::More tests => 4;

my $module = 'Mail::Action::Address';
use_ok( $module ) or exit;

diag( 'apply the expires role' );
Class::Roles->import( does => 'address_expires' );
can_ok( __PACKAGE__, 'expires', 'process_time' );

diag( 'apply the named role' );
Class::Roles->import( does => 'address_named' );
can_ok( __PACKAGE__, 'name' );

diag( 'apply the described role' );
Class::Roles->import( does => 'address_described' );
can_ok( __PACKAGE__, 'description' );
