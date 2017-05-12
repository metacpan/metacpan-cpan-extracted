package Hypatia::Columns;
{
  $Hypatia::Columns::VERSION = '0.029';
}
use Moose;
use Array::Utils qw(unique);

#Required column types, defaults to 'x' and 'y'
has 'column_types'=>(isa=>'ArrayRef[Str]',is=>'rw',default=>sub{[qw(x y)]});

#Actual column values...this hash ref will be filled in from the coercion
has 'columns'=>(isa=>'HashRef[Str|ArrayRef[Str]]',is=>'rw',predicate=>'using_columns'
	,trigger=>
	sub{
		my $self=shift;
		
		return 1 if($self->using_columns);
		
		return $self->_validate;
	});

#Native validation works as follows:
#
# 0. 1 is returned if 'x' isn't a column type or if 'x' is the only column type (and in either case, a warning is thrown).
# 1.  undef is returned unless all column types other than 'x' are either a) all strings or b) all array references of the same length
# 2.  If 'x' represents a single column (ie 'x'=>"some_column_name"),
#     then this is assumed to denote the single, common set of x-values for all values of all other columns.  1 is returned.
# 3. If 'x' consists of an array reference of columns, then the length of this array reference must be the same as the references of all other column types.

has 'use_native_validation'=>(isa=>'Bool',is=>'rw',default=>1);

sub _validate
{
	my $self=shift;
	
	my $columns=$self->columns;
	my $types=$self->column_types;
	
	if(grep{$_ eq 'x'}@$types==0)
	{
		warn "WARNING: No column_type of 'x' has been found.\n";
		warn "Native validation in Hypatia::Columns will vacuously succeed.\n";
		return 1;
	}
	elsif(scalar@$types==1)
	{
		warn "WARNING: Only one column type--namely '" . $types->[0] . "' detected.\n";
		warn "Native validation in Hypatia::Columns will vacuously succeed.\n";
		return 1;
	}
	
	#Looking at reference types of column types other than 'x':
	my @ref_types_non_x=unique(map{ref $columns->{$_}}grep{$_ ne 'x'}@$types);
	
	if(@ref_types_non_x > 1)
	{
		warn "Reference non-'x' type mismatch: There are two column types other than 'x' such that one represents a single column and the other represents more than one column.\n";
		return undef;
	}
	
	
	if($ref_types_non_x[0] eq ref []) #If the other types correspond to array references
	{
		#look at unique lengths of the array references:
		my @lengths_non_x=unique(map{scalar(@{$columns->{$_}})}grep{$_ ne 'x'}@$types);
		
		if(@lengths_non_x > 1)
		{
			warn "Number of non-'x' type columns mismatch: All column types other than 'x' must represent the same number of columns.\n";
			return undef;
		}
		elsif(ref $columns->{x} eq ref [] and scalar(@{$columns->{x}}) != $lengths_non_x[0])
		{
			warn "Number of 'x' to non-'x' columns mismatch: If type 'x' represents more than one column, then it needs to represent the same number of columns as all other types.\n";
			return undef;
		}
	}
	
	return 1;
	
}

sub BUILD
{
	my $self=shift;
	my $types=$self->column_types;
	my $columns=$self->columns;
	
	if($self->using_columns)
	{
		my $num_types=scalar(@$types);
		
		unless(scalar(keys %$columns)==$num_types)
		{
			confess "Incorrect number of column types (should be $num_types, but I instead got " . scalar(keys %$columns) . ")";
		}
		
		foreach my $col_type(keys %$columns)
		{
			unless(grep{$col_type eq $_}@$types)
			{
				confess "Column type '$col_type' not found in the column_types attribute (containing " . join(",",map{"'" . $_ . "'"}@$types) . ")";
			}
			
		}
		
		if($self->use_native_validation)
		{
			confess "Validation failed" unless $self->_validate;
		}
	}
}



1;

__END__

=pod

=head1 NAME

Hypatia::Columns

=head1 VERSION

version 0.029

=head1 AUTHOR

Jack Maney <jack@jackmaney.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jack Maney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
