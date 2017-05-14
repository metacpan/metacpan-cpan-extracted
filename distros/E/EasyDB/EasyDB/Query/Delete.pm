#!/usr/bin/perl

=head1 NAME

EasyDB::Query - EasyDB query routines

=head1 SYNOPSIS

This file is used by EasyDB.

=head1 DESCRIPTION

Provides DELETE query functionality for the EasyDB package

=cut

package EasyDB::Query::Delete;

use EasyDB::Util qw(build_where sql);

use strict;
use Carp;

my $debug		= 0;

=head1 CONSTRUCTOR

Takes as it's parameters a DBI database handle.  Will return a
DELETE query object.

=cut
sub new 
	{
	
	# FInd out what we actually are
	my $proto 	= shift;
	my $class 	= ref($proto) || $proto;
	
	my $self  	= {};		

	# Now we check the DBH
	my $dbh					= shift;
	
	# Have we been given a database handle?
	$self->{_DBH}			= ( $dbh ) ? $dbh : undef ;		
			
	# Internal storage space
	$self->{SQL}			= undef;
	$self->{_SQL_WHERE}		= undef;
	$self->{_SQL_MAIN}		= undef;
	$self->{_COLUMNS}		= [];
	
	# Some SQL parameters that we need
	$self->{TABLE}			= undef;
		
	return bless ($self, $class);
	}

# DESTROY		- Class destructor
# 
# In:			- Nothing
# Out:			- Nothing
#
# This function will ensure that any open statement
# handles are closed before the connection to the 
# database is closed by the parent class
sub DESTROY {
	_debug{1, "Statement destroyed"};
	}

=head1 METHODS

=head2 debug ( [level] )

Sets the debugging level of this object.  The standard debug
level would normally be 1, and that would tell you what the program
is up to.  If you want you can go as high as 5, which spurts out
reams and reams of useless debugging information.

    $easyDB->debug('1');
   
would be sufficient.

=cut
sub debug
	{
	my $self	= shift;
	if ( @_ ) { $debug = shift; }
	_debug(4, "Debug set to $debug");
	return $debug;
	}
	
=head2 table ( [table name] )

When called with a table name this function will set the table
that the query will execute on.  Without a table name it will
return the current table it is looking at.

    $easyDB->find->table('table1');

If you have changed the table then the new table is returned.

=cut
sub table {
	my $self		= shift;	
	my $table		= shift;
	
	if ( $table ) {	$self->{TABLE} = $table; }
	return $self->{TABLE};
	}

=head2 criteria ( hash of criteria )

This function defines what data you want to delete from the given
table.  The language is partly functional and partly SQL based.  You start
by expressing what you want to delete:

   Delete all people with names that have an 'a' in, who are 
   between 21 and 28 but don't have blue eyes.  I also want 
   to know what height they are.

We then break this down a little more into some basic facts that 
we want to know:

   Name must have an 'a' in it
   Age must be greater then 21
   Age must be less than 28
   Eyes must not be blue
   They can be any height, we just want to know what it is.
   
We then convert this into some functional statements.  You should
use these symbols to convert your facts into functional facts:

   <     Less than
   >     Greater than
   =     Equal to
   !     Is Not
   
Some of these can be combined as well:

   <=    Less than or equal to
   >=    Greater than or equal to
   
We now re-write out facts like this:

    Name must have an 'a' in it
    Age > 21
    Age < 28
    Eyes ! 'blue'
    Any height
    
For the final step we need to use the wildcard, '%'.  The wildcard
means 'anything'.  It could represent a single letter or a string 
of numbers.  If we had the words 'ball', 'bat', 'bag', and 'hag', 
we can say:

    Word has 'll' at the end
    Word is like '%ll'
    (This would return 'ball')

    Word has 'ba' at the start
    Word is like 'ba%'
    (This would return 'ball', 'bat' and 'bag')

    Word has an 'a' in the middle
    Word is like '%a%'
    (This would return all the words)

    Any word at all
    Word is like '%'
    (This would also return all the words)
	
So now our set of facts would look like:

    Name is like '%a'
    Age > 21
    Age < 28
    Eyes ! 'blue'
    Height is like '%'

