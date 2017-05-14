#================================== Dbh.pm ===================================
# Filename:             Dbh.pm
# Description:          Objectifies Database handles so we only need one
# Original Author:      Dale M. Amon
# Revised by:           $Author: amon $ 
# Date:                 $Date: 2008-08-28 23:20:19 $
# Version:              $Revision: 1.5 $
# License:		LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use DBI;

package Fault::Dbh;
use vars qw{@ISA};
@ISA    = qw ( UNIVERSAL );

#=============================================================================
#                          CLASS METHODS                                    
#=============================================================================
my ($DBH,$DBHCNT) = (undef,0);

sub init {my $class=shift; ($DBH,$DBHCNT) = (undef,0); return $class;}


#-----------------------------------------------------------------------------
# Open a database server connection if one is not already open.

sub open {
    my ($class,$dbname,$user,$pass) = @_;
    defined $dbname or return undef;
    defined $user   or return undef;
    defined $pass   or return undef;

    if (defined $DBH) {$DBHCNT++;}
    else              {$DBH = DBI->connect("DBI:mysql:$dbname",$user,$pass);
		       $DBHCNT = (defined $DBH) ? 1 : 0;
		   }
    my $self = bless (\$DBH, "Fault::Dbh");
    return $self;
}

#=============================================================================
#		         INSTANCE METHODS
#=============================================================================
# Return the database handle. (I could have done $$self, but why bother?)

sub dbh {return $DBH;}

#-----------------------------------------------------------------------------
# Close the database. Once this is done this object should be considered
# *dead*.

sub close {
  my $self = shift;

  if    ($DBHCNT>1)    {$DBHCNT--;}
  elsif ($DBHCNT == 1) {$DBHCNT=0; $DBH->disconnect; $DBH=undef;}
  else	{warn ("Attempt to close an already closed dbh. Probable cause is " .
	       "a mismatch in the number of Dbh Class opens and closes.");}
  return undef;
}

#-----------------------------------------------------------------------------
# We need our own destructor so we can insure the database handle is 
# disconnected before garbage collection.

sub DESTROY {
  my $self = shift; 
  (defined $DBH) and $self->close;
  printf "\n\n**** WHY DID I CLOSE??? *****\n\n";
  return $self;
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documentation section with the 'perldoc' cmd.

=head1 NAME

 Fault::Dbh - Database Handle abstraction.

=head1 SYNOPSIS

 use Fault::Dbh;
        Fault::Dbh->init;
 $db  = Fault::Dbh->open ($db, $usr, $pass);
 $dbh = $db->dbh;
 $db->close;

=head1 Description

The Fault::Dbh Database handle abstraction centralizes the creation and 
destruction of a database handle for a connection to the database server. I
do this to minimize the number of active socket connections to the database
server. I have observed situations in which all available processes have been
utilized, causing further access attempts to fail.

This is currently only coded to function on a single local MySQL database. If
multiple databases are required, I will have to get fancier, perhaps a local
hash of database names with handles attached.

The init method is supplied for use in forked environments. Since only a 
single database connection is created by open, no matter how many times
you call it, you will get into very deep trouble if you open then fork and 
access the database from both processes. If you fork, use the init method
as one of the first things you do in your child process. If you do not do 
this, do not come crying to me about the really weird random error messages
and connection closures you are getting from your database.

If I wanted to, I could subclass the DBI::db handle itself, but I did not
study enough of it to make sure I did not step on anything,

Error handling is currently minimal; virtually anything that goes wrong will
cause the return of a pointer with a value of undef.

=head1 Examples

 use Fault::Dbh;
        Fault::Dbh->init;
 $db  = Fault::Dbh->open ("mydatabase","me","apassword");
 $dbh = $db->dbh;
 $db->close;

=head1 Class Variables (Internal)

 DBH            the database handle or undef
 DBHCNT         number of opens on this handle, zero if closed.

=head1 Instance Variables

None.

=head1 Class Methods

=over 4

=item B<Fault::Dbh-E<gt>init>

Initialize the local database handles. This discards any handle which was 
previously opened. We need this because if we fork a process the old handle 
gets shared among parent and child processes and if any two attempt to 
communicate with the db at the same time... 

If you are only working with a single process, you only need to use open and 
close. If you fork, you should init as one of the very first things you do 
in the new process.

=item B<$dbh = Fault::Dbh-E<gt>open ($db, $usr, $pass)>

Class method to create a new object to handle a connection to the local 
database  server for $db  as user $usr with password $pass. It only supports 
one localhost database at present. A new connection is opened only if the 
count of open connections is zero; otherwise it re-uses the currently open 
one.

It returns undef if it fails to make the requested connection.

=back 4

=head1 Instance Methods

=over 4

=item B<$dbh = $db-E<gt>dbh>

Return the database handle.

=item B<$db-E<gt>close>

Close this connection to the database server. It decrements the count of open
connections and does the real disconnect if the count reaches zero.

=back 4

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 DBI

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Dbh.pm,v $
# Revision 1.5  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.4  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.3  2008-05-07 17:44:17  amon
# Documentation changes; removed use of package DMA::
#
# Revision 1.2  2008-05-04 14:34:12  amon
# Tidied up code and docs.
#
# Revision 1.1.1.1  2008-04-18 12:44:03  amon
# Fault and Log System. Pared off of DMA base lib.
#
# Revision 1.6  2008-04-18 12:44:03  amon
# Added arg checking and bail out to open method.
#
# Revision 1.5  2008-04-11 22:25:23  amon
# Add blank line after cut.
#
# Revision 1.4  2008-04-11 18:56:35  amon
# Fixed quoting problem with formfeeds.
#
# Revision 1.3  2008-04-11 18:39:15  amon
# Implimented new standard for headers and trailers.
#
# Revision 1.2  2008-04-10 15:01:08  amon
# Added license to headers, removed claim that the documentation section still
# relates to the old doc file.
#
# Revision 1.1.1.1  2004-12-02 14:28:14  amon
# Dale's library of primitives in Perl
#
# 20041128	Dale Amon <amon@vnl.com>
#		Added init method to handle multiprocessing problems.
#
# Revision 1.1  2001/05/23 17:05:40  amon
# Added Dbh
#
# 20010515      Dale Amon <amon@vnl.com>
#               Created
1;
