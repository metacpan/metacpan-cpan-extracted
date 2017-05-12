#!/usr/bin/perl -w

#======================================================================
# lw.cgi -- a perl script for LibWeb administration and to test LibWeb
#           installation.
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

# $Id: lw.cgi,v 1.6 2000/07/19 20:31:57 ckyc Exp $

#-##########
# Begin edit.

# Uncomment the following line and edit the path if you have
# installed LibWeb into non-standard Perl's library locations.
#use lib '/home/me/my_perl_lib';

# Where is your LibWeb rc (config) file located?
# (Absolute path; NOT url).
my $Rc_file = '/home/me/dot_lwrc';

# Your admin account login and UID.  You can change $Admin_name
# ('root') but please remember it since you need that name to register
# an admin account.  For $Admin_uid, most database starts from 1 for
# an auto-increment field (UID is an auto-increment field, see the
# file USER_PROFILE.sql for details).  Therefore, it should probably
# be 1.
my ($Admin_name,$Admin_uid) = ('root',1);

# For debugging cgi perl script via a web browser.
# Should be commented out in production release of this script.
use CGI::Carp qw(fatalsToBrowser);

# End edit.
#-##########

## Make perl taint mode happy.
$ENV{PATH} = "";

#-#############################
# Use standard libraries.
use strict;

#-#############################
# Use custom libraries.
require LibWeb::HTML::Default;
require LibWeb::Themes::Default;
require LibWeb::CGI;
require LibWeb::Database;
require LibWeb::Admin;
require LibWeb::File;
require LibWeb::Time;

#-#############################
# LibWeb objects.
my $Html = LibWeb::HTML::Default->new( $Rc_file );
my $Theme = LibWeb::Themes::Default->new();
my $CGI = LibWeb::CGI->new();
my $Db = LibWeb::Database->new();
my $Session = LibWeb::Session->new();
my $Admin = LibWeb::Admin->new();
my $File = LibWeb::File->new();
my $Time = LibWeb::Time->new();
my $This = $ENV{SCRIPT_NAME};

#-#############################
# CGI parameters.
my %P = (
	 # General
	 'action' => '.a', 'page' => '.page',
	 # Admin
	 'registration_form' => '.reg_form', 'login_form' => '.login_form', 
	 'user_name' => 'user_name', 'guess' => 'password',
	 'new_user_name' => 'new_user_name', 'new_guess1' => 'password',
	 'new_guess2' => 'password_re-entry', 'new_email' => 'new_email',
	 'is_just_logged_in' => '.ijli',
	 # Tests
	 'Tests_err_msg' => '.err_msg'
	);

my %A = (
	 # Home
	 'Home' => 'Home',
	 # Admin
	 'Admin' => 'Admin',
	 'Admin_login' => 'Admin_login',
	 'Admin_logout' => 'Admin_logout',
	 'Admin_register' => 'Admin_register',
	 'Admin_control_panel' => 'Admin_cp',
	 'Admin_show_logs_and_profiles' => 'Admin_slp',
	 'Admin_show_server_and_browser_info' => 'Admin_ssbi',
	 # Tests
	 'Tests' => 'Tests',
	 'Tests_mail_admin' => 'mail_admin',
	 'Tests_mail_author' => 'mail_author'
	);

#-#############################
# Pager.
my %Pages = ( 'Home'=>0, 'Admin'=>1, 'Tests'=>2 );
my @Pages;
foreach ('Home','Admin','Tests') {
    push(@Pages,
	 "<A HREF=\"${This}?$P{page}=$_\"><FONT COLOR=\"$Html->{SITE_BG_COLOR}\"><B>$_</B></FONT></A>");
}

#-#############################
# MAIN.
my $display;
my $Page = $CGI->parameter($P{page}) || 'Home';
my $Tests_err_msg = $CGI->parameter( $P{Tests_err_msg} );
my $Action = $CGI->parameter( $P{action} );
$display = eval "${Page}_page()";
die "$@ " if ($@);
$CGI->delete_all();
print $CGI->header( -expires => $Html->{CLASSIC_EXPIRES} );
print $$display;
exit(0);

