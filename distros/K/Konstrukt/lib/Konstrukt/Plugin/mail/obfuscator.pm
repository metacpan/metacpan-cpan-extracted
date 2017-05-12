#FEATURE: Use template to generate the link and remove htmllink/textlink interface?!

=head1 NAME

Konstrukt::Plugin::mail::obfuscator - Hide email addresses from SPAM harvesters.

=head1 SYNOPSIS

=head2 Tag interface

B<Usage:>

	<& mail::obfuscator name="John Doe" mail="john@doe.com" / &>

B<Result:>

	<!-- used to decrypt the email address -->
	<script type="text/javascript">
	<!--
	function xor_enc(text, key) {
		var result = '';
		for(i = 0; i < text.length; i++)
			result += String.fromCharCode(key.charCodeAt(i % key.length) ^ text.charCodeAt(i));
		return result;
	}
	// -->
	</script>
	
	<script type="text/javascript">
	<!--
	document.write(xor_enc(unescape('encrypted link'), 'key to decrypt'));
	-->
	</script>
	<noscript>
	John Doe: john<img src="/gfx/layout/s.gif" alt="&gt; add @-character here &lt;" />doe.com
	</noscript>

You can also optionally specifiy the complete HTML-link and "text link" if you
don't like the simple one that the plugin generates:

	<& mail::obfuscator
		html="<a href='mailto:john@doe.com' class='some_css_class'>John Doe</a>"
		text="Blabla John Doe: john@doe.com" 
	/ &>

This will basically do the same as when you specify the name and description:
Encrypt the HTML, obfuscate the text.

Note that you have to use singlequotes instead of doublequotes in the data
as doublequotes will collide with those of the mail::obfuscator tag. The
singlequotes will be replaced by doublequotes in the result. 

=head2 Perl interface

	my $obfusc = use_plugin 'mail::obfuscator';
	print $obfunc->link(mail => 'john@doe.com', name => 'John Doe');

There also are more "low level" methods, which can be used to create a custom
composition of the link.
	
=head1 DESCRIPTION

This plugin will put an encrypted/obfuscated email address on the website.

It puts two versions into the website: One for use with JavaScript and one for
the case that JS has been disabled.

For JS-capable clients a link will be generated and encrypted on the server.
This link will be decrypted and placed on the page using JavaScript.

If the client doesn't support JavaScript, the email address will only be
obfuscated and put on the page. The "@" will be replaced by an image (whose
alt-attribute can be L<configured|/CONFIGURATION>). The letters will be
encoded as HTML entities and some useless tags/comments will be inserted.

You may omit the C<name> attribute. The email address will then be used as the
text of the link.

=head1 CONFIGURATION

You may configure the text, that will replace the @ sign. Defaults:

	mail/obfuscator/at_replacement <img src="/at_image.gif" alt="&gt; add @-character here &lt;" />

You may put only an "@" in the alt-attribute, what will allow the user to just
copy and paste the address. But this might make it easier for harvesters to find the
email address.
You may also just replace the @ with the HTML-entity-code &064; which will make
is easier for both the user and the harvester.

=cut

package Konstrukt::Plugin::mail::obfuscator;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

=head1 METHODS

=head2 init

Inititalization of this class

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default("mail/obfuscator/at_replacement", '<img src="/at_image.gif" alt="&gt; add @-character here &lt;" />');
	
	#reset state
	delete $self->{script_printed};
	
	return 1;
}
#= /init

=head2 prepare

The output static for static input.
All work can be done in the prepare step if there is no dynamic content inside
the content of this tag.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	return $self->link(%{$tag->{tag}->{attributes}});
}
#= /prepare

=head2 link

Returns the encrypted/obfuscated link both for JavaScript-capable clients and
those which are not.

As every parameter is optional, the parameters to this method must
be passed as an hash ("named parameters"):

	$obfusc->link(name => 'John Doe', mail => '...', ...)

B<Parameters>:

=over

=item * mail - The email address of the addressee.

=item * name - The name of the addressee.

=item * html - A predefined HTML link - the link will not be generated from mail (and name).

=item * text - A predefined text "link" - the "link" will not be generated from mail (and name). 

=back

