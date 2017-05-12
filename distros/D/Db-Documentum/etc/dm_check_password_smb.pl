#!/usr/local/bin/perl5.004

# $Id: dm_check_password_smb.pl,v 1.1 1999/02/01 18:40:34 briansp Exp briansp $

use Authen::Smb;
use Socket;
use Sys::Hostname;

# Define some constants.  
$pdc = '';	# Hostname of Primary Domain Controller.
$bdc = '';	# Hostname of Backup Domain Controller.
$domain = ''; # Name of NT Domain.

# Debugging help.
#$debug = 1;

if ($debug) {
	$debug_file = "/tmp/dm_check_password.out";
	open DEBUG, ">>$debug_file";
}

##########################################################################
# Documentum API Result Codes
##########################################################################
	$DM_EXT_APP_SUCCESS = 			0;
	$DM_CHKPASS_BAD_LOGIN =			245;
	$DM_CHKPASS_PASSWORD_STALE =    246;
	$DM_CHKPASS_PASSWORD_EXPIRED = 	247;
	$DM_CHKPASS_ACCOUNT_EXPIRED =	248;
	$DM_CHKPASS_ACCOUNT_DROPPED =	249;
	$DM_CHGPASS_PASSWORD_CRITERIA =	251;
	$DM_ASSUME_USER_SYSTEM_ERROR =	252;
	$DM_EXT_APP_OS_ERROR =			253;
	$DM_EXT_APP_NOT_IMPLEMENTED =	254;
	$DM_EXT_APP_UNEXPECTED_ERROR =	255;
##########################################################################
# SMB Auth Result Codes
##########################################################################
	$NTV_NO_ERROR 					= 0;
	$NTV_SERVER_ERROR 				= 1;
	$NTV_PROTOCOL_ERROR 			= 2;
	$NTV_LOGON_ERROR 				= 3;
##########################################################################

# Simple getspnam routine.
sub getspnam ($) {
	my($username) = @_;
	my(%data);

	open(SHADOW,"/etc/shadow") || return;
	while(<SHADOW>) {
		chomp;
		my($name,$junk) = split(':',$_);
		my(@list) = split(':',$_);
		$data{$name} = [ @list];
	}
	close(SHADOW);

	@{ $data{$username} };
}

# Local Auth (/etc/{passwd,shadow}).
sub dm_Local_Auth ($$) {
	my($username,$user_passwd) = @_;
	$sys_passwd_enc = (&getspnam($username))[1];

	# Its important to check that we got something back from getspnam(),
	# since crypt() returns NULL with NULL salt.
	if (! $sys_passwd_enc) {
		# The user doesn't exist locally.  Return and we'll try another method.
		return(0);
	} else {
		$user_passwd_enc = crypt $password, $sys_passwd_enc;

		if ($user_passwd_enc eq $sys_passwd_enc) {
			return(1);
		} else {
			$RESULT = $DM_CHKPASS_BAD_LOGIN;
			return(0);
		}
	}
}

sub dm_SMB_Passwd_Auth ($$$$$) {
	my($username,$password,$pdc,$bdc,$domain) = @_;

	my($rc) = Authen::Smb::authen($username,$password,$pdc,$bdc,$domain);

	if ($rc == $NTV_NO_ERROR) {
		return(1);
	} elsif (($rc == $NTV_SERVER_ERROR) or ($rc == $NTV_PROTOCOL_ERROR)) {
		print DEBUG "Smb::authen returned $rc.\n" if ($debug);
		$RESULT = $DM_EXT_APP_OS_ERROR;
		return(0);
	} elsif ($rc == $NTV_LOGON_ERROR) {
		print DEBUG "Smb::authen returned $rc.\n" if ($debug);
		$RESULT = $DM_CHKPASS_BAD_LOGIN;
		return(0);
	}
	return(0);
}

##############################################################################

# Grab our data from stdin.  Isn't perl great?
$username = <STDIN>; chomp $username;
$password = <STDIN>; chomp $password;
$auth_data_1 = <STDIN>; chomp $auth_data_1;
$auth_data_2 = <STDIN>; chop $auth_data_2;

# First try to validate the user locally.
if ((! $auth_data_1) or (! $auth_data_2)) {
	if (&dm_Local_Auth($username,$password)) {
		exit $DM_EXT_APP_SUCCESS;
	} else {
		# If we set RESULT in dm_Local_Auth then exit with that value.
		if ($RESULT) {
			print DEBUG "Got $RESULT from dm_Local_Auth.  Exiting.\n" if ($debug);
			exit($RESULT);
		} else {
			print DEBUG "dm_Local_Auth failed.  Trying NT Domain Auth.\n" if ($debug);
			if (&dm_SMB_Passwd_Auth($username,$password,$pdc,$bdc,$domain)) {
				exit $DM_EXT_APP_SUCCESS;
			} else {
				if ($RESULT) {
					print DEBUG "Got $RESULT from dm_SMB_Passwd_Auth.  Exiting.\n" if ($debug);
					exit($RESULT);
				} else {
					print DEBUG "dm_SMB_Passwd_Auth failed, but no RESULT set.  Exiting with DM_EXT_APP_OS_ERROR.\n";
					exit($DM_EXT_APP_OS_ERROR);
				}
			}
		}
	}
}	


# If we got this far, exit with a failure.
print DEBUG "Passed through loop.  Exiting with DM_CHKPASS_BAD_LOGIN.\n" 
	if ($debug);
exit($DM_CHKPASS_BAD_LOGIN);
