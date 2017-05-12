#!/usr/bin/perl -w

#======================================================================
# lm.cgi -- LogManager, a sample script to demonstrate how to write a
#           login script using LibWeb.
#
# Copyright (C) 2000  Colin Kong
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.
#
#======================================================================

# $Id: lm.cgi,v 1.4 2000/07/18 06:33:30 ckyc Exp $

#=============================================================
# Begin edit.

# Uncomment the following line and edit the path if you have
# installed LibWeb into non-standard Perl's library locations.
#use lib '/path/to/LibWeb';

# Where is your LibWeb rc (config) file located?
# (Absolute path; NOT url).
my $Rc_file = '/home/me/dot_lwrc';

# When a remote user has signed up, this script will send
# her/him an e-mail message.  Put your message here.
my $msg_to_new_user = 'Welcome.  Thank you for signing up.';

# Assign 0 if you do not want to send an e-mail to new user.
my $is_send_mail_to_new_user = 1;

# The first script (relative URL) to which the user will be directed
# once he/she has been authenticated.  Make sure to use
# LibWeb::Session in that script!!
my $first_script = '/cgi-bin/first_script.cgi';

# For debugging cgi script via a web browser.
# Should be commented out in production release of this script.
use CGI::Carp qw(fatalsToBrowser);

# End edit.
#=============================================================

# Make perl taint mode happy.
$ENV{PATH} = "";

#-###########################
#  Use standard libraries.
use strict;

#-###########################
#  Use custom libraries.
require LibWeb::HTML::Default;
require LibWeb::Themes::Default;
require LibWeb::CGI;
require LibWeb::Database;
require LibWeb::Admin;

#-###########################
#  Global variables.
my $html = LibWeb::HTML::Default->new( $Rc_file );
my $themes = LibWeb::Themes::Default->new();
my $a = LibWeb::Admin->new();
my $q = LibWeb::CGI->new();
my $db = LibWeb::Database->new();
my $this = $ENV{SCRIPT_NAME};

#-###########################
#  CGI parameters.
my $p_a = '.a';
my $p_user_name = 'user_name';
my $p_guess = 'password';
my $p_new_guess1 = 'new_password_1';
my $p_new_guess2 = 'new_password_2';
my $p_email = 'email';
my $p_is_just_login = '.b';
my $p_is_first_time = '.c';
my $p_login_form = 'login_form';
my $p_new_form = 'new_form';
my $a_login = 'login';
my $a_logout = 'logout';
my $a_is_logout = 'is_logout';
my $a_new = 'new';
my $action = $q->parameter($p_a);

#-###########################
#  MAIN.
if ($action eq $a_login) { login(); }
elsif ($action eq $a_logout) { logout(); }
elsif ($action eq $a_is_logout) { is_logout(); }
elsif ($action eq $a_new) { add_new_user(); }
else { print_login_page(); }
exit(0);

#-###########################
# Subroutines
sub login {
    ## If the user is authenticated, redirect him/her to his/her control panel.
    my ($user_name, $guess, $is_just_login);
    $user_name = $q->parameter($p_user_name);
    $guess = $q->parameter($p_guess);

    ## Input checking.
    $a->fatal(-msg => 'User name not entered.',
	      -alertMsg => 'lm.cgi::login(): user name not entered.',
	      -helpMsg => $html->hit_back_and_edit())
      unless defined($user_name);
    $a->fatal(-msg => 'Password not entered.',
	      -alertMsg => "lm.cgi::login(): password not entered for user: $user_name",
	      -helpMsg => $html->hit_back_and_edit())
      unless defined($guess);

    if ( $a->login($user_name, $guess) ) {
	$is_just_login = int( rand($a->{RAND_RANGE}) );
	$q->redirect( -url => $first_script . "?$p_is_just_login=$is_just_login" );
    } else {
	$a->fatal(-msg => 'Incorrect login.',
		  -alertMsg => 'lm.cgi::login(): could not login.',
		  -helpMsg => $html->login_failed());
    }
}

sub logout {
    if ( $a->logout() ) { $q->redirect( -url => "${this}?$p_a=$a_is_logout" ); }
    else {
	$a->fatal(-msg => 'Logout failed.',
		  -alertMsg => 'Could not logout.',
		  -helpMsg => $html->logout_failed());
    }
}