#-#############################
# Home page.
sub Home_page {
    my $congratulations =
      $Theme->enlighted_titled_table(
				     -title => 'Installation succeeded!',
				     -content => [ _congratulation_msg_phtml() ]
				    );

    my $contents = [ $congratulations ];
    return $Html->display(
			  -header => _header(), -sheader => _sheader(),
			  -lpanel => _lpanel(), -content => $contents,
			  -rpanel => _rpanel(), -footer => _footer()
			 );
}

sub _congratulation_msg_phtml {
    my $time = $Time->get_datetime();
return \<<HTML;
<br>$time<br>
<p>Congratulations!  LibWeb has been successfully installed for
$Html->{SITE_NAME}.  For more information on how LibWeb can help you
rapidly develop Web applications, please read the documentation
available at
<a href="http://libweb.sourceforge.net">LibWeb's home page</a>.</p>
<p>If you are looking for more information on plug-and-play Web
applications for Web site with LibWeb installed, please go to the
<a href="http://leaps.sourceforge.net">LEAPs' home page</a>.</p>
<p>Thank you.</p>
HTML
}

#-#############################
# Admin page.
sub Admin_page {
    my ($admin,$uid,$contents);
    
    if ( $CGI->parameter($P{is_just_logged_in}) ) {
	($admin, $uid) = $Admin->get_user( -no_auth => sub{}, -is_update_db => 1 );
    } else {
	($admin, $uid) = $Admin->get_user( -no_auth => sub{} );
    }

    if ( $Action eq $A{Admin_logout} ) {
	# Remove authentication cookie from remote browser.

	$contents = [ _logout() ];

    } elsif ( $Action eq $A{Admin_login} ) {
	# Try to authenticate remote browser.

	_login();

    } elsif ( $Action eq $A{Admin_register} ) {
	# Create an admin account.

	$contents = [ _create_account() ];

    } elsif ( !$admin || !$uid ) {
	# Remote browser has not been authenticated yet.

	my $login =
	  $Theme->titled_table( -title => 'Sign in',
				-title_align => 'left',
				-content => [ _login_form_phtml() ] );
	my $registration =
	  $Theme->titled_table( -title => 'Create an account',
				-title_align => 'left',
				-content => [ _registration_form_phtml() ] );
	
	$contents = [ $login, $registration ];

    } elsif ( ($admin eq $Admin_name) && ($uid == $Admin_uid) ) {
	# Remote browser has been authenticated as admin.

	return _Admin_control_panel_html();

    } else {
	# Remote browser has not been authenticated as admin.

	$Html->fatal( -msg => 'Permission denied.',
		      -alertMsg =>
		      "Someone tried to view your LibWeb's admin page.",
		      -helpMsg =>
		      \ 'Sorry, you do not have permission to view this page.' );
    }

    return $Html->display(
			  -header => _header(), -sheader => _sheader(),
			  -lpanel => _lpanel(), -content => $contents,
			  -rpanel => _rpanel(), -footer => _footer()
			 );
}

sub _Admin_control_panel_html {
    # Must return a SCALAR reference to a HTML page.
    my ($lpanel,$rpanel,$contents);

    my $nav = $Theme->titled_table( -title => 'Admin options', 
				    -content => [_admin_options_phtml()] );
    my $wiol = $Theme->bordered_titled_table( -title => 'Users online',
					      -title_align => 'left',
					      -content => [_who_is_online_phtml()] );
    $lpanel = [ $wiol ];
    $rpanel = [ $nav ];

    if ( $Action eq $A{Admin_show_logs_and_profiles} ) {

	my $lt = $Theme->enlighted_titled_table( -title => 'User logs table',
						 -content => [_user_log_table_phtml()] );
	my $pt = $Theme->enlighted_titled_table( -title => 'User profiles table',
						 -content => [_user_profile_table_phtml()] );
	$contents = [ $pt, '<br>', $lt ];

    } elsif ( $Action eq $A{Admin_show_server_and_browser_info} ) {

	my $pi = $Theme->titled_table( -title => 'Perl INC',
				       -content => [_perl_inc_phtml()] );
	my $bs = $Theme->titled_table( -title => 'Browser / server status',
				       -content => [_browser_server_status_phtml()] );   
	
	$contents = [ $bs, '<br>', $pi ];

    } else {
	$contents = [ _admin_intro_phtml() ];
    }

    return $Html->display( -header => _header(), -sheader => _sheader(),
			   -lpanel => $lpanel, -content => $contents,
			   -rpanel => $rpanel, -footer => _footer() );
}

