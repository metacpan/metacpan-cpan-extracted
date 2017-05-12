#TODO: remove dirty hack: $Konstrukt::Session->get('user_id').
#      cleaner: use user management plugin instead
#FEATURE: implement graphical captcha

=head1 NAME

Konstrukt::Plugin::captcha - Put captchas in your forms easily.

=head1 SYNOPSIS

=head2 Tag interface

B<Usage:>

	<!-- the easy way -->
	<& captcha / &>

or

	<!-- defining your own settings that may differ from the defaults -->
	<& captcha type="text" template="/templates/captcha/text.template" / &>

B<Result:> (Something like this)

	<script type="text/javascript">
		var enctext = "%50%0A%3A%21%44%38%4C%0C%0D%0E%31%6C%13%2F%0D%12%18%00%3C%30%6E%2D%02%11%1B%06%26%73%11%38%15%12%09%5E%76%39%58%28%08%07%02%41%74%32%5D%2D%1F%11%51%41%2C%29%5D%6E%4C%14%0D%0F%21%34%0C%6E%5D%16%06%01%23%73%11%63%52%68";
		var key = "lcTQ1Llb";
		function xor_enc(text, key) {
			var result = '';
			for(i = 0; i < text.length; i++)
				result += String.fromCharCode(key.charCodeAt(i % key.length) ^ text.charCodeAt(i));
			return result;
		}
		document.write(xor_enc(unescape(enctext), key));
	</script>
	
	<noscript>
		<label>Antispam:</label>
		<div>
		<p>Please type the text '1tjbw' into this field:</p>
		<input name="captcha_answer" />
		</div>
	</noscript>
	
	<input name="captcha_hash" type="hidden" value="3452c4fb13505c5ffa256f2352851ed2b9286af70c3f9ed65e3e888690e1ee69" />

The captcha tag will usually be embedded in an existing C<<form>>. It will
only generate the question (using a template) and two C<<input>> HTML-tags that
will accept the answer and pass a hash of the correct answer to the server.

=head2 Perl interface

It's very easy to add a captcha-check to your plugins:

	my $template = use_plugin 'template';
	
	if ((use_plugin 'captcha')->check()) {
		#captcha solved!
		#your code...
	} else {
		#captcha not solved!
		#e.g. put error message and ask again:
		$self->add_node($template->node('error_message.template'));
		$self->add_node($template->node('template_with_input_form_and_captcha_tag.template'));
	}

=head1 DESCRIPTION

This plugin will put a captcha on your website and allows you to check it easily.

There may be several implementation types, although currently only
L<text|Konstrukt::Plugin::captcha::text> captchas are implemented.

If the session management is activated, the user won't be asked to answer a
captcha again, if (s)he already answered one correctly. This behaviour can be
disabled in the setting C<captcha/ask_once>.

Also a user, which has logged on, won't be asked to enter a captcha. This
behaviour can be disabled in the setting C<captcha/dont_ask_users>.

=head1 CREATING OWN CAPTCHA IMPLEMENTATIONS

To create an captcha implementation, you must create plugin module
C<Konstrukt::Plugin::captcha::your_type>.

This plugin needs to have a method C<display>, which will be called to display
the captcha part of the input dialogue (i.e. the captcha question and the input
fields for the answer (C<name="captcha_answer">)and the hash checksum
(C<name="captcha_hash">)).

This will be done like every (simple) plugin does via C<print> or C<$self->add_node()>
(see L<Konstrukt::Plugin/add_node>).

You might want to take an existing implementation as a template.

B<Parameters>:

=over

=item * $answer - The correct answer for the captcha

=item * $hash - The hash of the correct answer

=item * $templ - Path to the template to display the captcha

=back

=head1 CONFIGURATION

You may control the behaviour of this plugin with some settings. Defaults:

	captcha/type           text
	captcha/template_path  /templates/captcha/
	captcha/ask_once       1
	captcha/dont_ask_users 1

=cut

package Konstrukt::Plugin::captcha;

use strict;
use warnings;

use base 'Konstrukt::SimplePlugin'; #inheritance
use Konstrukt::Plugin; #inheritance

use Digest::SHA;

=head1 METHODS

=head2 init

Inititalization of this class

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default("captcha/type"           => "text");
	$Konstrukt::Settings->default("captcha/template_path"  => "/templates/captcha/");
	$Konstrukt::Settings->default("captcha/ask_once"       => 1);
	$Konstrukt::Settings->default("captcha/dont_ask_users" => 1);
	
	return 1;
}
#= /init

=head2 check

Checks if the user answer matches the captcha question. This is done by hashing
the user answer and comparing it to the hashed correct answer.

Returns true, if the answer is correct.

B<Parameters>: none

