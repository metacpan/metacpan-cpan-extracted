package Games::LatticeGenerator::Model;
use strict;
use warnings;
use Carp;
use Math::Trig;
use GD::Simple;
use Games::LatticeGenerator::ObjectDescribedByFacts;
use base 'Games::LatticeGenerator::ObjectDescribedByFacts';


=head1 NAME

Games::LatticeGenerator::Model - The Games::LatticeGenerator::Model.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SUBROUTINES/METHODS

=head2 new

A constructor. It calls the superconstructor and adds a hash "coordinates".

=cut
sub new
{
	my $class = shift;
	my $this = $class->SUPER::new(@_);
	
	$$this{coordinates} = {};
	
	return $this;
}

=head2 add_knowledge_about_solids

The knowledge about the solids is added to the overall knowledge about the object.

=cut
sub add_knowledge_about_solids
{
	my $this = shift;
	$$this{description} .= join("", map { 
<<DESCRIPTION
$$this{solids}[$_]{description}
belongs_to($$this{solids}[$_]{name}, $this).
DESCRIPTION
} 0..$this->get_amount_of_solids()-1);
}

=head2 get_amount_of_solids

Returns the amount of solids within the object.

=cut
sub get_amount_of_solids
{
	my $this = shift;
	croak "no solids in ".ref($this)." $$this{name}" unless defined($$this{solids});
	return scalar(@{$$this{solids}});
}

=head2 get_candidates

Returns a list of planes connected to the lattice that have a common edge with the given plane.

=cut
sub get_candidates
{
	my ($this, $plane, $knowledge_about_planes_connected_to_lattice, $knowledge_about_connections_between_planes, $list_of_planes_connected_to_lattice_ref) = @_;

	my @result = ();

	for my $k (keys %{$$this{knowledge_about_common_edges_of_visible_planes}{$plane}})
	{
		if (!grep { $k eq $_ } @$list_of_planes_connected_to_lattice_ref)
		{
			push @result, $k;
		}
	}
	return @result;
}

=head2 create_png

Creates an img object (an image).

=cut
sub create_png
{
	my $this = shift;
	$$this{img} = GD::Simple->new(450, 670);	
}

=head2 save_png

Saves an image into a file.

=cut
sub save_png
{
	my ($this, $filename) = @_;
	croak "give filename" unless $filename;
	
	local *FILE;
	open FILE, ">$filename" or die "$! ($filename)";
	binmode FILE;
	print FILE $$this{img}->png();
	close FILE;
}

=head2 add_knowledge

Adds given knowledge (Prolog facts and rules) to the description.

=cut
sub add_knowledge
{
	my ($this, $knowledge) = @_;
	$$this{description} .= $knowledge;

	if ($$this{super})
	{
		$$this{super}->add_knowledge($knowledge);
	}
}

=head2 get_edges

Returns all edges belonging to this object.

=cut
sub get_edges
{
	my $this = shift;	
	return $this->get_solution(__LINE__,"EDGE", "is_a_Stretch(EDGE), belongs_to(EDGE, PLANE), is_a_Polygon(PLANE), belongs_to(PLANE, SOLID), belongs_to(SOLID, $$this{name})");
}

=head2 get_planes

Returns all planes belonging to this object.

=cut
sub get_planes
{
	my $this = shift;
	return $this->get_solution(__LINE__,"PLANE", "is_a_Polygon(PLANE), belongs_to(PLANE, SOLID), belongs_to(SOLID, $$this{name})");
}

=head2 set_the_point_coordinates

Sets the point coordinates. It refers to the points on the lattice (not in the 3D space!), so the points are
denoted with their respective plane.

=cut
sub set_the_point_coordinates
{
	my ($this, $coordinates_ref, $plane, $point, $x, $y) = @_;
	
	croak "unknown x for $plane $point" unless defined($x);
	croak "unknown y for $plane $point" unless defined($y);
		
	$$coordinates_ref{$plane.$point} = { x => $x, y => $y };
}

=head2 make_decision_whether_to_do_an_overlap

=cut
sub make_decision_whether_to_do_an_overlap
{
	my ($this, $plane, $vertex1, $vertex2) = @_;
	
	my @planes = $this->get_solution(__LINE__,"PLANE", <<CONDITION);
belongs_to($vertex1, EDGE),
belongs_to($vertex2, EDGE),	
belongs_to(EDGE, PLANE), 
belongs_to(EDGE, $plane),
not(eq(PLANE, $plane)),
is_visible(PLANE), 
is_a_Polygon(PLANE), 
not(is_connected_in_lattice(PLANE, $plane))
CONDITION

	return 0 unless scalar(@planes);
	
	my $sheet1;
	my $sheet2;
	
	for my $solid (@{$$this{solids}})
	{
		for my $plane2 (@{$$solid{planes}})
		{
			if ($$plane2{name} eq $planes[0])
			{
				$sheet1 = $$plane2{sheet};
			}
			if ($$plane2{name} eq $plane)
			{
				$sheet2 = $$plane2{sheet};
			}
		}
	}
	
	return $sheet1 < $sheet2;
}

=head2 determine_the_coordinates_of_additional_points_for_overlaps

It creates two additional overlap points and calculates their coordinates.

