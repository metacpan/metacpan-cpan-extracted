package HTML::FormHandlerX::Form::Login;

use 5.006;

use strict;
use warnings;

=head1 NAME

HTML::FormHandlerX::Form::Login - An HTML::FormHandler login form.

=head1 VERSION

Version 0.17

=cut

our $VERSION = '0.17';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

Performs login form validation, including changing passwords, forgotten passwords, and resetting passwords.

If you are working under Catalyst, take a look at L<CatalystX::SimpleLogin> or L<CatalystX::Controller::Auth>.

Registering...

 $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email password confirm_password ) ] );

 $form->process( params => { email            => $email,
                             password         => $password,
                             confirm_password => $confirm_password,
                           } );

Login with either an optional C<email> B<or> C<username> parameter.

 my $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email password ) ] );
 
 $form->process( params => { email => $email, password => $password } );

Changing a password...

 my $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( old_password password confirm_password ) ] );
 
 $form->process( params => { old_password     => $old_password,
                             password         => $password,
                             confirm_password => $confirm_password,
                           } );

Forgot password, just validates an C<email>, or C<username>.

Use this to create a C<token> to send to the user to verify their email address.

 my $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email ) ] );
 
 $form->process( params => { email => $email } );
 
 if ( $form->validated )
 {
         $form->token_salt( 'SoMeThInG R4nD0M AnD PR1V4te' );

         my $token = $form->token;
 }

Coming back from an email link, if the form validates, you would show the password reset form (carry the token in a hidden field or cookie).

 $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( token ) ] );
 
 $form->token_salt( 'SoMeThInG R4nD0M AnD PR1V4te' );
 
 $form->process( params => { token => $token } );

When trying to actually reset a password...

 $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( token password confirm_password ) ] );
 
 $form->token_salt( 'SoMeThInG R4nD0M AnD PR1V4te' );

 $form->process( params => { token            => $token,
                             password         => $password,
                             confirm_password => $confirm_password,
                           } );

=head1 DESCRIPTION

This module will validate your forms.  It does not perform any actual authentication, that is still left for you.

=head2 Register

You can register with either an C<email> or C<username>.

Using C<email> brings in validation using L<Email::Valid>.

C<email>/C<username>, C<password> and C<confirm_password> are all required fields, so will fail validation if empty.

 my $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email password confirm_password ) ] );
 
 $form->process( params => { email => $email, password => $password, confirm_password => $confirm_password } );

=head2 Login

You can choose between an optional C<email> and C<username> for the unique identifier.

Using C<email> brings in validation using L<Email::Valid>.

 my $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email password ) ] );
 
 $form->process( params => { email => $email, password => $password } );

=head2 Change Password

Instantiate the form by activating the 3 fields: C<old_password>, C<password>, and C<confirm_password>.

All 3 fields are required, and validation will also check the C<confirm_password> matches the C<password>.

 my $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( old_password password confirm_password ) ] );
 
 $form->process( params => { old_password     => $old_password,
                             password         => $password,
                             confirm_password => $confirm_password,
                           } );
 
 if ( $form->validated ) { }

=head2 Forgot Password

Provide the C<email> B<or> C<username> to validate, the form will then have a C<token> for you.

You can then send this C<token> to the user via email to verify their identity.

You need to supply a (private) C<token_salt> to make sure your C<token>s are not guessable.  This can be anything you like.

Tokens expire by default after 24 hours from the date/time of issue.  To change
this, either supply an epoch timestamp of when to expire, or give a human-friendly format of how long to wait.  We like things like:

 2h - 2 hours
 3d - 3 days
 4w - 4 weeks
 5m - 5 months

If you specify C<add_token_field> the value of this field in the form will be included in the token.  This can be useful when the token is sent back, to identify the user.

 my $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email ) ] );
 
 $form->process( params => { email => $email } );
 
 if ( $form->validated )
 {
         $form->token_salt( 'SoMeThInG R4nD0M AnD PR1V4te' );
         
         $form->add_token_field( 'email' );
         
         $form->token_expires( '3h' );
  
         my $token = $form->token;
 }

The token is comprised of a L<Digest::SHA> hash, so can be a tad long, but has much less chance of collisions compared to an MD5.

=head2 Reset Password - Stage 1

You will usually give the token to the user in an email so they can verify they own the email address.

This step is for just showing the user a reset-password form.

The first step when the user comes back to reset their password, is to check they have not fiddled with the token.

You can safely skip this step, we check the token again when they/you actually try to change the password, this just lets you stop them in their tracks a little sooner.

Setting the C<token_salt> is required, and must obviously be the same C<salt> as used in the forgot-password call.

C<add_token_field> as you did during the forgot-password process.  This will populate the unique identifier field for you. 

 $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( token ) ] );
 
 $form->token_salt( 'SoMeThInG R4nD0M AnD PR1V4te' );
 
 $form->add_token_field( 'email' );
 
 $form->process( params => { token => $token } );
 
 if ( $form->validated ) { }

