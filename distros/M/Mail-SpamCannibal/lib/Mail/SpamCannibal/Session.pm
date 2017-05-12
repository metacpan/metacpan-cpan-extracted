#!/usr/bin/perl
package Mail::SpamCannibal::Session;

use strict;
#use diagnostics;
use vars qw($VERSION @ISA @EXPORT_OK);

# do not AutoLoad, used only by scripts
require Exporter;
@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.04 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	mac
	encode
	decode
	new_ses
	clean
	validate
	sesswrap
);

=head1 NAME

Mail::SpamCannibal::Session - session management utilities

=head1 SYNOPSIS

  use Mail::SpamCannibal::Session qw(
	encode
	decode
	mac
	new_ses
	clean
	validate
	sesswrap
  );

  $encoded = encode($string);
  $string = decode($encoded);
  $mac = mac(@elements);
  $sess_id=new_ses($base64ID,$session_dir,\$error,$ses_val);
  $var = clean($tainted);
  $user=validate($session_dir,$sess_id,$secret,\$error,$expire);
  ($user,$content,$file)=validate($session_dir,$sess_id,$secret,\$error,$expire);
  $rv = sesswrap($command,$stdin);

=cut

=head1 DESCRIPTION

B<Mail::SpamCannibal::Session> provides utilities to manage web sessions.

=over 4

=item * $encoded = encode($string);

This function encodes an ascii string into the I<URL and Filename safe> Base64
character set. Character
62 (0x3E) "+" is replaced with a "-" (minus sign) 
and character 63 (0x3F) "/" is replaced with a "_"
(underscore). Pad characters "=" are removed.

  input:	ascii string
  returns:	modified Base64 encoded string

=cut

sub encode {
  my $string = shift or return '';
  require MIME::Base64;
  (my $encoded = &MIME::Base64::encode_base64($string,'')) =~ s/=//g;
  $encoded =~ tr|+/|-_|;
  return $encoded;
}

=item * $string = decode($encoded);

This function decodes a <URL and Filename safe> Base64 encoded string.

  input:	encoded string
  returns:	text string

=cut

sub decode {
  my $encoded = shift or return '';
  require MIME::Base64;
  $encoded =~ tr|-_|+/|;
  $encoded .= ('','','==','=')[length($encoded) % 4];
  &MIME::Base64::decode_base64($encoded);
}

=item * $mac = mac(@elements);

This function makes a I<URL and Filename safe> BASE64 MD5 hash of from the
supplies text string(s). Character
62 (0x3E) "+" is replaced with a "-" (minus sign) 
and character 63 (0x3F) "/" is replaced with a "_"
(underscore).

  input:	one or more input elements
  returns:	modified base64 string

=cut

#       From  RFC 3548
# ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
#
# In the URL and Filename safe variant, character
# 62 (0x3E) "+" is replaced with a "-" (minus sign)
# and character 63 (0x3F) "/" is replaced with a "_"
# (underscore).
# Pad characters "=" are eliminated entirely
# ... but is not produced by Digest::MD5 to begin with
#

sub mac {
  require Digest::MD5;
  (my $scode = &Digest::MD5::md5_base64(join('',@_))) =~ tr|+/|-_|;
  return $scode;
}

=item * $sess_id = new_ses($base64ID,$session_dir,\$error,$ses_val);

Create a new session and return the identifying string.

  input:	session directory path,
		base64 unique ID, (URL safe)
		secret key for MAC,
		pointer to $error scalar,
		[optional] value for session
		file contents, default -1

Normally the session file is created containing a -1 with the presumption
that the login procedure and password verification was successful. If the
application needs to track conditional login attempts, then the session
value can be initialized to a positive value and the 'validate' function
(below) will return a false (undef) for 'user' when called with a SCALAR return
value. The application must set the session value negative for the 'user'
string to be returned.


  returns:	session ID or undef

=cut

# create a complete ticket of the form
# user(base64).MAC.file
# where mac  = mac(user(base64),file,secret);
# where file = time.pid.ticket
# and ticket = mac(user(base64),time,pid,secret)
#
sub new_ses {
  my ($session_dir,$base64ID,$secret,$ep,$ses_val) = @_;
  my $time = time;
  my $ticket = mac($base64ID,$time,$$,$secret);
  my $file = $time .'.'. $$ .'.'. $ticket;
  my $mac = mac($base64ID,$file,$secret);
  $$ep = 'could not create session key';
  open(SES,'>'. $session_dir .'/'. $file)
	or return undef;
  print SES ($ses_val) ? $ses_val : -1;
  close SES;
  return $base64ID .'.'. $mac .'.'. $file;
}
  
