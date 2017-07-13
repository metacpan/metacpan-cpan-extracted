use 5.010;
use JSON::MaybeXS;
use Scalar::Util qw[blessed];
use lib "../lib";
use JSON::Path;

my $json = JSON::MaybeXS->new( pretty => 1 );
my $object = $json->decode(<<'JSON');
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
	say $json->encode([$jpath->values($object)]);
	say $json->encode([$jpath->paths($object)]);
	say [$jpath->values($object)]->[0]->nodePath
		if blessed([$jpath->values($object)]->[0]);
	say '-' x 40;
}
