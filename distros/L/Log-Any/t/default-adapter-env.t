use strict;
use warnings;
use Test::More tests => 4;

BEGIN { $ENV{LOG_ANY_DEFAULT_ADAPTER} = 'Test'; }

use Log::Any '$log';

isa_ok( $log, 'Log::Any::Proxy', 'we have a proxy...' );
ok( !$log->isa('Log::Any::Proxy::Null'), '...but it\'s not the null proxy' );

isa_ok( $log->adapter, 'Log::Any::Adapter::Test', 'correct adapter set' );
$log->err("this is an error");
$log->adapter->contains_ok( qr/this is an error/,
    'adapter got error string' );
