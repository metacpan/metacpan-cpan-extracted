#!perl
use strict;
use warnings;
use utf8;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use Carp qw/carp croak/;
use MaybeMaketextIntegrationTest;

MaybeMaketextIntegrationTest::test_integration_package('Locale::Maketext::Utils');
done_testing();