Now we need to convert this into our criteria hash.  This step
is quite simple once you've got the functional section:

    $easydb->delete->criteria(
                            Name   => '%a',
                            Age    => ['> 21', '< 28'],
                            Eyes   => '! blue',
                            Height => '%',
                            );

Note that we can have more than one criteria for Age.  Simply
put the list into an array by enclosing it in square brackets.

=cut
sub criteria {
	my $self		= shift;
	my %criteria	= @_;	

	
	# No table, no go.
	unless ( $self->{TABLE} ) { 
		_debug(1, "No table selected to query");
		croak "There is no table chosen";
		}			

	# Simply build our where criteria
	$self->{_SQL_MAIN}	= "DELETE FROM " . $self->{TABLE};
	$self->{_SQL_WHERE}	= EasyDB::Util::build_where( \%criteria );
	
	return;
	}

=head2 sql ( )

This function will either return the current SQL string, if one has
been generated, or nothing if there is no SQL statment stored.

    my $string	= $easyDB->delete->sql();

string now holds the SQL statement.

=cut
sub sql {
	my $self	= shift;
	my $sql		= "";
	if ( $self->{_SQL_MAIN} and  $self->{_SQL_WHERE} ) { 
		$sql		= $self->{_SQL_MAIN} . " " . $self->{_SQL_WHERE};
		}
	return $sql;
	}

=head2 how_many ( )

Function to return the number of records fetched.  Calls a utility
function in EasyDB::Util to count the number of records that are
affected by the query.

    my $rows	= $easyDB->delete->how_many();

For more information view the EasyDB::Util documentation.

=cut

sub how_many {
	my $self	= shift;
	return EasyDB::Util::count_rows($self->{_DBH}, $self->{TABLE}, $self->{_SQL_WHERE});
	}
	
=head2 now ( )

Function to confirm the deletion of some records.  Firstly you must have
set some criteria using:

    $easyDB->delete->table('table1');
    $easyDB->delete->criteria( ... );
    
Provided you have set a table as well, you can then confirm the delete of
the date using the now() function:

    $easyDB->delete->now();
    
The data has gone and 0 rows will be returned.

=cut
sub now {

	# Load in our variables
	my $self	= shift;
	my $dbh		= $self->{_DBH};

	my $sql		= $self->{_SQL_MAIN} . " " . $self->{_SQL_WHERE};
	
	# No SQL, no go.
	unless ( $sql ) { 
		my $msg	= "No SQL defined.  Can't run a query that doesn't exist";
		_debug(1, $msg);
		carp($msg);
		return 0;
		}		

	# Problems everywhere... we need a table to run properly
	my $table	= $self->{TABLE};
	unless ( $table ) { 
		my $msg	= "No table selected.  Can't run a query without a table";
		_debug(1, $msg);
		carp($msg);
		return 0;
		}	
		
	# Execute the query or fall over safely
	my $rv		= $dbh->do($sql) or die "SQL Error:" . $dbh->errstr() . "\nSQL was:\n$sql";
	my $count	= $dbh->rows();

	# If we get back 0 rows, then that returns as 0E0, which
	# we then change to 0 for the user
	if ( $rv =~ m/^0E0/i or $rv < 0 ) { 
		$rv	= 0;
		}
		
	# Fly away home...
	return $rv;
	}		

=head1 Internal Functions

=head2 _debug ( error level, debug message[s] )

Internal function used to report error messages.  When you specify
the level of this message it is checked against the current 
debug level.  If the debug level is equal or greater than the level
of this message, it is displayed.

=cut
sub _debug {
	
	# Who sent us this function?
	my @list	= caller(1);
	my $func	= $list[3];	
	my $level		= shift;
	if ($debug >= $level) { for (@_) { print "$func: $_\n"; } } 
	}

=head1 CAVEATS

Unsure as to how stable the SQL parsing engine is.  I don't know its
tolerance for bad syntax.

=head1 KNOWN BUGS

I'll have to get back to you on that one

=head1 SEE ALSO

EasyDB

=head1 ABOUT

This is part of Gaby Vanhegan's third year project for
the University Of Leeds.

=head1 AUTHOR

Gaby Vanhegan <gaby@vanhegan.com>

=cut

1;