sub is_logout {
    ##
    # Check to see if cookie has been nullified and deleted on remote
    # client Web browser.  Print a confirmation message if so.
    if ( $a->is_logout() ) { print_is_logout_page(); }
    else {
	$a->fatal(-msg => 'Logout failed.',
		  -alertMsg => 'lm.cgi::is_logout: could not logout.',
		  -helpMsg => $html->logout_failed());
    }
}

sub add_new_user {
    ## Add new user to database and redirect him/her to the control panel.
    my ($user_name, $guess1, $guess2, $email, $is_just_login, $is_first_time);
    $user_name = $q->parameter($p_user_name);
    $guess1 = $q->parameter($p_new_guess1);
    $guess2 = $q->parameter($p_new_guess2);
    $email = $q->parameter($p_email);

    ## Input checking.
    $a->fatal(-msg => 'User name not entered.',
	      -alertMsg => 'lm.cgi::add_new_user(): user name not entered.',
	      -helpMsg => $html->hit_back_and_edit())
      unless defined($user_name);
    $a->fatal(-msg => 'Password not entered.',
	      -alertMsg => 'lm.cgi::add_new_user(): password not entered.',
	      -helpMsg => $html->hit_back_and_edit())
      unless defined($guess1);
    $a->fatal(-msg => 'Email address not entered.',
	      -alertMsg => 'lm.cgi::add_new_user(): email not entered.',
	      -helpMsg => $html->hit_back_and_edit())
      unless defined($email);
    $a->fatal(-msg => 'Passwords do not match.',
	      -alertMsg => 'lm.cgi::add_new_user(): passwords do not match.',
	      -helpMsg => $html->hit_back_and_edit())
      unless ( $guess2 eq $guess1 );
    
    if ( $a->add_new_user(-user=>$user_name,-password=>$guess1,-email=>$email) ) {

	if ($is_send_mail_to_new_user) {
	    $a->send_mail( -to => $email, -from => $a->{ADMIN_EMAIL},
			   -subject => "$a->{SITE_NAME} welcomes you,  $user_name!",
			   -msg => _email_msg_to_new_user($user_name) );
	}

	$a->login( $user_name, $guess1 );
	$is_just_login = int( rand( $a->{RAND_RANGE} ) );
	$is_first_time = int( rand( $a->{RAND_RANGE} ) );
	$q->redirect( -url => $first_script . "?$p_is_just_login=$is_just_login&" .
		              "$p_is_first_time=$is_first_time" );

    } else {

	$a->fatal(-msg => 'Registration failed.',
		  -alertMsg => 'lm.cgi::add_new_user(): registration failed.' .
		               "Username: $user_name Password: $guess1 Email: $email",
		  -helpMsg => $html->registration_failed());

    }
}

sub _email_msg_to_new_user {
    #
    # Args: $new_user_name (scalar).
    #
return \<<EOM;
Hello $_[0],
$msg_to_new_user
EOM
}

sub print_login_page {
    # Print out a HTML login page, which also allows new user to sign up.
    $q->delete_all();
    $q->autoEscape(undef);
    ##
    # Set the expire date of the login page so that anything entered in the
    # login form will not show up again once leave the page.
    print $q->header( -expires => $a->{CLASSIC_EXPIRES} );
    print ${ _login_page_html() };
}

sub print_is_logout_page {
    # Print out a HTML page confirming that the remote user has successfully
    # logged out.
    $q->delete_all();
    $q->autoEscape(undef);
    print $q->header();
    print ${ _is_logout_page_html() };
}

#-##############################
# Page constructs.
sub _sheader {
    return undef; # Use LibWeb::HTML::Default sheader.
}

sub _lpanel {
    return undef; # Use LibWeb::HTML::Default lpanel.
}

sub _rpanel {
    return undef; # Use LibWeb::HTML::Default rpanle.
}

sub _header {
    return undef; # Use LibWeb::HTML::Default header.
}

