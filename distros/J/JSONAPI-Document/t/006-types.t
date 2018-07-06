#! perl -w

use lib 't/lib';

use Test::Most;
use Test::JSONAPI;
use JSONAPI::Document::Builder;

my $t = Test::JSONAPI->new({ api_url => 'http://example.com/api' });
$t->schema;

my $builder = JSONAPI::Document::Builder->new(
	chi => $t->chi,
	kebab_case_attrs => 1,
	row => $t->schema->resultset('Post')->find(1),
	segmenter => $t->segmenter,
);

is($builder->document_type('someweird_thing'), 'some-weird-things');
is($builder->document_type('gdk_burger'), 'gdk-burgers');
is($builder->document_type('gdk_burgers'), 'gdk-burgers');

done_testing;
