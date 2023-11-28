package MARC::Leader::Print;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::MARC::Leader::Utils;
use English;
use Error::Pure qw(err);

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Use with ANSI sequences.
	$self->{'mode_ansi'} = undef;

	# Use description.
	$self->{'mode_desc'} = 1;

	# Output separator.
	$self->{'output_separator'} = "\n";

	# Process parameters.
	set_params($self, @params);

	$self->{'_utils'} = Data::MARC::Leader::Utils->new;

	if (! defined $self->{'mode_ansi'}) {
		if (exists $ENV{'NO_COLOR'}) {
			$self->{'mode_ansi'} = 0;
		} elsif (defined $ENV{'COLOR'}) {
			$self->{'mode_ansi'} = 1;
		} else {
			$self->{'mode_ansi'} = 0;
		}
	}

	# Check routine for ANSI colors output.
	if ($self->{'mode_ansi'}) {
		eval {
			require Term::ANSIColor;
		};
		if ($EVAL_ERROR) {
			err "Cannot load 'Term::ANSIColor' module.";
		}
	}

	return $self;
}

sub print {
	my ($self, $leader_obj) = @_;

	my @ret;
	push @ret, $self->_key('Record length').$leader_obj->length;
	push @ret, $self->_key('Record status').$self->_print($leader_obj, 'status');
	push @ret, $self->_key('Type of record').$self->_print($leader_obj, 'type');
	push @ret, $self->_key('Bibliographic level').$self->_print($leader_obj,
		'bibliographic_level');
	push @ret, $self->_key('Type of control').$self->_print($leader_obj,
		'type_of_control');
	push @ret, $self->_key('Character coding scheme').$self->_print($leader_obj,
		'char_coding_scheme');
	push @ret, $self->_key('Indicator count').$self->_print($leader_obj,
		'indicator_count');
	push @ret, $self->_key('Subfield code count').$self->_print($leader_obj,
		'subfield_code_count', 1);
	push @ret, $self->_key('Base address of data').$leader_obj->data_base_addr;
	push @ret, $self->_key('Encoding level').$self->_print($leader_obj,
		'encoding_level');
	push @ret, $self->_key('Descriptive cataloging form').$self->_print($leader_obj,
		'descriptive_cataloging_form');
	push @ret, $self->_key('Multipart resource record level').$self->_print($leader_obj,
		'multipart_resource_record_level');
	push @ret, $self->_key('Length of the length-of-field portion').$self->_print($leader_obj,
		'length_of_field_portion_len', 1);
	push @ret, $self->_key('Length of the starting-character-position portion').
		$self->_print($leader_obj, 'starting_char_pos_portion_len', 1);
	push @ret, $self->_key('Length of the implementation-defined portion').
		$self->_print($leader_obj, 'impl_def_portion_len', 1);
	push @ret, $self->_key('Undefined').$self->_print($leader_obj, 'undefined');

	return wantarray ? @ret : (join $self->{'output_separator'}, @ret);
}

sub _key {
	my ($self, $key) = @_;

	my $ret;
	if ($self->{'mode_ansi'}) {
		$ret = Term::ANSIColor::color('cyan').$key.Term::ANSIColor::color('reset');
	} else {
		$ret = $key;
	}
	$ret .= ': ';

	return $ret;
}

sub _print {
	my ($self, $leader_obj, $method_name, $value) = @_;

	my $ret_value = $leader_obj->$method_name;
	my $ret;
	if ($self->{'mode_desc'}) {
		$ret = eval "\$self->{'_utils'}->desc_$method_name(\$ret_value);";
	}
	if (defined $value) {
		$ret .= ' ('.$ret_value.')';
	}

	return $ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Leader::Print - MARC leader class for print.

=head1 SYNOPSIS

 use MARC::Leader::Print;

 my $obj = MARC::Leader::Print->new(%params);
 my @ret = $obj->print($leader_obj);
 my $ret = $obj->print($leader_obj);

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Leader->new(%params);

Constructor.

=over 8

=item * C<mode_ansi>

Mode for ANSI color support:

 1 - ANSI color support enabled.
 0 - ANSI color support disabled.

When is undefined, env variables C<COLOR> or C<NO_COLOR> could control ANSI
color support.

Default value is undef.

=item * C<mode_desc>

Use description instead of raw leader values.

Default value is 1.

=item * C<output_separator>

Output separator used in scalar context of C<print()> method.

Default value is "\n".

=back

Returns instance of object.

=head2 C<print>

 my @ret = $obj->print($leader_obj);
 my $ret = $obj->print($leader_obj);

Process L<Data::MARC::Leader> instance to output print.
In scalar context compose printing output as one string.
In array context compose list of printing lines.

Color (ANSI colors) output is controlled by 'mode_ansi' parameter
or env variables C<COLOR> and C<NO_COLOR>.

Returns string in scalar context.
Returns array of string in array context.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=print_data_marc_leader.pl

 use strict;
 use warnings;

 use Data::MARC::Leader;
 use MARC::Leader::Print;

 # Print object.
 my $print = MARC::Leader::Print->new;

 # Data object.
 my $data_marc_leader = Data::MARC::Leader->new(
         'bibliographic_level' => 'm',
         'char_coding_scheme' => 'a',
         'data_base_addr' => 541,
         'descriptive_cataloging_form' => 'i',
         'encoding_level' => ' ',
         'impl_def_portion_len' => '0',
         'indicator_count' => '2',
         'length' => 2200,
         'length_of_field_portion_len' => '4',
         'multipart_resource_record_level' => ' ',
         'starting_char_pos_portion_len' => '5',
         'status' => 'c',
         'subfield_code_count' => '2',
         'type' => 'e',
         'type_of_control' => ' ',
         'undefined' => '0',
 );

 # Print to output.
 print scalar $print->print($data_marc_leader), "\n";

 # Output:
 # Record length: 2200
 # Record status: Corrected or revised
 # Type of record: Cartographic material
 # Bibliographic level: Monograph/Item
 # Type of control: No specified type
 # Character coding scheme: UCS/Unicode
 # Indicator count: Number of character positions used for indicators
 # Subfield code count: Number of character positions used for a subfield code (2)
 # Base address of data: 541
 # Encoding level: Full level
 # Descriptive cataloging form: ISBD punctuation included
 # Multipart resource record level: Not specified or not applicable
 # Length of the length-of-field portion: Number of characters in the length-of-field portion of a Directory entry (4)
 # Length of the starting-character-position portion: Number of characters in the starting-character-position portion of a Directory entry (5)
 # Length of the implementation-defined portion: Number of characters in the implementation-defined portion of a Directory entry (0)
 # Undefined: Undefined

=head1 DEPENDENCIES

L<Class::Utils>,
L<Data::MARC::Leader::Utils>,
L<English>,
L<Error::Pure>.

And optional L<Term::ANSIColor> for ANSI color support.

=head1 SEE ALSO

=over

=item L<Data::MARC::Leader>

Data object for MARC leader.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Leader-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
