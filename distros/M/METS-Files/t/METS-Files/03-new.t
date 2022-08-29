use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use METS::Files;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $mets_data = slurp($data->file('ex1.mets')->s);
my $obj = METS::Files->new(
	'mets_data' => $mets_data,
);
isa_ok($obj, 'METS::Files');
is($obj->{'_prefix'}, '', 'Default METS prefix.');

# Test.
$mets_data = slurp($data->file('ex2.mets')->s);
$obj = METS::Files->new(
	'mets_data' => $mets_data,
);
isa_ok($obj, 'METS::Files');
is($obj->{'_prefix'}, 'mets:', 'Explicit METS prefix.');

# Test.
eval {
	METS::Files->new;
};
is($EVAL_ERROR, "Parameter 'mets_data' is required.\n",
	"Parameter 'mets_data' is required.");
clean();