=cut
sub check {
	my ($self) = @_;
	
	my $askonce = $Konstrukt::Settings->get('captcha/ask_once');
	
	return 1 if
		$Konstrukt::Session->activated() and
		(
			($askonce and $Konstrukt::Session->get('captcha/solved'))
			or
			($Konstrukt::Settings->get('captcha/dont_ask_users') and $Konstrukt::Session->get('user_id'))
		);
	
	#get answer and hash
	my $answer = $Konstrukt::CGI->param('captcha_answer');
	my $hash   = $Konstrukt::CGI->param('captcha_hash');
	
	#compare hash of user answer and hash of the correct answer
	if ($hash eq Digest::SHA->new(256)->add($answer)->hexdigest()) {
		$Konstrukt::Session->set('captcha/solved' => 1) if
			$Konstrukt::Session->activated() and $askonce;
		
		return 1;
	}
}
#= /init

=head2 install

Installs the templates.

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_file_install_helper($Konstrukt::Settings->get('captcha/template_path'));
}
# /install

=head2 default :Action

Default (and only) action for this plugin. Will display the captcha according
to the attributes set in the C<<& captcha / &>> tag.

The attributes are optional. Their value defaults are defined in the L<settings|/CONFIGURATION>.

B<Tag attributes>:

=over

=item * type - Optional: The type of the captcha. Currently only "text" captchas
are implemented. Defaults to the setting C<captcha/type>).

=item * template - Optional: The path to the template to display the captcha.
Defaults to "C<captcha/template_path> C<$type> .template". The variables C<answer>
and C<hash> will be passed to your template.

=back

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=item * $content - The content below/inside the tag as a flat string.

=item * $params - Reference to a hash of the passed CGI parameters.

=back

=cut
sub default :Action {
	my ($self, $tag, $content, $params) = @_;
	
	#skip, if the user already proved to be a human
	return if
		$Konstrukt::Session->activated() and
		(
			($Konstrukt::Settings->get('captcha/ask_once') and $Konstrukt::Session->get('captcha/solved'))
			or
			($Konstrukt::Settings->get('captcha/dont_ask_users') and $Konstrukt::Session->get('user_id'))
		);
	
	my $template = use_plugin 'template';
	
	my $type  = $tag->{tag}->{attributes}->{type}        || $Konstrukt::Settings->get('captcha/type');
	my $templ = $tag->{tag}->{attributes}->{template}    || $Konstrukt::Settings->get('captcha/template_path') . "$type.template";
	
	#generate answer
	my $answer = $Konstrukt::Lib->random_password(5, 1);
	my $hash   = Digest::SHA->new(256)->add($answer)->hexdigest();
	
	#display the captcha using the specified implementation
	my $impl = use_plugin "captcha::$type";
	$impl->{collector_node} = $self->{collector_node}; #collect the output in _this_ plugin
	$impl->display($answer, $hash, $templ);
}
#= /default

=head2 solve :Action

This is a demo/debug action, which allows you to test your captcha.

Just put this code on a web page:

	<form action="" method="post">
		<input type="hidden" name="captcha_action" value="solve" />
		<& captcha / &>
		<input type="submit" value="Check" />
	</form>

Okay, this is some kind of a dirty hack, but it should work for test purposed.

=cut
sub solve :Action {
	my ($self, $tag, $content, $params) = @_;
	
	if ($self->check()) {
		print "<span style=\"color: green;\">Captcha solved!</span>";
	} else {
		print "<span style=\"color: red;\">Capcha not solved!</span>";
	}
	
	$self->default($tag, $content, $params);
}
#= /solve

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::SimplePlugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: text.template -- >8 --

Please enter the text '<+$ answer / $+>' into this field:
<br />
<input name="captcha_answer" />
<input name="captcha_hash" type="hidden" value="<+$ hash / $+>" />
<br />

-- 8< -- textfile: text_js.template -- >8 --

<script type="text/javascript">
<& perl &>
	#generate encrypted answer
	my $answer  = $template_values->{fields}->{answer};
	my $key     = $Konstrukt::Lib->random_password(8);
	my $enctext = $Konstrukt::Lib->uri_encode($Konstrukt::Lib->xor_encrypt("<input name=\"captcha_answer\" type=\"hidden\" value=\"$answer\" />", $key), 1);
	print "\tvar enctext = \"$enctext\";\n";
	print "\tvar key = \"$key\";";
<& / &>
	function xor_enc(text, key) {
		var result = '';
		for(i = 0; i < text.length; i++)
			result += String.fromCharCode(key.charCodeAt(i % key.length) ^ text.charCodeAt(i));
		return result;
	}
	document.write(xor_enc(unescape(enctext), key));
</script>

<noscript>
	Please enter the text '<+$ answer / $+>' into this field:
	<br />
	<input name="captcha_answer" />
</noscript>

<input name="captcha_hash" type="hidden" value="<+$ hash / $+>" />
