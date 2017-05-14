#!/usr/bin/perl

=head1 NAME

EasyDB::Query - EasyDB query routines

=head1 SYNOPSIS

This file is used by EasyDB.

=head1 DESCRIPTION

Provides SELECT query functionality for the EasyDB package.

=cut

package EasyDB::Query::Select;
require EasyDB::Util;

use strict;
use Carp;

my $debug		= 0;

=head1 CONSTRUCTOR

Takes as it's parameters a DBI database handle.  Will return a
SELECT query object.

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

This function defines what data you want to find in the given
table.  The language is partly functional and partly SQL based.  You start
by expressing what you want to find:

   Find all people with names that have an 'a' in, who are 
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
    Height is like '%'

Now we need to convert this into our criteria hash.  This step
is quite simple once you've got the functional section:

    $easydb->find->criteria(
                            Name   => '%a',
                            Age    => ['> 21', '< 28'],
                            Eyes   => '! blue',
                            Height => '%',
                            );

Note that we can have more than one criteria for Age.  Simply
put the list into an array by enclosing it in square brackets.

=head2 IMPORTANT

B<If you want to get a particular bit of data then you must specify
it with a % sign in the criteria.  See the Height field above.  
We do not care what the height is but we want to get that data anyway
so we say that it can be 'anything', or '%'.  This makes sure that that
bit of data comes back in the results.>

=cut
sub criteria {
	my $self		= shift;
	my %criteria	= @_;	

	# Simply build our where criteria
	$self->{_SQL_WHERE}	= EasyDB::Util::build_where( \%criteria );
	
	# No table, no go.
	unless ( $self->{TABLE} ) { 
		_debug(1, "No table selected to query");
		croak "There is no table chosen";
		}			

	my $table	= $self->{TABLE};		
	my $text	= "SELECT ";
			
	# If we had no criteria, then we say select *
	# However we need to pull in the column names
	# from the DB somehow.
	unless ( %criteria ) { 
		$text = 'SELECT *'; 
		}
	# Now we just iterate the columns
	else {
		$self->{_COLUMNS}	= [];
		for ( sort keys (%criteria) ) {
			_debug(4, "Added $_ to col list");
			$text	.= "$_, ";
			push( @{ $self->{_COLUMNS} }, $_);
			}
		
		$text		=~ s/\,\s$//;
		}

	$text	.= " FROM " . $table;		
	$self->{_SQL_MAIN}	= $text;
		
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
	return EasyDB::Util::count_rows($self->{_DBH}, $self->{TABLE}, $self->{_SQL_WHERE});
	}

=head2 as_array ( )

Will return the results of the query as a reference to an array.  
Each element of the array will contain a reference to a hash
that contains one row of the query, with the keys of the hash
being the individual search fields.  To print out all the 
results from a query in rows:

    # Get the result into an array
    my $ref    = $easydb->find->as_array();
    my @array  = @{ $ref };

	# For each result row returned
	for ( @array ) { 
	
        # Make it a proper hash
        my %row = %{ $_ };

        # Print out in rows
        for $item ( sort keys %row ) { 
            print $row{$item} . "\t";
            }
        print "\n";
        }	
    }

You will only be able use this function if you have defined
some search criteria using the B<criteria> function and have
selected a table using the table function.

=cut
sub as_array {

	my $self	 		= shift;
	
	_debug(5, "Retrieving results as array");

	unless ( $self->{TABLE} ) { 
		debug(1, "No table selected");
		carp "You have not selected a table";
		return 0;
		}		

	unless ( defined($self->{_SQL_WHERE}) ) {
		debug(1, "No working criteria given");
		carp "You have not specified any criteria";
		return 0;
		}
		
	my $ref	= &_do_select_query($self, 'ARRAY');
	return $ref;
	}

=head2 as_hash ( )

This function is only available for find queries.

Will return the results of the query as a reference to a hash.  
Each key of the hash is a reference to an array storing the 
rows of the results from the query.  This query is best used 
with the how_many function.  To print out all the results from 
the query in nice rows:

    # Get the result into a hash
    my $ref  = $easydb->find->as_hash();
    my %hash = %{ $ref };
    
    # Get the number of rows returned 
    my $count = $easydb->find->how_many();
    
    # Counting from 0 to $count
    for ( my $i = 0 ; $i < $count ; $i ++ ) {

        # For each key in the hash print out
        # the i'th item
        foreach $item ( sort keys %hash ) { 
            print $hash{$item}[$i];
            }
        print "\n";
        }

You will only be able use this function if you have defined
some search criteria using the B<criteria> function and have
selected a table using the table function.

=cut
sub as_hash {
	my $self	 		= shift;
	
	_debug(5, "Retrieving results as hash");
			
	unless ( $self->{TABLE} ) { 
		debug(1, "No table selected");
		carp "You have not selected a table";
		return 0;
		}		

	unless ( defined($self->{_SQL_WHERE}) ) {
		debug(1, "No working criteria given");
		carp "You have not specified any criteria";
		return 0;
		}
	
	my $ref	= &_do_select_query($self, 'HASH');
	return $ref;
	}


=head1 INTERNAL FUNCTIONS

=head2 _do_select_query ( $self object )

This function will, when given a valid query object, extract
and execute the SQL statement.  This function is only called by
the SELECT query object.

=cut
sub _do_select_query {

	my $self	= shift;
	my $type	= shift;
		
	_debug(3, "Running SELECT query");	
		
	my $dbh		= $self->{_DBH};
	my $sql		= $self->{_SQL_MAIN} . " " . $self->{_SQL_WHERE};
	my $table	= $self->{TABLE};

	my $ref		= $dbh->selectall_arrayref($sql) 
				  or die "SQL error: " . $dbh->errstr(), "SQL was:\n$sql";
	my @result	= @{ $ref };
		
	unless ( scalar(@result) ) { 
		return 0;
		}

	_debug(4, "Found some rows");

	# Copy the references to the stored hash and array		
	my %hr;
	my @ar;
	
	for ( @result ) { 

		_debug(4, "Dealing with a new row");
	
		my $i	= 0;
		my %rec;
		my $field;
		
		for $field ( @{ $self->{_COLUMNS} } ) {
			my $value	= @{$_}[$i];
			push( @{ $hr{$field} }, $value );
			$rec{$field}	= $value;
			_debug(5, "Column $i, Item '$field', value is '$value'");
			$i++;
			}
		push(@ar, \%rec);
		_debug(5, "New ar record added");
		}

	# Make the lists in the hash be references
	# instead of actual lists.  This allows the

		
	_debug(5, "Array '" . \@ar . "':", @ar, "Hash '" . \%hr . "':", %hr);

	# Send back the correct type
	if ( $type =~ m/ARRAY/i ) { return \@ar; }
	elsif ( $type =~ m/HASH/i ) { return \%hr; }
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

Does not currently support:

    SELECT *

type queries.  Relies on there actually being some column names supplied
or it will have problems generating the hashes.

=head1 KNOWN BUGS

I'll have to get back to you on that one

=head1 SEE ALSO

EasyDB
EasyDB::Query::Insert
EasyDB::Query::Update
EasyDB::Query::Delete
EasyDB::Query::Select

=head1 ABOUT

This is part of Gaby Vanhegan's third year project for
the University Of Leeds.

=head1 AUTHOR

Gaby Vanhegan <gaby@vanhegan.com>

=cut

1;