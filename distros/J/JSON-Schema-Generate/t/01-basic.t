use Test::More;

use JSON::Schema::Generate;

my $data = '{
    "checked": false,
    "dimensions": {
        "width": 5,
        "height": 10
    },
    "id": 1,
    "name": "A green door",
    "price": 12.5,
    "tags": [
	{ "date-time": "2018-11-13T20:20:39+00:00" }
    ]
}';

my $schem = JSON::Schema::Generate->new(
	id => 'https://example.com/arrays.schema.json',
	description => 'A representation of a person, company, organization, or place',
	spec => {
		id => {
			title => 'The ID of the door',
			description => 'This section represents the id of the door.'
		}
	}
)->learn($data)->generate;

use JSON::Schema;
my $validator = JSON::Schema->new($schem);
my $result = $validator->validate($data);
ok($result);
done_testing;
