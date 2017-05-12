#!/usr/bin/perl
use strict;
use warnings;

### Example for method query(): get identity of router by command line

use MikroTik::API;

my $api = MikroTik::API->new({
	host => 'mikrotik.example.org',
	username => 'whoami',
	password => 'SECRET',
	use_ssl => 1,
});

my ( $ret_get_identity, @aoh_identity ) = $api->query( '/system/identity/print', {}, {} );
print "Name of router: $aoh_identity[0]->{name}\n";

$api->logout();
