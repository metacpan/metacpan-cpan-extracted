#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 6;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# No IKE Configured
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_ike_configured() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->ike_peers(), 'ARRAY' );
is_deeply( $fw->ike_peers(), [] , "No IKE configured returns an empty ARRAYREF" );

# No IKE Up
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_ike_up() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->ike_peers(), 'ARRAY' );
is_deeply( $fw->ike_peers(), [] , "No IKE up returns an empty ARRAYREF" );

# IKE up no IPSEC
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( ike_up_no_ipsec() )->simplify(forcearray => ['entry'] )->{result} } );
isa_ok( $fw->ike_peers(), 'ARRAY' );

# All up
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( all_up() )->simplify(forcearray => ['entry'] )->{result} } );
isa_ok( $fw->ike_peers(), 'ARRAY' );








sub no_ike_configured {
   return <<'END'
<response status="success"><result/></response>
END
}

sub no_ike_up {
   return <<'END'
<response status="success"><result/></response>
END
}

sub ike_up_no_ipsec {
   return <<'END'
<response status="success"><result>
  <entry>
    <name>c1000v</name>
    <created>Aug.28 18:44:58</created>
    <expires>Aug.29 02:44:58</expires>
    <gwid>1</gwid>
    <role>Init</role>
    <mode>Main</mode>
    <algo>PSK/ DH5/ AES/SHA512</algo>
  </entry>
</result></response>
END
}

sub all_up {
   return <<'END'
<response status="success"><result>
  <entry>
    <name>c1000v</name>
    <created>Aug.28 18:44:58</created>
    <expires>Aug.29 02:44:58</expires>
    <gwid>1</gwid>
    <role>Init</role>
    <mode>Main</mode>
    <algo>PSK/ DH5/ AES/SHA512</algo>
  </entry>
</result></response>
END
}
