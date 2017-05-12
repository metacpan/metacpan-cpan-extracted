package Mail::Vmailmgr;

##Copyright (C) 2000 Martin Langhoff <martin@scim.net>
##
##Most of this code is based on a PHP version written by
##Mike Bell <mike@mikebell.org> . This Perl Module is mostly
##a quick translation of Mikes PHP code, so it doesn't look 
##nice, but we certainly hope it works.
##
##This program is free software; you can redistribute it and/or modify
##it under the terms of the GNU General Public License as published by
##the Free Software Foundation; either version 2 of the License, or
##(at your option) any later version.
##
##This program is distributed in the hope that it will be useful,
##but WITHOUT ANY WARRANTY; without even the implied warranty of
##MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##GNU General Public License for more details.
##
##You should have received a copy of the GNU General Public License
##along with this program; if not, write to the Free Software
##Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA	

# define globals
my ($debug);

BEGIN {
	use strict;
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	$debug = 0;
	
	$VERSION = 0.4;
	
	@ISA		= qw(Exporter);
	
	# symbols to export by default
	@EXPORT	= qw(							
				&vlistdomain
				&vlookup
				&vadduser
				&vaddalias
				&vdeluser
				&vchpass
				&vchforward
				&vchattr
				&vwriteautoresponse
				&vreadautoresponse
				&vdisableautoresponse
				&venableautoresponse
				&vautoresponsestatus
			    );
	
	# symbols to export on request
	#@EXPORT_OK   = qw($Var1 %Hashit &func3);

	# define names for sets of symbols
	#%EXPORT_TAGS	=	;# not used here, yet... 	


	return 1;
};

use strict;
use IO::Socket;
#use Data::Dumper;

sub vm_daemon_raw {
	
	$debug && warn "vm_daemon_raw called with params: \n " . Dumper(\@_);
	
	my @arg		= @_;
	my $vmailfile	= "/tmp/.vmailmgrd";
	my $socketfile	= "/etc/vmailmgr/socket-file";	
	
	# override $vmailfile witth the contents of $socketfile, if it's there
	if (stat $socketfile){
		open SOCKETFILE, $socketfile or die "can't open $socketfile: $!";
		my $socket = <SOCKETFILE>;
		chomp $socket;
		if (stat $socket){ # the daemon seems to be running ok!
			$vmailfile = $socket;
		}
		close SOCKETFILE;
	}
	
	$debug && warn "vm_daemon_raw ->about to connect to $vmailfile";
	
	socket (DAEMON, PF_UNIX, SOCK_STREAM, 0);
	connect(DAEMON, sockaddr_un($vmailfile)) 										
				or die "Can't connect to $vmailfile : $! ... is the daemon running?";

	$debug && warn "vm_daemon_raw ->connected!";

	# parse @arg into a glob... I don't seem to understand Mike's code well
	# hope bit-operators work similarly between perl and php...
	my $command;
	for (my $n=0; $n<@arg; $n++){		
		my $commandlength 	 = length $arg[$n];
		my $high 			 = (($commandlength & (0xFF << 8)) >> 8);
		my $low		 		 = ($commandlength & 0xFF);
		   $command 		.= sprintf('%c%c%s', $high, $low, $arg[$n]);		   
	}
													
	# Create the header, which consists of another two byte length
    #    representation, the number of arguments being passed, and the
    #    command string created above.												
	my $commandlength 	= length $command;
	my $high 			= (($commandlength & (255 << 8)) >> 8);
	my $low				= ($commandlength & 255);
    my $commandstr 		= sprintf("\002%c%c%c", $high, $low+1, scalar @arg -1) . $command;
	
	# pass it to the daemon
	$debug && warn "vm_daemon_raw ->sending command with length ". length $commandstr;

	send (DAEMON, $commandstr,0) == length($commandstr) or die "cant send!";
	
	#
	# now catch the answer
	#
	$debug && warn "vm_daemon_raw ->reading answer";
		
	# catch the 1 char $value
	my $value;
	read(DAEMON, $value, 1);
	$value = ord $value;
	
	#catch the 2 char length ... 
	my $length;
	read(DAEMON, $length, 2);
	$length = "$length";
	$length = ( ord(substr($length,0,1) ) << 8 + ord(substr($length,1,1)));
	
	;
	
	# now read the damned message!
	my $message;
	if ($value == 0){
		my $buffer;
		$message .= $buffer while read(DAEMON, $buffer, 65535);		
		# don't really know why ....
		close DAEMON;
		return $message;
	}
	
	read(DAEMON, $message, $length);
	
	# and close the socket
	close DAEMON;
	
	
	return [$value, $message];
		
}

