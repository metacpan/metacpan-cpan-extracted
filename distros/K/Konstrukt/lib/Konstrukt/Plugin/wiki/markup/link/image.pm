#TODO: framed images

=head1 NAME

Konstrukt::Plugin::wiki::markup::link::image - Plugin to handle (internal and external) images

=head1 SYNOPSIS

See L<Konstrukt::Plugin::wiki::markup::linkplugin/SYNOPSIS>.

=head1 DESCRIPTION

This one will be responsible for all internal and external image links.

Internal images will be displayed on the page with a default width of 180px.
They will link to a page with the full sized image.

External images will just be linked and not displayed unless you define a
parameter to show them.

Note that the filename of internal images will be normalized.
All characters but letters, numbers, parenthesis and dots will be replaced
by underscores.

=head1 EXAMPLE

Internal images

	inline image: image:foo.jpg
	explicit image with alternative text: [[image:foo bar baz|alternative text (default = image name)]]
	explicit image with specified width: [[image:foo|200px]]
	
	Parameter reference:
	left: align the image on the left side
	right: align the image on the right side
	center: centered alignment of the image
	123px: width in pixels
	thumb: alias for 100px width
	text at the end: caption text (also alt-text)
	
	Default alignment: No special alignment, but may be overridden by the
	template/stylesheet. 
	
External images (.gif, .jpg, .png)

	implicit image: http://foo.bar/baz.gif
	explicit image: [[http://foo.bar/baz bar foo.jpg|link text]]
	explicit image displayed on the page: [[http://foo.bar/baz bar foo.jpg|embed|link text]]
	
	When an explicit image is displayed using the embed parameter the parameters
	available for internal images will also work.
	
=cut

package Konstrukt::Plugin::wiki::markup::link::image;

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
	return ('^[iI]mage:\S+$|^http://\S+\.(?:[gG][iI][fF]|[jJ][pP][eE]?[gG]|[pP][nN][gG])$', '^[iI]mage:.+|^http://.+\.(?:[gG][iI][fF]|[jJ][pP][eE]?[gG]|[pP][nN][gG])');
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
	$self->{image_backend} = use_plugin "wiki::backend::image::" . $Konstrukt::Settings->get("wiki/backend_type") or return undef;
	
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

B<Parameters>:

=over

=item * $link - The link string.

=back

=cut
sub handle {
	my ($self, $link_string) = @_;
	
	#container to collect the nodes. the type is arbitrary
	my $container = Konstrukt::Parser::Node->new({ type => 'wikinodecontainer' });
	
	#parse parameters
	my ($link, @parameters) = split /\|/, $link_string;
	#cut leading 'image:'
	$link =~ s/^image://i;
	#defaults
	my $parameters = {
		width => '180',
		align => undef,
		text  => $link
	};
	foreach my $parameter (@parameters) {
		if (lc($parameter) eq 'left') {
			$parameters->{align} = 'left';
		} elsif (lc($parameter) eq 'right') {
			$parameters->{align} = 'right';
		} elsif (lc($parameter) eq 'center') {
			$parameters->{align} = 'center';
		} elsif (lc($parameter) eq 'embed') {
			$parameters->{embed} = 1;
		} elsif (lc($parameter) eq 'thumb') {
			$parameters->{width} = 100;
		} elsif ($parameter =~ /^(\d+)px$/i) {
			$parameters->{width} = $1;
		} elsif ($parameter eq $parameters[-1]) {
			$parameters->{text} = $parameter;
		}
	};
	$parameters->{title} = $Konstrukt::Lib->html_escape($link);
	$parameters->{title_uri_encoded} = $Konstrukt::Lib->uri_encode($link);
	$parameters->{text} = $Konstrukt::Lib->html_escape($parameters->{text});
	my $type = $link =~ /^http:\/\// ? 'external' : 'internal';
	
	#put out templates
	my $template = use_plugin 'template';
	$self->reset_nodes();
	if ($type eq 'internal') {
		#create tag node of this plugin and add the containers
		my $node = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '&', tag => { type => 'wiki::markup::link::image' }, parameters => $parameters });
		$self->add_node($node);
	} else {
		my $node;
		if ($parameters->{embed}) {
			$node = $template->node("$self->{template_path}markup/image_link_external_embed.template", { fields => $parameters });
		} else {
			$node = $template->node("$self->{template_path}markup/image_link_external.template", { fields => $parameters });
		}
		
		$self->add_node($node);
	}
	
	return $self->get_nodes();
}
# /handle

=head2 execute_again

Yep, will return template nodes.

=cut
sub execute_again {
	return 1;
}
#= /execute_again

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

Here we will decide which link should be returned in dependence of the existance
of the image.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;
	
	$self->reset_nodes();
	my $template = use_plugin 'template';
	
	my $image = $self->{image_backend}->get_info($tag->{parameters}->{title});
	if (defined $image) {
		#image exists
		if ($image->{content_revision}) {
			#calculate height
			my $aspect = $image->{width} / $image->{height};
			$tag->{parameters}->{height} = int($tag->{parameters}->{width} / $aspect);
		}
		#join image info and parameters
		my $fields = { %{$image}, %{$tag->{parameters}} };
		#put out node
		$self->add_node($template->node("$self->{template_path}markup/image_link_exists.template", { fields => $fields }));
	} else {
		#image doesn't exist
		$self->add_node($template->node("$self->{template_path}markup/image_link_not_exists.template", { fields => $tag->{parameters} }));
	}
	
	#strip nowiki nodes off the template output
	#(use_plugin 'wiki')->separate_nowiki($self->get_nodes());
	
	return $self->get_nodes();
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

-- 8< -- textfile: markup/image_link_exists.template -- >8 --

<div class="wiki image block <+$ align $+>default<+$ / $+>" style="width: <+$ width / $+>px">
	<p class="image">
		<a class="wiki image exists" href="/wiki/?action=image_show;title=<+$ title_uri_encoded $+><+$ / $+>">
			<& if condition="<+$ content_revision $+>0<+$ / $+>" &>
				<$ then $><img class="wiki" src="/wiki/image/?action=image_content;title=<+$ title_uri_encoded / $+>;revision=<+$ revision / $+>;width=<+$ width / $+>" alt="<+$ text $+>(no description)<+$ / $+>" title="<+$ text $+>(no description)<+$ / $+>" width="<+$ width / $+>" height="<+$ height / $+>" /><$ / $>
				<$ else $><+$ title / $+><$ / $>
			<& / &>
		</a>
	</p>
	<p class="description"><+$ text $+>(no description)<+$ / $+></p>
</div>

-- 8< -- textfile: markup/image_link_external.template -- >8 --

<nowiki><a class="wiki image link external" href="<+$ title $+><+$ / $+>"><+$ text $+>(Kein Titel)<+$ / $+></a></nowiki>

-- 8< -- textfile: markup/image_link_external_embed.template -- >8 --

<nowiki><img class="wiki image external" src="<+$ title $+><+$ / $+>" alt="<+$ text $+>(Kein Text)<+$ / $+>" /></nowiki>

-- 8< -- textfile: markup/image_link_not_exists.template -- >8 --

<a class="wiki image notexists" href="/wiki/?action=image_show;title=<+$ title_uri_encoded $+><+$ / $+>" title="<+$ title $+><+$ / $+>"><+$ text $+>(no title)<+$ / $+></a>(?)

