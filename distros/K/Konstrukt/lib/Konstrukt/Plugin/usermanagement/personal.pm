#TODO: 

=head1 NAME

Konstrukt::Plugin::usermanagement::personal - Personal information about the user.

=head1 SYNOPSIS
	
=head2 Tag interface

	<& usermanagement::personal / &>
	
=head2 Perl interface

	#get some data:
	my $user_personal = use_plugin 'usermanagement::personal' or die;
	$user_personal->firstname();
	$user_personal->homepage();
	...

=head1 DESCRIPTION

This plugin offers functionality to let each user manage some personal data
of itself.

If the HTTP parameter C<id> is set, the personal information page of the user
with that id will be shown.

Otherwise a form to change the personal information of the user, which is
currently logged in, will be shown.

=head1 DEPENDENCIES

This plugin create a new entry for every newly registered user and deletes it
when the user deregisters.

To know when a user (de)registers, this plugin has to register itself for the
C<registered> and C<deregistered> events, that the
L<basic usermanagement|Konstrukt::Plugin::usermanagement::basic/EVENTS> plugin fires.

So this plugin must be initialized before the basic user management plugin is
executed. For this to happen, you can preload this plugin like this on the page,
where the basic usermanagement is executed:

	<& perl &>
		#preload plugins, which will react on events (register, deregister)
		use_plugin 'usermanagement::personal';
	<& / &>
	<& usermanagement::basic show="login, changepass, register, sendpass" / &>

=head1 CONFIGURATION

You have to do some konstrukt.settings-configuration to let the plugin know
where to get its data and which layout to use. Defaults:
	
	#backend
	usermanagement/basic/backend DBI

See the documentation of the backend modules
(e.g. L<Konstrukt::Plugin::usermanagement::basic::DBI/CONFIGURATION>) for their configuration.

	#layout
	usermanagement/personal/template_path /templates/usermanagement/personal/

=cut

package Konstrukt::Plugin::usermanagement::personal;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use Konstrukt::Debug;

=head1 METHODS

=head2 init

Initializes this object. Sets $self->{backend} and $self->{template_path}

C<init()> will be called the first time this plugin is needed each request.

=cut
sub init {
	my ($self) = @_;
	
	#dependencies
	$self->{user_basic} = use_plugin 'usermanagement::basic' or return undef;

	#set default settings
	$Konstrukt::Settings->default("usermanagement/personal/backend"       => 'DBI');
	$Konstrukt::Settings->default("usermanagement/personal/template_path" => '/templates/usermanagement/personal/');
	
	$self->{backend}       = use_plugin "usermanagement::personal::" . $Konstrukt::Settings->get("usermanagement/basic/backend") or return undef;
	$self->{template_path} = $Konstrukt::Settings->get('usermanagement/personal/template_path');
	
	#register for usermanagement::basic events "registered" and "deregistered"
	$Konstrukt::Event->register("Konstrukt::Plugin::usermanagement::basic::registered",   $self, \&new_user);
	$Konstrukt::Event->register("Konstrukt::Plugin::usermanagement::basic::deregistered", $self, \&del_user);
	
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

=head2 execute_again

Yes, this plugin may return dynamic nodes (i.e. template nodes).

=cut
sub execute_again {
	return 1;
}
#= /execute_again

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

Execute method

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;

	#reset the collected nodes
	$self->reset_nodes();
	
	my $action = $Konstrukt::CGI->param('action');
	if (defined($action)) {
		if ($action eq 'change') {
			$self->change();
		}
	}
	$self->show();
	
	return $self->get_nodes();
}
#= /execute

=head2 data

Returns all relevant user data as an anonymous hash, if uid exists:

   { nick => .., firstname => .., lastname => .., sex => ..,
     birth_year => .., birth_month => .., birth_day => ..,
     email => .., jabber => .., icq => .., aim => .., msn => .., yahoo => .., homepage => ...}

Returns an empty hash if the uid doesn't exist.

B<Parameters> (optional):

=over

=item * $uid - The user id (optional)

=back

=cut
sub data {
	my ($self, $id) = @_;
	
	$id ||= $self->{user_basic}->id();
	return $self->{backend}->get_data($id);
}
#= /data

=head2 get

Returns a specified personal information field for a specified user, if the
uid exists, undef otherwise.

B<Parameters>:

=over

=item * $uid - The user ID

=item * $field - The requested personal information field, e.g. "firstname", "nick", ...

=back

