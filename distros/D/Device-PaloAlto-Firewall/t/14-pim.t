#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 9;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# No PIM Configured.
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_pim_configured() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->pim_neighbours(), 'ARRAY' );
is_deeply( $fw->pim_neighbours(), [] , "No PIM returns an empty ARRAYREF" );

ok( !$test->pim_neighbours_up(neighbours => ['192.168.122.30']), "No PIM configured returns 0");

# PIM configured, but no peers.
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_pim_neighbour() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->pim_neighbours(), 'ARRAY' );
is_deeply( $fw->pim_neighbours(), [] , "No PIM peers returns empty ARRAYREF" );

ok( !$test->pim_neighbours_up(neighbours => ['192.168.122.30']), "PIM configured with no neighbour returns 0");


# PIM configured and a peer is up.
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( pim_neighbour_up() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->pim_neighbours(), 'ARRAY' );
ok( $test->pim_neighbours_up(neighbours => ['192.168.122.30']), "PIM configured with a neighbour returns 1");
ok( !$test->pim_neighbours_up(neighbours => ['192.168.122.29']), "PIM configured with a neighbour but not specified returns 0");

sub no_pim_configured {
   return <<'END'
<response status="success"><result/></response>
END
}

sub no_pim_neighbour {
   return <<'END'
<response status="success"><result/></response>
END
}

sub pim_neighbour_up {
   return <<'END'
<response status="success"><result>
  <entry>
    <DRPriority>1</DRPriority>
    <UpTime>44.97</UpTime>
    <ExpiryTime>94.06</ExpiryTime>
    <sec/>
    <Address>192.168.122.30</Address>
    <IfIndex>ethernet1/1</IfIndex>
    <GenerationIDValue>1410841443</GenerationIDValue>
    <GenerationIDPresent>yes</GenerationIDPresent>
  </entry>
</result></response>
END
}


