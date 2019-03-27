use strict;
use warnings;
use 5.010;

use Device::Firewall::PaloAlto;

use Test::More;
use Test::Warn;

ok( my $fw = Device::Firewall::PaloAlto->new(uri => 'https://localhost', username => 'admin', password => 'password'), "new() with 3 args" );

warning_is { Device::Firewall::PaloAlto->new(uri => 'scheme://localhost', username => 'admin', password => 'password') } "Incorrect URI scheme in uri 'scheme://localhost': must be either http or https", "Warn on scheme";

ok( $fw->op, 'Operational Object' );

done_testing();
