=head1 NAME

Konstrukt::Plugin::wiki::markup::paragraph - Block plugin to handle paragraphs

=head1 SYNOPSIS
	
	my $par = use_plugin 'wiki::markup::paragraph';
	my $rv = $par->process($block);

=head1 DESCRIPTION

This one won't do much more but putting <p> and </p> around a block.

It matches all blocks and should be the last plugin in your filter chain so it
will catch all block that didn't match any other plugin.

=head1 EXAMPLE

	this is
	one paragraph and will be surrounded
	by <p> and </p>
	
	this one also

=cut

package Konstrukt::Plugin::wiki::markup::paragraph;

use strict;
use warnings;

use base 'Konstrukt::Plugin::wiki::markup::blockplugin';
use Konstrukt::Plugin; #import use_plugin

use Konstrukt::Parser::Node;

=head1 METHODS

=head2 install

Installs the templates.

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_file_install_helper($Konstrukt::Settings->get("wiki/template_path"));
}
# /install

=head2 process

This method will do the work.

B<Parameters>:

=over

=item * $block - Block node (of type L<Konstrukt::Parser::Node>) containing the
(text-)nodes of this block.

=back

=cut
sub process {
	my ($self, $block) = @_;
	
	#check, if there is any textual content within this paragraph.
	#<nowiki>-regions and image-links are no textual content.
	my $image = use_plugin 'wiki::markup::link::image';
	my ($image_implicit, $image_explicit) = map { s/[\$\^]//g; $_ } $image->matching_regexps();
	my $has_content;
	my $node = $block->{first_child};
	while (defined $node) {
		if (not $node->{wiki_finished} and $node->{type} eq 'plaintext' and length $node->{content} and $node->{content} !~ /^($image_implicit|\[\[$image_explicit\]\])$/o) {
			$has_content = 1;
			last;
		}
		$node = $node->{next};
	}
	return 1 unless $has_content;
	
	#put out paragraph template
	my $template = use_plugin 'template';
	my $template_path = $Konstrukt::Settings->get("wiki/template_path");
	#create field node and put the block content into it
	my $container = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '$' });
	$block->move_children($container);
	#create the template node and add it to the block
	my $template_node = $template->node("${template_path}markup/paragraph.template", { content => $container });
	$block->add_child($template_node);
	
	return 1;
}
# /process

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::wiki>

=cut

__DATA__

-- 8< -- textfile: markup/paragraph.template -- >8 --

<nowiki><p class="wiki"></nowiki><+$ content $+><+$ / $+><nowiki></p></nowiki>

