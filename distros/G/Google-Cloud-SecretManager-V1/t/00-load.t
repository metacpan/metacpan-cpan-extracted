use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::SecretManager::V1') || print "Bail out!
";
}

diag( "Google::Cloud::SecretManager::V1 $Google::Cloud::SecretManager::V1::VERSION, Perl $], $^X" );
