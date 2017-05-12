#=============================================================================
# LibWeb::Admin -- User authentication for libweb applications.

package LibWeb::Admin;

# Copyright (C) 2000  Colin Kong
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#=============================================================================

# $Id: Admin.pm,v 1.4 2000/07/18 06:33:30 ckyc Exp $

#-############################
# Use standard library.
use SelfLoader;
use strict;
use vars qw(@ISA $VERSION);

#-############################
# Use custom library.
require LibWeb::Session;
##require LibWeb::Database;

#-############################
# Inheritance.
@ISA = qw(LibWeb::Session);

$VERSION = '0.02';

#-############################
# Methods.
sub new {
    #
    # Params: $class [, $rc_file]
    #
    # - $class is the class/package name of this package, be it a string
    #   or a reference.
    # - $rc_file is the absolute path to the rc file for LibWeb.
    #
    # Usage: my $object = new LibWeb::Admin([$rc_file]);
    #
    my ($class, $Class, $self);
    $class = shift;
    $Class = ref($class) || $class;

    # Inherit instance variables from the base class.
    $self = $Class->SUPER::new(shift);
    bless($self, $Class);
}

sub DESTROY {}

sub _authenticateLogin {
    #
    # Params:
    # (\$uid, \$usrName, $db)
    #
    # Post:
    # 1. Send the prepared auth. cookie: session ID, issue time,
    #    expiration time, user name, IP, UID, MAC, where all elements are encrypted
    #    (one-way encrypted; except for the expiration time, user name and UID which
    #    are encrypted as ciphers (two-way encrypted) for later decryption during
    #    authentication check and for generating logout cookies.
    #    
    # 2. Update database: `LAST_LOGIN' (Internet address, IP and date/time) and
    #    `NUM_LOGIN_ATTEMPT' for that user IS NOT done here since we want to make
    #    sure client Web browser accepts cookie first.  This task is delegated
    #    to sub is_login(1) which should be called by client codes when user is
    #    FIRST login.  Subsequent authenticate checks should call islogin() instead
    #    of is_login(1);
    #
    # 3. Return 1 upon success.
    #
    # Note: how a MAC is generated.  Could use MD5 or SHA etc.
    # MAC = MD5("secret key " +
    #           MD5("session ID" + "issue time" + "expiration time" +
    #               "user name" + "IP address" + "user id" + "secret key")
    #          ),
    #       where session ID = PID(which is $$) + UID(which is $$uid).
    #
    
    #============== #1 =====================
    my ($self, $crypt, $digest, $uid, $usrName, $db, $sid, $issueTime, $expireTime,
	$user, $ip, $cuid, $macKey, $preMAC, $MAC, $dummyCookie, $auth_cookie);
    $self = shift;
    ($uid, $usrName, $db) = @_;
    $crypt = LibWeb::Crypt->new();
    $digest = LibWeb::Digest->new();
    my(
       $cipher_key, $cipher_algorithm, $cipher_format,
       $digest_key, $digest_algorithm, $digest_format
      )
      = (
	 $self->{CIPHER_KEY}, $self->{CIPHER_ALGORITHM}, $self->{CIPHER_FORMAT},
	 $self->{DIGEST_KEY}, $self->{DIGEST_ALGORITHM}, $self->{DIGEST_FORMAT}
	);

    ($sid, $issueTime, $expireTime, $user, $ip, $cuid, $macKey) =
      ( 
       $digest->generate_digest(
				-data => $$ + $$uid,
				-key => $digest_key,
				-algorithm => $digest_algorithm,
				-format => $digest_format
			       ),
       $digest->generate_digest(
				-data => time(),
				-key => $digest_key,
				-algorithm => $digest_algorithm,
				-format => $digest_format
			       ),
       $crypt->encrypt_cipher(
			      -data => time() + $self->{LOGIN_DURATION_ALLOWED},
			      -key => $cipher_key,
			      -algorithm => $cipher_algorithm,
			      -format => $cipher_format
			     ),
       $crypt->encrypt_cipher(
			      -data => $$usrName,
			      -key => $cipher_key,
			      -algorithm => $cipher_algorithm,
			      -format => $cipher_format
			     ),
       $digest->generate_digest( 
				-data => $ENV{REMOTE_ADDR},
				-key => $digest_key,
				-algorithm => $digest_algorithm,
				-format => $digest_format
			       ),
       $crypt->encrypt_cipher(
			      -data => $$uid,
			      -key => $cipher_key,
			      -algorithm => $cipher_algorithm,
			      -format => $cipher_format
			     ),
       $self->{MAC_KEY}
      );
    $preMAC =
      $digest->generate_MAC(
			    -data => $sid.$issueTime.$expireTime.$user.$ip.$cuid.$macKey,
			    -key => $macKey,
			    -algorithm => $digest_algorithm,
			    -format => $digest_format
			   );
    $MAC = $digest->generate_MAC(
				 -data => $macKey.$preMAC,
				 -key => $macKey,
				 -algorithm => $digest_algorithm,
				 -format => $digest_format
				);
    $dummyCookie =
      "B=" .
	$digest->generate_digest(
				 -data => rand( $self->{RAND_RANGE} ),
				 -key => $digest_key,
				 -algorithm => $digest_algorithm,
				 -format => $digest_format
				) .
				"; path=/";
    # CGI::Cookie has problem with characters `=' and `&' or a problem with my
    # understanding of autoescaping?  Therefore prepare the auth cookie manually
    # instead.
    $auth_cookie =
      "C=z=$sid&y=$issueTime&x=$expireTime&w=$user&v=$ip&u=$cuid&t=$MAC; path=/";
    LibWeb::CGI->new()->send_cookie([$dummyCookie, $auth_cookie]);
    return 1;
}

