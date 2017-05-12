#TODO: use stored user data, if a logged in user posts a comment

=head1 NAME

Konstrukt::Plugin::guestbook - Konstrukt guestbook

=head1 SYNOPSIS
	
	<& guestbook / &>
	
=head1 DESCRIPTION

This Konstrukt Plug-In provides "easy to implement" guestbook-facilities for your
website.

You may simply integrate it by putting 

	<& guestbook / &>

somewhere in your website.

=head1 CONFIGURATION

You may do some configuration in your konstrukt.settings to let the
plugin know where to get its data and which layout to use. Defaults:
	
	#use a captcha to prevent spam
	guestbook/use_captcha          1 #you have to put <& captcha / &> inside your add-template

	#backend
	guestbook/backend              DBI

See the documentation of the backend modules
(e.g. L<Konstrukt::Plugin::guestbook::DBI/CONFIGURATION>) for their configuration.

	#Layout
	guestbook/template_path        /templates/guestbook/
	guestbook/entries_per_page     10
	#administration
	guestbook/userlevel_admin      3

=cut

package Konstrukt::Plugin::guestbook;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use POSIX qw/ceil/;

use Konstrukt::Debug;

=head1 METHODS

=head2 execute_again

Yes, this plugin may return dynamic nodes (i.e. template nodes).

=cut
sub execute_again {
	return 1;
}
#= /execute_again

=head2 init

Initializes this object. Sets $self->{backend} and $self->{template_path}layout/.
init will be called by the constructor.

=cut
sub init {
	my ($self) = @_;
	
	#dependencies
	$self->{user_level} = use_plugin 'usermanagement::level' or return undef;
	
	#default settings
	$Konstrukt::Settings->default("guestbook/use_captcha"      => 1);
	$Konstrukt::Settings->default("guestbook/backend"          => "DBI");
	$Konstrukt::Settings->default("guestbook/template_path"    => '/templates/guestbook/');
	$Konstrukt::Settings->default("guestbook/entries_per_page" => 10);
	$Konstrukt::Settings->default("guestbook/userlevel_admin"  => 3);
	
	#create content object
	$self->{backend}       = use_plugin "guestbook::" . $Konstrukt::Settings->get("guestbook/backend") or return undef;
	$self->{template_path} = $Konstrukt::Settings->get('guestbook/template_path');
	
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

=head2 prepare

Prepare method

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

All the work is done in the execute step.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;

	#reset the collected nodes
	$self->reset_nodes();

	my $action = $Konstrukt::CGI->param('action') || '';
	#what to do?
	if ($action eq 'add') {
		#add a new entry
		$self->add_entry();
	} elsif ($action eq 'showdelete') {
		#show the form to delete an entry
		$self->delete_entry_show();
	} elsif ($action eq 'delete') {
		#remove an existing entry
		$self->delete_entry();
	}
	if ($action ne 'showdelete') {
		$self->add_entry_show();
		$self->show_entries();
	}
	
	return $self->get_nodes();
}
#= /execute

=head2 add_entry_show

Displays the form to add an entry.

=cut
sub add_entry_show {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	$self->add_node($template->node("$self->{template_path}layout/add_form.template"));
}
#= /add_entry_show

=head2 add_entry

Takes the HTTP form input and adds a new guestbook entry.

Displays a confirmation of the successful addition or error messages otherwise.

=cut
sub add_entry {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	my $form     = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/add_form.form");
	$form->retrieve_values('cgi');
	my $log = use_plugin 'log';
	
	if ($form->validate()) {
		if (not $Konstrukt::Settings->get('guestbook/use_captcha') or (use_plugin 'captcha')->check()) {
			my $name     = ($form->get_value('author')   || '');
			my $email    = ($form->get_value('email')    || '');
			my $icq      = ($form->get_value('icq')      || '');
			my $aim      = ($form->get_value('aim')      || '');
			my $yahoo    = ($form->get_value('yahoo')    || '');
			my $jabber   = ($form->get_value('jabber')   || '');
			my $msn      = ($form->get_value('msn')      || '');
			my $homepage = ($form->get_value('homepage') || '');
			my $text     = ($form->get_value('text')     || '');
			my $host     = $Konstrukt::Handler->{ENV}->{REMOTE_ADDR};
			$homepage = "http://$homepage" unless substr(lc $homepage, 0, 7) eq "http://";
			if ($self->{backend}->add_entry($name, $email, $icq, $aim, $yahoo, $jabber, $msn, $homepage, $text, $host)) {
				#success 
				my $author_name = join ' / ', ($name, $email);
				$log->put(__PACKAGE__ . '->add_entry', "$author_name added a new guestbook entry.", $author_name);
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/add_failed.template"));
			}
		} else {
			#captcha not solved
			$self->add_node($template->node("$self->{template_path}messages/add_failed_captcha.template"));
		}
	} else {
		$self->add_node($form->errors());
	}
}
#= /add_entry

