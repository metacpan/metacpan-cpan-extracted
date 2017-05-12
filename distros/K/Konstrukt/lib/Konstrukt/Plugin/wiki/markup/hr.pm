=head1 NAME

Konstrukt::Plugin::wiki::markup::hr - Block plugin to handle horizontal rules

=head1 SYNOPSIS
	
	my $hr = use_plugin 'wiki::markup::hr';
	my $rv = $hr->process($block);

=head1 DESCRIPTION

This one will match if the block consists of only one line that just contains
dashes (-).

The block will be replaced by a <hr>-tag.

=head1 EXAMPLE

	those two paragraphs
	
	------
	
	will be separated by a horizontal rule

=cut

package Konstrukt::Plugin::wiki::markup::hr;

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
	
	if ($block->{first_child} eq $block->{last_child} and not $block->{first_child}->{wiki_finished} and $block->{first_child}->{type} eq 'plaintext' and $block->{first_child}->{content} =~ /^-+\s*$/) {
		#replace by hr-template
		my $template = use_plugin 'template';
		my $template_path = $Konstrukt::Settings->get("wiki/template_path");
		#create the template node
		my $template_node = $template->node("${template_path}markup/hr.template");
		#remove all child nodes from the block an add the template
		$block->{first_child} = $block->{last_child} = undef;
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

-- 8< -- textfile: markup/hr.template -- >8 --

<nowiki><hr class="wiki" /></nowiki>

