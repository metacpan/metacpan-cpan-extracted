use lib "lib";
use lib "t/lib";

use Test::More;
use JSON::GRDDL;
use LWP::UserAgent;
use RDF::Trine;

eval { require Test::HTTP::Server; 1; }
	or plan skip_all => "Could not use Test::HTTP::Server: $@";

plan tests => 11;

my $server  = Test::HTTP::Server->new();
my $baseuri = $server->uri;
sub baseuri { $baseuri }

sub Test::HTTP::Server::Request::j_data_1 {my$baseuri=::baseuri();$_[0]->{out_headers}{content_type}='application/json' and <<"DATA"}
{
	"\$transformation" : "${baseuri}j_transformation#Person" ,
	"name" : "Joe Bloggs" ,
	"mbox" : "joe\@example.net" 
}
DATA

sub Test::HTTP::Server::Request::j_data_2 {my$baseuri=::baseuri();$_[0]->{out_headers}{content_type}='application/json' and <<"DATA"}
{
	"\$schema" : { "\$ref\" : "${baseuri}j_schema" } ,
	"name" : "Joe Bloggs" ,
	"mbox" : "joe\@example.net" 
}
DATA

sub Test::HTTP::Server::Request::j_data_3 {my$baseuri=::baseuri();$_[0]->{out_headers}{content_type}='application/json' and <<"DATA"}
[
	{
		"\$schema" : { "\$ref\" : "${baseuri}j_schema" } ,
		"name" : "Alice" ,
		"mbox" : "alice\@example.net" 
	},
	{
		"\$schema" : { "\$ref\" : "${baseuri}j_schema" } ,
		"name" : "Bob" ,
		"mbox" : "bob\@example.net" 
	}
]
DATA

sub Test::HTTP::Server::Request::j_schema {my$baseuri=::baseuri();$_[0]->{out_headers}{content_type}='application/schema+json' and <<"DATA"}
{
	"type" : "object" ,
	"\$schemaTransformation" : "${baseuri}j_transformation#Person"
}
DATA

sub Test::HTTP::Server::Request::j_transformation {my$baseuri=::baseuri();$_[0]->{out_headers}{content_type}='application/ecmascript' and <<"DATA"}
var People =
{
	"self" : function(x)
	{
		var rv = {};
		for (var i=0; x[i]; i++)
		{
			var person = JSON.parse(Person.self(x[i]));
			rv["_:Contact" + i] = person["_:Contact"];
		}
		return JSON.stringify(rv, 0, 2);
	}
};

var Person =
{
	"self" : function(x)
	{
		var rv =
		{
			"_:Contact" :
			{
				"http://www.w3.org/1999/02/22-rdf-syntax-ns#type" :
				[{
					"type" : "uri" ,
					"value" : "http://xmlns.com/foaf/0.1/Person"
				}],
				"http://xmlns.com/foaf/0.1/name" :
				[{
					"type" : "literal" ,
					"value" : x.name
				}],
				"http://xmlns.com/foaf/0.1/mbox" :
				[{
					"type" : "uri" ,
					"value" : "mailto:" + x.mbox
				}]
			}
		};
		return JSON.stringify(rv, 0, 2);
	}
};
DATA

diag "Running HTTP server at: $baseuri";

foreach (1..2)
{
	my $uri   = "${baseuri}j_data_${_}";
	my $cnt   = LWP::UserAgent->new->get($uri)->decoded_content;
	
	diag "JSON::GRDDL on $uri";
	my $model = JSON::GRDDL->new->data($cnt, $uri);
	
	isa_ok($model, 'RDF::Trine::Model');
	
	is($model->size, 3, 'Model has correct size');
	
	my ($s) = $model->subjects(
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/Person'),
		);

	my ($name) = map { $_->literal_value } $model->objects(
		$s,
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
		);

	is($name, 'Joe Bloggs', 'Correct name');

	my ($mbox) = map { $_->uri } $model->objects(
		$s,
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/mbox'),
		);

	is($mbox, 'mailto:joe@example.net', 'Correct mbox');
}

my $uri   = "${baseuri}j_data_3";
my $cnt   = LWP::UserAgent->new->get($uri)->decoded_content;

diag "JSON::GRDDL on $uri";
my $model = JSON::GRDDL->new->data($cnt, $uri);

isa_ok($model, 'RDF::Trine::Model');

is($model->size, 6, 'Model has correct size');

my ($s1) = map { "$_" } $model->subjects(
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/mbox'),
		RDF::Trine::Node::Resource->new('mailto:alice@example.net'),
		);

my ($s2) = map { "$_" } $model->subjects(
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/mbox'),
		RDF::Trine::Node::Resource->new('mailto:bob@example.net'),
		);

isnt($s1, $s2, "Two distinct subjects");