sub _admin_intro_phtml {
return \<<HTML;
I plan to add more admin features, please post on
<A HREF="http://sourceforge.net/forum/?group_id=5501">LibWeb's message board</A>
or send me an e-mail
<A HREF="mailto:ckyc\@users.sourceforge.net">ckyc\@users.sourceforge.net</A>
if you wish any feature to be added.  I'll try my best to implement
your request if possible.  Thank you.
HTML
}

sub _admin_options_phtml {
return \<<HTML;
<UL>
<LI><A HREF="${This}?$P{page}=$A{Admin}">Admin main page</A></LI>
<LI><A HREF="${This}?$P{page}=$A{Admin}&$P{action}=$A{Admin_show_logs_and_profiles}">User profiles & logs</A></LI>
<LI><A HREF="${This}?$P{page}=$A{Admin}&$P{action}=$A{Admin_show_server_and_browser_info}">Sever / browser info</A></LI>
<LI><A HREF="${This}?$P{page}=$A{Admin}&$P{action}=$A{Admin_logout}">logout</A></LI>
</UL>
HTML
}

sub _who_is_online_phtml {
    my ($fetch, $user, @users, $ret);
    $fetch = $Db->query( -sql => $ { _who_is_online_sql() },
			 -bind_cols => [\$user] );
    while ( &$fetch ) {
	push @users, "<TD>$user</TD>";
    }
    $Db->finish();
    
    $ret = $CGI->start_table() . $CGI->Tr( \@users ) . $CGI->end_table();
    return \$ret;
}

sub _who_is_online_sql {
return \<<SQL;
select $Db->{USER_PROFILE_TABLE}.$Db->{USER_PROFILE_TABLE_NAME}
from $Db->{USER_PROFILE_TABLE}, $Db->{USER_LOG_TABLE}
where $Db->{USER_LOG_TABLE}.$Db->{USER_LOG_TABLE_NUM_LOGIN_ATTEMPT}=
$Db->{LOGIN_INDICATOR} and
$Db->{USER_PROFILE_TABLE}.$Db->{USER_PROFILE_TABLE_UID}=
$Db->{USER_LOG_TABLE}.$Db->{USER_LOG_TABLE_UID}
order by $Db->{USER_PROFILE_TABLE}.$Db->{USER_PROFILE_TABLE_NAME}
SQL
}

sub _user_log_table_phtml {
  my ($fetch, $row_num, $row_color, @rows, $uid, $num_login_attempt, $last_login,
      $ip, $host, $edit_link, $delete_link, $ret);

  ## Table headings.
  push @rows, $CGI->th( { -bgcolor => $Html->{SITE_LIQUID_COLOR3} },
			 [ 'UID', 'Login attempts', 'Last login', 'IP', 'Host',
			   'Edit', 'Delete' ] );

  ## Fetch info from database.
  $fetch =
    $Db->query( -sql => $ { _user_log_table_sql() },
		-bind_cols => [\$uid, \$num_login_attempt, \$last_login, \$ip, \$host] );

  ## Build the table.
  $row_num = 1;
  while ( &$fetch ) {
      $edit_link = 'Edit';
      $delete_link = 'Delete';
      $row_color = ($row_num % 2) ? $Html->{SITE_LIQUID_COLOR1} : $Html->{SITE_LIQUID_COLOR2};
      push @rows, $CGI->td( {-bgcolor => $row_color},
			    [ $uid, $num_login_attempt, $last_login,
			      $ip||'&nbsp;', $host||'&nbsp;',
			      $edit_link, $delete_link ] );
      $row_num++;
  }
  $Db->finish();
  $ret = $CGI->start_table( {-width => '100%', -border => 0, -cellspacing => 1,
			     -cellpadding => 2} ).
         $CGI->Tr( \@rows ) . $CGI->end_table();

  return \$ret;
}

