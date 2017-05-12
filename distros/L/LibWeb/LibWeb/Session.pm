#=============================================================================
# LibWeb::Session -- Session management for libweb applications.

package LibWeb::Session;

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

# $Id: Session.pm,v 1.7 2000/07/19 20:31:57 ckyc Exp $

$VERSION = '0.02';

#-#############################
#  Use standard library.
use Carp;
use strict;
use vars qw(@ISA $VERSION);

#-#############################
# Use custom library.
require LibWeb::Core;
require LibWeb::Digest;
require LibWeb::Crypt;
##require LibWeb::CGI;
##require LibWeb::Database;

#-#############################
# Inheritance.
@ISA = qw(LibWeb::Core);

#-#############################
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

sub _checkDummyCookieIntegrity {
    #
    # Params:
    # _dummyCookies_ [, _no_auth_ ]
    #
    # Pre: 
    # 1. `_dummyCookies_' is a scalar which is the dummy cookie retrieved
    #    from $ENV{HTTP_COOKIE}.
    # 2. `_no_auth_' is a CODE reference for callback if the viewing browser
    #    does not return an authentication cookie.
    #
    my ($self, $dc, $no_auth_callback);
    ($self,$dc,$no_auth_callback) = (shift,shift,shift);
    unless ($dc =~ m:^B=.+$:) {
	if ($no_auth_callback) {
	    return undef;
	} else {
	    $self->fatal( -alertMsg => 'Dummy cookie has been tampered with.',
			  -isDisplay => 0 );
	    $self->_redirect_to_login_page();
	}
    }
    return 1;
}

sub _getAuthInfoFromCookie {
    #
    # Params:
    # [ _isJustLogin_,  _no_auth_ ]
    #
    # Pre:
    # 1. Parameter `_isJustLogin_' is to indicate whether this is the first login
    #    check.  This parameter should be defined in order to check whether the
    #    remote Web browser is cookie enabled when first logging in.
    # 2. `_no_auth_' is a CODE reference for callback if the viewing browser
    #    does not return an authentication cookie.
    # 3. The auth. cookie must came after the dummy cookie in the $ENV{HTTP_COOKIE}
    #    string i.e. in the second position.
    #
    # Post:
    # 1. If `_no_auth_' is provided, then call it; otherwise, Output an error message
    #    and exit the program if integrity of the dummy cookies have been tampered
    #    with.  This is achieved by checking the positions of the dummy.
    #
    # 2. Return encrypted auth. info in an array
    #    (sid, issueTime, expireTime, user, ip, uid, MAC) if auth. cookie is set
    #    properly on client Web browser; ow, return undef (null).
    #
    # Since the authentication cookie is stored as one single gigantic string,
    # need to parse it to get sub info within it.
    #
    my ($self, $is_just_login, $no_auth_callback, @cookies, $auth);
    $self = shift;
    $is_just_login = shift;
    $no_auth_callback = shift;
    
    return undef
      unless ( $self->is_browser_cookie_enabled( $is_just_login, $no_auth_callback ) );

    @cookies = split /; /, $ENV{HTTP_COOKIE};
    $self->_checkDummyCookieIntegrity( shift(@cookies), $no_auth_callback );
    $auth = shift @cookies;
    if ($auth) {
	$auth =~ m:^C=z=(.*)&y=(.*)&x=(.*)&w=(.*)&v=(.*)&u=(.*)&t=(.*)$:;
	return ($1, $2, $3, $4, $5, $6, $7);
    }

    return undef;
}

sub _redirect_to_login_page {
    my $self = shift;
    require LibWeb::CGI;
    LibWeb::CGI->new()->redirect( 
				 -url => $self->{LM_IN},
				 -cookie => $self->prepare_deauth_cookie()
				);
    exit(0);
}

