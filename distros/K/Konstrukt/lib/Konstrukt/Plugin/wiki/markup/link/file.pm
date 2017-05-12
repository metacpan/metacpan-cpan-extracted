=head1 NAME

Konstrukt::Plugin::wiki::markup::link::file - Plugin to handle links to internal files.

=head1 SYNOPSIS

See L<Konstrukt::Plugin::wiki::markup::linkplugin/SYNOPSIS>.

=head1 DESCRIPTION

This one will be responsible for all internal files.

A link to the file will be created. If the target file doesn't exist, the user may
upload it.

Note that the filename will be normalized. All characters but letters, numbers,
parenthesis and dots will be replaced by underscores.

=head1 EXAMPLE

Implicit

	file:somefile.zip
	
Explicit

	[[file:some other file.rar|with a different link text]]
	
=cut

package Konstrukt::Plugin::wiki::markup::link::file;

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
	#both explicit and implicit links will match on almost the same pattern.
	#but the explicit link will also match on whitespaces.
	return ('^[fF]ile:\S+$', '^[fF]ile:.+');
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
	$self->{file_backend} = use_plugin "wiki::backend::file::" . $Konstrukt::Settings->get("wiki/backend_type") or return undef;
	
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

This one uses the same trick as L<Konstrukt::Plugin::wiki::markup::link::article/handle>.

B<Parameters>:

=over

=item * $link - The link string.

=back

=cut
sub handle {
	my ($self, $link_string) = @_;
	
	#does this link have a description?
	my ($link, $description) = split /\|/, $link_string, 2;
	#cut leading 'file:'
	$link =~ s/^file://i;
	$description = $link unless defined $description;
	
	#create the template nodes for both links
	my $template = use_plugin 'template';
	my $values = {
		title => $Konstrukt::Lib->html_escape($link),
		title_uri_encoded => $Konstrukt::Lib->uri_encode($link),
		description => $Konstrukt::Lib->html_escape($description)
	}; 
	my $link_alive = $template->node("$self->{template_path}markup/file_link_exists.template",     $values);
	my $link_dead  = $template->node("$self->{template_path}markup/file_link_not_exists.template", $values);
	
	#put the templates into containers to separate them
	my $cont_alive = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '', tag => { type => 'wiki::markup::link::file container (alive)' } });
	my $cont_dead  = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '', tag => { type => 'wiki::markup::link::file container (dead)'  } });
	$cont_alive->add_child($link_alive);
	$cont_dead->add_child($link_dead);
	
	#create tag node of this plugin and add the containers
	my $node = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '&', tag => { type => 'wiki::markup::link::file' }, title => $link });
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
	
	if ($self->{file_backend}->exists($tag->{title})) {
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

-- 8< -- textfile: markup/file_link_exists.template -- >8 --

<a class="wiki file exists" href="/wiki/?action=file_show;title=<+$ title_uri_encoded $+><+$ / $+>" title="<+$ title $+><+$ / $+>"><+$ description $+>(no title)<+$ / $+></a>
<a class="wiki file content exists" href="/wiki/file/?action=file_content;title=<+$ title_uri_encoded $+><+$ / $+>" title="Direct download">[ direct dl ]</a>

-- 8< -- textfile: markup/file_link_not_exists.template -- >8 --

<a class="wiki file notexists" href="/wiki/?action=file_show;title=<+$ title_uri_encoded $+><+$ / $+>" title="<+$ title $+><+$ / $+>"><+$ description $+>(no title)<+$ / $+></a>(?)

