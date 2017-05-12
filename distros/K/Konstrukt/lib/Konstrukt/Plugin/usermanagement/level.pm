#TODO: how should this plugin be preloaded to register the register/deregister events?
#      maybe the basic plugin should load it (if it knows "somehow", that the level plugin will be used)

=head1 NAME

Konstrukt::Plugin::usermanagement::level - Information about the users (admin) level.

=head1 SYNOPSIS
	
=head2 Tag interface

		<!-- Show a list of all users and forms to change each user's level.
		     This is the default if the "show"-attribute is omitted. -->
		<& usermanagement::level show="users" / &>
		
		<!-- Show the level of the current user.
		     May be useful in conditional templates. -->
		<& usermanagement::level show="level" / &>
		
	
=head2 Perl interface

		my $user_level = use_plugin 'usermanagement::level';
		my $level = $user_level->level();

=head1 DESCRIPTION

User levels:

Every user has an user level, which is represented by a number. The higher
this number ist, the more operations will be allowed to this user.

An user that is not registered/logged in has a level of 0.
A user that has just registered get the user level 1.
The first user that has just registered will get the super user level.

An admin may set the levels of the other users. And the users may do some
operations on the website according to their level.

To view all registered users and change the user level of an other user you
have to be logged in and you must have an user level that ist greater or
equal to the appropriate number defined in your konstrukt.settings:

	usermanagement/level/superuser_level     3

Other plugins may have similar settings as well, which define the needed user
levels to permit special operations.

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
		use_plugin 'usermanagement::level';
	<& / &>
	<& usermanagement::basic show="login, changepass, register, sendpass" / &>

=head1 CONFIGURATION

You have to do some konstrukt.settings-configuration to let the plugin know
where to get its data and which layout to use. Defaults:
	
	#backend
	usermanagement/level/backend         DBI

See the documentation of the backend modules
(e.g. L<Konstrukt::Plugin::usermanagement::level::DBI/CONFIGURATION>) for their configuration.

	#layout
	usermanagement/level/template_path   /templates/usermanagement/level/
	#superuser level
	usermanagement/level/superuser_level 3
	
=cut

package Konstrukt::Plugin::usermanagement::level;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use Konstrukt::Debug;
use Konstrukt::Parser::Node;

=head1 METHODS

=head2 init

Initializes this object. Sets $self->{backend}, $self->{template_path}messages/ and $self->{template_path}layout/.

C<init()> will be called the first time this plugin is needed each request.

=cut
sub init {
	my ($self) = @_;
	
	#dependencies
	$self->{user_basic} = use_plugin 'usermanagement::basic' or return undef;
	
	#set default settings
	$Konstrukt::Settings->default("usermanagement/level/backend"         => 'DBI');
	$Konstrukt::Settings->default("usermanagement/level/template_path"   => '/templates/usermanagement/level/');
	$Konstrukt::Settings->default("usermanagement/level/superuser_level" => 3);

	$self->{backend}       = use_plugin "usermanagement::level::" . $Konstrukt::Settings->get("usermanagement/level/backend") or return undef;
	$self->{template_path} = $Konstrukt::Settings->get('usermanagement/level/template_path');
	
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
	
	my $show = $tag->{tag}->{attributes}->{show} || 'users';
	if ($show eq 'level') {
		$self->add_node($self->level());
	} elsif ($show eq 'users') {
		my $action = $Konstrukt::CGI->param('action');
		if (defined($action)) {
			if ($action eq 'showchange') {
				$self->show_change_level();
			} elsif ($action eq 'change') {
				$self->change_level();
			}
		} else {
			$self->show_users();
		}
	}
	
	return $self->get_nodes();
}
#= /execute

=head2 level

Returns the level level of the specified user. If no user is specified, the
currently logged in user will be used. Returns 0 ist not logged in or user
not existant.

B<Parameters>:

=over

=item * $uid - The user ID

=back

=cut
sub level {
	my ($self, $id) = @_;
	
	$id ||= $self->{user_basic}->id();
	my $level = 0;
	
	if ($id > 0) {
		my $data = $self->{backend}->get_data($id);
		if (defined $data and exists $data->{level}) {
			$level = $data->{level};
		}
	}
	
	return $level;
}
#= /level

=head2 data

Returns all relevant user data as an anonymous hash, if uid exists:

	{ level => ... }

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

=head2 new_user

Creates a new entry for the given user id.

B<Parameters> (optional):

=over

=item * $uid - The user id (optional)

=back

=cut
sub new_user {
	my ($self, $id) = @_;

	if (!$id) {
		$Konstrukt::Debug->error_message("Invalid user ID '$id'") if Konstrukt::Debug::ERROR;
	} else {
		if($self->{backend}->add_user($id)) {
			#first user?
			if (@{$self->{backend}->get_all()} == 1) {
				$self->{backend}->set_level($id, $Konstrukt::Settings->get("usermanagement/level/superuser_level"));
			}
		} else {
			$Konstrukt::Debug->error_message("Couldn't create user! Internal Backend error.") if Konstrukt::Debug::ERROR;
		}
	}
}
#= /new_user

=head2 del_user

Deletes an entry with the given user id.

B<Parameters>:

=over

=item * $uid - The user id

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

=head2 show_users

Returns the Konstrukt-Code to display the existing users.

