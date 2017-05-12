use 5.010;
use lib "lib";
use lib "../JSON-JOM/lib";
use JSON::JOM qw[from_json to_json to_jom];
use JSON::Path;
use Scalar::Util qw[blessed];

my $object = to_jom(from_json(<<'JSON'));
{
	"store": {
		"book": [
			{
				"category": "reference",
				"author":   "Nigel Rees",
				"title":    "Sayings of the Century",
				"price":    8.95
			},
			{
				"category": "fiction",
				"author":   "Evelyn Waugh",
				"title":    "Sword of Honour",
				"price":    12.99
			},
			{
				"category": "fiction",
				"author":   "Herman Melville",
				"title":    "Moby Dick",
				"isbn":     "0-553-21311-3",
				"price":    8.99
			},
			{
				"category": "fiction",
				"author":   "J. R. R. Tolkien",
				"title":    "The Lord of the Rings",
				"isbn":     "0-395-19395-8",
				"price":    22.99
			}
		],
		"bicycle": {
			"color": "red",
			"price": 19.95
		}
	}
}
JSON

$JSON::Path::Safe = 0;

foreach ('$.store.book[0].title', '$.store.book[*].author', '$..author', '$..book[-1:]',
	'$..book[?($_->{author} =~ /tolkien/i)]')
{
	my $jpath = JSON::Path->new($_);
	say $jpath;
	say to_json([$jpath->values($object)], {pretty=>1});
	say to_json([$jpath->paths($object)], {pretty=>1});
	say [$jpath->values($object)]->[0]->nodePath
		if blessed([$jpath->values($object)]->[0]);
	say '-' x 40;
}
