package Digest::UserSID;
require 5.001;
##############################################################################
# $Id: UserSID.pm,v 1.5 2001/03/21 17:32:11 unrzc9 Exp $          #            
# 
# See the bottom of this file for the POD documentation.  Search for the
# string '=head'.
# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).
#
# Copyright 1999-2001 Wolfgang Wiese.  All rights reserved.
# It may be used and modified freely, but I do request that this copyright
# notice remain attached to the file.  You may modify this module as you 
# wish, but if you redistribute a modified version, please attach a note
# listing the modifications you have made.
#
##############################################################################
# Last Modified on:	$Date: 2001/03/21 17:32:11 $
# By:			$Author: unrzc9 $
# Version:		$Revision: 1.5 $ 
##############################################################################
use strict;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);

BEGIN {
    use Exporter   ();
    use vars       qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
    $VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
    $UserSID::VERSION = '$Id: UserSID.pm,v 1.5 2001/03/21 17:32:11 unrzc9 Exp $';
    @ISA         = qw(Exporter);
    @EXPORT      = qw(removewebsid getuserbysid makewebsid checkwebsid USID_check USID_add USID_update
                      read new create remove update);
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],
    @EXPORT_OK   = qw();
}
use vars      @EXPORT_OK;


$UserSID::digest		= "hex";
	# Could be: binary, hex, base64. See the manual of Digest::SHA1 for more.
$UserSID::FILE			= "/tmp/sid";
	# Name for the dbm-file in which username, sid and time will be stored
$UserSID::MAXSECONDS		= 60*30;
	# Sets the time how long the sid is valid
$UserSID::CHECKTIMEONLY		 = 1;
	# If this is unlike 0 the routine 'checkwebsid' will check only
	# for the valid timerange but not of the userclient is valid.
	# Additionally in 'makewebsid' the used variables for encryption
	# dont use the typical environment-variables that are used to determine
	# the client.
