use strict;
use warnings;
use Test::More tests => 3;

use Log::Any '$log', default_adapter => 'Stderr';

isa_ok( $log, 'Log::Any::Proxy', 'we have a proxy...' );
ok( !$log->isa('Log::Any::Proxy::Null'), '...but it\'s not the null proxy' );

my $err;
{
    open my $fd, ">", \$err;
    local *STDERR = $fd;
    $log->err( "Foobared. This test is likely broken if you see this message" );
};

like $err, qr/Foobared/, "Log captured on STDERR";

