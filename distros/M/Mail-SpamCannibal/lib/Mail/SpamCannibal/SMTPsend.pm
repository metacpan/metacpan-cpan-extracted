#!/usr/bin/perl
#
package Mail::SpamCannibal::SMTPsend;

use strict;
#use diagnostics;
use Net::DNS::Codes qw(
	C_IN
	T_MX
	QUERY
	NOERROR
);
use Net::DNS::ToolKit qw(
	inet_ntoa
	inet_aton
	gethead
	get_ns
);
use Mail::SpamCannibal::ScriptSupport qw(
	question
	query
);
use Sys::Hostname::FQDN qw(fqdn);
use Net::SMTP;
use Net::Cmd;
use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;

@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.06 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	getMXhosts
	sendmessage
);

=head1 NAME

Mail::SpamCannibal::SMTPsend - simple mail transport agent

=head1 SYNOPSIS

use Mail::SpamCannibal::SMTPsend qw(
	getMXhosts
	sendmessage
);

=head1 DESCRIPTION

B<Mail::SpamCannibal::SMTPsend> provides a simple interface to send mail from the host 
system without relying on installed MTA's.

=over 4

=item * @mxhosts = getMXhosts($domain);

This function accepts either a domain name or email address as its argument. It returns
an array of MXhosts in "priority" order or an empty array on error.

The function is used internally by "sendmessage" and is exported for
convenience.

  input:	somedomain.com
	   or	name@somedomain.com

  returns:	array of MX hostnames
	   or	() on error

If you wish to overide this internal call so that B<sendmessage> will use
designated host(s), such as your ISP, then use the code snippet below
prior to calling B<sendmessage> (do not import getMXhosts).

  *Mail::SpamCannibal::SMTPsend::getMXhosts = sub {
	return qw(	mx1.designated.host.com
			mx2.designated.host.com
	);
  }

=cut

#use Net::DNS::ToolKit::Debug qw(print_buf);

sub getMXhosts {
  my $domain = shift;
  if ($domain =~ /^\w+\@(.+)/) {
    $domain = $1;
  }
  my @localns = get_ns();
  my $querybuf = question($domain,T_MX);
  my $response;
  foreach(@localns) {
    $response = query(\$querybuf);
    last if $response;
  }
  return () unless $response;	# no answer
  my ($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$response);

  my %mxhosts;
  
  DECODE:
  while(1) {
    last if
	$tc ||
	$opcode != QUERY ||
	$rcode != NOERROR ||
	$qdcount != 1 ||
	$ancount < 1;
        
    my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
    my ($off,$name,$type,$class) = $get->Question(\$response,$off);
    last unless $class == C_IN;

    foreach(0..$ancount -1) {
      ($off,$name,$type,$class,my($ttl,$rdlength,$pref,$nsname)) =
	$get->next(\$response,$off);
      $mxhosts{"$nsname"} = $pref;
    }
    last;
  }
  local @_ = sort { $mxhosts{$a} <=> $mxhosts{$b} } keys %mxhosts;
}

=item * $rv = sendmessage($message,$to,$from);

Send an email message.

  input:	$message,	# text
		$to,		# name@host.com
		$from,		# optional@otherhost.com
		[optional] $fh	# message spool "from" file handle

If from is omitted, the ENV{USER} is used. If the domain is omitted, the
fully qualified domain name of the host is used.

If the optional $fh is present, then B<sendmessage> will use the
Net::Cmd datasend and dataend methods to send and will spool
all available data from $fh to the target.

  returns:	true on success
		else false

=back

=cut

sub sendmessage {
  my ($message,$to,$from,$fh) = @_;
  $to .= '@' . fqdn()
	unless $to =~ /\@/;
  unless ($from) {
    $from = (getpwuid($<))[0] .'@'. fqdn();
  } elsif( $from !~ /\@/) {
    $from .= '@' . fqdn();
  }
  my $head = 'To: '. $to ."\nFrom: ". $from ."\n";
  my @mxhosts = getMXhosts($to);
  return 0 unless @mxhosts;

  my $smtp;
  foreach(@mxhosts) {
    $smtp = Net::SMTP::->new($_,Hello => fqdn());
    last if $smtp;
  }
  return 0 unless $smtp;
  $smtp->mail($from);
  my $rv = ($smtp->to($to) &&
	    $smtp->data() &&
	    $smtp->datasend($head) &&
	    $smtp->datasend($message))
	? 1 : 0;
  if ($fh) {
    my $buf;
    while (read($fh,$buf,10000)) {
      last unless $smtp->datasend($buf);
    }
  }
  $smtp->dataend();
  $smtp->quit();
  return $rv;
}

=head1 DEPENDENCIES

  Net::DNS::Codes
  Net::DNS::ToolKit
  Sys::Hostname::FQDN
  Net::SMTP
  Mail::SpamCannibal::ScriptSupport
  
=head1 EXPORT_OK

        getMXhosts
        sendmessage

=head1 COPYRIGHT

Copyright 2003 - 2007, Michael Robinton <michael@bizsystems.com>

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