##############################################################################
# Exported Subroutines
##############################################################################
sub removewebsid {
  my $name = shift;
  my $sha = shift;
  my $file = shift || $UserSID::FILE;
  my $maxseconds = shift || $UserSID::MAXSECONDS;

  if ((not $name) || (not $sha)) {
    return 0;
  }
  if (not %UserSID::DATA) {
    &LoadSIDData($file);
  }

  if ($UserSID::DATA{$name}) {
    delete $UserSID::DATA{$name};
    return &SaveSIDData($file);
  } else {
    return 0;
  }

}
##############################################################################
sub getuserbysid {
  my $code = shift;
  my $file = shift || $UserSID::FILE; 
  my $key;
  my ($checksha, $checktime);
  my $found;
  
  if (not $code) {
    return;
  }
  if (not %UserSID::DATA) {
    &LoadSIDData($file);
  }
  foreach $key (keys %UserSID::DATA) {
    ($checksha, $checktime) = split(/\t/,$UserSID::DATA{$key},2);
    if ($checksha eq $code) {
      $found = $key;
      last;
    }
  }
  return $found;
}
##############################################################################
sub makewebsid {
  my $name = shift;
  my $code;
  my $ip;
  
  if (not $name) {
    return;
  }
  if ($UserSID::CHECKTIMEONLY) {
    $ip      = $ENV{'HTTP_X_FORWARDED_FROM'} || $ENV{'REMOTE_ADDR'} || $ENV{'REMOTE_HOST'};
    $code = $name.$ip;
  } else {
    my $referer = &GetSecondaryDN($ENV{'SERVER_NAME'});
    my $agent   = $ENV{'HTTP_USER_AGENT'};
    $ip      = $ENV{'HTTP_X_FORWARDED_FROM'} || $ENV{'REMOTE_ADDR'} || $ENV{'REMOTE_HOST'};
    $code =  $referer.$agent.$ip;
  }

  if (not $code) {
    $code = $<;
  }
  return &USID_add($name,$code);
}
##############################################################################
sub checkwebsid {
  my $name = shift;
  my $pass = shift; 
  
  my $res = &USID_check($name,$pass);
  
  if (not $res) {
    return 0;
  }
  if ($UserSID::CHECKTIMEONLY) {
    return 1;
  }

  
  my $referer = &GetSecondaryDN($ENV{'HTTP_REFERER'});
  my $agent   = $ENV{'HTTP_USER_AGENT'};
  my $ip      = $ENV{'HTTP_X_FORWARDED_FROM'} || $ENV{'REMOTE_ADDR'} || $ENV{'REMOTE_HOST'};
  my $code =  $referer.$agent.$ip;
  if (not $code) {
    $code = $<;
  }  
  $code = &CreateKey($code);
  
  if ($code eq $pass) {
    return 1;
  } else {
    return 0;
  }
}
##############################################################################
sub USID_add {
  my $name = shift;
  my $string = shift;
  my $file = shift || $UserSID::FILE; 
  
  if ((not $name) || (not $string)) {
    return 0;
  }
  
  my $sid = new Digest::UserSID($file);
  my $res = $sid->create($name,$string);
  if ($res) {
    return $sid->{'sha'};
  } else {
    return 0;
  }
}
##############################################################################
sub USID_check {
  my $name = shift;
  my $sha = shift;
  my $file = shift || $UserSID::FILE; 
  my $maxseconds = shift || $UserSID::MAXSECONDS;
  
  if ((not $name) || (not $sha)) {
    return 0;
  }
  if (not %UserSID::DATA) {
    &LoadSIDData($file);
  }
  if ($UserSID::DATA{$name}) {
    my ($checksha, $checktime) = split(/\t/,$UserSID::DATA{$name},2);
    if ($checksha eq $sha) {
      my $nowtime = time;
      if (($nowtime-$checktime) > $maxseconds) {
        delete $UserSID::DATA{$name};  
        &SaveSIDData($file);
        return 0;
      } else {
        return 1;
      }
    } else {
      return 0;
    }
  } else {
    return 0;
  }
}
##############################################################################
sub USID_update {
  my $name = shift;
  my $sha = shift;
  my $file = shift || $UserSID::FILE;
  my $maxseconds = shift || $UserSID::MAXSECONDS;

  if ((not $name) || (not $sha)) {
    return 0;
  }
  if (not %UserSID::DATA) {
    &LoadSIDData($file);
  }
  if ($UserSID::DATA{$name}) {
    my ($checksha, $checktime) = split(/\t/,$UserSID::DATA{$name},2);
    if ($checksha eq $sha) {
      $checktime = time;
      $UserSID::DATA{$name} = "$checksha\t$checktime";
      return &SaveSIDData($file);
    } else {
      return 0;
    }
  } else {
    return 0;
  }
}
##############################################################################
sub read {
  my $sid = shift;
  my $user = shift;
  my $file = shift || $UserSID::FILE;

  if ((not $sid) || (not $user)) {
    return 0;
  }
  if (not %UserSID::DATA) {
    &LoadSIDData($file);
  }
  if ($UserSID::DATA{$user}) {
    my ($checksha, $checktime) = split(/\t/,$UserSID::DATA{$user},2);
    $sid->{'sha'} = $checksha;
    $sid->{'time'} = $checktime;
    $sid->{'user'} = $user;
    return 1;
  } else {
    return 0;
  }
}
##############################################################################
sub update {
  my $sid = shift;
  my $file = shift || $UserSID::FILE;
  
  if ((not $sid) || (not $sid->{'user'})) {
    return 0;
  }
  $sid->{'time'} = time;
  return &AddNewSID($sid);  
}
##############################################################################
sub remove {
  my $sid = shift;
  my $file = shift || $UserSID::FILE;
  my $key;
  
  if ((not $sid) || (not $sid->{'user'})) {
    return 0;
  }
  
  if (not %UserSID::DATA) {
    &LoadSIDData($file);
  }
  
  delete $UserSID::DATA{$sid->{'user'}};  
  return &SaveSIDData($file);

}
##############################################################################
sub create {
  my $sid = shift;
  my $user = shift;
  my $string = shift || localtime;
  my $digest = shift || $UserSID::digest;
  
  if ((not $sid) || (not $user)) {
    return;
  }
  
  $sid->{'user'} = $user;
  $sid->{'time'} = time;  
  $sid->{'sha'} = &CreateKey($string,$digest);

  return &AddNewSID($sid);
}
##############################################################################
sub new {
  my $that = shift;
  my $file = shift || $UserSID::FILE;
  my $class = ref($that) || $that;
  my $self = {   };
  
  if (($file ne $UserSID::FILE) || (not %UserSID::DATA)) {
    &LoadSIDData($file);
  }
  bless $self, $class;
  return $self;
}

##############################################################################
# Privat Subroutines
##############################################################################
sub GetSecondaryDN {
  my $string = shift || $ENV{'HTTP_HOST'} || $ENV{'SERVER_NAME'};
  
  if (not $string) {
    return;
  }
  $string =~ s/^([a-z]+):\/\///;
  if ($string =~ /^([^:\/]+)(:[0-9]+)?/i) {
    $string = $1;
  }
  my @domain = split(/\./,$string);
  my $tld = pop(@domain);
  my $secondary = pop(@domain);
  return "$secondary.$tld";
}
##############################################################################
sub CreateKey {
  my $string = shift;
  my $digest = shift || $UserSID::digest;;
  my $i;
  my $result;
  
  if ($digest =~ /base/i) {
    $result = sha1_base64($string);
  } elsif ($digest =~ /hex/) {
    $result = sha1_hex($string);
  } else {
    $result = sha1($string);
  }
  while($result =~ /[^a-zA-Z0-9\.\-_]/) {
    $i++;
    $i = $i % 9;
    $result =~ s/[^a-zA-Z0-9\.\-_]/$i/i;
  }
  
  return $result;
}
##############################################################################
sub AddNewSID {
  my $sid = shift;
  my $file = shift || $UserSID::FILE;
  my $key;
  
  if ((not $sid) || (not $sid->{'user'})) {
    return 0;
  }
  
  if (not %UserSID::DATA) {
    &LoadSIDData($file);
  }
  $UserSID::DATA{$sid->{'user'}} = "$sid->{'sha'}\t$sid->{'time'}";
  return &SaveSIDData($file);
}
##############################################################################
sub LoadSIDData {
  my $file = shift;
  my %hash;
  my $lockfile = $file.".pag";
  
  
  dbmopen(%hash,$file,0644);
  %UserSID::DATA = %hash;
  dbmclose(%hash);
  
}
##############################################################################
sub SaveSIDData {
  my $file = shift;
  my %hash = %UserSID::DATA;
  my $lockfile = $file.".pag";
  
  if (not $file) {
    return 0;
  }
  
  dbmopen(%hash,$file,0644);
  %hash = %UserSID::DATA;
  dbmclose(%hash);
  
  return 1;

}
##############################################################################
# EOFunctions
##############################################################################
1;
__END__

