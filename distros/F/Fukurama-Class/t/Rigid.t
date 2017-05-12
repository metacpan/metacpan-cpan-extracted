#!perl -T
use Test::More tests => 6;
use lib qw(./ ./t);
use strict;
use warnings;

use Fukurama::Class::Rigid;
eval("\$t = 1");
like($@, qr/requires explicit/, 'strict is enabled');

close(STDERR);
my $warnings = '';
open(STDERR, '>', \$warnings);
eval("my \$t;my \$t;");
like($warnings, qr/earlier/, 'warnings is enabled');

eval("use Rigid::WrongPackage");
like($@, qr/Wrong package name/, 'croak at wrong packagename');

eval("use Rigid::RightPackage");
is($@, '', 'use right packagename correct');

eval("
	package MyWrongPackage;
	use Fukurama::Class::Rigid;
");
is($@, '', 'dont check packagename in eval');

my @warnings = split(/\n/, $warnings);
is(scalar(@warnings), 1, 'no other warnings');