sub is_browser_cookie_enabled {
    #
    # Params:
    # [ _is_just_login_, _no_auth_ ]
    #
    # Pre:
    # 1. _is_just_login_ is either 1 or undef indicating whether the user has
    #    just logged in.
    # 2. _no_auth_ is a CODE reference for callback if the viewing browser
    #    does not return an authentication cookie.
    #
    # Post:
    # 1. Print out an error to client Web browser telling the user that his/her
    #    browser is not cookie enabled and exit the program if $ENV{HTTP_COOKIE}
    #    is not defined and `_is_just_login_' is defined.
    # 2. If $ENV{HTTP_COOKIE} is not defined and `_is_just_login_' is undef,
    #    call `_no_auth_' if it is provided; otherwise, redirect remote Web browser
    #    to a login page 
    # 3. Return 1 ow.
    #
    # Caveat: $ENV{HTTP_COOKIE} is still null even if the browser is cookie-enabled
    #         if no cookie is available for our domain.  Therefore a dummy cookie is
    #         sent to client Web browser (it stays for one browser session) to help
    #         indicate that the browser is still cookie-enabled (i.e. to keep
    #         $ENV{HTTP_COOKIE} defined even after DeAuth. cookie has been issued.)
    #         For details, see LibWeb::Admin::_authenticateLogin() where the dummy
    #         cookie is first set.
    #
    my ($self, $is_just_login, $no_auth_callback);
    $self = shift;
    $is_just_login = shift;
    $no_auth_callback = shift;
    unless ( $ENV{HTTP_COOKIE} ) {

	if ( $is_just_login ) {

	    $self->fatal( -msg => 'Your browser is not cookie enabled.',
			  -alertMsg => 'Could not retrieve cookie.',
			  -helpMsg => $self->{HHTML}->cookie_error(),
			  -cookie => $self->prepare_deauth_cookie() );

	} elsif ($no_auth_callback) {

	    return undef;

	} else {

	    $self->fatal(
			 -alertMsg =>
			 'LibWeb::Session::is_browser_cookie_enabled: no cookie.',
			 -isDisplay => 0
			);
	    $self->_redirect_to_login_page();
	}

    }

    return 1;
}

