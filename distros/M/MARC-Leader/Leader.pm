package MARC::Leader;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::MARC::Leader;
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

sub parse {
	my ($self, $leader) = @_;

	my %params = (
		'length' => $self->_int($leader, 0, 5),,
		'status' => (substr $leader, 5, 1),
		'type' => (substr $leader, 6, 1),
		'bibliographic_level' => (substr $leader, 7, 1),
		'type_of_control' => (substr $leader, 8, 1),
		'char_coding_scheme' => (substr $leader, 9, 1),
		'indicator_count' => (substr $leader, 10, 1),
		'subfield_code_count' => (substr $leader, 11, 1),
		'data_base_addr' => $self->_int($leader, 12, 5),
		'encoding_level' => (substr $leader, 17, 1),
		'descriptive_cataloging_form' => (substr $leader, 18, 1),
		'multipart_resource_record_level' => (substr $leader, 19, 1),
		'length_of_field_portion_len' => (substr $leader, 20, 1),
		'starting_char_pos_portion_len' => (substr $leader, 21, 1),
		'impl_def_portion_len' => (substr $leader, 22, 1),
		'undefined' => (substr $leader, 23, 1),
	);

	return Data::MARC::Leader->new(%params);
}

sub serialize {
	my ($self, $leader_obj) = @_;

	# Check object.
	if (! blessed($leader_obj) || ! $leader_obj->isa('Data::MARC::Leader')) {
		err "Bad 'Data::MARC::Leader' instance to serialize.";
	}

	my $leader = sprintf('%05d', $leader_obj->length).
		$leader_obj->status.
		$leader_obj->type.
		$leader_obj->bibliographic_level.
		$leader_obj->type_of_control.
		$leader_obj->char_coding_scheme.
		$leader_obj->indicator_count.
		$leader_obj->subfield_code_count.
		sprintf('%05d', $leader_obj->data_base_addr).
		$leader_obj->encoding_level.
		$leader_obj->descriptive_cataloging_form.
		$leader_obj->multipart_resource_record_level.
		$leader_obj->length_of_field_portion_len.
		$leader_obj->starting_char_pos_portion_len.
		$leader_obj->impl_def_portion_len.
		$leader_obj->undefined;

	return $leader;
}

sub _int {
	my ($self, $leader, $pos, $length) = @_;

	my $ret = substr $leader, $pos, $length;
	if ($ret =~ m/^\s+$/ms) {
		$ret = 0;
	} else {
		$ret = int($ret);
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Leader - MARC leader class.

=head1 SYNOPSIS

 use MARC::Leader;

 my $obj = MARC::Leader->new(%params);
 my $leader_obj = $obj->parse($leader_str);
 my $leader_str = $obj->serialize($leader_obj);

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Leader->new(%params);

Constructor.

Returns instance of object.

=head2 C<parse>

 my $leader_obj = $obj->parse($leader_str);

Parse MARC leader string to object.

Returns instance of 'Data::MARC::Leader' object.

=head2 C<serialize>

 my $leader_str = $obj->serialize($leader_obj);

Serialize MARC leader object to string.

Returns string.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 serialize():
         Bad 'Data::MARC::Leader' instance to serialize.


=head1 EXAMPLE1

=for comment filename=parse_marc_leader_and_dump.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Leader;

 if (@ARGV < 1) {
         print "Usage: $0 marc_leader\n";
         exit 1;
 }
 my $marc_leader = $ARGV[0];

 # Object.
 my $obj = MARC::Leader->new;

 # Parse.
 my $leader_obj = $obj->parse($marc_leader);

 # Dump to output.
 p $leader_obj;

 # Output for '02200cem a2200541 i 4500':
 # Data::MARC::Leader  {
 #     parents: Mo::Object
 #     public methods (3):
 #         BUILD
 #         Mo::utils:
 #             check_strings
 #         Readonly:
 #             Readonly
 #     private methods (0)
 #     internals: {
 #         bibliographic_level               "m",
 #         char_coding_scheme                "a",
 #         data_base_addr                    541,
 #         descriptive_cataloging_form       "i",
 #         encoding_level                    " ",
 #         impl_def_portion_len              0,
 #         indicator_count                   2,
 #         length                            2200,
 #         length_of_field_portion_len       4,
 #         multipart_resource_record_level   " ",
 #         starting_char_pos_portion_len     5,
 #         status                            "c",
 #         subfield_code_count               2,
 #         type                              "e",
 #         type_of_control                   " ",
 #         undefined                         0
 #     }
 # }

=head1 EXAMPLE2

=for comment filename=parse_marc_leader_and_print.pl

 use strict;
 use warnings;

 use MARC::Leader;
 use MARC::Leader::Print;

 if (@ARGV < 1) {
         print "Usage: $0 marc_leader\n";
         exit 1;
 }
 my $marc_leader = $ARGV[0];

 # Object.
 my $obj = MARC::Leader->new;

 # Parse.
 my $leader_obj = $obj->parse($marc_leader);

 # Print to output.
 print scalar MARC::Leader::Print->new->print($leader_obj), "\n";

 # Output for '02200cem a2200541 i 4500':
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

=head1 EXAMPLE3

=for comment filename=serialize_marc_leader.pl

 use strict;
 use warnings;

 use Data::MARC::Leader;
 use MARC::Leader;

 # Object.
 my $obj = MARC::Leader->new;

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

 # Serialize.
 my $leader = $obj->serialize($data_marc_leader);

 # Print to output.
 print $leader."\n";

 # Output:
 # 02200cem a2200541 i 4500

=head1 DEPENDENCIES

L<Class::Utils>,
L<Data::MARC::Leader>,
L<Error::Pure>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Data::MARC::Leader>

Data object for MARC leader.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Leader>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
