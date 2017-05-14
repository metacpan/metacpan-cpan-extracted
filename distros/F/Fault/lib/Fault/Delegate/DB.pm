#==============================================================================
# Filename:            DB.pm
# Description:         Database Logger Delegate.
# Original Authoer:    Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:20:19 $ 
# Version:             $Revision: 1.10 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#==============================================================================use strict;
use Fault::Dbh;
use Fault::DebugPrinter;
use Fault::ErrorHandler;
use Fault::Delegate;
use Fault::Msg;

package Fault::Delegate::DB;
use vars qw{@ISA};
@ISA = qw( Fault::Delegate );

#=============================================================================
#                      Family internal methods
#=============================================================================
# *** Not much to do if it fails, but think about it anyway.

sub _write ($$) {
    my ($self,$msg) = @_;
    my ($stamp,$priority,$type,$p,$m) = $msg->get;

    $self->{'logins'}->execute($stamp,$priority,$p,$type,$m);
    return 1;
}

#------------------------------------------------------------------------------

sub _connect ($) {
  my $self = shift;
  my ($DBH,$dbh,$sth_del,$sth_ins,$sth_lkp);

  return 1 if (defined $self->{'dbh'});

  $DBH = Fault::Dbh->open ($self->{'dbname'},
			 $self->{'user'},
			 $self->{'pass'});

  $dbh = (defined $DBH) ? $DBH->dbh : undef;
  if (!defined $dbh) {
       $self->warn ("Failed to connect to db \'$self->{'dbname'}\' " . 
		     "for user \'$self->{'user'}\'");
       return 0;
   }

  @$self{'dbh','logins','faultins','sthdel','sthlist','sthexist'} =
    ($DBH,
     $dbh->prepare ("INSERT INTO log VALUES      ('',?,?,?,?,?)"),
     $dbh->prepare ("INSERT   INTO faults VALUES ('',?,?,?,?,?)"),
     $dbh->prepare ("DELETE   FROM faults WHERE Message=? and Process=?"),
     $dbh->prepare ("SELECT * FROM faults WHERE               Process=?"),
     $dbh->prepare ("SELECT * FROM faults WHERE Message=? and Process=?"),
     );
  return 1;
}

#------------------------------------------------------------------------------
# NOTE: The undef is really important. Otherwise a pointer with a valid open
# db handle exists before processes get spawned. If a dbh gets passed through
# to two different running processes... mysql gets really confused when both
# try to access the same connection.
#
# NOTE: I hope that moving it all here instead of doing this to objects 
#       will be just as effective.
#

sub _disconnect ($) {
    my $self = shift;
    if (defined $self->{'dbh'}) {$self->{'dbh'}->close;}

    @$self{'dbh','logins','faultins','sthdel','sthlist','sthexist'} = 
	(undef,undef,undef,undef,undef,undef);
    return 1;    
}

#=============================================================================
#                      Local internal methods
#=============================================================================

sub _dump ($$) {
  my ($self,$p) = @_;
  my @list      = ();

  Fault::DebugPrinter->dbg (3, "Dump of fault table.");
  $self->{'sthlist'}->execute ($p) || (return (@list));

  my $cnt  = $self->{'sthlist'}->rows;
  Fault::DebugPrinter->dbg (3, "Found $cnt faults.");

  while ($cnt-- > 0 ) {push @list, ($self->{'sthlist'}->fetchrow_hashref);}
  $self->{'sthlist'}->finish;
  return (@list);
}

#==============================================================================
#			       CLASS METHODS
#==============================================================================

sub new ($$$$$) {
    my ($class,$host,$dbname,$user,$pass) = @_;
    my $self = bless {}, $class;
    defined $host or ($host="localhost");

    if ((ref $host) or !POSIX::isalnum $host) {
	$self->warn 
	    ("Database server name invalid: defaulting to localhost.");
	$host = "localhost";
    }

    if (!defined $dbname or (ref $dbname) or !POSIX::isalnum $dbname) {
	$self->warn
	    ("Fail: dbname string is invalid or undefined!");
	return undef;
    }

    if (!defined $user or (ref $user) or !POSIX::isalnum $user) {
	$self->warn
	    ("Fail: user name string is invalid or undefined!");
	return undef;
    }

    if (!defined $pass or (ref $pass) or !POSIX::isprint $pass) {
	$self->warn
	    ("Fail: password string is invalid or undefined!");
	return undef;
    }

    @$self{'host','dbname','user','pass'} = ($host,$dbname,$user,$pass);

    return ($self->test) ? $self : undef;
}

#==============================================================================
#			    INSTANCE METHODS
#==============================================================================
#		Logger Internal Hook Callback Methods
#==============================================================================
# Callback from Logger when it raises a fault

