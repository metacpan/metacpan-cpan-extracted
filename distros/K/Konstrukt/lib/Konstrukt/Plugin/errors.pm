#FEATURE: also display debug messages?

=head1 NAME

Konstrukt::Plugin::errors - Display the error messages that occured during the page processing

=head1 SYNOPSIS

B<Usage:>

	<& errors / &>

B<Result:>

A list of the errors, that occurred during the processing of the file, if any.

=head1 DESCRIPTION

Will display the error messages (if any) that have been created with
C<$Konstrukt::Debug->error_message()>.

A template named C<error.template> will be used to display them. The template
must have a list C<errors>, which must have a field C<text>.

=head1 CONFIGURATION

You may set the path to the template (C<error.template>) of this plugin. Default:

	errors/template_path  /templates/errors/

=cut

package Konstrukt::Plugin::errors;

use strict;
use warnings;

use base 'Konstrukt::SimplePlugin'; #inheritance
use Konstrukt::Plugin; #inheritance

=head1 METHODS

=head2 init

Inititalization of this class

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default("errors/template_path" => "/templates/errors/");
	
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
	return $Konstrukt::Lib->plugin_file_install_helper($Konstrukt::Settings->get('errors/template_path'));
}
# /install

=head2 default :Action

Default (and only) action for this plugin. Will display the error messages.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=item * $content - The content below/inside the tag as a flat string.

=item * $params - Reference to a hash of the passed CGI parameters.

=back

=cut
sub default :Action {
	my ($self, $tag, $content, $params) = @_;
	
	if (@{$Konstrukt::Debug->{error_messages}}) {
		my $template = use_plugin 'template';
		my $templ = $Konstrukt::Settings->get('errors/template_path') . "errors.template";
		
		$self->add_node($template->node($templ, { errors => [ map { { text => $_ } } @{$Konstrukt::Debug->{error_messages}} ] }));	
	}
}
#= /default

=head2 executionstage

This one should be executed last.

=cut
sub executionstage {
	return 999_999;
}
#= /executionstage

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Debug>, L<Konstrukt::SimplePlugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: errors.template -- >8 --

<div class="error">
	<h1>There have been errors/warnings during the processing of this page:</h1>
	<ul>
	<+@ errors @+>	<li><+$ text $+>(No text)<+$ / $+></li>
	<+@ / @+>
	</ul>
</div>

