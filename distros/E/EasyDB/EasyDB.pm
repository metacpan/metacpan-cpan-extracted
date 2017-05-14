#!/usr/bin/perl -w

# Parent class for EasyDB
package EasyDB;

# These modules we need for normal operation
use DBI;
use DBD::mysql;
use strict;
use Carp;

# Reauire our query types in here
require EasyDB::Query::Select;
require EasyDB::Query::Insert;
require EasyDB::Query::Update;
require EasyDB::Query::Delete;

# We're using our own delete function...
use subs 'delete';

# Package global constant
my $debug		= 0;

# Object constructor
# 
# In:			- Valid username, password, host, DBD driver and DB name
# Out:			- The new EasyDB object
sub new 
	{
	
	# FInd out what we actually are
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	# Read in our variables
	my ($user, $pass, $host, $db)	= (@_);
	unless ( $db and $user and $host) { 
		carp "Must supply database name, username, host and driver module name";
		_debug(1, "Not enough parameters supplied to create new object");
		return 0;
		}

	# Our hash construction to hold this objects methods
	my $self	= {};
	
	# This string is the DSN, needed to connect to the databse
	my $dsn			= "DBI\:mysql\:$db\:$host";
	
	# And here we actually connect, or die if not.
	$self->{_DBH}	= DBI->connect($dsn, $user, $pass) 
					  or die "Can't connect to database on $host:" . DBI->errstr();	
					  
	# Line up our four query types
	$self->{FIND}	= EasyDB::Query::Select->new( $self->{_DBH} );
	$self->{ADD}	= EasyDB::Query::Insert->new( $self->{_DBH} );
	$self->{CHANGE}	= EasyDB::Query::Update->new( $self->{_DBH} );
	$self->{DELETE}	= EasyDB::Query::Delete->new( $self->{_DBH} );
		
	# Return the new object
	return bless ($self, $class);
	}

# DESTROY		- Class destructor
# 
# In:			- Nothing
# Out:			- Nothing
#
# This function will ensure that the database
# handle is closed properly and everything goes
# away nicely.
sub DESTROY 
	{
	my $self	= shift;

	my $dbh		= $self->{_DBH};
	$dbh->disconnect();
	
	_debug{1, "Database handle closed"};
	}

# debug			- Sets the debugging level
# 
# In:			- [ Debug level ]
# Out:			- Debug level
#
# Function to set the current debug level.  The current 
# debugging level is returned
sub debug
	{
	# Set our debugging level for this object
	my $self	= shift;
	if ( @_ ) { $debug = shift; }
	_debug(4, "Debug set to $debug");
	
	# We'd better set it for the child objects
	# as well, so we can get some good reporting.
	$self->find->debug($debug);
	$self->add->debug($debug);
	$self->change->debug($debug);
	$self->delete->debug($debug);
	
	# Send back the current debug level
	return $debug;
	}
	
# _debug		- Internal debug reporting
# 
# In:			- Debug priority, debug message
# Out:			- Nothing
#
# Will print to screen the message given if the debugging
# level supplied is greater or equal to the current debug
# level.
sub _debug 
	{
	# Who sent us this function?
	my @list	= caller(1);
	my $func	= $list[3];
	
	my $level		= shift;
	if ($debug >= $level) { for (@_) { print "$func: $_\n"; } } 
	}
	
# find			- Function to access the SELECT query
# 					
# In:			- Nothing
# Out:			- The SELECT query object
sub find 
	{
	_debug(5, "Accessing SELECT query object");
	my $self	= shift;
	return $self->{FIND};
	}
	
# add			- Function to access the INSERT query
# 					
# In:			- Nothing
# Out:			- The INSERT query object	
sub add 
	{
	_debug(5, "Accessing INSERT query object");
	my $self	= shift;
	return $self->{ADD};	
	}
	
# change		- Function to access the UPDATE query
# 					
# In:			- Nothing
# Out:			- The UPDATE query object
sub change 
	{
	_debug(5, "Accessing UPDATE query object");
	my $self	= shift;
	return $self->{CHANGE};	
	}
	
# delete		- Function to access the DELETE query
# 					
# In:			- Nothing
# Out:			- The DELETE query object
sub delete 
	{	
	_debug(5, "Accessing DELETE query object");
	my $self	= shift;
	return $self->{DELETE};	
	}

