# check pod in modules,
# see http://search.cpan.org/~dwheeler/Test-Pod-1.48/lib/Test/Pod.pm
use strict;
use Test::Pod tests => 2;

pod_file_ok( 'lib/HTTP/OAIPMH/Validator.pm', 'HTTP::OAIPMH::Validator POD ok' );
pod_file_ok( 'lib/HTTP/OAIPMH/Log.pm', 'HTTP::OAIPMH::Log POD ok' );