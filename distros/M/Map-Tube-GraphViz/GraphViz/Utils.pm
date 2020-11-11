package Map::Tube::GraphViz::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(node_color node_color_id
	node_color_without_label color_line);
Readonly::Array our @COLORS => qw(red green yellow cyan magenta blue grey
	orange brown white greenyellow red4 violet tomato cadetblue aquamarine
	lawngreen indigo deeppink darkslategrey khaki thistle peru darkgreen
);

our $VERSION = 0.07;

# Create GraphViz color node.
sub node_color {
	my ($obj, $node) = @_;
	my %params = _node_color_params($obj, $node);
	$obj->{'g'}->add_node(
		'label' => $node->name,
		'name' => $obj->{'callback_node_id'}->($obj, $node),
		%params,
	);
	return;
}

# Create GraphViz color node with id as label.
sub node_color_id {
	my ($obj, $node) = @_;
	my %params = _node_color_params($obj, $node);
	$obj->{'g'}->add_node(
		'label' => $node->id,
		'name' => $obj->{'callback_node_id'}->($obj, $node),
		%params,
	);
	return;
}

# Create GraphViz color node without label.
sub node_color_without_label {
	my ($obj, $node) = @_;
	my %params = _node_color_params($obj, $node);
	$obj->{'g'}->add_node(
		'label' => '',
		'name' => $obj->{'callback_node_id'}->($obj, $node),
		%params,
	);
	return;
}

# Get line color.
sub color_line {
	my ($obj, $line) = @_;
	my $line_name = $line->id || $line->name;
	if (! exists $obj->{'_color_line'}->{$line_name}) {
		if ($line->color) {
			$obj->{'_color_line'}->{$line_name} = $line->color;
		} else {
			if (! exists $obj->{'_color_index'}) {
				$obj->{'_color_index'} = 0;
			} else {
				$obj->{'_color_index'}++;
				if ($obj->{'_color_index'} > $#COLORS) {
					$obj->{'_color_index'} = 0;
				}
			}
			my $rand_color = $COLORS[$obj->{'_color_index'}];
			$obj->{'_color_line'}->{$line_name} = $rand_color;
		}
	}
	return $obj->{'_color_line'}->{$line_name};
}

# Get color node parameters.
sub _node_color_params {
	my ($obj, $node) = @_;
	my @node_lines = @{$node->line};
	my %params;
	if (@node_lines == 1) {
		%params = (
			'style' => 'filled',
			'fillcolor' => color_line($obj, $node_lines[0]),
		);
	} else {
		%params = (
			'style' => 'wedged',
			'fillcolor' => (join ':', map {
				color_line($obj, $_);
			} @node_lines),
		);
	}
	return %params;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Map::Tube::GraphViz::Utils - Utilities for Map::Tube::GraphViz module.

=head1 SYNOPSIS

 use Map::Tube::GraphViz::Utils qw(node_color node_color_id node_color_without_label color_line);

 node_color($obj, $node);
 node_color_id($obj, $node);
 node_color_without_label($obj, $node);
 my $color = color_line($obj, $line);

=head1 SUBROUTINES

=over 8

=item C<node_color($obj, $node)>

 Create GraphViz color node.
 $obj is Map::Tube::GraphViz object.
 Returns undef.

=item C<node_color_id($obj, $node)>

 Create GraphViz color node with id as label.
 $obj is Map::Tube::GraphViz object.
 Returns undef.

=item C<node_color_without_label($obj, $node)>

 Create GraphViz color node without label.
 $obj is Map::Tube::GraphViz object.
 Returns undef.

=item C<color_line($obj, $line)>

 Get line color.
 $obj is Map::Tube::GraphViz object.
 Returns color of metro line.

=back

=head1 EXAMPLE

 use strict;
 use warnings;

 use Map::Tube::Prague;
 use Map::Tube::GraphViz;
 use Map::Tube::GraphViz::Utils qw(color_line);

 my $prague = Map::Tube::Prague->new;

 my $graphviz = Map::Tube::GraphViz->new(
         'tube' => $prague,
 );

 foreach my $line_num (1 .. 25) {
         print "Line number: $line_num\n";
         my $line = Map::Tube::Line->new('id' => 'line'.$line_num);
         my $line_color = color_line($graphviz, $line);
         print "Line color: $line_color\n";
 }

 # Output:
 # Line number: 1
 # Line color: red
 # Line number: 2
 # Line color: green
 # Line number: 3
 # Line color: yellow
 # Line number: 4
 # Line color: cyan
 # Line number: 5
 # Line color: magenta
 # Line number: 6
 # Line color: blue
 # Line number: 7
 # Line color: grey
 # Line number: 8
 # Line color: orange
 # Line number: 9
 # Line color: brown
 # Line number: 10
 # Line color: white
 # Line number: 11
 # Line color: greenyellow
 # Line number: 12
 # Line color: red4
 # Line number: 13
 # Line color: violet
 # Line number: 14
 # Line color: tomato
 # Line number: 15
 # Line color: cadetblue
 # Line number: 16
 # Line color: aquamarine
 # Line number: 17
 # Line color: lawngreen
 # Line number: 18
 # Line color: indigo
 # Line number: 19
 # Line color: deeppink
 # Line number: 20
 # Line color: darkslategrey
 # Line number: 21
 # Line color: khaki
 # Line number: 22
 # Line color: thistle
 # Line number: 23
 # Line color: peru
 # Line number: 24
 # Line color: darkgreen
 # Line number: 25
 # Line color: red

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Map::Tube::GraphViz>

GraphViz output for Map::Tube.

=item L<Task::Map::Tube>

Install the Map::Tube modules.

=item L<Task::Map::Tube::Metro>

Install the Map::Tube concrete metro modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Map-Tube-GraphViz>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2014-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.07

=cut
