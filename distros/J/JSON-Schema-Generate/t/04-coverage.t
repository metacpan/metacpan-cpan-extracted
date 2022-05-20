use Test::More;

use JSON::Schema::Generate;
my $scalar = 0;
my $data = {
    "checked" => \$scalar,
    "num" => 123,
    "float" => 5.555,
    "id" => 1,
    "array" => [
	"one",
	{
		"abc" => "def"
	},
	[
		"two"
	]
    ]
};

my $schem = JSON::Schema::Generate->new(
	no_id => 1,
	merge_examples => 1,
	spec => {
		id => {
			title => 'The ID of the door',
			description => 'This section represents the id of the door.'
		}
	}
)->learn($data)->generate(1);


open my $fh, '>', 'schema.json';
print $fh $schem;
close $fh;

use JSON::Schema;
my $validator = JSON::Schema->new($schem);
my $result = $validator->validate($data);
ok($result);
done_testing;
