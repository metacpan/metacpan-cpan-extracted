package HTML::InfoVis::Graph;

=pod

=head1 NAME

HTML::InfoVis::Graph - Generate a JSON structure suitable for loadJSON classes

=head1 SYNOPSIS

  use HTML::InfoVis;
  
  my $graph = HTML::InfoVis::Graph->new;
  $graph->add_edge( 'foo' => 'bar' );
  
  print "var json = " . $graph->as_json . "\n";

=head1 DESCRIPTION

HTML::InfoVis::Graph is used to generate a JSON structure suitable for loading
by any InfoVis Javascript object that has the C<loadJSON> method.

This is a basic first implementation, designed to prove the concept of converting
Perl graphs into InfoVis graphs.

It provides a few L<Graph>-like methods to populate the graph, and a single method
for generating an anonymous JSON structure representing the graph.

=head1 METHODS

=cut

use 5.006;
use strict;
use JSON  2.16 ();
use Graph 0.85 ();

our $VERSION = '0.03';

=pod

=head2 new

  my $graph = HTML::InfoVis::Graph->new(
      Graph->new,
  );

The default constructor takes a single optional param of a L<Graph> object
that represents the graph structure.

Returns a new B<HTML::InfoVis::Graph> object.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	unless ( defined $self->{graph} ) {
		$self->{graph} = Graph->new;
	}
	return $self;
}

=pod

=head2 add_node

  $graph->add_node( 'foo' );

The C<add_node> method is a pass-through method to the underlying
L<Graph> C<add_vertex> method.

=cut

sub add_node {
	my $self = shift;
	$self->{graph}->add_vertex(@_);
}

=pod

=head2 add_edge

  $graph->add_edge( 'foo' => 'bar' );

The C<add_edge> method is a pass-through method to the underlying
L<Graph> C<add_edge> method.

=cut

sub add_edge {
	my $self = shift;
	$self->{graph}->add_edge(@_);
}

=pod

=head2 as_json

  my $json = $graph->as_json;

The C<as_json> method generates a serialized anonymous JSON structure that
represents the graph in a form suitable for loading by any InfoVis C<loadJSON>
method.

Because it is generated anonymously, if you wish to assign it to a variable
you will need to do that yourself in your JavaScript template.

=cut

sub as_json {
	my $self  = shift;
	my $graph = $self->{graph};
	my @nodes = ();
	foreach my $name ( sort $graph->vertices ) {
		push @nodes, {
			id          => $name,
			name        => $name,
			adjacencies => [ $graph->successors($name) ],
		};
	}
	JSON->new->canonical(1)->pretty(1)->encode(\@nodes);
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-InfoVis>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
