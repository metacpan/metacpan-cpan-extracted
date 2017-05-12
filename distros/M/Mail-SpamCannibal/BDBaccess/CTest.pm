package Mail::SpamCannibal::BDBaccess::CTest;

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

$modVERSION = do './BDBaccess.pm';

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

bootstrap Mail::SpamCannibal::BDBaccess::CTest $modVERSION;

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
the the 'C' pieces for F<bdbaccess>

=over 4

=item * $rv=t_main(qw(program_name args, arg2,..., argN);

  input:	program name
		-d
		-f etc... see readme
  output:	number of arguments passed

=item * t_setport(pnum);

  set the port value to pnum

  input:	integer port number
  output:	none


=item * t_setsig();

  set the signal handler. 
  test routine should issue SIGINT 
  to child and catch resulting text

=item * t_set_parent(val);

  set the value of "parent"
  return the previous value

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

  input:	dbhome, arg1...argN
  output:	0 or error code

=item * $err = t_dump(which, name);

  input:	0  = primary db
	  or	nz = secondary db,
		database name

	this only works for specific
	test sequence used in the 
	test suite.

  output:	0 or error code

  prints database to STDOUT in the format
	dot.quad.addr => timestamp

=item * t_close();

  input:	none
  output:	none

  close the database files and environment

=item * $data = t_get(which,addr,name);

  input:	0  = primary db
	  or	nz = secondary db
		database name

  output:	data (long)
		or undef if not there

=item * ($key,$data)=t_getrecno(which,name,cursor);

  input:	0  = primary db
	  or	nz = secondary db
		database name,
		cursor (starting at 1)

  output:	key, data

=item * $string = t_bdberror(status);

  input:	BDB status code
  output:	string representing the code

=item * $version_string=t_bdbversion();

  input:	none
  output:	BDB version

=item * $nrecords = t_bdbcount(name);

  input:	name of database
  output:	number of records in db

NOTE: database must be open

=back

=head1 EXPORT

None

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 See also: files in subdirectory ./t

=cut