=cut
sub link {
	my ($self, %params) = @_;
	
	#add JavaScript function to decrypt the mail link
	my $js = '';
	unless ($self->{script_printed}) {
		$js = $self->js_function();
		$self->{script_printed} = 1; #only add the script once
	}
	
	my ($name, $mail, $html, $text) = map { $params{$_} } qw/name mail html text/;
	
	#generate links, if necessary
	$html = $self->html_link($mail, $name) unless defined $html;
	$text = $self->text_link($mail, $name) unless defined $text;
	
	#replace singleqoute by doublequotes
	$html =~ s/'/"/g;
	 
	#encrypt/obfuscate
	$html = $self->encrypt($html);
	$text = "<noscript>\n" . $self->obfuscate($text) . "\n</noscript>";
	
	return $js . $html . $text;
}
#= /link

=head2 js_function

Returns the JavaScript code that contains the function to decrypt the HTML link.

Usually only used internally.

B<Parameters>: none

=cut
sub js_function {
return <<SCRIPT;
<script type="text/javascript">
<!--
function xor_enc(text, key) {
	var result = '';
	for(i = 0; i < text.length; i++)
		result += String.fromCharCode(key.charCodeAt(i % key.length) ^ text.charCodeAt(i));
	return result;
}
// -->
</script>
SCRIPT
}
#= /js_function

=head2 html_link

Generates the HTML link for the specified name and email address.

Usually only used internally.

B<Parameters>:

=over

=item * $mail - The email address of the addressee

=item * $name - The name of the addressee. Defaults to $mail, if not specified

=back

=cut
sub html_link {
	my ($self, $mail, $name) = @_;
	
	#use address as name if not specified
	if (defined $name and length $name) {
		return (defined $mail and length $mail) ? "<a href=\"mailto:$mail\">$name</a>" : $name;
	} else {
		return (defined $mail and length $mail) ? "<a href=\"mailto:$mail\">$mail</a>" : "";
	}
}
#= /html_link

=head2 text_link

Generates the obfuscated text link for the specified name and email address.

Usually only used internally.

B<Parameters>:

=over

=item * $mail - The email address of the addressee

=item * $name - The name of the addressee. Optional.

=back

=cut
sub text_link {
	my ($self, $mail, $name) = @_;
	
	#generate "link"
	if (defined $name and length $name) {
		return (defined $mail and length $mail) ? "$name: $mail" : $name;
	} else {
		return (defined $mail and length $mail) ? $mail : "";
	}
}
#= /text_link

=head2 encrypt

Encrypts the specified text and returns a piece of HTML/JavaScript which will
decrypt it at the client. 

B<Parameters>:

=over

=item * $text - The text to be encrypted (usually an HTML link to an email address)

=back

=cut
sub encrypt {
	my ($self, $text) = @_;
	
	#generate encryption key
	my $key = $Konstrukt::Lib->random_password(8);
	
	#encrypt and escape the text
	$text = $Konstrukt::Lib->uri_encode($Konstrukt::Lib->xor_encrypt($text, $key), 1);
	
	#return JavaScript to decrypt this link
	return "<script type=\"text/javascript\">\n<!--\ndocument.write(xor_enc(unescape('$text'), '$key'))\n-->\n</script>";
}
#= /encrypt

=head2 obfuscate

Obfuscated the specified text: Encodes each character as HTML entities, inserts
comments and invisible tags and replaces any @-character by an image.

B<Parameters>:

=over

=item * $text - The text to be obfuscated (e.g. a text "link" to the mail address)

=back

=cut
sub obfuscate {
	my ($self, $text) = @_;
	
	#split link into characters
	my @chars = split '', $text;
	
	#encode each char as an HTML entity
	@chars = map { sprintf "&#%03i;", ord($_) } @chars;
	
	#insert span tags and a comment
	# split length into 4 pieces
	my $len = length($text);
	my @pos = ($len /4, $len / 2, $len / 4 * 3);
	#insert
	splice @chars, $pos[0], 0, '<span>';
	splice @chars, $pos[1], 0, '<!-- hi spammer! -->';
	splice @chars, $pos[2], 0, '</span>';
	#join
	$text = join '', @chars;
	
	#replace @-character
	my $repl = $Konstrukt::Settings->get('mail/obfuscator/at_replacement');
	$text =~ s/&#064;/$repl/g;
	
	#return obfuscated text
	return $text;
}
#= /obfuscate

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt>

=cut

