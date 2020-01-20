package Map::Tube::Text::Table;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Map::Tube::Text::Table::Utils qw(table);
use List::MoreUtils qw(any);
use Readonly;
use Scalar::Util qw(blessed);

# Constants.
Readonly::Scalar our $CONNECTED_TO => q{Connected to};
Readonly::Scalar our $ID => q{ID};
Readonly::Scalar our $JUNCTIONS => q{Junctions};
Readonly::Scalar our $LINE => q{Line};
Readonly::Scalar our $LINES => q{Lines};
Readonly::Scalar our $STATION => q{Station};

our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Print ids.
	$self->{'print_id'} = 0;

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

# Print junctions.
sub junctions {
	my $self = shift;

	# Get data.
	my @data;
	my @title = ($STATION, $LINE, $CONNECTED_TO);
	my @data_len = map { length $_ } @title;
	my $nodes_hr = $self->{'tube'}->nodes;
	foreach my $node_name (sort keys %{$nodes_hr}) {
		if (@{$nodes_hr->{$node_name}->line} > 1) {

			# Get data.
			my @links = map { $self->{'tube'}->get_node_by_id($_)->name }
				split m/,/ms, $nodes_hr->{$node_name}->link;
			my $data_ar = [
				$nodes_hr->{$node_name}->name,
				(join ', ', map { $_->name } @{$nodes_hr->{$node_name}->line}),
				(join ', ', sort @links),
			];
			push @data, $data_ar;

			# Maximum data length.
			foreach my $i (0 .. $#{$data_ar}) {
				if (length $data_ar->[$i] > $data_len[$i]) {
					$data_len[$i] = length $data_ar->[$i];
				}
			}
		}
	}

	# Print and return table.
	return table($JUNCTIONS, \@data_len, \@title, \@data);
}

# Print line.
sub line {
	my ($self, $line) = @_;

	# Get data.
	my @data;
	my @title = ($STATION, $CONNECTED_TO);
	if ($self->{'print_id'}) {
		unshift @title, $ID;
	}
	my @data_len = map { length $_ } @title;
	my $nodes_hr = $self->{'tube'}->nodes;
	foreach my $node_name (sort keys %{$nodes_hr}) {
		if (any { $_ eq $line } map { $_->name }
			@{$nodes_hr->{$node_name}->line}) {

			# Get data.
			my @links = map { $self->{'tube'}->get_node_by_id($_)->name }
				split m/,/ms, $nodes_hr->{$node_name}->link;
			my $data_ar = [
				$nodes_hr->{$node_name}->name,
				(join ', ', sort @links),
			];
			if ($self->{'print_id'}) {
				unshift @{$data_ar}, $nodes_hr->{$node_name}->id,
			}
			push @data, $data_ar;

			# Maximum data length.
			foreach my $i (0 .. $#{$data_ar}) {
				if (length $data_ar->[$i] > $data_len[$i]) {
					$data_len[$i] = length $data_ar->[$i];
				}
			}
		}
	}

	# Print and return table.
	return table($LINE." '$line'", \@data_len, \@title, \@data);
}

# Get lines.
sub lines {
	my $self = shift;
	my $lines_ar = $self->{'tube'}->get_lines;
	my $length = 0;
	my @data;
	foreach my $line (sort @{$lines_ar}) {
		push @data, [$line];
		if (length $line > $length) {
			$length = length $line;
		}
	}
	return table($LINES, [$length], undef, \@data);
}

# Print all.
sub print {
	my $self = shift;
	my $ret = $self->junctions;
	foreach my $line (@{$self->{'tube'}->get_lines}) {
		$ret .= $self->line($line->name);
	}
	return $ret;
}

1;

__END__

=encoding utf8

=head1 NAME

Map::Tube::Text::Table - Table output for Map::Tube.

=head1 SYNOPSIS

 use Map::Tube::Text::Table;

 my $obj = Map::Tube::Text::Table->new(%params);
 my $text = $obj->junctions;
 my $text = $obj->line($line);
 my $text = $obj->lines;
 my $text = $obj->print;

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<print_id>

 Flag, that means printing of ID.
 Affected methods:
 - line()
 - print() (by line()).
 Default value is 0.

=item * C<tube>

 Map::Tube object.
 It is required.
 Default value is undef.

=back

=item C<junctions()>

 Print junctions.
 Returns string with unicode text table.

=item C<line($line)>

 Print line.
 Returns string with unicode text table.

=item C<lines()>

 Print sorted lines.
 Returns string with unicode text table.