=cut
sub determine_the_coordinates_of_additional_points_for_overlaps
{
	my ($this, $plane, $vertex1, $vertex2, $alpha, $coordinates_ref) = @_;
	
	my ($edge) = $this->get_solution(__LINE__, "EDGE", "belongs_to($vertex1, EDGE), belongs_to($vertex2, EDGE)");
	
	croak "cannot find common edge" unless defined($edge);
	
	if ($this->make_decision_whether_to_do_an_overlap($plane, $vertex1, $vertex2))
	{
		my $w1 = $edge."_".$vertex1."_overlap_point";
		my $w2 = $edge."_".$vertex2."_overlap_point";
				
		$$this{description} .= <<INFORMATION_ABOUT_OVERLAP;
there_is_an_overlap($plane, $vertex1, $vertex2, $w1, $w2).
INFORMATION_ABOUT_OVERLAP


		my $dx = $$coordinates_ref{$plane.$vertex2}{x}-$$coordinates_ref{$plane.$vertex1}{x};
		my $dy = $$coordinates_ref{$plane.$vertex2}{y}-$$coordinates_ref{$plane.$vertex1}{y};
			
		$this->set_the_point_coordinates($coordinates_ref, $plane, $w2, 
					$$coordinates_ref{$plane.$vertex2}{x} + sin(($alpha-90-45)*3.14159/180)*10,
					$$coordinates_ref{$plane.$vertex2}{y} + cos(($alpha-90-45)*3.14159/180)*10);

		$this->set_the_point_coordinates($coordinates_ref, $plane, $w1, 
					$$coordinates_ref{$plane.$vertex1}{x} + sin(($alpha-45)*3.14159/180)*10,
					$$coordinates_ref{$plane.$vertex1}{y} + cos(($alpha-45)*3.14159/180)*10);
	}				
}

=head2 determine_the_coordinates_of_planes_adjacent_to_the_edge

Given an edge of a plane it determines the coordinates of the vertices of the planes adjacent to it.

=cut
sub determine_the_coordinates_of_planes_adjacent_to_the_edge
{
	my ($this, $plane, $vertex1, $vertex2, $alpha, $knowledge_about_processed_planes, $coordinates_ref) = @_;

	my @planes = 
	grep
	{ 
		my $name = $_; 
		grep 
		{ 
			my $solid = $_; 
			grep { $$_{active} && $$_{name} eq $name } @{$$solid{planes}} 
		} 
		@{$$this{solids}}
	}
	$this->get_solution(__LINE__,"PLANE", <<CONDITION
belongs_to($vertex1, EDGE),
belongs_to($vertex2, EDGE),	
belongs_to(EDGE, PLANE), 
belongs_to(EDGE, $plane),
not(eq(PLANE, $plane)),
is_visible(PLANE), 
is_a_Polygon(PLANE), 
is_connected_in_lattice(PLANE, $plane),
not(plane_has_been_processed(PLANE))
CONDITION
	, "$knowledge_about_processed_planes\nis_connected_to_lattice(some_plane1, some_plane2).\n");


	if (@planes)
	{
		my $plane2 = $planes[0];	
		
		my @vertices = $this->get_solution(__LINE__,"POINT", "belongs_to(POINT, EDGE), belongs_to(EDGE, $plane2)");
		
		$$coordinates_ref{$plane2.$vertex1}{x} = $$coordinates_ref{$plane.$vertex1}{x};		
		$$coordinates_ref{$plane2.$vertex1}{y} = $$coordinates_ref{$plane.$vertex1}{y};		
		$$coordinates_ref{$plane2.$vertex2}{x} = $$coordinates_ref{$plane.$vertex2}{x};
		$$coordinates_ref{$plane2.$vertex2}{y} = $$coordinates_ref{$plane.$vertex2}{y};

		croak "unknown x in ".$plane2.$vertex1 unless defined($$coordinates_ref{$plane2.$vertex1}{x});
		croak "unknown y in ".$plane2.$vertex1 unless defined($$coordinates_ref{$plane2.$vertex1}{y});
		croak "unknown x in ".$plane2.$vertex2 unless defined($$coordinates_ref{$plane2.$vertex2}{x});
		croak "unknown y in ".$plane2.$vertex2 unless defined($$coordinates_ref{$plane2.$vertex2}{y});
				
		$this->determine_the_coordinates_beginning_at($plane2, $vertex2, 
			$$coordinates_ref{$plane.$vertex2}{x}, 
			$$coordinates_ref{$plane.$vertex2}{y},
			$vertex1, $alpha+180.0, scalar(@vertices), 
			$knowledge_about_processed_planes, <<KNOWLEDGE_ABOUT_PROCESSED_VERTICES, $coordinates_ref);
vertex_has_been_processed($vertex2).
vertex_has_been_processed($vertex1).
KNOWLEDGE_ABOUT_PROCESSED_VERTICES
	}
}


=head2 determine_the_coordinates_beginning_at

Determine the coordinates of the vertices beginning at the first and second one.

