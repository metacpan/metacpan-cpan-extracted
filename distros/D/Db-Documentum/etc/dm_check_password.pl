#!/usr/local/bin/perl5.004

# $Id: dm_check_password.pl,v 1.10 1998/06/29 19:59:20 briansp Exp briansp $

use Krb4;
use Socket;
use Sys::Hostname;
require 'getopts.pl';

# Define some constants.  
$service = 'documentum';
$srvtab = '/etc/krb-srvtab';
$user_config = '/etc/dm_userconfig.conf';
$program_name = 'dm_check_password.pl';

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
# Kerberos 4 Result Codes
##########################################################################
	# Values returned from KDC operations.
	$KDC_OK =						0;   # Request OK 
	$KDC_NAME_EXP =					1;   # Principal expired 
	$KDC_SERVICE_EXP =				2;   # Service expired 
	$KDC_AUTH_EXP =					3;   # Auth expired 
	$KDC_PKT_VER =					4;	# Protocol version unknown 
	$KDC_P_MKEY_VER =				5;	# Wrong master key version 
	$KDC_S_MKEY_VER =				6;   # Wrong master key version 
	$KDC_BYTE_ORDER =				7;   # Byte order unknown 
	$KDC_PR_UNKNOWN =				8;   # Principal unknown 
	$KDC_PR_N_UNIQUE =				9;   # Principal not unique 
	$KDC_NULL_KEY =					10;   # Principal has null key 
	$KDC_GEN_ERR =					20;   # Generic error from KDC 
	# Values returned by mk_ap_req  
	$MK_AP_OK =					    0;   # Success 
	$MK_AP_TGTEXP =					26;   # TGT Expired 
	# Values returned by rd_ap_req 
	$RD_AP_OK =						0;   # Request authentic 
	$RD_AP_UNDEC =					31;  # Can't decode authenticator 
	$RD_AP_EXP =					32;  # Ticket expired 
	$RD_AP_NYV =					33;  # Ticket not yet valid 
	$RD_AP_REPEAT =					34;  # Repeated request 
	$RD_AP_NOT_US =					35;  # The ticket isn't for us 
	$RD_AP_INCON =					36;  # Request is inconsistent 
	$RD_AP_TIME =					37;  # delta_t too big 
	$RD_AP_BADD =					38;  # Incorrect net address 
	$RD_AP_VERSION =				39;  # protocol version mismatch 
	$RD_AP_MSG_TYPE =				40;  # invalid msg type 
	$RD_AP_MODIFIED =				41;  # message stream modified 
	$RD_AP_ORDER =					42;  # message out of order 
	$RD_AP_UNAUTHOR =				43;  # unauthorized request 
	# Values returned by get_pw_tkt 
	$GT_PW_OK =						0;   # Got password changing tkt 
	$GT_PW_NULL =					51;  # Current PW is null 
	$GT_PW_BADPW =					52;  # Incorrect current password 
	$GT_PW_PROT =					53;  # Protocol Error 
	$GT_PW_KDCERR =					54;  # Error returned by KDC 
	$GT_PW_NULLTKT =				55;  # Null tkt returned by KDC 
	# Values returned by send_to_kdc 
	$SKDC_OK =						0;   # Response received 
	$SKDC_RETRY =					56;  # Retry count exceeded 
	$SKDC_CANT =					57;  # Can't send request 
	$INTK_OK =						0;   # Ticket obtained 
	$INTK_W_NOTALL =				61;  # Not ALL tickets returned 
	$INTK_BADPW =					62;  # Incorrect password 
	$INTK_PROT =					63;  # Protocol Error 
	$INTK_ERR =						70;  # Other error 
	# Error codes returned by ticket file utilities 
	$NO_TKT_FIL =					76;  # No ticket file found 
	$TKT_FIL_ACC = 					77;  # Couldn't access tkt file 
	$TKT_FIL_LCK = 					78;  # Couldn't lock ticket file 
	$TKT_FIL_FMT =					79;  # Bad ticket file format 
	$TKT_FIL_INI =					80;  # tf_init not called first 
	# Error code returned by kparse_name 
	$KNAME_FMT =   					81;  # Bad Kerberos name format 
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

sub dm_Krb_Passwd_Auth ($$) {
	my($username,$password) = @_;
	my($instance) = "";
	my($lifetime) = 1;
	my($tkt_file) = '/tmp/dm_krb_auth.tkt';
	my($service) = 'krbtgt';
	$ENV{'KRBTKFILE'} = $tkt_file;

	my($realm) = Krb4::realmofhost($hostname);
	if (! $realm) {
		$RESULT = $DM_EXT_APP_OS_ERROR;
		return(0);
	}

	my($rc) = Krb4::get_pw_in_tkt($username,$instance,$realm,$service,
									$realm,$lifetime,$password);

	# Clean up after ourselves.
	if (-f $tkt_file) {
		unlink $tkt_file;
	}

	if ($rc == $GT_PW_OK) {
		return(1);
	} elsif ($rc == $INTK_BADPW) {
		$RESULT = $DM_CHKPASS_BAD_LOGIN;
		return(0);
	} elsif ($rc == $KDC_PR_UNKNOWN) {
		print DEBUG "Kerberos returned ", Krb4::get_err_txt($rc), "\n" if ($debug);
		$RESULT = $DM_CHKPASS_ACCOUNT_DROPPED;
		return(0);
	} else {
		print DEBUG "Kerberos returned ", Krb4::get_err_txt($rc), "\n" if ($debug);
		$RESULT = $DM_EXT_APP_OS_ERROR;
		return(0);
	}
	return(0);
}

