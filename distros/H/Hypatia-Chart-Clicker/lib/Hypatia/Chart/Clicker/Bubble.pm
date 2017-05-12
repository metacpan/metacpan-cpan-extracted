package Hypatia::Chart::Clicker::Bubble;
{
  $Hypatia::Chart::Clicker::Bubble::VERSION = '0.026';
}
use Moose;
use MooseX::Aliases;
use Hypatia::Columns;
use Moose::Util::TypeConstraints;
use Scalar::Util qw(blessed);
use Chart::Clicker;
use Chart::Clicker::Data::DataSet;
use Chart::Clicker::Data::Series::Size;
use Chart::Clicker::Renderer::Bubble;
use namespace::autoclean;

extends 'Hypatia::Chart::Clicker';


#ABSTRACT: Line Charts with Hypatia and Chart::Clicker


subtype 'HypatiaBubbleColumns' => as class_type("Hypatia::Columns");
coerce "HypatiaBubbleColumns",from "HashRef", via {Hypatia::Columns->new({columns=>$_,column_types=>[qw(x y size)]})};

has '+cols'=>(isa=>'HypatiaBubbleColumns');




sub chart
{
	my $self=shift;
	my $data_arg=shift;
	
	my $data;
	
	if(defined $data_arg and $self->_validate_input_data($data_arg))
	{
		$data=$data_arg;
	}
	else
	{
		$data=$self->_get_data(qw(x y size));
	}
	
	
	my $cc=Chart::Clicker->new;
	
	my $dataset=$self->_build_data_set($data);
	
	
	unless(blessed($dataset) eq "Chart::Clicker::Data::DataSet")
	{
		confess "Returned value from the _build_data_set method is not a Chart::Clicker::Data::DataSet";
	}
	
	$cc->add_to_datasets($dataset);
	
	
	my $dc=$cc->get_context("default");
	$dc->renderer(Chart::Clicker::Renderer::Bubble->new);
	
	$cc = $self->options->apply_to($cc);
	
	return $cc;
}

alias graph=>'chart';

