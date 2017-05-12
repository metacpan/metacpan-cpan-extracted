#TODO: send password: parse customizable mail with template
#TODO: currently only working on apache mod_perl! (r->{...})

=head1 NAME

Konstrukt::Plugin::usermanagement::basic - Basic user management.

=head1 SYNOPSIS
	
=head2 Tag interface

	<!-- example for a page for basic user management.
	     "login, register, sendpass, changepass" is the default, so you can
	     also omit the "show"-attribute. -->
	<& usermanagement::basic show="login, register, sendpass, changepass" / &>
	
	<!-- only show login -->
	<& usermanagement::basic show="login" / &>

=head2 Perl interface

	my $user_basic = use_plugin 'usermanagement::basic' or die;
	my $id = $user_basic->id(); #will return the user's id, if logged in. 0 otherwise
	$user_basic->data($id); #will return { email => ..}
	#of the user with the given id
	$user_basic->email($id); #will return the users email address
	#...

=head1 DESCRIPTION

This Konstrukt plugin provides basic user management functionality.

It will care for persistence by using the Konstrukt session management and it
allows other plugins to access basic user data like the users id, if logged in.
	
	my $user_basic = use_plugin 'usermanagement::basic' or die;
	my $id = $user_basic->id(); #will return the user's id, if logged in. 0 otherwise
	$user_basic->data($id); #will return { email => ..}
	#of the user with the given id
	$user_basic->email($id); #will return the users email address
	
It may also be used for user athentication on your website to provide log-in/
log-out-screens etc:
	
	<& usermanagement::basic show="login, register, sendpass, changepass" / &>
	
The "login"-form will enable the user to log in with its email/password if not
logged in or a log-off button otherwise.

The "register"-form will enable the user to register itself with its email
for the service. A random password will be generated and sent to the given
email address.

The "sendpass"-form will enable the user to get its password sent to its
email address.

The "changepass"-form will enable the user to change its password.

Disabling some forms will let you split the forms into several pages.

=head1 EVENTS

This plugin triggers these L<events|Konstrukt::Event>:

=over

=item * C<Konstrukt::Plugin::usermanagement::basic::registered>

=item * C<Konstrukt::Plugin::usermanagement::basic::deregistered>

=back

Each with the user id as an argument. So your plugin might register for those
events, if it wants to react on these events.

=head1 CONFIGURATION
	
You have to do some konstrukt.settings-configuration to let the plugin know
where to get its data and which layout to use:
		
	#backend
	usermanagement/basic/backend       DBI

See the documentation of the backend modules
(e.g. L<Konstrukt::Plugin::usermanagement::basic::DBI/CONFIGURATION>) for their configuration.

	#layout
	usermanagement/basic/template_path /templates/usermanagement/basic/

=cut

package Konstrukt::Plugin::usermanagement::basic;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use Konstrukt::Debug;
use Konstrukt::Session;

use Digest::SHA;

=head1 METHODS

=head2 init

Initializes this object. Sets $self->{backend} and $self->{template_path}.

C<init()> will be called the first time this plugin is needed each request.