sub _user_log_table_sql {
return \<<SQL;
select * from $Db->{USER_LOG_TABLE}
order by $Db->{USER_LOG_TABLE_UID}
SQL
}

sub _user_profile_table_phtml {
  my ($fetch, $row_num, $row_color, @rows, $uid, $name, $pass, $email,
      $edit_link, $delete_link, $ret);

  ## Table headings.
  push @rows, $CGI->th( { -bgcolor => $Html->{SITE_LIQUID_COLOR3} },
			[ 'UID', 'Name', 'Password', 'E-mail', 'Edit', 'Delete' ] );

  ## Fetch info from database.
  $fetch =
    $Db->query( -sql => $ { _user_profile_table_sql() },
		-bind_cols => [\$uid, \$name, \$pass, \$email] );

  ## Build the table.
  $row_num = 1;
  while ( &$fetch ) {
      $edit_link = 'Edit';
      $delete_link = 'Delete';
      $row_color = ($row_num % 2) ? $Html->{SITE_LIQUID_COLOR1} : $Html->{SITE_LIQUID_COLOR2};
      push @rows, $CGI->td( {-bgcolor => $row_color},
			    [ $uid, $name, '*', $email, $edit_link, $delete_link ] );
      $row_num++;
  }
  $Db->finish();
  $ret = $CGI->start_table( {-width => '100%', -border => 0, -cellspacing => 1,
			     -cellpadding => 2} ).
	 $CGI->Tr( \@rows ) . $CGI->end_table();

  return \$ret;
}

sub _user_profile_table_sql {
return \<<SQL;
select * from $Db->{USER_PROFILE_TABLE}
order by $Db->{USER_PROFILE_TABLE_UID}
SQL
}

sub _perl_inc_phtml {
    my (@rows,$row_num,$row_color,$key,$value,$count,$ret);
    $row_num = 1;

    ## Table's headings.
    #push( @rows, $CGI->th( ['Key','Value'] ) );

    ## Perl's libraries include path.
    $count = 0;
    foreach (@INC) {
	$row_color = ($row_num % 2) ? $Html->{SITE_LIQUID_COLOR1} : $Html->{SITE_LIQUID_COLOR2};
	push( @rows, $CGI->td( {-bgcolor=>$row_color},
			       [ '$INC['.$count++.']', $_||'&nbsp;' ] ) );
	$row_num++;
    }

    ## Modules that has been loaded.
    while ( ($key,$value) = each(%INC) ) {
	$row_color = ($row_num % 2) ? $Html->{SITE_LIQUID_COLOR1} : $Html->{SITE_LIQUID_COLOR2};
	push( @rows, $CGI->td( {-bgcolor=>$row_color},
			       [ $key, $value || '&nbsp;' ] ) );
	$row_num++;
    }

    $ret = $CGI->start_table( { -width=>'100%',-border=>0, -cellspacing=>1,
				-cellpadding=>2 } ).
	   $CGI->Tr( \@rows ).$CGI->end_table();
    return \$ret;
}

