use strict;
use warnings;

use Fedora::RPM::Spec::License;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Fedora::RPM::Spec::License->new;
isa_ok($obj, 'Fedora::RPM::Spec::License');
