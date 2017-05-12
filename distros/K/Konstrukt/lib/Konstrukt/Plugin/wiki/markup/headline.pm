=head1 NAME

Konstrukt::Plugin::wiki::markup::headline - Block plugin to handle headlines

=head1 SYNOPSIS
	
	my $h = use_plugin 'wiki::markup::headline';
	my $rv = $h->process($block);

=head1 DESCRIPTION

This one will match if the first character of the first line of the block is a C<=>.

The block will then be enclosed by <hX> and </hX> (X = number of ='s before the
first character).

Any trailing ='s at the end of the block will be removed.

=head1 EXAMPLE

	= headline of level 1
	
	some text
	
	== headline of level 2
	
	some other text

=cut

package Konstrukt::Plugin::wiki::markup::headline;

use strict;
use warnings;

use base qw/Konstrukt::Plugin::wiki::markup::linkplugin/;
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
	
	if (not $block->{first_child}->{wiki_finished} and $block->{first_child}->{type} eq 'plaintext' and $block->{first_child}->{content} =~ s/^(=+)\s*//) {
		#level of this headline
		my $level = length($1);
		$level = 6 if $level > 6;
		
		#remove trailing ='s
		$block->{last_child}->{content} =~ s/\s*=+$// if (not $block->{last_child}->{wiki_finished} and $block->{last_child}->{type} eq 'plaintext');
		
		#put out headline template
		my $template = use_plugin 'template';
		my $template_path = $Konstrukt::Settings->get("wiki/template_path");
		#create field node and put the block content into it
		my $container = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '$' });
		$block->move_children($container);
		#get a normalized version of the content string that may be used in a id=".." attribute
		my $backend = use_plugin 'wiki::backend';
		my $normalized_content = $backend->normalize_link($container->children_to_string());
		#create the template node and add it to the block
		my $template_node = $template->node("${template_path}markup/headline.template", { level => $level, content => $container, normalized_content => $normalized_content });
		$block->add_child($template_node);
		
		return 1;
	} else {
		#doesn't match
		return undef;
	}
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

-- 8< -- textfile: markup/headline.template -- >8 --

<nowiki><h<+$ level $+>1<+$ / $+> class="wiki" id="<+$ normalized_content $+>no_title<+$ / $+>"></nowiki><+$ content $+>(no title)<+$ / $+><nowiki></h<+$ level $+>1<+$ / $+>></nowiki>