##=for martin listdomain_parse_userdata($line, $username)
##
##Parses the lines from listdomain into fields. All fields after aliases are ignored, but this is easy to fix if anybody cared about them.
##
##=cut

sub listdomain_parse_userdata {

	$debug && warn "listdomain_parse_userdata called with params: \n " . Dumper(\@_);

	my $line 		= shift;
	my $username 	= shift;
	
	# grab the protocol version
	my $ver = ord(substr($line,0,1));
	if ($ver ne "2") { die "Protocol version is $ver. This module expects protocol version 2."};
	
	# chop off the version
	$line = substr($line,1);
	
	
	# process flags (???) according to Mike's code, they seem to be pairs, 
	# but I don't quite get it	
	my @flags;
	{	
		# need to scope $n a bit farther
		my $n;
		for ($n=0; $n<length($line)-1; $n+=2){ #	step 2 
			# flags come in pairs. and null is a valid value.
			my $flagname	=	substr($line, $n,1);
			my $flagvalue	=	substr($line, $n+1,1);			
			# according to mike, 
			# if the las flag name/identifier is a null (\0)
			# then that means flags are over... 
			last if $flagname =~ /\0/;
			$flags[ord($flagname)] = ord($flagvalue);
		}
		#remove the already processed flags + the trailing \0...
		$line = substr($line, $n+1); 
	}
	
	# split the fields on NULLS
	my @fields = split(/\0/, $line);
	
	(my $password, my $mailbox, @fields) = @fields;
	
	#$password = 'Set' if $password ne '*' ;
	
	my @aliases;
	while($fields[0]){
		push (@aliases, shift @fields);
	}
	shift @fields;
	
	my ( $PersonalInfo,
		$HardQuota,
		$SoftQuota,
		$SizeLimit,
		$CountLimit,
		$CreationTime,
		$ExpiryTime		) = @fields;
	
	return [
			$username,		$password, 
			$mailbox,		\@aliases,
			$PersonalInfo, 	$HardQuota, 
			$SoftQuota,		$SizeLimit, 
			$CountLimit,	$CreationTime, 	
			$ExpiryTime, 	\@flags];
}