=head2 delete_entry_show

Displays the confirmation form to delete an entry.

=cut
sub delete_entry_show {
	my ($self) = @_;
	
	my $id  = $Konstrukt::CGI->param('id');
	if ($id) {
		my $entry = $self->{backend}->get_entry($id);
		if (keys %{$entry}) {
			my $template = use_plugin 'template';
			$self->add_node($template->node("$self->{template_path}layout/delete_form.template", { author => $entry->{name}, text => $Konstrukt::Lib->html_escape($entry->{text}), id => $id }));
		} else {
			$Konstrukt::Debug->error_message("Entry $id does not exist!") if Konstrukt::Debug::ERROR;
		}
	} else {
		$Konstrukt::Debug->error_message('No id specified!') if Konstrukt::Debug::ERROR;
	}
}
#= /delete_entry_show

=head2 delete_entry

Deletes the specified entry.

Displays a confirmation of the successful removal or error messages otherwise.

=cut
sub delete_entry {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/delete_form.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $id = $form->get_value('id');
		my $template = use_plugin 'template';
		if ($self->{user_level}->level() >= $Konstrukt::Settings->get('guestbook/userlevel_admin')) {
			if ($id and $self->{backend}->delete_entry($id)) {
				#success
				$self->add_node($template->node("$self->{template_path}messages/delete_successful.template"));
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/delete_failed.template"));
			}
		} else {
			#permission denied
			$self->add_node($template->node("$self->{template_path}messages/delete_failed_permission_denied.template"));
		}
	} else {
		$self->add_node($form->errors());
	}
}
#= /delete_entry

=head2 show_entries

Shows the guestbook entries.

=cut
sub show_entries {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	
	#calculate range
	my $page  = $Konstrukt::CGI->param('page') || 0;
	$page = 1 unless $page > 0;
	my $count = $Konstrukt::Settings->get('guestbook/entries_per_page');
	my $pages = ceil(($self->{backend}->get_entries_count() || 0) / $count);
	my $start = ($page - 1) * $count;
	
	my $entries = $self->{backend}->get_entries($start, $count);
	if (@{$entries}) {
		my $may_delete = ($self->{user_level}->level() >= $Konstrukt::Settings->get('guestbook/userlevel_admin') ? 1 : 0);
		foreach my $entry (@{$entries}) {
			map { $entry->{$_} = $Konstrukt::Lib->html_escape($entry->{$_}); $entry->{"show_$_"} = length($entry->{$_}) ? 1 : 0; } qw/name email icq aim yahoo jabber msn homepage text/;
			map { $entry->{$_} = sprintf("%02d", $entry->{$_}) } qw/month day hour minute/;
			$entry->{text} = $Konstrukt::Lib->html_paragraphify($entry->{text});
			$entry->{may_delete} = $may_delete;
			$self->add_node($template->node("$self->{template_path}layout/entry.template", { fields => $entry }));
		}
		$self->add_node($template->node("$self->{template_path}layout/entries_nav.template", { prev_page => ($page > 1 ? $page - 1 : 0), next_page => ($page < $pages ? $page + 1 : 0) })) if $pages > 1;
	} else {
		#no entries
		$self->add_node($template->node("$self->{template_path}messages/guestbook_empty.template"));
	}	
}
#= /show_entries

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::guestbook::DBI>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: layout/add_form.form -- >8 --

$form_name = 'add';
$form_specification =
{
	author    => { name => 'Name (mandatory!)'        , minlength => 1, maxlength =>   256, match => '' },
	homepage  => { name => 'Homepage (http://*.*)'    , minlength => 0, maxlength =>   256, match => '(^([hH][tT][tT][pP]\:\/\/)?\S+\.\S+$|^$)' },
	email     => { name => 'Email (name@domain.tld)'  , minlength => 0, maxlength =>   256, match => '(^.+?\@.+\..+$|$^)' },
	jabber    => { name => 'Jabber (name@domain.tld)' , minlength => 0, maxlength =>   256, match => '(^.+?\@.+\..+$|$^)' },
	icq       => { name => 'ICQ (Only digits)'        , minlength => 0, maxlength =>   256, match => '^\d*$' },
	aim       => { name => 'AIM'                      , minlength => 0, maxlength =>   256, match => '' },
	yahoo     => { name => 'Yahoo!'                   , minlength => 0, maxlength =>   256, match => '' },
	msn       => { name => 'MSN'                      , minlength => 0, maxlength =>   256, match => '' },
	text      => { name => 'Text (mandatory!)'        , minlength => 1, maxlength => 65536, match => '' },
};