=cut
sub get {
	my ($self, $id, $field) = @_;
	my $data = $self->data($id);
	return (exists($data->{$field}) ? $data->{$field} : undef);
}
#= /get

=head2 get wrappers

For an easier access to the data fields of an user you may also use these wapper
methods:

=over

=item * firstname($uid)

=item * lastname($uid)

=item * nick($uid)

=item * sex($uid)

=item * birth_year($uid)

=item * birth_month($uid)

=item * birth_day($uid)

=item * jabber($uid)

=item * icq($uid)

=item * aim($uid)

=item * msn($uid)

=item * yahoo($uid)

=item * homepage($uid)

=back

=cut
#= Some wrappers around get()
sub firstname   { return $_[0]->get($_[1], 'firstname');   }
sub lastname    { return $_[0]->get($_[1], 'lastname');    }
sub nick        { return $_[0]->get($_[1], 'nick');        }
sub sex         { return $_[0]->get($_[1], 'sex');         }
sub birth_year  { return $_[0]->get($_[1], 'birth_year');  }
sub birth_month { return $_[0]->get($_[1], 'birth_month'); }
sub birth_day   { return $_[0]->get($_[1], 'birth_day');   }
sub jabber      { return $_[0]->get($_[1], 'jabber');      }
sub icq         { return $_[0]->get($_[1], 'icq');         }
sub aim         { return $_[0]->get($_[1], 'aim');         }
sub msn         { return $_[0]->get($_[1], 'msn');         }
sub yahoo       { return $_[0]->get($_[1], 'yahoo');       }
sub homepage    { return $_[0]->get($_[1], 'homepage');    }
#= /Some wrappers

=head2 set

Sets the data specified in the passed hash in the database

B<Parameters>:

=over

=item * $uid - The user ID

=item * $data - Hashreference with the data that should be set:
	{ firstname => .., nick => .., ... }

=back

=cut
sub set { $_[0]->{backend}->set_data(@_); }
#= /set

=head2 new_user

Creates a new entry for the given user id.

B<Parameters>:

=over

=item * $uid - The user ID

=back

=cut
sub new_user {
	my ($self, $id) = @_;

	if (!$id) {
		$Konstrukt::Debug->error_message("Invalid user ID '$id'") if Konstrukt::Debug::ERROR;
		return undef;
	} else {
		return $self->{backend}->add_user($id);
	}
}
#= /new_user

=head2 del_user

Deletes an entry with the given user id.

B<Parameters>:

=over

=item * $uid - The user ID

=back

=cut
sub del_user {
	my ($self, $id) = @_;

	if (!$id) {
		$Konstrukt::Debug->error_message("Invalid user ID '$id'") if Konstrukt::Debug::ERROR;
		return undef;
	} else {
		return $self->{backend}->delete_user($id);
	}
}
#= /del_user

=head2 show

Shows the personal information of the user, whose id has been specified via
HTTP, or of the current user, if no user id is specified.
Only the user itself may change the user data.

Displays the form with the personal user information.

=cut
sub show {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/show_form.form");
	$form->retrieve_values('cgi');
	
	my $id;
	if ($form->validate()) {
		$id = $form->get_value('id');
	} else {
		$id = $self->{user_basic}->id();
	}
	
	if ($id) {
		#get data
		my $data = $self->data($id);
		$data->{id} = $id;
		#escape values
		map { $data->{$_} = $Konstrukt::Lib->html_escape($data->{$_}); $data->{"${_}_defined"} = 1 if defined $data->{$_}; } qw/nick firstname lastname email jabber icq aim msn yahoo homepage/;
		#use change_form.template, if the user may edit the data, show.template otherwise
		$self->add_node($template->node("$self->{template_path}layout/" . ($id == $self->{user_basic}->id() ? 'change' : 'show') . ".template", { fields => $data }));
		return 1;
	} else {
		$self->add_node($template->node("$self->{template_path}messages/not_logged_in.template"));
		return undef;
	}
}
#= /show

=head2 change

Changes the personal information specified in an HTTP POST request.

Returns a confirmation of the successful userdata change or error messages otherwise.