sub _handleLogin {
    #
    # Params:
    # (\$uid, \$usrname, \$cryptRealPass, \$guess, \$numLoginAttempt, $db)
    #
    # Pre:
    # 1. None.
    #
    # Post:
    # 1. Writing...
    #
    my ($self, $uid, $usrName, $cryptRealPass, $guess, $numLoginAttempt, $db);
    $self = shift;
    ($uid, $usrName, $cryptRealPass, $guess, $numLoginAttempt, $db) = @_;

    # Prevent further login attempt if reached max login attempt allowed.
    $self->fatal(-msg => 'Maximum login attempts reached.',
		 -alertMsg => "Max guess ($$guess) for account ($$usrName) reached.",
		 -helpMsg => $self->{HHTML}->exceeded_max_login_attempt(),
		 -cookie => $self->prepare_deauth_cookie())
      unless ($$numLoginAttempt < $self->{MAX_LOGIN_ATTEMPT_ALLOWED} ||
	      $$numLoginAttempt == $self->{LOGIN_INDICATOR});

    # Compare crypted guess with crypted real password.
    my $cryptGuess = crypt($$guess, $$cryptRealPass);
    if ($cryptGuess eq $$cryptRealPass) {

	# Alert admin if more than one login per account at a time.
	if ($$numLoginAttempt == $self->{LOGIN_INDICATOR}) {
#	    my $sql_statement = "update $self->{USER_LOG_TABLE} " .
#	                        "set $self->{USER_LOG_TABLE_NUM_LOGIN_ATTEMPT}=0 " .
#		                "where $self->{USER_LOG_TABLE_UID}='$$uid'";
#	    $db->do( -sql => $sql_statement );
	    $self->fatal(
			 -alertMsg => "Attempt to use guess [$$guess] to log in " .
			              "as user [$$usrName] while account's login " .
			              "indicator is high!",
			 -isDisplay => 0
			);
	}

	$self->_authenticateLogin($uid, $usrName, $db);
    }
    elsif ($cryptGuess ne $$cryptRealPass) {
	$self->_failLogin($uid, $usrName, $guess, $numLoginAttempt, $db);
    }
}

sub is_logout {
    #
    # Params:
    # none.
    #
    # Check to see if authentication cookies have been removed from
    # client Web browser and return true (1).  Otherwise, print
    # $self->{HHTML}->logout_failed() and exit the program.
    #
    my ($self, $sid, $issueTime, $expireTime, $cryptUsrname, $guessIP, $guessCUID,
	$guessMAC);
    $self = shift;
    ($sid, $issueTime, $expireTime, $cryptUsrname, $guessIP, $guessCUID, $guessMAC)
      = $self->_getAuthInfoFromCookie();
    $self->fatal(-msg => 'Could not logout.',
		 -alertMsg => 'Auth cookie is still defined after logout()!!!',
		 -helpMsg => $self->{HHTML}->logout_failed(),
		 -cookie => $self->prepare_deauth_cookie())
      if ( defined($sid) || defined($issueTime) || defined($expireTime) ||
	   defined($cryptUsrname) || defined($guessIP) || defined($guessCUID) ||
	   defined($guessMAC) );
    return 1;
}

