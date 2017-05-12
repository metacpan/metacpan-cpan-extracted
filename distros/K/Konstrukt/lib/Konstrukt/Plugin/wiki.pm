#TODO: see TODO in the source (of the other modules)
#TODO: templates for internal image links, article links and file links must not
#      use <nowiki>-tags.
#      -	image: template is put out in the execute run, so no separate_nowiki will be run after that
#      - article/file: template is nested inside template tag. separate_nowiki doesn't recurse and will not be recognized
#TODO: post-plugin-cleanup only prepares template-plugins and no other plugin nodes
#      possibly returned by the markup plugin
#FEATURE: section overview (derived from the headlines) at the beginning of the page
#FEATURE: Wiki-Syntax in {file, article, image} descriptions?
#FEATURE: enable sandbox editing for every user
#FEATURE: option to allow wiki-editing without usermanagement
#FEATURE: export other formats than HTML?
#FEATURE: offer metadata for each article (dublin core)?

=head1 NAME

Konstrukt::Plugin::wiki - Plugin to convert wiki markup and manage wiki content

=head1 SYNOPSIS
	
	<& wiki &>
	= Headline
	
	some text
	<& / &>
	
	<& wiki page="FooBar" / &>

=head1 DESCRIPTION

This plugin will render given wiki markup into an other format (e.g. HTML).

The markup may come from several sources, which are checked in this order:

=over

=item * Content between C<<& wiki &>> and C<<& / &>>

=item * Page passed through C<?wiki_page=somepage> cgi parameter

=item * Page specified in the tag attribute: C<<& wiki page="somepage" / &>>

=item * Default page set in wiki/default_page

=back

=head2 Markup Plugins

The markup will be handled by the markup plugins. An overview of the syntax can
be found at L<Konstrukt::Plugin::wiki::syntax>. Below are links to the detailed
documentation of each markup plugin.

=head3 Block Markup:

All these plugins are derived from the same base class
(L<Konstrukt::Plugin::wiki::blockplugin>).

=over

=item * L<Konstrukt::Plugin::wiki::markup::definition>

=item * L<Konstrukt::Plugin::wiki::markup::headline>

=item * L<Konstrukt::Plugin::wiki::markup::hr>

=item * L<Konstrukt::Plugin::wiki::markup::list>

=item * L<Konstrukt::Plugin::wiki::markup::paragraph>

=item * L<Konstrukt::Plugin::wiki::markup::pre>

=item * L<Konstrukt::Plugin::wiki::markup::quote>

=back

=head3 Inline Markup:

All these plugins are derived from the same base class
(L<Konstrukt::Plugin::wiki::inlineplugin>).

=over

=item * L<Konstrukt::Plugin::wiki::markup::acronym>

=item * L<Konstrukt::Plugin::wiki::markup::basic>

=item * L<Konstrukt::Plugin::wiki::markup::htmlescape>

=item * L<Konstrukt::Plugin::wiki::markup::link>

=item * L<Konstrukt::Plugin::wiki::markup::replace>

=back

=head2 Backend Plugins

The data will be stored and accessed through various backend plugins. Take
a look at their documentation for more information about them (e.g. configuration).

All backend plugins are derived from the base class L<Konstrukt::Plugin::wiki::backend>,
which explains what requirements must be fulfilled to build an own backend plugin.

=head3 Articles:

Will handle any wiki articles.

The article backends implement the L<Konstrukt::Plugin::wiki::backend::article>
interface.

=over

=item * L<Konstrukt::Plugin::wiki::backend::article::DBI>

=back

=head3 Images:

Will handle all images (JPEG, PNG, GIF, ...).

The image backends implement the L<Konstrukt::Plugin::wiki::backend::image>
interface.

=over

=item * L<Konstrukt::Plugin::wiki::backend::image::DBI>

=back

=head3 Files:

Will handle all other files.

The file backends implement the L<Konstrukt::Plugin::wiki::backend::file>
interface.

=over

=item * L<Konstrukt::Plugin::wiki::backend::file::DBI>

=back

=head2 Note on page titles

You might want to use something like

	<title><& param key="wiki_page" &><+$ title $+>(default title)<+$ / $+><& / &></title>
	
in your page layout template to get the title of the wiki pages as your page
title. If no wiki_page-param is defined it will default to the title-template
value (this may of course vary in your template) supplied for page.
If even no title-template value has been specified, the title will default
to C<(default title)>.  

=head1 CONFIGURATION

