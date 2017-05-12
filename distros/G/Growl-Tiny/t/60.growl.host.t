#!/perl
use strict;

use Test::More tests => 3;

use Growl::Tiny qw(notify);

my $growl_host = $ENV{GROWL_HOST} || 'localhost';
$ENV{GROWL_HOST} = '';

ok( notify( { subject => 'disabled network delivery',
              title   => 'network growl',
          }),
    "notify() called without network delivery"
);

ok( notify( { subject => 'using "host" param to notify',
              title   => 'network growl',
              host    => $growl_host,
          }),
    "notify() called with 'host' set to $growl_host and no GROWL_HOST env var"
);


$ENV{GROWL_HOST} = $growl_host;

ok( notify( { subject => 'using GROWL_HOST env var',
              title   => 'network growl',
          }),
    "notify() called with GROWL_HOST set to $growl_host"
);
    
