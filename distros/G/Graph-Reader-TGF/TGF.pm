package Graph::Reader::TGF;

use base qw(Graph::Reader);
use strict;
use warnings;

use Encode qw(decode_utf8);
use Error::Pure qw(err);

our $VERSION = 0.04;

# Edge callback.
sub _edge_callback {
	my ($self, $graph, $id1, $id2, $edge_label) = @_;
	$graph->set_edge_attribute($id1, $id2, 'label', $edge_label);
	return;
}

# Init.
sub _init {
	my ($self, $param_hr) = @_;
	$self->SUPER::_init();
	if (exists $param_hr->{'edge_callback'}
		&& defined $param_hr->{'edge_callback'}
		&& ref $param_hr->{'edge_callback'} ne 'CODE') {

		err "Parameter 'edge_callback' isn't reference to code.";
	}
	$self->{'edge_callback'} = $param_hr->{'edge_callback'};
	if (exists $param_hr->{'vertex_callback'}
		&& defined $param_hr->{'vertex_callback'}
		&& ref $param_hr->{'vertex_callback'} ne 'CODE') {

		err "Parameter 'vertex_callback' isn't reference to code.";
	}
	$self->{'vertex_callback'} = $param_hr->{'vertex_callback'};
	return;
}

# Read graph subroutine.
sub _read_graph {
	my ($self, $graph, $fh) = @_;
	my $vertexes = 1;
	while (my $line = decode_utf8(<$fh>)) {
		chomp $line;

		# End of vertexes section.
		if ($line =~ m/^#/ms) {
			$vertexes = 0;
			next;
		}

		# Vertexes.
		if ($vertexes) {
			my ($id, $vertex_label) = split m/\s+/ms, $line, 2;
			if (! defined $vertex_label) {
				$vertex_label = $id;
			}
			$graph->add_vertex($id);
			if ($self->{'vertex_callback'}) {
				$self->{'vertex_callback'}->($self, $graph,
					$id, $vertex_label);
			} else {
				$self->_vertex_callback($graph, $id,
					$vertex_label);
			}

		# Edges.
		} else {
			my ($id1, $id2, $edge_label) = split m/\s+/ms, $line, 3;
			$graph->add_edge($id1, $id2);
			if ($self->{'edge_callback'}) {
				$self->{'edge_callback'}->($self, $graph, $id1,
					$id2, $edge_label);
			} else {
				$self->_edge_callback($graph, $id1, $id2,
					$edge_label);
			}
		}
		
	}
	return;
}

# Vertex callback.
sub _vertex_callback {
	my ($self, $graph, $id, $vertex_label) = @_;
	$graph->set_vertex_attribute($id, 'label', $vertex_label);
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Graph::Reader::TGF - Perl class for reading a graph from TGF format.

=head1 SYNOPSIS

 use Graph::Reader::TGF;

 my $obj = Graph::Reader::TGF->new;
 my $graph = $obj->read_graph($tgf_file);

=head1 METHODS

=head2 C<new>

 my $obj = Graph::Reader::TGF->new;

Constructor.

This doesn't take any arguments.

Returns Graph::Reader::TGF object.

=head2 C<read_graph>

 my $graph = $obj->read_graph($tgf_file);

Read a graph from the specified file.
The argument can either be a filename, or a filehandle for a previously opened file.

Returns Graph object.

=head1 TGF FILE FORMAT

 TGF = Trivial Graph Format
 TGF file format is described on L<English Wikipedia - Trivial Graph Format|https://en.wikipedia.org/wiki/Trivial_Graph_Format>
 Example:
 1 First node
 2 Second node
 #
 1 2 Edge between the two

=head1 ERRORS

 new():
         Parameter 'edge_callback' isn't reference to code.
         Parameter 'vertex_callback' isn't reference to code.

=head1 EXAMPLE1

=for comment filename=read_tgf_trivial_and_print.pl

 use strict;
 use warnings;

 use File::Temp qw(tempfile);
 use Graph::Reader::TGF;
 use IO::Barf qw(barf);

 # Example data.
 my $data = <<'END';
 1 First node
 2 Second node
 #
 1 2 Edge between the two
 END

 # Temporary file.
 my (undef, $tempfile) = tempfile();

 # Save data to temp file.
 barf($tempfile, $data);

 # Reader object.
 my $obj = Graph::Reader::TGF->new;

 # Get graph from file.
 my $g = $obj->read_graph($tempfile);

 # Print to output.
 print $g."\n";

 # Clean temporary file.
 unlink $tempfile;

 # Output:
 # 1-2

=head1 EXAMPLE2

=for comment filename=read_tgf_advanced_and_print.pl

 use strict;
 use warnings;

 use File::Temp qw(tempfile);
 use Graph::Reader::TGF;
 use IO::Barf qw(barf);

 # Example data.
 my $data = <<'END';
 1 Node #1
 2 Node #2
 3 Node #3
 4 Node #4
 5 Node #5
 6 Node #6
 7 Node #7
 8 Node #8
 9 Node #9
 10 Node #10
 #
 1 2
 1 3
 1 5
 1 6
 1 10
 3 4
 6 7
 6 8
 6 9
 END

 # Temporary file.
 my (undef, $tempfile) = tempfile();

 # Save data to temp file.
 barf($tempfile, $data);

 # Reader object.
 my $obj = Graph::Reader::TGF->new;

 # Get graph from file.
 my $g = $obj->read_graph($tempfile);

 # Print to output.
 print $g."\n";

 # Clean temporary file.
 unlink $tempfile;

 # Output:
 # 1-10,1-2,1-3,1-5,1-6,3-4,6-7,6-8,6-9

=head1 DEPENDENCIES

L<Encode>,
L<Error::Pure>,
L<Graph::Reader>.

=head1 SEE ALSO

=over

=item L<Graph::Reader>

base class for Graph file format readers

=item L<Task::Graph::Reader>

Install the Graph::Reader modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Graph-Reader-TGF>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2014-2023

BSD 2-Clause License

=head1 VERSION

0.04

=cut