=item * $var = clean($tainted);

Clean a tainted variable;

  input:	tainted var
  returns:	clean var

=cut

# untaint a variable
sub clean {
  return undef unless $_[0];
  $_[0] =~ /^(.+)/;
  return $1;
}

=item * $user=validate($session_dir,$sess_id,$secret,\$error,$expire);

=item * ($user,$content,$file)=validate($session_dir,$sess_id,$secret,\$error,$expire);

Validate a current session. The session directory is swept for
sessions that have exceeded the expire time (seconds), then checked for the
presence of a matching session. On error, a descriptive message is placed in
the external scalar $error and undef is returned.

  input:	session directory path,
		session ID,
		secret key for MAC,
		pointer to error,
		expire (seconds) [optional]
			default = 15 minutes

  returns:	scalar: user name or undef
		array: (user,contents,sess file)
			or ()

NOTE: in SCALAR mode, the return value will always be false if the session
contents are > 0.

=cut

# return $user on success
# return undef on failure and set $error = reason
#
sub validate {
  my($session_dir,$sesid,$secret,$ep,$expire) = @_;
  $expire = 900 unless $expire;
  $expire = time - clean($expire);
  unless (opendir(D,$session_dir)) {
	$$ep = 'could not open session directory';
	return (wantarray) ? () : undef;
  }
  my @files = grep(!/^\./, readdir(D));
  closedir D;
  my @zap;
  foreach(@files) {
    my $file = $session_dir .'/'. clean($_);
    my $atime = (stat($file))[8];
    push @zap, $file unless (stat($file))[8] > $expire;
  }
  unlink @zap if @zap;

  my ($user,$mac,$file) = split(/\./,$sesid,3);
  unless ($mac eq mac($user,$file,$secret)) {
    $$ep = 'session ID is altered';
    return (wantarray) ? () : undef;
  }
  my ($time,$pid,$ticket) = split(/\./,$file);
  unless ($ticket eq mac($user,$time,$pid,$secret)) {
    $$ep = 'corrupt session ticket';
    return (wantarray) ? () : undef;
  }
  unless (open(SES,$session_dir .'/'. $file)) {
    $$ep = 'no such session';
    return (wantarray) ? () : undef;
  }
  $_ = <SES>;
  close SES;
  if ($_) {
    chomp;
  } else {
    $_ = -1;
  }
  return (wantarray)
	? (decode($user),$_,$file)
	: ($_ && $_ < 0)
		? decode($user)
		: do {$$ep = 'login required'; undef};
}

=item * $rv = sesswrap($command,$stdin);

Execute a session wrap command and return results.

  input:	command string,
		stdin string [optional]
  returns:	wrapper output

The wrapper is opened with the command string in it's command line. $stdin,
if any, is written to the wrapper's STDIN.

For calls which have a $stdin argument, this routine uses 'fork' and spawns
a child httpd process. The routine is enhanced for modperl to properly kill
off the child

=back

=cut

sub sesswrap {
  my($command,$stdin) = @_;
# do this in a lite weight fashion if there is no stdin
  return eval{qx|$command|} unless $stdin;
  my $r;
  eval{require Apache && ($r = Apache->request)};
  eval {pipe(FROM_ADMIN, TO_ADMIN) || die "pipe: $!"};
  return $@ if $@;
  my $pid = fork;
  my $rv;
  if ($pid) {			# parent
    close TO_ADMIN;
    $rv = <FROM_ADMIN>;
    close FROM_ADMIN;
# belt and suspenders
    local $SIG{CHLD} = sub {waitpid($pid,0)};
    waitpid($pid,0);
  } else {			# child
    return "could not fork sesswrap: $!" 
	unless defined $pid;
    close FROM_ADMIN;
    while (1) {
      unless (open STDERR, '>&STDOUT') {
	print STDERR "could not dup STDERR to STDOUT: $!";
	last;
      }
      unless (open STDOUT, '>&TO_ADMIN') {
	print STDERR "could not dup STDOUT TO_ADMIN: $!";
	last;
      }
      open(ADMIN, '|'. $command) ||
	print STDERR "can not exec program";
      print ADMIN $stdin
	if $stdin;
      close ADMIN;
      last;
    }
    close TO_ADMIN;
    (exit 0) unless $r;
    CORE::exit(0);
  }
  $rv || '';
}

=head1 DEPENDENCIES

	none
  
=head1 EXPORT_OK

	encode
	decode
	mac
	new_ses
	validate
	sesswrap

=head1 COPYRIGHT

Copyright 2003 - 2005 , Michael Robinton <michael@bizsystems.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=cut

1;
