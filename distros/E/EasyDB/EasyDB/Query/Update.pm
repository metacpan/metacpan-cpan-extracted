#!/usr/bin/perl

=head1 NAME

EasyDB::Query::Update - EasyDB UPDATE query routines

=head1 SYNOPSIS

This file is used by EasyDB.

=head1 DESCRIPTION

Provides UPDATE functionality for the EasyDB packge.

=cut

package EasyDB::Query::Update;

use EasyDB::Util qw(sql);

use strict;
use Carp;

my $debug		= 0;

=head1 CONSTRUCTOR

Takes as it's parameters a DBI database handle.  Will return a
UPDATE query object.

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
			
	# Internal variable storage space
	$self->{SQL}			= undef;
	$self->{_SQL_WHERE}		= undef;
	$self->{_SQL_MAIN}		= undef;
	$self->{_COLUMNS}		= [];
	
	# How many rows did we change?
	$self->{_ROWS}			= 0;
	
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

This function defines what data you want to change in the given
table.  The language is partly functional and partly SQL based.  You start
by expressing what you want to changte:

   Change all people with names that have an 'a' in, who are 
   between 21 and 28 but don't have blue eyes.

We then break this down a little more into some basic facts that 
we want to know:

   Name must have an 'a' in it
   Age must be greater then 21
   Age must be less than 28
   Eyes must not be blue
   
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
    
For the final step we need to use the wildcard, '%'.  The wildcard
means 'anything', that is anything can replace the wildcard.
If we had the words 'ball', 'bat', 'bag', and 'hag', we can say:

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

Now we need to convert this into our criteria hash.  This step
is quite simple once you've got the functional section:

    $easydb->change->criteria(
                            Name   => '%a',
                            Age    => ['> 21', '< 28'],
                            Eyes   => '! blue',
                            );

Note that we can have more than one criteria for Age.  Simply
put the list into an array by enclosing it in square brackets.

=cut
sub criteria {
	my $self		= shift;
	my %criteria	= @_;	

	$self->{_ROWS}	= 0;

	# Simply build our where criteria
	$self->{_SQL_WHERE}	= EasyDB::Util::build_where( \%criteria );
		
	return;
	}

=head2 sql ( )

This function will either return the current SQL string, if one has
been generated, or nothing if there is no SQL statment stored.

    my $string	= $easyDB->find->sql();

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

    my $rows	= $easyDB->find->how_many();

For more information view the EasyDB::Util documentation.

=cut

sub how_many {
	my $self	= shift;
	return EasyDB::Util::count_rows($self->{_DBH}, $self->{TABLE}, $self->{_SQL_WHERE})
	unless $self->{_ROWS};
	return $self->{_ROWS};
	}

=head2 to ( hash of new values ) 

This function will allow you to change the values of some data in the
database.  Firstly you must select a table and which records you want to
alter.  This is done using table() and criteria() :

    $easyDB->change->table('table1');
    $easyDB->change->criteria(Eyes => 'b%',
                              Age  => '> 26' );
                              
The above statement will only change entries in table 1 where 
'Eyes' has a 'b' at the start and the age is greater than 26.

You then specify what you want to change this information to, using the
to() function:

    $easyDB->change->to( Age    => 'unknown',
                         Status => 'single' );
                         
The information has then been updated.

=cut
sub to {
	my $self	= shift;
	
	unless ( $self->{TABLE} ) { 
		debug(1, "No table selected");
		carp "You have not selected a table";
		return 0;
		}		

	unless ( $self->{_SQL_WHERE} ) {
		debug(1, "No working criteria given");
		carp "You have not specified any criteria";
		return 0;
		}

	# Check we have vars
	unless ( @_ ) { 
		debug(1, "No new values given");
		croak "You have not specified what to change the values to";
		return 0;
		}
	
	my $table	= $self->{TABLE};
		
	my $sql		= "UPDATE $table SET ";
	my %vars	= @_;
	
	for ( sort keys (%vars) ) { 
		my $var	= $_;
		my $val	= $vars{$_};
		$sql	.= "$var\='$val', ";
		}
		
	# Chop off the extraneous ', '
	$sql		=~ s/\,\s$//;	
	$self->{_SQL_MAIN}	= $sql;	
	
	my $rv		= &_do_update_query($self);

	# What do we return?Whatever came from exec_update
	return $rv;
	}

=head1 INTERNAL FUNCTIONS

=head2 _do_update_query	( $self object )

Function to execute an UPDATE query.  This is only ever called 
by the UPDATE query type.

=cut
sub _do_update_query {

	# Load in our variables
	my $self		= shift;
	my $dbh			= $self->{_DBH};
	my $table		= $self->{TABLE};
	my $sql			= $self->{_SQL_MAIN} . " " . $self->{_SQL_WHERE};
	
	# Execute the query or fall over safely
	my $rv			= $dbh->do($sql) 
					  or die "SQL Error:" . $dbh->errstr() . "\nSQL was:\n$sql";
	$self->{_ROWS}	= $rv;
	# If we get back 0 rows, then that returns as 0E0, which
	# we then change to 0 for the user
	if ( $rv =~ m/^0E0/i or $rv < 0 ) { 
		$rv	= 0;
		}

	# Fly away home...
	return $rv;
	}	

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