-- 8< -- textfile: layout/add_form.template -- >8 --

<& formvalidator form="add_form.form" / &>
<div class="guestbook form">
	<h1>Add entry</h1>
	
	<p>Just keep the fields empty for the data you don't want to enter.</p>
	<p>The fields name und ein text are mandatory, though.</p>
	
	<form name="add" action="" method="post" onsubmit="return validateForm(document.add)">
		<input type="hidden" name="action" value="add" />
		
		<label>Name:</label>
		<input name="author"   maxlength="255" />
		<br />
		
		<label>Email:</label>
		<input name="email"    maxlength="255" />
		<br />
		
		<label>Homepage:</label>
		<input name="homepage" maxlength="255" />
		<br />
		
		<label>Jabber:</label>
		<input name="jabber"   maxlength="255" />
		<br />
		
		<label>ICQ:</label>
		<input name="icq"      maxlength="255" />
		<br />
		
		<label>AIM:</label>
		<input name="aim"      maxlength="255" />
		<br />
		
		<label>Yahoo:</label>
		<input name="yahoo"    maxlength="255" />
		<br />
		
		<label>MSN:</label>
		<input name="msn"      maxlength="255" />
		<br />
		
		<label>Text:</label>
		<textarea name="text"></textarea>
		<br />
		
		<& captcha template="/templates/guestbook/layout/add_form_captcha_js.template" / &>
		
		<label>&nbsp;</label>
		<input value="Add!" type="submit" class="submit" />
		<br />
		
	</form>
	
	<p class="clear" />
</div>

-- 8< -- textfile: layout/add_form_captcha.template -- >8 --


<label>Antispam:</label>
<div>
<p>Please type the text '<+$ answer / $+>' into this field:</p>
<input name="captcha_answer" />
<input name="captcha_hash" type="hidden" value="<+$ hash / $+>" />
<br />

-- 8< -- textfile: layout/add_form_captcha_js.template -- >8 --

<script type="text/javascript">
<& perl &>
	#generate encrypted answer
	my $answer  = $template_values->{fields}->{answer};
	my $key     = $Konstrukt::Lib->random_password(8);
	my $enctext = $Konstrukt::Lib->uri_encode($Konstrukt::Lib->xor_encrypt("<input name=\"captcha_answer\" type=\"hidden\" value=\"$answer\" />\n", $key), 1);
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
	<label class="s">Antispam:</label>
	<div>
	<p>Please type the text '<+$ answer / $+>' into this field:</p>
	<input name="captcha_answer" />
	<br />
</noscript>

<input name="captcha_hash" type="hidden" value="<+$ hash / $+>" />

-- 8< -- textfile: layout/delete_form.form -- >8 --

$form_name = 'del';
$form_specification =
{
	id           => { name => 'ID of the entry (number)', minlength => 1, maxlength => 256, match => '^\d+$' },
	confirmation => { name => 'Confirmation'            , minlength => 0, maxlength => 1,   match => '1' },
};

-- 8< -- textfile: layout/delete_form.template -- >8 --

<& formvalidator form="delete_form.form" / &>
<div class="guestbook form">
	<h1>Confirmation: Delete entry</h1>
	
	<p>Shall this entry really be deleted?</p>
	
	<table>
		<colgroup>
			<col width="50" />
			<col width="*" />
		</colgroup>
		<tr><th>Author:</th><td><+$ author / $+></td></tr>
		<tr><th>Text:  </th><td><+$ text / $+></td></tr>
	</table>
	
	<form name="del" action="" method="post" onsubmit="return validateForm(document.del)">
		<input type="hidden" name="action" value="delete" />
		<input type="hidden" name="id"     value="<+$ id / $+>" />
		
		<input id="confirmation" name="confirmation" value="1" type="checkbox" class="checkbox" />
		<label for="confirmation" class="checkbox">Yeah, kill it!</label>
		<br />
		
		<input value="Big red button" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/entries.template -- >8 --