You may (but usually don't want to) configure the processing order of the markup plugins:

	#defaults
	wiki/block_plugins pre quote headline hr list definition paragraph
	wiki/inline_plugins link acronym basic replace htmlescape

Note that the block plugins will be executed one after another for each block until
one plugin returns a true value, which indicates, that this block plugin
handles the passed block. No other block plugin will then handle the block.

The inline plugins will always be executed first to last on the whole text.

You may define more specific configuration for each markup plugin. Take a look
at the documentation of those.

To define which backends you want to use, use the following setting. There are
several backends (article, image, file, ...), which may be implemented in
several types (DBI, file, ...). Each backend has to define, for which action
(passed with the C<action> CGI parameter) it is responsible. Take a look
at the C<Konstrukt::Plugin::wiki::backend::*>-modules. The default backends which
are queried for their action responsibilities are:

	wiki/backends article file image

You also may specify the backend type to use. Currently only 'DBI' is available,
which is also the default:

	wiki/backend_type DBI
	
The page, which will be used to display the wiki article, may also be specified.
This file is just a plain html file (with konstrukt tags) that must contain a
wiki tag:

	<& wiki / &>

This tag will then be replaced by the wiki page that should be displayed.
The default path to this file is:

	wiki/base /wiki.html

If no page, that should be displayed, is specified, a default page will be used:

	wiki/default_page index

You may also specify the user level, that is required to to write/edit wiki
articles. Default:

	#every registered user may edit/write articles
	wiki/userlevel_write 0

Rendered wiki articles get cached to speed up the display. To prevent a collision
between other file names and the names of wiki pages in the cache, you can specify
a pseudo directory which will be prefixed to the cache names of the wiki pages.
Default:

	wiki/cache_prefix wiki_article_cache/

This plugin uses templates to display forms and messages. The path to these
templates can be customized (and should end with a slash). Default:

	wiki/template_path /templates/wiki/

If you use the image- and file-plugin you must create a file, which returns the
content of the file, for each plugin. Actually you can choose any filename you
like (e.g. /wiki/file/index.html and /wiki/image/index.html) as it will be
referenced in the file and image info template (usually
/templates/wiki/layout/file_info.template and image_info.template).
These files must B<only> consist of:

	<& wiki::backend::image / &>
	
Respectively

	<& wiki::backend::file / &>
	
and B<no> other characters (no newlines, no whitespaces)!

The image backend automatically generates resized versions of the images if a
specified width is requested. You may specify the quality (0-100, 100 = best)
of the compressed (jpeg, mng, png) image. Default:

	wiki/image_quality 75

For further configuration of some submodules take a look at

=over

=item * L<Konstrukt::Plugin::wiki::markup::link/CONFIGURATION>

=item * L<Konstrukt::Plugin::wiki::markup::replace/CONFIGURATION>

=back

For further configuration of the backend modules take a look at the
documentation of those.

=cut

package Konstrukt::Plugin::wiki;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use Konstrukt::Parser::Node;

=head1 METHODS

=head2 init

Initialization. Will only be used internally.

=cut
sub init {
	my ($self) = @_;

	#set default settings
	$Konstrukt::Settings->default("wiki/block_plugins"   => 'pre quote headline hr list definition paragraph');
	$Konstrukt::Settings->default("wiki/inline_plugins"  => 'link acronym basic replace htmlescape');
	$Konstrukt::Settings->default("wiki/backends"        => 'article file image');
	$Konstrukt::Settings->default("wiki/backend_type"    => 'DBI');
	$Konstrukt::Settings->default("wiki/base"            => '/wiki.html');
	$Konstrukt::Settings->default("wiki/default_page"    => 'index');
	$Konstrukt::Settings->default("wiki/userlevel_write" => 0);
	$Konstrukt::Settings->default("wiki/cache_prefix"    => '/wiki_article_cache/');
	$Konstrukt::Settings->default("wiki/template_path"   => '/templates/wiki/');
	$Konstrukt::Settings->default("wiki/image_quality"   => 75);
	
	#load all backends and check which actions they handle
	my $backend_type = $Konstrukt::Settings->get("wiki/backend_type");
	$self->{backend_actions} = {};
	foreach my $backend (split /\s+/, $Konstrukt::Settings->get("wiki/backends")) {
		my $plugin = use_plugin "wiki::backend::${backend}::$backend_type";
		if (defined $plugin) {
			foreach my $action ($plugin->actions()) {
				$self->{backend_actions}->{$action} = $plugin;
			}
		} else {
			$Konstrukt::Debug->error_message("Couldn't load backend ${backend}::$backend_type!") if Konstrukt::Debug::ERROR;
			return undef;
		}
	}
	
	return 1;
}
#= /init

=head2 install

Installs the stylesheet.

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_file_install_helper($self->{template_path});
}
# /install