=cut
sub determine_the_coordinates_beginning_at
{
	my ($this, $plane, $first, $x, $y, $second, $alpha, $amount_of_vertices, $knowledge_about_processed_planes, 
		$knowledge_about_processed_vertices, $coordinates_ref) = @_;
		
	$this->set_the_point_coordinates($coordinates_ref, $plane, $first, $x, $y);
	
	my ($length) = $this->get_solution(__LINE__, "LENGTH", "has_length(EDGE, LENGTH), belongs_to($first, EDGE), belongs_to($second, EDGE)");
	
	$knowledge_about_processed_planes .= "plane_has_been_processed($plane).\n";

	$x += sin($alpha*3.14159/180)*$length;
	$y += cos($alpha*3.14159/180)*$length;

	$this->set_the_point_coordinates($coordinates_ref, $plane, $second, $x, $y);
	
	$this->determine_the_coordinates_of_additional_points_for_overlaps($plane, $first, $second, $alpha, $coordinates_ref);

	$this->determine_the_coordinates_of_planes_adjacent_to_the_edge($plane, $first, 
		$second, $alpha, $knowledge_about_processed_planes, $coordinates_ref);

	my $subsequent = $second;
	
	for my $i (3..$amount_of_vertices)
	{
		my $previous = $subsequent;
		
		($subsequent) = $this->get_solution(__LINE__,"NEIGHBOUR", <<CONDITION, $knowledge_about_processed_vertices);
is_a_Point(NEIGHBOUR), belongs_to(NEIGHBOUR, EDGE), belongs_to(EDGE, $plane), not(vertex_has_been_processed(NEIGHBOUR)), belongs_to($previous, EDGE)
CONDITION

		croak "could not find another vertex" unless $subsequent;

		my ($internal_angle) = $this->get_solution(__LINE__,"INTERNAL_ANGLE", "is_an_InternalAngle($plane, $previous, INTERNAL_ANGLE)");

		unless (defined($internal_angle))
		{
			croak "no internal angle in $plane at $previous";
		}
		$alpha += 180.0-$internal_angle;

		my ($length) = $this->get_solution(__LINE__, "LENGTH", "has_length(EDGE, LENGTH), belongs_to($subsequent, EDGE), belongs_to($previous, EDGE)");
	
		$x += sin($alpha*3.14159/180)*$length;
		$y += cos($alpha*3.14159/180)*$length;

		$this->set_the_point_coordinates($coordinates_ref, $plane, $subsequent, $x, $y);

		$knowledge_about_processed_vertices .= "vertex_has_been_processed($subsequent).\n";

		$this->determine_the_coordinates_of_additional_points_for_overlaps($plane, $previous, $subsequent, $alpha, $coordinates_ref);

		$this->determine_the_coordinates_of_planes_adjacent_to_the_edge($plane, $previous, $subsequent, $alpha, $knowledge_about_processed_planes, $coordinates_ref);
	}

	my ($internal_angle) = $this->get_solution(__LINE__,"INTERNAL_ANGLE", "is_an_InternalAngle($plane, $subsequent, INTERNAL_ANGLE)");
	
	unless (defined($internal_angle))
	{
		croak "no internal angle in $plane at $subsequent";
	}

	$alpha += 180.0-$internal_angle;
	
	$this->determine_the_coordinates_of_additional_points_for_overlaps($plane, $subsequent, $first, $alpha, $coordinates_ref);

	$this->determine_the_coordinates_of_planes_adjacent_to_the_edge($plane, $subsequent, $first, $alpha, $knowledge_about_processed_planes, $coordinates_ref);
}

=head2 determine_the_coordinates

Determine the coordinates of the vertices of the first visible plane (and the others).

=cut
sub determine_the_coordinates
{
	my $this = shift;
	my %coordinates = ();
	my @planes = 
	grep
	{
		my $plane = $_;
		grep 
		{
			my $solid = $_;
			grep
			{
				$$_{active} && $$_{name} eq $plane
			}
			@{$$solid{planes}}
		} @{$$this{solids}}
	}
	$this->get_solution(__LINE__,"PLANE", "is_visible(PLANE), is_a_Polygon(PLANE)");

	unless (@planes)
	{
		croak "there are no visible planes";
	}

	my $plane = $planes[0];

	my @vertices = $this->get_solution(__LINE__,"POINT", "belongs_to(POINT, EDGE), belongs_to(EDGE, $plane)");

	my $first = $vertices[0];

	my @neighbours = $this->get_solution(__LINE__,"NEIGHBOUR", <<CONDITION);
is_a_Point(NEIGHBOUR), belongs_to(NEIGHBOUR, EDGE), belongs_to($first, EDGE), belongs_to(EDGE, $plane), not(eq(NEIGHBOUR,$first))
CONDITION


	my $second = $this->select_the_second_point_when_determining_the_coordinates($plane, $first, \@neighbours);
		
	$this->determine_the_coordinates_beginning_at($plane, $first, 100, 400, $second, 0, scalar(@vertices), "",  <<KNOWLEDGE_ABOUT_PROCESSED_VERTICES, \%coordinates);
vertex_has_been_processed($first).
vertex_has_been_processed($second).
KNOWLEDGE_ABOUT_PROCESSED_VERTICES

	$$this{coordinates} = \%coordinates;
}

=head2 select_the_second_point_when_determining_the_coordinates

Given a plane and its vertex (first) select randomly another vertex adjacent to it.

=cut
sub select_the_second_point_when_determining_the_coordinates
{
	my ($this, $plane, $first, $neighbours_ref) = @_;

	my @solids =
		grep 
		{
			my $solid = $_;
			grep
			{
				$$_{active} && $$_{name} eq $plane
			}
			@{$$solid{planes}}
		} @{$$this{solids}};

	my @planes = 
		grep
		{
			$$_{active} && $$_{name} eq $plane
		}
	@{$solids[0]{planes}};

	croak "there should be only one plane!" unless scalar(@planes) == 1;

	if (exists($planes[0]{rotation}))
	{
		my @rotation = map { $$_{name} } grep { defined($_) } @{$planes[0]{rotation}};
		my ($index) = grep { $rotation[$_] eq $first } 0..$#rotation;
		$index = ($index+1)%4;
		return $rotation[$index];
	}

	return $$neighbours_ref[int(rand() % scalar(@$neighbours_ref))];
}