=head2 Reset Password - Stage 2

You have now shown the user a form to enter a new password (and confirm it).

Either hidden in that form, or as a cookie, you have also stored the token.

 $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( token password confirm_password ) ] );
 
 $form->token_salt( 'SoMeThInG R4nD0M AnD PR1V4te' );
 
 $form->add_token_field( 'email' );
 
 $form->process( params => { token            => $token,
                             password         => $password,
                             confirm_password => $confirm_password,
                           } );
 
 if ( $form->validated ) { }
 
If you specified the C<token_field> as C<email>, you can now collect that from the form as the record to update safely.

 $form->field( 'email' )->value;

And now know which user to update.

=cut

use HTML::FormHandler::Moose;

extends 'HTML::FormHandler';

use Digest::SHA qw( sha512_hex );
use Email::Valid;

=head1 METHODS

=head2 Attributes

=head3 token

 $form->token

Returns a unique string for the C<email> or C<username> validated by the form.

You typically send this to the users email.

=cut

has token => ( is => 'rw', isa => 'Str', lazy_build => 1 );

=head3 token_fields

 $form->add_token_field( 'email' );

Specifies which fields to include in the token for you to identify which user it is trying to reset their password when they come back.

Either C<email> or C<username> is normal.

=cut

has _token_fields => ( is  => 'rw',
                       isa => 'ArrayRef[Str]',
                       default => sub { [] },
                       traits => ['Array'],
                       handles => { token_fields    => 'elements',
                                    add_token_field => 'push',
                                  }
                     );

=head3 token_salt

 $form->token_salt

Your own (random string) salt used to create the reset-password token.

=cut

has token_salt => ( is => 'rw', isa => 'Str', default => '' );

=head3 token_expires

 $form->token_expires

Dictates how long the token is valid for, default is 1 day.

Possible formats are 2h, 3d, 6w, 1m, or an epoch timestamp.

=cut

has token_expires => ( is => 'rw', isa => 'Int', default => 86400 ); # 1 day

=head2 Fields

=head3 token

 $form->field('token')

This field is used when attempting to reset a password.

=cut

has_field token => ( type         => 'Hidden',
                     required     => 1,
                     messages     => { required => "Missing token." },
                     wrapper_attr => { id => 'field-token', },
                     tags         => { no_errors => 1 },
                     inactive     => 1,
                   );

=head3 email / username / openid_identifier

 $form->field('email')
 
 $form->field('username')

 $form->field('openid_identifier')

The C<openid_identifier> field used by L<Catalyst::Authentication::Credential::OpenID> for OpenID logins, C<username> field, or use the specific C<email> field for extra validation (employing Email::Valid).

=cut

has_field email => ( type         => 'Email',
                     required     => 1,
                     messages     => { required => 'Your email is required.' },
                     tags         => { no_errors => 1 },
                     wrapper_attr => { id => 'field-email' },
                     inactive     => 1,
                   );

has_field username => ( type         => 'Text',
                        required     => 1,
                        messages     => { required => 'Your username is required.' },
                        tags         => { no_errors => 1 },
                        wrapper_attr => { id => 'field-username' },
                        inactive     => 1,
                      );

has_field openid_identifier => ( type         => 'Text',
                                 required     => 1,
                                 messages     => { required => 'Your openid is required.' },
                                 tags         => { no_errors => 1 },
                                 wrapper_attr => { id => 'field-openid-identifer' },
                                 inactive     => 1,
                               );
                      
=head3 old_password

 $form->field('old_password')

Required when changing a known password.

C<HTML::FormHandler> has a built-in length restriction for C<password> fields of 6-characters, we drop that to 1-character, it is up to you to come with your own rules.

=cut

has_field old_password => ( type         => 'Password',
                            minlength    => 1,
                            required     => 1,
                            messages     => { required => "Your old password is required." },
                            tags         => { no_errors => 1 },
                            wrapper_attr => { id => 'field-old-password', },
                            inactive     => 1,
                          );

=head3 password

 $form->field('password')

Used for logging in, changing and/or resetting a password to something new.

C<HTML::FormHandler> has a built-in length restriction for C<password> fields of 6-characters, we drop that to 1-character, it is up to you to come with your own rules.

=cut

has_field password => ( type         => 'Password',
                        minlength    => 1,
                        required     => 1,
                        messages     => { required => "Your password is required." },
                        tags         => { no_errors => 1 },
                        wrapper_attr => { id => 'field-password', },
                        inactive     => 1,
                      );

=head3 confirm_password

 $form->field('confirm_password')

Required for changing and/or resetting the password.

=cut

has_field confirm_password => ( type           => 'PasswordConf',
                                required       => 1,
                                password_field => 'password',
                                messages       => { required => "You must confirm your password." },
                                tags           => { no_errors => 1 },
                                wrapper_attr   => { id => 'field-confirm-password', },
                                inactive       => 1,
                              );

