use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Convert::Wikidata::Object::PublicationDate;
use Test::More 'tests' => 15;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'date' => '2010',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::PublicationDate');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'copyright' => 1,
	'date' => '2010',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::PublicationDate');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'date' => '2010',
	'sourcing_circumstances' => 'circa',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::PublicationDate');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'start_time' => '2010',
	'end_time' => '2012',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::PublicationDate');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'earliest_date' => '2010',
	'latest_date' => '2012',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::PublicationDate');

# Test.
eval {
	MARC::Convert::Wikidata::Object::PublicationDate->new(
		'date' => '2010',
		'earliest_date' => '2009',
	);
};
is($EVAL_ERROR, "Parameter 'date' is in conflict with parameter 'earliest_date'.\n",
	"Parameter 'date' is in conflict with parameter 'earliest_date'.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::PublicationDate->new(
		'date' => '2010',
		'latest_date' => '2012',
	);
};
is($EVAL_ERROR, "Parameter 'date' is in conflict with parameter 'latest_date'.\n",
	"Parameter 'date' is in conflict with parameter 'latest_date'.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::PublicationDate->new(
		'date' => '2010',
		'start_time' => '2009',
	);
};
is($EVAL_ERROR, "Parameter 'date' is in conflict with parameter 'start_time'.\n",
	"Parameter 'date' is in conflict with parameter 'start_time'.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::PublicationDate->new(
		'date' => '2010',
		'end_time' => '2012',
	);
};
is($EVAL_ERROR, "Parameter 'date' is in conflict with parameter 'end_time'.\n",
	"Parameter 'date' is in conflict with parameter 'end_time'.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::PublicationDate->new(
		'earliest_date' => '2009',
		'start_time' => '2009',
	);
};
is($EVAL_ERROR, "Parameter 'earliest_date' is in conflict with parameter 'start_time'.\n",
	"Parameter 'earliest_date' is in conflict with parameter 'start_time'.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::PublicationDate->new(
		'earliest_date' => '2009',
		'end_time' => '2010',
	);
};
is($EVAL_ERROR, "Parameter 'earliest_date' is in conflict with parameter 'end_time'.\n",
	"Parameter 'earliest_date' is in conflict with parameter 'end_time'.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::PublicationDate->new(
		'latest_date' => '2010',
		'start_time' => '2009',
	);
};
is($EVAL_ERROR, "Parameter 'latest_date' is in conflict with parameter 'start_time'.\n",
	"Parameter 'latest_date' is in conflict with parameter 'start_time'.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::PublicationDate->new(
		'latest_date' => '2009',
		'end_time' => '2010',
	);
};
is($EVAL_ERROR, "Parameter 'latest_date' is in conflict with parameter 'end_time'.\n",
	"Parameter 'latest_date' is in conflict with parameter 'end_time'.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::PublicationDate->new(
		'copyright' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'copyright' must be a bool (0/1).\n",
	"Parameter 'copyright' must be a bool (0/1).");
clean();