=cut
sub show_users {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	
	if ($self->level() >= $Konstrukt::Settings->get('usermanagement/level/superuser_level')) {
		my $users = $self->{backend}->get_all();
		my $data = { users => [ map { $_->{email} = $Konstrukt::Lib->html_escape($self->{user_basic}->email($_->{user})); $_ } @{$users} ] };
		$self->add_node($template->node("$self->{template_path}layout/users.template", $data));
	} else {
		$self->add_node($template->node("$self->{template_path}messages/show_failed_permission_denied.template"));
	}
}
#= /show_users

=head2 show_change_level

Returns the Konstrukt-Code to display a form to change the level of a specified user.

=cut
sub show_change_level {
	my ($self) = @_;
	
	my $template = use_plugin 'template';

	if ($self->level() >= $Konstrukt::Settings->get('usermanagement/level/superuser_level')) {
		my $form = use_plugin 'formvalidator';
		$form->load("$self->{template_path}layout/change_show_form.form");
		$form->retrieve_values('cgi');
		
		if ($form->validate()) {
			my $uid = $form->get_value('id');
			my $level = $self->{backend}->get_data($uid)->{level};
			my $email = $Konstrukt::Lib->html_escape($self->{user_basic}->email($uid));
			$self->add_node($template->node("$self->{template_path}layout/change_form.template", { id => $uid, level => $level, email => $email }));
			return 1;
		} else {
			$self->add_node($form->errors());
			return undef;
		}
	}
}

=head2 change_level

Takes the HTTP form input and changes the level for the specified user.

Returns a confirmation of the successful change or error messages otherwise.

B<Parameters>:

=over

=item * $uid - The user whose level should be changed

=item * $level - The new level

=back

=cut
sub change_level {
	my ($self) = @_;

	my $template = use_plugin 'template';
	
	if ($self->level() >= $Konstrukt::Settings->get('usermanagement/level/superuser_level')) {
		my $form = use_plugin 'formvalidator';
		$form->load("$self->{template_path}layout/change_form.form");
		$form->retrieve_values('cgi');
		
		if ($form->validate()) {
			if ($self->{backend}->set_level($form->get_value('id'), $form->get_value('level'))) {
				#change successful
				$self->add_node($template->node("$self->{template_path}messages/change_successful.template"));
				return 1;
			} else {
				#cahange failed
				$self->add_node($template->node("$self->{template_path}messages/change_failed.template"));
				return undef;
			}
		} else {
			$self->add_node($form->errors());
			return undef;
		}
	} else {
		#permission denied
		$self->add_node($template->node("$self->{template_path}messages/change_failed_permission_denied.template"));
		return undef;
	}
}
#= /change_level

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::usermanagement::level::DBI>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: layout/change_form.form -- >8 --

$form_name = 'change';
$form_specification =
{
	id    => { name => 'User ID (number)'   , minlength => 1, maxlength => 8, match => '^\d+$' },
	level => { name => 'User level (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/change_form.template -- >8 --

<& formvalidator form="change_form.form" / &>
<div class="usermanagement form">
	<h1>Change user level</h1>
	
	<form name="change" action="" method="post" onsubmit="return validateForm(document.change)">
		<input type="hidden" name="action" value="change" />
		<input type="hidden" name="id"     value="<+$ id / $+>" />
		
		<label>User:</label>
		<p><+$ email / $+></p>
		<br />
		
		<label>Level:</label>
		<input name="level" maxlength="16" value="<+$ level $+>0<+$ / $+>" />
		<br />
		
		<label>&nbsp;</label>
		<input value="Update!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/change_show_form.form -- >8 --

$form_name = 'changeshow';
$form_specification =
{
	id => { name => 'User ID (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/users.template -- >8 --

<div class="usermanagement levels">
	<h1>Registered users</h1>
	
	<p>This is a list of all registered users.</p>
	<p>To change a users level, just click on the link at the right.</p>
	
	<table>
		<colgroup>
			<col width="*" />
			<col width="100" />
			<col width="100" />
		</colgroup>
		<tr>
			<th>Email adress</th>
			<th>User level</th>
			<th>Change</th>
		</tr>
		<+@ users @+>
		<tr>
			<td><+$ email / $+></td>
			<td><+$ level / $+></td>
			<td><a href="?action=showchange;id=<+$ user $+>0<+$ / $+>">[ change ]</a></td>
		</tr>
		<+@ / @+>
	</table>
</div>

-- 8< -- textfile: messages/change_failed.template -- >8 --

<div class="usermanagement message failure">
	<h1>User level not updated</h1>
	
	<p>An internal error occurred while updating the user level.</p>
</div>

-- 8< -- textfile: messages/change_failed_permission_denied.template -- >8 --

<div class="usermanagement message failure">
	<h1>User level not updated</h1>
	
	<p>The user level has not been updated, because only an authorized administrator can change user levels!</p>
</div>

-- 8< -- textfile: messages/show_failed_permission_denied.template -- >8 --

<div class="usermanagement message failure">
	<h1>No access to the user management</h1>
	
	<p>You cannot access the user management, because only an authorized administrator can do this!</p>
</div>

-- 8< -- textfile: messages/change_successful.template -- >8 --

<div class="usermanagement message success">
	<h1>User level updated</h1>
	
	<p>The user level has been changed successfully</p>
</div>