sub _build_data_set
{
	my $self=shift;
	my $data=shift;
	
	my ($x,$y,$size)=($self->columns->{x},$self->columns->{y},$self->columns->{size});
	
	my $series_array_ref=[];
	
	foreach($x,$y,$size)
	{
		$_=[$_] unless ref($_);
	}
	
	my $x_cols; #Either n copies of $x->[0] (if there's only one $x column) or just $x (if there's more than one $x column)
	
	if(scalar(@$x)==1)
	{
		foreach(@$y)
		{
			push @$x_cols,$x->[0];
		}
	}
	else
	{
		$x_cols=$x;
	}
	
	my @names=@$y;
	
	if($self->has_data_series_names)
	{
		foreach my $i(0..(scalar(@{$self->data_series_names})-1))
		{
			if (defined($self->data_series_names->[$i]) and $i<@$y)
			{
				$names[$i]=$self->data_series_names->[$i];
			}
		}
	}
	
	foreach(0..(scalar(@$y)-1))
	{
		my @x_data;
		my @y_data;
		my @size_data;
		
		if($self->has_input_data)
		{
			my @raw_x_data=@{$data->{$x_cols->[$_]}};
			my @raw_y_data=@{$data->{$y->[$_]}};
			my @raw_size_data=@{$data->{$size->[$_]}};
			
			@x_data=sort{$a<=>$b}@raw_x_data;
			#sorting y by the values of x:
			@y_data=@raw_y_data[sort{$raw_x_data[$a]<=>$raw_x_data[$b]}0..$#raw_x_data];
			#ditto for size
			@size_data=@raw_size_data[sort{$raw_x_data[$a]<=>$raw_x_data[$b]}0..$#raw_x_data];
		}
		else
		{
			@x_data=@{$data->{$x_cols->[$_]}};
			@y_data=@{$data->{$y->[$_]}};
			@size_data=@{$data->{$size->[$_]}};
		}
		
		push @$series_array_ref,Chart::Clicker::Data::Series::Size->new(
			keys=>\@x_data,
			values=>\@y_data,
			sizes=>\@size_data,
			name=>$names[$_]
		);
	}
	
	return Chart::Clicker::Data::DataSet->new(series=>$series_array_ref);

}

override '_guess_columns' =>sub
{
    my $self=shift;
    
    my @columns=@{$self->_setup_guess_columns};
    
    my $col_types={};
    
    if(@columns < 3)
    {
	confess "One or two columns are insufficient to form a bubble chart";
    }
    elsif(@columns == 3)
    {
	$col_types->{x} = $columns[0];
        $col_types->{y} = $columns[1];
	$col_types->{size} = $columns[2];
    }
    elsif(scalar(@columns) % 3 == 0)
    {
	while(@columns)
	{
		push @{$col_types->{x}},shift @columns;
		push @{$col_types->{y}},shift @columns;
		push @{$col_types->{size}},shift @columns;
	}
    }
    elsif(scalar(@columns) % 2)
    {
	$col_types->{x}=shift @columns;
	
	while(@columns)
	{
		push @{$col_types->{y}}, shift @columns;
		push @{$col_types->{size}}, shift @columns;
	}
    }
    else
    {
	confess "Unable to guess which columns correspond to which type. Please use the 'columns' attribute";
    }
    
    $self->cols(Hypatia::Columns->new({columns=>$col_types,column_types=>[qw(x y size)]}));
};



override '_validate_input_data',sub
{
	my $self=shift;
	
	my $data=shift;
	
	return undef unless defined $data;
	
	my $first=1;
	my $num_rows;
	
	my @column_list;
	
	foreach my $type(keys %{$self->columns})
	{
		my $col=$self->columns->{$type};
		
		if(ref $col eq ref [])
		{
			foreach my $c(@$col)
			{
				push @column_list,$c unless grep{$c eq $_}@column_list;
			}
		}
		else
		{
			push @column_list,$col unless grep{$col eq $_}@column_list;
		}
	}
	
	foreach my $col(@column_list)
	{ 
		unless(grep{$_ eq $col}(keys %$data))
		{
			warn "WARNING: Column \"$col\" not found as a key in the input_data attribute\n";
			return undef;
		}
		
		
		my @column=@{$data->{$col}};
		
		unless(@column == grep{defined $_}@column)
		{
			warn "WARNING: Undefined values found in the input_data for column $col";
			return undef;
		}
		
		if($first)
		{
			$num_rows=scalar(@column);
			$first=0;
		}
		else
		{
			unless(@{$data->{$col}} == $num_rows)
			{
				warn "WARNING: Mismatch for number of elements in input_data values";
				return undef;
			}
		}
	}
	
	return 1;
};


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Hypatia::Chart::Clicker::Bubble - Line Charts with Hypatia and Chart::Clicker

=head1 VERSION

version 0.026

=head1 SYNOPSIS

This module extends L<Hypatia::Chart::Clicker>.  The C<graph> method (also known as the C<chart> method) returns the C<Chart::Clicker> object built from the relevant data and options provided.

=head1 ATTRIBUTES

=head2 columns

The required column types are C<x>, C<y>, and C<size>.  Each of the values for this attribute may be either a string (indicating one column) or an array reference of strings (indicating several columns).  If C<y> and C<size> are array references, then they must be the same size.  If C<x> is an array reference, then it also must be the same size as C<y> and C<size> (and in this case, each C<x> column will serve as x-axis values corresponding to the C<y> and C<size> columns).  Otherwise, if C<x> is a string, then the single C<x> column will serve as a common set of x-values for all C<y> and C<size> values.

Of course, since C<size> represents size values for the given data set(s), please make sure that the data stored in any C<size> columns contains nonnegative values.

If this column isn't provided, then Hypatia will do its best job to guess which column names of your data correspond to which types, as follows:

=over 4

=item 1. If there are three columns, then they'll be assigned to C<x>, C<y>, and C<size> (respectively).
=item 2. Otherwise, if the number of columns is a multiple of 3, then the corresponding types will be

	x, y, size, x, y, size,..., x, y, size

(ie each consecutive triple will be assigned to C<x>, C<y>, and C<size>, respectively).

=item 3. If the number of columns is odd, larger than 3, but not divisible by 3, then the first column will be assigned to type C<x>, and the remaining columns will be paired off as types:

	y, size, y, size,..., y, size

=item 4. If none of the above are the case, then an error is thrown.

=back

=head1 METHODS

=head2 chart([$data]), a.k.a graph([$data])

This method returns the relevant L<Chart::Clicker> object.  If neither the C<dbi> nor the C<input_data> attributes have been set, then you can input your data as an argument here.

=head1 AUTHOR

Jack Maney <jack@jackmaney.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jack Maney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
