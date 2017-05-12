#!/usr/bin/perl -T
#
# sc_remote.pl
#
# version 1.05, 1-10-06
#
#################################################################
# WARNING! if you modify this script, make a backup copy.	#
# This script will be overwritten by subsequent installs of 	#
# SpamCannibal.							#
#################################################################
#
# utility to make a remote connection to the server hosting the tarpit
#
# Copyright 2003 - 2006, Michael Robinton <michael@bizsystems.com>
   
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
   
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
   
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#

use strict;
#use diagnostics;
use Mail::SpamCannibal::ScriptSupport qw(
	DO
);
use Mail::SpamCannibal::Session qw(
	sesswrap
	clean
);
use Mail::SpamCannibal::SiteConfig;

my $CONFIG = DO '../config/sc_web.conf';
syntax('Could not open config file')
	unless $CONFIG;

my $DBCONFIG = $CONFIG->{SiteConfig} ||
	new Mail::SpamCannibal::SiteConfig;

$| = 1;		# unbuffer IO

# set real to effective
$< = $>;

$ENV{PATH} = '';	# no path, all direct

sub syntax {
  my($comment) = @_;
  $comment = '' unless $comment;
  print <<EOF;
$comment

Syntax:	sc_session.pl command [arg1] [arg2] ...

  sc_session.pl admin	  on | off (command line only)
  sc_session.pl	newsess	  user password 
  sc_session.pl newtick   user
  sc_session.pl login     session_id expire password maxretry
  sc_session.pl updpass	  session_id expire user newpass oldpass
  sc_session.pl	chksess   session_id expire (relative)
  sc_session.pl rmvsess	  session_id
  sc_session.pl getC24	  session_id expire dot.quad.ip.addr
  sc_session.pl insBL	  session_id expire dot.quad.ip.addr stuff...
  sc_session.pl	insEVD	  session_id expire dot.quad.ip.addr stuff...
  sc_session.pl insEBLKnn session_id expire dot.quad.ip.addr stuff...
  sc_session.pl delete	  session_id expire dot.quad.ip.addr
  sc_session.pl delBLK	  session_id expire dot.quad.ip.addr

  admin		returns "OK status"
	allow admin addition/deletion of users
  newsess	returns "OK session_id"
  newtick	returns "OK session_id"
  login		returns "OK username" or (error text)
	expire is a login retry expiration, retry
	is the maximum allowable failed passwords
  updpass	returns OK or (error text)
	blank passwords deletes user (not self)
  chksess	returns "OK username" or (error text)
  rmvsess	returns OK or (error text)
  getC24	returns OK packed result or (error text)
  insBL		returns OK or (error text)
		insert blacklist contrib
		the arguments are (in order):
	addr => resp, err, remrsp, time, zone
	
	dot.quad.ip.addr =>
	127.0.0.3	# response code from our DNSBL
	"error string... from remote DNSBL or our default"
	127.0.0.x	# remote response accepted from remote DNSBL
	1059422395	# time record expires (since epoch) or "0"
	remote.dnsbl.zone
 
  insEVD	returns OK or (error text)
		insert evidence, the arguments are:
	dot.quad.ip.addr followed by STDIN of
	mail headers +
	message terminated on the last line by a single
	.

  insEBLKnn	same as insEVD except that the insertion is done for
		the entire CIDR/nn block specified by the IP address
		where nn is 31 - 24

  delete	returns OK or (error text)
		deletes dot.quad.ip.addr in all databases

  delBLK	returns OK or (error text)
		deletes CIDR/24 described by dot.quad.ip.addr

EOF
  exit;
}

syntax if @ARGV < 2;

my $action = clean(shift @ARGV);

my $rv;
if ($action =~ /^newsess/) {	# new session
  $rv = Normal(@ARGV[0,1]);
}
elsif ($action =~ /^newtick/) { # creat a new ticket without password validation
  $rv = Normal(@ARGV[0]);
}
elsif ($action =~ /^login/) {	# login user using current ticket
  $rv = Normal(@ARGV[0,1,2,3]);
}
elsif ($action =~ /^updpass/) {	# update password - possibly create new user
  $rv = Normal(@ARGV[0,1,2,3,4]);
}
elsif ($action =~ /^chksess/) {	# check and re-validate current session
  $rv = Normal(@ARGV[0,1]);
}
elsif ($action =~ /^insBL/) {	# insert a Black List item
  $rv = Normal(@ARGV[0,1,2,3,4,5,6,7]);
}
elsif ($action =~ /^insEVD/) {	# insert an Evidence item
  $rv = InsEVD(@ARGV[0,1,2]);
}
elsif ($action =~ /^insEBLK/) {  # insert an Evidence CIDR/nn block
  $rv = InsEVD(@ARGV[0,1,2]);
}
elsif ($action =~ /^delete/) {	# delete and address from database
  $rv = Normal(@ARGV[0,1,2]);
}
elsif ($action =~ /^delBLK/) {	# delete CIDR24 block from database
  $rv = Normal(@ARGV[0,1,2]);
}
elsif ($action =~ /^getC24/) {	# get CIDR/24 block
  $rv = Normal(@ARGV[0,1,2]);
}
elsif ($action =~ /^admin/) {	# allow / disallow admin user additions/deletions
  $rv = 'remote admin access disallowed';
}
elsif ($action =~ /^sorry/) {	# command line intercept from wrapper
  $rv = 'command line execution only';
}
elsif ($action =~ /^echo/) {	# echo test
  $rv = Normal(@ARGV);
}
elsif ($action =~ /^rmvsess/) {	# remove session
  $rv = Normal($ARGV[0]);
}
else {
  syntax;
}

print $rv,"\n";

sub Normal {
  my $command = clean(join(' ',@_));
  return sesswrap("$CONFIG->{remoteshell} $CONFIG->{remotecommand} $action $command");
}

sub InsEVD {
  my $command = clean(join(' ',@_));
  my $string = '';
  while($_ = <STDIN>) {
    last if $_ =~/^\.$/;
    $string .= $_;
  }
  return sesswrap("$CONFIG->{remoteshell} $CONFIG->{remotecommand} $action $command",$string);
}