sub dm_Krb_Tkt_Auth ($$$) {
	my($username,$ticket_data_encoded,$nonce_encoded) = @_;
	print DEBUG "in dm_krb_tkt_auth: $nonce_encoded\n";
	my($nonce_prefix) = "KERBEROS_V4_NONCE__";

	my($time) = time();

	# First, get rid of the encoding on the password/ticket.
	# uuencode encrypted ticket data, then encode it with URI-style encoding
	$ticket_data_encoded =~ tr/+/ /;
	$ticket_data_encoded =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
	$ticket_data = unpack "u", $ticket_data_encoded;
	# Now turn the data into a real live ticket.
	$ticket = Krb4::Ticket->new($ticket_data);
	# Same thing with nonce.
	$nonce_encoded =~ tr/+/ /;
	$nonce_encoded =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
	$nonce_encrypted = unpack "u", $nonce_encoded;
	
	#print DEBUG "Got this far (1).\n";

	my($hostname) = hostname();
	if (! $hostname) {
		$RESULT = $DM_EXT_APP_OS_ERROR;
		return(0);
	}
	
	my($inaddr) = inet_aton($hostname);
	if (! $inaddr) {
		$RESULT = $DM_EXT_APP_OS_ERROR;
		return(0);
	}
	
	#print DEBUG "Got this far (2).\n";

	my($realm) = Krb4::realmofhost($hostname);
	if (! $realm) {
		$RESULT = $DM_EXT_APP_OS_ERROR;
		return(0);
	}

	my($phost) = Krb4::get_phost($hostname,$realm,$service);
	if (! $phost) {
		$RESULT = $DM_EXT_APP_OS_ERROR;
		return(0);
	} 
	
	#print DEBUG "Got this far (3).\n";

	my($auth_data) = Krb4::rd_req($ticket,$service,$phost,$srvtab);

	if (! $auth_data) {
		if ($debug) {
			print DEBUG "Didn't get auth_data.\n";
			print DEBUG Krb4::get_err_txt($Krb4::error), "\n";
		}
		$RESULT = $DM_EXT_APP_OS_ERROR;
		return(0);
	} 
	#print DEBUG "Got this far (4).\n";
	
	my($principal) = $auth_data->pname;
	my($instance) = $auth_data->pinst;
	$auth_username = "$principal";
	if ($instance) { $auth_username .= ".$instance"; }

	# If we don't find a config file entry, make sure the user in the
	# ticket matches the user in the auth request.
	if (! $config_data{$username}) {
		if ($auth_username ne $username) {
			$RESULT = $DM_CHKPASS_BAD_LOGIN;
			#print DEBUG "$auth_username <> $username\n";
			return(0);
		}
	} else {
	# Otherwise see if the config data permits the user to log in.
		my($expr) = $config_data{$username};
		if ($auth_username !~ m#$expr#) {
			#print DEBUG "$auth_username !~ $expr\n";
			$RESULT = $DM_CHKPASS_BAD_LOGIN;
			#$RESULT = DM_EXT_APP_OS_ERROR;
			return(0);
		}
	}
	#print DEBUG "Got this far (5).\n";

	# Check to make sure the ticket hasn't expired.
	my($tkt_lifetime) = $auth_data->life;
	my($tkt_issuetime) = $auth_data->time_sec;
	my($tkt_expiretime) = $tkt_issuetime + ($tkt_lifetime * 5 * 60);
	
	my $tkt_issuedate = localtime $tkt_issuetime;
	my $tkt_expiredate = localtime $tkt_expiretime;
	my $date = localtime $time;


	if ( $tkt_expiretime <= $time ) {
		$RESULT = $DM_CHKPASS_BAD_LOGIN;
		return(0);
	}

	# Decrypt the nonce and make sure that this isn't a replay
	# attack.
	my($session_key) = $auth_data->session;

	if (! $session_key) {
		print DEBUG "Didn't get session_key.\n" if ($debug);
		$RESULT = $DM_EXT_APP_OS_ERROR;
		return(0);
	} else {
		print DEBUG "session_key: $session_key\n" if ($debug);
	}

	# Okay, now I realize this really sucks, since I'm using the
	# address in the ticket without comparing it against the address
	# of the client, but since I can't do a getpeername() here, there's
	# no reliable way to determine the address of the client unless
	# the documentum server puts something in the environment.
	my($client_inaddr) = inet_aton($auth_data->address);
	print DEBUG "client_inaddr: $client_inaddr\n";
	print DEBUG "inaddr: $inaddr\n";
	my($key_schedule) = Krb4::get_key_sched($session_key);

	if (! $key_schedule) {
		$RESULT = $DM_EXT_APP_OS_ERROR;
		return(0);
	}

	my($nonce) = Krb4::rd_priv($nonce_encrypted,$key_schedule,$session_key,$client_inaddr,$inaddr);
	$nonce =~ s#$nonce_prefix##;	# Remove nonce prefix.  The nonce needs
									# to be at least as long as the cipher
									# block size or you get no data.

	# 300 sec = five minutes, standard for K4.  This allows for reasonable
	# clock skew.
	if ( ($time - $nonce) > 300 ) {
		print DEBUG "Nonce expired.  Replay problem?\n" if ($debug);
		$RESULT = $DM_CHKPASS_BAD_LOGIN;
		return(0);
	}

	return(1);
}

