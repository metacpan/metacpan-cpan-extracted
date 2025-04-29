use strict;
use Test::More;

use JSON::Schema::Generate;

my $data = '{
    "checked": false,
    "id": 1
}';

my $schema = JSON::Schema::Generate->new(
	id => 'https://example.com/arrays.schema.json',
	description => 'A representation of a person, company, organization, or place',
	spec => {
		id => {
			title => 'The ID of the door',
			description => 'This section represents the id of the door.'
		}
	}
)->learn($data)->generate;

my $schema_file = 't/schemas/schema-full.json';
if ($ENV{GENERATE_SCHEMA_FILES} == 1) {
  open my $fh, '>', $schema_file;
  print $fh $schema;
  close $fh;
}

my $schema_from_file;
{
  local($/) = undef;
  open my $fh, "<", $schema_file or die "Failed to open '$schema_file'... $!";
  $schema_from_file = <$fh>;
  close $fh;
}

is ($schema, $schema_from_file, "schema matched previously generated");

use JSON::Schema;
my $validator = JSON::Schema->new($schema);
my $result = $validator->validate($data);
ok($result);
done_testing;
