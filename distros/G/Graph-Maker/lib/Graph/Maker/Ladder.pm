package Graph::Maker::Ladder;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $r = delete($params{rungs}) || 0;
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	my $g = $gm->(%params);

	return $g if $r == 0;

	$g->add_edges($_, $_+1, ($g->is_directed() ? ($_+1,$_) : ())) for (1..$r-1);
	$g->add_edges($_, $_+1, ($g->is_directed() ? ($_+1,$_) : ())) for ($r+1..2*$r-1);
	$g->add_edges($_, $_+$r, ($g->is_directed() ? ($_+$r,$_) : ())) for (1..$r);

	return $g;
}

Graph::Maker->add_factory_type( 'ladder' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Ladder - Creates a ladder graph.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates the ladder with the specified number of rungs.
The ladder is a rungs by 2 L<Grid|Graph::Maker::Grid>.


	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Ladder;

	my $g = new Graph::Maker('ladder', rungs => 4, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates the ladder graph with the number of rungs specified.
The recognized parameters are rungs, and graph_maker.
Any other parameters are passed onto Graph's constructor.
If the rungs is not specified, it defaults to 0.
If graph_maker is specified, it will be called to create the Graph class as
desired (for example if you have a subclass of Graph), this defaults to
create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

None at the moment...

Please report any bugs or feature requests to
C<bug-graph-maker-ladder at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
