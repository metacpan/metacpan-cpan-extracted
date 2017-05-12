#!/usr/bin/perl

#==============================================================================
#
# Simple script to test LemonLDAP::NG SOAP configuration service
#
#==============================================================================

use strict;
use SOAP::Lite;
use Data::Dumper;

# Service
my $soap =
  SOAP::Lite->new( proxy => 'http://auth.example.com/index.pl/config' );
$soap->default_ns('urn:Lemonldap/NG/Common/CGI/SOAPService');

# Call SOAP methods
my $lastCfg = $soap->call('lastCfg')->result();
print "Last configuration:\n" . Dumper $lastCfg;

my $config = $soap->call('getConfig')->result();
print "Configuration data:\n" . Dumper $config;

exit;