=head2 create_a_lattice

Creates a lattice for the given model.

=cut
sub create_a_lattice
{
	my $this = shift;

	my @planes = grep 
	{ 
		my $name = $_; 
		grep 
		{ 
			my $solid = $_; 
			grep { $$_{active} && $$_{name} eq $name } @{$$solid{planes}} 
		} 
		@{$$this{solids}}
	} $this->get_planes();
	
	my $knowledge_about_visible_planes;
	
	$knowledge_about_visible_planes = join("", map { "is_visible($_).\n" } $this->get_solution(__LINE__,"PLANE", <<CONDITION));
is_a_Polygon(PLANE), belongs_to(PLANE, SOLID), belongs_to(SOLID, $$this{name})
CONDITION

	$this->add_knowledge($knowledge_about_visible_planes);

	my @visible_planes = grep 
	{ 
		my $name = $_; 
		grep 
		{ 
			my $solid = $_; 
			grep { $$_{active} && $$_{name} eq $name } @{$$solid{planes}} 
		}
		@{$$this{solids}}
	} $this->get_solution(__LINE__,"PLANE", "is_visible(PLANE)");

	return 1 unless @visible_planes;

	$this->find_common_edges();
	$this->find_internal_angles();

	return $this->add_to_lattice($visible_planes[0], "", "", [], 0, []);
}

=head2 find_common_edges

Stores the knowledge about common edges of visible planes in a separate structure so that we do not need to
call Prolog afterwards.

=cut
sub find_common_edges
{
	my $this = shift;

	$$this{knowledge_about_common_edges_of_visible_planes} = undef;

	my @pairs = $this->get_solution_n(__LINE__, ["A", "B", "EDGE", "LENGTH", "POINT", "INTERNAL_ANGLE"], 
		"is_a_Stretch(EDGE), belongs_to(EDGE, A), belongs_to(EDGE, B), not(eq(A, B)), is_visible(A), is_visible(B), has_length(EDGE, LENGTH), is_a_Point(POINT), belongs_to(POINT, EDGE), is_an_InternalAngle(A, POINT, INTERNAL_ANGLE)");

	for my $p (map { [ split / /, $_ ] } @pairs)
	{
		push @{$$this{knowledge_about_common_edges_of_visible_planes}{$$p[0]}{$$p[1]}}, 
			{
				plane1 => $$p[0],
				plane2 => $$p[1],
				common_edge => $$p[2],
				length => $$p[3],
				point => $$p[4],
				internal_angle => $$p[5]
			};
	}
}

=head2 find_internal_angles

Stores the knowledge about internal angles in a separate structure.

=cut
sub find_internal_angles
{
	my $this = shift;

	$$this{knowledge_about_internal_angles} = undef;

	my @pairs = $this->get_solution_n(__LINE__, ["A", "POINT", "INTERNAL_ANGLE"], 
		"is_visible(A), is_a_Point(POINT), belongs_to(POINT, EDGE), belongs_to(EDGE, A), is_an_InternalAngle(A, POINT, INTERNAL_ANGLE)");

	for my $p (map { [ split / /, $_ ] } @pairs)
	{
		push @{$$this{knowledge_about_internal_angles}{$$p[0]}{$$p[1]}}, 
			{
				plane1 => $$p[0],
				point => $$p[1],
				internal_angle => $$p[2]
			};
	}
}

=head2 add_to_lattice

Finds te candidates and adds them to the lattice.

=cut
sub add_to_lattice
{
	my ($this, 
		$plane, 
		$knowledge_about_planes_connected_to_lattice, 
		$knowledge_about_connections_between_planes, 
		$list_of_planes_connected_to_lattice_ref, 
		$depth, 
		$list_of_connected_planes_ref) = @_;

	$knowledge_about_planes_connected_to_lattice .= "is_connected_to_lattice($plane).\n";

	my @candidates = 
	grep
	{ 
		my $name = $_; 
		grep 
		{ 
			my $solid = $_; 
			grep { $$_{active} && $$_{name} eq $name } @{$$solid{planes}} 
		} 
		@{$$this{solids}}
	}
	$this->get_candidates($plane, $knowledge_about_planes_connected_to_lattice, $knowledge_about_connections_between_planes, [@$list_of_planes_connected_to_lattice_ref, $plane]);
	
	if (@candidates)
	{
		return 1 if $this->add_to_lattice_subsequent_candidates($plane, 
			$knowledge_about_planes_connected_to_lattice, 
			$knowledge_about_connections_between_planes, 
			$list_of_planes_connected_to_lattice_ref, 
			$depth, 
			$list_of_connected_planes_ref,
			\@candidates);
			
		croak "failed to add candidates to plane $plane";
	}
	else
	{
		my $all = $this->get_have_all_planes_been_connected($knowledge_about_planes_connected_to_lattice, $knowledge_about_connections_between_planes, [$plane, @$list_of_planes_connected_to_lattice_ref]);

		if (!$all)
		{
			croak "not all planes have been connected";
			return 0;
		}
		$this->add_knowledge($knowledge_about_connections_between_planes);
		return 1;
	}

	return 0;
}

=head2 get_common_edge