sub get_user {
    #
    # Check to see if the viewing Web browser has logged in by
    # checking expiration time, IP and MAC in the authentication cookie, and
    # return user name and user ID if it passes all the authentication checks.
    #
    # Params:
    # [ -no_auth=>, -mac_mismatch=>, -ip_mismatch=>,
    #   -expired=>, -is_update_db=> ]
    #
    # Pre:
    # 1. -no_auth is a CODE reference for callback if the viewing browser
    #    does not return an authentication cookie.
    # 2. -mac_mismatch is a CODE reference for callback if the authentication
    #    cookie has been tampered with.
    # 3. -ip_mismatch is a CODE reference for callback if the IP in the
    #    authentication cookie does not correspond to the IP address of the
    #    viewing browser.
    # 4. -expired is a CODE reference for callback if the authentication cookie
    #    is expired.
    # 5. -is_update_db is either 1 or 0 (default).  Use this to indicate whether
    #    this is the first login check.  This parameter should be 1 in order to
    #    update database's 'NUM_LOGIN_ATTEMPT' when user first logged in.
    #
    # Post:
    # 1. Retrieve authentication cookies from client Web browser.
    #
    # 2. All -no_auth, -mac_mismatch, _ip_mismatch and -expired default to
    #    the following actions if you do not provide the callbacks:
    #    * Nullify and delete all authentication cookies resided on the viewing
    #      Web browser,
    #    * send an alert e-mail to ADMIN_EMAIL,
    #    * log that event in FATAL_LOG, and
    #    * redirect the remote user to the login page (LM_IN).
    #
    # 3. Check to see If cookie values are null/zero.
    #
    # 4. Check to see If MAC mis-matches (this means possible hacking from remote
    #    host).
    #
    # 5. Check to see if If IP mis-matches (this means possible hacking from remote
    #    host).
    #
    # 6. Check to see if the login has expired and update database: Set
    #    'NUM_LOGIN_ATTEMPT' to 0 if this is the case.
    #
    # 7. If client has officially logged in and none of #3, #4, #5 and #6 happens,
    #    set database's NUM_LOGIN_ATTEMPT to LOGIN_INDICATOR if parameter
    #    -is_update_db is defined and is equal to 1.  This helps indicate that the
    #    user is online (currently login).
    #
    # 8. And finally return an array (user name and uid) in plain text.
    #
    # Note:
    #    'NUM_LOGIN_ATTEMPT' != 0 && != 'LOGIN_INDICATOR' means
    #    there were several attempts to login but unsuccessful solely because
    #    cryptGuess != cryptRealPass.  Need to re-flush it to 0 manually
    #    after 24 hours of receiving the alert email if this value == the max
    #    login attempt allowed (MAX_LOGIN_ATTEMPT_ALLOWED).
    #
    my ($self,$no_auth,$mac_mismatch,$ip_mismatch,$expired,$is_update_db,
	$sid, $issueTime, $expireTime, $user, $guessIP, $guessCUID, $guessMAC,
	$crypt, $digest, $alertMsg, $userName, $uid, $macKey,
	$preRealMAC, $realMAC, $realIP, $decryptExpireTime, $gmcDecryptExpireTime,
	$db, $log, $sqlStatement);
    $self = shift;
    ($no_auth,$mac_mismatch,$ip_mismatch,$expired,$is_update_db)
      = $self->rearrange(
			 [
			  'NO_AUTH','MAC_MISMATCH','IP_MISMATCH','EXPIRED',
			  'IS_UPDATE_DB'
			 ], @_
			);
    
    $is_update_db ||= 0;

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

    # Does the viewing browser has the authentication cookie set?
    ($sid, $issueTime, $expireTime, $user, $guessIP, $guessCUID, $guessMAC) =
      $self->_getAuthInfoFromCookie( $is_update_db, $no_auth );
    unless ( defined($sid) && defined($issueTime) && defined($expireTime) &&
	     defined($user) && defined($guessIP) && defined($guessCUID) &&
	     defined($guessMAC) ) {

	if ($no_auth) {
	    eval { &{$no_auth}; };
	    croak "-no_auth must be a CODE reference." if $@;
	    return undef;
	} else {
	    $self->fatal( -alertMsg => 'No auth. cookies!!!', -isDisplay => 0 );
	    $self->_redirect_to_login_page();
	}
	
    }

    # Generate a digest of remote IP.
    # Note: some proxies have rotating IPs, can't check their IP in that case.
    #       How to get the ``true'' IP of remote browser?
    #if ( $ENV{REMOTE_HOST} =~ m:^proxy: ) { $realIP = $guessIP; }
    if ( $ENV{HTTP_VIA} ) {
	$realIP = $guessIP;
    } else {
	$realIP = $digest->generate_digest(
					   -data => $ENV{REMOTE_ADDR},
					   -key => $digest_key,
					   -algorithm => $digest_algorithm,
					   -format => $digest_format
					  );
    }

    # Generate a MAC.
    $macKey = $self->{MAC_KEY};
    $preRealMAC =
      $digest->generate_MAC(
			    -data => $sid.$issueTime.$expireTime.$user.$realIP.$guessCUID.$macKey,
			    -key => $macKey,
			    -algorithm => $digest_algorithm,
			    -format => $digest_format
			   );
    $realMAC = $digest->generate_MAC(
				     -data => $macKey.$preRealMAC,
				     -key => $macKey,
				     -algorithm => $digest_algorithm,
				     -format => $digest_format
				    );

    # MAC check.
    unless ($guessMAC eq $realMAC) {
	if ($mac_mismatch) {
	    eval { &{$mac_mismatch}; };
	    croak "-mac_mismatch must be a CODE reference." if $@;
	    return undef;
	} else {
	    $alertMsg = "MAC mis-match!!!\nGuessMAC: $guessMAC\nRealMAC: $realMAC\n";
	    $self->fatal( -alertMsg => $alertMsg, -isDisplay => 0 );
	    $self->_redirect_to_login_page();
	}
    }

    # IP check.
    unless ($guessIP eq $realIP) {
	if ($ip_mismatch) {
	    eval { &{$ip_mismatch}; };
	    croak "-ip_mismatch must be a CODE reference." if $@;
	    return undef;
	} else {
	    $alertMsg = "IP mis-match!!!\nGuessIP: $guessIP\nRealIP: $realIP\n";
	    $self->fatal( -alertMsg => $alertMsg, -isDisplay => 0 );
	    $self->_redirect_to_login_page();
	}
    }

    # Decrypt username from the authentication cookie.
    $userName = $crypt->decrypt_cipher(
				       -cipher => $user,
				       -key => $cipher_key,
				       -algorithm => $cipher_algorithm,
				       -format => $cipher_format
				      );

    # Decrypt uid from the authentication cookie.
    $uid = $crypt->decrypt_cipher(
				  -cipher => $guessCUID,
				  -key => $cipher_key,
				  -algorithm => $cipher_algorithm,
				  -format => $cipher_format
				 );

    # Decrypt the expire time from the authentication cookie.
    $decryptExpireTime =
      $crypt->decrypt_cipher(
			     -cipher => $expireTime,
			     -key => $cipher_key,
			     -algorithm => $cipher_algorithm,
			     -format => $cipher_format
			    );

    # Is the authentication cookie expired?
    unless ( $decryptExpireTime > time() ) {
	if ($expired) {
	    eval { &{$expired}; };
	    croak "-expired must be a CODE reference." if $@;
	    return undef;
	} else {
	    require LibWeb::Database;
	    $db = new LibWeb::Database();

	    # Flush the database.  Set `NUM_LOGIN_ATTEMPT' to 0.
	    $sqlStatement = "update $self->{USER_LOG_TABLE} " .
	                    "set $self->{USER_LOG_TABLE_NUM_LOGIN_ATTEMPT}=0 " .
			    "where $self->{USER_LOG_TABLE_UID}=$uid";
	    $db->do( -sql => $sqlStatement );
	    $db->finish();
    
	    # Alert admin and redirect user to login page.
	    $gmcDecryptExpireTime = localtime($decryptExpireTime);
	    $alertMsg = "Login session expired.\n " .
	                "Current time: " . localtime() . "\n " .
			"Expire time: $gmcDecryptExpireTime\n";
	    $self->fatal( -alertMsg => $alertMsg, -isDisplay => 0 );
	    $self->_redirect_to_login_page();    
	}
    }

    # Update database.
    if ( $is_update_db ) {

	require LibWeb::Database;
	$db = new LibWeb::Database();

	my $time = localtime();
	my $ip = $ENV{REMOTE_ADDR};
	my $host = $ENV{REMOTE_HOST};
	$sqlStatement = "update $self->{USER_LOG_TABLE} " .
	                "set $self->{USER_LOG_TABLE_NUM_LOGIN_ATTEMPT}=" .
			"$self->{LOGIN_INDICATOR}, " .
	                "$self->{USER_LOG_TABLE_LAST_LOGIN}='$time', " .
	                "$self->{USER_LOG_TABLE_IP}='$ip', " .
	                "$self->{USER_LOG_TABLE_HOST}='$host' " .
	                "where $self->{USER_LOG_TABLE_UID}=$uid";
	$db->do( -sql => $sqlStatement );
	$db->finish();
    }

    return ($userName, $uid);
}

