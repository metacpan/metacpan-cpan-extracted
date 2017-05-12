=head1 NAME

Konstrukt::Plugin::wiki::markup::link::article - Plugin to handle wiki article links

=head1 SYNOPSIS
	
See L<Konstrukt::Plugin::wiki::markup::linkplugin/SYNOPSIS>.

=head1 DESCRIPTION

This one will be responsible for all wiki links (CamelCase, [[nocamelcase]]).

You should put this one at the end of the list of the link plugins since it will
act like a 'catch all' plugin to match all links that haven't been matched by another
plugin.

=head1 EXAMPLE

Implicit links

	CamelCaseLink
	
	!ThisLinkWontMatch

Explicit links (with description)

	[[thislinkwillmatch]]

	[[CamelCaseLink|but with another description]]
	
	[[linikwith#anchor]]

=cut

package Konstrukt::Plugin::wiki::markup::link::article;

use strict;
use warnings;

use base qw/Konstrukt::Plugin::wiki::markup::linkplugin Konstrukt::Plugin/;
use Konstrukt::Plugin; #import use_plugin

use Konstrukt::Parser::Node;

=head1 METHODS

=head2 matching_regexps()

See L<Konstrukt::Plugin::wiki::markup::linkplugin/matching_regexps> for a description.

=cut
sub matching_regexps {
	my ($self) = @_;
	#match CamelCase as implicit links or every string as explicit links.
	return ('^[A-Z]+[a-z]+[A-Z]+[A-Za-z]*$', '^.+');
}
# /matching_regexps

=head2 init

Initialization.

=cut
sub init {
	my ($self) = @_;
	
	#load wiki plugin to let it define its default settings
	use_plugin 'wiki';
	
	#create data backend object
	$self->{article_backend} = use_plugin "wiki::backend::article::" . $Konstrukt::Settings->get("wiki/backend_type") or return undef;
	
	#path
	$self->{template_path} = $Konstrukt::Settings->get("wiki/template_path");
	
	return 1;
}
#= /init

=head2 install

Installs the templates.

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_file_install_helper($self->{template_path});
}
# /install

=head2 handle()

See L<Konstrukt::Plugin::wiki::markup::linkplugin/handle> for a description.

This one is tricky.

On every request we want to check if the target wiki page exists and put
out a different link if it doesn't so that the user can recognize a link to a
page that doesn't exist yet.

As the decision of the existance of a wiki page must be made at the execute run
we cannot determine which template to use for the link before the execute run.
So the template must be processed at the execute run, which will be very time
consuming.

What this plugin does, is to put B<both> templates (for a dead and for an alive
link) into the tree at the prepare run under a tag node of itself, so both
templates will be processed in the prepare run und we can save this work in
the execute run, where this plugin's tag node just decides which (processed)
template to use.

So we're effectively moving work from the execute to the prepare run, which will
lead into a bit more work in the prepare run but will save us a lot of work on
every execute run. Great, isn't it?

B<Parameters>:

=over

=item * $link - The link string.

=back

=cut
sub handle {
	my ($self, $link_string) = @_;
	
	#split the link into article, anchor and description
	my ($link, $description) = split /\|/, $link_string, 2;
	my ($article, $anchor) = split /#/, $link, 2;
	$description = $article unless defined $description;
	
	#create the template nodes for both links
	my $template = use_plugin 'template';
	my $values = {
		title => $Konstrukt::Lib->html_escape($article),
		title_uri_encoded => $Konstrukt::Lib->uri_encode($article),
		anchor => (defined $anchor ? "#" . $Konstrukt::Lib->uri_encode($anchor) : undef),
		description => $Konstrukt::Lib->html_escape($description)
	}; 
	my $link_alive = $template->node("$self->{template_path}markup/article_link_exists.template",     $values);
	my $link_dead  = $template->node("$self->{template_path}markup/article_link_not_exists.template", $values);
	
	#put the templates into containers to separate them
	my $cont_alive = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '', tag => { type => 'wiki::markup::link::article container (alive)' } });
	my $cont_dead  = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '', tag => { type => 'wiki::markup::link::article container (dead)'  } });
	$cont_alive->add_child($link_alive);
	$cont_dead->add_child($link_dead);
	
	#create tag node of this plugin and add the containers
	my $node = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '&', tag => { type => 'wiki::markup::link::article' }, page => $article });
	$node->add_child($cont_alive);
	$node->add_child($cont_dead);
	
	#return this tag node
	$self->reset_nodes();
	$self->add_node($node);
	return $self->get_nodes();
}
# /handle

=head2 prepare

Won't do anything in the prepare run.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	#Don't do anything beside setting the dynamic-flag
	$tag->{dynamic} = 1;
	
	return undef;
}
#= /prepare

=head2 execute

Here we will decide which link should be returned. Either one for dead links or
one for links, that are alive.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;
	
	if ($self->{article_backend}->exists($tag->{page})) {
		#return the 'alive' link
		return $tag->{first_child};
	} else {
		#return the 'dead' link
		return $tag->{first_child}->{next};
	}
}
#= /execute

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::wiki>

=cut

__DATA__

-- 8< -- textfile: markup/article_link_exists.template -- >8 --

<a class="wiki article exists" href="/wiki/?wiki_page=<+$ title_uri_encoded / $+><+$ anchor / $+>" title="<+$ title $+><+$ / $+>"><+$ description $+>(no title)<+$ / $+></a>

-- 8< -- textfile: markup/article_link_not_exists.template -- >8 --

<a class="wiki article notexists" href="/wiki/?wiki_page=<+$ title_uri_encoded / $+><+$ anchor / $+>" title="<+$ title $+><+$ / $+>"><+$ description $+>(no title)<+$ / $+></a>(?)

