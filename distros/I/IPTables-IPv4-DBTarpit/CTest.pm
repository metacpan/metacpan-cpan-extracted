package IPTables::IPv4::DBTarpit::CTest;

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

$modVERSION = do './DBTarpit.pm';

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

bootstrap IPTables::IPv4::DBTarpit::CTest $modVERSION;

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
the the 'C' pieces for F<dbtarpit>

=over 4

=item * $pid = t_pidrun();

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

=item * $rv=t_main(qw(program_name args, arg2,..., argN);

  input:	program name
		-d
		-f etc... see readme
  output:	number of arguments passed

=item * t_setsig();

  set the signal handler. 
  test routine should issue SIGINT 
  to child and catch resulting text

=item * ($size,$seed) = t_inirand(test);

  input:	0 = seed with time
  		n = seed with "n"
  output:	size of random array
		random number seed value

  Initialize the random number generator

=item * @random = t_fillrand();

  input:	none (use t_inirand above)
  output:	random array of $size

=item * $IPPROTO_TCP = t_ret_IPPTCP();

  input:	none
  output:	numeric value of IPPROTO_TCP

=item * $rv = t_chk_trace();

  input:	none
  output:	conditional return value 
		of "trace_tarpit" (below)

  conditionally called by check_4_tarpit(m)
  int
  tarpit(void * v)
  {
    extern int trace_tarpit;
    extern int dummy_tarpit;
    trace_tarpit = dummy_tarpit;
    return(trace_tarpit);
  }

=item * t_Lflag(ell);

Set the value of Lflag;

  input:	integer
   output:	none

=item * t_NF_ACCEPT();

Return the value of NF_ACCEPT.

=item * t_NF_DROP();

Return the value of NF_DROP.

=item * $rv = t_check(addr,ts,xf,prot,tarpitresp);

  input:	ip address (dot quad)
		timestamp
		xflag
		protocol
		tarpit response
  output:	rv of check_4_tarpit(m)

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

=item * $rv = t_findaddr(addr,timestamp);

  input:	packed network address
		timestamp
  output:	true if address found
		in primary database

  updates timestamp in database if addr found

=item * t_saveaddr(addr, timestamp);

  input:	packed network address
		timestamp
  output:	none

  inserts address (if absent) in secondary
  database, updates timestamp

=item * t_statn(name);

  input:	database name
  output:	number of keys
		or zero on error

=item * ($errno,$fd)=t_LogPrint(dbhome,fifoname,message,oflag,Oflag,[fd])

Directly call the LogPrint routine.

  input:	pointer to home path,
		pointer to fifo name,
		pointer to message,
		oflag,
		Oflag,
		fd value [optional]
		(defaults to 0)
  output:	error number,
		file descriptor

    in scalar context returns errno only

    prints somewhere dependent on

	fifoname
	oflag
	Oflag

  don't print to a closed syslog!

=item * t_fifo_close();

Close the fifo fd opened by LogPrint if it exists;

=item * @errors = t_errors();

Returns an array of error numbers used for test.

EPIPE,ENOSPC,EEXIST,ENOENT,ENOTDIR,ENXIO,ENODEV

=item * t_get(ai,addr,notstring)

Same functionality as Tools::t_get but uses readOne

=item * t_getrecno(ai,cursor,notstring)

Same functionality as Tools::t_getrecno but uses readOne

=item * t_libversion(ai)

Similar functionality to Tools::t_libversion() and Tools::t_nkeys;

  input:	index to database
  returns:	number of keys,
		major version,
		minor version,
		patch

In scalar context returns only number of keys

=back

=head1 EXPORT

None

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 See also: files in subdirectory ./t

=cut