sub Parse_Config ($) {
	my($config_file) = @_;
	my(%config_data);

	if (! -f $config_file) {
		return(0);
	}

	if (! open(CONFIG, "$config_file")) {
		print STDERR "$program_name: Unable to open config_file '$config_file': $!\n";
		return(0);
	}
	while (<CONFIG>) {
		next if ($_ =~ m/^#+/);
		next if ($_ =~ m/^\s+/);
		chomp;
		my($dm_user,$krb_expr) = split ':',$_,2;
		$config_data{$dm_user} = $krb_expr;
	}
	close CONFIG;

	return %config_data;
}


##############################################################################

#print DEBUG `/usr/local/gnu/bin/date`;

# Grab our data from stdin.  Isn't perl great?
$username = <STDIN>; chomp $username;
$password = <STDIN>; chomp $password;
$auth_data_1 = <STDIN>; chomp $auth_data_1;
$auth_data_2 = <STDIN>; chop $auth_data_2;

$nonce_encoded = $auth_data_2;

# RightSite login sets a funky additional param for some reason.
$nonce_encoded = '' unless (length $nonce_encoded > 8);

if ($debug) {
	print DEBUG "$username : $password : $nonce_encoded\n";
}

%config_data = &Parse_Config($user_config);

# First try to validate the user locally.
if (! $nonce_encoded) {
	if (&dm_Local_Auth($username,$password)) {
		print DEBUG "dm_Local_Auth succeeded.\n" if ($debug);
		exit $DM_EXT_APP_SUCCESS;
	} else {
		# If we set RESULT in dm_Local_Auth then exit with that value.
		if ($RESULT) {
			print DEBUG "Got $RESULT from dm_Local_Auth.  Exiting.\n" if ($debug);
			exit($RESULT);
		} else {
			print DEBUG "dm_Local_Auth failed.\n" if ($debug);
		}
	}
}	


# If no match (for whatever reason), try Kerberos.
# If the user supplied a client_hostname, they must want ticket-based
# authentication.
if ($nonce_encoded) {
	print DEBUG "Got nonce.  Trying dm_Krb_Tkt_Auth.\n" if ($debug);
	if (&dm_Krb_Tkt_Auth($username,$password,$nonce_encoded)) {
		print DEBUG "dm_Krb_Tkt_Auth succeeded.\n" if ($debug);
		exit($DM_EXT_APP_SUCCESS);
	} else {
	$RESULT = $DM_CHKPASS_BAD_LOGIN;
		if ($RESULT) {
			print DEBUG "dm_Krb_Tkt_Auth set RESULT($RESULT).  Exiting.\n" if ($debug);
			exit($RESULT);
		} else {
			print DEBUG "dm_Krb_Tkt_Auth did not set RESULT.  Exiting with DM_EXT_APP_UNEXPECTED_ERROR.\n" if ($debug);
			exit($DM_EXT_APP_UNEXPECTED_ERROR);
		}
	}
} else {
# Otherwise try password-based auth to the KDC.
	# Set our privilege level back to what it used to be.
	$real_user_id = $<;
	$> = $real_user_id;	
	if (&dm_Krb_Passwd_Auth($username,$password,$default_realm)) {
		print DEBUG "Did not get nonce.  Trying dm_Krb_Passwd_Auth.\n" if ($debug);
		exit($DM_EXT_APP_SUCCESS);
	} else {
		if ($RESULT) {
			print DEBUG "dm_Krb_Passwd_Auth set RESULT($RESULT).  Exiting.\n" if ($debug);
			exit($RESULT);
		} else {
			print DEBUG "dm_Krb_Passwd_Auth did not set RESULT.  Exiting.\n" if ($debug);
			exit($DM_EXT_APP_UNEXPECTED_ERROR);
		}
	}
}
# If we got this far, exit with a failure.
print DEBUG "Passed through loop.  Exiting with DM_CHKPASS_BAD_LOGIN.\n" 
	if ($debug);
exit($DM_CHKPASS_BAD_LOGIN);