# error			- Function to return the last error code raised
#				  by the DBH
#
# In:			- Nothing
# Out:			- The error code
sub error {
	my $self	= shift;
	my $dbh		= $self->{_DBH};
	return $dbh->errstr();
	}

=pod

=head1 NAME

EasyDB - Access a database without writing SQL

=head1 SYNOPSIS

    use EasyDB;

    # Connect to the database
    my $db	= new EasyDB ($user, $pass, $host, $database);

    # Find some data
    $db->find->table('table1');
    $db->find->criteria(  
                        Age  => '< 25',
                        Eyes => '!= Blue'
                       );

    # Get the data in two forms
    my %results_hash  = %{ $db->find->as_hash()  };
    my @results_array = @{ $db->find->as_array() };

    # Changing data
    $db->change->table('table1');
    $db->change->criteria( Age => '<= 20' );
    $db->change->to( Young => 'Yes' );

    # Adding data
    $db->add->table('table1');
    $db->add->data( 
                    Name   => 'Gaby',
                    Age    => '22',
                    Height => '165' 
                  );
                
    # Deleting data
    $db->delete->table('table1');
    $db->delete->criteria( Name => 'a%' );
    
    print "Removing " . $db->delete->how_many() . "records\n";
    
    $db->delete->now();                

=head1 DESCRIPTION

EasyDB is a Perl module that allows users with no experience of SQL to 
use a database within their application.  It provides a simpler
interface to the database that does not involve the use of SQL in 
any way.

The only requirements are that the database is a mySQL database 
and the modules DBI and DBD::mysql are installed on this machine.

=head1 BASIC USAGE

There are 4 steps to fetching some data:

1. Create a new EasyDB object that is connected to the database.  You need
   to supply a username and password.  You also need to say which machine
   the database is located on and what the name of the database is:

    use EasyDB;
    my $db     = new EasyDB($user, $pass, $host, $database)
                 or die "Can't connect: " . DBI->errstr();

2. Choose a table

    $db->find->table('table1');

