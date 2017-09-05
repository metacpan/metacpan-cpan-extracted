#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 10;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# No Panorama Configured
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_panorama_configured() )->simplify( forcearray => ['entry'] )->{result} } );

isa_ok( $fw->panorama_status(), 'ARRAY', "No Panorama returns ARRAYREF" );
is_deeply( $fw->panorama_status(), [] , "No Panorama returns an empty ARRAYREF" );

ok( !$test->panorama_connected(), "No Panorama configured returns 0" );

# Single Panorama Confiugured and up
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( single_panorama_up() )->simplify( forcearray => ['entry'] )->{result} } );

isa_ok( $fw->panorama_status(), 'ARRAY', "Single Panorama returns ARRAYREF" );
ok( $fw->panorama_status(), "Single Panorama returns ARRAYREF" );

ok( $test->panorama_connected(), "Single up Panorama returns 1" );

# Multiple Panorama configured one down
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( multiple_panorama_one_down() )->simplify( forcearray => ['entry'] )->{result} } );

isa_ok( $fw->panorama_status(), 'ARRAY', "Multiple Panorama returns ARRAYREF" );

ok( !$test->panorama_connected(), "Multiple Panorama one down returns 0" );

# Multiple Panorama configured all up
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( multiple_panorama_all_up() )->simplify( forcearray => ['entry'] )->{result} } );

isa_ok( $fw->panorama_status(), 'ARRAY', "Multiple Panorama all up returns ARRAYREF" );

ok( $test->panorama_connected(), "Multiple Panorama all up returns 1" );


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

sub multiple_panorama_one_down {
    return <<'END'
<response status="success"><result>Panorama Server 1 : 1.1.1.1
    Connected     : no
    HA state      : disconnected

Panorama Server 2 : 1.1.1.2
    Connected     : yes
    HA state      : disconnected
</result></response>
END
}

sub multiple_panorama_all_up {
    return <<'END'
<response status="success"><result>Panorama Server 1 : 1.1.1.1
    Connected     : yes
    HA state      : Unknown 

Panorama Server 2 : 1.1.1.2
    Connected     : yes
    HA state      : Unknown 
</result></response>
END
}
