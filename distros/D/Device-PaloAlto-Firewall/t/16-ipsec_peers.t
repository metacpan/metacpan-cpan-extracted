#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 7;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# No IKE Configured
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_ipsec_configured() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->ipsec_peers(), 'ARRAY' );
is_deeply( $fw->ipsec_peers(), [] , "No IPSEC configured returns an empty ARRAYREF" );

# No IKE or IPSEC UP
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_ike_no_ipsec_up() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->ipsec_peers(), 'ARRAY' );
is_deeply( $fw->ipsec_peers(), [] , "No IKE or IPSEC up returns an empty ARRAYREF" );

# IKE up, IPSEC not up
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( ike_up_no_ipsec() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->ipsec_peers(), 'ARRAY' );
is_deeply( $fw->ipsec_peers(), [] , "IKE up, IPSEC not up returns an empty ARRAYREF" );

# IPSEC peer up
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( all_up() )->simplify(forcearray => ['entry'] )->{result} } );
isa_ok( $fw->ipsec_peers(), 'ARRAY' );

sub no_ipsec_configured {
   return <<'END'
<response status="success"><result><ntun>0</ntun><entries/></result></response>
END
}

sub no_ike_no_ipsec_up {
   return <<'END'
<response status="success"><result>
  <ntun>1</ntun>
  <entries/>
</result></response>
END
}

sub ike_up_no_ipsec{
   return <<'END'
<response status="success"><result><ntun>1</ntun><entries/></result></response>
END
}

sub all_up {
   return <<'END'
<response status="success"><result>
  <ntun>1</ntun>
  <entries>
    <entry>
      <kb>4608000</kb>
      <life>3527</life>
      <enc>3DES</enc>
      <remote>192.168.122.30        </remote>
      <name>c1000v(c1000v)</name>
      <proto>ESP</proto>
      <i_spi>-1257231397</i_spi>
      <gwid>1</gwid>
      <o_spi>-2087709595</o_spi>
      <tid>1</tid>
      <hash>MD5</hash>
    </entry>
  </entries>
</result></response>
END
}