sub is_login {
    #
    # This is here mainly for backward compatible with client codes
    # written using LibWeb-0.01.
    #
    shift->get_user( -is_update_db => ($_[0]) ? 1 : 0 );
}

# Selfloading methods declaration.
sub LibWeb::Session::prepare_deauth_cookie ;
1;
__DATA__

sub prepare_deauth_cookie {
    #
    # Params:
    # none.
    #
    # Pre:
    # 1. None.
    #
    # Post:
    # 1. Return prepared DeAuth cookies (array ref) for nullifying
    #    all cookies for this site on client Web browser by preparing zero/null
    #    auth cookies with an expiration date in the past.
    #
    my $self = shift;
    return
      ['B=0; path=/',
       'C=z=0&y=0&x=0&w=0&v=0&u=0&t=0; path=/; expires=' . $self->{CLASSIC_EXPIRES}];
}

1;
__END__

=head1 NAME

LibWeb:: - Sessions management for libweb applications

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

LibWeb::CGI

=item *

LibWeb::Crypt

=item *

LibWeb::Database

=item *

LibWeb::Digest

=back

=head1 ISA

=over 2

=item *

LibWeb::Core

=back

=head1 SYNOPSIS

  use LibWeb::Session;
  my $s = new LibWeb::Session();

  my ($user_name, $user_id) = $s->get_user();

  #or

  my ($user_name, $user_id)
      = $s->get_user( -is_update_db => 1 );