3. Select what data you want to find using the criteria.  For more
   information read the section B<Using The Criteria>

    $db->find->criteria( Age  => '21',
                         Name => '%al% );

4. Fetch the data in either a hash of arrays or an array of hashes.

    my %hash  = %{ $db->find->as_hash()  };
    my @array = @{ $db->find->as_array() };

=head1 WHAT CAN I DO WITH THIS?

You can do a number of things:

=over 4

=item *

Retrieve data from the table

=item *

Change data in the table

=item *

Add data to the table

=item *

Delete data from the table

=back

=head1 CHOOSING A TABLE

The first thing that you have to do before you can go any further
is to choose which table you are going to work with.  Choosing a 
table is simply a matter of specifiying which table you want
to work with:

    $db->find->table('table1');

Or to choose the table to delete/change/add to:

    $db->delete->table('table1');
    $db->change->table('table1');
    $db->add->table('table1');

=head1 USING THE CRITERIA

The next step is to say which specific data in the table you want
to work with.  This is called setting the criteria.  If we only wanted
to work with rows where 'AGE' is less than 25 then we would specify
the criteria as:

    $db->find->criteria( Age  => '< 25' );

The criteria function narrows down the data in the table to those
matching the criteria.  In this case you will only be working with
data where Age is less than 25.  There are other possible uses for
the criteria function:

The language that you express the criteria in is partly functional
and partly SQL based.  You start by expressing what you want to find:

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
   =     Is equal to
   !     Is not

Some of these can be combined as well:

   <=    Less than or equal to
   >=    Greater than or equal to
   !=    Not equal to

We now re-write out facts using the functional symbols above:

    Name must have an 'a' in it
    Age > 21
    Age < 28
    Eyes ! 'blue'
    Any height

For the final step we need to use the wildcard, '%'.  The wildcard
means 'anything'.  It could represent a single letter or a string 
of numbers.  For example, If we had the words:

    ball
    bat
    bag
    hag

We can say:

    Word has 'll' at the end
    Word is like '%ll'
    (This would give us 'ball')

    Word has 'ba' at the start
    Word is like 'ba%'
    (This would give 'ball', 'bat' and 'bag')

    Word has an 'a' in the middle
    Word is like '%a%'
    (This would give all the words)

    Any word at all
    Word is like '%'
    (This would also give all the words)

If our name has an 'a' in it then we would express this as '%a%'.
So now our set of facts looks like this:

    Name is like '%a%'
    Age > 21
    Age < 28
    Eyes ! 'blue'
    Height is like '%'

Now we put this into the criteria function.  This step
is quite simple if you've gone through the steps above:

    $easydb->find->criteria(
                            Name   => '%a%',
                            Age    => ['> 21', '< 28'],
                            Eyes   => '! blue',
                            Height => '%',
                            );

Note that we can have more than one criteria for Age.  Simply
put some square brackets around list of criteria for that fact.

=head2 EXAMPLES

    # Will give the ages of everyone
    $easydb->find->criteria(
                            Age    => '%'
                           );

    # Will give the ages of everyone over 21
    $easydb->find->criteria(
                            Age    => '> 21'
                           );


    # Will give the ages of everyone under 21
    $easydb->find->criteria(
                            Age    => '< 21'
                           );

    # Will give the names and ages of everyone not 21
    $easydb->find->criteria(
                            Age    => '!= 21',
                            Name   => '%'
                           );

    # Will give the ages of everyone between
    # 21 and 29 and who is not 25
    $easydb->find->criteria(
                            Age    => ['> 21', '< 29', '! 25']
                           );

    # Will give the names and ages of everyone over 21
    $easydb->find->criteria(
                            Age    => '> 21',
                            Name   => '%'
                           );
                           
    # Fetch the name, age and height of person with id 104
    $easydb->find->criteria(
                            Id     => '104',
                            Name   => '%',
                            Age    => '%',
                            Height => '%'
                           );

=head1 FINDING DATA

When you want to find some data in the table you use the
B<find> function.  You have to do 2 things first:

1. Choose a table

    # Choose table1 to find data in
    $asydb->find->table('table1');

2. Specify what data you want to find

    # Set the search criteria
    $easydb->find->criteria(
                            Name   => '%a%',
                            Age    => ['> 21', '< 28'],
                           );

See the section on B<Using The Criteria> for more information
on how to specify criteria.

You can then get the data back in two forms:  Hash or array.

=head2 ARRAY FORM

When you request the data as an array, using:

    my $array_ref = $easydb->find->as_array();

You are returned a reference to an array that contains all the
data that matched the criteria.  Each element in the array represents
one row found in the table.  Each element is a reference to a hash
that holds the data found, with the keys of the hash being the criteria
that you searched on.

Assume you did this:

    # Set the search criteria
    $easydb->find->table('table1');
    $easydb->find->criteria(
                            Name   => '%a%',
                            Age    => ['> 21', '< 28'],
                           );

    # Fetch in array form
    my $array_ref = $easydb->find->as_array();

    # Make the reference into a proper array
    my @array     = @{ $array_ref };

The structure of what is held in @array would look like this:

   @array[0]-----@array[1]-----@array[2]----- etc...
   |             |             |
   V             V             V
   $hashref of   $hashref of   $hashref of
   first result  next result   next result
   |             |             |-----> and so on...
   |             v
   |             %hash{NAME} = 'Andy'
   |             %hash{AGE}  = '22'
   V             
   %hash{NAME} = 'Boris'
   %hash{AGE}  = '25'

Each item is a reference to a hash that contains 1 result.  All the
keys to the hash are upppercase.  They are automatically set this way
when yo specify the criteria.

=head2 EXAMPLE

If you wanted to print out all the results from a search, you could
use code like this to do it:

    # Fetch in array form
    my $array_ref = $easydb->find->as_array();

    # Make the reference into a proper array
    my @array     = @{ $array_ref };

    # Print out all the results
    foreach $result ( @array ) { 

        # Make this result into a hash
        my %row		= %{ $result };

        # For each key in this hash
        for $key ( sort keys %row ) { 

            # Print it out
            print $key . "=" . $row{$key} . "\t";
        }
        
        # End this row
        print "\n";
    }	

=head2 HASH FORM

When you request the data as a hash, using:

    my $hash_ref = $easydb->find->as_hash();

You are given back a reference to a hash that contains all the
rows in the table that match the criteria.  The next step is to
convert this reference into a real hash:

    my %results  = %{ $hash_ref };

Assume that you have the following:

    # Set the search criteria
    $easydb->find->table('table1');
    $easydb->find->criteria(
                            Name   => '%a%',
                            Age    => ['> 21', '< 28'],
                           );

    # Get the results as a hash
    my $hash_ref = $easydb->find->as_hash();

    # Convert it to a real hash
    my %results  = %{ $hash_ref };

The %reults hash now holds data from the table that match the
criteria.  The keys of the hash are the search criteria and the
values are references to arrays that contain the actual data.  The
structure is this:

   %reults{AGE} = $array_ref, %results{NAME} = $array_ref
                  |                            |
                  V                            V
                 @array[0] = '25';            @array[0] = 'Boris'
                 @array[1] = '22';            @array[1] = 'Andy'
                 etc...                       etc...

Each value is a reference to an array.  These arrays contain the
lists of data returned.

=head2 EXAMPLE

If you wanted to print out all the values returned from a search,
you could use this code:

    # Fetch in hash form
    my $hash_ref = $easydb->find->as_hash();

    # Make the reference into a proper array
    my %hash     = %{ $hash_ref };

    # We need to know how many rows we have
    my $num	     = $db->find->how_many();

    # Print out the hashref results	
    for ( my $c = 0 ; $c < $num ; $c++ ) { 

        # For each key in our hash
        for $key ( sort keys ( %hash ) ) { 

            # Print out the row
            print $key . '=' . $hash{$key}[$c] . "\t";
            }

        # End the row
        print "\n";
        }

=head1 CHANGING DATA

Changing data is a two step process.  Firstly you specifiy what
you want to change using the criteria function:

    $easydb->change->table('table1');
    $easydb->change->criteria( Age => '> 21' );

Then you say what you want to change the data to for rows that match
the criteria:

    $easydb->change->to( CanVote => 'Yes' );

You can search on any number of criteria and change any value you want
using the B<change->to> function.  The data is only changed once you
specified what to change it to.

=head1 ADDING DATA

Adding data is simply a matter of saying what data you want to add:

    # Choose the table
    $easydb->add->table('table1');
    
    # Add some data
    $easydb->add->data( Age    => '52',
                        Name   => 'Gaby',
                        Height => '159',
                        Eyes   => 'Green' );

And the data is added.

B<WARNING> I cannot gurantee that this function will always work.  It
may fall over quite badly when you try and enter values for fields
that don't exist in the table.  Be careful.

This should hopefully be fixed in a later release.

=head1 DELETING DATA

Deleting data is a simple matter:

    # Choose a table
    $easydb->delete->table('table1');
    
    # Set the criteria
    $easydb->delete->criteria( Age => '< 18' );
    
    # Make it so
    $easydb->delete->now();

The above will remove anyone who is younger than 18 years of age.  Beware when
using this function as once data is gone, you cannot get it back.  Data is only
deleted when you call the B<delete->now()> function.  This is so you cannot
accidentally delete data, you have to call the now() function to do it.

In later versions some form of undo functionality may be built in, but this is
pure speculation at this time.

=head1 SQL

If you want to view the SQL code that the query is using to access the
database then you can use the B<sql()> function.  This function will return
the current SQL string that the query is holding:

    print "Find SQL was: "   . $easydb->find->sql()   . "\n";
    print "Change SQL was: " . $easydb->change->sql() . "\n";
    print "Add SQL was: "    . $easydb->add->sql()    . "\n";
    print "Delete SQL was: " . $easydb->delete->sql() . "\n";

You can use this as a learning aid if you want to learn SQL, although it may
be better and quicker to learn from a book.

=head1 HOW MANY

You can use the B<how_many()> function to see how many rows a particular
action is going to affect.  If you want to know how many rows of data were
found the last time you did a search on the database, you can use:

    $easydb->find->how_many();

The same functions are available for delete and change as well:

    $easydb->delete->how_many();
    $easydb->change->how_many();

There is no how_many function for adding data as you are only ever adding
one row at a time, so how_many would always return '1'.

B<NOTE>

You can only call how_many once you have set some criteria.  how_many returns
the number of rows that the current query would affect, or has affected, in the
case of update and delete queries.

=head1 CAVEATS

Unsure as to how stable the SQL parsing engine is.  I don't know its
tolerance for bad syntax.

Currently does not allow for 'SELECT *'queries to be used.  This is
becuase of the need to know what the column names are, and they are
specified with the B<criteria> function.

=head1 KNOWN BUGS

Currently know known bugs.  Please bear in mind this is a beta version.

=head1 ABOUT

This is part of Gaby Vanhegan's third year project for
the University Of Leeds.

=head1 AUTHOR

Gaby Vanhegan <gaby@vanhegan.com>

=cut

1;