=head3 remember

 $form->field('remember')

Useful for a "remember me" checkbox.

=cut

has_field remember => ( type         => 'Checkbox',
                        tags         => { no_errors => 1 },
                        wrapper_attr => { id => 'field-remember', },
                        inactive     => 1,
                      );

=head3 submit

 $form->field('submit')

The submit button.

=cut

has_field submit => ( type         => 'Submit',
                      value        => '',
                      wrapper_attr => { id => 'field-submit', },
                    );

=head2 Validation

=head3 validate_token

The internal validation of the token when attempting to reset a password.

=cut

sub validate_token
{
	my ( $self, $field ) = @_;
	
	my @token_parts = split( ':', $field->value );

	my $token = pop @token_parts;
	
	if ( $token ne sha512_hex( $self->token_salt . join( '', @token_parts ) ) )
	{
		$field->add_error("Invalid token.");
	}
	
	my $time  = pop @token_parts;

	if ( time > $time )
	{
		$field->add_error("Expired token.");
	}
}

=head3 html_attributes

This method has been populated to ensure all fields in error have the C<error> CSS class assigned to the labels.

=cut

sub html_attributes
{
	my ($self, $field, $type, $attr, $result) = @_;
    
	if( $type eq 'label' && $result->has_errors )
	{
		push @{$attr->{class}}, 'error';
	}
}

after build_active => sub {
	my $self = shift;

	if ( ( $self->field('email')->is_active || $self->field('username')->is_active ) && $self->field('password')->is_active && $self->field('confirm_password')->is_active )
	{
		$self->field('submit')->value('Register');
	}
	elsif ( ( $self->field('password')->is_active && ! $self->field('confirm_password')->is_active ) || $self->field('openid_identifier')->is_active )
	{
		$self->field('submit')->value('Login');
	}
	elsif ( ( $self->field('email')->is_active || $self->field('username')->is_active ) && ! $self->field('password')->is_active && ! $self->field('token')->is_active )
	{
		$self->field('submit')->value('Forgot Password');
	}
	elsif ( $self->field('old_password')->is_active && $self->field('password')->is_active && $self->field('confirm_password')->is_active )
	{
		$self->field('password')->label('New Password');
		$self->field('submit')->value('Change Password');
	}
	elsif ( $self->field('token')->is_active )
	{
		$self->field('password')->label('New Password');
		$self->field('submit')->value('Reset Password');
	}		
};

around token_expires => sub {
	my $orig = shift;
	my $self = shift;

	if ( my $arg = shift )
	{
		if ( $arg =~ /(\d+)h/i )
		{
			$arg = $1 * 3600;
		}
		elsif ( $arg =~ /(\d+)d/i )
		{
			$arg = $1 * 86400;
		}
		elsif ( $arg =~ /(\d+)w/i )
		{
			$arg = $1 * 604800;
		}
		elsif ( $arg =~ /(\d+)m/i )
		{
			$arg = $1 * 2629743;
		}
		
		return $self->$orig( $arg );
	}

	return $self->$orig;
};

sub _build_token
{
	my $self = shift;

	return '' if $self->token_salt eq '';   # no salt, no token
	
	my $time = time + $self->token_expires;

	my @field_value_list = map { $self->field( $_ )->value } $self->token_fields;

	my $token = join( ':', @field_value_list, $time, sha512_hex( $self->token_salt . join( '', @field_value_list ) . $time ) );

	return $token;
}

sub _munge_params
{
	my ( $self, $params ) = @_;
	
	if ( exists $params->{ token } )
	{
		# the order is drastically important
		
		my @token_parts = split( ':', $params->{ token } );

		foreach my $field ( $self->token_fields )
		{
			$self->field( $field )->inactive(0);

			$params->{ $field } = shift @token_parts;
		}
	}

	$self->next::method( $params );
}

=head1 RENDERING

This form does some subtle rendering tricks, renaming buttons and labels based on which fields are active.

=head1 TODO

Look at password type fields, pre-set char-length, etc. and/or import types from HTML::FormHandler directly.

=head1 AUTHOR

Rob Brown, C<< <rob at intelcompute.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-formhandlerx-form-login at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-FormHandlerX-Form-Login>.  I will be notified, and then you will
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::FormHandlerX::Form::Login


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-FormHandlerX-Form-Login>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-FormHandlerX-Form-Login>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-FormHandlerX-Form-Login>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-FormHandlerX-Form-Login/>

=back


=head1 ACKNOWLEDGEMENTS

gshank: Gerda Shank E<lt>gshank@cpan.orgE<gt>

t0m: Tomas Doran E<lt>bobtfish@bobtfish.netE<gt>

castaway: Jess Robinson (OpenID support)


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HTML::FormHandlerX::Form::Login