sub login {
    #
    # Params:
    # (user_name, guess).
    #
    # Pre:
    # 1. None.
    #
    # Post:
    #
    # 1. Check for correct password.  If correct, send the special
    #    authentication cookie object to client Web browser and
    #    return 1; alert admin and print out error page and exit ow.
    #
    my ($self, $usrName, $guess, $uid, $cryptRealPass, $numLoginAttempt, $db,
	$bindCols, $sqlStatement, $fetchFunc, $alertMsg);
    $self = shift;
    $usrName = shift;
    $guess = shift;

    require LibWeb::Database;
    $db = new LibWeb::Database();

    # Fetch encrypted user password and numLoginAttempt from database.
    $bindCols = [\$uid, \$cryptRealPass, \$numLoginAttempt];
    $sqlStatement =
      "select $self->{USER_PROFILE_TABLE}.$self->{USER_PROFILE_TABLE_UID}, ".
	"$self->{USER_PROFILE_TABLE}.$self->{USER_PROFILE_TABLE_PASS}, ".
	  "$self->{USER_LOG_TABLE}.$self->{USER_LOG_TABLE_NUM_LOGIN_ATTEMPT} from ". 
	    "$self->{USER_PROFILE_TABLE},$self->{USER_LOG_TABLE} ".
	      "where  $self->{USER_PROFILE_TABLE_NAME} = '$usrName' ".
		"and $self->{USER_LOG_TABLE}.$self->{USER_LOG_TABLE_UID} = ".
		  "$self->{USER_PROFILE_TABLE}.$self->{USER_PROFILE_TABLE_UID}";
    $fetchFunc = $db->query(
			    -sql => $sqlStatement,
			    -bind_cols => $bindCols
			   );
    &$fetchFunc;
    if (defined($uid) && defined($cryptRealPass) && defined($numLoginAttempt)) {
	$self->_handleLogin(\$uid, \$usrName, \$cryptRealPass,
			    \$guess, \$numLoginAttempt, $db);
	return 1;
    }
    else { # No such user.
	$db->finish();
	$alertMsg = "User name ($usrName) and guess ($guess) non-exist.\n";
	$self->fatal(-msg => 'Login incorrect.', alertMsg => $alertMsg,
		     -helpMsg => $self->{HHTML}->login_failed(),
		     -cookie => $self->prepare_deauth_cookie());
    }
}

sub logout {
    #
    # Params:
    # None.
    #
    # Pre:
    #  1. None.
    #
    # Post:
    #  1. Check to see if user is logged in.  Get user name from cookie on client
    #     Web browser (decrypt).  Fatal if not logged in or no auth cookie.
    #  2. Flush 'NUM_LOGIN_ATTEMPT' to 0 in database.  This also indicates that
    #     the user is currently offline (logout).
    #  3. Send the prepared DeAuth. cookies for nullifying all cookies on client
    #     Web browser by preparing zero/null auth cookies with an expiration date
    #     in the past.  Also set dummy cookie's value to zero.
    #  4. Return 1 upon success.
    #
    my ($self, $usrName, $uid, $sqlStatement, $db);
    $self = shift;
    #=================== #1 =============================
    ($usrName, $uid) = $self->is_login();
    #=================== #2 =============================
    require LibWeb::Database;
    $db = new LibWeb::Database();
    $sqlStatement = "update $self->{USER_LOG_TABLE} " .
                    "set $self->{USER_LOG_TABLE_NUM_LOGIN_ATTEMPT} = 0 " .
		    "where $self->{USER_LOG_TABLE_UID} = $uid";  
    $db->do( -sql => $sqlStatement );
    $db->finish();
    #=================== #3 =============================
    # Remove auth. cookie from client Web browser and reset dummy cookie to 0.
    LibWeb::CGI->new()->send_cookie($self->prepare_deauth_cookie());
    return 1;
}

