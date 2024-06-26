use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Convert::Wikidata::Object::People;
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = MARC::Convert::Wikidata::Object::People->new;
isa_ok($obj, 'MARC::Convert::Wikidata::Object::People');

# Test.
$obj = MARC::Convert::Wikidata::Object::People->new(
	date_of_birth => '1814',
	date_of_death => '1883',
	name => decode_utf8('Antonín'),
	nkcr_aut => 'jk01033252',
	surname => 'Halouzka',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::People', 'Full object.');

# Test.
eval {
	MARC::Convert::Wikidata::Object::People->new(
		date_of_birth => 'foo',
		date_of_death => '1883',
		name => decode_utf8('Antonín'),
		nkcr_aut => 'jk01033252',
		surname => 'Halouzka',
	);
};
is($EVAL_ERROR, "Parameter 'date_of_birth' is in bad format.\n",
	"Parameter 'date_of_birth' is in bad format.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::People->new(
		date_of_birth => '1900',
		date_of_death => '1883',
		name => decode_utf8('Antonín'),
		nkcr_aut => 'jk01033252',
		surname => 'Halouzka',
	);
};
is($EVAL_ERROR, "Parameter 'date_of_birth' has date greater or same as parameter 'date_of_death' date.\n",
	"Parameter 'date_of_birth' has date greater or same as parameter 'date_of_death' date.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::People->new(
		work_period_start => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'work_period_start' is in bad format.\n",
	"Parameter 'work_period_start' is in bad format (bad).");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::People->new(
		work_period_end => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'work_period_end' is in bad format.\n",
	"Parameter 'work_period_end' is in bad format (bad).");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::People->new(
		work_period_start => '1900',
		work_period_end => '1883',
	);
};
is($EVAL_ERROR, "Parameter 'work_period_start' has date greater or same as parameter 'work_period_end' date.\n",
	"Parameter 'work_period_start' has date greater or same as parameter 'work_period_end' date.");
clean();
