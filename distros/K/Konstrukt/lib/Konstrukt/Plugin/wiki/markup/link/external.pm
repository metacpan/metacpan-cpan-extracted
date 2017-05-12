#FEATURE: download the target file, if it's text/* and look for <title> tag
#         which can be used for <a title="page title">

=head1 NAME

Konstrukt::Plugin::wiki::markup::link::external - Plugin to handle external links

=head1 SYNOPSIS

See L<Konstrukt::Plugin::wiki::markup::linkplugin/SYNOPSIS>.

=head1 DESCRIPTION

This one will be responsible for all external links (http://, ftp://, mailto:,
news:, ...). The links will be surrounded by <a> and </a>.

=head1 EXAMPLE

Implicit links

	http://foo.bar/baz
	
Explicit links (with description)

	[[http://foo.bar/baz]]

	[[http://foo.bar/baz|something here]]

=cut

package Konstrukt::Plugin::wiki::markup::link::external;

use strict;
use warnings;

use base qw/Konstrukt::Plugin::wiki::markup::linkplugin Konstrukt::Plugin/;
use Konstrukt::Plugin; #import use_plugin

=head1 METHODS

=head2 matching_regexps()

See L<Konstrukt::Plugin::wiki::markup::linkplugin/matching_regexps> for a description.

=cut
sub matching_regexps {
	#both explicit and implicit links will match on almost the same pattern.
	#but the explicit link will also match on whitespaces, whereas in the implicit
	#links whitespaces are not allowed.
	return ('^\S+://\S+$|^mailto:\S+$|^news:\S+$', '^.+://.+|^mailto:.+|^news:.+');
}
# /matching_regexp

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

=head2 handle()

See L<Konstrukt::Plugin::wiki::markup::linkplugin/handle> for a description.

B<Parameters>:

=over

=item * $link - The link string.

=back

=cut
sub handle {
	my ($self, $link_string) = @_;
	
	#does this link have a description?
	my ($link, $description) = split /\|/, $link_string, 2;
	$description = $link unless defined $description;
	
	#create and return link
	my $template = use_plugin 'template';
	my $template_path = $Konstrukt::Settings->get("wiki/template_path");
	
	#determine link type
	$link =~ /^(\S+)?:/;
	my $type = $1;
	
	#special handling of mail descriptions and separate template for mail links
	if ($type eq 'mailto') {
		#remove the mailto-prefix
		$description =~ s/^mailto:// if $description eq $link;
		$link =~ s/^mailto://;
	}
	
	my $template_file = "${template_path}markup/external_link.template";
	$self->reset_nodes();
	$self->add_node($template->node($template_file, { link => $link, description => $description, type => $type }));
	return $self->get_nodes();
}
# /handle

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::wiki>

=cut

__DATA__

-- 8< -- textfile: markup/external_link.template -- >8 --

<nowiki><& if condition="'<+$ type / $+>' eq 'mailto'" &>
	<$ then $><& mail::obfuscator text="<+$ link $+><+$ / $+>" html="<a class='wiki external' href='mailto:<+$ link $+><+$ / $+>'><+$ description / $+></a>" / &><$ / $>
	<$ else $><a class="wiki external" href="<+$ link $+><+$ / $+>"><+$ description $+>(no title)<+$ / $+></a><$ / $>
<& / &></nowiki>