# Selfloading methods declaration.
sub LibWeb::Admin::_failLogin ;
sub LibWeb::Admin::_is_user_email_registered ;
sub LibWeb::Admin::_is_user_name_registered ;
sub LibWeb::Admin::add_new_user ;
1;
__DATA__

sub _failLogin {
    #
    # Actively fail a login attempt.
    #
    # Params:
    # (\$uid, \$usrName, \$guess, \$numLoginAttempt, $db)
    #
    # Pre:
    # 1. None.
    #
    # Post:
    # 1. None.
    #
    my ($self, $uid, $usrName, $guess, $numLoginAttempt, $db, $sqlStatement,
	$alertMsg);
    $self = shift;
    ($uid, $usrName, $guess, $numLoginAttempt, $db) = @_;
    $$numLoginAttempt++;
    $sqlStatement = "update $self->{USER_LOG_TABLE} " .
                    "set $self->{USER_LOG_TABLE_NUM_LOGIN_ATTEMPT}=".
		    $$numLoginAttempt .
	            " where $self->{USER_LOG_TABLE_UID}=$$uid";
    $alertMsg = "Incorrect guess ($$guess) for user account: $$usrName.\n";
    $db->do( -sql => $sqlStatement );
    $db->finish();
    $self->fatal(-msg => 'Login incorrect.', -alertMsg => $alertMsg,
		 -helpMsg => $self->{HHTML}->login_failed(),
		 -cookie => $self->prepare_deauth_cookie());
    return undef;
}

sub _is_user_email_registered {
    #
    # Params:
    # $email (scalar).
    #
    # Pre:
    # 1. None.
    #
    # Post:
    # 1. Print an error message and abort if $email is already registered.
    # 2. Otherwise, return 1.
    #
    my ($self, $email, $db, $sql_statement, $fetch, $uid);
    $self = shift;
    $email = shift;

    require LibWeb::Database;
    $db = new LibWeb::Database();

    $sql_statement = "select $self->{USER_PROFILE_TABLE_UID} ".
                     "from $self->{USER_PROFILE_TABLE} where ".
	             "$self->{USER_PROFILE_TABLE_EMAIL} = '$email'";
    $fetch = $db->query(
			-sql => $sql_statement,
			-bind_cols => [\$uid]
		       );
    &$fetch;
    $db->finish();
    return 0 unless defined($uid);
    $self->fatal(-msg => 'The email has already been registered.',
		 -input => $email,
		 -helpMsg => $self->{HHTML}->hit_back_and_edit());
}

sub _is_user_name_registered {
    #
    # Check a user name against database to see if the user name is in use already.
    #
    # Params:
    # $user_name (scalar).
    #
    # Pre:
    # 1. None.
    #
    # Post:
    # 1. Print an error message and abort if $user_name is already registered.
    # 2. Otherwise, return 0.
    #
    my ($self, $user_name, $db, $sql_statement, $fetch, $uid);
    $self = shift;
    $user_name = shift;

    require LibWeb::Database;
    $db = new LibWeb::Database();

    $sql_statement = "select $self->{USER_PROFILE_TABLE_UID} ".
                     "from $self->{USER_PROFILE_TABLE} where ".
	             "$self->{USER_PROFILE_TABLE_NAME} = '$user_name'";
    $fetch = $db->query(
			-sql => $sql_statement,
			-bind_cols => [\$uid]
		       );
    &$fetch;
    $db->finish();
    return 0 unless defined($uid);
    $self->fatal(-msg => 'The user name has already been registered.',
		 -input => $user_name,
		 -helpMsg => $self->{HHTML}->hit_back_and_edit());
}

