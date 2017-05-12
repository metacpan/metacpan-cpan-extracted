#! perl -T

use Test::More tests => 5;

my $module = 'Mail::Action::Address';
use_ok( $module ) or exit;

my $add = bless {}, $module;

can_ok( $module, 'description' );
is( $add->description(), '',
    'description() should be blank unless set in constructor' );

$add->{description} = 'now set';
is( $add->description(), 'now set',
    '... or whatever is set in constructor' );

$add->description( 'set here' );
is( $add->description(), 'set here',
    '... and should be able to set description' );
