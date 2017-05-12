package Hypatia::GraphViz2;
{
  $Hypatia::GraphViz2::VERSION = '0.015';
}
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Aliases;
use GraphViz2;
use namespace::autoclean;

extends "Hypatia::Base";

#ABSTRACT: Hypatia Bindings for GraphViz2



subtype "HypatiaGraphViz2Columns" => as class_type("Hypatia::Columns");
coerce "HypatiaGraphViz2Columns", from "HashRef"
    , via {Hypatia::Columns->new({column_types=>[qw(v1 v2)],columns=>$_,use_native_validation=>0})};

has "+cols"=>(isa=>"HypatiaGraphViz2Columns");


has "directed"=>(isa=>"Bool",is=>"ro",default=>0);


sub graph
{
    my $self=shift;
    my $data_arg=shift;
	
    my $data=$self->_get_data("v1","v2",{query=>$self->query});

	use Data::Dumper;print "\$data: " . Dumper($data) . "\n";
    
    my $graph=GraphViz2->new(global=>{directed=>$self->directed});
    
    my $n=scalar(@{$data->{$self->columns->{v1}}}) - 1;
    
    foreach my $i(0..$n)
    {
	my ($v1,$v2) = ($data->{$self->columns->{v1}}->[$i],$data->{$self->columns->{v2}}->[$i]);
	$graph->add_node(name=>$v1) if defined $v1;
	$graph->add_node(name=>$v2) if defined $v2;
	$graph->add_edge(from=>$v1, to=>$v2) if(defined $v1 and defined $v2);
    }
    
    return $graph;
    
}

alias chart=>'graph';


override '_guess_columns' =>sub
{
    my $self=shift;
    
    my @columns=@{$self->_setup_guess_columns};
    
    if(@columns != 2)
    {
	confess "Only two columns (of types v1 and v2) are currently supported for GraphViz2 graphs via Hypatia";
    }
    
    $self->cols(Hypatia::Columns->new({columns=>{v1=>$columns[0],v2=>$columns[1]},column_types=>[qw(v1 v2)],use_native_validation=>0}));
    
};

sub BUILD
{
    my $self=shift;
    
    $self->_guess_columns unless $self->cols->using_columns;
    
    unless(scalar(keys %{$self->columns}) == 2 and scalar(grep{$_ eq "v1" or $_ eq "v2"}(keys %{$self->columns})) == 2)
    {
	confess "The only allowable column types are 'v1' and 'v2'";
    }
    
    unless(ref $self->columns->{v1} eq ref "" and ref $self->columns->{v2} eq ref "")
    {
	confess "Only a single column of each of types 'v1' and 'v2' is allowed (no array refs)";
    }
}

sub query
{
    my $self=shift;
    
    $self->_guess_columns unless $self->using_columns;
    
    my @columns=();
    
    foreach my $ct(@{$self->cols->column_types})
    {
	push @columns,$self->columns->{$ct};
    }
    
    
    my $middle;
    
    if($self->dbi->has_query)
    {
		$middle = $self->dbi->query;
    }
    else
    {
		$middle = "select * from " . $self->dbi->table;
    }
    
	my ($v1,$v2) = ($self->columns->{v1},$self->columns->{v2});

    my $query="select " . join(",",@columns) . " from ( " . $middle . " )a where ";
    

	$query .= "( $v1 is not null or $v2 is not null ) ";
    
    $query.= " or ( $v1 is not null and $v2 is not null and $v1 < $v2 )" unless($self->directed);
    $query .= " group by " . join(",",@columns) . " order by " . join(",",@columns);
    
    return $query;
}



__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Hypatia::GraphViz2 - Hypatia Bindings for GraphViz2

=head1 VERSION

version 0.015

=head1 SYNOPSIS

	use strict;
	use warnings;
	use Hypatia;
	
	my $hypatia=Hypatia->new({
		back_end=>"GraphViz2",
		dbi=>{
			dsn=>"dbi:Pg:dbname=some_db;host=localhost",
			username=>"bob",
			password=>"dole",
			query=>"select a.user_id as user_1,b.user_id as user_2
			from users a
			join users b on (a.id = b.frend_id)
			where a.user_id != b.user_id"
		}
		,columns=>{v1=>"user_1",v2=>"user2"}
		,directed=>1
	});
	
	# $gv2 is now a GraphViz2 object, with all of the default label, color, shape, etc settings,
	# except for the fact that the graph is directed
	my $gv2 = $hypatia->graph;
	
	$gv2->run(format=>"png",output_file=>"user_social_graph.png");

=head1 DESCRIPTION

As with the other Hypatia plugins, this module extends L<Hypatia::Base>. The API is mostly the same as that for L<Hypatia::Chart::Clicker>, with the biggest exception being that only two column types are allowed: C<v1> and C<v2> (see below).

For the other attributes and methods, look at L<Hypatia::Base>.

=head1 ATTRIBUTES

=head2 columns

For now, the only acceptable column types are C<v1> and C<v2>. If this attribute is not provided, then column guessing works as follows: if there are two columns, then the first is assigned to C<v1> and the second to C<v2>, otherwise an error is thrown.

=head2 directed

This boolean value determines whether or not the L<GraphViz2> object emitted from the C<graph> method (see below) will represent a directed graph. The default value is 0.

=head1 METHODS

=head2 graph([$data]) aka chart([$data])

Returns the L<GraphViz2> object represented by the data, with edges represented by (non-null) C<< (v1,v2) >> pairs.

=head1 TODO

=over 4

=item 1. Write more robust unit tests, as soon as I can find out how to list the nodes and edges from a GraphViz2 object.

=item 2. Look through the list of L<GraphViz attributes|http://www.graphviz.org/content/attrs> and figure out which would be the most useful to include as column types (definitely vertex shapes and colors, as well as edge colors and labels, but what else?).

=item 3. Include the attributes from part 2. as column types and apply the attributes (if provided) within the C<graph> method.

=back

=head1 AUTHOR

Jack Maney <jack@jackmaney.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jack Maney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