=head1 NAME

UserSID - Managing of Session IDs for Users on CGI- and console-scripts 


=head1 SYSTEM REQUIREMENTS

To use this modul you should have Digest::SHA1 installed.

=head1 SYNOPSIS

use Digest::UserSID;

=head1 ABSTRACT

The modul uses Digest:SHA1 to create and manage user session-id's
which are beeing created by sha1, sha1_hex or sha1_base64 .

Session-id's are valid as long a time-range is used or
special environment-variables don't change, depending on the
used functions.
It's possible to use functions in object-oriented style as well as in
function-oriented style.

Session-id's can be generated via CGI as well as from console.
Using Digest::UserSID to generate secure CGI-session-id's adds
the possibility to use environment-variables for identification.

The current version of Digest::UserSID is available at
CPAN and at http://cgi.xwolf.com/ .


=head1 DSLI

Digest::UserSID  adph  Managing session-id's with Digest::SHA1 XWOLF

=head1 DESCRIPTION

=head2 Object-oriented 

=head2 new

Creates a new reference for the session id's (SID). It also reads in 
$UserSID::FILE if possible and saves existing session id's into
the hash  %UserSID::DATA.
Takes a filename in replace for $UserSID::FILE as argument.
Example:

	use Digest::UserSID;
	
	my $sid = new Digest::UserSID;
	my $res = $sid->create($user,$string);
	
	print "key: $sid->{'sha'}\n";
	print "time: $sid->{'time'}\n";
	dbmopen(%hash,$UserSID::FILE,0644);
	%test = %hash; 
	dbmclose(%hash);

	print "Reading UserSID-Data:\n";
	my $key;
	foreach $key (keys %test) {
  	  print "\t$key: $test{$key}\n";
	}


=head2 create

Gets a SID-reference and a string (e.g. a username) as argument
and returns a SHA1-string.
Additionally the SHA1-string will be saved in the file given in 
$UserSID::FILE together with the inputstring and the localtime.


=head2 remove

Removes all data of a SID from the $UserSID::FILE, making the SID
invalid.

=head2 read

$sid->read($loginname), where $loginname is the string for the username
and $SID the reference, will return TRUE if this SID was created with
$sid-create($loginname) before and the delay between creation and reading
is not longer as $UserSID::MAXSECONDS seconds.
Also the fields 
	$sid->{'sha'},
	$sid->{'time'} and
    	$sid->{'user'}
will be filled, where $sid->{'user'} equals $loginname.

=head2 update

This function will update the field $sid->{'time'} to the current 
localtime.

=head2 Function-oriented, with use for CGI

=head2 makewebsid

Returns a session-string that can be used as a session-variable for CGI-scripts.
Needs a string, e.g. a username as argument.
Example:

	my $pass = makewebsid($user);
	print "User $user got SID $pass.....";


=head2 checkwebsid

Checks if the session-string is still valid and if the used environment
is still the same as at calling makewebsid().
Example:

	if (checkwebsid($user,$pass)) {
	  print "SID ok\n";
	} else {
	  print "SID invalid.\n";
	}

Please note, that checkwebsid() will automatically remove the
saved data of a requested $user, if it's not valid in time anymore.


=head2 getuserbysid

Returns the username (the string used at makewebsid()) by using
the session-string as argument.

=head2 removewebsid

Removes all data for the session-id.


=head1 AUTHOR INFORMATION

Copyright 1999-2001, Wolfgang Wiese.  All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

Address bug reports and comments to: xwolf@xwolf.com.  When
sending bug reports, please provide the version of UserSID.pm,
the version of Perl and the name and version of the operating 
system you are using.  

=head1 CREDITS

Thanks very much to:

=over 4

=item Gregor Longariva (gregor@softbaer.de)

=item Rolf Rost (info@i-netlab.de)


=head1 SEE ALSO

the Digest::SHA1 manpage

=cut

# EOF
##############################################################################
