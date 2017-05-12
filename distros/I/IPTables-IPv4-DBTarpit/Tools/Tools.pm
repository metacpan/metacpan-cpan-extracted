package IPTables::IPv4::DBTarpit::Tools;
use strict;
#use warnings;
#use Carp;

use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK $nf $rr $DBTP_ERROR);

$VERSION = do { my @r = (q$Revision: 1.14 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

require Exporter;
require DynaLoader;
use AutoLoader qw(AUTOLOAD);

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
	DB_NOTFOUND
	DB_RUNRECOVERY
);
@EXPORT_OK = qw(
	$DBTP_ERROR
	inet_aton
	inet_ntoa
	bdbversion
	libversion
	db_strerror
);

$DBTP_ERROR = 0;

bootstrap IPTables::IPv4::DBTarpit::Tools $VERSION;

$nf = t_notfound();
$rr = t_runrecovery();

# Preloaded methods go here.

sub DB_NOTFOUND {$nf}
sub DB_RUNRECOVERY {$rr}

# DESTROY is XS
#sub DESTROY {}

=head1 NAME

  IPTables::IPv4::DBTarpit::Tools - to manipulate tarpit database

=head1 SYNOPSIS

  use IPTables::IPv4::DBTarpit::Tools qw(
	$DBTP_ERROR
	inet_aton
	inet_ntoa
	bdbversion
	libversion
	db_strerror
);

  $tool = new IPTables::IPv4::DBTarpit::Tools (
	# defaults shown - one or more db's
	dbfile	=>	['tarpit','... etc'],
	dbhome	=>	'/var/run/dbtarpit',
	umask	=>	007,
  # optional
	txtfile	=>	['name1','... etc'],
	recover	=>	1,
  );

  $string = db_strerror($DBTP_ERROR);
  $tool = new IPTables::IPv4::DBTarpit::Tools(%hash);
  $tool->closedb;
  $rv = $tool->get($db,$4byteIPaddress);
  ($key,$data) = $tool->getrecno($db,$recno);
  $rv = $tool->remove($db,$4byteIPaddress);
  $rv = $tool->put($db,$4byteIPaddress,$value);
  $rv = $tool->touch($db,$4byteIPaddress,$timestamp);
  $rv = $tool->sync($db);
  $rv = $tool->clear($db);
  $rv = $tool->cull($db,$age,\%hash,$nop); 
  $rv = $tool->dump($db,\%hash);
  $number = $tool->nkeys($db)
  ($string,$major,$minor,$patch)=bdbversion();
  ($string,$major,$minor,$patch)=libversion()  
  $netaddr = inet_aton($dotquad);
  $dotquad = inet_ntoa($netaddr);

=head1 DESCRIPTION

B<IPTables::IPv4::DBTarpit::Tools> provides utilities to manage the database for
B<IPtables> QUEUE packets delivered to user space routine dbtarpit. Utilities are available to 
add/update the DB file as well as get, remove, and expire the host ip's in the databases.

=over 4

=item * $DBTP_ERROR;

The code returned by the last DB operation. A text string representing the
code will be returned by:

=item * $string = db_strerror($DBTP_ERROR);

Return a string describing the error condition in $DBTP_ERROR.

=cut

sub db_strerror {
  return t_db_strerror($_[0]);
}

=item * $tool = new IPTables::IPv4::DBTarpit::Tools(%hash);

Open a database environment and its databases and return its reference.
Returns undef on failure.

  %hash = (
	# defaults shown - one or more db's
	dbfile	=>	['tarpit','... etc'],
	dbhome	=>	'/var/run/dbtarpit',
	umask	=>	007,
  # optional
	txtfile	=>	['name1','... etc'],
	recover	=>	1,
  );

	dbhome	=>	'/var/run/dbtarpit',

Default if not present.
Location of BerkeleyDB sub-system files.

The leading directories must be present and writable. 

	dbfile	=>	['tarpit','...etc'],

Default is 'tarpit' if not present. However, if 'dbfile' is omitted and
'txtfile' is present, no 'dbfile' will be forced by default.
BerkeleyDB file located in B<dbhome> containing 
keys which are four byte ip address's 
(as returned by inet_aton() and values which are 
time in seconds since epoch of the record update.

The combined maximum total number of open dbfiles + txtfiles must be 10 or
less.

Multiple db files may be created, each referenced
in other methods by the file name specified. The
dbname will be the B<file> portion of the path/file
database name.

The home directory and database will be created if they do not exist.
However, the parent directories for B<dbhome> must already exist and have
adequate premissions.

	umask	=>	007,

Default if omitted. Files and directories are created
with mode 0666 and 0777, respectively, masked with 
'umask' of 007 by default.

	txtfile	=>	['name1','name2', etc...]

Optional database(s) that take text as the B<value>. The databases specified
by B<dbfile> only accept and return unsigned long timestamps.

	recover =>	1, # any true value

Use this flag if the Berkeley DB returns a DB_RUNRECOVERY error. The
database environment is destroyed and recreated. Since the databases for
this application are not transactional, the DB_RECOVER flag is not
applicable. DBENV->remove is called to remove the corrupt environment.
All other threads must be stopped and this thread run by itself. 
See the Berkeley DB documentation for further details.

See: B<DATABASE CONFIGURATION FILE>
below for additional configuration options.

=cut

sub new {
  my ($proto,%parms) = @_;
  my $class = ref($proto) || $proto;
  my $tool	= {};

  $tool->{umask}  = $parms{umask} || 007;
  $tool->{dbhome} = $parms{dbhome} || '/var/run/dbtarpit';
  my $savmsk = umask $tool->{umask};
  unless (-e $tool->{dbhome}) {
    mkdir $tool->{dbhome}, 0777;;
  }
  die "$tool->{dbhome} is not a directory\n" unless -d $tool->{dbhome};

  my ($dbfile,$txtfile);

  if (exists $parms{txtfile}) {
    if (ref $parms{txtfile}) {
      $txtfile = $parms{txtfile};
    } else {
      $txtfile = [$parms{txtfile}];
    }
  }
  if (exists $parms{dbfile}) {
    if (ref $parms{dbfile}) {
      $dbfile = $parms{dbfile};
    } else {
      $dbfile = [$parms{dbfile}];
    }
  } elsif (!$txtfile) { 	# must have some db file specs
    $dbfile = ['tarpit'];	# force basic if no specs given
  }

  my @files;
  if ($dbfile) {
    push @files, @$dbfile;
  }
  $tool->{_dbf} = @files;	# db filter marker, items greater than this will not be filtered

  if ($txtfile) {
    push @files, @$txtfile;
  }
  @{$tool->{_db}}{@files} = (0..$#files);

  if ($parms{recover}) {
    t_set_recovery(1);
  }
  $tool->{_mem} = t_nmem();		# get memory allocation
#print "LEN=",length($tool->{_mem}),"\n";
  die "NO MEMORY AVAILABLE" unless $tool->{_mem};
  my $rv = t_new_r($tool->{_mem},$tool->{dbhome},@files);
#  my $rv = t_new($tool->{dbhome},@files);
  t_set_recovery(0);		# unconditional

# restore umask
  umask $savmsk;
  return undef if $rv || !defined $rv;		# failed !

  bless ($tool, $class);
  return $tool;
}

=item * $rv = $tool->closedb();

  returns:	FALSE unconditional

  Close the database files

=cut

sub closedb {
  my $tool = shift;
  t_closedb_r($tool->{_mem});
  return undef;
}

=item * $rv = $tool->get($db,$4byteIPaddress);

  input:	dbname,
		address,  # as returned by inet_aton()

  For dbfile type db's:
  returns:	action code or
		time (seconds) of last update
		  or
		undef if db or key not found
		  or
		0 on ERROR (real db error)
  NOTE:	the error will be in $DBTP_ERROR.
	Use $tool->db_error($DBTP_ERROR) to
	get a string describing the error.

  For txtfile type db's:
  returns:	text string

=cut

sub get {
  my($tool,$db,$addr) = @_;
  unless (exists $tool->{_db}->{"$db"}) {
    $DBTP_ERROR = DB_NOTFOUND();
    return undef;
  }
  t_get_r($tool->{_mem},$tool->{_db}->{"$db"},$addr,$tool->{_dbf});
}

=item * ($key,$data) = $tool->getrecno($db,$recno);

  input:	dbname,
		record number

  for all types the first element,
  returns:	a key consisting of
		a 4byteIPaddress

  for dbaddr types a second element
  returns:	action code or
		time (seconds) of last update

  for dbtxt types a second element
  returns:	text string

  In scalar context, returns only
	only the key -- 4byteIPaddress

  returns:	an empty array or undef
		if there is a db error 
		or record is not found
		for array and scalar 
		context as appropriate
  
NOTE: (in BIG LETTERS!)

Berkeley DB provides a "1" based numbering system for record numbers. i.e.
the first record number is "1". Attempting to access record "0" will create
and error, you've been warned.

=cut

sub getrecno {
  my($tool,$db,$recno) = @_;
  unless (exists $tool->{_db}->{"$db"}) {
    $DBTP_ERROR = DB_NOTFOUND();
    if (wantarray) {
      return ();
    }
    return undef;
  }
  t_getrecno_r($tool->{_mem},$tool->{_db}->{"$db"},$recno,$tool->{_dbf});
}

=item * $rv = $tool->remove($db,$4byteIPaddress);

  input:	dbname,
		address,  # as returned by inet_aton()
	
  returns:	ZERO (null) on success
		  or
		undef on key not found
		  or
		non-zero, see BerkeleyDB documentation

  Removes database record
  
=cut

sub remove {
  my($tool,$db,$addr) = @_;
  unless (exists $tool->{_db}->{"$db"}) {
    $DBTP_ERROR = DB_NOTFOUND();
    return undef;
  }
  local $_ = t_del_r($tool->{_mem},$tool->{_db}->{"$db"},$addr);
}

=item * $rv = $tool->put($db,$4byteIPaddress,$value);

  input:	dbname,
		address, # as returned by inet_aton()
		value

  returns:	ZERO on success
		  or
		non-zero, see BerkeleyDB documentation

  Update or insert a record into named database

  USE caution, do not insert text values into databases
  specified with B<dbfile>. You will get erroneous results.

=cut

sub put {
  my($tool,$db,$addr,$value) = @_;
  unless (exists $tool->{_db}->{"$db"}) {
    $DBTP_ERROR = DB_NOTFOUND();
    return $DBTP_ERROR;
  }
  t_put_r($tool->{_mem},$tool->{_db}->{"$db"},$addr,$value,$tool->{_dbf});
}

=item * $rv = $tool->touch($db,$4byteIPaddress,$timestamp);

  input:	dbname,
		address, # as returned by inet_aton()
		$timestamp   or current time

  returns:	ZERO on success
		  or
		non-zero, see BerkeleyDB documentation

  Updates or creates or updates record with the
  $timestamp or current epoch time in seconds if
  $timestamp is not present. 

  (may be used to put arbitrary non-zero values in
  the database for test purposes -- this will break
   normal operations)

=cut

sub touch {
  my($tool,$db,$addr,$timestamp) = @_;
  $timestamp = time unless $timestamp;
  put($tool,$db,$addr,$timestamp);
}

=item * $rv = $tool->sync($db);

Flush the cached pages of the database to file. $tool->sync() should be
performed after database update (remove, put, touch) when the operation(s)
are complete.

  input:	db name
  returns:	false on success or
		Berkeley DB error code

=cut

sub sync {
  my ($tool,$db) = @_;
  unless (exists $tool->{_db}->{"$db"}) {
    $DBTP_ERROR = DB_NOTFOUND();
    return $DBTP_ERROR;
  }
  t_sync_r($tool->{_mem},$tool->{_db}->{"$db"});
}

=item * $rv = $tool->clear($db);

Clear a database of all records.

  input:	db name
  returns:	false on success or
		Berkeley DB error code

=cut

sub clear {
  my ($tool,$db) = @_;
  unless (exists $tool->{_db}->{"$db"}) {
    $DBTP_ERROR = DB_NOTFOUND();
    return $DBTP_ERROR;
  }
  my $key;
  my $exitstatus;
  while ($key =  t_getrecno_r($tool->{_mem},$tool->{_db}->{"$db"},1,$tool->{_dbf})) {
    my $status = t_del_r($tool->{_mem},$tool->{_db}->{"$db"},$key);
    return $status if $status;	# bail if error
    next if defined $status;	# zero is the good answer
    $exitstatus = $DBTP_ERROR;
    last;			# must be DB_NOTFOUND which is not good
  }
  return $exitstatus if $exitstatus;
  t_sync_r($tool->{_mem},$tool->{_db}->{"$db"});
}

=item * $rv = $tool->cull($db,$age,\%hash,$nop);

  input:	dbname,
		age in seconds from now,
		hash pointer,
		no operation = true

  returns:	number of keys removed

Fills the %hash with 4 byte IP address and time tag
for each address older than $age seconds from 
the current time.

If $nop is false, the %hash represents the addresses
deleted from the database. If $nop is true, no 
action is taken on the database. The %hash is just
returned showing what action is proposed.

This operation can consume a lot of memory and is intended primarily for use
in testing on smallish databases.
Use a tied %hash if you expect large arrays.

=cut

sub cull {
  my($tool,$db,$age,$hashpoint,$nop) = @_;
  my $now = time;
  my $cursor = 1;
  while ($cursor) {
    @_ = $tool->getrecno($db,$cursor++);
    last unless @_;
    my ($key,$val) = @_;
    next unless $val + $age < $now;
    $hashpoint->{$key} = $val;
  }
  my $keycount = keys %$hashpoint;

  unless ($nop) {
    foreach(keys %$hashpoint) {
      $tool->remove($db,$_);
    }
    $tool->sync($db) if $keycount;
  }
  return $keycount;
}

=item * $rv = $tool->dump($db,\%hash);

  input:	dbname,
		pointer to hash

  returns:	0 on success
		  or
		BerkeleyDB error code

Returns the hash filled with the contents
of the database.

This operation can consume a lot of memory and is intended primarily for use
in testing on smallish databases. 
Use a tied %hash if you expect large arrays.

=cut

sub dump {
  my($tool,$db,$hp) = @_;
  unless (exists $tool->{_db}->{"$db"}) {
    $DBTP_ERROR = DB_NOTFOUND();
    return $DBTP_ERROR;    
  }
  t_dump_r($tool->{_mem},$tool->{_db}->{"$db"},$hp,$tool->{_dbf});
}

=cut

=item * $number = $tool->nkeys($db)

Returns the number of unique keys (or records) in a connected database. If
there is an error, it return undef and sets the error number in $DBTP_ERROR.

  input:	database name
  returns:	number of keys
		or zero

Note: zero is a perfectly good answer. If the error number is also zero,
then that's the real answer.

=cut

sub nkeys {
  my($tool,$db) = @_;
    unless (exists $tool->{_db}->{"$db"}) {
    $DBTP_ERROR = DB_NOTFOUND();
    return 0;    
  }
  t_nkeys_r($tool->{_mem},$tool->{_db}->{"$db"});
}

=item * ($string,$major,$minor,$patch)=bdbversion();

Returns the version of the installed Berkeley DB.

  input:	none
  output:	scalar context, a string
		describing the version
    or		array context, the string
		as above followed by the
		major, minor, and patch
		revision levels

=cut

sub bdbversion {
  t_bdbversion();
}

=item * ($string,$major,$minor,$patch)=libversion();

Returns the version of the bdbtarpit library.

  input:	none
  output:	scalar context, a string
		describing the version
    or		array context, the string
		as above followed by the
		major, minor, and patch
		 revision levels

=cut

sub libversion {
  t_libversion();
}

=item * $netaddr = inet_aton($dotquad);

Provided for convenience. This method is the same as the one in Socket from
perl 5.8.
Takes a string giving the name of a host, and translates that to
the 4-byte string (structure). Takes arguments of both the 
'blackhole.spamcannibal.org' type and '86.1.2.4'. If the
host name cannot be resolved, returns undef.
For multi-homed hosts (hosts with more than one address), the
first address found is returned.

=item * $dotquad = inet_ntoa($netaddr);
	
Provided for convenience. This method is the same as the one in Socket from 
perl 5.8.	
Takes a four byte ip address (as returned by inet_aton()) and
translates it into a string of the form 
'd.d.d.d' where the 'd's are numbers less than 256 (the normal
readable four dotted number notation for internet addresses).

=back

=head1 DATABASE CONFIGURATION FILE [optional]

Usually used to increase database cache size.

Most of the configuration information that can be specified to 
DB_ENV methods can also be specified using a configuration file. 
Any file named DB_CONFIG in the database home directory will be 
read for lines of the format NAME VALUE.

One or more whitespace characters are used to delimit the two parts of 
the line, and trailing whitespace characters are discarded. All empty 
lines or lines whose first character is a whitespace or hash (#) 
character will be ignored. Each line must specify both the NAME and the 
VALUE of the pair. The specific NAME VALUE pairs are documented in the 
Berkeley DB manual for the corresponding methods.

See: http://www.sleepycat.com/docs/ref/env/db_config.html

=head1 DEPENDENCIES

	none

=head1 EXPORT

        DB_NOTFOUND
        DB_RUNRECOVERY

=head1 EXPORT_OK

        $DBTP_ERROR 
        inet_aton
        inet_ntoa
        bdbversion
        libversion
        db_strerror

=head1 ACKNOWLEDGEMENTS

inet_aton and inet_ntoa have been included with a few modifications from
perl-5.80 by Larry Wall, copyright 1989-2002. Thank you Larry for making
PERL possible for all of us.

Much of how to write this module and the bdb functions in the SpamCannibal
package I learned from reading the source code of Paul Marquess's
BerkeleyDB-0.20. The versioning information for Berkeley DB was all taken
directly from Paul's module. Thanks Paul.

=head1 COPYRIGHT

Copyright 2003 - 2008, Michael Robinton <michael@bizsystems.com>
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

=head1 SEE ALSO

perl(1), Socket(3)

=cut

1;
__END__
