package Graph::Reader::UnicodeTree;

# Pragmas.
use base qw(Graph::Reader);
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use Readonly;

# Constants.
Readonly::Scalar our $GR_LINE => decode_utf8(q{───});
Readonly::Scalar our $GR_TREE => decode_utf8(q{─┬─});

# Version.
our $VERSION = 0.02;

# Read graph subroutine.
sub _read_graph {
	my ($self, $graph, $fh) = @_;
	my @indent = ([0, undef]);
	while (my $line = decode_utf8(<$fh>)) {
		chomp $line;

		# Remove indent.
		my $parseable_line = substr $line, $indent[-1]->[0];

		# Split to vertexes.
		my @new_indent;
		my @vertexes;
		my $new_indent = $indent[-1]->[0];
		my $last_indent;
		foreach my $new_block (split m/$GR_TREE/ms, $parseable_line) {
			if (defined $last_indent) {
				push @new_indent, $last_indent;
				$last_indent = undef;
			}
			my $last_vertex;	
			foreach my $new_vertex (split m/$GR_LINE/ms, $new_block) {
				push @vertexes, $new_vertex;
				$last_vertex = $new_vertex;
			}
			$new_indent += (length $new_block) + 3;
			$last_indent = [$new_indent, $last_vertex];
		}

		# Add vertexes and edges.
		my $first_v;
		if (defined $indent[-1]->[1]) {
			$first_v = $indent[-1]->[1];
		} else {
			$first_v = shift @vertexes;
		}
		$graph->add_vertex($first_v);
		foreach my $second_v (@vertexes) {
			$graph->add_vertex($second_v);
			$graph->add_edge($first_v, $second_v);
			$first_v = $second_v;
		}

		# Update indent.
		my $end_pos = $indent[-1]->[0] - 2;
		if ($end_pos > 0) {
			my $end_char = substr $line, $end_pos, 1;
			if ($end_char eq decode_utf8('└')) {
				pop @indent;
			}
		}
		if (@new_indent) {
			push @indent, @new_indent;
		}
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Graph::Reader::UnicodeTree - Perl class for reading a graph from unicode tree text format.

=head1 SYNOPSIS

 use Graph::Reader::UnicodeTree;
 my $obj = Graph::Reader::UnicodeTree->new;
 my $graph = $obj->read_graph($unicode_tree_file);

=head1 METHODS

=over 8

=item C<new()>

 Constructor.
 This doesn't take any arguments.
 Returns Graph::Reader::UnicodeTree object.

=item C<read_graph($unicode_tree_file)>

 Read a graph from the specified file.
 The argument can either be a filename, or a filehandle for a previously opened file.
 Returns Graph object.

=back

=head1 UNICODE TREE FILE FORMAT

 Vertices are simple text.
 Edges are '─┬─' or '───' in main line and ' ├─' or ' └─' in other lines.
 Example:
 1─┬─2
   ├─3───4
   ├─5
   ├─6─┬─7
   │   ├─8
   │   └─9
   └─10

=head1 EXAMPLE

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Encode qw(decode_utf8 encode_utf8);
 use Graph::Reader::UnicodeTree;
 use IO::Barf qw(barf);
 use File::Temp qw(tempfile);

 # Example data.
 my $data = decode_utf8(<<'END');
 1─┬─2
   ├─3───4
   ├─5
   ├─6─┬─7
   │   ├─8
   │   └─9
   └─10
 END

 # Temporary file.
 my (undef, $tempfile) = tempfile();

 # Save data to temp file.
 barf($tempfile, encode_utf8($data));

 # Reader object.
 my $obj = Graph::Reader::UnicodeTree->new;

 # Get graph from file.
 my $g = $obj->read_graph($tempfile);

 # Clean temporary file.
 unlink $tempfile;

 # Print to output.
 print $g."\n";

 # Output:
 # 1-10,1-2,1-3,1-5,1-6,3-4,6-7,6-8,6-9

=head1 DEPENDENCIES

L<Encode>,
L<Graph::Reader>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Graph::Reader>

base class for Graph file format readers

=item L<Task::Graph::Reader>

Install the Graph::Reader modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Graph-Reader-UnicodeTree>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © Michal Špaček 2013-2015
 BSD 2-Clause License

=head1 VERSION

0.02

=cut
