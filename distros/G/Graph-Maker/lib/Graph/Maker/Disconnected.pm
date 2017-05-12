package Graph::Maker::Disconnected;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n = delete($params{N}) || 0;
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	my $g = $gm->(%params);

	$g->add_vertices(1..$n);

	return $g;
}

Graph::Maker->add_factory_type( 'disconnected' => __PACKAGE__ );

1;

__DATA__


=head1 NAME

Graph::Maker::Disconnected - Create a graph with no edges

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a disconnected graph with the number of nodes. A
disconnected graph has N nodes and no edges.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Disconnected;

	my $g = new Graph::Maker('disconnected', N => 4, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a disconnected graph with N nodes. The recognized parameters are
graph_maker, N and any others are passed onto Graph's constructor. If N
is not given, it defaults to 0. If graph_maker is specified, it will be
called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

None at the moment...

Please report any bugs or feature requests to
C<bug-graph-maker-disconnected at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
