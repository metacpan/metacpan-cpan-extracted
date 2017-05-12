#==============================================================================
# LibWeb::HTML::Error -- Displaying error messages (`stderr') in html for libweb
#                        applications.

package LibWeb::HTML::Error;

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

# $Id: Error.pm,v 1.6 2000/07/19 20:31:57 ckyc Exp $

$VERSION = '0.02';

# Contains site's common help instructions for users when error occurs.
# Please DO NOT make this a subclass of any class in the LibWeb package
# since it will generate infinite loop at initialization due to the fact
# that LibWeb::Core uses this module.  Also please do not put any ``use''
# statement in this class to use any LibWeb classes.  Same reason applies.
# Any idea of how to improve this?

#-##############################
# Use standard libraries.
use SelfLoader;
use Carp;
use strict;
use vars qw($VERSION);

#-##############################
# Methods.
sub new {
    #
    # You don't use or ISA this class directly.  Use or ISA
    # LibWeb::HTML::Default instead.
    #
    my $class = shift;
    bless( {}, ref($class) || $class );
}

sub DESTROY {}

# Selfloading methods declaration.
sub LibWeb::HTML::Error::cookie_error ;
sub LibWeb::HTML::Error::database_error ;
sub LibWeb::HTML::Error::display_error ;
sub LibWeb::HTML::Error::exceeded_max_login_attempt ;
sub LibWeb::HTML::Error::hit_back_and_edit ;
sub LibWeb::HTML::Error::login_expired ;
sub LibWeb::HTML::Error::login_failed ;
sub LibWeb::HTML::Error::logout_failed ;
sub LibWeb::HTML::Error::mysterious_error ;
sub LibWeb::HTML::Error::post_too_large ;
sub LibWeb::HTML::Error::registration_failed ;
sub LibWeb::HTML::Error::special_characters_not_allowed ;
1;
__DATA__

sub display_error {
    #
    # Params: $caller, $error_msg, $error_input, $help_msg
    #
    # $caller is a ref. to the calling object.
    # All other parameters are scalars except $help_msg which must be a
    # SCALAR ref.
    #
    my ($caller, $error_msg, $error_input, $err_input_display, $help_msg);
    shift;
    $caller = shift;
    ($error_msg, $error_input, $help_msg) = @_;
    croak "-helpMsg must be a SCALAR reference."
      unless ( ref($help_msg) eq 'SCALAR' );
    $err_input_display = ($error_input ne ' ') ?
                         "<b><big>The erroneous input:</big></b>".
                         "<p><font color=\"red\">$error_input</font>" : 
			 ' ';

return \<<HTML;
<html><head><title>$caller->{SITE_NAME}</title>
<link rel="stylesheet" href="$caller->{CSS}"></head>
<body bgcolor="$caller->{SITE_BG_COLOR}" text="$caller->{SITE_TXT_COLOR}">
<center>
<a href="/"><img src="$caller->{SITE_LOGO}" border="0" alt="$caller->{SITE_NAME}"></a>
<table border=0 cellpadding=0 cellspacing=0 width="65%" bgcolor="$caller->{SITE_BG_COLOR}">

<Tr><td>
<table border=0 cellpadding=1 cellspacing=0 width="100%" bgcolor="$caller->{SITE_LIQUID_COLOR5}">
<Tr><td>
<table border=0 cellpadding=0 cellspacing=0 width="100%" bgcolor="$caller->{SITE_LIQUID_COLOR3}">
<Tr><td bgcolor="$caller->{SITE_LIQUID_COLOR3}" align="center">
<font color="$caller->{SITE_TXT_COLOR}"><b>Error</b></font>
</td></Tr></table>
</td></Tr></table>
</td><Tr>

<Tr><td>
<table border=0 cellpadding=7 cellspacing=0 width="100%" bgcolor="$caller->{SITE_BG_COLOR}"><Tr><td>
<p><b><big>The following error has occurred:</big></b>
<p>$error_msg
<p>$err_input_display
<p><b><big>Suggested help:</big></b>
<p>$$help_msg
</td></Tr></table>
</td></Tr>

</table><br>
<table border=0 width="60%"><Tr><td align="center"><hr size=1>
Copyright&nbsp;&copy;&nbsp;$caller->{SITE_YEAR}&nbsp;$caller->{SITE_NAME}.  All rights reserved.<br>
<a href="$caller->{TOS}">Terms of Service.</a> &nbsp;
<a href="$caller->{PRIVACY_POLICY}">Privacy Policy.</a>
</td></Tr></table></center>
</body></html>
HTML
}

