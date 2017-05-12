package Hypatia::Chart::Clicker::Bar;
{
  $Hypatia::Chart::Clicker::Bar::VERSION = '0.026';
}
use Moose;
use MooseX::Aliases;
use Chart::Clicker;
use Chart::Clicker::Data::DataSet;
use Chart::Clicker::Renderer::Bar;
use Chart::Clicker::Renderer::StackedBar;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

extends 'Hypatia::Chart::Clicker';

#ABSTRACT: Bar Charts with Hypatia and Chart::Clicker


has 'stacked'=>(isa=>'Bool',is=>'ro',default=>0);


has 'baseline'=>(isa=>'Num',is=>'ro',predicate=>'has_baseline');




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
		confess "No data given to the chart method (and no DBI options set, either)" unless $self->use_dbi;
		
		if(defined $data_arg and $self->_validate_input_data($data_arg))
		{
			$data=$data_arg;
		}
		else
		{
			$data=$self->_get_data(qw(x y));
		}
	}
	
	my $cc=Chart::Clicker->new;
	
	my $dataset=$self->_build_data_set($data);
	
	unless(blessed($dataset) eq "Chart::Clicker::Data::DataSet")
	{
		confess "Returned value from the _build_data_set method is not a Chart::Clicker::Data::DataSet";
	}
	
	$cc->add_to_datasets($dataset);
	
	
	my $dc=$cc->get_context("default");
   
	$dc->range_axis->baseline($self->baseline) if $self->has_baseline;
	
	my $renderer="Chart::Clicker::Renderer::Bar";
	
	$renderer="Chart::Clicker::Renderer::StackedBar" if $self->stacked;
	
	$dc->renderer($renderer->new);     
	
	$cc = $self->options->apply_to($cc);
	
	return $cc;
}

alias graph=>'chart';

sub BUILD
{
	with 'Hypatia::Chart::Clicker::Role::XY';
}


1;

__END__

=pod

=head1 NAME

Hypatia::Chart::Clicker::Bar - Bar Charts with Hypatia and Chart::Clicker

=head1 VERSION

version 0.026

=head1 ATTRIBUTES

=head2 columns

The required column types are C<x> and C<y> (ie the default given by L<Hypatia>).  Each of the values for this attribute may be either a string (indicating one column) or an array reference of strings (indicating several columns).  In the latter case, the number of C<x> and C<y> columns must match and each respective C<x> and C<y> column will form its own bar chart.  In the former case, the single C<x> column will act as the same C<x> column for all of the C<y> columns.

If the C<columns> attribute is B<not> set, then column guessing is used as needed via the algorithm described in L<Hypatia::Chart::Clicker::Role::XY>.

=head2 stacked

A boolean value indicating whether or not the graph should be a stacked bar graph (ie whether or not the y values should be treated cumulatively).  This is disabled by default.

=head2 baseline

A numeric value indicating where the baseline should be on the y-axis.  Bars with values below the baseline will be considered "negative", and will point downwards.  Take a look at L<https://github.com/gphat/chart-clicker-examples/blob/master/bar/bar-baseline.png|this chart> and L<https://github.com/gphat/chart-clicker-examples/blob/master/bar/bar-baseline.pl|the corresponding code> for an example.

If this attribute isn't set (which is the default), then there is no baseline.

=head1 AUTHOR

Jack Maney <jack@jackmaney.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jack Maney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
