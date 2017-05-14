#!/usr/bin/perl

# Sub-class for the EasyDB module
# Provides general utility functions, such as those for building
# WHERE clauses, that every query type uses, and those for running
# stuff against the database.

package EasyDB::Util;

use Carp;

use Exporter;

@EXPORT	= qw( 	build_where
			 	count_rows
			 	sql
			);

use strict;

my $debug	= 0;

# debug			- Sets the debugging level
# 
# In:			- [ Debug level ]
# Out:			- Debug level
#
# Function to set the current debug level.  The current 
# debugging level is returned
sub debug
	{
	my $self	= shift;
	if ( @_ ) { $debug = shift; }
	_debug(4, "Debug set to $debug");
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
sub _debug {
	
	# Who sent us this function?
	my @list	= caller(1);
	my $func	= $list[3];
	# $func		=~ s/.*\://;
	
	my $level		= shift;
	if ($debug >= $level) { for (@_) { print "$func: $_\n"; } } 
	}

# build_where	- Build a WHERE clause from a given hashref
# 
# In:			- [ A hash of the criteria ]
# Out:			- Nothing
#
# Used to set the criteria for the WHERE clause
# when passed in a hash of search criteria.
#
# If using a SELECT query:
# Passing no criteria will make the query return
# all columns by using a * in the query instead of
# any field names
sub build_where {

	# Make sure we actually have vars...
	unless ( @_ ) { 
		return undef;
		}

	my $hold	= shift;

	# Read in our vars
	my %vars	= %{$hold};

	unless ( %vars ) { 
		return "";
		}

	my $sql		= "WHERE ";

	for ( sort keys (%vars) ) { 			
		my $str		= $vars{$_};
		my $type	= ref($str);
		
		# It's a list of statements
		if ( $type =~ m/^ARRAY/i ) { 
			for my $element ( @{$str} ) {
				my $bit	= _build_where($_, $element);
				if ( $bit ) { $sql .= "$bit AND "; }					
				}
			}					
			# It's a single statement
		else {
			my $bit		= _build_where($_, $str);
			if ( $bit ) { $sql .= "$bit AND "; }
			}
		}		
	
	$sql		=~ s/\sAND\s$//;
						
	return $sql;
	}
	
# _build_where	- Set the criteria for this query
# 
# In:			- A variable name, the functional argument
# Out:			- A parsed SQL WHERE clause
#
# Used internally to generate the WHERE sub-clauses
# Syntax is thus:
# 
# <				- Less than
# >				- Greater than
# <=			- Less than or equal to
# >=			- Greater than or equal to
# =				- Equal to
# !				- Not
# !=			- Not equal to
# %				- Wildcard
#
# Use of wildcards
#	The wildcard is used to pad out values that have no
#	particular criteria but need to be included in the returned
# 	results.  This is only really used for SELECT queries so they
#	get filtered out at this stage.  If there is a wildcard then
#	there is no need to include a WHERE clause for it, so it is
# 	stripped out.
#
#	When the value is more than just the wildcard then the wildcards
# 	are used and the LIKE keyword is used.  Any functional grammer is
#	then stripped out.
sub _build_where {	

	chomp(@_);
	my ($var, $val)	= @_;
		
	# Somewhere we need to check the syntax of the var/val pair
	# that we've been passed.
	
	_debug(5, "Passed: $var $val");
	
	my ($mod, $rv);
		
	# If it's got a % and greater than 1 then it is carryin
	# a wildcard.  This needs special treatment.
	if ( $val =~ m/\%/i and ( length($val) > 1 ) ) { 
		$mod	= " LIKE ";
		}
	# If it's a standard functional expression, then we will use
	# whatever we were passed instead.
	elsif ( $val =~ m/^\<\=\s.*/i ) { 
		$mod	= "<=";
		}
	elsif ( $val =~ m/^\>\=\s.*/i ) { 
		$mod	= ">=";
		}
	elsif ( $val =~ m/^\<\s.*/i ) { 
		$mod	= "<";
		}
	elsif ( $val =~ m/^\>\s.*/i ) { 
		$mod	= ">=";
		}
	# If it's a not statement, we'll have that as well
	elsif ( $val =~ m/^\!\=\s.*/i ) { 
		$mod	= ' NOT ';
		}
	elsif ( $val =~ m/^\!\s.*/i ) { 
		$mod	= '!=';
		}
	# Otherwise it's just a simple =
	else {
		$mod	= '=';
		}

	# Strip any control chars from the start
	# of our value ready for insertion into 
	# the GET_SQL statement
	$val =~ s/^>\=//i; 
	$val =~ s/^<\=//i; 
	$val =~ s/^!\=//i; 
	$val =~ s/^!//i; 
	$val =~ s/^\=//i; 
	$val =~ s/^\<//i; 
	$val =~ s/^\>//i; 
	
	# Chop off the spaces at the start
	$val =~ s/^\s+//i;

	# If the only thing in the value was a % then
	# it's simply a null variable that doesn't actually
	# need any entry in the WHERE syntax
	unless ( $val =~ m/^\%$/i ) {
		$rv		= "$var$mod'$val'";
		}

	_debug(5, "Returned where clause $rv");
	return $rv;
	}

# Function to count the number of rows this query will affect.
sub count_rows {

	my ($dbh, $table, $where) = @_;
	
	my $sql	= "SELECT * FROM $table $where";
	my $sth	= $dbh->prepare($sql); 
	          $sth->execute();
	my $rc	= $sth->rows();
	          $sth->finish();
	          
	return $rc;
	}

1;
