use strict;
use warnings;

use MARC::Validator::Utils qw(check_260c_year);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $value = '(1940)';
my $struct_hr = {};
my $id = 'ID';
my $field = '260';
check_260c_year({}, $value, $struct_hr, $id, $field);
is_deeply(
	$struct_hr->{'not_valid'}->{$id}->[0],
	{
		'error' => 'Bad year in parenthesis in MARC field 260 $c.',
		'params' => {
			'Value' => '(1940)',
		},
	},
	'Get error.',
);