#==================================================================================
# Begin of methods returning error/help messages.
sub mysterious_error {
return \<<HTML;
Our programmers are working on the page you have requested.  Please
<a href="javascript:history.go(-1);">click here</a> or hit the ``back'' button on
your browser and try again at a later time.  The site administrator has already
been notified of your request.  It may be helpful if you could contact us with any
additional information about your situation if the problem persists.  Thank you.
HTML
}

sub special_characters_not_allowed {
return \<<HTML;
For security reasons, we cannot process special characters (i.e. non-numeric or
non-alphabetical characters) in certain contexts.  Please
<a href="javascript:history.go(-1);">click here</a> or hit the ``back'' button on
your browser and try again by using only numbers and alphabets.  The site
administrator has already been notified of your request.  It may be helpful if you
could contact us with any additional information about your situation if the
problem persists.  Thank you.
HTML
}

sub hit_back_and_edit {
return \<<HTML;
Please <a href="javascript:history.go(-1);">click here</a> or hit the ``back''
button on your browser and edit.
HTML
}

sub post_too_large {
return \<<HTML;
This is probably because you have posted/sent some huge data to our site.
Please <a href="javascript:history.go(-1);">click here</a>
or hit the ``back'' button on your browser and try again with smaller, legitimate
post.  The site administrator has already been notified of your request.
It may be helpful if you could contact us with any additional information about
your situation if the problem persists.  Thank you.
HTML
}

sub database_error {
return \<<HTML;
Our programmers are working on the page you have requested.  Please
<a href="javascript:history.go(-1);">click here</a> or hit the ``back'' button on
your browser and try again at a later time.  The site administrator has already been
notified of your request.  It may be helpful if you could contact us with any
additional information about your situation if the problem persists.  Thank you.
HTML
}

sub login_failed {
return \<<HTML;
Your login is incorrect.  Please <a href="javascript:history.go(-1);">click here</a>
or hit the ``back'' button on your browser and try again.  The site administrator
has already been notified of your request.  It may be helpful if you could contact
us with any additional information about your situation if the problem persists.
Thank you.
HTML
}

sub logout_failed {
return \<<HTML;
Logout failed. Please <a href="javascript:history.go(-1);">click here</a>
or hit the ``back'' button on your browser and try again. The site administrator has
already been notified of your request.  It may be helpful if you could contact us
with any additional information about your situation if the problem persists.
Thank you.
HTML
}

sub login_expired {
return \<<HTML;
Your login session has expired.  Please re-login.  The site administrator has
already been notified of your request.  It may be helpful if you could contact us
with any additional information about your situation if the problem persists.
Thank you.
HTML
}

sub exceeded_max_login_attempt {
return \<<HTML;
Exceeded maximum login attempt allowed.  Please try again later.  The site
administrator has already been notified of your request.  It may be helpful if you
could contact us with any additional information about your situation if the
problem persists.  Thank you.
HTML
}

sub registration_failed {
return \<<HTML;
This may be because our programmers are working on the page you have requested.
Please <a href="javascript:history.go(-1);">click here</a> or hit the ``back''
button on your browser and try again later.  The site administrator has already
been notified of your request.  It may be helpful if you could contact us with
any additional information about your situation if the problem persists.  Thank you.
HTML
}

