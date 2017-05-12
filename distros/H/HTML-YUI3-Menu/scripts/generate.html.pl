#!/usr/bin/env perl

use strict;
use warnings;

use DBI;

use HTML::YUI3::Menu;
use HTML::YUI3::Menu::Util::Config;

use Tree::DAG_Node::Persist;

use Text::Xslate 'mark_raw';

# ------------------------------------------------

sub build_switch_functions
{
	return <<EOS;
function database()
{
	alert('Intercepted /Database');
}
function update_version_number()
{
	alert('Intercepted /UpdateVersionNumber');
}
EOS

} # End of build_switch_functions.

# ------------------------------------------------

my($dbh)    = DBI -> connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS});
my($driver) = Tree::DAG_Node::Persist -> new
(
 context    => 'HTML::YUI3::Menu',
 dbh        => $dbh,
 table_name => 'items',
);

my($tree)   = $driver -> read(['url']);
my($config) = HTML::YUI3::Menu::Util::Config -> new -> config;
my($yui)    = HTML::YUI3::Menu -> new
	(
	 horizontal    => 1,
	 menu_buttons  => 0,
	 split_buttons => 0,
	 switch_js     => 1,
	 template_path => $$config{template_path},
	 tree          => $tree,
	);

$yui -> menu_buttons(0);
$yui -> split_buttons(1);
$yui -> run;

my($templater) = Text::Xslate -> new
	(
	 input_layer => '',
	 path        => $$config{template_path},
	);

print $templater -> render
	(
	 'web.page.tx',
	 {
		 menu             => mark_raw($yui -> menu),
		 switch_functions => mark_raw(build_switch_functions() ),
		 yui_js           => mark_raw($yui -> js),
		 yui_url          => $$config{yui_url},
	 }
	);