=head1 ABSTRACT

This class manages session authentication after the remote user has
logged in.

The current version of LibWeb::Session is available at

   http://libweb.sourceforge.net

Several LibWeb applications (LEAPs) have be written, released and are
available at

   http://leaps.sourceforge.net

=head1 TYPOGRAPHICAL CONVENTIONS AND TERMINOLOGY

Variables in all-caps (e.g. MAX_LOGIN_ATTEMPT_ALLOWED) are those
variables set through LibWeb's rc file.  Please read L<LibWeb::Core>
for more information.  All `error/help messages' mentioned can be
found at L<LibWeb::HTML::Error> and they can be customized by ISA
(making a sub-class of) LibWeb::HTML::Default. Please see
L<LibWeb::HTML::Default> for details.  Method's parameters in square
brackets means optional.

=head1 DESCRIPTION

=head2 METHODS

B<get_user()>

Check to see if the viewing Web browser has logged in by checking
expiration time, IP and MAC in the authentication cookie, and return
the user name and the user ID if it passes all the authentication
checks.

Params:

  [ -no_auth=>, -mac_mismatch=>, -ip_mismatch=>,
    -expired=>, -is_update_db=> ]

Pre:

=over 2

=item *

I<-no_auth> is a CODE reference for callback if the viewing browser
does not return an authentication cookie.

=item *

I<-mac_mismatch> is a CODE reference for callback if the
authentication cookie has been tampered with.

=item *

I<-ip_mismatch> is a CODE reference for callback if the IP in the
authentication cookie does not correspond to the IP address of the
viewing browser.

=item *

I<-expired> is a CODE reference for callback if the authentication
cookie is expired.

=item *

I<-is_update_db> is either 1 or 0 (default).  Use this to indicate
whether this is the first login check.  This parameter should be 1 in
order to update database's I<NUM_LOGIN_ATTEMPT> when a user first
logged in.

=back

Post:

=over 2

=item *

Retrieve authentication cookies from the viewing Web browser,

=item *

All I<-no_auth>, I<-mac_mismatch>, I<-ip_mismatch> and I<-expired>
default to the following actions if you do not provide the callbacks:

=over 4

=item *

Nullify and delete all authentication cookies resided on the viewing
Web browser,

=item *

send an alert e-mail to B<ADMIN_EMAIL>,

=item *

log that event in B<FATAL_LOG>,

=item *

redirect the remote user to the login page (B<LM_IN>), and

=item *

abort the current running program.

=back

=item *

Check to see If cookie values are null/zero, call I<-no_auth> if no
authentication cookie is retrieved,

=item *

Check to see If MAC matches, call I<-mac_mismatch> if not,

=item *

Check to see if If IP matches, call I<-ip_mismatch> if not,

=item *

update database: Set I<NUM_LOGIN_ATTEMPT> to 0 and call I<-expired> if
the login has expired,

=item *

If the retrieved cookie passes all the above authentication checks,
set database's I<NUM_LOGIN_ATTEMPT> to B<LOGIN_INDICATOR> if parameter
I<-is_update_db> is defined and is equal to 1.  This helps indicate
that the user is online (currently login),

=item *

and finally return an array (user name and uid) in plain text.

=back

Note:

I<USER_LOG_TABLE.NUM_LOGIN_ATTEMPT> != 0 && != B<LOGIN_INDICATOR>
means there were several attempts to login but unsuccessful solely
because incorrect password were entered by the remote user.  You need
to re-flush database's I<USER_LOG_TABLE.NUM_LOGIN_ATTEMPT> to 0
manually after receiving the alert e-mail if this value ==
B<MAX_LOGIN_ATTEMPT_ALLOWED>; otherwise, the user will never be able
to sign into your site even he/she enters the correct password
afterwards.

=head2 DEPRECATED METHODS

B<is_login()>

Note:

This method is deprecated as of LibWeb-0.02.  You are encouraged to
use B<get_user()> instead.  B<is_login()> is mainly for backward
compatible with client codes written using LibWeb-0.01.

Params:

  [ is_just_logged_in ]

Pre:

=over 2

=item *

Parameter `is_just_logged_in' is either 1 or undef.  This is to
indicate whether this is the first login check.  This parameter should
be defined in order to update database's
USER_LOG_TABLE.NUM_LOGIN_ATTEMPT when user first logged in; possibly
in the first script invoked after the user has been authenticated.