=head2 prepare_again

Yes, this plugin may generate new tag nodes in the prepare run.

=cut
sub prepare_again {
	return 1;
}
#= /prepare_again

=head2 execute_again

Yes, this plugin may generate new tag nodes in the execute run.

=cut
sub execute_again {
	return 1;
}
#= /execute_again

=head2 prepare

This plugin will process static content in the prepare-run.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	#only prepare content that will not change over several requests.
	#this is only then the case, when the markup is passed as plaintext child nodes.
	if (defined $tag->{first_child} and not $tag->{dynamic}) {
		$self->convert_markup($tag);
		#return the passed result. replace this tag by the converted child nodes
		return $tag;
	} else {
		#process this one in the execute run.
		$tag->{dynamic} = 1;
		return undef;
	}
}
#= /prepare

=head2 execute

Finally process the wiki content

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;

	#reset the collected nodes
	$self->reset_nodes();
	
	#what should be done?
	my $action = $Konstrukt::CGI->param('action') || 'article_show';
	
	#delegate action to the apropriate backend plugin
	if (exists $self->{backend_actions}->{$action}) {
		my $plugin = $self->{backend_actions}->{$action};
		eval "\$plugin->{collector_node} = \$self->{collector_node}; \$plugin->$action(\$tag)";
		#Check for errors
		if (Konstrukt::Debug::ERROR and $@) {
			#Errors in eval
			chomp($@);
			$Konstrukt::Debug->error_message("Error while executing action '$action'!\n$@");
		}
	} else {
		$Konstrukt::Debug->error_message("No plugin will handle the action '$action'!") if Konstrukt::Debug::WARNING;
	}
	
	return $self->get_nodes();
}
#= /execute

=head2 convert_markup

Will convert the wiki markups in the child nodes of a given node into another
markup (usually HTML).

The input child nodes will be replaced by the converted markup.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub convert_markup {
	my ($self, $tag) = @_;

	$self->separate_nowiki($tag);
	$self->split_into_blocks($tag);
	
	#pass the blocks through the block-plugins, which might identify
	#a wiki block (e.g. code, list, ...) and process it.
	#put all child nodes of the blocks back directly under the wiki-tag-node.
	my @block_plugins = map { use_plugin "wiki::markup::$_" } split /\s+/, $Konstrukt::Settings->get('wiki/block_plugins');
	my $block = $tag->{first_child};
	while (defined $block) {
		#pass the block to each plugin until one plugin processes this block
		foreach my $plugin (@block_plugins) {
			if ($plugin->process($block)) {
				#postprocess output
				$self->postprocess_output($block);
				last;
			}
		}
		#replace the block by its children
		my $next_block = $block->{next};
		$block->replace_by_children();
		$block = $next_block;
	}
	
	#process all inline markup (e.g. *bold*).
	#pass all nodes through each inline-plugin.
	my @inline_plugins = map { use_plugin "wiki::markup::$_" } split /\s+/, $Konstrukt::Settings->get('wiki/inline_plugins');
	foreach my $plugin (@inline_plugins) {
		#pipe the whole document through the plugin
		$plugin->process($tag);
		$self->postprocess_output($tag);
	}
	
	#warn $tag->children_to_string();
	#return $tag;

	#clean up: mark all text nodes as finally processed
	my $node = $tag->{first_child};
	while (defined $node) {
		$node->{wiki_final} = 1 if $node->{type} eq 'plaintext';
		$node = $node->{next};
	}
	
	return $tag;
}
#= /convert_markup

=head2 convert_markup_string

Will convert a string containing wiki markup into another markup (usually HTML).

Returns a containter node, that in turn contains nodes with the converted markup.

B<Parameters>:

=over

=item * $markup - The string containing the markup to convert.

=back

=cut
sub convert_markup_string {
	my ($self, $markup) = @_;
	
	#put markup into a field container
	my $cont = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '$' });
	$cont->add_child(Konstrukt::Parser::Node->new({ type => 'plaintext', content => $markup }));
	return $self->convert_markup($cont);
}
#= /convert_markup_string

=head2 postprocess_output

Will run L</prepare_templates>, L</separate_nowiki> and L</merge_similar_neighbours>
on the passed node.

B<Parameters>:

=over

=item * $node - Node with children to process

=back

