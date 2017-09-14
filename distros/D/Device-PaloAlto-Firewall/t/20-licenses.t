#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 5;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# No licences
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_licenses() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->licenses(), 'ARRAY' );
is_deeply( $fw->licenses(), [] , "No licenses returns an empty ARRAYREF" );

ok( !$test->licenses_active(), "No licenses returns 0");

## Some licenses expired
#$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( licenses_expired() )->simplify(forcearray => ['entry'] )->{result} } );
#
#isa_ok( $fw->ospf_neighbours(), 'ARRAY' );
#is_deeply( $fw->ospf_neighbours(), [] , "No OSPF neighbours returns an empty ARRAYREF" );
#
#ok( !$test->ospf_neighbours_up(neighbours => ['192.168.122.30']), "OSPF with no neighbours returns 0");
#
# All licenses active
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( licenses_active() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->licenses(), 'ARRAY' );
ok( $test->licenses_active(), "Licenses active returns 1");

sub no_licenses {
   return <<'END'
<response status="success"><result><licenses></licenses></result></response>
END
}

sub licenses_expired {
   return <<'END'
END
}

sub licenses_active {
   return <<'END'
<response status="success"><result><licenses><entry><feature>PA-VM</feature><description>Standard VM-300</description><serial>1234567890</serial><issued>July 06, 2017</issued><expires>Never</expires><expired>no</expired><authcode></authcode></entry><entry><feature>WildFire License</feature><description>WildFire signature feed, integrated WildFire logs, WildFire API</description><serial>1234567890</serial><issued>July 06, 2017</issued><expires>June 30, 2020</expires><expired>no</expired><base-license-name>PA-VM</base-license-name><authcode></authcode></entry><entry><feature>Threat Prevention</feature><description>Threat Prevention</description><serial>1234567890</serial><issued>July 06, 2017</issued><expires>June 30, 2020</expires><expired>no</expired><base-license-name>PA-VM</base-license-name><authcode></authcode></entry><entry><feature>PAN-DB URL Filtering</feature><description>Palo Alto Networks URL Filtering License</description><serial>1234567890</serial><issued>July 06, 2017</issued><expires>June 30, 2020</expires><expired>no</expired><base-license-name>PA-VM</base-license-name><authcode></authcode></entry><entry><feature>GlobalProtect Gateway</feature><description>GlobalProtect Gateway License</description><serial>1234567890</serial><issued>July 06, 2017</issued><expires>June 30, 2020</expires><expired>no</expired><base-license-name>PA-VM</base-license-name><authcode></authcode></entry><entry><feature>Premium Partner</feature><description>Premium Partner</description><serial>1234567890</serial><issued>July 06, 2017</issued><expires>June 30, 2020</expires><expired>no</expired><base-license-name>PA-VM</base-license-name><authcode></authcode></entry></licenses></result></response>
END
}
