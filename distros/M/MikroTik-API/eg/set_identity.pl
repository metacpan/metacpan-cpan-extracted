#!/usr/bin/perl
use strict;
use warnings;

### Example for method cmd(): set identity of router by command line

use MikroTik::API;

if ( not defined $ARGV[0] ) {
	die 'USAGE: $0 <new name>';
}

my $api = MikroTik::API->new({
	host => 'mikrotik.example.org',
	username => 'whoami',
	password => 'SECRET',
	use_ssl => 1,
});

my $ret_set_identity = $api->cmd( '/system/identity/set', { 'name' => $ARGV[0] } );
print "Name set\n";

$api->logout();
