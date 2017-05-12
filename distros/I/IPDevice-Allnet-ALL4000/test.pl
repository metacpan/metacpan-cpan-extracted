use Test;
BEGIN { plan tests => 2 }

use strict;
use warnings;

use IPDevice::Allnet::ALL4000;

ok( 1 );

my %params = ( HOST     => 'localhost',
               USERNAME => 'testuser',
               PASSWORD => 'testpass',
               PORT     => '80' );

my $all4000;
eval
{
    $all4000 = new IPDevice::Allnet::ALL4000( %params );
};
ok( defined( $all4000 ), 1, 'Error creating new ALL4000 object: ' . $@ );
