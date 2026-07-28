#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Privateca::V1::CertificateAuthorityServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Privateca::V1::CertificateAuthorityServiceClient $Google::Cloud::Privateca::V1::CertificateAuthorityServiceClient::VERSION, Perl $], $^X" );
