package Mail::SpamCannibal::DNSBLserver::CTest;

#use 5.006;
use strict;
#use warnings;
use Carp;

use vars qw(@ISA $modVERSION);

require Exporter;
require DynaLoader;
use AutoLoader;

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

$modVERSION = do './DNSBLserver.pm';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined CTest macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Mail::SpamCannibal::DNSBLserver::CTest $modVERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

CTest - Perl extension for testing local 'C' routines

=head1 SYNOPSIS

  use CTest;

=head1 DESCRIPTION

This module consists of various test routines to exercise the subroutines in
the the 'C' pieces for F<dnsbls>

=over 4

=item * $rv=t_main(qw(program_name args, arg2,..., argN);

  input:	program name
		-d
		-f etc... see readme
  output:	number of arguments passed

=item * t_setsig();

  set the signal handler. 
  test routine should issue SIGINT 
  to child and catch resulting text

=item * t_set_parent(val);

  set the value of "parent"
  return the previous value

=item * t_set_qflag(val);

  set the value of "qflag"
  return the previous value

=item * t_set_stop(val);

  set the value of "stop"
  return the previous value

  This flag forces 'main' to return(0)
  as soon as it enters the -T print 
  routine BEFORE it issues STDOUT

=item * $pid = t_pidrun()

  input:	none
  output:	pid found in pid file

  see t_chk4pid below

=item * t_savpid(path2pidfile)

  input:	path to pid file
  output:	none

  saves the pid of the current process
  in the pid file (path2pidfile)

=item * $pidpath = t_chk4pid(path)

  input:	path to pid file
  output:	undef or path to pid file

  checks for a process running with the pid
  found in "path". If the process is running
  return undef, otherwise return the "path".
  Always places the "pid" found in pid file
  into the variable "pidrun".

=item * $pidpath = t_pidpath();

  input:	none
  output:	current pidpath/file

=item * $err = t_init(home,...);

  input:	dbhome
		db file name
		secondary db file name (optional)
  output:	0 or error code

=item * $err = t_dump(which);

  input:	0  = primary db
		nz = secondary db
  output:	0 or error code

  prints database to STDOUT in the format
	dot.quad.addr => timestamp

=item * t_close();

  input:	none
  output:	none

  close the database files and environment

=item * $data = t_get(which,addr);

  input:	0  = primary db
		nz = secondary db
  output:	data (long)
		or undef if not there

=item * $short_hostname = t_short();

  input:	none
  output:	short host name

=item * $rv = t_munge(fd,bp,msglen,is_tcp)

  input:	handle number, [fileno(FD)]
		pointer buffer,
		length of buffer,
		tcp flag

  output:	number of bytes processed,
		-1 on error

  NOTES: is_tcp
  Setting is_tcp true forces TCP mode in the ns.c
  is_tcp tells ns.c how to process the requests 
  (TCP or UDP) and specifically how to process AXFR 
  requests so we can test all of the program branches.
 
  is_tcp  = 0  use UDP
  is_tcp  = 1  use TCP, AXFR in one message if possible
  is_tcp  = 2  use TCP, AXFR in two messages. The first 
               message contains all overhead records, SOA, 
               NS, MX and local host stuff. The second 
               message contains all numeric A & TXT records  
               or as many as will fit.
  is_tcp >= 3  The first record is the same as is_tcp 2. 
               Each additional record contains an A + TXT 
               record pair for a particular numeric record, 
               with the last record containing only the SOA

=item * $rv = t_cmdline(cmd,stuff);

  input:	one of n a b e m L I z c P Z
		parameter
  output:	true on success else false

  SEE:		command line parameters for
		dnsbls -n -a -b -e -m -L -I -z -c -P -Z

B<L> sets the name of the local host. If the zone name has been
set already then the zoneEQlocal flag is set appropriately. If local host
name is already set when the zone name is set, zoneEQlocal will again be set
appropriately.

B<I> sets the IP address of the local host
		
=item * $rv = t_set_resp(seria_rec,stdResp,stdRespBeg);

Set various internal address registers

  input:	ipaddr for serial record
		ipaddr for stdResp
		ipaddr for stdRespBeg
  output:	true on success,
		else undef

  Set the ip address for db access

=item * $rv = t_cmp_serial(s1,s2);

  input:	zone serial number pair
  returns:	 0	s1 = s2
		-1	s1 < s2
		 1	s1 > s2
		>1	 undefined

=item * $rv = t_name_skip(buf);

  input:	buffer of characters/numbers
  returns:	integer offset from begining
		of buffer past dn names


=item * $rv = t_set_parent(val);

Set parent pid value

  input:	new value
  returns:	old value

=item * $rv = t_set_qflag(val);

Set qflag value

  input:	new value
  returns:	old value

=item * @rv or $rv = t_ret_resp();

  returns:	one or more of zonefile
		response values aa,ab,ac,ad
		as returned by inet_ntoa

=item * t_initlb();

Initialize ip address nibbles, text responses, A responses, origin level
ah..dz txa..txd aa..ad org to zero

=item * $rv = t_set_org(val);

Set org value

  input:	new value
  returns:	old value

=item * @rv or $rv = t_ret_a_nibls();

  returns:	one or more of zonefile
		nibble groups
		ah.am.al.az
		bh.bm.bl.bz
		ch.cm.cl.cz
		dh.dm.dl.dz
		as returned by inet_ntoa

=item * $rv = t_mybuffer(which)

Returns one of mybuffer, txa, txb, txc, txd as selected by which (0,1,2,3,4)
respectively.
		
=item * t_set_dbhome(path);

Set dbhome to 'path'

  input:	/some/path

=item * t_tabout(name,type);

Tab justify to 3 tabs, the name and type => 'mybuffer' which can be
retrieved with B<t_mybuffer(0)>

 mybuffer = 'name			A	'

=item * t_add_A_rec(name,ip_response);

Use 'tabout' to the name, 'A' type plus ip_response code (text)
and put it in 'mybuffer' which can be retrieved with B<t_mybuffer(0)>

The text ip_response code is converted by inet_aton internally for testing.

=item * t_ishift();

Perform shift operation:

	ip address nibbles
    ch->dh cm->dm cl->dl cz->dz
    bh->ch bm->cm bl->cl bz->cz
    ah->bh am->bm al->bl az->bz
	response codes
    ac->ad ab->ac aa->ab
	txt responses
    txc->txd txb->txc txa->txb

=item * t_precrd(F,name,resp,text);

Print A record line and conditionally TXT line depending on the Zflag

  input:  File handle,
	  name fragment,
	  response code (ascii)
	  text string

=item * t_oflush(F);

Flush the adress nibbles and related codes and text to the output stream 'F'

  input:	file handle

=item * t_iload(netaddr,resp,text);

Load the address, response, text record into process stack.

  input:	netaddr	=> ah, am, al, az
		resp	=> aa
		text	=> txa

=item * t_iprint(F);

Conditionally print process stack based on the zonefile host address
nibbles.

  input:	file handle

=item * $rv = t_zone_name();

Return the zone name

  input:	none
  returns:	zone name or undef

=item * $rv = t_zonefile(fd);

Dump a zonefile named 'zonename.tmp' to the db home directory then rename it
to 'zonename.in'

  input:     file handle
  returns:   0 on success
	     1 no serial number found
	    -1 start/end serial mismatch

=item * ($delta,$partsum,$partmax,$charsum) = t_ratelimit(
	$run,
	$new_tv_sec,
	$new_tv_usec,
	$then_tv_sec,
	$then_tv_usec,
	$diskmax,
	$charsum,
	$partsum
);

  input:	run,	true=normal, false=debug/test
		struct timeval 'new' sec, usec
		struct timeval 'then' sec, usec
		diskmax,	rate limit chars/sec
		charsum,	characters so far
		partsum,	partial sum
  returns:	timeval delta,
		partsum,	new average
		partmax		initial value
		charsum		total so far or cleared

  If either element of 'then' is undefined then the 
  remaining internal value is used rather than
  being set from the input data

=back

=head1 EXPORT

None

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 See also: files in subdirectory ./t

=cut