sub _footer {
my $r = \<<HTML;
<script language="JavaScript">
<!--
  document.$p_login_form.$p_user_name.focus();
// -->
</script>

<center><table border=0 width="60%"><Tr><td align="center"><hr size=1>
Copyright&nbsp;&copy;&nbsp;$html->{SITE_YEAR}&nbsp;$html->{SITE_NAME}.  All rights reserved.<br>
<a href="$html->{TOS}">Terms of Service.</a> &nbsp;
<a href="$html->{PRIVACY_POLICY}">Privacy Policy.</a>
</td></Tr></table></center>
HTML
return [ $r ];
}

#-#####################################
# HTML pages.
sub _login_page_html {
    my ($sign_in, $sign_in_form, $registration,
	$registration_form, $terms);

    $terms = 'By submitting your registration information, you indicate that you ' .
             'agree to the ' .
	     $q->a( {-href=>"$a->{TOS}"}, 'Terms of Service' ) . '.'; 

    $sign_in_form = $q->start_form( { -name => $p_login_form,
				      -action => $this,
				      -autocomplete => 'off' } ) .
		    $q->hidden( -name => $p_a, -default => $a_login ) .					
		    $q->start_table( {width=>'100%'} ) .
                    $q->Tr(
			   $q->td( {-align=>'right', -width=>'30%'}, ' User name: ' ),
			   $q->td( {-align=>'left', -width=>'70%'},
				   $q->textfield(-name=>$p_user_name,
						 -maxlength=>'30',
						 -override=>1) )
			  ) .
		    $q->Tr(
			   $q->td( {-align=>'right', -width=>'30%'}, ' Password: ' ),
			   $q->td( {-align=>'left', -width=>'70%'},
				   $q->password_field(-name=>$p_guess,
						      -maxlength=>'30',
						      -override=>1),
				   $q->submit('Go!') )
			  ) .
		    $q->end_table() . $q->end_form();
		    
    $sign_in = $themes->titled_table( -title => 'Sign in', -title_align => 'left',
				      -title_bg_color => $a->{SITE_LIQUID_COLOR3},
				      -content => [\$sign_in_form] );

    $registration_form = $q->start_form( { -action => $this,
					   -name => $p_new_form,
					   -autocomplete => 'off' } ) .
			 $q->hidden( -name => $p_a, -default => $a_new ) .
			 $q->start_table( {width=>'100%'} ) .
                         $q->Tr(
				$q->td( {-align=>'right', -width=>'30%'}, 'Pick a user name: '),
				$q->td( {-align=>'left', -width=>'70%'},
					 $q->textfield(-name=>$p_user_name,
						       -maxlength=>'30',
						       -override=>1) )
				) .
			 $q->Tr(
				$q->td( {-align=>'right', -width=>'30%'}, 'Pick a password: ' ),
				$q->td( {-align=>'left', -width=>'70%'},
					$q->password_field(-name=>$p_new_guess1,
							   -maxlength=>'30',
							   -override=>1) )
				) .
			 $q->Tr(
				$q->td( {-align=>'right', -width=>'30%'}, 'Re-enter password: ' ),
				$q->td( {-align=>'left', -width=>'70%'},
					$q->password_field(-name=>$p_new_guess2,
							   -maxlength=>'30',
							   -override=>1) )
				) .
			 $q->Tr(
				$q->td( {-align=>'right', -width=>'30%'}, 'Current email address: ' ),
				$q->td( {-align=>'left', -width=>'70%'},
					$q->textfield(-name=>$p_email,
						      -maxlength=>'40',
						      -override=>1) )
				) .
			 $q->end_table() .
			 $q->start_table( {-width=>'100%'} ) .
			 $q->Tr(
				$q->td( $terms ),
				$q->td( {-align=>'right'}, $q->submit('Submit') )
			       ) .
			 $q->end_table() .
			 $q->end_form();

    $registration = $themes->titled_table( -title => 'New sign up',
					   -title_bg_color => $a->{SITE_LIQUID_COLOR3},
					   -title_align => 'left',
					   -content => [\$registration_form] );

    return $html->display(
			  -content => [$sign_in, $registration],
			  -sheader => _sheader(), -lpanel => _lpanel(),
			  -rpanel => _rpanel(), -header => _header(),
			  -footer => _footer()
			 );
}

sub _is_logout_page_html {
    my ($content, $display);
    return $html->display( -sheader =>
			    ['<BIG>You have logged out successfully.</BIG>'] );
}

1;
__END__