=cut
sub change {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	my $log      = use_plugin 'log';
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/change_form.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $id = $form->get_value('id');
		if ($id == $self->{user_basic}->id()) {
			my $set = {};
			map { $set->{$_} = $form->get_value($_) } qw/firstname lastname nick sex birth_year birth_month birth_day email jabber icq aim msn yahoo homepage/;
			if ($self->{backend}->set_data($id, $set)) {
				$log->put(__PACKAGE__ . '->change', $self->{user_basic}->email() . " changed its personal user information.", $self->{user_basic}->email(), $self->{user_basic}->id());
				$self->add_node($template->node("$self->{template_path}messages/change_successful.template"));
				return 1;
			} else {
				$self->add_node($template->node("$self->{template_path}messages/change_failed.template"));
				return undef;
			}
		} else {
			$self->add_node($template->node("$self->{template_path}messages/change_failed_permission_denied.template"));
			return undef;
		}
	} else {
		$self->add_node($form->errors());
		return undef;
	}
}
#= /change

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::usermanagement::personal::DBI>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: layout/change.template -- >8 --

<& formvalidator form="change_form.form" / &>
<div class="usermanagement form">
	<h1>Change personal data</h1>
	
	<p>All information but the nickname is optional. You can simply leave the fields empty, if you don't want to specify the information.</p>
	
	<form name="change" action="" method="post" onsubmit="return validateForm(document.change)">
		<input type="hidden" name="action" value="change" />
		<input type="hidden" name="id"     value="<+$ id $+>0<+$ / $+>" />
		
		<fieldset>
			<legend>Personal information</legend>
			
			<label>Nickname:</label>
			<input name="nick" maxlength="255" value="<+$ nick / $+>" />
			<br />
			
			<label>Fist name:</label>
			<input name="firstname" maxlength="255" value="<+$ firstname / $+>" />
			<br />
			
			<label>Last name:</label>
			<input name="lastname" maxlength="255" value="<+$ lastname / $+>" />
			<br />
			
			<label>Birthday:</label>
			<input name="birth_year" class="xxs" maxlength="4" value="<+$ birth_year / $+>" />
			<span class="inline">-</span>
			<input name="birth_month" class="xxs" maxlength="2" value="<+$ birth_month / $+>" />
			<span class="inline">-</span>
			<input name="birth_day" class="xxs" maxlength="2" value="<+$ birth_day / $+>" />
			<br />
			
			<label>Sex:</label>
			<select name="sex">
				<option value="0">(not set)</option>
				<option value="1" <& if condition="'<+$ sex $+>0<+$ / $+>' eq '1'" &>selected="selected"<& / &>>Male</option>
				<option value="2" <& if condition="'<+$ sex $+>0<+$ / $+>' eq '2'" &>selected="selected"<& / &>>Female</option>
			</select>
			<br />
		</fieldset>
		
		<fieldset>
			<legend>Contact information</legend>
			
			<label>Email address:</label>
			<input name="email" maxlength="255" value="<+$ email / $+>" />
			<br />
			
			<label>Jabber ID:</label>
			<input name="jabber" maxlength="255" value="<+$ jabber / $+>" />
			<br />
			
			<label>ICQ number:</label>
			<input name="icq" maxlength="16" value="<+$ icq / $+>" />
			<br />
			
			<label>AIM screenname:</label>
			<input name="aim" maxlength="255" value="<+$ aim / $+>" />
			<br />
			
			<label>Yahoo! address:</label>
			<input name="yahoo" maxlength="255" value="<+$ yahoo / $+>" />
			<br />
			
			<label>MSN screenname:</label>
			<input name="msn" maxlength="255" value="<+$ msn / $+>" />
			<br />
			
			<label>Homepage:</label>
			<input name="homepage" maxlength="255" value="<+$ homepage / $+>" />
			<br />
		</fieldset>
		
		<fieldset>
			<legend>Submit</legend>
			
			<label>&nbsp;</label>
			<input value="Update!" type="submit" class="submit" />
			<br />
		</fieldset>
		
	</form>
</div>

-- 8< -- textfile: layout/change_form.form -- >8 --

