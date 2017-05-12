#!/usr/bin/perl
package Mail::SpamCannibal::ParseMessage;
use strict;
#use diagnostics;
use Socket;
use NetAddr::IP::Lite;
use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = do { my @r = (q$Revision: 0.09 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use AutoLoader 'AUTOLOAD';
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	limitread
	dispose_of
	headers
	rfheaders
	skiphead
	get_MTAs
	firstremote
	array2string
	string2array
	trimmsg
);

# autoload declarations

sub limitread;
sub dispose_of;
sub headers;
sub rfheaders;
sub skiphead;
sub get_MTAs;
sub firstremote;
sub _headers;
sub array2string;
sub string2array;
sub trimmsg;

sub DESTROY {};

=head1 NAME

  Mail::SpamCannibal::ParseMessage - parse mail headers

=cut

1;
__END__

=head1 SYNOPSIS

  use Mail::SpamCannibal::ParseMessage qw(
        limitread
        dispose_of
        headers
        rfheaders
        skiphead 
        get_MTAs
        firstremote
        array2string
        string2array
  );

  $chars = limitread(*H,\@lines,$limit);
  $rv = dispose_of(*H,$limit);
  $hdrs = headers(\@lines,\@headers);
  $hdrs = rfheaders(\@lines,\@headers);
  $lines = skiphead(\@lines);
  $mtas = get_MTAs(\@headers,\@mtas);
  $from = firstremote(\@MTAs,\@myhosts,$noprivate);
  $string = array2string(\@array,$begin,$end);
  $count = string2array($string,\@array);

=head1 DESCRIPTION

B<Mail::SpamCannibal::ParseMessage> provides utilities to parse mail headers
and email messages containing mail headers as their message content to 
find the origination Mail Transfer Agent.

  use Mail::SpamCannibal::ParseMessage qw(
        limitread
        dispose_of
        headers   
        skiphead  
        get_MTAs  
        firstremote
        array2string
        string2array
  );

  # example of reading mail message from STDIN

  # read up to 10000 characters
  my @lines;
  exit unless limitread(*STDIN,\@lines,10000);

  # release the daemon feeding this script
  dispose_of(*STDIN);

  # optional, if message content is headers
  # skip the real headers on this message
  exit unless skiphead(\@lines);

  # linearize headers, convert multi-line headers
  # to single line, removing extra white space
  my @headers;
  exit unless headers(\@lines,\@headers);

  # get list of MTA's from headers  
  my @mtas;
  exit unless get_MTAs(\@headers,\@mtas);

  # extract the first remote MTA from the 
  # resulting MTA object
  my @myhosts = qw(
	mail1.mydomain.com
	mail2.mydomain.com
  };
  my $remoteIP = firstremote(\@mtas,\@myhosts);

=head1 SUBROUTINE DESCRIPTIONS

=over 4

=item * $chars = limitread(*H,\@lines,$limit);

Read $limit charcters (or to end of file) from stream *H and place the lines in
an array. 

This is useful for reading an input stream which
could overflow internal buffers if it were not in the expected format.

  input:	*H,	# stream handle
		array pointer,
		limit	# max characters [1000 default]

  returns:	number of characters read

=cut

sub limitread {
  my($fh,$ap,$lim) = @_;
  $lim = 1000 unless $lim;
  return 0 unless defined fileno($fh) && ref $ap;	# ignore really dumb users
  my $buf;
  my $chars = read($fh,$buf,$lim);
  unless ($chars) {
    @$ap = ();
    return 0;
  }
  $buf =~ s/\r\n/\n/g;				# dos 2 unix
  @$ap = split(/\n/, $buf);
  return $chars;
}

=item * $rv = dispose_of(*H,$limit);

  Empty the stream *H
  .... reads until EOF and returns

  input:	*H		# stream handle
		limit		# max buffer size
				# default 1000

  return:	positive integer if anything read
		else zero

=cut

sub dispose_of {
  my($fh,$lim) = @_;
  return 0 unless defined fileno($fh); 
  $lim = 1000 unless $lim && $lim > 0;
  my $buf;
  my $rv = 0;
  while($_ = read($fh,$buf,$lim)) {
    $rv = $_;
  }
  $rv;
}

=item * $hdrs = headers(\@lines,\@headers);

  Reads lines from array and returns them
  in and array of headers. The headers are 
  unfolded into single lines.
    i.e.
  Received: from hotmail.com ([64.216.248.129])
	by mail.mydoamin.com (8.12.8/8.12.8) 
	with SMTP id h2KIRcYC029373;
        Thu, 20 Mar 2003 10:27:39 -0800

  would be returned as one header line with 
  compressed white space

  input:	pointer to inout line array
		pointer to output headder array

  returns:	number headers

=cut

sub headers {
  goto &_headers;
}

=item * $hdrs = rfheaders(\@lines,\@headers);

Similar in function to "headers" above.
Parsing is "dirty" in the sense that extraneous
leading characters such as:

  >> etc... 

are ignored and lines improperly wrapped without
leading white space (by your email client) will
be added correctly to the header in a manner
that can be parsed by "get_MTA's"

This method is not a "pure" as just using "headers", but it also does not
require properly formated header text with no leading spaces or characters.

  input:	pointer to inout line array
		pointer to output headder array

  returns:	number headers

=cut

sub rfheaders {
  push @_, 1;
  goto &_headers;
}

sub _headers {
  my($ap,$hp,$dirty) = @_;
  return 0 unless ref $ap && ref $hp;
  @$hp = ();
  my $next = '';
  my $xtra = undef;
  foreach(@$ap) {
    if ($dirty && !defined $xtra) {
      if ($_ =~ /^([^a-zA-Z]*)[a-zA-Z\-]+:\s/i) {
        $xtra = $1;	# defined !
      } else {
        next;
      }
    }
# snip extra characters if they exist
    $_ =~ s/^$xtra// if $xtra && $dirty;
    $_ =~ s/\r\n/\n/g;		# dos 2 unix

    if (!$next || 
	( $_ =~ /\S/ &&
		( $_ =~ /^\s/ || ($dirty && $xtra && $_ =~ /^${xtra}\s/) ||
		  ($dirty && $_ !~ /^\s*[a-zA-Z\-]+:/)
		)
       )) {
      $next .= $_;
    } elsif ($_ !~ /\S/) {
      $next =~ s/\s+/ /g;
      push @$hp, $next;
      $next = '';
      last;
    } else {
      $next =~ s/\s+/ /g;
      push @$hp, $next;
      $next = $_;
    }
  }
  if ($next) {
    push @$hp, $next;
  }
  return scalar @$hp;
}

=item * $lines = skiphead(\@lines,\@discard);

  Removes lines from the text array until one
  or more blank lines are found. Leading blank
  lines are removed and the top of the array
  is positioned at the first line with text.

  Optionally, an array of the skipped lines
  is returned for use in bounce messages.

  input:	pointer to text lines,
		[optional] ptr to skip lines

  returns:	number of lines remaining

=cut

sub _discard {
  my($dgp,$line) = @_;
  if ($dgp && defined $line) {
    push @$dgp, $line;
  }
}

sub skiphead {
  my($ap,$dgp) = @_;
  return 0 unless ref $ap && @$ap;
  return 0 if $dgp && ! ref $dgp;
  while(($_ = shift @$ap) =~ /\S/) {		# search for blank line
    _discard($dgp,$_);
    return 0 unless @$ap;
  }
  _discard($dgp,$_);
  while (@$ap && $ap->[0] !~ /\S/) {_discard($dgp,shift @$ap);}	# search for non-blank
  return scalar @$ap;
}

=item * $mtas = get_MTAs(\@headers,\@mtas);

  Return  an array pointing to a structure of
  "Received: from" MTA's found in header lines.

  each array entry ->{from} = IP addr;
		|--->{by}   = host or IP;

  input:	pointer to header array

  returns:	number of MTA entries

=cut

sub get_MTAs {
  my($ap,$mtap) = @_;
  return 0 unless ref $ap && ref $mtap;
  @$mtap = ();
  foreach(@$ap) {
    next unless $_ =~
	/^Received:\s+from.+[\(\[]+(\d+\.\d+\.\d+\.\d+)[\)\]]+.+by\s+([0-9a-zA-Z_\-\.]+)/i;
    push @$mtap, {
	from	=> $1,
	by	=> $2,
	};
  }
  return scalar @$mtap;
}

=item * $from = firstremote(\@MTAs,\@myhosts,$noprivate);

  Parse the "Received: from" structure for the first 
  remote MTA address that is not in @myhosts or is
  not part of a private network where:

  @myhosts = (
	'12.34.56.78',		# a dot.quad address
	'12.34.56.0/28',	# a net block
	'mail.mydomain.com',	# a domain name
	'etc...',
  }

  The IP addresses of "named" hosts will be resolved for
  multiple interfaces. If you do not want this behavior
  then always use dot.quad notation.

  The private networks listed below are automatically
  included in @myhosts by default. If you do not want
  this behavior, set $noprivate TRUE.

	127./8, 10./8, 172.16/12, 192.168/16


  input:	pointer to "Received: from" structure,
		pointer to array of local host names,
		[optional] no private nets = TRUE

  returns:	ip address of first "from" remote host
		or and 'empty' character [''] if the 
		remote host can not be determined.

=cut

# convert any named hosts to an entry for each distinct IP address
#
# input:	copy of mixed ip.addrs, host.names, net.names
# returns:	local array filed with ip.addrs, net.names

sub _host2ip {
  my($myhp,$lp) = @_;			# copy ptr, local ptr
  @$lp = ();
  foreach(@$myhp) {
    if ($_ !~ /[a-zA-Z]/) {		# if not named host
      push @$lp, $_;
      next;
    }
    my ($name,$aliases,$addrtype,$length,@addrs) = gethostbyname($_);
    if (@addrs) {
      foreach(@addrs) {
        push @$lp, inet_ntoa($_);
      }
    } else {
      push @$lp, '255.255.255.255';	# dummy address that will never exist
    }
  }
}

sub firstremote {
  my($mtap,$myhosts,$no) = @_;
  return '' unless ref $mtap && ref $myhosts;
  my @local;				# all dot.quad notation
# put all 'named' ip addresses + net addresses in 'local'
  _host2ip($myhosts,\@local);
# convert each ip description to a net object
  @_ = sort @local;
  undef @local;
  my $last = '';
  foreach(@_) {				# remove duplicates and non-existent hosts [255.255.255.255]
    next if $_ eq $last || $_ eq '255.255.255.255';
    $last = $_;
    push @local, new NetAddr::IP::Lite($_);
  }
  my @private;
  unless ($no) {
    @private = ('127.0.0.0/8',		 	# exclude local and
      '10.0.0.0/8','172.16.0.0/12','192.168.0.0/16');	# private networks
    foreach(0..$#private) {
      $private[$_] = new NetAddr::IP::Lite($private[$_]);
    }
  }
# check for presence of "from" in excluded address range
  my $from = '';
  my $by;
  foreach my $hp (0..$#{$mtap}) {
    my $mtaobj = new NetAddr::IP::Lite($mtap->[$hp]->{from});
# goto next header if address is in the exclusion list
    next if grep($_->contains($mtaobj),(@local,@private));
    $from = $mtap->[$hp]->{from};	# tenatively this one
    $by   = $mtap->[$hp]->{by};
    last;
  }
  if ($from) {				# if candidate found
# get all ip addrs for named 'by' host
    my @by;
    my @from = ($by);
    _host2ip(\@from,\@by);
    foreach(@by) {
      my $byobj = new NetAddr::IP::Lite($_);
# return valid 'from' address if 'by' is found in local host list
      return $from if grep($_->contains($byobj),@local);
    }
  }
  return '';	# sorry :-( bogus!
}

=item * $end = trimmsg(\%MAILFILTER,\@lines)

If message length is limited by configuration of MAXMSG, remove
duplicate blank lines and return the $end pointer for further processing

  input:	pointer to MAILFILTER hash,
		pointer to @lines array
  returns:	ending line number

=cut

sub trimmsg {
  my($MAILFILTER,$ap) = @_;
  return $#${ap} unless exists $MAILFILTER->{MAXMSG} && $MAILFILTER->{MAXMSG} > 0;
  my @newlines;
  my $prev = 'random stuff';
  foreach(@$ap) {	# remove duplicate blank lines
    unless ($prev =~ /\S/) {
      next unless $_ =~ /\S/;
    }
    $prev = $_;
    push @newlines, $_;
  }
  @$ap = @newlines;
  my $end =  0;
  for ($end = 0;$end <=$#{$ap};$end++) {
    last if $ap->[$end] eq '';
  }
  $end += $MAILFILTER->{MAXMSG};
  return ($end > $#{$ap}) ? $#{$ap} : $end;
}

=item * $string = array2string(\@array,$begin,$end);

Makes a string from the array elements beginning with $begin and ending with
$end. If $begin is undefined, 0 is assumed. If $end is undefined, $#array is
assumed. An empty string is returned if $begin > $end.

Unlike a 'join', 'array2string' adds an endline to the
'end' of the string in this manner:

  $string = join("\n",@array,"");

  input:	pointer to array of lines
  returns:	string;

=cut

sub array2string {
  my ($ap,$begin,$end) = @_;
  return '' unless ref $ap;
  $begin = 0 unless defined $begin;
  $end = $#{$ap} unless defined $end;
  return '' if $begin > $end;
  @_ = @$ap;	# don't modify the input array
  join("\n",splice(@_,$begin,$end - $begin +1), '');
}

=item * $count = string2array($string,\@array);

Convert a string into an array of separate lines.
Surpresses multiple trailing blank lines. Considers a
dangling line to be complete.

  i.e.	"once upon a time
	 there were three"

  is the same as:

	"once upon a time 
	 there were three
	"

  input:	string or string pointer,
		pointer to array
  returns:	line count

=back

=cut

sub string2array {
  my($sp,$ap) = @_;
  $sp = \$_[0] unless ref $sp;
  if (ref $ap) {
    @$ap = split(/\n/,$$sp);
  } else {
    @$ap = ();
  }
  return scalar @$ap;
}

=head1 DEPENDENCIES

  NetAddr::IP::Lite version 0.02

=head1 EXPORT

	none

=head1 EXPORT_OK

	limitread
	dispose_of
	headers
	rfheaders
	skiphead
	get_MTAs
	firstremote
	array2string
	string2array
	trimmsg

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

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

=head1 SEE ALSO

perl(1)

=cut

1;