##=for martin list_domain_parse_line($line)
##
##Parses the lines from listdomain into fields.
##
##=cut
sub listdomain_parse_line {

	$debug && warn "listdomain_parse_line called with param of " . length $_[0] . 'length';
	
	my $line = shift;
	
	# find the first null.
	$line =~ m/\0/ or warn "no nulls in string??";
	
	# grab the user data
	my $username= $`;
	$debug && warn "user found->$username";
	
	# Send that user's data to be parsed.
	return &listdomain_parse_userdata( $', $username);
}

##=for martin listdomain_parse($output)
##
##Does the ugly stuff for listdomain, and calls listdomain_parse_line once
##for each user
##
##=cut

sub listdomain_parse {

	$debug && warn "listdomain_parse called with param of  " . length $_[0]. " chars";

	my $output = shift; 
	my @array;
	my $cur=1;
	while (1){
		my $linelength=(ord(substr($output, $cur++, 1)) << 8 ) + ord(substr($output, $cur++, 1));
		last unless $linelength;
		push @array, listdomain_parse_line(substr($output, $cur, $linelength));
		$cur += $linelength + 1;
	} ;
	
	return \@array;
}

sub vlistdomain{

	$debug && warn "listdomain called with params: \n " . Dumper(\@_);

	my ($domain, $password) = @_;
	
	return [1, "Empty domain"] 			unless $domain;
	return [1, "Empty domain password"]	unless $password;
	
	
	my $temp = vm_daemon_raw("listdomain", $domain, $password);

	if (ref($temp) eq 'ARRAY') {return $temp};
	return listdomain_parse($temp);
}

sub vlookup {
	my ($domain, $user, $password) = @_;	
	my $tmp = vm_daemon_raw("lookup", $domain, $user, $password);
	
	if (ref $tmp eq 'ARRAY'){

		return $tmp;		
	} else {
		return listdomain_parse_userdata($tmp, $user);
	}
}

sub vadduser {
	my ($domain, $password, $username, $userpass, @forwards) = @_;
	
	return [1, "Empty domain"]				unless $domain;
	return [1, "Empty domain password"]		unless $password;
	return [1, "Empty username"]			unless $username;
	return [1, "No user password supplied"]	unless $userpass;
	
	my @command = ("adduser2", $domain, $username, $password,
	               $userpass, $username);
	foreach my $fw (@forwards){
		push (@command, $fw)		if $fw; 
	}
	return vm_daemon_raw(@command);
}

sub  vaddalias {
	my ($domain, $password, $username, $userpass, @forwards) = @_;
	
	return [1, "Empty domain"]				unless $domain;
	return [1, "Empty domain password"]		unless $password;
	return [1, "Empty username"]			unless $username;
	
	my @command = ("adduser2", $domain, $username, $password,
	               $userpass, "");

	foreach my $fw (@forwards){
		push (@command, $fw)		if $fw; 
	}
	
	return vm_daemon_raw(@command);
}

sub vdeluser {
	my ($domain, $password, $username) = @_;
		
	return [1, "Empty domain"]				unless $domain;
	return [1, "Empty domain password"]		unless $password;
	return [1, "Empty username"]			unless $username;
	
	my @command=("deluser", $domain, $username,$password, );	
	return vm_daemon_raw(@command);
}

sub vchpass {
	my ($domain, $password, $username, $newpass) = @_; 

	return [1, "Empty domain"]				unless $domain;
	return [1, "Empty domain password"]		unless $password;
	return [1, "Empty username"]			unless $username;
	return [1, "No new password supplied"]	unless $newpass;

	my @command=("chattr", $domain, $username, $password, "1", $newpass);
	return vm_daemon_raw(@command);
	
}

sub vchforward {
	my ($domain, $password, $username, @forwards) = @_;
	
	return [1, "Empty domain"]				unless $domain;
	return [1, "Empty domain password"]		unless $password;
	return [1, "Empty username"]			unless $username;
	
	my @command=("chattr", $domain, $username, $password, "2");
	foreach my $fw (@forwards){
			push (@command, $fw)		if $fw; 
	}
	push (@command, "") unless @forwards; 
		
	return vm_daemon_raw(@command);
}

sub vchattr {
	my ($domain, $password, $username, $attr, $value) = @_; 
	my %ATTR = (
		"PASS" => "1",
		"DEST" => "2",
		"HARDQUOTA" => "3",
		"SOFTQUOTA" => "4",
		"MSGSIZE" => "5",
		"MSGCOUNT" => "6",
		"EXPIRY" => "7",
		"MAILBOX_ENABLED" => "8",
		"PERSONAL" => "9",
	);
	my @command = ("chattr", $domain, $username, $password, $ATTR{$attr}, $value);
	
	return vm_daemon_raw(@command);
}

sub vwriteautoresponse {
	my ($domain, $password, $username, $message) = @_;
	my @command = ("autoresponse", $domain, $username, $password, "write", $message);
	return vm_daemon_raw(@command);
}

sub vreadautoresponse{
	my ($domain, $password, $username) = @_;
	my @command = ("autoresponse", $domain, $username, $password, "read");
	return vm_daemon_raw(@command);
}

sub vdisableautoresponse{
	my ($domain, $password, $username) = @_;
	my @command = ("autoresponse", $domain, $username, $password, "disable");
	return vm_daemon_raw(@command);
}

sub venableautoresponse{
	my ($domain, $password, $username) = @_;
    my @command = ("autoresponse", $domain, $username, $password, "enable");
	return vm_daemon_raw(@command);
}

sub vautoresponsestatus{
	my ($domain, $password, $username) = @_;
	my @command = ("autoresponse", $domain, $username, $password, "status");
	return vm_daemon_raw(@command);
}

1; # yes, we compiled gracefully.

__END__

=head1 NAME

Mail::Vmailmgr - A Perl module to use Vmailmgr daemon. 

=head1 SYNOPSIS

use Mail::Vmailmgr;

#create a user account martin@mydomain.com
vadduser("mydomain.com", "my_domain_passwd", "martin");

=head1 DESCRIPTION

This module allows easy interaction 
with the vmailmgrd, a daemon designed
to allow access to all of vmailmgr 
functions from unprivileged accounts,
such as CGI scripts usually have.

It was designed and tested against
vmailmgrd version 0.96.9. A major 
rewrite of vmailmgrd is expected,
so this module may not work properly 
with newer versions of vmailmgrd. 

=head1 AUTHOR

The author and mantainer of this module is 
Martin Langhoff <martin@scim.net>. 

Most of this initial release is based on 
the PHP version written by Mike Bell 
<mike@mikebell.org>. This module would not
be here without Mike's help. 

=head1 Passwords

Commands that operate on an existing
virtual user account can be authorized
with either the virtual user account
password, or with the domain-user 
password.

Commands that operate on the virtual
domain, such as vadduser, can only be
authorized with the domain-user password.

=head1 Return codes

In a very un-perlish fashion, all of
these functions (with a few exceptions) 
will return an array where the first 
positions indicates if the command 
succeded or not. 

If the command did not succeed, the
error code will be >0. And probably 
you'll find string in the second position
of the array, indicating what went wrong.

The success code is "0". This is 
consistent with the design of the
vmailmgrd interface, and very 
inconsistent with the general Perl 
fashion. 

=head1 vlistdomain($domain, $password){

Returns the user accounts available 
in the virtual domain.

Similar to the listvdomain binary, 
supplied with Vmailmgr.

=head1 vlookup($domain, $user, $password)

Returns for a single virtual user what 
vlistdomain does for an entire domain.

=head1 vadduser($domain, $password, $username, $userpass, @forwards)

Similar to the vadduser binary, 
supplied with Vmailmgr.

=head1 vaddalias($domain, $password, $username, $userpass, @forwards)

Similar to the vaddalias binary, 
supplied with Vmailmgr.


=head1 vdeluser($domain, $password, $username)

Similar to the vdeluser binary, 
supplied with Vmailmgr.

=head1 vchpass($domain, $password, $username, $newpass)

Similar to the vchpassd binary, 
supplied with Vmailmgr.

=head1 vchforward($domain, $password, $username, @forwards)

Similar to the vchpassd binary, 
supplied with Vmailmgr.

=head1 vchattr($domain, $password, $username, $attr, $value)

Change Attribute. Chech attribute list
and the possible values with the vmailmgr 
documentation.

=head1 vwriteautoresponse($domain, $password, $username, $message)

missing explanation

=head1 vreadautoresponse($domain, $password, $username, $message)

missing explanation

=head1 vdisableautoresponse($domain, $password, $username, $message)

missing explanation

=head1 venableautoresponse($domain, $password, $username, $message)

missing explanation

=head1 vautoresponsestatus($domain, $password, $username, $message)

missing explanation

=head1 SEE ALSO

vmailmgr(7).