sub _browser_server_status_phtml {
    my (@rows,$row_num,$row_color,$key,$value,$count,$ret);

    ## Table's headings.
    #push( @rows, $CGI->th( ['Key','Value'] ) );

    ## Browser's variables.
    while ( ($key,$value) = each(%ENV) ) {
	$row_color = ($row_num % 2) ? $Html->{SITE_LIQUID_COLOR1} : $Html->{SITE_LIQUID_COLOR2};

	if ( $key eq 'HTTP_COOKIE' ) {
	    push( @rows, $CGI->td( {-bgcolor=>$row_color},
				   [ $key, 'authentication cookies not shown.' ] ) );
	} else {
	    push( @rows, $CGI->td( {-bgcolor=>$row_color},
				   [ $key, $value || '&nbsp;' ] ) );
	}

	$row_num++;
    }

    $ret = $CGI->start_table( { -width=>'100%',-border=>0, -cellspacing=>1,
				-cellpadding=>2 } ).
	   $CGI->Tr( \@rows ).$CGI->end_table();
    return \$ret;
}

sub _logout {
    # return a SCALAR reference.
    my $ret;
    my $login_link = "${This}?$P{page}=$A{Admin}";
    if ( $Admin->logout() ) {
	$ret = "You have been successfully logged out.  Please close your browser ".
	       "immediately or if you want, you can ".
	       "<A HREF=\"$login_link\">re-login</A>";
    } else {
	$ret = "Couldn't log out.";
    }
    return \$ret
}

sub _login {
    my $user_name = $CGI->parameter( $P{user_name} );
    my $guess = $CGI->parameter( $P{guess} );

    if ( $Admin->login($user_name, $guess) ) {
	$Html->fatal( -alertMsg =>
		      "Someone logged into your LibWeb's admin account, ".
		      "please make sure that it is you who logged in!",
		      -isDisplay => 0 )
	  if ( $user_name eq $Admin_name );			
	$CGI->redirect( -url => "${This}?$P{page}=$A{Admin}&$P{action}=$A{Admin_control_panel}&$P{is_just_logged_in}=1" );
	exit(0);
    } else {
	$Html->fatal( -msg => 'Incorrect login.',
		      -alertMsg => 'lw.cgi::_login(): could not login.',
		      -helpMsg => $Html->login_failed() );
    }
}

sub _create_account {
    # return a SCALAR reference.
    my $user_name = $CGI->parameter( $P{new_user_name} );
    my $guess1 = $CGI->parameter( $P{new_guess1} );
    my $guess2 = $CGI->parameter( $P{new_guess2} );
    my $email = $CGI->parameter( $P{new_email} );
    $Html->fatal(-msg => 'Passwords do not match.',
		 -alertMsg => 'lw.cgi::_create_account(): passwords do not match.',
		 -helpMsg => $Html->hit_back_and_edit())
      unless ( $guess2 eq $guess1 );

    if ( $Admin->add_new_user(-user=>$user_name,-password=>$guess1,-email=>$email) ) {
	$Admin->login( $user_name, $guess1 );
	$CGI->redirect( -url => "${This}?$P{page}=$A{Admin}&$P{action}=$A{Admin_control_panel}&$P{is_just_logged_in}=1" );
	exit(0);
    } else {
	return \ "Couldn't create account.";
    }
}

sub _login_form_phtml {
    my $sign_in_form = $CGI->start_form( { -name => $P{login_form},
					   -action => $This,
					   -autocomplete => 'off' } ) .
		    $CGI->hidden( -name => $P{page}, -default => $A{Admin} ) .
		    $CGI->hidden( -name => $P{action}, -default => $A{Admin_login} ) .
		    $CGI->start_table( {width=>'100%'} ) .
                    $CGI->Tr(
			   $CGI->td( {-align=>'right', -width=>'30%'}, ' User name: ' ),
			   $CGI->td( {-align=>'left', -width=>'70%'},
				   $CGI->textfield(-name=>$P{user_name},
						   -maxlength=>'30',
						   -override=>1) )
			  ) .
		    $CGI->Tr(
			   $CGI->td( {-align=>'right', -width=>'30%'}, ' Password: ' ),
			   $CGI->td( {-align=>'left', -width=>'70%'},
				   $CGI->password_field(-name=>$P{guess},
							-maxlength=>'30',
							-override=>1),
				   $CGI->submit('Go!') )
			  ) .
		    $CGI->end_table() . $CGI->end_form();
    return \$sign_in_form;
}

