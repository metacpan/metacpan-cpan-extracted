package Map::Tube::Text::Shortest;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use List::Util qw(reduce);
use Readonly;
use Scalar::Util qw(blessed);

# Constants.
Readonly::Scalar our $DOUBLE_SPACE => q{  };
Readonly::Scalar our $EMPTY_STR => q{};

# Version.
our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Map::Tube object.
	$self->{'tube'} = undef;

	# Process params.
	set_params($self, @params);

	# Check Map::Tube object.
	if (! defined $self->{'tube'}) {
		err "Parameter 'tube' is required.";
	}
	if (! blessed($self->{'tube'})
		|| ! $self->{'tube'}->does('Map::Tube')) {

		err "Parameter 'tube' must be 'Map::Tube' object.";
	}

	# Object.
	return $self;
}

# Print shortest table.
sub print {
	my ($self, $from, $to) = @_;
	my $route = $self->{'tube'}->get_shortest_route($from, $to);
	my $header = sprintf 'From %s to %s', $route->from->name,
		$route->to->name;
	my @output = (
		$EMPTY_STR,
		$header,
		'=' x length $header,
		$EMPTY_STR,
		sprintf '-- Route %d (cost %s) ----------', 1, '?',
	);
	my $line_id_length = length
		reduce { length($a) > length($b) ? $a : $b }
		map { $_->id || '?'} @{$self->{'tube'}->get_lines};
	foreach my $node (@{$route->nodes}) {
		my $num = 0;
		foreach my $line (@{$node->line}) {
			$num++;
			my $line_id = $line->id || '?';
			push @output, sprintf "[ %1s %-${line_id_length}s ] %s",
				# TODO +
				$num == 2 ? '*' : $EMPTY_STR,
				$line_id,
				$node->name;
		}
	}
	push @output, $EMPTY_STR;
	# TODO Skip lines, which are not in route table.
	foreach my $line (@{$self->{'tube'}->get_lines}) {
		push @output, (
			$line->id.$DOUBLE_SPACE.$line->name,
		);
	}
	push @output, (
		$EMPTY_STR,
		'*: Transfer to other line',
		'+: Transfer to other station',
		$EMPTY_STR,
	);
	return wantarray ? @output : join "\n", @output;
}

1;

__END__

=encoding utf8

=head1 NAME

Map::Tube::Text::Shortest - Shortest route information via Map::Tube object.

=head1 SYNOPSIS

 use Map::Tube::Test::Shortest;
 my $obj = Map::Tube::Text::Shortest->new;
 print $obj->print($from, $to);

=head1 METHODS

=over 8

=item C<new()>

 Constructor.

=over 8

=item * C<tube>

 Map::Tube object.
 Parameter is required.
 Default value is undef.

=back

=item print($from, $to)>

 Print shortest route table.
 Returns string with table.

=back

=head1 ERRORS

 new():
         Parameter 'tube' is required.
         Parameter 'tube' must be 'Map::Tube' object.

=head1 EXAMPLE

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use English;
 use Encode qw(decode_utf8 encode_utf8);
 use Error::Pure qw(err);
 use Map::Tube::Text::Shortest;

 # Arguments.
 if (@ARGV < 3) {
         print STDERR "Usage: $0 metro from to\n";
         exit 1;
 }
 my $metro = $ARGV[0];
 my $from = decode_utf8($ARGV[1]);
 my $to = decode_utf8($ARGV[2]);

 # Load metro object.
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

 # Table object.
 my $table = Map::Tube::Text::Shortest->new(
         'tube' => $tube,
 );
 
 # Print out.
 print encode_utf8(scalar $table->print($from, $to))."\n";

 # Output without arguments like:
 # Usage: /tmp/O0s_2qtAuB metro from to

 # Output with 'Budapest', 'Fővám tér', 'Opera' arguments like:
 # 
 # From Fővám tér to Opera
 # =======================
 # 
 # -- Route 1 (cost ?) ----------
 # [   M4 ] Fővám tér
 # [   M3 ] Kálvin tér
 # [ * M4 ] Kálvin tér
 # [   M3 ] Ferenciek tere
 # [   M1 ] Deák Ferenc tér
 # [ * M2 ] Deák Ferenc tér
 # [   M3 ] Deák Ferenc tér
 # [   M1 ] Bajcsy-Zsilinszky út
 # [   M1 ] Opera
 # 
 # M1  Linia M1
 # M3  Linia M3
 # M2  Linia M2
 # M4  Linia M4
 # 
 # *: Transfer to other line
 # +: Transfer to other station
 # 

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::Util>,
L<Readonly>,
L<Scalar::Util>.

=head1 SEE ALSO

L<Map::Tube>,
L<Map::Tube::Graph>,
L<Map::Tube::GraphViz>,
L<Map::Tube::Plugin::Graph>,
L<Map::Tube::Text::Table>,
L<Task::Map::Tube>.

=head1 REPOSITORY

L<https://github.com/tupinek/Map-Tube-Text-Shortest>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2015 Michal Špaček
 Artistic License
 BSD 2-Clause License

=head1 VERSION

0.01

=cut
