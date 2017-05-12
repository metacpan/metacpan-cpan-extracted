#!/usr/bin/perl
package Mail::SpamCannibal::BDBclient;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use Socket;
use AutoLoader 'AUTOLOAD';
require Exporter;

$VERSION = do { my @r = (q$Revision: 0.03 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw(Exporter);

@EXPORT_OK = ('dataquery', 'retrieve', @Socket::EXPORT, @Socket::EXPORT_OK);

# returns the number of bytes read on success, else undef;

sub _common {
  my($how,$key,$name,$sockpath,$is_network,$bp) = @_;
  return undef if $how < 0;
  $how = 255 if $how > 255;

  my $alarmval = $is_network || 10;

  local $SIG{ALRM} = sub {die "timed out"};
  alarm $alarmval;
  
  my $S = ($is_network) ?_sock($sockpath) : _unsock($sockpath);

  if ($how) {
    $$bp = pack("C N Z*",$how,$key,$name);
  } else {
    $$bp = pack("C a4 Z*",$how,$key,$name);
  }
  my $len = length($$bp);
  send($S,(pack("n",$len)),0);
  send($S,$$bp,0);

  sysread($S,$$bp,2);

  $len = unpack("n",$$bp);
  $len = sysread($S,$$bp,$len);

  close $S;
  alarm 0;

  return $len;
}

sub DESTROY {}

1;
__END__

sub _unsock {
  my($sockpath) = @_;
  local *S;
  die "could not create socket: $!"
	unless socket(S,PF_UNIX,SOCK_STREAM,0);

  die "could not connect to Daemon"
	unless connect(S,sockaddr_un($sockpath));

  return *S;
}

sub _sock {
  my($sockpath) = @_;
  local *S;
  my($host,$port) = split(':',$sockpath);
  die "not a port number '$port'"
	if $port =~ /\D/ &&
	   $port !~ /\d/;

  my $netaddr;
  die "could not resolve hostname '$host'"
	unless ($netaddr = inet_aton($host));

  die "could not create socket: $!"
	unless socket(S,PF_INET,SOCK_STREAM,0);

  die "could not connect to Daemon"
	unless connect(S,sockaddr_in($port,$netaddr));

  return *S;
}

  
=head1 NAME

Mail::SpamCannibal::BDBclient -- BDBaccess client

=head1 SYNOPSIS

  use Mail::SpamCannibal::BDBclient qw(dataquery);

  [constants and functions from Socket avaliable for export]

  ($key,$val)=dataquery($how,$cursor_key,$name,$sockpath,$is_network);
  $count=retrieve($howmany,$cursor,$name,\@list,$sockpath,$is_network);

=head1 DESCRIPTION

B<Mail::SpamCannibal::BDBclient> can retrieve either a single complete
record (key + data) or a list of keys (IP addresses) from a BDBaccess daemon
either on the local host via a UNIX domain socket, or on a remote host via a
network connection.

=over 4

=item * ($key,$val)=dataquery($how,$cursor_key,$name,$sockpath,$is_network);

Query a BDBaccess daemon for a single record.
  $how = 0	lookup a record by key value
  $how = 1	lookup a record by cursor (record number)

  $cursor_key	for $how = 0,
		IP address of the record of interest as
		returned by inet_ntoa('11.22.33.44')
	 or	for $how = 1,
		the cursor (record number), where the 
		first valid record number is "1"

RETRIEVING DATABASE STATISTICS and VERSION NUMBER

The first record number in a Berkeley DB is record number ONE (1), there is
no record ZERO (0). If the bdbaccess daemon is queried with $how = 1, for record 
ZERO (0), it will return the version number of the underlying database in a form
that can be unpacked by inet_ntoa. The returned data record will contain the
number of keys or unique records currently in the database. Both of these
will be 32 bit fields.

  $name		the name of the database from which to
		fetch the record (usually 'evidence')

  $sockpath	the path to the socket filename, usually
		'/var/run/dbtarpit/bdbread'
	or
		a host and port to connect to in the form
		hostname:port or 123.11.22.10:port

  $is_network	zero for local socket, alarm timeout > 0
		if remote host. Timeout is in seconds.

On a successful lookup of a record, what is returned is the access key, a
packed 4 byte network address as returned by inet_aton('11.22.33.44'), and
the data found for the record. The data may be either a character string or
a numeric value depending on which database was accessed. In the case of the
'evidence' database, it will be an character string.

If a record is not found or there is any other database error, $key will
contain the value INADDR_NONE (the value returned by
inet_aton('255.255.255.255') and $data will contain the error code returned
by Berkeley DB.

If there is a catastrophic failure, such a failure to connect to the domain
socket, B<dataquery> will return 'undef' or and empty array () depending on the
calling context and $@ will be set with the error.

=cut

sub dataquery {
  my($how,$key,$name,$sockpath,$is_network) = @_;  
  my $len;
  my $buffer;
  unless ($len = eval{_common($how,$key,$name,$sockpath,$is_network,\$buffer)}) {
    return () if wantarray;
    return undef;
  }
  my $val;
  if ($len == 8) {
    ($key,$val) = unpack("a4 N4",$buffer);
  } else {
    ($key,$val) = unpack("a4 A*",$buffer);
  }
  return $key unless wantarray;
  return($key,$val);
}

=item * $count=retrieve($howmany,$cursor,$name,\@list,$sockpath,$is_network);

Retrieve a list of $howmany keys from a BDBaccess daemon.

  $howmany = 2 -> 255	the number of keys to retrieve

  $cursor	the starting record number

  $name		the name of the database from which
		to fetch the record

  $listpointer	array reference in which to put list

  $sockpath	the path to the socket filename, usually
		'/var/run/dbtarpit/bdbread'
	or
		a host and port to connect to in the form
		hostname:port or 123.11.22.10:port

  $is_network	zero for local socket, alarm timeout > 0
		if remote host. Timeout is in seconds.

On successful lookup, returns the number of items found (this may be zero)
and the list is filled accordingly with IP addresses in the form to be
decoded by inet_ntoa. On failure, returns undef.

=back

=cut

sub retrieve {
  my($howmany,$start,$name,$lp,$sockpath,$is_network) = @_;
  my $len;
  my $buffer;
  return undef unless
	$len = eval{_common($howmany,$start,$name,$sockpath,$is_network,\$buffer)};

  $_ = substr($buffer,0,1);
  my $count = unpack("C",$_);
  my $sp = 1;
  foreach(0..$count -1) {
    my $raw = substr($buffer,$sp,4);
    $lp->[$_] = unpack("a4",$raw);
    $sp += 4;
  }
  return $count;
}


=head1 EXPORT

	none by default

=head1 EXPORT_OK

	dataquery
	retrieve

	all the functions and constants
	available from B<Socket>

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT

Copyright 2003, Michael Robinton & BizSystems This program
is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published 
by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public
License along with this program; if not, write to the Free
Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

=head1 SEE ALSO

L<Mail::SpamCannibal::BDBaccess>, L<Socket>

=cut

1;
