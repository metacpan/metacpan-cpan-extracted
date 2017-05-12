package Graph::Maker;

use strict;
use warnings;
use base qw/Class::Factory/;

our $VERSION = '0.02';

#Graph::Maker->add_factory_type('balanced_tree' => 'Graph::Maker::BalancedTree');
#Graph::Maker->add_factory_type('barbell' => 'Graph::Maker::Barbell' );
#Graph::Maker->add_factory_type('bipartite' => 'Graph::Maker::Bipartite' );
#Graph::Maker->add_factory_type('circular_ladder' => 'Graph::Maker::CircularLadder' );
#Graph::Maker->add_factory_type('complete' => 'Graph::Maker::Complete' );
#Graph::Maker->add_factory_type('complete_bipartite' => 'Graph::Maker::CompleteBipartite' );
#Graph::Maker->add_factory_type('cycle' => 'Graph::Maker::Cycle' );
#Graph::Maker->add_factory_type('degree' => 'Graph::Maker::Degree' );
#Graph::Maker->add_factory_type('disconnected' => 'Graph::Maker::Disconnected' );
#Graph::Maker->add_factory_type('disk' => 'Graph::Maker::Disk' );
#Graph::Maker->add_factory_type('empty' => 'Graph::Maker::Empty' );
#Graph::Maker->add_factory_type('grid' => 'Graph::Maker::Grid' );
#Graph::Maker->add_factory_type('hypercube' => 'Graph::Maker::HyperCube' );
#Graph::Maker->add_factory_type('ladder' => 'Graph::Maker::Ladder' );
#Graph::Maker->add_factory_type('linear' => 'Graph::Maker::Linear' );
#Graph::Maker->add_factory_type('lollipop' => 'Graph::Maker::Lollipop' );
#Graph::Maker->add_factory_type('random' => 'Graph::Maker::Random' );
#Graph::Maker->add_factory_type('regular' => 'Graph::Maker::Regular' );
#Graph::Maker->add_factory_type('small_world_ba' => 'Graph::Maker::SmallWorldBA' );
#Graph::Maker->add_factory_type('small_world_hk' => 'Graph::Maker::SmallWorldHK' );
#Graph::Maker->add_factory_type('small_world_k' => 'Graph::Maker::SmallWorkdK' );
#Graph::Maker->add_factory_type('small_world_ws' => 'Graph::Maker::SmallWorkdWS' );
#Graph::Maker->add_factory_type('star' => 'Graph::Maker::Star' );
#Graph::Maker->add_factory_type('uniform' => 'Graph::Maker::Uniform' );
#Graph::Maker->add_factory_type('wheel' => 'Graph::Maker::Wheel' );
#Graph::Maker->add_factory_type('linear' => 'Graph::Maker::Linear' );

1;

__DATA__

=head1 NAME

Graph::Maker - Create many types of graphs

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Base class for Graph::Maker::*.  Subclasses extend this class and override the init method.  The init
method is passed the class and the parameters.  This uses L<Class::Factory>.


	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Linear; # or import qw/Graph::Maker/;

	my $g = new Graph::Maker('linear', N => 10);
	# work with the graph

=head1 SUBCLASSING

The simplest example is the linear graph, nodes i is connected to node i+1.  The implimentation can simply be:

	package Graph::Maker::Linear;

	use strict;
	use warnings;
	use Carp;
	use base qw/Graph::Maker/;
	use Graph;

	sub init
	{
		my ($self, %params) = @_;

		my $N = delete($params{N});

		my $g = new Graph(%params);
		$g->add_path(1..$N);
		return $g;
	}

	Graph::Maker->add_factory_type( 'linear' => __PACKAGE__ );

	1;

A real implimentation should check that N is defined and is valid (the one provided in this package does).
It is that simple.


=head1 SEE ALSO

=over 4

=item L<Class::Factory>

=item L<Graph>

=back

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

None at the moment...

Please report any bugs or feature requests to
C<bug-graph-maker at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

This package owes a lot to L<NetworkX|http://networkx.lanl.gov/>, this is something I think is
really needed to extend the great L<Graph> module.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
