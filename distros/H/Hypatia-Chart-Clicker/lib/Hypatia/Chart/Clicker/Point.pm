package Hypatia::Chart::Clicker::Point;
{
  $Hypatia::Chart::Clicker::Point::VERSION = '0.026';
}
use Moose;
use MooseX::Aliases;
use Moose::Util::TypeConstraints;
use Scalar::Util qw(blessed);
use Chart::Clicker;
use Chart::Clicker::Data::DataSet;
use Chart::Clicker::Renderer::Point;
use namespace::autoclean;

extends 'Hypatia::Chart::Clicker';


#ABSTRACT: Scatterplots with Hypatia and Chart::Clicker


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
		$data=$self->_get_data(qw(x y));
	}
	
	use Data::Dumper;
	
	my $cc=Chart::Clicker->new;
	
	my $dataset=$self->_build_data_set($data);
	
	
	unless(blessed($dataset) eq "Chart::Clicker::Data::DataSet")
	{
		confess "Returned value from the _build_data_set method is not a Chart::Clicker::Data::DataSet";
	}
	
	$cc->add_to_datasets($dataset);
	
	
	my $dc=$cc->get_context("default");
	$dc->renderer(Chart::Clicker::Renderer::Point->new);
	
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

Hypatia::Chart::Clicker::Point - Scatterplots with Hypatia and Chart::Clicker

=head1 VERSION

version 0.026

=head1 SYNOPSIS

This module extends L<Hypatia::Chart::Clicker>.  The C<graph> method (also known as the C<chart> method) returns the C<Chart::Clicker> object built from the relevant data and options provided.

=head1 ATTRIBUTES

=head2 columns

The required column types are C<x> and C<y>.  Each of the values for this attribute may be either a string (indicating one column) or an array reference of strings (indicating several columns).  In the latter case, the number of C<x> and C<y> columns must match and each respective C<x> and C<y> column will form its own line graph.  In the former case, the single C<x> column will act as the same C<x> column for all of the C<y> columns.

If the C<columns> attribute is B<not> set, then column guessing is used as needed via the algorithm described in L<Hypatia::Chart::Clicker::Role::XY>.

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
