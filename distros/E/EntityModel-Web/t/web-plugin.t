use strict;
use warnings;

use Test::More tests => 21;
use EntityModel;
use EntityModel::Web;
use URI;

my $web = new_ok('EntityModel::Web');
my $model = new_ok('EntityModel');
ok($model->add_plugin($web), 'add plugin');
ok($model->load_from(
	Perl	=> {
 "name" => "mymodel",
 "entity" => [ {
  "name" => "thing",
  "field" => [
   { "name" => "id", "type" => "int" },
   { "name" => "name", "type" => "varchar" }
  ] }, {
  "name" => "other",
  "field" => [
   { "name" => "id", "type" => "int" },
   { "name" => "extra", "type" => "varchar" }
  ] } ],
  "web" => [
   { "host" => "something.com",
     "layout" => [
       { "name" => "panel", template => "Panel.tt2" },
       { "name" => "main", template => "MainContent.tt2" },
     ],
     "page" => [ {
       "name"		=> "Index",
       "path"		=> "",
       "pathtype" 	=> "string",
       "title"		=> "Home page",
       "description" 	=> "The main index page",
       "handler" => [
        { "type"		=> "post", "method" => "something" },
       ],
       "pathinfo" => [
        { "item" => "" }
       ],
       "data" => [
        { "key" => "key1", "instance" => "", "method" => "" }
       ],
       "content" => [
        { "panel" => "", "template" => "" }
       ]
     }, {
       "name"		=> "Documentation",
       "path"		=> "documentation",
       "pathtype" 	=> "string",
       "title"		=> "Documentation list",
       "description" 	=> "Area for documentation",
       "content" => [
        { "section" => "main", "template" => "Documentation.tt2" }
       ]
     }, {
       "name"		=> "Tutorials",
       "parent"		=> "Documentation",
       "path"		=> "tutorials",
       "pathtype" 	=> "string",
       "title"		=> "Tutorials",
       "description" 	=> "Tutorial list",
       "content" => [
        { "section" => "main", "template" => "Tutorials.tt2" }
       ]
     }, {
       "name"		=> "FirstTutorial",
       "parent"		=> "Tutorials",
       "path"		=> "first",
       "pathtype" 	=> "string",
       "title"		=> "First tutorial entry",
       "description" 	=> "First tutorial",
       "content" => [
        { "section" => "main", "template" => "Tutorial1.tt2" }
       ]
     }, {
       "name"		=> "SecondTutorial",
       "parent"		=> "Tutorials",
       "path"		=> "second",
       "pathtype" 	=> "string",
       "title"		=> "Second tutorial entry",
       "description" 	=> "Second tutorial",
       "content" => [
        { "section" => "main", "template" => "Tutorial2.tt2" }
       ]
     }, {
       "name"		=> "RegexTest",
       "parent"		=> "Tutorials",
       "path"		=> 'number(\d+)',
       "pathtype" 	=> "regex",
       "title"		=> "random tutorial entry",
       "description" 	=> "Other entry",
       "content" => [
        { "section" => "main", "template" => "Tutorial2.tt2" }
       ]
     } ],
  } ]
}), 'load model');

# Get vhost from request
my $url = 'http://something.com/';
my $uri = URI->new($url);
ok(my $index = $web->page_from_uri($uri), 'look up page') or die 'no site found';
is($index->name, 'Index', 'name is correct');
is($index->title, 'Home page', 'title is correct');
is($index->description, 'The main index page', 'description is correct');
ok($index->handle_request(request => EntityModel::Web::Request->new), 'can handle request');

# Check a nested page entry with extension
ok(my $page = $web->page_from_uri(URI->new('http://something.com/documentation/tutorials.html')), 'look up page') or die 'no site found';
ok($page->handle_request(request => EntityModel::Web::Request->new), 'can handle request');

ok($page = $web->page_from_uri(URI->new('http://something.com/documentation/tutorials/number35.html')), 'look up page') or die 'no site found';

# Turn off logging for this since we don't need to know
#EntityModel::Log->instance->disabled(1);
ok(!$web->page_from_uri(URI->new('http://something.com/documentation/tutorials/numberx35.html')), 'check regex non-match');
#EntityModel::Log->instance->disabled(0);

ok($page->handle_request(request => EntityModel::Web::Request->new), 'can handle request');

# Try a semi-legitimate request
my $req = new_ok('EntityModel::Web::Request' => [
	method	=> 'get',
	path	=> '/documentation/tutorials.html',
	version	=> '1.1',
	header	=> [
		{ name => 'Host',	value => 'something.com' },
		{ name => 'User-Agent', value => 'EntityModel/0.1' },
	]
]);
is($req->method, 'get', 'method is correct');
is($req->path, '/documentation/tutorials.html', 'path is correct');
is($req->version, 1.1, 'version is correct');
is($req->hostname, 'something.com', 'host is correct');
is($req->uri->as_string, 'http://something.com/documentation/tutorials.html', 'URI is correct');
is($req->header_by_name->get('User-Agent')->value, 'EntityModel/0.1', 'UserAgent is correct');