=cut
sub init {
	my ($self) = @_;
	
	#depends on session management
	unless ($Konstrukt::Session->activated()) {
		$Konstrukt::Debug->error_message("Cannot initialize because the session management seems to be deactivated");
		return undef;
	}
	
	#set default settings
	$Konstrukt::Settings->default("usermanagement/basic/backend"       => 'DBI');
	$Konstrukt::Settings->default("usermanagement/basic/template_path" => '/templates/usermanagement/basic/');
	
	$self->{backend}       = use_plugin "usermanagement::basic::" . $Konstrukt::Settings->get("usermanagement/basic/backend") or return undef;
	$self->{template_path} = $Konstrukt::Settings->get('usermanagement/basic/template_path');
	
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

	my $action  = $Konstrukt::CGI->param('action');
	my $uid     = $self->id();
	
	#default: show all
	$tag->{tag}->{attributes}->{show} = 'login, register, sendpass, changepass'
		unless defined $tag->{tag}->{attributes}->{show};
	
	#grab "show" tag attributes
	my $show = {};
	foreach my $key (split /\s*,\s*/, $tag->{tag}->{attributes}->{show}) {
		$show->{lc($key)} = 1;
	}
	
	#phase 1: work
	#process the passed action. show the messages
	if (defined $action) {
		if ($action eq 'logout' and $show->{login} and $uid) {
			$self->logout();
		} elsif ($action eq 'login' and $show->{login}) {
			$self->login();
		} elsif ($action eq 'deregister' and $show->{register} and $uid) {
			$self->deregister();
		} elsif ($action eq 'register' and $show->{register}) {
			$self->register();
		} elsif ($action eq 'sendpass' and $show->{sendpass} and !$uid) {
			$self->sendpass();
		} elsif ($action eq 'changepass' and $show->{changepass} and $uid) {
			$self->changepass();
		}
	}
	
	#this one may have changed within the processes above
	$uid = $self->id();
	
	#phase 2: show
	#display the forms
	if ($show->{login}) {
		if ($uid) {
			$self->logout_show();
		} else {
			$self->login_show();
		}
	}
	if ($show->{register}) {
		if ($uid) {
			$self->deregister_show();
		} else {
			$self->register_show();
		}
	}
	if ($show->{sendpass} and !$uid) {
		$self->sendpass_show();
	}
	if ($show->{changepass} and $uid) {
		$self->changepass_show();
	}
	
	return $self->get_nodes();
}
#= /execute

=head2 register_show

Displays the register form.

=cut
sub register_show {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	$self->add_node($template->node("$self->{template_path}layout/registration_form.template"));
	
	return 1;
}
#= &/register_show

=head2 register

Takes the HTTP form input and tries to register a new user.
The user will be added to the database and an email will be sent to the users
email address.

Returns a confirmation of the successful registration or error messages otherwise

=cut
sub register {
	my ($self) = @_;

	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/registration_form.form");
	$form->retrieve_values('cgi');
	my $log = use_plugin 'log';
		
	if ($form->validate()) {
		my $email    = $form->get_value('email');
		my $rv       = $self->{backend}->register($email);
		my $template = use_plugin 'template';
		if ($rv > 0) {
			#success. $rv is the user id
			$log->put(__PACKAGE__ . '->register', "$email registered with user id $rv.", $email, $rv);
			$Konstrukt::Event->trigger("Konstrukt::Plugin::usermanagement::basic::registered", $rv);
			$self->add_node($template->node("$self->{template_path}messages/registration_successful.template"));
			$self->sendpass($email);
			return 1;
		} else {
			#failed
			if ($rv == -1) {
				#email address already exists in the database
				$self->add_node($template->node("$self->{template_path}messages/registration_failed_email_exists.template", { email => $email }));
				return 1;
			} else {
				$self->add_node($template->node("$self->{template_path}messages/registration_failed.template"));
				return undef;
			}
		}
	} else {
		$self->add_node($form->errors());
		return undef;
	}
}
#= /register

=head2 deregister_show

Displays the deregister form.

=cut
sub deregister_show {
	my ($self) = @_;

	my $template = use_plugin 'template';
	$self->add_node($template->node("$self->{template_path}layout/deregistration_form.template"));
	
	return 1;
}
#= &/deregister_show

=head2 deregister

Takes the HTTP form input and tries to deregister an existing user.
The user will be removed from the database.

Returns a confirmation of the successful deregistration or error messages otherwise