sub _registration_form_phtml {
    my $msg = 'This is important that you create an admin account first.  ';
    my $registration_form = $CGI->start_form( { -action => $This,
						-name => $P{registration_form},
						-autocomplete => 'off' } ) .
			 $CGI->hidden( -name => $P{page}, -default => $A{Admin} ) .
			 $CGI->hidden( -name => $P{action}, -default => $A{Admin_register} ) .
			 $CGI->start_table( {width=>'100%'} ) .
                         $CGI->Tr(
				$CGI->td( {-align=>'right', -width=>'30%'}, 'Pick a user name: '),
				$CGI->td( {-align=>'left', -width=>'70%'},
					 $CGI->textfield(-name=>$P{new_user_name},
							 -maxlength=>'30',
							 -override=>1) )
				) .
			 $CGI->Tr(
				$CGI->td( {-align=>'right', -width=>'30%'}, 'Pick a password: ' ),
				$CGI->td( {-align=>'left', -width=>'70%'},
					$CGI->password_field(-name=>$P{new_guess1},
							     -maxlength=>'30',
							     -override=>1) )
				) .
			 $CGI->Tr(
				$CGI->td( {-align=>'right', -width=>'30%'}, 'Re-enter password: ' ),
				$CGI->td( {-align=>'left', -width=>'70%'},
					$CGI->password_field(-name=>$P{new_guess2},
							     -maxlength=>'30',
							     -override=>1) )
				) .
			 $CGI->Tr(
				$CGI->td( {-align=>'right', -width=>'30%'}, 'Current email address: ' ),
				$CGI->td( {-align=>'left', -width=>'70%'},
					$CGI->textfield(-name=>$P{new_email},
							-maxlength=>'40',
							-override=>1) )
				) .
			 $CGI->end_table() .
			 $CGI->start_table( {-width=>'100%'} ) .
			 $CGI->Tr(
				  $CGI->td( {-align=>'left'}, $msg ),
				  $CGI->td( {-align=>'right'}, $CGI->submit('Submit') )
				 ) .
			 $CGI->end_table() .
			 $CGI->end_form();
    return \$registration_form;
}

#-#############################
# Tests page.
sub Tests_page {
    
    # E-mail admin / author of LibWeb.
    if ( $Action eq $A{Tests_mail_admin} ) {
	$Html->fatal( -alertMsg => 'This is a LibWeb test message.',
		      -isDisplay => 0 );
    } elsif ( $Action eq $A{Tests_mail_author} ) {
	$Html->send_mail( -to => 'ckyc@users.sourceforge.net',
			  -from => 'nobody@'.$Html->{SITE_NAME},
			  -subject => 'LibWeb installation.',
			  -msg => \ 'LibWeb has been successfully installed!' );
    }

    # Error message test.
    $Html->fatal( -msg => 'Error message testing',
		  -helpMsg => $Html->$ {Tests_err_msg}(),
		  -isAlert => 0 ) if ($Tests_err_msg);

    my $time_test = $Theme->bordered_table( -content => [ _time_test_phtml() ] );
    my $email_test = $Theme->bordered_table( -content => [ _email_test_phtml() ] );
    my $err_msg_test = $Theme->bordered_table( -content => [ _err_msg_test_phtml() ] );
    my $colors_test = $Theme->bordered_table( -content => [ _colors_test_phtml() ] );

    my $contents = [ $time_test, '<br>', $email_test, '<br>', $err_msg_test, '<br>',
		     $colors_test ];
    return $Html->display(
			  -header => _header(), -sheader => _sheader(),
			  -lpanel => _lpanel(), -content => $contents,
			  -rpanel => _rpanel(), -footer => _footer()
			 );
}

sub _time_test_phtml {
    my $date = $Time->get_date();
    my $datetime = $Time->get_datetime();
    my $time = $Time->get_time();
    my $timestamp = $Time->get_timestamp();
    my $year = $Time->get_year();
return \<<HTML;
<B>LibWeb::Time class test</B>
<ul>
<li>Date: $date</li>
<li>Date, time & year: $datetime</li>
<li>Time: $time</li>
<li>Timestamp: $timestamp</li>
<li>Year: $year</li>
</ul>
HTML
}