=cut
sub get_common_edge
{
	my ($this, $candidate, $knowledge_about_planes_connected_to_lattice, $list_of_planes_connected_to_lattice_ref) = @_;

	for my $plane (@$list_of_planes_connected_to_lattice_ref)
	{
		if ($$this{knowledge_about_common_edges_of_visible_planes}{$plane}{$candidate})
		{
			for my $i (0..$#{$$this{knowledge_about_common_edges_of_visible_planes}{$plane}{$candidate}})
			{
				return  $$this{knowledge_about_common_edges_of_visible_planes}{$plane}{$candidate}[$i]{common_edge};
			}
		}

		for my $k (keys %{$$this{knowledge_about_common_edges_of_visible_planes}{$plane}})
		{
			for my $i (0..$#{$$this{knowledge_about_common_edges_of_visible_planes}{$plane}{$k}})
			{
				return  $$this{knowledge_about_common_edges_of_visible_planes}{$plane}{$k}[$i]{common_edge};
			}
		}
	}

	return undef;
}

=head2 get_vertex_planes_if_candidate_is_connected

=cut
sub get_vertex_planes_if_candidate_is_connected
{
	my ($this, $candidate, $vertex, $knowledge_about_planes_connected_to_lattice, $list_of_planes_connected_to_lattice_ref) = @_;

	my @planes = ();

	for my $plane (@$list_of_planes_connected_to_lattice_ref, $candidate)
	{
		for my $i (0..$#{$$this{knowledge_about_internal_angles}{$plane}{$vertex}})
		{
			if ($$this{knowledge_about_internal_angles}{$plane}{$vertex}[$i]{point} eq $vertex)
			{
				push @planes, $plane unless grep { $_ eq $plane } @planes;
			}
		}
	}

	if (@planes)
	{
		return @planes;
	}
	return undef;
}

=head2 get_is_connected_with

Returns true if and only if the two planes are identical.

=cut
sub get_is_connected_with
{
	my ($this, $s1, $s0, $list_of_connected_planes_ref) = @_;

	if ($s0 eq $s1)
	{
		return 1;
	}
	
	return 0;
}


=head2 get_internal_angle

Returns the internal angle given a plane and vertex.

=cut
sub get_internal_angle
{
	my ($this, $s, $vertex) = @_;

	for my $i (0..$#{$$this{knowledge_about_internal_angles}{$s}{$vertex}})
	{
		if ($$this{knowledge_about_internal_angles}{$s}{$vertex}[$i]{point} eq $vertex)
		{
			return $$this{knowledge_about_internal_angles}{$s}{$vertex}[$i]{internal_angle};
		}
	}
	return undef;
}

=head2 get_can_candidate_be_connected_to_lattice_check_vertex_and_plane

Checks whether a candidate can be connected to the lattice. It calculates the sum of internal angles
adjacent to a vertex and responds true if and only if it is not greater than 360 degrees.

=cut
sub get_can_candidate_be_connected_to_lattice_check_vertex_and_plane
{
	my ($this, 
		$plane, 
		$candidate, 
		$vertex, 
		$knowledge_about_planes_connected_to_lattice,
		$list_of_planes_connected_to_lattice_ref, 
		$list_of_connected_planes_ref, 
		$common_edge_vertices_ref, 
		$common_edge, 
		$planes_of_vertex_ref, 
		$s0) = @_;

	my $sum_of_angles = 0;
	for my $s (grep { $this->get_is_connected_with($_, $s0, $list_of_connected_planes_ref) } @$planes_of_vertex_ref)
	{
		my $internal_angle = $this->get_internal_angle($s, $vertex);

		unless (defined($internal_angle))
		{
			croak "missing internal angle in $s at vertex $vertex";
		} 
		$sum_of_angles += $internal_angle;
	}

	if ($sum_of_angles > 360.0)
	{
		return 0;
	}

	return 1;
}

=head2 get_can_candidate_be_connected_to_lattice_check_vertex

Checks whether a candidate plane can be connected to the lattice. It checks the vertex.

=cut
sub get_can_candidate_be_connected_to_lattice_check_vertex
{
	my ($this, 
		$plane, 
		$candidate, 
		$vertex, 
		$knowledge_about_planes_connected_to_lattice,
		$list_of_planes_connected_to_lattice_ref, 
		$list_of_connected_planes_ref, 
		$common_edge_vertices_ref, 
		$common_edge) = @_;

	my @vertex_planes = $this->get_vertex_planes_if_candidate_is_connected(
		$candidate, 
		$vertex, 
		$knowledge_about_planes_connected_to_lattice, 
		$list_of_planes_connected_to_lattice_ref);

	for my $s0 (@vertex_planes)
	{
		if (!$this->get_can_candidate_be_connected_to_lattice_check_vertex_and_plane(
			$plane, 
			$candidate, 
			$vertex, 
			$knowledge_about_planes_connected_to_lattice,
			$list_of_planes_connected_to_lattice_ref, 
			$list_of_connected_planes_ref, 
			$common_edge_vertices_ref, 
			$common_edge, 
			\@vertex_planes, $s0))
		{
			return 0;
		}
	}

	return 1;
}


=head2 get_can_candidate_be_connected_to_lattice

Checks whether a candidate plane can be connected to lattice.

=cut
sub get_can_candidate_be_connected_to_lattice
{
	my ($this, 
		$plane, 
		$candidate, 
		$knowledge_about_planes_connected_to_lattice, 
		$knowledge_about_connections_between_planes, 
		$list_of_planes_connected_to_lattice_ref, 
		$list_of_connected_planes_ref) = @_;

	my ($common_edge) = $this->get_common_edge($candidate,
		$knowledge_about_planes_connected_to_lattice,
		$list_of_planes_connected_to_lattice_ref);

	croak "something is wrong" unless $common_edge;

	my @common_edge_vertices = $this->get_common_edge_vertices($candidate, $common_edge);

	for my $vertex (@common_edge_vertices)
	{
		if (!$this->get_can_candidate_be_connected_to_lattice_check_vertex($plane, $candidate,
			$vertex, $knowledge_about_planes_connected_to_lattice, $list_of_planes_connected_to_lattice_ref,
			$list_of_connected_planes_ref, \@common_edge_vertices, $common_edge))
		{
			return 0;
		}
	}

	return 1;
}

=head2 get_common_edge_vertices

Returns the vertices of an edge.

=cut
sub get_common_edge_vertices
{
	my ($this, $candidate, $common_edge) = @_;

	my @points = ();

	for my $k (keys %{$$this{knowledge_about_common_edges_of_visible_planes}{$candidate}})
	{
		for my $i (grep { $$this{knowledge_about_common_edges_of_visible_planes}{$candidate}{$k}[$_]{common_edge} eq $common_edge } 
			0..$#{$$this{knowledge_about_common_edges_of_visible_planes}{$candidate}{$k}})
		{
			push @points, $$this{knowledge_about_common_edges_of_visible_planes}{$candidate}{$k}[$i]{point}
				unless grep { $_ eq $$this{knowledge_about_common_edges_of_visible_planes}{$candidate}{$k}[$i]{point} } @points;
		}
	}
	return @points if @points;

	return undef;
}

=head2 get_common_edge_length

Given two planes it returns the length of the common edge.

=cut
sub get_common_edge_length
{
	my ($this, $plane, $candidate) = @_;

	for my $i (0..$#{$$this{knowledge_about_common_edges_of_visible_planes}{$plane}{$candidate}})
	{
		return $$this{knowledge_about_common_edges_of_visible_planes}{$plane}{$candidate}[$i]{length};
	}
	return undef;
}


=head2 add_to_lattice_subsequent_candidates

Adds subsequent candidate planes to the lattice.

=cut
sub add_to_lattice_subsequent_candidates
{
	my ($this, 
		$plane, 
		$knowledge_about_planes_connected_to_lattice, 
		$knowledge_about_connections_between_planes, 
		$list_of_planes_connected_to_lattice_ref, 
		$depth, 
		$list_of_connected_planes_ref,
		$candidates_ref) = @_;

	my %common_edge_length = ();

	for my $candidate (@$candidates_ref)
	{
		my ($length) = $this->get_common_edge_length($plane, $candidate);
		croak "no common edge found between $plane and $candidate" unless defined($length);
		$common_edge_length{$candidate} = $length;
	}

	my @candidates = reverse sort { $common_edge_length{$a} <=> $common_edge_length{$b} } @$candidates_ref;
		
	for my $candidate (@candidates)
	{
		if ($this->get_can_candidate_be_connected_to_lattice($plane, $candidate, 
				$knowledge_about_planes_connected_to_lattice, $knowledge_about_connections_between_planes,
				,[$plane, @$list_of_planes_connected_to_lattice_ref],
				[@$list_of_connected_planes_ref, { $candidate => $plane, $plane => $candidate } ]))
		{
			return 1 if $this->add_to_lattice($candidate, $knowledge_about_planes_connected_to_lattice, $knowledge_about_connections_between_planes.<<ADDITION
is_connected_in_lattice($plane, $candidate).
is_connected_in_lattice($candidate, $plane).
ADDITION
					,[$plane, @$list_of_planes_connected_to_lattice_ref], $depth+1,
					[@$list_of_connected_planes_ref, { $candidate => $plane, $plane => $candidate }]);
		}
	}

	return 0;
}

=head2 get_have_all_planes_been_connected

Checks whether all the planes have been connected.

=cut
sub get_have_all_planes_been_connected
{
	my ($this, $knowledge_about_planes_connected_to_lattice, $knowledge_about_connections_between_planes, $list_of_planes_connected_to_lattice_ref) = @_;

	my @list_of_active_planes = 
	grep
	{
		my $name = $_; 
		grep 
		{ 
			my $solid = $_; 
			grep { $$_{active} && $$_{name} eq $name } @{$$solid{planes}} 
		} 
		@{$$this{solids}}
	}
	keys %{$$this{knowledge_about_common_edges_of_visible_planes}};

	if (scalar(@$list_of_planes_connected_to_lattice_ref) > scalar(@list_of_active_planes))
	{
		croak "more planes have been connected than should have been!";
	}
	
	return scalar(@$list_of_planes_connected_to_lattice_ref) == scalar(@list_of_active_planes);
}

=head2 get_angle_between_vectors

Calculates an angle between two vectors (in degrees).

=cut
sub get_angle_between_vectors
{
	my $this = shift;
	my ($p0, $p1, $q0) = @_;

	my $va =
	{
		x => $$p1{x}-$$p0{x},
		y => $$p1{y}-$$p0{y},
		z => $$p1{z}-$$p0{z}
	};

	my $vb =
	{
		x => $$q0{x}-$$p0{x},
		y => $$q0{y}-$$p0{y},
		z => $$q0{z}-$$p0{z}
	};

	my $vc =
	{
		x => $$p1{x}-$$q0{x},
		y => $$p1{y}-$$q0{y},
		z => $$p1{z}-$$q0{z}
	};

	my $a = sqrt($$va{x}*$$va{x}+$$va{y}*$$va{y}+$$va{z}*$$va{z});
	my $b = sqrt($$vb{x}*$$vb{x}+$$vb{y}*$$vb{y}+$$vb{z}*$$vb{z});
	my $c = sqrt($$vc{x}*$$vc{x}+$$vc{y}*$$vc{y}+$$vc{z}*$$vc{z});

	my $r = ($a*$a+$b*$b-$c*$c)/2.0/$a/$b;

	return rad2deg(acos($r));
}

=head2 get_distance

Calculates the distance between two points.

=cut
sub get_distance
{
	my $this = shift;
	my ($a, $b) = @_;
	return sqrt(($$a{x}-$$b{x})*($$a{x}-$$b{x})
				+($$a{y}-$$b{y})*($$a{y}-$$b{y})
				+($$a{z}-$$b{z})*($$a{z}-$$b{z}));
}

=head2 activate_the_planes_of

Activates the planes of the given sheet.

=cut

sub activate_the_planes_of
{
	my ($this, $sheet) = @_;

	for my $solid (@{$$this{solids}})
	{
		for my $plane (@{$$solid{planes}})
		{
			$$plane{active} = ($$plane{sheet} == $sheet);
		}
	}
}

=head2 scale_the_lattice

Scales the lattice.

=cut
sub scale_the_lattice
{
	my ($this, $x1, $y1, $x2, $y2, $scale) = @_;

	$this->rotate_lattice_optimally($x1, $y1, $x2, $y2);
	
	my @keys_of_the_active_planes_coordinates = 
		grep
		{
			my $coordinate_name = $_;
			grep 
			{
				my $solid = $_;
				grep
				{
					$$_{active} && $coordinate_name =~ /^$$_{name}/
				}
				@{$$solid{planes}}
			} @{$$this{solids}}
		}
		keys %{$$this{coordinates}};

	return 1 unless @keys_of_the_active_planes_coordinates;

	my @x = sort { $a <=> $b } map { $$this{coordinates}{$_}{x} } @keys_of_the_active_planes_coordinates;
	my @y = sort { $a <=> $b } map { $$this{coordinates}{$_}{y} } @keys_of_the_active_planes_coordinates;
		
	my $mx = ($x2-$x1)/($x[-1]-$x[0]);
	my $my = ($y2-$y1)/($y[-1]-$y[0]);
			
	my $m = $mx > $my ? $my : $mx;		
	
	if (defined($scale))
	{
		if ($m < $scale)
		{
			croak "max scale is $m, required $scale";
		}
		$m = $scale;
	}
	
	for my $k (@keys_of_the_active_planes_coordinates)
	{
		$$this{coordinates}{$k}{x} -= $x[0];
		$$this{coordinates}{$k}{x} *= $m;
		$$this{coordinates}{$k}{x} += $x1;
		$$this{coordinates}{$k}{y} -= $y[0];
		$$this{coordinates}{$k}{y} *= $m;
		$$this{coordinates}{$k}{y} += $y1;
	}

	$$this{scale} = $m;
	return 1;
}

=head2 rotate_lattice_optimally

Finds the optimal angle to rotate the active planes coordinates.

=cut
sub rotate_lattice_optimally
{
	my ($this, $x1, $y1, $x2, $y2) = @_;
	local $_;

	my $optimal_alpha = undef;
	my $optimal_m = undef;

	my @keys_of_the_active_planes_coordinates = 
		grep
		{
			my $coordinate_name = $_;

			defined($$this{coordinates}{$_}{x})
			&& defined($$this{coordinates}{$_}{y})
			&& grep 
			{
				my $solid = $_;
				grep
				{
					$$_{active} && $coordinate_name =~ /^$$_{name}/
				}
				@{$$solid{planes}}
			} @{$$this{solids}}
		}
		keys %{$$this{coordinates}};

	return unless @keys_of_the_active_planes_coordinates;

	for my $alpha (map { $_*10 } 0..35)
	{
		my @x = sort { $a <=> $b } map { cos($alpha*3.14159/180)*$$this{coordinates}{$_}{x}-sin($alpha*3.14159/180)*$$this{coordinates}{$_}{y} } @keys_of_the_active_planes_coordinates;
		my @y = sort { $a <=> $b } sort map { cos($alpha*3.14159/180)*$$this{coordinates}{$_}{y}+sin($alpha*3.14159/180)*$$this{coordinates}{$_}{x} } @keys_of_the_active_planes_coordinates;

		my $mx = ($x2-$x1)/($x[-1]-$x[0]);
		my $my = ($y2-$y1)/($y[-1]-$y[0]);

		my $m = $mx > $my ? $my : $mx;		
		
		if (!defined($optimal_m) || $optimal_m < $m)
		{
			$optimal_alpha = $alpha;
			$optimal_m = $m;
		}

	}

	my $alpha = $optimal_alpha;
	for (@keys_of_the_active_planes_coordinates)
	{
		my ($nx, $ny) = (cos($alpha*3.14159/180)*$$this{coordinates}{$_}{x}-sin($alpha*3.14159/180)*$$this{coordinates}{$_}{y},
				cos($alpha*3.14159/180)*$$this{coordinates}{$_}{y}+sin($alpha*3.14159/180)*$$this{coordinates}{$_}{x});

		$$this{coordinates}{$_}{x} = $nx;
		$$this{coordinates}{$_}{y} = $ny;
	}
}

=head2 get_coordinate

Returns the coordinate of a point.

=cut
sub get_coordinate
{
	my ($this, $plane, $point, $coordinate) = @_;

	return $$this{coordinates}{$plane.$point}{$coordinate} if defined($$this{coordinates}{$plane.$point}{$coordinate});

	croak "undefined coordinate for ${plane}${point}";
}

=head2 draw_overlap_lines


=cut
sub draw_overlap_lines
{
	my ($this, $plane, $edge, $points_ref, $x1, $y1, $x2, $y2) = @_;

	my @points = @$points_ref;

	my ($t1) = $this->get_solution(__LINE__, "'true'", "there_is_an_overlap($plane, $points[0], $points[1], _, _)", "there_is_an_overlap(some_plane, some_point, some_point, something, something).");
			
	if ($t1)
	{
		my $w1 = $edge."_".$points[0]."_overlap_point";
		my $w2 = $edge."_".$points[1]."_overlap_point";
								
		my ($xw1, $yw1) = map { int($this->get_coordinate($plane, $w1, $_)+0.5) } qw/x y/;
		my ($xw2, $yw2) = map { int($this->get_coordinate($plane, $w2, $_)+0.5) } qw/x y/;
				
		croak "missing xw1" unless defined($this->get_coordinate($plane, $w1, "x"));
		croak "missing yw1" unless defined($this->get_coordinate($plane, $w1, "y"));
		croak "missing xw2" unless defined($this->get_coordinate($plane, $w2, "x"));
		croak "missing yw2" unless defined($this->get_coordinate($plane, $w2, "y"));
																
		$$this{img}->moveTo($x1, $y1);
		$$this{img}->lineTo($xw1, $yw1);
		$$this{img}->lineTo($xw2, $yw2);
		$$this{img}->lineTo($x2, $y2);							
	}
	else
	{

		my ($t2) = $this->get_solution(__LINE__, "'true'", "there_is_an_overlap($plane, $points[1], $points[0], _, _)", "there_is_an_overlap(some_plane, some_point, some_point, something, something).");

		if ($t2)
		{
			my $w1 = $edge."_".$points[1]."_overlap_point";
			my $w2 = $edge."_".$points[0]."_overlap_point";
								
			my ($xw1, $yw1) = map { int($this->get_coordinate($plane, $w1, $_)+0.5) } qw/x y/;
			my ($xw2, $yw2) = map { int($this->get_coordinate($plane, $w2, $_)+0.5) } qw/x y/;
				
			croak "missing xw1" unless defined($this->get_coordinate($plane, $w1, "x"));
			croak "missing yw1" unless defined($this->get_coordinate($plane, $w1, "y"));
			croak "missing xw2" unless defined($this->get_coordinate($plane, $w2, "x"));
			croak "missing yw2" unless defined($this->get_coordinate($plane, $w2, "y"));
								
			$$this{img}->moveTo($x2, $y2);
			$$this{img}->lineTo($xw1, $yw1);
			$$this{img}->lineTo($xw2, $yw2);
			$$this{img}->lineTo($x1, $y1);						
		}
	}
}

=head2 draw_lines

Draws the lines of the visible planes.

=cut
sub draw_lines
{
	my $this = shift;

	my @planes = 
	grep
	{
		my $plane = $_;
		grep 
		{
			my $solid = $_;
			grep
			{
				$$_{active} && $$_{name} eq $plane
			}
			@{$$solid{planes}}
		} @{$$this{solids}}
	}
	$this->get_solution(__LINE__, "PLANE", "is_visible(PLANE)");
	
	$$this{img}->colorClosest(0,0,0); 	
	
	for my $plane (@planes)
	{
		my @edges = $this->get_solution(__LINE__, "EDGE", "belongs_to(EDGE, $plane)");		
		for my $edge (@edges)
		{
			my @points = $this->get_solution(__LINE__, "POINT", "belongs_to(POINT, $edge)");

			confess "x does not exist for $points[0] in $plane" unless defined($this->get_coordinate($plane, $points[0], "x"));
			confess "y does not exist for $points[0] in $plane" unless defined($this->get_coordinate($plane, $points[0], "y"));
			confess "x does not exist for $points[1] in $plane" unless defined($this->get_coordinate($plane, $points[1], "x"));
			confess "y does not exist for $points[1] in $plane" unless defined($this->get_coordinate($plane, $points[1], "y"));

			my ($x1, $y1) = map { int($this->get_coordinate($plane, $points[0], $_)+0.5) } qw/x y/;
			my ($x2, $y2) = map { int($this->get_coordinate($plane, $points[1], $_)+0.5) } qw/x y/;
			
			if ($$this{add_description})
			{
				local $_;
				$$this{img}->moveTo($x1, $y1);
				$_ = $points[0];
				s/^alpha_//;
				$$this{img}->string($_);
				$$this{img}->moveTo($x2, $y2);
				$_ = $points[1];
				s/^alpha_//;
				$$this{img}->string($_);
			}

			$$this{img}->moveTo($x1, $y1);
			$$this{img}->lineTo($x2, $y2);
			
			$this->draw_overlap_lines($plane, $edge, \@points, $x1, $y1, $x2, $y2);
		}
	}	
}

1;