=cut
sub deregister {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	my $log      = use_plugin 'log';
	
	if ($Konstrukt::CGI->param('confirmation')) {
		my $uid     = $self->id();
		my $email   = $self->email($uid);
		my $success = $self->{backend}->deregister($uid);
		if ($success) {
			$Konstrukt::Session->set('user_id', 0);
			$log->put(__PACKAGE__ . '->deregister', $email . " with user $uid deregistered.", $email, $uid);
			$Konstrukt::Event->trigger("Konstrukt::Plugin::usermanagement::basic::deregistered", $uid);
			$self->add_node($template->node("$self->{template_path}messages/deregistration_successful.template"));
			return 1;
		} else {
			$self->add_node($template->node("$self->{template_path}messages/deregistration_failed.template"));
			return undef;
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/deregistration_failed_not_confirmed.template"));
		return undef;
	}
}
#= /deregister

=head2 login_show

Displays the login form.

=cut
sub login_show {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	$self->add_node($template->node("$self->{template_path}layout/login_form.template"));
	
	return 1;
}
#= /login_show

=head2 login

Takes the HTTP form input and tries to login the user.
The user id will be saved inside the session.

Returns a confirmation of the successful login or error messages otherwise.

B<Parameters>:

=over

=item * $email - Optional: Username

=item * $pass - Optional: Password

=back

=cut
sub login {
	my ($self, $email, $pass) = @_;
	
	my $template = use_plugin 'template';
	my $log      = use_plugin 'log';
	
	if (!$email or !$pass) {
		#get data from input form
		my $form = use_plugin 'formvalidator';
		$form->load("$self->{template_path}layout/login_form.form");
		$form->retrieve_values('cgi');
		if (!$form->validate()) {
			$self->add_node($form->errors());
			return undef;
		} else {
			$email = $form->get_value('email');
			$pass  = $form->get_value('pass');
		}
	}
	
	if ($email and $pass) {
		#check login
		my $pass  = Digest::SHA->new(256)->add($pass)->hexdigest();
		my $uid   = $self->{backend}->check_login($email, $pass);
		if ($uid) {
			#login successful
			$Konstrukt::Session->set('user_id', $uid);
			$Konstrukt::Session->set('failed_logins', 0);
			$log->put(__PACKAGE__ . '->login', $email . ' logged in.', $email, $uid);
			$self->add_node($template->node("$self->{template_path}messages/login_successful.template"));
			return 1;
		} else {
			#login failed
			$Konstrukt::Session->set('failed_logins', ($Konstrukt::Session->get('failed_logins') || 0) + 1);
			$log->put(__PACKAGE__.'->login', $email . ' entered the wrong password 3 times in a row.', $email, $uid) if $Konstrukt::Session->get('failed_logins') == 3;
			$self->add_node($template->node("$self->{template_path}messages/login_failed.template"));
			return undef;
		}
	} else {
		#login failed
		$self->add_node($template->node("$self->{template_path}messages/login_failed.template"));
		return undef;
	}
}
#= /login

=head2 logout_show

Displays the logout form.

=cut
sub logout_show {
	my ($self) = @_;

	my $template = use_plugin 'template';
	$self->add_node($template->node("$self->{template_path}layout/logout_form.template", { email => $self->email() }));
	
	return 1;
}

=head2 logout

Logs out the current user. The user id will be removed from the session.

=cut
sub logout {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	$Konstrukt::Session->set('user_id', 0);
	$self->add_node($template->node("$self->{template_path}messages/logout_successful.template", { email => $self->email() }));

	return 1;
}
#= /logout

=head2 sendpass_show

Displays the "send password" form.

=cut
sub sendpass_show {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	$self->add_node($template->node("$self->{template_path}layout/send_password_form.template"));
	
	return 1;
}
#= /sendpass_show

=head2 sendpass

Generates a new password for the user and sends an email with the password to the user.
The email address may be passed as a parameter to this sub. If not passed, it
will be received from the HTTP parametes.

Returns a confirmation of the successfully sent email or error messages otherwise.

B<Parameters>:

=over

=item * $email - Optional: The email address of the user to whom the pass should be sent

=back

=cut
sub sendpass {
	my ($self, $email) = @_;
	
	my $template = use_plugin 'template';
	my $log      = use_plugin 'log';
	
	if (!$email) {
		#get email from input form
		my $form = use_plugin 'formvalidator';
		$form->load("$self->{template_path}layout/send_password_form.form");
		$form->retrieve_values('cgi');
		if (!$form->validate()) {
			$self->add_node($form->errors());
			return undef;
		} else {
			$email = $form->get_value('email');
		}
	}
	
	my $uid = $self->{backend}->get_id_from_email($email);
	if ($uid) {
		#get some user info
		my $email      = $self->email($uid);
		#generate new password
		my $plain_pass = $Konstrukt::Lib->random_password(12);
		my $pass       = Digest::SHA->new(256)->add($plain_pass)->hexdigest();
		$self->{backend}->set_password($uid, $pass);
		#generate and send mail
		my $mailfile   = $Konstrukt::File->read("$self->{template_path}layout/send_password_mail.email");
		if (defined($mailfile)) {
			my $mail;
			eval($mailfile);
			#Check for errors
			if ($@) {
				#Errors in eval
				chomp($@);
				$Konstrukt::Debug->error_message("Error while loading mail template '$self->{template_path}layout/send_password_mail.email'! $@") if Konstrukt::Debug::ERROR;
				$self->add_node($template->node("$self->{template_path}messages/send_password_failed.template"));
				return 0;
			} else {
				$mail->{body} =~ s/\$pass\$/$plain_pass/gi;
				$mail->{body} =~ s/\$email\$/$email/gi;
				if ($Konstrukt::Lib->mail($mail->{subject}, $mail->{body}, $email)) {
					$log->put(__PACKAGE__ . '->sendpass', "$email got a new password sent.", $email);
					$self->add_node($template->node("$self->{template_path}messages/send_password_successful.template", { email => $email }));
					return 1;
				} else {
					$self->add_node($template->node("$self->{template_path}messages/send_password_failed.template"));
					return 0;
				}
			}
		} else {
			$self->add_node($template->node("$self->{template_path}messages/send_password_failed.template"));
			return 0;
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/send_password_failed.template"));
		return 0;
	}
}
#= /sendpass

=head2 changepass_show

Displays the "change password" form.

=cut
sub changepass_show {
	my ($self) = @_;

	my $template = use_plugin 'template';
	$self->add_node($template->node("$self->{template_path}layout/change_password_form.template"));
	
	return 1;
}

=head2 changepass

Changes the password of the user that is currently logged in.
The old password will be checked and the new ones must be identical.
The parameters are optional. They will be received from HTTP parameters,
if not specified.

Returns a confirmation of the successful password change or error messages otherwise.

B<Parameters> (optional):

=over

=item * $old_pass - The old password.

=item * $new_pass - The new password.

=item * $new_pass2 - The new password (confirmation).

=back

=cut
sub changepass {
	my ($self, $old_pass, $new_pass, $new_pass2) = @_;
	
	my $template = use_plugin 'template';
	my $log      = use_plugin 'log';

	if (!($old_pass and $new_pass and $new_pass2)) {
		my $form = use_plugin 'formvalidator';
		$form->load("$self->{template_path}layout/change_password_form.form");
		$form->retrieve_values('cgi');
		if (!$form->validate()) {
			$self->add_node($form->errors());
			return undef;
		} else {
			$old_pass  = $form->get_value('old_pass');
			$new_pass  = $form->get_value('new_pass');
			$new_pass2 = $form->get_value('new_pass2');
		}
	}
	
	$old_pass  = Digest::SHA->new(256)->add($old_pass)->hexdigest();
	$new_pass  = Digest::SHA->new(256)->add($new_pass)->hexdigest();
	$new_pass2 = Digest::SHA->new(256)->add($new_pass2)->hexdigest();
	my $uid = $self->id();
	my $userdata = $self->{backend}->get_data($uid);
	if ($old_pass eq $userdata->{password}) {
		if ($new_pass eq $new_pass2) {
			if ($self->{backend}->set_password($uid, $new_pass)) {
				$log->put(__PACKAGE__.'->changepass', $userdata->{email} . " changed its password.", $userdata->{email});
				$self->add_node($template->node("$self->{template_path}messages/change_password_successful.template"));
				return 1;
			} else {
				$self->add_node($template->node("$self->{template_path}messages/change_password_failed.template"));
				return undef;
			}
		} else {
			$self->add_node($template->node("$self->{template_path}messages/change_password_failed_unmatched.template"));
			return undef;
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/change_password_failed_wrong_pass.template"));
		return undef;
	}
}
#= /changepass

=head2 id

Returns the user id of the user, which is currently logged in, 0 if not logged in.

=cut
sub id {
	my ($self) = @_;
	return $Konstrukt::Session->get('user_id') || 0;
}
#= /id

=head2 email

Returns the user's email address, if uid exists, undef otherwise.

=cut
sub email {
	my ($self, $id) = @_;
	
	$id ||= $self->id();
	my $data = $self->data($id);
	return (exists($data->{email}) ? $data->{email} : undef);
}
#= /email

=head2 data

Returns all relevant user data as an anonymous hash, if uid exists:

	{ email => 'a@b.c', pass => '<hash>' }

Returns an empty hash if the uid doesn't exist.

B<Parameters> (optional):

=over

=item * $uid - The user id (optional)

=back

=cut
sub data {
	my ($self, $id) = @_;
	
	$id ||= $self->id();
	return $self->{backend}->get_data($id);
}
#= /data

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::usermanagement::basic::DBI>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: layout/change_password_form.form -- >8 --

$form_name = 'changepass';
$form_specification =
{
	old_pass  => { name => 'Old password (not empty)'   , minlength => 1, maxlength => 256, match => '' },
	new_pass  => { name => 'New password (not empty)'   , minlength => 1, maxlength => 256, match => '' },
	new_pass2 => { name => 'New password (confirmation)', minlength => 1, maxlength => 256, match => '' },
};

-- 8< -- textfile: layout/change_password_form.template -- >8 --

<& formvalidator form="change_password_form.form" / &>
<script type="text/javascript">
<!--
function checkChangePassForm() {
	var ok = validateForm(document.changepass);
	if (ok && (document.changepass.new_pass.value != document.changepass.new_pass2.value)) {
		alert("The passwords do not match!");
		document.changepass.new_pass.focus();
		ok = false;
	}
	return ok;
}
// -->
</script>
<div class="usermanagement form">
	<h1>Change password</h1>
	
	<p>Empty passwords are not allowed!</p>
	<p>For the technically minded: The passwords are stored as a SHA-256 hash. There is not much reason for paranoia. And no, the passwords don't get logged...</p>
	<form name="changepass" action="" method="post" onsubmit="return checkChangePassForm()">
		<input type="hidden" name="action" value="changepass" />
		
		<label>Old password:</label>
		<input name="old_pass" type="password" maxlength="255" />
		<br />
		
		<label>New password:</label>
		<input name="new_pass" type="password" maxlength="255" />
		<br />
		
		<label>New password (confirmation):</label>
		<input name="new_pass2" type="password" maxlength="255" />
		<br />
		
		<label>&nbsp;</label>
		<input value="Update password!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/deregistration_form.form -- >8 --

$form_name = 'deregister';
$form_specification =
{
	confirmation => { name => 'Confirmation of deregistration', minlength => 0, maxlength => 1, match => '1' },
};

-- 8< -- textfile: layout/deregistration_form.template -- >8 --

<& formvalidator form="deregistration_form.form" / &>
<div class="usermanagement form">
	<h1>Deregistration</h1>
	
	<p>If you don't need your user account anymore, you can deregister yourself of course. All your user data will be deleted.</p>
	
	<form name="deregister" action="" method="post" onsubmit="return validateForm(document.deregister)">
		<input type="hidden" name="action" value="deregister" />
		
		<input id="confirmation" name="confirmation" type="checkbox" class="checkbox" value="1" />
		<label for="confirmation" class="checkbox">Yes, I'm really sure, blabla, GO AWAY!</label>
		<br />
		
		<input value="Bye, bye!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/login_form.form -- >8 --

$form_name = 'login';
$form_specification =
{
	email => { name => 'Email address (name@domain.tld)', minlength => 1, maxlength => 256, match => '^.+?\@.+\..+$' },
	pass  => { name => 'password (not empty)'           , minlength => 1, maxlength => 256, match => '' },
};

-- 8< -- textfile: layout/login_form.template -- >8 --

<& formvalidator form="login_form.form" / &>
<div class="usermanagement form">
	<h1>Log in</h1>
	
	<form name="login" action="" method="post" onsubmit="return validateForm(document.login)">
		<input type="hidden" name="action" value="login" />
		
		<label>Email address:</label>
		<input name="email" maxlength="255" />
		<br />
		
		<label>Password:</label>
		<input name="pass" type="password" maxlength="255" />
		<br />
		
		<label>&nbsp;</label>
		<input value="Log in!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/logout_form.template -- >8 --

<div class="usermanagement form">
	<h1>Log out</h1>
	
	<p>You are logged in with the email address <em>'<+$ email / $+>'</em>.</p>
	<form name="logout" action="" method="post">
		<input type="hidden" name="action" value="logout" />
		
		<input value="Log out!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/registration_form.form -- >8 --

$form_name = 'register';
$form_specification =
{
	email => { name => 'Email address (name@domain.tld)', minlength => 1, maxlength => 256, match => '^.+?\@.+\..+$' },
};

-- 8< -- textfile: layout/registration_form.template -- >8 --

<& formvalidator form="registration_form.form" / &>
<div class="usermanagement form">
	<h1>Register</h1>
	
	<p>You may create a user account, to use some advanced functions of this site. For example you can write blog entries or manage bookmarks and appointments when your account has been activated for this functions.</p>
	<p>All you need for registration is a valid email address.</p>
	<p>After the registration you'll get an initial password sent to your email address. After the login you can change your password and your personal data.</p>
	<p>Note that this email address will only be used internally and will not be published! If you want to publish your email address to other users, you can add it to your personal data page.</p>
	
	<form name="register" action="" method="post" onsubmit="return validateForm(document.register)">
		<input type="hidden" name="action" value="register" />
		
		<label>Email address:</label>
		<input name="email" maxlength="255" />
		<br />
		
		<label>&nbsp;</label>
		<input value="Register!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/send_password_form.form -- >8 --

$form_name = 'sendpass';
$form_specification =
{
	email => { name => 'Email address (name@domain.tld)', minlength => 1, maxlength => 256, match => '^.+?\@.+\..+$' },
};

-- 8< -- textfile: layout/send_password_form.template -- >8 --

<& formvalidator form="send_password_form.form" / &>
<div class="usermanagement form">
	<h1>Send password</h1>
	
	<p>If you lost your password, you can get a new one sent to your email address</p>
	<p>This new password can be changed later, of course</p>
	
	<form name="sendpass" action="" method="post" onsubmit="return validateForm(document.sendpass)">
		<input type="hidden" name="action" value="sendpass" />
		
		<label>Email address:</label>
		<input name="email" maxlength="255" />
		<br />
		
		<label>&nbsp;</label>
		<input value="Send password!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/send_password_mail.email -- >8 --

$mail = {
	subject => 'Your password',
	body    => "With this password you have access to the advanced features of this website\nYour temporary password for the email address \$email\$ is: \$pass\$\nYou can change the password after your login.",
}

-- 8< -- textfile: messages/change_password_failed.template -- >8 --

<div class="usermanagement message failure">
	<h1>Password not changed</h1>
	<p>An internal error occurred while updating the password</p>
</div>

-- 8< -- textfile: messages/change_password_failed_unmatched.template -- >8 --

<div class="usermanagement message failure">
	<h1>Password not changed</h1>
	
	<p>The passwords don't match.</p>
	<p>The password has not been changed.</p>
</div>

-- 8< -- textfile: messages/change_password_failed_wrong_pass.template -- >8 --

<div class="usermanagement message failure">
	<h1>Password not changed</h1>
	
	<p>The entered password is wrong.</p>
	<p>The password has not been changed.</p>
</div>

-- 8< -- textfile: messages/change_password_successful.template -- >8 --

<div class="usermanagement message success">
	<h1>Password updated</h1>
	
	<p>The password has been updated successfully.</p>
</div>

-- 8< -- textfile: messages/deregistration_failed.template -- >8 --

<div class="usermanagement message failure">
	<h1>Deregistration failed</h1>
	
	<p>An internal error occurred during the deregistration.</p>
</div>

-- 8< -- textfile: messages/deregistration_failed_not_confirmed.template -- >8 --

<div class="usermanagement message failure">
	<h1>Deregistration failed</h1>
	
	<p>The deregistration has failed.</p>
	<p>The confirmation checkbox was not checked!</p>
</div>

-- 8< -- textfile: messages/deregistration_successful.template -- >8 --

<div class="usermanagement message success">
	<h1>Deregistration successful</h1>
	
	<p>Your account has been removed from the database.</p>
</div>

-- 8< -- textfile: messages/login_failed.template -- >8 --

<div class="usermanagement message failure">
	<h1>Login failed</h1>
	
	<p>The login has failed.</p>
	<p>Either a wrong username password has been entered.</p>
</div>

-- 8< -- textfile: messages/login_successful.template -- >8 --

<div class="usermanagement message success">
	<h1>Login successful</h1>
	
	<p>You have logged in successfully.</p>
</div>

-- 8< -- textfile: messages/logout_successful.template -- >8 --

<div class="usermanagement message success">
	<h1>Logout successful</h1>
	
	<p>You have logged out successful.</p>
</div>

-- 8< -- textfile: messages/registration_failed.template -- >8 --

<div class="usermanagement message failure">
	<h1>Registration failed</h1>
	
	<p>An internal error occurred while registering.</p>
</div>

-- 8< -- textfile: messages/registration_failed_email_exists.template -- >8 --

<div class="usermanagement message failure">
	<h1>Registration failed</h1>
	
	<p>The registration failed!</p>
	<p>The specified email address <+$ email / $+> does already exist.</p>
</div>

-- 8< -- textfile: messages/registration_successful.template -- >8 --

<div class="usermanagement message success">
	<h1>Registration successful</h1>
	
	<p>The registration was successful!</p>
	<p>A temporary password will be sent to your email address.</p>
	<p>You can change your password after your login.</p>
</div>

-- 8< -- textfile: messages/send_password_failed.template -- >8 --

<div class="usermanagement message failed">
	<h1>Password not sent</h1>
	
	<p>An error occurred while sending the password.</p>
	<p>Maybe the specified email address is not registered here or an internal error occurred.</p>
</div>

-- 8< -- textfile: messages/send_password_failed_email_not_exists.template -- >8 --

<div class="usermanagement message failed">
	<h1>Password not sent</h1>
	
	<p>The password has not been sent.</p>
	<p>The email address <+$ email / $+> is not registered on this site.</p>
</div>

-- 8< -- textfile: messages/send_password_successful.template -- >8 --

<div class="usermanagement message success">
	<h1>Password sent</h1>
	
	<p>A new password has been sent to the email address <+$ email / $+>.</p>
</div>

