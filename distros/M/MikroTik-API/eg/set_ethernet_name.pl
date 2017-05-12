#!/usr/bin/perl
use strict;
use warnings;

### Example for combination of query() and cmd(): set name of ethernet interface by default-name

use MikroTik::API;

if ( not ( defined $ARGV[0] && defined $ARGV[1] ) ) {
	die 'USAGE: $0 <default name> <new name>';
}

my $api = MikroTik::API->new({
	host => 'mikrotik.example.org',
	username => 'whoami',
	password => 'SECRET',
	use_ssl => 1,
});

my ( $ret_interface_print, @interfaces ) = $api->query('/interface/print', { '.proplist' => '.id,name' }, { type => 'ether', 'default-name' => $ARGV[0] } );
if( $interfaces[0]->{name} eq $ARGV[1] ) {
	print "Name is already set to this value\n";
}
else {
	my $ret_set_interface = $api->cmd( '/interface/ethernet/set', { '.id' => $interfaces[0]->{'.id'}, 'name' => $ARGV[1] } );
	print "Name changed\n";
}

$api->logout();