sub cookie_error {
return \<<HTML;
<p>Please enable your browser to accept cookies.
We use session cookies to identify who you are so you can use our applications.
We do not use cookies to collect personal information.

<p>Select the proper setting from the list below for instructions on how to set up
your system to allow cookies.  Then, please
<a href="javascript:history.go(-1);">click here</a> or hit the ``back'' button on
your browser and try again.  Thank you.


<p>Microsoft Internet Explorer 5.0 (Windows) 
<br>
1. Click on the Tools menu<br>
2. Click on 'Internet Options'<br> 
3. Click on the Security tab<br>
4. Click on the 'Custom Level' button<br> 
5. Scroll down to the Cookies section<br>
6. Select 'Enable'<br>
7. Click 'OK'<br>
		
<p>Microsoft Internet Explorer 4.0 (Windows) 
<br>
1. Click on the View menu<br> 
2. Click on 'Internet Options'<br> 
3. Click on the Advanced tab<br>
4. Scroll down to the Security/Cookies section<br>
5. Select 'Always Accept Cookies'<br>
6. Click 'OK'<br> 

<p>Microsoft Internet Explorer 3.0 or 4.0+ (Macintosh) 
<br>
1. Click on 'Preferences'<br>
2. Under 'Receiving Files,' click Cookies<br>
3. Click on 'Never Ask'<br>
4. Click 'OK'<br>

<p>Netscape Navigator/Communicator 4.0+ (Linux/BSD/Solaris/Windows/Macintosh) 
<br>
1. Click on the Edit menu<br> 
2. Click on 'Preferences'<br> 
3. Click on 'Advanced'<br>
4. Select 'Accept all cookies'<br>
5. Click 'OK'<br>

<p>AOL (Windows)
<br> 
1. Click on the 'My AOL' toolbar icon<br>
2. Click on 'Preferences'<br>
3. Click on 'WWW'<br>
4. Click on the Security tab<br>
5. Click on the 'Custom Level' button<br>
6. Scroll down to the Cookies section<br>
7. Select 'Enable'<br>
8. Click 'OK'<br>
HTML
}

1;
__END__

=head1 NAME

LibWeb::HTML::Error - Displaying error messages in html for libweb
applications

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

No non-standard Perl's library is required.

=back

=head1 ISA

=over 2

=item *

None.

=back

=head1 SYNOPSIS

You do not use this class directly; use LibWeb::HTML::Default instead.
See L<LibWeb::HTML::Default>.

=head1 ABSTRACT

This class defines a method for displaying error messages in HTML.
Several basic error messages are also defined.

The current version of LibWeb::HTML::Error is available at

   http://libweb.sourceforge.net

Several LibWeb applications (LEAPs) have be written, released and
are available at

   http://leaps.sourceforge.net

=head1 DESCRIPTION

=head2 METHODS

B<display_error()>

Params:

=over 2

=item I<caller>, I<error_msg>, I<error_input>, I<help_msg>

=back

Pre:

=over 2

=item *

I<caller> is a reference to the calling object.  All other parameters
are scalars except I<help_msg> which must be a SCALAR reference.

=back

Post:

=over 2

=item *

Display a HTML page with the error message, error input and help
message.

=back

NOTE:

Do not call this method directly, call LibWeb::Core::fatal() instead.
See L<LibWeb::Core> for details.

All of the following methods return a SCALAR reference to an error
message in HTML.

B<mysterious_error()>

B<special_characters_not_allowed()>

B<hit_back_and_edit()>

B<post_too_large()>

B<database_error()>

B<login_failed()>

B<logout_failed()>

B<login_expired()>

B<exceeded_max_login_attempt()>

B<registration_failed()>

B<cookie_error()>

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=head1 BUGS

=head1 SEE ALSO

L<LibWeb::Core>, L<LibWeb::HTML::Standard>, L<LibWeb::HTML::Default>.

=cut