$form_name = 'change';
$form_specification =
{
	id          => { name => 'User-ID (number)'        , minlength => 1, maxlength =>   8, match => '^\d+$' },
	nick        => { name => 'Nick (not empty)'        , minlength => 1, maxlength => 256, match => '' },
	firstname   => { name => 'First name'              , minlength => 0, maxlength => 256, match => '' },
	lastname    => { name => 'Last name'               , minlength => 0, maxlength => 256, match => '' },
	birth_day   => { name => 'Day (0-31)'              , minlength => 0, maxlength =>   2, match => '^(|[012]?\d|3[01])$' },
	birth_month => { name => 'Month (0-12)'            , minlength => 0, maxlength =>   2, match => '^(|0?\d|1[012])$' },
	birth_year  => { name => 'Year (19xx/20xx)'        , minlength => 0, maxlength =>   4, match => '^(|19\d\d|20\d\d)$' },
	sex         => { name => 'Sex'                     , minlength => 0, maxlength =>   1, match => '' },
	email       => { name => 'Email (name@domain.tld)' , minlength => 0, maxlength => 256, match => '^(.+?\@.+\..+|)$' },
	jabber      => { name => 'Jabber (name@domain.tld)', minlength => 0, maxlength => 256, match => '^(.+?\@.+\..+|)$' },
	icq         => { name => 'ICQ (number)'            , minlength => 0, maxlength =>  16, match => '^\d*$' },
	aim         => { name => 'AIM'                     , minlength => 0, maxlength => 256, match => '' },
	msn         => { name => 'MSN'                     , minlength => 0, maxlength => 256, match => '' },
	yahoo       => { name => 'Yahoo!'                  , minlength => 0, maxlength => 256, match => '' },
	homepage    => { name => 'Homepage (http://*.*)'   , minlength => 0, maxlength => 256, match => '^([hH][tT][tT][pP]\:\/\/\S+\.\S+|)$' },
};

-- 8< -- textfile: layout/show.template -- >8 --

<& formvalidator form="change_form.form" / &>
<div class="usermanagement personal">
	<h1>View personal information</h1>
	
	<table>
		<colgroup>
			<col width="150" />
			<col width="550" />
		</colgroup>
			<tr><th colspan="2">Personal information</th></tr>
			<tr><td>Nickname:        </td><td><+$ nick      $+>(not set)<+$ / $+></td></tr>
			<tr><td>First name:      </td><td><+$ firstname $+>(not set)<+$ / $+></td></tr>
			<tr><td>Last name:       </td><td><+$ lastname  $+>(not set)<+$ / $+></td></tr>
			<tr><td>Birthday:        </td><td><+$ birth_year $+>????<+$ / $+>-<+$ birth_month $+>??<+$ / $+>-<+$ birth_day $+>??<+$ / $+></td></tr>
			<tr><td>Sex:             </td><td><& perl &>
				my $sex = '<+$ sex $+>0<+$ / $+>';
				if    ($sex == 1) { print 'Male'; }
				elsif ($sex == 2) { print 'Female'; }
				else              { print '(not set)'; }
			<& / &></td></tr>
			<tr><th colspan="2">Contact information</th></tr>
			<tr><td>Email address:  </td><td><& if condition="<+$ email_defined $+>0<+$ / $+>" &>
				<$ then $><a href="mailto:<+$ email / $+>"><+$ email / $+></a><$ / $>
				<$ else $>(not set)<$ / $>
			<& / &></td></tr>
			<tr><td>Jabber ID:       </td><td><+$ jabber    $+>(not set)<+$ / $+></td></tr>
			<tr><td>ICQ number:      </td><td><+$ icq       $+>(not set)<+$ / $+></td></tr>
			<tr><td>AIM screenname:  </td><td><+$ aim       $+>(not set)<+$ / $+></td></tr>
			<tr><td>Yahoo! address:  </td><td><+$ yahoo     $+>(not set)<+$ / $+></td></tr>
			<tr><td>MSN screenname:  </td><td><+$ msn       $+>(not set)<+$ / $+></td></tr>
			<tr><td>Homepage:        </td><td><& if condition="<+$ homepage_defined $+>0<+$ / $+>" &>
				<$ then $><a href="<+$ homepage  / $+>"><+$ homepage / $+></a><$ / $>
				<$ else $>(not set)<$ / $>
			<& / &></td></tr>
		</form>
	</table>
</div>

-- 8< -- textfile: layout/show_form.form -- >8 --

$form_name = 'changeshow';
$form_specification =
{
	id => { name => 'User ID (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: messages/change_failed.template -- >8 --

<div class="usermanagement message failure">
	<h1>Personal information not changed</h1>
	<p>An internal error occurred while updating your personal information</p>
</div>

-- 8< -- textfile: messages/change_failed_permission_denied.template -- >8 --

<div class="usermanagement message failure">
	<h1>Personal information not changed</h1>
	<p>The personal information has not been updated, because only the person itself can change its personal data!</p>
</div>

-- 8< -- textfile: messages/change_successful.template -- >8 --

<div class="usermanagement message success">
	<h1>Personal information updated</h1>
	<p>Your personal information has been updated successfully</p>
</div>

-- 8< -- textfile: messages/not_logged_in.template -- >8 --

<div class="usermanagement message failure">
	<h1>Not logged in</h1>
	<p>The personal information can only be changed if you are logged in</p>
</div>

