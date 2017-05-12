#! perl

# SQLEngine.pm -- Execute SQL commands
# Author          : Johan Vromans
# Created On      : Wed Sep 28 20:45:55 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jun 19 00:47:09 2010
# Update Count    : 72
# Status          : Unknown, Use with caution!

package EB::Tools::SQLEngine;

use strict;
use warnings;

use EB;

sub new {
    my ($class, @args) = @_;
    $class = ref($class) || $class;
    bless { _cb => {}, @args } => $class;
}

sub callback($%) {
    my ($self, %vec) = @_;
    return unless %vec;
    while ( my($k,$v) = each(%vec) ) {
	$self->{_cb}->{$k} = $v;
    }
}

# Basic SQL processor. Not very advanced, but does the job.
# Note that COPY status will not work across different \i providers.
# COPY status need to be terminated on the same level it was started.

sub process {
    my ($self, $cmd, $copy) = (@_, 0);
    my $sql = "";
    my $dbh = $self->{dbh} || $::dbh;

    # If we have PostgreSQL and it is of a suitable version, we can use
    # fast loading.
    my $pgcopy = $dbh->feature("pgcopy");

    # Filter SQL, if needed.
    my $filter = $dbh->feature("filter");

    # Remember type
    my $type = $dbh->driverdb;

    # Use raw handle from here.
    $dbh = $dbh->dbh;

    my $skipthis;
    foreach my $line ( split(/\n/, $cmd) ) {

	# Detect \i provider (include).
	if ( $line =~ /^\\i\s+(.*).sql/ ) {
	    my $call = $self->{_cb}->{$1};
	    die("?".__x("SQLEngine: No callback for {cb}",
			cb => $1)."\n") unless $call;
	    $self->process($call->(), $copy);
	    next;
	}

	# Handle COPY status.
	if ( $copy ) {
	    if ( $line eq "\\." ) {
		# End COPY.
		$dbh->pg_endcopy if $pgcopy;
		$copy = 0;
	    }
	    elsif ( $pgcopy ) {
		# Use PostgreSQL fast load.
		$dbh->pg_putline($line."\n");
	    }
	    else {
		# Use portable INSERT.
		my @args = map { $_ eq 't' ? 1 :
				   $_ eq 'f' ? 0 :
				     $_ eq '\\N' ? undef :
				       $_
				   } split(/\t/, $line);
		my $s = $copy;
		my @a = map {
		    !defined($_) ? "NULL" :
		      /^[0-9]+$/ ? $_ : $dbh->quote($_)
		  } @args;
		$s =~ s/\?/shift(@a)/eg;
		$copy = $filter->($copy) if $filter;
		my $sth = $dbh->prepare($copy);
		$sth->execute(@args);
		$sth->finish;
	    }
	    next;
	}

	if ( $line =~ /^-- SKIP:\s*(\S+)/ ) {
	    $skipthis = lc($1) eq lc($type);
	}
	elsif ( $line =~ /^-- ONLY:\s*(\S+)/ ) {
	    $skipthis = lc($1) ne lc($type);
	}

	# Ordinary lines.
	# Strip comments.
	$line =~ s/--.*$//m;
	# Ignore empty lines.
	next unless $line =~ /\S/;
	# Trim whitespace.
	$line =~ s/\s+/ /g;
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;
	# Append to command string.
	$sql .= $line . " ";

	# Execute if trailing ;
	if ( $line =~ /.+;$/ ) {
	    if ( $skipthis ) {
		warn("++ SKIPPED:: $sql\n") if $self->{trace};
		$skipthis = 0;
		$sql = "";
		next;
	    }

	    # Check for COPY/
	    if ( $sql =~ /^copy\s(\S+)\s+(\([^\051]+\))/i ) {
		if ( $pgcopy ) {
		    # Use PostgreSQL fast load.
		    $copy = 1;
		}
		else {
		    # Prepare SQL statement.
		    $copy = "INSERT INTO $1 $2 VALUES (" .
		      join(",", map { "?" } split(/,/, $2)) . ")";
		    $sql = "";
		    next;
		}
	    }

	    # Postprocessing.
	    $sql = $filter->($sql) if $filter;
	    next unless $sql;

	    # Intercept transaction commands. Must be handled by DBI calls.
	    if ( $sql =~ /^begin\b/i ) {
		warn("++ INTERCEPTED:: $sql\n") if $self->{trace};
		$dbh->begin_work if $dbh->{AutoCommit};
	    }
	    elsif ( $sql =~ /^commit\b/i ) {
		warn("++ INTERCEPTED: $sql\n") if $self->{trace};
		$dbh->commit;
	    }
	    elsif ( $sql =~ /^rollback\b/i ) {
		warn("++ INTERCEPTED: $sql\n") if $self->{trace};
		$dbh->rollback;
	    }
	    else {
		# Execute.
		warn("++ $sql\n") if $self->{trace};
		$dbh->do($sql);
	    }
	    $sql = "";
	}
    }

    die("?".__x("Incomplete SQL opdracht: {sql}", sql => $sql)."\n") if $sql;
}

1;
