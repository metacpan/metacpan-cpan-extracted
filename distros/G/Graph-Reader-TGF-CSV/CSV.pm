package Graph::Reader::TGF::CSV;

use base qw(Graph::Reader::TGF);
use strict;
use warnings;

use Error::Pure qw(err);
use Text::CSV;

our $VERSION = 0.03;

# Edge callback.
sub _edge_callback {
	my ($self, $graph, $id1, $id2, $edge_label) = @_;
	my $status = $self->{'_csv'}->parse($edge_label);
	if (! $status) {
		err 'Cannot parse edge label.',
			'Error', $self->{'_csv'}->error_input,
			'String', $edge_label;
	}
	my %params = map { split m/=/ms, $_ } $self->{'_csv'}->fields;
	foreach my $key (keys %params) {
		$graph->set_edge_attribute($id1, $id2, $key, $params{$key});
	}
	return;
}

# Initialization.
sub _init {
	my ($self, $param_hr) = @_;
	$self->SUPER::_init();
	$self->{'_csv'} = Text::CSV->new({'binary' => 1});
	if (! $self->{'_csv'}) {
		err 'Cannot create Text::CSV object.',
			'Error', Text::CSV->error_diag;
	}
	return;
}

# Vertex callback.
sub _vertex_callback {
	my ($self, $graph, $id, $vertex_label) = @_;
	my $status = $self->{'_csv'}->parse($vertex_label);
	if (! $status) {
		err 'Cannot parse vertex label.',
			'Error', $self->{'_csv'}->error_input,
			'String', $vertex_label;
	}
	my %params = map { split m/=/ms, $_ } $self->{'_csv'}->fields;
	foreach my $key (keys %params) {
		$graph->set_vertex_attribute($id, $key, $params{$key});
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Graph::Reader::TGF::CSV - Perl class for reading a graph from TGF format with CSV labeling.

=head1 SYNOPSIS

 use Graph::Reader::TGF::CSV;

 my $obj = Graph::Reader::TGF::CSV->new;
 my $graph = $obj->read_graph($tgf_csv_file);

=head1 METHODS

=over 8

=item C<new()>

 Constructor.
 This doesn't take any arguments.
 Returns Graph::Reader::TGF::CSV object.

=item C<read_graph($tgf_csv_file)>

 Read a graph from the specified file.
 The argument can either be a filename, or a filehandle for a previously opened file.
 Returns Graph object.

=back

=head1 TGF WITH CSV LABELING FILE FORMAT

 TGF = Trivial Graph Format
 TGF file format is described on L<English Wikipedia - Trivial Graph Format|https://en.wikipedia.org/wiki/Trivial_Graph_Format>
 Example with CSV labeling:
 1 label=First node,color=red
 2 label=Second node,color=cyan
 #
 1 2 label=Edge between the two,color=green

=head1 ERRORS

 new():
         Cannot create Text::CSV object.
                 Error: %s
         Cannot parse edge label.
                 Error: %s
                 String: %s
         Cannot parse vertex label.
                 Error: %s
                 String: %s

=head1 EXAMPLE

 use strict;
 use warnings;

 use Graph::Reader::TGF::CSV;
 use IO::Barf qw(barf);
 use File::Temp qw(tempfile);

 # Example data.
 my $data = <<'END';
 1 label=First node,green=red
 2 label=Second node,green=cyan
 #
 1 2 label=Edge between the two,color=green
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

=head1 DEPENDENCIES

L<Error::Pure>,
L<Graph::Reader::TGF>,
L<Text::CSV>.

=head1 SEE ALSO

=over

=item L<Graph::Reader>

base class for Graph file format readers

=item L<Task::Graph::Reader>

Install the Graph::Reader modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Graph-Reader-TGF-CSV>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2014-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
