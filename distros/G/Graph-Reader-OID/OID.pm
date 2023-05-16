package Graph::Reader::OID;

use base qw(Graph::Reader);
use strict;
use warnings;

use Readonly;

# Constants.
Readonly::Scalar our $DOT => q{.};
Readonly::Scalar our $EMPTY_STR => q{};

# Version.
our $VERSION = 0.04;

# Read graph subroutine.
sub _read_graph {
	my ($self, $graph, $fh) = @_;
	while (my $line = <$fh>) {
		chomp $line;

		# End of vertexes section.
		if ($line =~ m/^#/ms) {
			next;
		}

		# Process OID.
		my ($line_oid, $line_label) = split m/\s+/ms, $line, 2;
		my @oid = split m/\./ms, $line_oid;
		my $last_oid;
		my $act_oid = $EMPTY_STR;
		foreach my $oid (@oid) {
			if ($act_oid ne $EMPTY_STR) {
				$act_oid .= $DOT;
			}
			$act_oid .= $oid;
			$graph->add_vertex($act_oid);
			if ($act_oid eq $line_oid) {
				if (! $line_label) {
					$line_label = $line_oid;
				}
				$graph->set_vertex_attribute($act_oid, 'label',
					$line_label);
			}
			if (defined $last_oid) {
				$graph->add_edge($last_oid, $act_oid);
			}
			$last_oid = $act_oid;
		}
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Graph::Reader::OID - Perl class for reading a graph from OID format.

=head1 SYNOPSIS

 use Graph::Reader::OID;

 my $obj = Graph::Reader::OID->new;
 my $graph = $obj->read_graph($oid_file);

=head1 METHODS

=over 8

=item C<new()>

 Constructor.
 This doesn't take any arguments.
 Returns Graph::Reader::OID object.

=item C<read_graph($tgf_file)>

 Read a graph from the specified file.
 The argument can either be a filename, or a filehandle for a previously opened file.
 Returns Graph object.

=back

=head1 OID FILE FORMAT

 File format with OID list.
 For OID (Object identifier) see L<Object identifier|https://en.wikipedia.org/wiki/Object_identifier>
 Example:
 1.2.410.200047.11.2013.10234913023321120142141561581 Label #1
 1.2.276.0.7230010.3.0.3.6.1 Label #2

=head1 EXAMPLE

=for comment filename=read_oid_graph_and_print.pl

 use strict;
 use warnings;

 use Graph::Reader::OID;
 use IO::Barf qw(barf);
 use File::Temp qw(tempfile);

 # Example data.
 my $data = <<'END';
 1.2.410.200047.11.2013.10234913023321120142141561581 Label #1
 1.2.276.0.7230010.3.0.3.6.1 Label #2
 END

 # Temporary file.
 my (undef, $tempfile) = tempfile();

 # Save data to temp file.
 barf($tempfile, $data);

 # Reader object.
 my $obj = Graph::Reader::OID->new;

 # Get graph from file.
 my $g = $obj->read_graph($tempfile);

 # Print to output.
 print $g."\n";

 # Clean temporary file.
 unlink $tempfile;

 # Output:
 # 1-1.2,1.2-1.2.276,1.2-1.2.410,1.2.276-1.2.276.0,1.2.276.0-1.2.276.0.7230010,1.2.276.0.7230010-1.2.276.0.7230010.3,1.2.276.0.7230010.3-1.2.276.0.7230010.3.0,1.2.276.0.7230010.3.0-1.2.276.0.7230010.3.0.3,1.2.276.0.7230010.3.0.3-1.2.276.0.7230010.3.0.3.6,1.2.276.0.7230010.3.0.3.6-1.2.276.0.7230010.3.0.3.6.1,1.2.410-1.2.410.200047,1.2.410.200047-1.2.410.200047.11,1.2.410.200047.11-1.2.410.200047.11.2013,1.2.410.200047.11.2013-1.2.410.200047.11.2013.10234913023321120142141561581

=head1 DEPENDENCIES

L<Graph::Reader>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Graph::Reader>

base class for Graph file format readers

=item L<Task::Graph::Reader>

Install the Graph::Reader modules.

=item L<Task::Graph::Writer>

Install the Graph::Writer modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Graph-Reader-OID>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2014-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
