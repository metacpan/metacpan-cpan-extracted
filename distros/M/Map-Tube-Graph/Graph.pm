package Map::Tube::Graph;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use Graph;
use List::Util 1.33 qw(none);
use Scalar::Util qw(blessed);

our $VERSION = 0.06;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Edge callback.
	$self->{'callback_edge'} = sub {
		my ($self, $node, $link) = @_;
		$self->{'graph'}->add_edge($node->id, $link);
		return;
	};

	# Vertex callback.
	$self->{'callback_vertex'} = sub {
		my ($self, $node) = @_;
		$self->{'graph'}->add_vertex($node->id);
		return;
	};

	# Graph object.
	$self->{'graph'} = undef;

	# Map::Tube object.
	$self->{'tube'} = undef;

	# Process params.
	set_params($self, @params);

	# Check Map::Tube object.
	if (! defined $self->{'tube'}) {
		err "Parameter 'tube' is required.";
	}
	if (! defined &UNIVERSAL::DOES) {
		eval {
			require UNIVERSAL::DOES;
		};
		if ($EVAL_ERROR) {
			err 'Cannot load UNIVERSAL::DOES module.';
		}
	}
	if (! blessed($self->{'tube'})
		|| ! $self->{'tube'}->DOES('Map::Tube')) {

		err "Parameter 'tube' must be 'Map::Tube' object.";
	}

	# Graph object.
	if (! defined $self->{'graph'}) {
		$self->{'graph'} = Graph->new;
	}

	# Object.
	return $self;
}

# Get graph.
sub graph {
	my $self = shift;
	foreach my $node (values %{$self->{'tube'}->nodes}) {
		$self->{'callback_vertex'}->($self, $node);
	}
	my @processed;
	foreach my $node (values %{$self->{'tube'}->nodes}) {
		foreach my $link (split m/,/ms, $node->link) {
			if (none {
				($_->[0] eq $node->id && $_->[1] eq $link) 
				|| 
				($_->[0] eq $link && $_->[1] eq $node->id)
				} @processed) {

				$self->{'callback_edge'}->($self, $node, $link);
				push @processed, [$node->id, $link];
			}
		}
	}
	return $self->{'graph'};
}

1;

__END__

=encoding utf8

=head1 NAME

Map::Tube::Graph - Graph output for Map::Tube.

=head1 SYNOPSIS

 use Map::Tube::Graph;
 my $obj = Map::Tube::GraphViz->new(%params);
 my $graph = $obj->graph;

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<callback_edge>

 Edge callback.
 Default value is this:
 sub { 
         my ($self, $node, $link) = @_;
         $self->{'graph'}->add_edge($node->id, $link);
         return;
 }

=item * C<callback_vertex>

 Vertex callback.
 Default value is this:
 sub { 
         my ($self, $node) = @_;
         $self->{'graph'}->add_vertex($node->id);
         return;
 }

=item * C<graph>

 Graph object.
 Default value is Graph->new.

=item * C<tube>

 Map::Tube object.
 It is required.
 Default value is undef.

=back

=item C<graph()>
 
 Get Graph object.
 Returns Graph object.

=back

=head1 ERRORS

 new():
         Cannot load UNIVERSAL::DOES module.
         Parameter 'tube' is required.
         Parameter 'tube' must be 'Map::Tube' object.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use English;
 use Error::Pure qw(err);
 use Map::Tube::Graph;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 metro\n";
         exit 1;
 }
 my $metro = $ARGV[0];
 
 # Object.
 my $class = 'Map::Tube::'.$metro;
 eval "require $class;";
 if ($EVAL_ERROR) {
         err "Cannot load '$class' class.",
                 'Error', $EVAL_ERROR;
 }
 
 # Metro object.
 my $tube = eval "$class->new";
 if ($EVAL_ERROR) {
         err "Cannot create object for '$class' class.",
                 'Error', $EVAL_ERROR;
 }
 
 # GraphViz object.
 my $g = Map::Tube::Graph->new(
         'tube' => $tube,
 );
 
 # Get graph.
 my $graph = $g->graph;

 # Output.
 print $graph."\n";

 # Output without arguments like:
 # Usage: /tmp/SZXfa2g154 metro

 # Output with 'Prague' argument like:
 # A02-A01,A02-A03,A04-A03,A04-MUSTEK,A07-A08,A07-MUZEUM,A08-A09,A09-A10,A11-A10,A11-A12,A13-A12,B01-B02,B03-B02,B03-B04,B05-B04,B05-B06,B07-B06,B08-B07,B08-B09,B10-B09,B10-B11,B11-B12,B17-B16,B17-B18,B18-B19,B19-B20,B21-B20,B21-B22,B22-B23,B24-B23,C01-C02,C03-C02,C04-C03,C04-C05,C06-C05,C06-C07,C09-MUZEUM,C11-C12,C11-MUZEUM,C13-C12,C13-C14,C14-C15,C16-C15,C16-C17,C18-C17,C18-C19,C20-C19,FLORENC-B14,FLORENC-B16,FLORENC-C07,FLORENC-C09,MUSTEK-B12,MUSTEK-B14,MUSTEK-MUZEUM

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<Graph>,
L<List::Util>,
L<Scalar::Util>.

L<UNIVERSAL::DOES> if doesn't exists in Perl.

=head1 SEE ALSO

=over

=item L<Map::Tube>

Core library as Role (Moo) to process map data.

=item L<Map::Tube::GraphViz>

GraphViz output for Map::Tube.

=item L<Map::Tube::Plugin::Graph>

Graph plugin for Map::Tube.

=item L<Map::Tube::Text::Table>

Table output for Map::Tube.

=item L<Task::Map::Tube>

Install the Map::Tube modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Map-Tube-Graph>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2014-2023 Michal Josef Špaček

Artistic License

BSD 2-Clause License

=head1 VERSION

0.06

=cut