<+@ entries @+>
	<div class="guestbook entry">
		<h1>From <em><+$ name $+>(no name)<+$ / $+></em> on <+$ year $+>????<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> at <+$ hour $+>??<+$ / $+>:<+$ minute $+>??<+$ / $+> <& if condition="<+$ may_delete $+>0<+$ / $+>" &><a href="?action=showdelete;id=<+$ id / $+>">[ delete ]</a><& / &></h1>
		
		<div class="content">
		<+$ text $+>(no text)<+$ / $+>
		</div>
		
		<div class="foot">
			<& if condition="'<+$ show_email    / $+>'" &>Email: <& mail::obfuscator mail="<+$ email / $+>" / &><& / &>
			<& if condition="'<+$ show_homepage / $+>'" &>Web: <a href="<+$ homepage / $+>"><+$ homepage / $+></a><& / &>
			<& if condition="'<+$ show_jabber   / $+>'" &>Jabber: <+$ jabber / $+><& / &>
			<& if condition="'<+$ show_icq      / $+>'" &>ICQ: <+$ icq / $+><& / &>
			<& if condition="'<+$ show_aim      / $+>'" &>AIM: <+$ aim / $+><& / &>
			<& if condition="'<+$ show_yahoo    / $+>'" &>Y!: <+$ yahoo    / $+><& / &>
			<& if condition="'<+$ show_msn      / $+>'" &>MSN: <+$ msn      / $+><& / &>
		</div>
	</div>
<+@ / @+>


-- 8< -- textfile: layout/entries_nav.template -- >8 --

<& if condition="'<+$ prev_page $+>0<+$ / $+>'" &>
	<div style="float: left;">
		<a href="?page=<+$ prev_page $+>0<+$ / $+>">Newer entries</a>
	</div>
<& / &>

<& if condition="'<+$ next_page $+>0<+$ / $+>'" &>
<div style="float: right;">
	<a href="?page=<+$ next_page $+>0<+$ / $+>">Older entries</a>
	</div>
<& / &>

<p class="clear" />

-- 8< -- textfile: layout/entry.template -- >8 --

<div class="guestbook entry">
	<h1>From <em><+$ name $+>(no name)<+$ / $+></em> on <+$ year $+>????<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> at <+$ hour $+>??<+$ / $+>:<+$ minute $+>??<+$ / $+> <& if condition="<+$ may_delete $+>0<+$ / $+>" &><a href="?action=showdelete;id=<+$ id / $+>">[ delete ]</a><& / &></h1>
	
	<div class="content">
	<+$ text $+>(no text)<+$ / $+>
	</div>
	
	<div class="foot">
		<& if condition="'<+$ show_email    / $+>'" &>Email: <& mail::obfuscator mail="<+$ email / $+>" / &><& / &>
		<& if condition="'<+$ show_homepage / $+>'" &>Web: <a href="<+$ homepage / $+>"><+$ homepage / $+></a><& / &>
		<& if condition="'<+$ show_jabber   / $+>'" &>Jabber: <+$ jabber / $+><& / &>
		<& if condition="'<+$ show_icq      / $+>'" &>ICQ: <+$ icq / $+><& / &>
		<& if condition="'<+$ show_aim      / $+>'" &>AIM: <+$ aim / $+><& / &>
		<& if condition="'<+$ show_yahoo    / $+>'" &>Y!: <+$ yahoo    / $+><& / &>
		<& if condition="'<+$ show_msn      / $+>'" &>MSN: <+$ msn      / $+><& / &>
	</div>
</div>

-- 8< -- textfile: messages/add_failed.template -- >8 --

<div class="guestbook message failure">
	<h1>Entry not added</h1>
	<p>An internal error occurred while adding the entry.</p>
</div>

-- 8< -- textfile: messages/add_failed_captcha.template -- >8 --

<div class="guestbook message failure">
	<h1>Entry not added</h1>
	<p>The entry has not been added, because the antispam question hasn't been answered (corretly)!</p>
</div>

-- 8< -- textfile: messages/delete_failed.template -- >8 --

<div class="guestbook message failure">
	<h1>Entry not deleted</h1>
	<p>An internal error occurred while deleting the entry.</p>
</div>

-- 8< -- textfile: messages/delete_failed_permission_denied.template -- >8 --

<div class="guestbook message failure">
	<h1>Entry not deleted</h1> 
	<p>The entry has not been deleted, because only an administrator can delete entries!</p>
</div>

-- 8< -- textfile: messages/delete_successful.template -- >8 --

<div class="guestbook message success">
	<h1>Entry deleted</h1>
	<p>The entry has been deleted successfully!</p>
</div>

-- 8< -- textfile: messages/guestbook_empty.template -- >8 --

<p>No entries yet.</p>

