=head1 NAME

Konstrukt::Plugin::wiki::markup::quote - Block plugin to handle quotes

=head1 SYNOPSIS
	
	my $q = use_plugin 'wiki::markup::quote';
	my $rv = $q->process($block);

=head1 DESCRIPTION

This one will match if the first line of the block start with a colon ":"
followed by at least one whitespace or tab.

The block will then be surrounded by <blockquote> and </blockquote> tags.

=head1 EXAMPLE

	: 640kb should be enough for everyone.
	
	: God does not play dice
	- Albert Einstein

=cut

package Konstrukt::Plugin::wiki::markup::quote;

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
	
	if (not $block->{first_child}->{wiki_finished} and $block->{first_child}->{type} eq 'plaintext' and $block->{first_child}->{content} =~ /^:[ \t]+(.*)$/s) {
		#update first line
		$block->{first_child}->{content} = $1;
		
		#strip off cite source if exists
		my $citesource;
		if ($block->{last_child}->{content} =~ /(?:\r?\n)[ \t]*-[ \t]*([^\n]*)$/) {
			#save cite source
			$citesource = $1;
			#strip off the last line
			$block->{last_child}->{content} =~ s/\r?\n.*?$//;
		}

		#put out quote template
		my $template = use_plugin 'template';
		my $template_path = $Konstrukt::Settings->get("wiki/template_path");
		#create field node and put the block content into it
		my $container = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '$' });
		$block->move_children($container);
		#create the template node and add it to the block
		my $template_node = $template->node("${template_path}markup/quote.template", { content => $container, cite => $citesource });
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

-- 8< -- textfile: markup/quote.template -- >8 --

<nowiki><blockquote class="wiki"><p></nowiki>
<+$ content $+><+$ / $+>
<nowiki></p>
<& if condition="'<+$ cite $+><+$ / $+>'" &>
<p><cite class="wiki"><+$ cite $+><+$ / $+></cite></p>
<& / &>
</blockquote></nowiki>
