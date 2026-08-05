use strict; use warnings;
use Test::More;
use Time::HiRes qw(time);
use JSON::Schema;
use JSON::Schema::Fast;
use JSON::Schema::Modern;
use File::Raw::JSON;
use Benchmark qw/timethese cmpthese/;

my $schema = {
    type       => 'object',
    required   => [ 'name', 'age' ],
    properties => {
        name  => { type => 'string', minLength => 1 },
        age   => { type => 'integer', minimum => 0 },
        email => { type => 'string' },
        tags  => { type => 'array', items => { type => 'string' } },
        addr  => { type => 'object', properties => { city => { type => 'string' } } },
    },
};
my $doc = File::Raw::JSON::file_json_decode(
    '{"name":"Ada","age":36,"email":"a@b.c","tags":["x","y","z"],"addr":{"city":"London"}}');

my $fast = JSON::Schema::Fast->compile($schema);
my $m = JSON::Schema::Modern->new(specification_version => 'draft2020-12');
$m->add_schema('https://bench/s', $schema);
my $s = JSON::Schema->new($schema);
my $cmp = timethese(-5, {
	'JSON::Schema::Fast' => sub {
		JSON::Schema::Fast::validate($fast, $doc);
	},
	'JSON::Schema::Modern' => sub {
		my $okay = $m->evaluate($doc, 'https://bench/s');
	},
	'JSON::Schema' => sub {
		$s->validate($doc);
	}
});

cmpthese $cmp;

done_testing;
