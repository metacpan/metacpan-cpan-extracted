use Test::More;

use JSON::Schema::Generate;

my $data = '{
    "checked": false,
    "id": 1
}';

my $schem = JSON::Schema::Generate->new(
	id => 'https://example.com/arrays.schema.json',
	description => 'A representation of a person, company, organization, or place',
	spec => {
		id => {
			title => 'The ID of the door',
			description => 'This section represents the id of the door.'
		}
	},
	none_required => 1
)->learn($data)->generate;

open my $fh, '>', 'schema.json';
print $fh $schem;
close $fh;

use JSON::Schema;
my $validator = JSON::Schema->new($schem);
my $result = $validator->validate($data);
ok($result);
done_testing;
