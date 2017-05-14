#!/usr/bin/perl

#==============================================================================
#
# Simple script to test LemonLDAP::NG SOAP error method
#
#==============================================================================

use strict;
use SOAP::Lite;
use Data::Dumper;

my $error_code = 15;

# Service
my $soap = SOAP::Lite->new( proxy => 'http://auth.example.com/index.pl' );
$soap->default_ns('urn:Lemonldap/NG/Common/CGI/SOAPService');

# Call error SOAP method
my $error_fr = $soap->call( 'error', $error_code, 'fr' )->result();
print Dumper $error_fr;

my $error_en = $soap->call( 'error', $error_code, 'en' )->result();
print Dumper $error_en;

exit;
