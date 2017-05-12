#!/usr/bin/perl

use strict;
use Test;
#use Data::Dumper;

BEGIN { plan tests => 20 };


use HTML::Template::Pro::Extension;
use HTML::Template::Pro::Extension::ObjBase;

my $comp = new HTML::Template::Pro::Extension(
												tmplfile => 't/templates/standard.tmpl',
											);

ok($comp);

$comp->param('test' => "It works!!!");
$_ = $comp->output;
ok($_,qr/It works/);

$comp = new HTML::Template::Pro::Extension(
												tmplfile => 't/templates/standard.tmpl',
												plugins => ['DO_NOTHING'],
											);

ok($comp);

$comp->param('test' => "It works!!!");
$_ = $comp->output;
ok(/It works/);


## Standard HTML::Template use with support for <TMPL_VAR>..</TMPL_VAR>
$comp->plugin_add("SLASH_VAR");
$comp->tmplfile('t/templates/simple.tmpl');
$comp->param('test' => "It works!!!");
$_ = $comp->output;
ok(/It works/ && $_ !~ /placeholder/);


# Advanced output method use
$_ = $comp->output(as => {'test' => "It works!!!"});

ok(/It works/ && $_ !~ /placeholder/);

# check vanguard mode
$_ = $comp->html({'test' => "It works!!!"},'t/templates/simple_vanguard.tmpl');
ok(/It works/);



# html method use and replacing tmplfilename
$_ = $comp->html({'test' => "It works!!!"},'t/templates/simple_html.tmpl');

ok(m/It works/ && !m/placeholder/ && m/\<HTML\>/);


# ...again to check caching
$_ = $comp->html({'test' => "It works!!!"},'t/templates/simple_html.tmpl');

ok(m/It works/ && !m/placeholder/ && m/\<HTML\>/);


# ...check autoDeleteHeader
$comp->plugin_add("HEAD_BODY");
$comp->autoDeleteHeader(1);
$_ = $comp->html({'test' => "It works!!!"},'t/templates/simple_html.tmpl');
#print $comp->header;

ok (m/It works/ && !m/placeholder/ && !m/\<HTML\>/ && $comp->header=~m/\<HTML\>/) ;


# check js_header
$comp->autoDeleteHeader(1);
$_ = $comp->html({'test' => "It works!!!"},'t/templates/html_js.tmpl');
ok (m/It works!!!/);
#print;
$_ = $comp->header_js;
#print;
ok (m/doNothing/);

# check header_css
$comp->autoDeleteHeader(1);
$_ = $comp->html({'test' => "It works!!!"},'t/templates/html_js.tmpl');
$_ = $comp->header_css;
#print;

ok (m/\.body/);
#check header_tokens
$comp->autoDeleteHeader(1);
$_ = $comp->html({'test' => "It works!!!"},'t/templates/html_js.tmpl');
$_ = $comp->header_tokens->{meta};
#print Data::Dumper::Dumper($_);
$_ = $_->[1]->[0];
##print ;
ok (m/windows\-1252/);

# check support for TMPL_DOC tag
$comp->autoDeleteHeader(0);
$comp->plugin_add("DOC");
$_ = $comp->html({'test' => "It works!!!"},'t/templates/html_doc.tmpl');

ok(!m/comment/);

# check support for TMPL_CSTART tag
$comp->plugin_add("CSTART");
$_ = $comp->html({'test' => "It works!!!"},'t/templates/html_cstart.tmpl');

ok (!m/BAD/);


# check support for IF_TERN plug-in
$comp->plugins_clear;
$comp->plugin_add("IF_TERN");
$_ = $comp->html({'test' => 1},'t/templates/if_tern.tmpl');
#print;


# check ObjBase

my $base = new HTML::Template::Pro::Extension::ObjBase;

$comp->plugin_add($base);

$_ = $comp->html({'test' => 1},'t/templates/if_tern.tmpl');

#print;

ok(!m/BAD/);

# try to remove IF_TERN plug-in

$comp->plugin_remove('IF_TERN');
$_ = $comp->html({'test' => 1},'t/templates/if_tern.tmpl');
#print;
ok(m/BAD/);

# check support for TAG_ATTRIBUTE_NORMALIZER plug-in
$comp->plugins_clear;
$comp->plugin_add("SLASH_VAR");
$comp->plugin_add("TAG_ATTRIBUTE_NORMALIZER");
$_ = $comp->html({'test' => 'It works!!!'},'t/templates/tag_normalizer.tmpl');
#print;

ok (m/It works/);

# check EXPR support mixing with plugin

$comp->plugins_clear;
$comp->plugin_add("SLASH_VAR");
$_ = $comp->html({'test' => 'ok',number => 5},'t/templates/simple_expr.tmpl');
#print;
ok(m/-->\sok/ && m/result:\s25/);

1;

# vim: set ts=2 filetype=perl:
