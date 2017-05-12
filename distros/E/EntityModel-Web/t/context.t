use strict;
use warnings;
package EntityModel::Web::ContextTest;
use Test::More;
use Test::Deep;

sub new { bless {}, shift }

sub test_method {
	my $class = shift;
	ok(!ref $class, 'class is not a ref');
	is($class, __PACKAGE__, 'class matches package');
	return $class->new;
}

sub second_test {
	my $self = shift;
	isa_ok($self, __PACKAGE__);
	my %args = @_;
	is(keys(%args), 2, 'have 2 args');
	cmp_deeply(\%args, {
		param1 => 'some_data',
		param2 => 42
	}, 'args match');
	return { 'second test' => 'ok' };
}

sub third_test { 42 }

package main;
use Test::More tests => 29;
use EntityModel;
use EntityModel::Web;
use EntityModel::Web::Context;
use EntityModel::Template;
use URI;
use Test::Deep;

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
     "template" => "PageTemplate",
     "layout" => [
       { "section" => "panel", wrapper => "Panel.tt2" },
       { "section" => "main",  wrapper => "MainContent.tt2" },
     ],
     "page" => [ {
       "name"		=> "Index",
       "path"		=> "",
       "pathtype" 	=> "string",
       "title"		=> "Home page",
       "description" 	=> "The main index page",
       "data" => [
        { "key" => "key1", "value" => "some_data" },
        { "key" => "key2", "value" => "other_data" },
        { "key" => "key3", "class" => "EntityModel::Web::ContextTest", "method" => "test_method" },
	{ "key" => "key4", "instance" => "key3", "method" => "second_test", "parameter" => [
	  { "value" => "param1" },
	  { "data" => "key1" },
	  { "value" => "param2" },
	  { "class" => "EntityModel::Web::ContextTest", "method" => "third_test" },
	] },
       ],
    }, {
       "name"		=> "Regexed",
       "path"		=> "entry/([^/]+)/([^.]+)",
       "pathtype" 	=> "regex",
       "pathinfo"	=> [
        { "name" => "entry_name" },
        { "name" => "entry_page" },
       ],
       "title"		=> "Some regex page match",
       "data" => [
        { "key" => "key1", "value" => "some_data" },
       ],
       "content" => [
        { "section" => "main", "template" => "Main" },
        { "section" => "panel", "template" => "WithData" },
       ]
    } ]
  } ]
}), 'load model');

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
my $ctx = new_ok('EntityModel::Web::Context' => [
	request	=> $req,
]);
ok($ctx->find_page_and_data($web), 'can find page');
is($ctx->page->name, 'Index', 'page name is correct');
ok($ctx->resolve_data, 'can resolve data');
is($ctx->data->get('key1'), 'some_data', 'static value is correct');
is($ctx->data->get('key2'), 'other_data', 'static value is correct');
isa_ok($ctx->data->get('key3'), 'EntityModel::Web::ContextTest');
cmp_deeply($ctx->data->get('key4'), {
	'second test' => 'ok'
}, 'args match');

$req->path('/entry/first/something.html');
$ctx = new_ok('EntityModel::Web::Context' => [
	request	=> $req,
]);
ok($ctx->find_page_and_data($web), 'can find page');
is($ctx->page->name, 'Regexed', 'page name is correct');
is($ctx->data->get('entry_name'), 'first', 'first regex capture is correct');
is($ctx->data->get('entry_page'), 'something', 'second regex capture is correct');
ok($ctx->resolve_data, 'can resolve data');
ok($ctx->site, 'have site');
is($ctx->site->layout->count, 2, 'two entries in layout');

$ctx->template->process_template(\q{[% BLOCK PageTemplate -%]
Page [% page.name %]:
== Main:
[% section.main -%]
== Panel:
[% section.panel -%]
[% END # PageTemplate
-%]
});
$ctx->template->process_template(\q{[% BLOCK Main -%]
Main block.
[% END # Main
-%]
});
$ctx->template->process_template(\q{[% BLOCK WithData -%]
[% FOREACH k IN data.keys.sort -%]
[% k %] = [% data.item(k) %]
[% END -%]
[% END # Main
-%]
});

is(EntityModel::Class::trim($ctx->section_content('main')), 'Main block.', 'main section content is correct');
is(EntityModel::Class::trim($ctx->section_content('panel')), "entry_name = first\nentry_page = something\nkey1 = some_data", 'second section content is correct');
is($ctx->process, q{Page Regexed:
== Main:
Main block.
== Panel:
entry_name = first
entry_page = something
key1 = some_data
}, 'full generated page is correct');