=cut
sub postprocess_output {
	my ($self, $node) = @_;
	
	#"execute" (actually prepare) template nodes to
	#get their plaintext output so it can be parsed by further wiki-markup plugins.
	$self->prepare_templates($node, { '&' => $Konstrukt::TagHandler::Plugin });
	#also parse for new <nowiki>-areas returned by the plugin and join similar nodes.
	$self->separate_nowiki($node);
	$self->merge_similar_neighbours($node);
}
#= /postprocess_output

=head2 prepare_templates

This sub takes a node with some child nodes an recursively prepares all template
nodes.

B<Parameters>:

=over

=item * $node - Node with children to process

=back

=cut
sub prepare_templates {
	my ($self, $tag, $actions) = @_;
	
	#recersively iterate over all children and execute the tags
	my $node = $tag->{first_child};
	while (defined $node) {
		#save next node as the current $node may be deleted by prepare_tag
		my $next_node = $node->{next};
		#recursively prepare template nodes
		if ($node->{type} eq 'tag') {
			$self->prepare_templates($node, $actions);
			if (defined $node->{handler_type} and $node->{handler_type} eq '&' and defined $node->{tag}->{type} and $node->{tag}->{type} eq 'template') {
				#all children processed. prepare this node
				$Konstrukt::Parser->prepare_tag($node, $actions);
			}
		}
		$node = $next_node;
	}
}
#= /prepare_templates

=head2 separate_nowiki

Find <nowiki>...</nowiki>-areas and create separate nodes for them,
that will not be processed.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub separate_nowiki {
	my ($self, $tag) = @_;
	
	#look for <nowiki> and mark all following nodes as finished until </nowiki> is found.
	my $nowiki = 0;
	my $node = $tag->{first_child};
	while (defined $node) {
		if (not $node->{wiki_finished} and $node->{type} eq 'plaintext' and $node->{content} =~ /<\/?nowiki>/si) {
			my @tokens = split /(<\/?nowiki>)/i, $node->{content};
			foreach my $token (@tokens) {
				if (lc($token) eq '<nowiki>') {
					$nowiki++;
				} elsif (lc($token) eq '</nowiki>') {
					$nowiki--;
				} else {
					$node->add_child(Konstrukt::Parser::Node->new({ type => 'plaintext', content => $token, ($nowiki > 0 ? (wiki_finished => 1) : ()) })) if defined $token;
				}
			}
			my $next_node = $node->{next};
			$node->replace_by_children();
			$node = $next_node;
		} else {
			$node->{wiki_finished} = 1 if $nowiki > 0;
			$node = $node->{next};
		}
	}
}
# /separate_nowiki

=head2 split_into_blocks

Walk over the tree and separate it into blocks (which are separated by
at least one empty line).

Each block will be moved under a "block node".

The passed tagnode will only have block nodes below it after this step.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub split_into_blocks {
	my ($self, $tag) = @_;
	
	#are there any nodes?
	if (defined $tag->{first_child}) {
		#prepare first and last node as they may have leading/trailing newlines
		#that won't be handled properly by the splitting regexp
		$tag->{first_child}->{content} =~ s/^(\r?\n|\r)+//s if not $tag->{first_child}->{wiki_finished} and $tag->{first_child}->{type} eq 'plaintext';
		$tag->{last_child}->{content}  =~ s/(\r?\n|\r)+$//s if not $tag->{last_child}->{wiki_finished}  and $tag->{last_child}->{type}  eq 'plaintext';
		
		#node which holds all blocks
		my $container = Konstrukt::Parser::Node->new({ type => 'wikiblockcontainer' });
		
		#initial block
		my $current_block = Konstrukt::Parser::Node->new({ type => 'wikiblock' });
		$container->add_child($current_block);
		
		my $node = $tag->{first_child};
		while (defined $node) {
			#save next node since $node->{next} might get overwritten
			#when moving this node around in the tree
			my $next_node = $node->{next};
			#at least one empty line?
			if ($node->{type} eq 'plaintext' and $node->{content} =~ /(\r?\n|\r)\1/s) {
				my $linefeed = $1;
				my @tokens = split /((?:$linefeed){2,})/, $node->{content};
				for (my $i = 0; $i < @tokens; $i++) {
					my $token = $tokens[$i];
					if ($token =~ /(?:$linefeed){2,}/s) {
						#empty line(s). new block!
						#create new block if there are tokens or nodes left
						if ($i < @tokens - 1 or defined $next_node) {
							$current_block = Konstrukt::Parser::Node->new({ type => 'wikiblock' });
							$container->add_child($current_block);
						}
					} else {
						$current_block->add_child(Konstrukt::Parser::Node->new({ type => 'plaintext', content => $token }));
					}
				}
			} else {
				$current_block->add_child($node);
			}
			$node = $next_node;
		}
		
		#move blocks to  the tag node
		$tag->{first_child} = $tag->{last_child} = undef;
		$container->move_children($tag);
	}
}

