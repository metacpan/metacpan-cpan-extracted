=head1 NAME

Konstrukt::Plugin::captcha::text - Implementation for text captchas.

=head1 DESCRIPTION

Will be used by L<Konstrukt::Plugin::captcha> to generate text captchas.

The text captchas are very simple and easily solvable by computers, if
someone would write a program for this captcha. But they should keep stupid
bulk spammers away from spamming your guestbook or blog comments.

There are two sample templates to display the captcha. One just asks the user
to enter the text into a form field. The other is a bit more tricky by
generating a hidden form field with the correct answer via JavaScript.
The user only has to enter the code itself if JS is disabled and a bulk
spammer wouldn't execute JavaScript.

=head1 CONFIGURATION

Nothing to configure.

=cut

package Konstrukt::Plugin::captcha::text;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

=head2 display

Implementation of the display method

=cut
sub display {
	my ($self, $answer, $hash, $templ) = @_;
	
	my $template = use_plugin 'template';
	$self->add_node($template->node($templ, { answer => $answer, hash => $hash }));
}
#= /display

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin:;captcha>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut