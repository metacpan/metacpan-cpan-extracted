#!/usr/bin/perl

=head1 NAME

EasyDB::Query::Insert - EasyDB INSERT query routines

=head1 SYNOPSIS

This file is used by EasyDB.

=head1 DESCRIPTION

Provides INSERT functionality for the EasyDB package.

=cut

package EasyDB::Query::Insert;
use EasyDB::Util qw(sql);
use strict;
use Carp;

my $debug		= 0;

=head1 CONSTRUCTOR

Takes as it's parameters a DBI database handle.  Will return an
INSERT query object.

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
			
	# Some storage variables
	$self->{SQL}			= undef;
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

    $easyDB->add->table('table1');

If you have changed the table then the new table is returned.

=cut
sub table {
	my $self		= shift;	
	my $table		= shift;
	
	if ( $table ) {	$self->{TABLE} = $table; }
	return $self->{TABLE};
	}

=head2 sql ( )

This function will either return the current SQL string, if one has
been generated, or nothing if there is no SQL statment stored.

    my $string	= $easyDB->add->sql();

string now holds the SQL statement.

=cut
sub sql {
	my $self	= shift;
	my $sql		= "";
	if ( $self->{_SQL_MAIN} ) { 
		$sql		= $self->{_SQL_MAIN};
		}
	return $sql;
	}
	
=head2 data ( hash of data values )

This function is used to insert data into the database.  You pass it a
hash of data, in the same format as that used for criteria().  If then
converta that into the correct SQL and runs it against the database.

	$easyDB->add->table('table1');
    $easyDB->add->data( Name   => 'Iris', 
                        Age    => '23',
                        Height => '150' );

It will return 1 or 0 depending on the success of the INSERT query.

=cut
sub data {	

	my $self	= shift;
	
	my %values	= @_;
	
	# We really need some values.
	unless ( %values ) { 
		my $msg	= "No values specified.  Can't add nothing to database";
		_debug(1, $msg);
		carp $msg;
		return 0;
		}
	
	my $table	= $self->{TABLE};
	
	# We also really need a table
	unless ( $table ) { 
		my $msg	= "No table specified.  Must have a table to add to";
		_debug(1, $msg);
		carp $msg;
		return 0;
		}		
	
	# Build value and variable lists to go in the query.
	# It's set out below so you can see where they go.
	my ($vars, $vals);
	for ( sort keys %values ) { 
		$vars	.= "$_, ";
		$vals	.= "'" . $values{$_} . "', ";
		}
	
	# Chop off the unwanted bits at the end
	for ($vars, $vals) { $_  =~ s/\,\s$//; }
	
	# Feed in these.  There are no WHERE clauses
	# for in INSERT statement
	$self->{_SQL_MAIN}	= "INSERT INTO $table ($vars) VALUES ($vals)";

	return &_do_insert_query($self)
	}

=head2 _do_insert_query	( $self object )

Function to execute an INSERT statement.  This function is only
ever called by the INSERT query object.

=cut
sub _do_insert_query {

	# Load in our variables
	my $self	= shift;
	my $dbh		= $self->{_DBH};

	# No SQL, no go.
	my $sql		= $self->{_SQL_MAIN};
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