use warnings;
use Test::More;
use strict;
use IO::String;
use MIME::Base64;
use URI;
use URI::QueryParam;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel              => 'error',
            portal                => 'https://auth.example.com/',
            skinTemplateDir       => 't/templates',
            tpl_iniParam          => 'Template parameter from lemonldap-ng.ini',
            portalCustomTplParams =>
              { confParam => 'Template parameter from configuration' },
        }
    }
);

ok(
    $res = $client->_get(
        '/', accept => 'text/html'
    ),
    'Get login page'
);

like(
    $res->[2]->[0],
    qr,Template parameter from lemonldap-ng.ini,,
    "Found customized template param from ini file"
);

like(
    $res->[2]->[0],
    qr,Template parameter from configuration,,
    "Found customized template param from configuration"
);

done_testing();
