package Hypatia::Chart::Clicker::Pie;
{
  $Hypatia::Chart::Clicker::Pie::VERSION = '0.026';
}
use Moose;
use MooseX::Aliases;
use Hypatia::Columns;
use Moose::Util::TypeConstraints;
use Scalar::Util qw(blessed);
use Chart::Clicker;
use Chart::Clicker::Data::DataSet;
use Chart::Clicker::Data::Series::Size;
use Chart::Clicker::Renderer::Pie;
use namespace::autoclean;

extends 'Hypatia::Chart::Clicker';


#ABSTRACT: Line Charts with Hypatia and Chart::Clicker


subtype 'HypatiaPieColumns' => as class_type("Hypatia::Columns");
coerce "HypatiaPieColumns",from "HashRef", via {Hypatia::Columns->new({columns=>$_,column_types=>[qw(label values)],use_native_validation=>0})};

has '+cols'=>(isa=>'HypatiaPieColumns');


has 'use_gradient'=>(isa=>'Bool',is=>'ro',default=>0);


subtype 'GradientColor' => as class_type("Graphics::Color::RGB");
coerce "GradientColor",from "HashRef", via {Graphics::Color::RGB->new($_)};

has 'gradient_color'=>(isa=>'GradientColor',is=>'ro',coerce=>1
	,default=>sub{Graphics::Color::RGB->new({red=>1,green=>1,blue=>1,alpha=>0.25})});



sub BUILD
{
	my $self=shift;
	my $columns=$self->columns;
	
	confess "Wrong number of column types" unless(scalar(keys %$columns)==2 or not $self->using_columns);
	confess "Wrong keys (should be 'label' and 'values')" unless(scalar(grep{$_ eq 'label' or $_ eq 'values'}(keys %$columns))==2 or not $self->using_columns);
	confess "Column values need to be strings" unless(scalar(grep{ref $_ eq ref ""}(values %$columns)) == 2 or not $self->using_columns);
	
}


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
		$data=$self->_get_data(qw(label values));
	}
	
	
	my $cc=Chart::Clicker->new;
	
	my $dataset=$self->_build_data_set($data);
	
	
	unless(blessed($dataset) eq "Chart::Clicker::Data::DataSet")
	{
		confess "Returned value from the _build_data_set method is not a Chart::Clicker::Data::DataSet";
	}
	
	$cc->add_to_datasets($dataset);
	$cc->plot->grid->visible(0);
	
	
	my $dc=$cc->get_context("default");
	$dc->domain_axis->hidden(1);
	$dc->range_axis->hidden(1);
	
	my $renderer=Chart::Clicker::Renderer::Pie->new;
	
	if($self->use_gradient)
	{
		$renderer->gradient_color($self->gradient_color);
		$renderer->gradient_reverse(1);
	}
	
	$dc->renderer($renderer);
	
	$cc = $self->options->apply_to($cc);
	
	return $cc;
}

alias graph=>'chart';

sub _build_data_set
{
	my $self=shift;
	my $data=shift;
	
	my ($label,$values)=($self->columns->{label},$self->columns->{values});
	
	my %label_values=();
	
	foreach my $i(0..(scalar(@{$data->{$label}})-1))
	{
		$label_values{$data->{$label}->[$i]}+=$data->{$values}->[$i];
	}
	
	my $series_array_ref=[];
	
	foreach my $lab (sort keys %label_values)
	{
		unless($label_values{$lab}>=0)
		{
			confess "The sum of values corresponding to the label of '$lab' is negative";
		}
		
		push @$series_array_ref,Chart::Clicker::Data::Series->new(
			keys=>[1,2],
			values=>[$label_values{$lab},0],
			name=>$lab
		);
	}
	
	
	return Chart::Clicker::Data::DataSet->new(series=>$series_array_ref);

}

override '_guess_columns' =>sub
{
    my $self=shift;
    
    my @columns=@{$self->_setup_guess_columns};
    
    my $col_types={};
    
    if(@columns != 2)
    {
	confess "Only two data columns (of types 'label' and 'values') are allowed for pie charts";
    }
    else
    {
	$col_types->{label} = $columns[0];
	$col_types->{values} = $columns[1];
    }
    
    $self->cols(Hypatia::Columns->new({columns=>$col_types,column_types=>[qw(label values)],use_native_validation=>0}));
};



override '_validate_input_data',sub
{
	my $self=shift;
	
	my $data=shift;
	
	return undef unless defined($data) and ref $data eq ref {};
	
	return undef unless scalar(keys %$data)==2;
	return undef unless grep{$_ eq 'label' or $_ eq 'values'}(keys %$data)==2;
	
	return undef unless grep{ref $_ eq ref []}(values %$data)==2;
	
	return undef unless @{$data->{label}}==@{$data->{values}};
	
	return 1;
	
};


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Hypatia::Chart::Clicker::Pie - Line Charts with Hypatia and Chart::Clicker

=head1 VERSION

version 0.026

=head1 SYNOPSIS

This module extends L<Hypatia::Chart::Clicker>.  The C<graph> method (also known as the C<chart> method) returns the C<Chart::Clicker> object built from the relevant data and options provided.

=head1 ATTRIBUTES

=head2 columns

The required column types are C<label> and C<values>.  Each of these must be a single string.

If this attribute isn't provided, then column guessing proceeds in the obvious manner: if there are two columns, then the first is of type C<label> and the second of type C<values>, and otherwise an error is thrown.

=head2 use_gradient

A boolean value determining whether or not a gradient should be applied to the pie chart.  Defaults to 0.

=head2 gradient_color

This is a hash reference of C<red>, C<green>, C<blue>, and C<alpha> values that are passed into a L<Graphics::Color::RGB> object (or, if you prefer, you can pass in a L<Graphics::Color::RGB> object directly).  The default RGBA values are 1,1,1,0.25, respectively.

=head1 METHODS

=head2 chart

This method returns the relevant L<Chart::Clicker> object.  If neither the C<dbi> nor the C<input_data> attributes have been set, then you can input your data as an argument here.

=head1 AUTHOR

Jack Maney <jack@jackmaney.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jack Maney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