=head2 merge_similar_neighbours

Your plugin may/should/must use this method if it splits the text into many
nodes that may be of similar type (e.g. two plaintext nodes that are not finally
parsed.). The splitted text may lead into wrong/missing recognition of markup
and in a little slower processing speed.

So if your plugin puts out many nodes of the same type you may want to use this
method to consolidate your output.

It is used by the basic-plugin and the link plugin that do much splitting.

Actually this method merges all plaintext nodes that have the same wiki_finished
state. It will not recurse into nodes having children.

This one is quite similar to L<Konstrukt::Parser/merge_similar_neighbours>, but it
will not recurse, it will care about the wiki_finished flag and it will not care
about comment nodes.

B<Parameters>:

=over

=item * $parent - The node whose children should be processed

=back

=cut
sub merge_similar_neighbours {
	my ($self, $parent) = @_;
	
	my $node = $parent->{first_child};
	while (defined $node) {
		if (defined $node->{next} and $node->{type} eq $node->{next}->{type} and $node->{type} eq "plaintext" and ($node->{wiki_finished} and $node->{next}->{wiki_finished} or not $node->{wiki_finished} and not $node->{next}->{wiki_finished})) {
			#merge nodes
			$node->{content} .= $node->{next}->{content};
			$node->{next}->delete();
		} else {
			$node = $node->{next};
		}
	}
}
#= /merge_similar_neighbours

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: /styles/wiki.css -- >8 --

/* CSS definitions for the Konstrukt wiki plugin */


/* icons */

img.wiki_icon {
	vertical-align: middle;
}

/* article */
/* clear floats (images,...) after the article */
div.wiki.article div.content:after {
	clear: both;
	content: ".";
	display: block;
	height: 0;
	visibility: hidden;
}
/* Hides from IE-mac \*/
* html div.wiki.article div.content {height: 1%;} /* hack for iE */
/* End hide from IE-mac */

/* image blocks */
div.wiki.image.block {
	float: right;
	clear: right;
	position: relative;
	margin: 5px;
	padding: 5px;
	border: 2px solid #3b8bc8;
	background-color: #e8f5ff;
}

div.wiki.image.block.default {
	float: right;
	clear: right;
}

div.wiki.image.block.left {
	float: left;
	clear: left;
}

div.wiki.image.block.right {
	float: right;
	clear: right;
}

div.wiki.image.block.center {
	float: none;
	margin-left: auto;
	margin-right: auto;
	text-align: center;
}


/* headlines */

h1.wiki {
	padding-bottom: 3px;
	border-bottom: 2px solid #3b8bc8;	
}


/* diff */

table.diff {
	width: 100%;
}

td.diff_remove {
	background-color: #DD7777;
}

td.diff_equal {
}

td.diff_empty {
}

td.diff_add {
	background-color: #77DD77;
}

td.diff_remove_number {
	width: 25px;
	background-color: #DD7777;
}

td.diff_equal_number {
	width: 25px;
}

td.diff_empty_number {
	width: 25px;
}

td.diff_add_number {
	width: 25px;
	background-color: #77DD77;
}

td.diff_seperator {
}

th.diff_header {
}


/* nonexistant links */

a.wiki.file.notexists, a.wiki.article.notexists, a.wiki.image.notexists {
	color: #a10000;
}


/* text formats */

span.wiki_acronym {
	border-bottom-width: 1px;
	border-bottom-style: dashed;
}

dt.wiki {
	font-weight: bold;
}

dd.wiki {
	margin-left: 10px;
	margin-bottom: 5px;
}

blockquote.wiki, pre.wiki {
	background-color: #e8f5ff;
	padding: 5px;
	margin: 5px;
	border: 1px dashed #3b8bc8;
	background-repeat: no-repeat;
	background-position: 2px 2px;
}

blockquote.wiki {
	font-style: italic;
}

cite.wiki {
	display: block;
	margin-top: 10px;
	margin-left: 10px;
	font-style: normal;
}

pre.wiki {
	font-family: "Lucida Console", monospace;
}

code.wiki {
	font-family: "Lucida Console", monospace;
}

strong.wiki.alternate {
	text-decoration: underline;
}
