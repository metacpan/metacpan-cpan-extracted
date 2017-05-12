# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

$|=1;

use Test::More tests => 5;

use_ok('HTML::Perlinfo');

my $output = `$^X t/info.cgi INFO_VARIABLES`;
ok($output =~ /Environment/i,"INFO_VARIABLES worked");

$output = `$^X t/info.cgi INFO_GENERAL`;
ok($output =~ /Perl version/i,"INFO_GENERAL worked");

$output = `$^X t/info.cgi INFO_LICENSE`;
ok($output =~ /license/i,"INFO_LICENSE worked");

$output = `$^X t/info.cgi INFO_CONFIG`;
ok($output =~ /config/i,"INFO_CONFIG worked");


