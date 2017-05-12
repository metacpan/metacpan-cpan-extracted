package Language::Homespring::Visualise::GraphViz;

$VERSION = 0.04;

use warnings;
use strict;
use GraphViz;

sub new {
        my $class = shift;
        my $self = bless {}, $class;

        my $options = shift;
        $self->{interp}		= $options->{interp};
	$self->{spring_col}	= $options->{spring_col} || '#C0C0FF';
	$self->{node_col}	= $options->{node_col} || 'white';

	$self->{fontname}	= $options->{fontname} || 'Times';
	$self->{fontsize}	= $options->{fontsize} || '12';

        return $self;
}

sub do {
	my ($self) = @_;
	
	$self->{graph}	= GraphViz->new(
			directed => 0, 
			layout => 'dot',
			rankdir => 1, 
			epsilon => 1,
		);

	$self->add_node($self->{interp}->{root_node}, 1);

	return $self->{graph};
}

sub add_node {
	my ($self, $node, $rank) = @_;

	for(@{$node->{child_nodes}}){
		my $label = $_->{node_name_safe};
		$label =~ s/\\/\\\\/g;

		my $fillcolor = $_->{spring}?$self->{spring_col}:$self->{node_col};

		$self->{graph}->add_node(
			$_->{uid}, 
			label		=> $label,
			rank		=> $rank,
			fillcolor	=> $fillcolor,
			style		=> 'filled',
			fontname	=> $self->{fontname},
			fontsize	=> $self->{fontsize},
		);

		$self->{graph}->add_edge(
			$node->{uid} => $_->{uid},
			arrowtail => 'normal',
		) if ($node->{uid} != $self->{interp}->{root_node}->{uid});

		$self->add_node($_, $rank+1);
	}
}

__END__

=head1 NAME

Language::Homespring::Visulaise::GraphViz - A visual op-tree viewer for "Homespring"

=head1 SYNOPSIS

  use Language::Homespring;
  use Language::Homespring::Visualise::GraphViz;

  my $code = "bear hatchery Hello,. World ..\n powers";

  my $hs = new Language::Homespring();
  $hs->parse($code);

  my $vis = new Language::Homespring::Visualise::GraphViz({'interp' => $hs});
  print $vis->do()->as_gif;

=head1 DESCRIPTION

This module implements a viewer for Homespring op-trees,
using the GraphViz program. You can now see the rivers that
your code produces :)

=head1 METHODS

=over 4

=item C<< new({'interp' => $hs}) >>

Creates a new C<Language::Homespring::Visualise::GraphViz> object. The single
hash argument contains initialisation info. The only key currently
required is 'interp', which should point to the C<Language::Homespring> object 
you wish to visualise. 

Other optional keys are:

=over 5

=item C<node_col>

The background color to use for reserved word nodes. Specified in GraphViz 
format (#rrggbb is ok). Defaults to white.

=item C<spring_col>

The background color to use for spring nodes. Specified in GraphViz format 
(#rrggbb is ok). Defaults to #c0c0ff (light blue).

=item C<fontname>

The name of the font to use. Defaults to "Times".

B<Important:> If the font file cannot be found (for "Times", "Times.ttf" must 
be in the font seach path - remember case sensitivity on unix etc.) then a 
built in font will be used, BUT the labels will not be centered in the nodes.

=item C<fontsize>

The size of the font in points. Defaults to 12.

=back

=item C<do()>

Returns a C<GraphViz> object, with all nodes and edges for the current state
of the op-tree. You can then call standard GraphViz methods on this object
such as as_gif() and as_png() to output an image.

=back

=head1 EXAMPLES

The examples folder in this distribution contains an example script (C<example.pl>)
and three example GIFs. The GIFs are visual representations of the .hs files of the 
same name from the C<Language::Homespring> distribution.

=head1 AUTHOR

Copyright (C) 2003 Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<perl>

L<Language::Homespring>

L<http://www.graphviz.org/>

=cut

