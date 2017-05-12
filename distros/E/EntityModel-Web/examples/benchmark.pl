#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Benchmark ':hireswallclock';

use EntityModel;
use EntityModel::Web;

my $web = EntityModel::Web->new;
my $model = EntityModel->new;
$model->add_plugin($web);
$model->load_from(
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
       ],
       "content" => [
        { "section" => "main", "template" => "Main" },
        { "section" => "panel", "template" => "WithData" },
       ]
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
        { "key" => "key2", "value" => "other_data" },
       ],
       "content" => [
        { "section" => "main", "template" => "Main" },
        { "section" => "panel", "template" => "WithData" },
       ]
    } ]
  } ]
});

my $tmpl = EntityModel::Template->new;
$tmpl->process_template(\q{[% BLOCK Main -%]
Main block.
[% END # Main
-%]});
$tmpl->process_template(\q{[% BLOCK WithData -%]
[% FOREACH k IN data.keys.sort -%]
[% k %] = [% data.item(k) %]
[% END -%]
[% END # Main
-%]});
timethese(1000, {
	'regex'	=> sub {
		my $req = EntityModel::Web::Request->new(
			method	=> 'get',
			path	=> '/',
			version	=> '1.1',
			header	=> [
				{ name => 'Host',	value => 'something.com' },
				{ name => 'User-Agent', value => 'EntityModel/0.1' },
			]
		);
		$req->path('/entry/first/something.html');
		my $ctx = EntityModel::Web::Context->new(
			request	=> $req,
			template => $tmpl,
		);
		$ctx->find_page_and_data($web);
		$ctx->resolve_data;
		$ctx->process;
	},
	'string'	=> sub {
		my $req = EntityModel::Web::Request->new(
			method	=> 'get',
			path	=> '/',
			version	=> '1.1',
			header	=> [
				{ name => 'Host',	value => 'something.com' },
				{ name => 'User-Agent', value => 'EntityModel/0.1' },
			]
		);
		$req->path('/');
		my $ctx = EntityModel::Web::Context->new(
			request	=> $req,
			template => $tmpl,
		);
		$ctx->find_page_and_data($web);
		$ctx->resolve_data;
		$ctx->process;
	}
});