sub _email_test_phtml {
my $ret = <<HTML;
<B>E-mail test</B>
<P>
<a href="${This}?$P{page}=${Page}&$P{action}=$A{Tests_mail_admin}">Send</a>
a test e-mail to the site administrator.  The following admin e-mail
has been registered with LibWeb: $Html->{ADMIN_EMAIL}.</P>
<P>
<a href="${This}?$P{page}=${Page}&$P{action}=$A{Tests_mail_author}">Send</a>
a test e-mail to the author of LibWeb.  I will be very happy to
hear good news from you.  My e-mail address is: ckyc at users.sourceforge.net
</P>
HTML

if ( $Action eq $A{Tests_mail_admin} ) {
    $ret .= "<P><FONT COLOR=\"red\">An e-mail has been sent to $Html->{ADMIN_EMAIL}.</FONT></P>";
} elsif ( $Action eq $A{Tests_mail_author} ) {
    $ret .= "<P><FONT COLOR=\"red\">An e-mail has been sent to ckyc at users.sourceforge.net.</FONT></P>";
}
   return \$ret;

}

sub _err_msg_test_phtml {
    my @err_msg_links;
    my $err_msgs = ['cookie_error','database_error','exceeded_max_login_attempt',
		    'hit_back_and_edit','login_expired','login_failed',
		    'logout_failed','mysterious_error','post_too_large',
		    'registration_failed','special_characters_not_allowed'];

    foreach (@$err_msgs) {
	push( @err_msg_links,
	"<li><a href=\"${This}?$P{page}=${Page}&$P{Tests_err_msg}=$_\">$_</a></li>\n" );
    }

return \<<HTML;
<B>LibWeb\'s built-in error messages</B>
<P><ul>
@err_msg_links
</ul></P>
<p>Please read the man page for LibWeb::HTML::Error and LibWeb::HTML::Default for
details on how to customize these and add your own error messages.</p>
HTML
}

sub _colors_test_phtml {
    my @color_tests;
    my $colors =['SITE_1ST_COLOR','SITE_2ND_COLOR','SITE_3RD_COLOR','SITE_4TH_COLOR',
		 'SITE_LIQUID_COLOR1','SITE_LIQUID_COLOR2','SITE_LIQUID_COLOR3',
		 'SITE_LIQUID_COLOR4','SITE_LIQUID_COLOR5','SITE_TXT_COLOR',
		 'SITE_BG_COLOR'];
    foreach (@$colors) {
	push(
	     @color_tests,
	      "<P>${_}: " .
	      ${ $Theme->table(
			       -bg_color => $Html->{$_},
			       -content => ["<FONT COLOR=\"$Html->{SITE_TXT_COLOR}\">$Html->{$_}</FONT>"]
			      )
	      } 
	    );
    }
return \<<HTML;
<B>Color test</B>
@color_tests
HTML
}

#-#############################
# Default page constructs.
sub _header {
    # Put a tabbed navigation bar at header.
    return [ $Html->tabber( -tabs => \@Pages, -active => $Pages{$Page} ) ];
}

sub _sheader {
    # Put nothing at sub-header.
    return [' '];
}

sub _lpanel {
    # Put nothing at left-panel.
    return [' '];
}

sub _rpanel {
    # Put nothing at right-panel.
    return [' '];
}
sub _footer {
    return [ _footer_phtml() ];
}

sub _footer_phtml {
return \<<HTML;
<center><table border=0 width="60%"><Tr><td align="center"><hr size=1>
Copyright&nbsp;&copy;&nbsp;$Html->{SITE_YEAR}&nbsp;$Html->{SITE_NAME}.  All rights reserved.<br>
<a href="$Html->{TOS}">Terms of Service.</a> &nbsp;
<a href="$Html->{PRIVACY_POLICY}">Privacy Policy.</a>
</td></Tr></table></center>
HTML
}
