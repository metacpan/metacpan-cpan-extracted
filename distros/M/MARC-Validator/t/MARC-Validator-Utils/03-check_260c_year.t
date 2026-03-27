use strict;
use warnings;

use MARC::Validator::Utils qw(check_260c_year);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $self = {};
my $value = '(1940)';
my $field = '260';
my @errors = check_260c_year($self, $value, $field);
isa_ok($errors[0], 'Data::MARC::Validator::Report::Error');
is($errors[0]->error, "Bad year in parenthesis in MARC field 260 \$c.",
	"Get error (Bad year in parenthesis in MARC field 260 \$c.).");
is($errors[0]->params->{'Value'}, '(1940)', 'Get error parameter (Value => (1940)).');