sub add_new_user {
    #
    # Add a new user to database.
    #
    # Params:
    # (-user=>'user_name', password=>'user_password', email=>'user_email').
    #
    # Pre:
    # 1. None.
    #
    # Post:
    # 1. Sanitize `user_name'.  Print out an error msg and abort if fails.
    # 2. Print out an error msg and abort if user name is already registered.
    # 3. Sanitize email address; print out an error msg and abort if fails.
    # 4. Print out an error msg and abort if email is already registered.
    # 5. Add user to database.
    # 6. Notify admin by email that a user has been added if
    #    $self->{IS_NOTIFY_ADMIN_WHEN_ADDED_NEW_USER} is true.
    # 7. Return user_name upon success.
    #
    my ($self, $user_name, $password, $email, $sanitized_user_name, $crypt_pass, $db,
	$sql_statement, );
    $self = shift;
    ($user_name, $password, $email)
      = $self->rearrange(['USER', 'PASSWORD', 'EMAIL'], @_);
    require LibWeb::Database;
    $db = new LibWeb::Database();
    #========================= #1. ============================
    # Check to see if user name is valid.
    # LibWeb::Core::sanitize() doesn't replace normal spaces with empty token
    # and therefore check that manually.
    $self->fatal(-msg => 'User name cannot contain spaces.',
		 -input => $user_name,
		 -alertMsg => 'LibWeb::Admin::add_new_user()',
		 -helpMsg => $self->{HHTML}->special_characters_not_allowed())
      if ( $user_name =~ m:\s+: );

    $sanitized_user_name = $self->sanitize( -text => $user_name,
					    -allow => ['_', '-'] );

    $self->fatal(-msg => 'User name cannot contain special characters.',
		 -input => $user_name,
		 -alertMsg => 'LibWeb::Admin::add_new_user()',
		 -helpMsg => $self->{HHTML}->special_characters_not_allowed())
      unless ($user_name eq $sanitized_user_name);

    # Double protection although we have checked for spaces already.
    $sanitized_user_name =~ s:\s+::g;

    #========================= #2. ============================
    $self->_is_user_name_registered($sanitized_user_name);

    #========================= #3. ============================
    # Check to see if email is in valid format.
    $email = $self->sanitize(-email => $email);

    #========================= #4. ============================
    # Check to see if email is already registered.
    $self->_is_user_email_registered($email)
      unless $self->{IS_ALLOW_MULTI_REGISTRATION};

    #========================= #5. ============================
    # Add user to database.
    $crypt_pass = LibWeb::Crypt->new()->encrypt_password($password);
    $sql_statement = "insert into $self->{USER_PROFILE_TABLE} " .
	             "set $self->{USER_PROFILE_TABLE_NAME} = '$sanitized_user_name', " .
		     "$self->{USER_PROFILE_TABLE_PASS} = '$crypt_pass', " .
		     "$self->{USER_PROFILE_TABLE_EMAIL} = '$email'";
    $db->do( -sql => $sql_statement );
    $sql_statement = "insert into $self->{USER_LOG_TABLE} " .
	             "set $self->{USER_LOG_TABLE_NUM_LOGIN_ATTEMPT}=0";
    $db->do( -sql => $sql_statement );

    $db->finish();

    #========================= #6. ============================
    # Notify admin.
    $self->fatal(-alertMsg =>
		 "Added new user:\t$user_name\n".#Password:\t$password\n".
		 "E-mail address:\t$email\n".
		 "From:\t$ENV{REMOTE_ADDR} $ENV{REMOTE_HOST}\n".
		 "Time:\t".localtime(),
		 -isDisplay => 0)
      if $self->{IS_NOTIFY_ADMIN_WHEN_ADDED_NEW_USER};

    return $user_name;
}

1;
__END__

=head1 NAME

LibWeb::Admin - User authentication for libweb applications

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

LibWeb::Database

=back

=head1 ISA

=over 2

=item *

LibWeb::Session

=back

=head1 SYNOPSIS

    use LibWeb::Admin;
    my $a = LibWeb::Admin->new();

    $a->login( $user_name, $guess_password );

             ...

    my ($user_name,$uid) = $a->get_user();

             ...

    $a->logout();

             ...

    $a->is_logout();

=head1 ABSTRACT

This class manages user authentication for web applications written
based on the interfaces and frameworks defined in LibWeb, a Perl
library/toolkit for programming web applications.  It is responsible
for managing user login, logout and new sign-up.  Therefore you may
want to use this module in the login script for your site.

The current version of LibWeb::Admin.pm is available at

   http://libweb.sourceforge.net

Several LibWeb applications (LEAPs) have be written, released and are
available at

   http://leaps.sourceforge.net