sub trans01 ($$) {
    my ($self,$msg) = @_;
    my ($stamp,$priority,$type,$p,$m) = $msg->get;
    my $val                           = 0;

    if ($self->_connect) {

	# *** Not much to do if it fails, but think about it anyway.
	$self->{'sthexist'}->execute($m,$p);
	($self->{'sthexist'}->rows == 0) || (return 0);

	# *** Not much to do if it fails, but think about it anyway.
	$self->{'faultins'}->execute($stamp,$priority,$p,$type,$m);
    }
    $self->_disconnect;
    return 0;
}

#------------------------------------------------------------------------------
# Callback from Logger when it clears a fault
#
sub trans10 ($$) {
    my ($self,$msg) = @_;
    my $val         = 0;

    if ($self->_connect) {
	# *** Not much to do if it fails, but think about it anyway.
	$self->{'sthdel'}->execute($msg->msg,$msg->priority);
    }
    $self->_disconnect;
    return 0;
}

#------------------------------------------------------------------------------
# Callback from Logger when it initializes it's in-memory fault table.

sub initfaults ($) {
    my ($self)  = @_;
    my @msglist = ();

    if ($self->_connect) {
	foreach my $fault ($self->_dump($self->processname)) {
	    push @msglist, ($fault->{'Message'});
	}
    }
    $self->_disconnect;
    return @msglist;
}

#==============================================================================
#                          POD DOCUMENTATION
#==============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Fault::Delegate::DB - Database Logger Delegate.

=head1 SYNOPSIS

 use Fault::Delegate::DB;
 $self = Fault::Delegate::DB->new ($host,$host,$dbname,$user,$pass);
 $okay = $self->log               ($msg);
 $zero = $self->trans01           ($msg);
 $zero = $self->trans10           ($msg);
 @list = $self->initfaults;

=head1 Inheritance

 UNIVERSAL
   Fault::Delegate
     Fault::Delegate::DB

=head1 Description

This is a Logger delegate for database logging.

This Class manages a database logging connection to a local Mysql database
server. 

Remote database access is not supported at this time. It will require changes 
to the Fault::Dbh module, or improvements in MySQL (and total disappearance 
of old versions) which prevent exhaustion of connections if your processes 
rapidly create and destroy connections. 

Also note that some attempt has been made to be thread-safe. I discovered that
if a handle was created in a parent there was a possibility it could be
reused in a child process. The parent and child then had interleaved 
communications with the server which completely confused it.

=head1 Database requirements

There should be two tables defined on the MySQL database server under the 
same database: log and fault. You must have a username and password that 
give you rights to select, insert and delete from them.

 use Mydatabase;
 CREATE TABLE log ( \
    LogId	bigint unsigned auto_increment, \
    Time        datetime                       NOT NULL, \
    Priority	enum('emerg','alert','crit','err','warning','notice','info','debug') NOT NULL DEFAULT 'err', \
    Process     varchar(20)                    NOT NULL DEFAULT 'Unspecified', \
    Type        enum('BUG','SRV','NET','DATA','NOTE') NOT NULL DEFAULT 'BUG', \
    Message	blob                           NOT NULL, \
 UNIQUE (LogId), \
 PRIMARY KEY  (LogId));
 

 CREATE TABLE faults ( \
    FaultId	     bigint unsigned auto_increment, \
    Time             datetime                   NOT NULL, \
    Priority	     enum('emerg','alert','crit','err','warning','notice','info','debug') NOT NULL DEFAULT 'err', \
    Process          varchar(20)                NOT NULL DEFAULT 'Unspecified', \
    Type             enum('BUG','SRV','NET','DATA','NOTE') NOT NULL DEFAULT 'BUG', \
    Message	     blob                       NOT NULL, \
 UNIQUE (FaultId), \
 PRIMARY KEY  (FaultId));

=head1 Examples

 use Fault::Delegate::DB;
 use Fault::Msg;
 use Fault::Logger;

 my $msg       = Fault::Msg               ("Arf!");
 my $baz       = Fault::Delegate::DB->new ($host,$db,$user,$pass);
 my $waslogged = $baz->log                ($msg);

                 Fault::Logger->new       ($baz);
 my $waslogged = Fault::Logger->log       ("Bow! Wow!");

 [See Fault::Logger for a detailed example.]

=head1 Class Variables

None.

=head1 Instance Variables

 host		Name of host computer.
 dbname         Name of database.
 user           Name of user.
 pass           Password string.

 Transient instance variables.
 dbh            database handle.
 logins         prepared log insert statement handle 
 faultins       prepared fault insert statement handle 
 sthdel         prepared fault delete statement handle 
 sthlist        prepared fault select all statement handle 
 sthexist       prepared fault select one statement handle 