=item C<print()>

 Print all (junctions + all lines).
 Returns string with unicode text table.

=back

=head1 ERRORS

 new():
         Parameter 'tube' is required.
         Parameter 'tube' must be 'Map::Tube' object.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use English;
 use Error::Pure qw(err);
 use Map::Tube::Text::Table;

 # Error::Pure environment.
 $ENV{'ERROR_PURE'} = 'AllError';

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
 my $table = Map::Tube::Text::Table->new(
         'tube' => $tube,
 );
 
 # Print out.
 print encode_utf8($table->print);

 # Output without arguments like:
 # Usage: /tmp/SZXfa2g154 metro

 # Output with 'Tbilisi' argument like:
 # ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
 # │ Junctions                                                                                        │
 # ├──────────────────┬──────────────────────────────────────────┬────────────────────────────────────┤
 # │ Station          │ Line                                     │ Connected to                       │
 # ├──────────────────┼──────────────────────────────────────────┼────────────────────────────────────┤
 # │ სადგურის მოედანი │ ახმეტელი-ვარკეთილის ხაზი,საბურთალოს ხაზი │ მარჯანიშვილი, ნაძალადევი, წერეთელი │
 # └──────────────────┴──────────────────────────────────────────┴────────────────────────────────────┘
 # ┌───────────────────────────────────────────────────────────┐
 # │ Line 'ახმეტელი-ვარკეთილის ხაზი'                           │
 # ├──────────────────────┬────────────────────────────────────┤
 # │ Station              │ Connected to                       │
 # ├──────────────────────┼────────────────────────────────────┤
 # │ ახმეტელის თეატრი     │ სარაჯიშვილი                        │
 # │ სარაჯიშვილი          │ ახმეტელის თეატრი, გურამიშვილი      │
 # │ გურამიშვილი          │ სარაჯიშვილი, ღრმაღელე              │
 # │ ღრმაღელე             │ გურამიშვილი, დიდუბე                │
 # │ დიდუბე               │ გოცირიძე, ღრმაღელე                 │
 # │ გოცირიძე             │ დიდუბე, ნაძალადევი                 │
 # │ ნაძალადევი           │ გოცირიძე, სადგურის მოედანი         │
 # │ მარჯანიშვილი         │ რუსთაველი, სადგურის მოედანი        │
 # │ რუსთაველი            │ თავისუფლების მოედანი, მარჯანიშვილი │
 # │ თავისუფლების მოედანი │ ავლაბარი, რუსთაველი                │
 # │ ავლაბარი             │ 300 არაგველი, თავისუფლების მოედანი │
 # │ 300 არაგველი         │ ავლაბარი, ისანი                    │
 # │ ისანი                │ 300 არაგველი, სამგორი              │
 # │ სამგორი              │ ვარკეთილი, ისანი                   │
 # │ ვარკეთილი            │ სამგორი                            │
 # │ სადგურის მოედანი     │ მარჯანიშვილი, ნაძალადევი, წერეთელი │
 # └──────────────────────┴────────────────────────────────────┘
 # ┌────────────────────────────────────────────────────────────────────┐
 # │ Line 'საბურთალოს ხაზი'                                             │
 # ├─────────────────────────┬──────────────────────────────────────────┤
 # │ Station                 │ Connected to                             │
 # ├─────────────────────────┼──────────────────────────────────────────┤
 # │ წერეთელი                │ სადგურის მოედანი, ტექნიკური უნივერსიტეტი │
 # │ ტექნიკური უნივერსიტეტი  │ სამედიცინო უნივერსიტეტი, წერეთელი        │
 # │ სამედიცინო უნივერსიტეტი │ დელისი, ტექნიკური უნივერსიტეტი           │
 # │ დელისი                  │ ვაჟა-ფშაველა, სამედიცინო უნივერსიტეტი    │
 # │ ვაჟა-ფშაველა            │ დელისი                                   │
 # │ სადგურის მოედანი        │ მარჯანიშვილი, ნაძალადევი, წერეთელი       │
 # └─────────────────────────┴──────────────────────────────────────────┘

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Map::Tube::Text::Table::Utils>,
L<List::MoreUtils>,
L<Readonly>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Task::Map::Tube>

Install the Map::Tube modules.

=item L<Task::Map::Tube::Metro>

Install the Map::Tube concrete metro modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Map-Tube-Text-Table>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2020 Michal Josef Špaček
 Artistic License
 BSD 2-Clause License

=head1 VERSION

0.05

=cut
