package Hypatia::DBI;
{
  $Hypatia::DBI::VERSION = '0.029';
}
use strict;
use warnings;
use Moose;
use DBI;
use Scalar::Util qw(blessed);
use namespace::autoclean;



has 'dsn'=>(isa=>'Str',is=>'ro');

has [qw(username password)]=>(isa=>'Str',is=>'ro',default=>"");

has 'attributes'=>(isa=>'HashRef',is=>'ro',default=>sub{return {}});


has 'table'=>(isa=>'Str',is=>'ro',predicate=>'has_table');
has 'query'=>(isa=>'Str',is=>'ro',predicate=>'has_query');


has 'dbh'=>(isa=>'Maybe[DBI::db]',is=>'ro');

#Disabling this flag will skip the database connection.  This is for testing only.

has 'connect'=>(isa=>'Bool',is=>'ro',default=>1);



around BUILDARGS=>sub
{
	my $orig  = shift;
	my $class = shift;
	my $args=shift;
	
	confess "Argument passed to BUILDARGS is not a hash reference" unless ref $args eq ref {};
	
	my $dbh=$args->{dbh};
	
	foreach("username","password")
	{
		$args->{$_}="" unless defined $args->{$_};
	}
	
	$args->{attributes}={} unless(defined $args->{attributes} and ref($args->{attributes}) eq ref{});
	$args->{connect} = 1 unless defined $args->{connect};
	
	if(defined $dbh and blessed($dbh) eq 'DBI::db')
	{
		unless($dbh->{Active})
		{
			confess "Database connection is inactive, and unable to reconnect (no DSN)" unless $args->{dsn};
			
			my $dbh = DBI->connect($args->{dsn},$args->{username},$args->{password},$args->{attributes}) or confess DBI->errstr;
		}
	}
	elsif($args->{connect})
	{
		confess "Cannot connect: neither a connection nor a DSN were passed" unless $args->{dsn};
		
		$dbh = DBI->connect($args->{dsn},$args->{username},$args->{password},$args->{attributes}) or confess DBI->errstr;
	}
	else
	{
		undef $dbh;
	}
	
	$args->{dbh}=$dbh;
	
	return $class->$orig($args);
};

sub data
{
	my $self=shift;
	
	my @raw_columns=grep{ref $_ eq ref "" or ref $_ eq ref []}@_;
	
	my $query;
	
	foreach(@_)
	{
		if(ref $_ eq ref {})
		{
			if(defined $_->{query})
			{
				$query=$_->{query};
				last;
			}
		}
	}
	
	my @columns=();
	foreach(@raw_columns)
	{
		if(ref $_ eq ref [])
		{
			foreach my $col(@{$_})
			{
				push @columns, $col;
			}
		}
		else
		{
			push @columns,$_;
		}
	}
	

	my $dbh=$self->dbh;
	
	unless(@columns)
	{
		warn "WARNING: no arguments passed to the data method";
		return undef;
	}
	
	confess "No active database connection" unless $dbh->{Active};
	
	unless($query)
	{
		$query=$self->_build_query(@columns);
	}
	
	confess "Unable to build query via the _build_query method" unless defined $query;
	
	
	my $data={};
	
	$data->{$_}=[] foreach(@columns);
	
	my $sth=$dbh->prepare($query) or confess $dbh->errstr;
	$sth->execute or confess $dbh->errstr;
	
	my $num_rows=0;
	
	while(my @row=$sth->fetchrow_array)
	{
		foreach(0..$#columns)
		{
			push @{$data->{$columns[$_]}},$row[$_];
		}
		$num_rows++;
	}
	
	$sth->finish;
	
	if($num_rows==0)
	{
		warn "WARNING: Zero rows of data returned by the following query:\n$query\n";
		return undef;
	}
	elsif($num_rows==1)
	{
		warn "WARNING: Only one row of data returned by the following query:\n$query\n";
	}
	
	return $data;
}


sub _build_query
{
	my $self=shift;
	my @columns=@_;
	
	unless(@columns)
	{
		if($self->has_query)
		{
			return "select * from ( " . $self->query . " )query";
		}
		elsif($self->has_table)
		{
			return "select * from " . $self->table;
		}
		else
		{
			return undef;
		}
	}
	
	my @dereferenced_columns=();
	foreach(@columns)
	{
		if(ref $_ eq ref "")
		{
			push @dereferenced_columns,$_;
		}
		else
		{
			push @dereferenced_columns,@{$_};
		}
	}
	my $column_list=join(",",@dereferenced_columns);
	my $is_not_null=join(" is not null and ",@dereferenced_columns) . " is not null ";
	
	
	if($self->has_table)
	{
		return "select $column_list from " . $self->table . " where $is_not_null group by $column_list order by $column_list";
	}
	elsif($self->has_query)
	{
		return "select $column_list from(" . $self->query . ")query where $is_not_null group by $column_list order by $column_list";
	}
	
	#There should be no reason why we wouldn't return by this point...
	#But just in case....
	return undef;
}



sub BUILD
{
	my $self=shift;
	
	if(($self->has_query and $self->has_table) or (not $self->has_query and not $self->has_table))
	{
		confess "Exactly one of the 'table' or 'query' attributes must be set";
	}
}



#__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Hypatia::DBI

=head1 VERSION

version 0.029

=head1 ATTRIBUTES

=head2 dsn,username,password,attributes

These are strings that are fed directly into the C<connect> method of L<DBI>.  The <dsn> attribute is not required as long as you pass an active database handle into the C<dbh> attribute (see below). Both C<username> and C<password> default to C<""> (which is useful if, for example, you're using a SQLite database).  The hash reference C<attributes> contains any optional key-value pairs to be passed to L<DBI>'s C<connect> method.  See the L<DBI> documentation for more details.

=head2 query,table

These strings represent the source of the data within the database represented by C<dsn>.  In other words, if your data source is from DBI, then you can pull data via a table name (C<table>) or via a query (C<query>).  Don't set both of these, as this will cause your script to die.

=head2 dbh

This optional attribute is the database handle that will be used to grab the data. If it is not supplied, then a connection will be made using the C<dsn>,C<username>,C<password>, and C<attributes> attributes (if possible).

=head1 METHODS

=head2 C<< data(@columns,{query=>$query}]) >>

This method grabs the resulting data from the query returned by the C<build_query> method.  The returned data structure is a hash reference of array references where the keys correspond to column names (ie the elements of the C<@columns> array) and the values of the hash reference are the values of the given column returned by the query from the C<_build_query> method.

The optional hash reference argument allows for the overriding of the query generated by the C<_build_query> method.

=head1 AUTHOR

Jack Maney <jack@jackmaney.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jack Maney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
