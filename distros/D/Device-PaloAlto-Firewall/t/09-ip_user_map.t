#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 14;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# User-ID not configured
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_userid_configured() )->simplify( forcearray => ['entry'] )->{result} } );


ok( !$test->ip_user_mapping(domain => 'domain', users => [ 'user1' ]), "No User-ID with configured with domain and user args returns 0" );
ok( !$test->ip_user_mapping(users => [ 'user1' ]), "No User-ID with configured with only user arg returns 0" );
ok( !$test->ip_user_mapping(domain => 'domain'), "No User-ID with configured with only domain arg returns 0" );
ok( !$test->ip_user_mapping(), "No User-ID with configured with no args returns 0" );

# User-ID configured and receiving entries
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( userid_mappings() )->simplify( forcearray => ['entry'] )->{result} } );

ok( $test->ip_user_mapping(), "User-ID configured with no args specified returns 1" );
ok( $test->ip_user_mapping(domain => 'domain'), "User-ID configured with domain specified returns 1" );
ok( $test->ip_user_mapping(users => ['user1']), "User-ID configured with user arg specified returns 1" );
ok( $test->ip_user_mapping(users => ['user1', 'user4']), "Multiple user across domains returns 1");
ok( !$test->ip_user_mapping(users => ['user1', 'user20']), "Multiple user, only 1 valid across domains returns 0");

ok( $test->ip_user_mapping(domain => 'domain', users => ['user1']), "Single matched user with domain returns 1");
ok( $test->ip_user_mapping(domain => 'domain', users => ['user1', 'user2']), "Multiple matched user with domain returns 1");
ok( $test->ip_user_mapping(users => ['user1']), "Single matched user without domain returns 1");
ok( $test->ip_user_mapping(users => ['user1', 'user2']), "Multiple matched user without domain returns 1");

ok( !$test->ip_user_mapping(domain => 'another_domain', users => ['user1', 'user4']), "Multiple user, only one in specified domain returns 0");

sub no_userid_configured {
    return <<'END'
<response status="success"><result/></response>
END
}

sub userid_mappings {
   return <<'END'
<response status="success"><result>
<entry><ip>192.9.202.79</ip><vsys>vsys1</vsys><type>AD</type><user>domain\user1</user><idle_timeout>413</idle_timeout><timeout>413</timeout></entry>
<entry><ip>192.9.200.64</ip><vsys>vsys1</vsys><type>AD</type><user>domain\user2</user><idle_timeout>2644</idle_timeout><timeout>2644</timeout></entry>
<entry><ip>192.9.201.141</ip><vsys>vsys1</vsys><type>AD</type><user>domain\user3</user><idle_timeout>668</idle_timeout><timeout>668</timeout></entry>
<entry><ip>10.5.232.26</ip><vsys>vsys1</vsys><type>Unknown</type><user>unknown</user><idle_timeout>2</idle_timeout><timeout>5</timeout></entry>
<entry><ip>10.5.232.26</ip><vsys>vsys1</vsys><type>Unknown</type><user>unknown</user><idle_timeout>2</idle_timeout><timeout>5</timeout></entry>
<entry><ip>192.9.202.80</ip><vsys>vsys1</vsys><type>AD</type><user>another_domain\user4</user><idle_timeout>2637</idle_timeout><timeout>2637</timeout></entry>
<entry><ip>192.9.201.29</ip><vsys>vsys1</vsys><type>AD</type><user>another_domain\user5</user><idle_timeout>2028</idle_timeout><timeout>2028</timeout></entry>
<entry><ip>192.168.24.8</ip><vsys>vsys1</vsys><type>AD</type><user>another_domain\user6</user><idle_timeout>1693</idle_timeout><timeout>1693</timeout></entry>
<count>8</count>
</result></response>
END
}