=head1 TYPOGRAPHICAL CONVENTIONS AND TERMINOLOGY

Variables in all-caps (e.g. MAX_LOGIN_ATTEMPT_ALLOWED) are those
variables set through LibWeb's rc file.  Please read L<LibWeb::Core>
for more information.  `Sanitize' means escaping any illegal character
possibly entered by user in a HTML form.  This will make Perl's taint
mode happy and more importantly make your site more secure.
Definition for illegal characters is given in L<LibWeb::Core>.  All
`error/help messages' mentioned can be found at L<LibWeb::HTML::Error>
and they can be customized by ISA (making a sub-class of)
LibWeb::HTML::Default.  Please see L<LibWeb::HTML::Default> for
details.

=head1 DESCRIPTION

=head2 HANDLING USER LOGIN

Fetch the user name and password from a HTML form and pass them to
login(),

  $a->login( $user_name, $guess );

If the password is correct and the user name exists in the database,
this will send an authentication cookie to the client web browser and
return 1; send an alert e-mail to the site administrator
(B<ADMIN_EMAIL>) and print out an error message and exit otherwise.

=head2 HANDLING USER SESSION AFTER LOGIN

At the top of every web application that requires user authentication,

  my ($user_name,$uid) = $a->get_user();

to retrieve user name and user ID from cookie.  This will send an
alert e-mail to the site administrator (B<ADMIN_EMAIL>) and redirect
the user to the login page (B<LM_IN>) if no authentication cookie is
found or it has been tampered with.  I would recommend you use
LibWeb::Session instead which is specifically designed for that
purpose and therefore runs a little bit faster,

  use LibWeb::Session;
  my $s = new LibWeb::Session();

  my ($user_name,$uid) = $s->get_user();

LibWeb::Admin should be used by login scripts; whereas LibWeb::Session
should be used by any web applications once the user has logged in.
Read L<LibWeb::Session> for details.

To update the database (set the login indicator to B<LOGIN_INDICATOR>)
when the user is first logged in,

  my ($user_name,$uid)
      = $s->get_user( -is_update_db => 1 );

This is probably done in `my control panel' or `my page' of some sorts
which is the first script invoked after password authentication.

=head2 HANDLING USER LOGOUT

  $a->logout();

This will check to see if the user is logged in.  Send an alert e-mail
to the site administrator (B<ADMIN_EMAIL>) and redirect user to the
login page (B<LM_IN>) if the remote user is not logged in or has no
authentication cookie.  Otherwise, this will flush
B<NUM_LOGIN_ATTEMPT> to 0 in database (indicating that the user has
logged out).  This will also send de-authentication cookies to nullify
all authentication cookies on client web browser.  Return 1 upon
success.

=head2 PARANOIA

  $a->is_logout();

Check to see if authentication cookies are indeed removed from the
client Web browser and return true (1).  Otherwise, print an error
message, send an alert e-mail to B<ADMIN_EMAIL> and exit the program.

=head2 ADDING NEW USER TO DATABASE

  $a->add_new_user(
                   -user => 'user_name',
                   -password => 'password',
                   -email => 'user_email'
                  );

Print out an error message and abort if,

=over 2

=item *

`user_name' contains illegal characters other than `_' and `-' or

=item *

`user_name' is already registered or

=item *

`user_email' does not conform to the standard format defined in
L<LibWeb::Core> or

=item *

`user_email' is already registered if B<IS_ALLOW_MULTI_REGISTRATION>
is set to 0.

=back

If the parameters pass all the tests, this will encrypt the password,
add that with the user name to the database, notify the site
administrator (B<ADMIN_EMAIL>) by e-mail if
B<IS_NOTIFY_ADMIN_WHEN_ADDED_NEW_USER> is set to 1 and log that event
in B<FATAL_LOG> if B<FATAL_LOG> is defined.  Return the registered
user_name upon success.

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=head1 BUGS

=head1 SEE ALSO

L<LibWeb::Core>, L<LibWeb::CGI>, L<LibWeb::Crypt>,
L<LibWeb::Database>, L<LibWeb::Digest>, L<LibWeb::HTML::Default>,
L<LibWeb::Session>, L<LibWeb::Themes::Default>.

=cut