=back

Post:

=over 2

=item *

Retrieve authentication cookies from client Web browser,

=item *

if cookie values are null/zero, send an alert e-mail to ADMIN_EMAIL
and redirect the remote user to the login page (LM_IN),

=item *

if MAC mis-match (this means possible spoofing from remote host), send
an alert e-mail to ADMIN_EMAIL and redirect the remote user to the
login page (LM_IN),

=item *

if IP mis-match (this means possible spoofing from remote host), send
an alert e-mail to ADMIN_EMAIL and redirect the remote user to the
login page (LM_IN),

=item *

login is expired if expiration time reached.  Update database: set
USER_LOG_TABLE.NUM_LOGIN_ATTEMPT to 0, send an alert e-mail to
ADMIN_EMAIL and redirect the remote user to the login page (LM_IN),

=item *

nullify and delete all cookies reside on client Web browser
immediately if any of item 2, 3, 4 or 5 happens.  Send an alert e-mail
to ADMIN_EMAIL and redirect the remote user to the login page (LM_IN),

=item *

if client has officially logged in and none of item 2, 3, 4 or 5
happens, set USER_LOG_TABLE.NUM_LOGIN_ATTEMPT to LOGIN_INDICATOR if
parameter `is_just_logged_in' is defined.  This helps to indicate that
the user is online (currently logged in), and

=item *

finally return an array (user name and uid) in plain text.

=back

Note:
USER_LOG_TABLE.NUM_LOGIN_ATTEMPT != 0 && != LOGIN_INDICATOR means
there were several attempts to login but unsuccessful solely because
incorrect password were entered by the remote user.  You need to
re-flush NUM_LOGIN_ATTEMPT to 0 manually after 24 hours (no rigorous
reason why it should be 24 hours) of receiving the alert e-mail if
this value == MAX_LOGIN_ATTEMPT_ALLOWED.

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS


=head1 BUGS


=head1 SEE ALSO

L<LibWeb::Admin>, L<LibWeb::Core>, L<LibWeb::Crypt> L<LibWeb::Digest>.

=cut
