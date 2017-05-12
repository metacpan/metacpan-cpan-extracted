#!perl -T
use Test::More tests => 2;
use lib qw(./ ./t);
use strict;
use warnings;

close(STDERR);
my $warnings = '';
open(STDERR, '>', \$warnings);

use Fukurama::Class::Rigid();
$Fukurama::Class::Rigid::PACKAGE_NAME_CHECK = 0;
use Fukurama::Class::Rigid;

eval("use Rigid::WrongPackage");
is($@, '', 'packagename check can be disabled');

is($warnings, '', 'no warnings');
