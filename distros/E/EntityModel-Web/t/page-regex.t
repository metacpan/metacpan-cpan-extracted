use strict;
use warnings;
use Test::More tests => 39;
use EntityModel;
use EntityModel::Web;
use EntityModel::Web::Context;
use URI;
use Test::Deep;

my $web = new_ok('EntityModel::Web');
my $model = new_ok('EntityModel');
ok($model->add_plugin($web), 'add plugin');
ok($model->load_from(
	Perl	=> {
 "name" => "mymodel",
 "web" => [
   { "host" => "something.com",
     "page" => [ {
       "name"		=> "Documentation",
       "path"		=> 'documentation/page(\d+)',
       "pathtype" 	=> "regex",
       "pathinfo"	=> [
        { "name" => "page_index" },
       ],
     }, {
       "name"		=> "Examples",
       "path"		=> 'examples/([^./]+)',
       "pathtype" 	=> "regex",
       "pathinfo"	=> [
        { "name" => "example_name" },
       ],
     }, {
         "name"		=> "SubExample",
	 "parent"	=> "Examples",
         "path"		=> '([^./]+)',
         "pathtype" 	=> "regex",
         "pathinfo"	=> [
          { "name" => "sub_example_name" },
         ],
     }, {
         "name"		=> "SubSubExample",
	 "parent"	=> "SubExample",
         "path"		=> '([^./]+)',
         "pathtype" 	=> "regex",
         "pathinfo"	=> [
          { "name" => "sub_sub_example_name" },
         ],
    } ]
  } ]
}), 'load model');

my @cases = (
	'/documentation/page1.html' => { name => 'Documentation', data => { page_index => 1 } },
	'/documentation/page2.html' => { name => 'Documentation', data => { page_index => 2 } },
	'/documentation/page11.html' => { name => 'Documentation', data => { page_index => 11 } },
	'/documentation/page23.html' => { name => 'Documentation', data => { page_index => 23 } },
	'/documentation/page230123.html' => { name => 'Documentation', data => { page_index => 230123 } },
	'/examples/first.html' => { name => 'Examples', data => { example_name => 'first' } },
	'/examples/another.one.html' => { name => 'Examples', data => { example_name => 'another' } },
	'/examples/another/one/two.html' => { name => 'SubSubExample', data => { example_name => 'another', sub_example_name => 'one', sub_sub_example_name => 'two' } },
);

# Try a semi-legitimate request
my $req = new_ok('EntityModel::Web::Request' => [
	method	=> 'get',
	path	=> '/',
	version	=> '1.1',
	header	=> [
		{ name => 'Host',	value => 'something.com' },
		{ name => 'User-Agent', value => 'EntityModel/0.1' },
	]
]);
CASE:
while(@cases) {
	my ($path, $c) = splice @cases, 0, 2;
	$req->path($path);
	my $ctx = new_ok('EntityModel::Web::Context' => [
		request	=> $req,
	]);
	ok($ctx->find_page_and_data($web), 'can find page') or next CASE;
	is($ctx->page->name, $c->{name}, 'page name is correct');
	foreach my $k (keys %{$c->{data}}) {
		is($ctx->data->get($k), $c->{data}->{$k}, 'regex capture for ' . $k . ' is correct');
	}
}

