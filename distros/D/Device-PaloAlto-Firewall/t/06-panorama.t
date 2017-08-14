#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 1;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# No Panorama Configured
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_panorama_configured() )->simplify()->{result} } );

ok( !$fw->panorama_status(), "No Panorama peers configured");


sub no_panorama_configured {
    return <<'END'
<response status="success"><result></result></response>
END
}

sub single_panorama_up {
    return <<'END'
<response status="success"><result>Panorama Server 1 : 192.9.200.9
    Connected     : yes
    HA state      : Unknown
</result></response>
END
}
