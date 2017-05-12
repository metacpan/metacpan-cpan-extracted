package Map::Tube::GraphViz::Utils;

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use Error::Pure qw(err);
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(node_color node_color_id
	node_color_without_label color_line);
Readonly::Array our @COLORS => qw(red green yellow cyan magenta blue grey
	orange brown white greenyellow red4 violet tomato cadetblue aquamarine
	lawngreen indigo deeppink darkslategrey khaki thistle peru darkgreen
);

# Version.
our $VERSION = 0.06;

# Create GraphViz color node.
sub node_color {
	my ($obj, $node) = @_;
	my %params = _node_color_params($obj, $node);
	$obj->{'g'}->add_node(
		'label' => $node->name,
		'name' => $node->id,
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
		'name' => $node->id,
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
		'name' => $node->id,
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
					err "No color for line '$line'.";
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
 node_color($obj, $node);
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

=head1 ERRORS

 color_line():
         No color for line '%s'.

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

L<Map::Tube>.

=head1 REPOSITORY

L<https://github.com/tupinek/Map-Tube-GraphViz>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.06

=cut