=head1 Class Methods

=over 4

=item B<$self = Fault::Delegate::DB-E<gt>new ($host,$dbname,$user,$pass)>

Create an object to mediate log and fault communications with a 
database server. It has only been tested with MySQL thus far.

$host can only be "localhost" at this time. If undef, $host will be set
to localhost. If $host is invalid in any other way, a warning will be 
issued and $host will be set to localhost.

$dname is the name of the MySQL database in which the tables log and fault
exist; $user is a user name that can read and write those tables; $pass
is that users MySQL password.

Returns undef on failure to create the object and connect to the db.

=back 4

=head1 Instance Methods

=over 4

=item B<$okay = $self-E<gt>log ($msgobj)>

Inserts a log message in the database and returns true if we succeeded in 
doing so. 

=item B<$zero = $self-E<gt>trans01 ($msgobj)>

Inserts a fault record for the current process name and the $msg string. 
If one already exists, do nothing. It always returns 0.

=item B<$zero = $self-E<gt>trans10 ($msgobj)>

Removes a fault record that matches the current process name and
the $msg string. If there is not, do nothing. It always returns 0.

=item B<@list = $self-E<gt>initfaults>

Requests a current list of faults from the database when Logger initializes.
@list contains a simple list of strings, where each string represents a 
unique active fault condition belonging to the current process.

 ("fault message 1", "fault message 2", ...)

If it cannot connect to the database, an empty list is returned.

=back 4

=head1 Private Class Methods

None.

=head1 Private Instance Methods

=over 4

=item B<$bool = $self-E<gt>_write ($msg)>

=item B<$bool = $self-E<gt>_connect>

=item B<$bool = $self-E<gt>_disconnect>

Impliments the above overrides to the internal family protocol utilized by 
the Fault:Delegate log and test methods.

=back 4

=head1 Errors and Warnings

Local warning messages are issued if the db server cannot be reached or has 
any problems whatever. 

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Fault::Logger, Fault::Delegate, Fault::Msg, Fault::Dbh, 
Fault::ErrorHandler, Fault::DebugPrinter

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: DB.pm,v $
# Revision 1.10  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.9  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.8  2008-07-24 21:17:24  amon
# Moved all todo notes to elsewhere; made Stderr the default delegate instead of Stdout.
#
# Revision 1.7  2008-05-09 18:24:55  amon
# Bugs and changes due to pre-release testing
#
# Revision 1.6  2008-05-08 20:22:50  amon
# Minor bug fixes; shifted fault table and initfault from Logger to List
#
# Revision 1.5  2008-05-07 18:14:55  amon
# Simplification and standardization. Much more is inherited from Fault::Delegate.
#
# Revision 1.4  2008-05-05 19:25:49  amon
# Catch any small changes before implimenting major changes
#
# Revision 1.3  2008-05-04 14:43:18  amon
# Updates to perl doc; minor code changes.
#
# Revision 1.2  2008-05-03 00:56:57  amon
# Changed standard argument ordering.
#
# Revision 1.1.1.1  2008-05-02 16:38:11  amon
# Fault and Log System. Pared off of DMA base lib.
#
# Revision 1.5  2008-04-18 13:37:59  amon
# Added some fault bailout code and warning.
#
# Revision 1.4  2008-04-18 13:05:13  amon
# Added call to Dbh close.
#
# Revision 1.3  2008-04-18 12:52:08  amon
# Minor changes.
#
# Revision 1.2  2008-04-18 12:48:14  amon
# Added arg checking and bail out to new method.
#
# Revision 1.1  2008-04-18 11:32:32  amon
# I combined three old modules into one simplified database logger delegate 
# class.
#
# 20041012	Dale Amon <amon@vnl.com>
#		Created starting from Document::LogFile as a template.
#
# DONE	* Make docs similar to docs in SimpleHttp. [DMA20080416-20080416]
#	* Bring in args to new method for host, user and password
#         [DMA20080416-20080416]
#	* I can move some internal methods like _process_name and
#	  _timestamp up to a Superclass Delegate.pm
#         [DMA20080416-20080416]
#	* Create a Delegate.pm which defines the full protocol
#	  for this set of classes. [DMA20080416-20080416]
#	* If a superclass defines stubs, then my use of 'can' methods
#	  to check the API from Logger won't work!
#	  (So I simply comment them out to indicate they are part of the
#	   optional protocol.) [DMA20080416-20080416]
#	* The LogTable and LogFault need the timestamp and
#	  processname methods. (I will fold them into this module.
#	  [DMA20080416-20080416]
#	* Add arg lists including marks for optional args.
#	  [DMA20080416-20080417]
#	* Add in all the connection checking and failsafe code.
#	  [DMA20080416-20080418]
1;
