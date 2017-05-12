#!/usr/bin/perl

#==============================================================================
#
# Simple script to test LemonLDAP::NG SOAP services
#
#==============================================================================

use strict;
use SOAP::Lite;
use Data::Dumper;

# Session ID (first parameter)
my $session_id = shift @ARGV;

# Service
my $soap =
  SOAP::Lite->new( proxy => 'http://auth.example.com/index.pl/sessions' );
$soap->default_ns('urn:Lemonldap/NG/Common/CGI/SOAPService');

# Call some SOAP methods
my $attributes = $soap->call( 'getAttributes', $session_id )->result();
print Dumper $attributes;

my $applications = $soap->call( 'getMenuApplications', $session_id )->result();
print Dumper $applications;

exit;
