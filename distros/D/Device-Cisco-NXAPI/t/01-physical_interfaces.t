#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 12;
use File::Slurp;
use JSON;


BEGIN {
    use_ok( 'Device::Cisco::NXAPI' ) || print "Can't use Device::Cisco::NXAPI!\n";
}

my $json_reply = read_file('./t/json/interface/show_interface.json');

my $api = Device::Cisco::NXAPI->new(uri => "http://10.47.64.57:80", username => 'admin', password => '4install!!', debug => 0);

#Modofy the '_send_cmd' method so it always returns our JSON defined in the HEREDOC.
$api->meta->remove_method('_send_cmd');
$api->meta->add_method('_send_cmd', sub { return decode_json($json_reply)->{result}->{body} } );

my $test = $api->tester();

# Test for up interfaces
ok( $test->interfaces_up( interfaces => [ 'mgmt0' ] ), "Single Interface Up" );
ok( $test->interfaces_up( interfaces => [ 'mgmt0', 'Ethernet1/1'] ), "Multiple Interfaces Up" );

# Test for down interfaces
ok( !$test->interfaces_up( interfaces => [ 'Ethernet1/4'] ), "Single Interface Down" );
ok( !$test->interfaces_up( interfaces => [ 'Ethernet1/4', 'Ethernet1/5' ] ), "Multiple Interfaces Down" );

# Test should succeed if no interfaces specified
ok( $test->interfaces_up( interfaces => [ ] ), "No Interfaces Specified" );

# Misspelled or incorrect interfaces names should fail
ok( !$test->interfaces_up( interfaces => [ 'ehternet1/4' ] ), "Misspelled interface name" );
ok( !$test->interfaces_up( interfaces => [ 'Ethernet1/1', 'ehternet1/4' ] ), "Misspelled interface name with another correct interface" );

# Specifying the same interface twice should succeed
ok( $test->interfaces_up( interfaces => [ 'mgmt0', 'mgmt0' ] ), "Duplicate up interface" );
ok( $test->interfaces_up( interfaces => [ 'mgmt0', 'mgmt0', 'Ethernet1/1', 'Ethernet1/1'] ), "Duplicate multiple interfaces up" );
ok( !$test->interfaces_up( interfaces => [ 'Ethernet1/4', 'Ethernet1/4' ] ), "Duplicate down interface" );
ok( !$test->interfaces_up( interfaces => [ 'Ethernet1/4', 'Ethernet1/4', 'Ethernet1/5', 'Ethernet1/5' ] ), "Duplicate multiple down interfaces" );





